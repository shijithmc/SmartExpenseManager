using System.ComponentModel.DataAnnotations;

namespace SmartExpenseManager.Api.Models;

public class SignUpRequest
{
    [Required(ErrorMessage = "Email is required")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Name is required")]
    public string Name { get; set; } = string.Empty;
}

public class SignInRequest
{
    [Required(ErrorMessage = "Email is required")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required")]
    public string Password { get; set; } = string.Empty;
}

public class ConfirmSignUpRequest
{
    [Required]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string ConfirmationCode { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}
