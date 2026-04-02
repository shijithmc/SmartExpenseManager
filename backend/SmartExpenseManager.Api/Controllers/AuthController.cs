using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Microsoft.AspNetCore.Mvc;
using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAmazonCognitoIdentityProvider _cognitoClient;
    private readonly IConfiguration _configuration;

    public AuthController(IAmazonCognitoIdentityProvider cognitoClient, IConfiguration configuration)
    {
        _cognitoClient = cognitoClient;
        _configuration = configuration;
    }

    [HttpPost("signup")]
    public async Task<IActionResult> SignUp([FromBody] Models.SignUpRequest request)
    {
        var clientId = _configuration["AWS:Cognito:ClientId"];

        var cognitoSignUpRequest = new Amazon.CognitoIdentityProvider.Model.SignUpRequest
        {
            ClientId = clientId,
            Username = request.Email,
            Password = request.Password,
            UserAttributes =
            [
                new AttributeType { Name = "email", Value = request.Email },
                new AttributeType { Name = "name", Value = request.Name }
            ]
        };

        var response = await _cognitoClient.SignUpAsync(cognitoSignUpRequest);
        return Ok(new { message = "User registered. Please check email for confirmation code.", userId = response.UserSub });
    }

    [HttpPost("confirm")]
    public async Task<IActionResult> ConfirmSignUp([FromBody] Models.ConfirmSignUpRequest request)
    {
        var clientId = _configuration["AWS:Cognito:ClientId"];
        await _cognitoClient.ConfirmSignUpAsync(new Amazon.CognitoIdentityProvider.Model.ConfirmSignUpRequest
        {
            ClientId = clientId,
            Username = request.Email,
            ConfirmationCode = request.ConfirmationCode
        });

        return Ok(new { message = "Email confirmed successfully" });
    }

    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
    {
        var clientId = _configuration["AWS:Cognito:ClientId"];
        var userPoolId = _configuration["AWS:Cognito:UserPoolId"];

        var authRequest = new AdminInitiateAuthRequest
        {
            UserPoolId = userPoolId,
            ClientId = clientId,
            AuthFlow = AuthFlowType.ADMIN_USER_PASSWORD_AUTH,
            AuthParameters = new Dictionary<string, string>
            {
                { "USERNAME", request.Email },
                { "PASSWORD", request.Password }
            }
        };

        var response = await _cognitoClient.AdminInitiateAuthAsync(authRequest);
        return Ok(new AuthResponse
        {
            Token = response.AuthenticationResult.IdToken,
            RefreshToken = response.AuthenticationResult.RefreshToken,
            UserId = request.Email,
            Email = request.Email
        });
    }
}
