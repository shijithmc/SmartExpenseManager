using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using SmartExpenseManager.Api.Models;
using SmartExpenseManager.Api.Services;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IUserService userService, IConfiguration configuration, ILogger<AuthController> logger)
    {
        _userService = userService;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpPost("signup")]
    public async Task<IActionResult> SignUp([FromBody] SignUpRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        var (success, error) = await _userService.SignUpAsync(
            request.Email, request.Password, request.Name);

        if (!success)
            return BadRequest(new { error });

        return Ok(new { message = "Account created successfully! You can now sign in." });
    }

    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        // Demo user login (MC/MC)
        var demoUsername = _configuration["DemoUser:Username"];
        var demoPassword = _configuration["DemoUser:Password"];
        if (request.Email == demoUsername && request.Password == demoPassword)
            return Ok(GenerateAuthResponse("demo-user-mc", demoUsername!));

        // Dev user login (dev/dev)
        if (request.Email == "dev" && request.Password == "dev")
            return Ok(GenerateAuthResponse("dev-user", "dev@smartexpense.local"));

        // DynamoDB user login
        var (valid, userId) = await _userService.ValidatePasswordAsync(request.Email, request.Password);
        if (!valid)
            return Unauthorized(new { error = "Invalid email or password" });

        return Ok(GenerateAuthResponse(userId!, request.Email));
    }

    [HttpPost("request-otp")]
    public async Task<IActionResult> RequestOtp([FromBody] OtpRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        var (code, error) = await _userService.GenerateOtpAsync(request.Email);
        if (!string.IsNullOrEmpty(error))
            return BadRequest(new { error });

        // In production, send via email/SMS. For demo, return in response.
        return Ok(new
        {
            message = "OTP sent successfully",
            otp = code // Remove this in production — only for demo
        });
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyRequest request)
    {
        if (!ModelState.IsValid) return ValidationProblem();

        var (valid, userId) = await _userService.VerifyOtpAsync(request.Email, request.Code);
        if (!valid)
            return Unauthorized(new { error = "Invalid or expired OTP code" });

        return Ok(GenerateAuthResponse(userId!, request.Email));
    }

    private AuthResponse GenerateAuthResponse(string userId, string email)
    {
        return new AuthResponse
        {
            Token = GenerateJwt(userId, email),
            RefreshToken = Guid.NewGuid().ToString(),
            UserId = userId,
            Email = email
        };
    }

    private string GenerateJwt(string userId, string email)
    {
        var signingKey = _configuration["Jwt:SigningKey"]!;
        var issuer = _configuration["Jwt:Issuer"];
        var audience = _configuration["Jwt:Audience"];

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
