using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartExpenseManager.Api.Models;
using SmartExpenseManager.Api.Services;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AIController : ControllerBase
{
    private readonly IAICategorizeService _aiService;

    public AIController(IAICategorizeService aiService)
    {
        _aiService = aiService;
    }

    [HttpPost("categorize")]
    public async Task<ActionResult<AICategorizeResponse>> Categorize([FromBody] AICategorizeRequest request)
    {
        var result = await _aiService.CategorizeExpenseAsync(request.Description, request.Amount);
        return Ok(result);
    }
}
