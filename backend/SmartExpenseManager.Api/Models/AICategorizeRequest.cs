namespace SmartExpenseManager.Api.Models;

public class AICategorizeRequest
{
    public string Description { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
}

public class AICategorizeResponse
{
    public string Category { get; set; } = string.Empty;
    public double Confidence { get; set; }
    public string Reasoning { get; set; } = string.Empty;
}
