using System.Text;
using Amazon.DynamoDBv2;
using Amazon.CognitoIdentityProvider;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SmartExpenseManager.Api.Middleware;
using SmartExpenseManager.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add AWS Lambda hosting support
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

// Add AWS services
builder.Services.AddSingleton<IAmazonDynamoDB>(sp =>
{
    var config = new AmazonDynamoDBConfig
    {
        RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(
            builder.Configuration["AWS:Region"] ?? "us-east-1")
    };
    return new AmazonDynamoDBClient(config);
});

builder.Services.AddSingleton<IAmazonCognitoIdentityProvider>(sp =>
{
    var config = new AmazonCognitoIdentityProviderConfig
    {
        RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(
            builder.Configuration["AWS:Region"] ?? "us-east-1")
    };
    return new AmazonCognitoIdentityProviderClient(config);
});

// Add application services
builder.Services.AddHttpClient();
builder.Services.AddScoped<IDynamoDbService, DynamoDbService>();
builder.Services.AddScoped<IAICategorizeService, AICategorizeService>();

// JWT Authentication - support both Cognito and demo tokens
var cognitoRegion = builder.Configuration["AWS:Region"] ?? "us-east-1";
var cognitoUserPoolId = builder.Configuration["AWS:Cognito:UserPoolId"] ?? "";
var cognitoAuthority = $"https://cognito-idp.{cognitoRegion}.amazonaws.com/{cognitoUserPoolId}";
var jwtSigningKey = builder.Configuration["Jwt:SigningKey"] ?? "";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "SmartExpenseManager";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "SmartExpenseManager";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Support both Cognito and self-signed demo tokens
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuers = [cognitoAuthority, jwtIssuer],
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey))
        };

        // For Cognito tokens, also try OIDC discovery
        options.Authority = cognitoAuthority;
        options.RequireHttpsMetadata = false;

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                // If Cognito validation fails, try local key validation
                if (context.Exception is SecurityTokenSignatureKeyNotFoundException)
                {
                    context.NoResult();
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// Add controllers and Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseMiddleware<GlobalExceptionHandler>();
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
