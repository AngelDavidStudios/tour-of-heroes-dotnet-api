using Microsoft.AspNetCore.Mvc;

namespace tour_of_heroes_api.Controllers;

/// <summary>
/// Controller for the root endpoint providing API information.
/// </summary>
[ApiController]
[Route("/")]
public class RootController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;
    private readonly IConfiguration _configuration;

    public RootController(IWebHostEnvironment environment, IConfiguration configuration)
    {
        _environment = environment;
        _configuration = configuration;
    }

    /// <summary>
    /// Returns information about the API including name, version, status, and available endpoints.
    /// </summary>
    /// <returns>API information object</returns>
    [HttpGet]
    [ProducesResponseType(typeof(ApiInfo), StatusCodes.Status200OK)]
    public IActionResult Get()
    {
        var apiInfo = new ApiInfo
        {
            Name = "Tour of Heroes API",
            Version = "1.0.0",
            Status = "healthy",
            Environment = _environment.EnvironmentName,
            Timestamp = DateTime.UtcNow,
            DatabaseProvider = _configuration["DATABASE_PROVIDER"] ?? "SqlServer",
            Endpoints = new EndpointInfo
            {
                Heroes = "/api/heroes",
                Health = "/api/health",
                Swagger = "/swagger",
                Metrics = "/metrics"
            }
        };

        return Ok(apiInfo);
    }
}

/// <summary>
/// Represents API information returned by the root endpoint.
/// </summary>
public class ApiInfo
{
    public string Name { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public string DatabaseProvider { get; set; } = string.Empty;
    public EndpointInfo Endpoints { get; set; } = new();
}

/// <summary>
/// Represents available API endpoints.
/// </summary>
public class EndpointInfo
{
    public string Heroes { get; set; } = string.Empty;
    public string Health { get; set; } = string.Empty;
    public string Swagger { get; set; } = string.Empty;
    public string Metrics { get; set; } = string.Empty;
}
