using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Moq;
using tour_of_heroes_api.Controllers;
using Xunit;

namespace tour_of_heroes_api.tests;

public class RootControllerTests
{
    private readonly Mock<IWebHostEnvironment> _mockEnvironment;
    private readonly Mock<IConfiguration> _mockConfiguration;
    private readonly RootController _controller;

    public RootControllerTests()
    {
        _mockEnvironment = new Mock<IWebHostEnvironment>();
        _mockConfiguration = new Mock<IConfiguration>();
        
        _mockEnvironment.Setup(e => e.EnvironmentName).Returns("Development");
        _mockConfiguration.Setup(c => c["DATABASE_PROVIDER"]).Returns("SqlServer");
        
        _controller = new RootController(_mockEnvironment.Object, _mockConfiguration.Object);
    }

    [Fact]
    public void Get_ReturnsOkResult_WithApiInfo()
    {
        // Act
        var result = _controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.Equal("Tour of Heroes API", apiInfo.Name);
        Assert.Equal("1.0.0", apiInfo.Version);
        Assert.Equal("healthy", apiInfo.Status);
    }

    [Fact]
    public void Get_ReturnsCorrectEnvironment()
    {
        // Act
        var result = _controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.Equal("Development", apiInfo.Environment);
    }

    [Fact]
    public void Get_ReturnsCorrectDatabaseProvider()
    {
        // Act
        var result = _controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.Equal("SqlServer", apiInfo.DatabaseProvider);
    }

    [Fact]
    public void Get_ReturnsCorrectEndpoints()
    {
        // Act
        var result = _controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.Equal("/api/heroes", apiInfo.Endpoints.Heroes);
        Assert.Equal("/api/health", apiInfo.Endpoints.Health);
        Assert.Equal("/swagger", apiInfo.Endpoints.Swagger);
        Assert.Equal("/metrics", apiInfo.Endpoints.Metrics);
    }

    [Fact]
    public void Get_ReturnsTimestamp_NotDefault()
    {
        // Act
        var result = _controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.NotEqual(default, apiInfo.Timestamp);
        Assert.True(apiInfo.Timestamp <= DateTime.UtcNow);
    }

    [Fact]
    public void Get_WhenDatabaseProviderNotSet_ReturnsDefaultSqlServer()
    {
        // Arrange
        var mockConfig = new Mock<IConfiguration>();
        mockConfig.Setup(c => c["DATABASE_PROVIDER"]).Returns((string?)null);
        var controller = new RootController(_mockEnvironment.Object, mockConfig.Object);

        // Act
        var result = controller.Get();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var apiInfo = Assert.IsType<ApiInfo>(okResult.Value);
        
        Assert.Equal("SqlServer", apiInfo.DatabaseProvider);
    }
}
