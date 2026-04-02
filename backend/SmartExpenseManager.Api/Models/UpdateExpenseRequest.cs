namespace SmartExpenseManager.Api.Models;

public class UpdateExpenseRequest
{
    public decimal? Amount { get; set; }
    public string? Description { get; set; }
    public string? Category { get; set; }
    public DateTime? Date { get; set; }
    public string? Notes { get; set; }
}
