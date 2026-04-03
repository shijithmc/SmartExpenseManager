namespace SmartExpenseManager.Api.Services;

public interface IUserService
{
    Task<(bool Success, string? Error)> SignUpAsync(string email, string password, string name);
    Task<(bool Valid, string? UserId)> ValidatePasswordAsync(string email, string password);
    Task<(string Code, string? Error)> GenerateOtpAsync(string email);
    Task<(bool Valid, string? UserId)> VerifyOtpAsync(string email, string code);
    Task<bool> UserExistsAsync(string email);
}
