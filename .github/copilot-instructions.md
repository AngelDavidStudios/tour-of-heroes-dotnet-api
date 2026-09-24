# Tour of Heroes API - Copilot Instructions

## 🏗️ Architecture Overview

This is a **.NET 9 REST API** for managing heroes, designed for demos with flexible database support.

```
src/                    # Application code
├── Controllers/        # REST endpoints (HeroController, HealthController)
├── Models/             # EF Core entities + DbContext (Hero, HeroContext)
├── Repositories/       # Data access layer (HeroRepository)
├── Interfaces/         # Abstractions (IHeroRepository)
└── Program.cs          # DI, middleware, OpenTelemetry config

tests/                  # xUnit tests with Moq
infrastructure/         # Terraform for Azure deployment
build/docker/           # Dockerfile
```

## 🔐 Security First

You are a **cybersecurity-focused agent**. Every recommendation must include:
- Input validation and sanitization
- Secure configuration (no hardcoded secrets)
- Proper error handling without leaking internals
- All generated code must be tested and documented

## 🗄️ Database Provider Pattern

The API supports **SQL Server** and **PostgreSQL** via `DATABASE_PROVIDER` environment variable:

```csharp
// Pattern for selecting database provider
var provider = builder.Configuration["DATABASE_PROVIDER"] ?? "SqlServer";
builder.Services.AddDbContext<HeroContext>(opt =>
{
    if (provider.Equals("PostgreSQL", StringComparison.OrdinalIgnoreCase))
        opt.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSQL"));
    else
        opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"));
});
```

## 📁 Code Organization

| Type | Location | Example |
|------|----------|---------|
| Controllers | `src/Controllers/` | `HeroController.cs` |
| Models/Entities | `src/Models/` | `Hero.cs`, `HeroContext.cs` |
| Repositories | `src/Repositories/` | `HeroRepository.cs` |
| Interfaces | `src/Interfaces/` | `IHeroRepository.cs` |
| Tests | `tests/` | `HeroControllerTests.cs` |
| Terraform | `infrastructure/` | `main.tf` |

## ✍️ Naming Conventions

- **Classes/Methods**: PascalCase → `HeroController`, `GetAllHeroes()`
- **Variables/Parameters**: camelCase → `heroId`, `connectionString`
- **Interfaces**: Prefix with `I` → `IHeroRepository`
- **Files**: Match class name → `HeroController.cs`

## 🧪 Testing Pattern

Use **xUnit + Moq**. Always include happy and sad paths:

```csharp
public class HeroControllerTests
{
    private readonly Mock<IHeroRepository> _mockRepo;
    private readonly HeroController _controller;

    public HeroControllerTests()
    {
        _mockRepo = new Mock<IHeroRepository>();
        _controller = new HeroController(_mockRepo.Object);
    }

    [Fact]
    public void GetById_ExistingId_ReturnsHero() { /* happy path */ }

    [Fact]
    public void GetById_NonExistingId_ReturnsNotFound() { /* sad path */ }
}
```

Run tests: `dotnet test` from root or `tests/` directory.

## ⚠️ Pre-Commit Checklist

**ALWAYS before commit or push:**
1. 🏗️ **Build**: `dotnet build` - Verify compilation succeeds
2. 🧪 **Test**: `dotnet test` - Run ALL tests and verify they pass
3. ✅ **New tests**: Add unit tests for any new code (happy + sad paths)
4. 🔍 **Review**: Check for warnings or errors in build output

```bash
# Quick validation before commit
dotnet build && dotnet test
```

**Never commit code that:**
- ❌ Doesn't compile
- ❌ Has failing tests
- ❌ Lacks unit tests for new functionality

## 📝 Commit Messages

Use conventional commits with emojis:
- `feat: ✨ add PostgreSQL support`
- `fix: 🐛 correct CORS configuration`
- `docs: 📖 update README`
- `ci: 🔄 update workflow to .NET 9`
- `chore: 🔧 update dependencies`
- `refactor: ♻️ extract database factory`

Max 100 characters, be concise.

## 🌿 Branch Naming

Use standard prefixes:
- `feature/` → New features (`feature/add-postgresql-support`)
- `fix/` → Bug fixes (`fix/cors-configuration`)
- `docs/` → Documentation (`docs/update-readme`)
- `refactor/` → Code refactoring (`refactor/async-repository`)
- `ci/` → CI/CD changes (`ci/update-workflows`)

## 🛡️ Rate Limiting

The API uses ASP.NET Core Rate Limiting with Fixed Window policy:

```csharp
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("fixed", opt =>
    {
        opt.PermitLimit = 100;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 10;
    });
});

// Apply to controllers with attribute
[EnableRateLimiting("fixed")]
public class HeroController : ControllerBase
```

## 🔄 GitHub Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR to main | Build, test, coverage |
| `release.yml` | Tags `v*` | Create GitHub release |
| `github-packages-docker.yml` | Push to main | Build & push Docker image |
| `docker-scans.yml` | Push to main | Security scans (Trivy, Checkov, Grype) |
| `iac-scans.yml` | Changes to `infrastructure/` | Terraform security scans |

## 🐳 Running Locally

```bash
# Dev Container (recommended) - includes SQL Server
# Open in VS Code → "Reopen in Container"

# Or manually:
cd src && dotnet run

# API: http://localhost:5020
# Swagger: http://localhost:5020/swagger
# Metrics: http://localhost:5020/metrics
```

## 📊 Observability

OpenTelemetry is pre-configured. Key endpoints in dev container:
- **Jaeger**: http://localhost:16686
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000