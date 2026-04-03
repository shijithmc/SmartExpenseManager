using System.Text;
using Amazon.DynamoDBv2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SmartExpenseManager.Api.Middleware;
using SmartExpenseManager.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add AWS Lambda hosting support
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

// Add AWS DynamoDB
builder.Services.AddSingleton<IAmazonDynamoDB>(sp =>
{
    var config = new AmazonDynamoDBConfig
    {
        RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(
            builder.Configuration["AWS:Region"] ?? "us-east-1")
    };
    return new AmazonDynamoDBClient(config);
});

// Add application services
builder.Services.AddHttpClient();
builder.Services.AddScoped<IDynamoDbService, DynamoDbService>();
builder.Services.AddScoped<IAICategorizeService, AICategorizeService>();
builder.Services.AddScoped<IUserService, UserService>();

// JWT Authentication
var jwtSigningKey = builder.Configuration["Jwt:SigningKey"] ?? "";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "SmartExpenseManager";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "SmartExpenseManager";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey))
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
