using System.Security.Cryptography;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

namespace SmartExpenseManager.Api.Services;

public class UserService : IUserService
{
    private readonly IAmazonDynamoDB _dynamoDb;
    private readonly ILogger<UserService> _logger;
    private const string UsersTable = "SmartExpenseManager_Users";
    private const string OtpTable = "SmartExpenseManager_OTP";

    public UserService(IAmazonDynamoDB dynamoDb, ILogger<UserService> logger)
    {
        _dynamoDb = dynamoDb;
        _logger = logger;
    }

    public async Task<(bool Success, string? Error)> SignUpAsync(string email, string password, string name)
    {
        // Check if user already exists
        if (await UserExistsAsync(email))
            return (false, "An account with this email already exists");

        var passwordHash = HashPassword(password);
        var userId = Guid.NewGuid().ToString();

        var item = new Dictionary<string, AttributeValue>
        {
            { "Email", new AttributeValue { S = email.ToLowerInvariant() } },
            { "UserId", new AttributeValue { S = userId } },
            { "Name", new AttributeValue { S = name } },
            { "PasswordHash", new AttributeValue { S = passwordHash } },
            { "CreatedAt", new AttributeValue { S = DateTime.UtcNow.ToString("o") } }
        };

        await _dynamoDb.PutItemAsync(new PutItemRequest
        {
            TableName = UsersTable,
            Item = item,
            ConditionExpression = "attribute_not_exists(Email)"
        });

        return (true, null);
    }

    public async Task<(bool Valid, string? UserId)> ValidatePasswordAsync(string email, string password)
    {
        var response = await _dynamoDb.GetItemAsync(new GetItemRequest
        {
            TableName = UsersTable,
            Key = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } }
            }
        });

        if (response.Item == null || response.Item.Count == 0)
            return (false, null);

        var storedHash = response.Item["PasswordHash"].S;
        var userId = response.Item["UserId"].S;

        return VerifyPassword(password, storedHash) ? (true, userId) : (false, null);
    }

    public async Task<(string Code, string? Error)> GenerateOtpAsync(string email)
    {
        if (!await UserExistsAsync(email))
            return (string.Empty, "No account found with this email");

        var code = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(5).ToUnixTimeSeconds();

        await _dynamoDb.PutItemAsync(new PutItemRequest
        {
            TableName = OtpTable,
            Item = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } },
                { "Code", new AttributeValue { S = code } },
                { "ExpiresAt", new AttributeValue { N = expiresAt.ToString() } },
                { "CreatedAt", new AttributeValue { S = DateTime.UtcNow.ToString("o") } }
            }
        });

        _logger.LogInformation("OTP for {Email}: {Code}", email, code);

        return (code, null);
    }

    public async Task<(bool Valid, string? UserId)> VerifyOtpAsync(string email, string code)
    {
        var response = await _dynamoDb.GetItemAsync(new GetItemRequest
        {
            TableName = OtpTable,
            Key = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } }
            }
        });

        if (response.Item == null || response.Item.Count == 0)
            return (false, null);

        var storedCode = response.Item["Code"].S;
        var expiresAt = long.Parse(response.Item["ExpiresAt"].N);
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        if (storedCode != code || now > expiresAt)
            return (false, null);

        // Delete used OTP
        await _dynamoDb.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = OtpTable,
            Key = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } }
            }
        });

        // Get user ID
        var userResponse = await _dynamoDb.GetItemAsync(new GetItemRequest
        {
            TableName = UsersTable,
            Key = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } }
            }
        });

        var userId = userResponse.Item?["UserId"]?.S;
        return (true, userId);
    }

    public async Task<bool> UserExistsAsync(string email)
    {
        var response = await _dynamoDb.GetItemAsync(new GetItemRequest
        {
            TableName = UsersTable,
            Key = new Dictionary<string, AttributeValue>
            {
                { "Email", new AttributeValue { S = email.ToLowerInvariant() } }
            },
            ProjectionExpression = "Email"
        });

        return response.Item != null && response.Item.Count > 0;
    }

    private static string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100000, HashAlgorithmName.SHA256, 32);
        return $"{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }

    private static bool VerifyPassword(string password, string storedHash)
    {
        var parts = storedHash.Split(':');
        if (parts.Length != 2) return false;

        var salt = Convert.FromBase64String(parts[0]);
        var expectedHash = Convert.FromBase64String(parts[1]);
        var actualHash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100000, HashAlgorithmName.SHA256, 32);

        return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
    }
}
