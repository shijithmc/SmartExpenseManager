using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartExpenseManager.Api.Models;
using SmartExpenseManager.Api.Services;
using System.Security.Claims;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public partial class ExpenseController : ControllerBase
{
    private readonly IDynamoDbService _dynamoDbService;
    private readonly IAICategorizeService _aiService;

    private static readonly HashSet<string> ValidCategories = new(StringComparer.OrdinalIgnoreCase)
    {
        "Food & Dining", "Transportation", "Shopping", "Bills & Utilities",
        "Entertainment", "Healthcare", "Travel", "Education", "Personal", "Other"
    };

    public ExpenseController(IDynamoDbService dynamoDbService, IAICategorizeService aiService)
    {
        _dynamoDbService = dynamoDbService;
        _aiService = aiService;
    }

    private string GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst("sub")?.Value
        ?? throw new UnauthorizedAccessException();

    private static string Sanitize(string input) =>
        HtmlTagRegex().Replace(input, string.Empty).Trim();

    [GeneratedRegex("<[^>]*>")]
    private static partial Regex HtmlTagRegex();

    [HttpGet]
    public async Task<ActionResult<List<Expense>>> GetAll()
    {
        var expenses = await _dynamoDbService.GetExpensesAsync(GetUserId());
        return Ok(expenses);
    }

    [HttpGet("{expenseId}")]
    public async Task<ActionResult<Expense>> GetById(string expenseId)
    {
        var expense = await _dynamoDbService.GetExpenseAsync(GetUserId(), expenseId);
        if (expense == null) return NotFound(new { error = "Expense not found" });
        return Ok(expense);
    }

    [HttpPost]
    public async Task<ActionResult<Expense>> Create([FromBody] CreateExpenseRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        // Sanitize text inputs
        request.Description = Sanitize(request.Description);
        if (string.IsNullOrWhiteSpace(request.Description))
            return BadRequest(new { error = "Description cannot be empty after sanitization" });

        if (request.Notes != null)
            request.Notes = Sanitize(request.Notes);

        // Validate date is not in the future
        if (request.Date.Date > DateTime.UtcNow.Date.AddDays(1))
            return BadRequest(new { error = "Expense date cannot be in the future" });

        // Validate category if provided
        if (request.Category != null && !ValidCategories.Contains(request.Category))
            return BadRequest(new { error = $"Invalid category. Valid categories: {string.Join(", ", ValidCategories)}" });

        string? aiCategory = null;
        if (request.AutoCategorize)
        {
            var result = await _aiService.CategorizeExpenseAsync(request.Description, request.Amount);
            aiCategory = result.Category;
        }

        var expense = await _dynamoDbService.CreateExpenseAsync(GetUserId(), request, aiCategory);
        return CreatedAtAction(nameof(GetById), new { expenseId = expense.ExpenseId }, expense);
    }

    [HttpPut("{expenseId}")]
    public async Task<ActionResult<Expense>> Update(string expenseId, [FromBody] UpdateExpenseRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        // Check expense exists
        var existing = await _dynamoDbService.GetExpenseAsync(GetUserId(), expenseId);
        if (existing == null) return NotFound(new { error = "Expense not found" });

        // Sanitize text inputs
        if (request.Description != null)
        {
            request.Description = Sanitize(request.Description);
            if (string.IsNullOrWhiteSpace(request.Description))
                return BadRequest(new { error = "Description cannot be empty after sanitization" });
        }
        if (request.Notes != null)
            request.Notes = Sanitize(request.Notes);

        // Validate date
        if (request.Date.HasValue && request.Date.Value.Date > DateTime.UtcNow.Date.AddDays(1))
            return BadRequest(new { error = "Expense date cannot be in the future" });

        // Validate category
        if (request.Category != null && !ValidCategories.Contains(request.Category))
            return BadRequest(new { error = $"Invalid category. Valid categories: {string.Join(", ", ValidCategories)}" });

        var expense = await _dynamoDbService.UpdateExpenseAsync(GetUserId(), expenseId, request);
        return Ok(expense);
    }

    [HttpDelete("{expenseId}")]
    public async Task<IActionResult> Delete(string expenseId)
    {
        var existing = await _dynamoDbService.GetExpenseAsync(GetUserId(), expenseId);
        if (existing == null) return NotFound(new { error = "Expense not found" });

        await _dynamoDbService.DeleteExpenseAsync(GetUserId(), expenseId);
        return NoContent();
    }

    [HttpGet("by-date")]
    public async Task<ActionResult<List<Expense>>> GetByDateRange([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
    {
        var expenses = await _dynamoDbService.GetExpensesByDateRangeAsync(GetUserId(), startDate, endDate);
        return Ok(expenses);
    }

    [HttpGet("by-category/{category}")]
    public async Task<ActionResult<List<Expense>>> GetByCategory(string category)
    {
        var expenses = await _dynamoDbService.GetExpensesByCategoryAsync(GetUserId(), category);
        return Ok(expenses);
    }

    [HttpGet("summary")]
    public async Task<ActionResult> GetSummary([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
    {
        var start = startDate ?? new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
        var end = endDate ?? DateTime.UtcNow;
        var expenses = await _dynamoDbService.GetExpensesByDateRangeAsync(GetUserId(), start, end);

        var summary = new
        {
            TotalExpenses = expenses.Sum(e => e.Amount),
            ExpenseCount = expenses.Count,
            ByCategory = expenses.GroupBy(e => e.Category).Select(g => new
            {
                Category = g.Key,
                Total = g.Sum(e => e.Amount),
                Count = g.Count()
            }).OrderByDescending(x => x.Total),
            StartDate = start,
            EndDate = end
        };

        return Ok(summary);
    }
}
