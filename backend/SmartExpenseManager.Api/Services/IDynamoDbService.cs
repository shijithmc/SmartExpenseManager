using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Services;

public interface IDynamoDbService
{
    Task<List<Expense>> GetExpensesAsync(string userId);
    Task<Expense?> GetExpenseAsync(string userId, string expenseId);
    Task<Expense> CreateExpenseAsync(string userId, CreateExpenseRequest request, string? aiCategory = null);
    Task<Expense> UpdateExpenseAsync(string userId, string expenseId, UpdateExpenseRequest request);
    Task DeleteExpenseAsync(string userId, string expenseId);
    Task<List<Expense>> GetExpensesByDateRangeAsync(string userId, DateTime startDate, DateTime endDate);
    Task<List<Expense>> GetExpensesByCategoryAsync(string userId, string category);
}
