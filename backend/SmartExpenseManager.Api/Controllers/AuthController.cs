using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAmazonCognitoIdentityProvider _cognitoClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAmazonCognitoIdentityProvider cognitoClient, IConfiguration configuration, ILogger<AuthController> logger)
    {
        _cognitoClient = cognitoClient;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpPost("signup")]
    public async Task<IActionResult> SignUp([FromBody] Models.SignUpRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        try
        {
            var clientId = _configuration["AWS:Cognito:ClientId"];

            var cognitoSignUpRequest = new Amazon.CognitoIdentityProvider.Model.SignUpRequest
            {
                ClientId = clientId,
                Username = request.Email,
                Password = request.Password,
                UserAttributes =
                [
                    new AttributeType { Name = "email", Value = request.Email },
                    new AttributeType { Name = "name", Value = request.Name }
                ]
            };

            var response = await _cognitoClient.SignUpAsync(cognitoSignUpRequest);
            return Ok(new { message = "User registered. Please check email for confirmation code.", userId = response.UserSub });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Sign up failed for {Email}", request.Email);
            return BadRequest(new { error = "Registration failed. Please try again." });
        }
    }

    [HttpPost("confirm")]
    public async Task<IActionResult> ConfirmSignUp([FromBody] Models.ConfirmSignUpRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        try
        {
            var clientId = _configuration["AWS:Cognito:ClientId"];
            await _cognitoClient.ConfirmSignUpAsync(new Amazon.CognitoIdentityProvider.Model.ConfirmSignUpRequest
            {
                ClientId = clientId,
                Username = request.Email,
                ConfirmationCode = request.ConfirmationCode
            });

            return Ok(new { message = "Email confirmed successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Confirm sign up failed for {Email}", request.Email);
            return BadRequest(new { error = "Confirmation failed. Please check your code and try again." });
        }
    }

    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        // Demo user login
        var demoUsername = _configuration["DemoUser:Username"];
        var demoPassword = _configuration["DemoUser:Password"];

        if (request.Email == demoUsername && request.Password == demoPassword)
        {
            var token = GenerateDemoJwt(demoUsername);
            return Ok(new AuthResponse
            {
                Token = token,
                RefreshToken = "demo-refresh-token",
                UserId = "demo-user-mc",
                Email = demoUsername
            });
        }

        // Cognito login
        try
        {
            var clientId = _configuration["AWS:Cognito:ClientId"];
            var userPoolId = _configuration["AWS:Cognito:UserPoolId"];

            if (string.IsNullOrEmpty(clientId) || clientId == "YOUR_CLIENT_ID")
                return Unauthorized(new { error = "Invalid credentials" });

            var authRequest = new AdminInitiateAuthRequest
            {
                UserPoolId = userPoolId,
                ClientId = clientId,
                AuthFlow = AuthFlowType.ADMIN_USER_PASSWORD_AUTH,
                AuthParameters = new Dictionary<string, string>
                {
                    { "USERNAME", request.Email },
                    { "PASSWORD", request.Password }
                }
            };

            var response = await _cognitoClient.AdminInitiateAuthAsync(authRequest);
            return Ok(new AuthResponse
            {
                Token = response.AuthenticationResult.IdToken,
                RefreshToken = response.AuthenticationResult.RefreshToken,
                UserId = request.Email,
                Email = request.Email
            });
        }
        catch (NotAuthorizedException)
        {
            return Unauthorized(new { error = "Invalid credentials" });
        }
        catch (UserNotFoundException)
        {
            return Unauthorized(new { error = "Invalid credentials" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Sign in failed for {Email}", request.Email);
            return Unauthorized(new { error = "Invalid credentials" });
        }
    }

    private string GenerateDemoJwt(string username)
    {
        var signingKey = _configuration["Jwt:SigningKey"]!;
        var issuer = _configuration["Jwt:Issuer"];
        var audience = _configuration["Jwt:Audience"];

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, "demo-user-mc"),
            new Claim(JwtRegisteredClaimNames.Email, username),
            new Claim(ClaimTypes.NameIdentifier, "demo-user-mc"),
            new Claim("name", "MC Demo User"),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
