namespace SmartExpenseManager.Api.Models;

public class CreateExpenseRequest
{
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? Category { get; set; }
    public DateTime Date { get; set; }
    public string? Notes { get; set; }
    public bool AutoCategorize { get; set; }
}
