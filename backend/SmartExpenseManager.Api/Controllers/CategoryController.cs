using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartExpenseManager.Api.Models;

namespace SmartExpenseManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CategoryController : ControllerBase
{
    private static readonly List<Category> DefaultCategories =
    [
        new() { Name = "Food & Dining", Icon = "restaurant", Color = "#FF6B6B" },
        new() { Name = "Transportation", Icon = "directions_car", Color = "#4ECDC4" },
        new() { Name = "Shopping", Icon = "shopping_bag", Color = "#45B7D1" },
        new() { Name = "Bills & Utilities", Icon = "receipt_long", Color = "#96CEB4" },
        new() { Name = "Entertainment", Icon = "movie", Color = "#FFEAA7" },
        new() { Name = "Healthcare", Icon = "local_hospital", Color = "#DDA0DD" },
        new() { Name = "Travel", Icon = "flight", Color = "#98D8C8" },
        new() { Name = "Education", Icon = "school", Color = "#F7DC6F" },
        new() { Name = "Personal", Icon = "person", Color = "#BB8FCE" },
        new() { Name = "Other", Icon = "more_horiz", Color = "#AEB6BF" }
    ];

    [HttpGet]
    public ActionResult<List<Category>> GetAll()
    {
        return Ok(DefaultCategories);
    }
}
