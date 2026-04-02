using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Services;

public class DynamoDbService : IDynamoDbService
{
    private readonly IAmazonDynamoDB _dynamoDb;
    private const string TableName = "SmartExpenseManager_Expenses";

    public DynamoDbService(IAmazonDynamoDB dynamoDb)
    {
        _dynamoDb = dynamoDb;
    }

    public async Task<List<Expense>> GetExpensesAsync(string userId)
    {
        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "UserId = :userId",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                { ":userId", new AttributeValue { S = userId } }
            },
            ScanIndexForward = false
        };

        var response = await _dynamoDb.QueryAsync(request);
        return response.Items.Select(MapToExpense).ToList();
    }

    public async Task<Expense?> GetExpenseAsync(string userId, string expenseId)
    {
        var request = new GetItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                { "UserId", new AttributeValue { S = userId } },
                { "ExpenseId", new AttributeValue { S = expenseId } }
            }
        };

        var response = await _dynamoDb.GetItemAsync(request);
        return response.Item.Count == 0 ? null : MapToExpense(response.Item);
    }

    public async Task<Expense> CreateExpenseAsync(string userId, CreateExpenseRequest request, string? aiCategory = null)
    {
        var expenseId = Guid.NewGuid().ToString();
        var now = DateTime.UtcNow;
        var category = aiCategory ?? request.Category ?? "Other";

        var item = new Dictionary<string, AttributeValue>
        {
            { "UserId", new AttributeValue { S = userId } },
            { "ExpenseId", new AttributeValue { S = expenseId } },
            { "Amount", new AttributeValue { N = request.Amount.ToString() } },
            { "Description", new AttributeValue { S = request.Description } },
            { "Category", new AttributeValue { S = category } },
            { "Date", new AttributeValue { S = request.Date.ToString("o") } },
            { "CreatedAt", new AttributeValue { S = now.ToString("o") } },
            { "AICategorized", new AttributeValue { BOOL = aiCategory != null } }
        };

        if (!string.IsNullOrEmpty(request.Notes))
            item["Notes"] = new AttributeValue { S = request.Notes };

        await _dynamoDb.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = item
        });

        return new Expense
        {
            UserId = userId,
            ExpenseId = expenseId,
            Amount = request.Amount,
            Description = request.Description,
            Category = category,
            Date = request.Date,
            CreatedAt = now,
            AICategorized = aiCategory != null,
            Notes = request.Notes
        };
    }

    public async Task<Expense> UpdateExpenseAsync(string userId, string expenseId, UpdateExpenseRequest request)
    {
        var updateExpressions = new List<string>();
        var expressionValues = new Dictionary<string, AttributeValue>();
        var expressionNames = new Dictionary<string, string>();

        if (request.Amount.HasValue)
        {
            updateExpressions.Add("#amt = :amount");
            expressionValues[":amount"] = new AttributeValue { N = request.Amount.Value.ToString() };
            expressionNames["#amt"] = "Amount";
        }
        if (request.Description != null)
        {
            updateExpressions.Add("Description = :desc");
            expressionValues[":desc"] = new AttributeValue { S = request.Description };
        }
        if (request.Category != null)
        {
            updateExpressions.Add("Category = :cat");
            expressionValues[":cat"] = new AttributeValue { S = request.Category };
        }
        if (request.Date.HasValue)
        {
            updateExpressions.Add("#dt = :date");
            expressionValues[":date"] = new AttributeValue { S = request.Date.Value.ToString("o") };
            expressionNames["#dt"] = "Date";
        }
        if (request.Notes != null)
        {
            updateExpressions.Add("Notes = :notes");
            expressionValues[":notes"] = new AttributeValue { S = request.Notes };
        }

        if (updateExpressions.Count == 0)
            return (await GetExpenseAsync(userId, expenseId))!;

        var updateRequest = new UpdateItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                { "UserId", new AttributeValue { S = userId } },
                { "ExpenseId", new AttributeValue { S = expenseId } }
            },
            UpdateExpression = "SET " + string.Join(", ", updateExpressions),
            ExpressionAttributeValues = expressionValues,
            ReturnValues = "ALL_NEW"
        };

        if (expressionNames.Count > 0)
            updateRequest.ExpressionAttributeNames = expressionNames;

        var response = await _dynamoDb.UpdateItemAsync(updateRequest);
        return MapToExpense(response.Attributes);
    }

    public async Task DeleteExpenseAsync(string userId, string expenseId)
    {
        await _dynamoDb.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                { "UserId", new AttributeValue { S = userId } },
                { "ExpenseId", new AttributeValue { S = expenseId } }
            }
        });
    }

    public async Task<List<Expense>> GetExpensesByDateRangeAsync(string userId, DateTime startDate, DateTime endDate)
    {
        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "UserId = :userId",
            FilterExpression = "#dt BETWEEN :start AND :end",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                { ":userId", new AttributeValue { S = userId } },
                { ":start", new AttributeValue { S = startDate.ToString("o") } },
                { ":end", new AttributeValue { S = endDate.ToString("o") } }
            },
            ExpressionAttributeNames = new Dictionary<string, string>
            {
                { "#dt", "Date" }
            }
        };

        var response = await _dynamoDb.QueryAsync(request);
        return response.Items.Select(MapToExpense).ToList();
    }

    public async Task<List<Expense>> GetExpensesByCategoryAsync(string userId, string category)
    {
        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "UserId = :userId",
            FilterExpression = "Category = :cat",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                { ":userId", new AttributeValue { S = userId } },
                { ":cat", new AttributeValue { S = category } }
            }
        };

        var response = await _dynamoDb.QueryAsync(request);
        return response.Items.Select(MapToExpense).ToList();
    }

    private static Expense MapToExpense(Dictionary<string, AttributeValue> item)
    {
        return new Expense
        {
            UserId = item.GetValueOrDefault("UserId")?.S ?? string.Empty,
            ExpenseId = item.GetValueOrDefault("ExpenseId")?.S ?? string.Empty,
            Amount = decimal.TryParse(item.GetValueOrDefault("Amount")?.N, out var amt) ? amt : 0,
            Description = item.GetValueOrDefault("Description")?.S ?? string.Empty,
            Category = item.GetValueOrDefault("Category")?.S ?? string.Empty,
            Date = DateTime.TryParse(item.GetValueOrDefault("Date")?.S, out var date) ? date : DateTime.MinValue,
            CreatedAt = DateTime.TryParse(item.GetValueOrDefault("CreatedAt")?.S, out var created) ? created : DateTime.MinValue,
            AICategorized = item.GetValueOrDefault("AICategorized")?.BOOL ?? false,
            Notes = item.GetValueOrDefault("Notes")?.S
        };
    }
}
