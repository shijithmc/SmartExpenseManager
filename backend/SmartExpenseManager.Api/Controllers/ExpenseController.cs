using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartExpenseManager.Api.Models;
using SmartExpenseManager.Api.Services;
using System.Security.Claims;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ExpenseController : ControllerBase
{
    private readonly IDynamoDbService _dynamoDbService;
    private readonly IAICategorizeService _aiService;

    public ExpenseController(IDynamoDbService dynamoDbService, IAICategorizeService aiService)
    {
        _dynamoDbService = dynamoDbService;
        _aiService = aiService;
    }

    private string GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst("sub")?.Value
        ?? throw new UnauthorizedAccessException();

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
        if (expense == null) return NotFound();
        return Ok(expense);
    }

    [HttpPost]
    public async Task<ActionResult<Expense>> Create([FromBody] CreateExpenseRequest request)
    {
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
        var expense = await _dynamoDbService.UpdateExpenseAsync(GetUserId(), expenseId, request);
        return Ok(expense);
    }

    [HttpDelete("{expenseId}")]
    public async Task<IActionResult> Delete(string expenseId)
    {
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
