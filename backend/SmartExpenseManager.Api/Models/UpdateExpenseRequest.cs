using System.ComponentModel.DataAnnotations;

namespace SmartExpenseManager.Api.Models;

public class UpdateExpenseRequest
{
    [Range(0.01, 10000000, ErrorMessage = "Amount must be between 0.01 and 10,000,000")]
    public decimal? Amount { get; set; }

    [StringLength(500, MinimumLength = 1)]
    public string? Description { get; set; }

    public string? Category { get; set; }

    public DateTime? Date { get; set; }

    [StringLength(1000)]
    public string? Notes { get; set; }
}
