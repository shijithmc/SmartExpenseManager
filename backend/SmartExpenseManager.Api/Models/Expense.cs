namespace SmartExpenseManager.Api.Models;

public class Expense
{
    public string UserId { get; set; } = string.Empty;
    public string ExpenseId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool AICategorized { get; set; }
    public string? Notes { get; set; }
}
