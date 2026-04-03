using System.ComponentModel.DataAnnotations;

namespace SmartExpenseManager.Api.Models;

public class CreateExpenseRequest
{
    [Required]
    [Range(0.01, 10000000, ErrorMessage = "Amount must be between 0.01 and 10,000,000")]
    public decimal Amount { get; set; }

    [Required(AllowEmptyStrings = false, ErrorMessage = "Description is required")]
    [StringLength(500, MinimumLength = 1)]
    public string Description { get; set; } = string.Empty;

    public string? Category { get; set; }

    [Required]
    public DateTime Date { get; set; }

    [StringLength(1000)]
    public string? Notes { get; set; }

    public bool AutoCategorize { get; set; }
}
