using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Services;

public class AICategorizeService : IAICategorizeService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<AICategorizeService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public AICategorizeService(IConfiguration configuration, ILogger<AICategorizeService> logger, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<AICategorizeResponse> CategorizeExpenseAsync(string description, decimal? amount = null)
    {
        var apiKey = _configuration["Anthropic:ApiKey"];
        if (string.IsNullOrEmpty(apiKey) || apiKey == "YOUR_ANTHROPIC_API_KEY")
        {
            _logger.LogWarning("Anthropic API key not configured, using rule-based categorization");
            return RuleBasedCategorize(description);
        }

        try
        {
            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("x-api-key", apiKey);
            client.DefaultRequestHeaders.Add("anthropic-version", "2023-06-01");

            var amountText = amount.HasValue ? $"Amount: ${amount.Value}" : "";
            var prompt = "Categorize this expense into exactly one of these categories:\n" +
                "Food & Dining, Transportation, Shopping, Bills & Utilities, Entertainment, Healthcare, Travel, Education, Personal, Other\n\n" +
                $"Expense description: \"{description}\"\n" +
                amountText + "\n\n" +
                "Respond with ONLY a JSON object (no markdown, no code blocks) in this format:\n" +
                "{\"category\": \"category name\", \"confidence\": 0.95, \"reasoning\": \"brief reason\"}";

            var requestBody = new
            {
                model = "claude-haiku-4-5-20251001",
                max_tokens = 150,
                messages = new[] { new { role = "user", content = prompt } }
            };

            var content = new StringContent(
                JsonSerializer.Serialize(requestBody),
                Encoding.UTF8,
                "application/json");

            var response = await client.PostAsync("https://api.anthropic.com/v1/messages", content);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);
            var text = doc.RootElement
                .GetProperty("content")[0]
                .GetProperty("text")
                .GetString() ?? string.Empty;

            text = text.Trim();
            if (text.StartsWith("```"))
            {
                var lines = text.Split('\n');
                text = string.Join('\n', lines.Skip(1));
                text = text.TrimEnd('`').Trim();
            }

            var result = JsonSerializer.Deserialize<AICategorizeResponse>(text, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            return result ?? RuleBasedCategorize(description);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to categorize via AI, falling back to rule-based");
            return RuleBasedCategorize(description);
        }
    }

    private static AICategorizeResponse RuleBasedCategorize(string description)
    {
        var desc = description.ToLowerInvariant();
        var (category, confidence) = desc switch
        {
            _ when desc.Contains("food") || desc.Contains("restaurant") || desc.Contains("lunch") || desc.Contains("dinner") || desc.Contains("breakfast") || desc.Contains("coffee") || desc.Contains("grocery") => ("Food & Dining", 0.7),
            _ when desc.Contains("uber") || desc.Contains("lyft") || desc.Contains("taxi") || desc.Contains("gas") || desc.Contains("fuel") || desc.Contains("bus") || desc.Contains("train") || desc.Contains("metro") => ("Transportation", 0.7),
            _ when desc.Contains("amazon") || desc.Contains("shop") || desc.Contains("store") || desc.Contains("buy") || desc.Contains("purchase") || desc.Contains("mall") => ("Shopping", 0.6),
            _ when desc.Contains("electric") || desc.Contains("water") || desc.Contains("internet") || desc.Contains("phone") || desc.Contains("bill") || desc.Contains("rent") || desc.Contains("insurance") => ("Bills & Utilities", 0.7),
            _ when desc.Contains("movie") || desc.Contains("netflix") || desc.Contains("spotify") || desc.Contains("game") || desc.Contains("concert") || desc.Contains("entertainment") => ("Entertainment", 0.7),
            _ when desc.Contains("doctor") || desc.Contains("hospital") || desc.Contains("pharmacy") || desc.Contains("medicine") || desc.Contains("health") || desc.Contains("dental") => ("Healthcare", 0.7),
            _ when desc.Contains("flight") || desc.Contains("hotel") || desc.Contains("travel") || desc.Contains("airbnb") || desc.Contains("booking") => ("Travel", 0.7),
            _ when desc.Contains("course") || desc.Contains("book") || desc.Contains("tuition") || desc.Contains("school") || desc.Contains("education") || desc.Contains("training") => ("Education", 0.6),
            _ => ("Other", 0.3)
        };

        return new AICategorizeResponse
        {
            Category = category,
            Confidence = confidence,
            Reasoning = "Categorized using keyword matching (AI unavailable)"
        };
    }
}
