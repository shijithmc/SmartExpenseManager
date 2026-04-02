using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Services;

public interface IAICategorizeService
{
    Task<AICategorizeResponse> CategorizeExpenseAsync(string description, decimal? amount = null);
}
