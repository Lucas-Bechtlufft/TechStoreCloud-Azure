using Microsoft.EntityFrameworkCore;
using ProductApi.Data;

var builder = WebApplication.CreateBuilder(args);

// log no console -> no Linux o systemd manda isso pro journal/syslog,
// e o Azure Monitor Agent leva pro Log Analytics
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Application Insights e opcional: so liga se a connection string existir como variavel de ambiente
if (!string.IsNullOrWhiteSpace(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    builder.Services.AddApplicationInsightsTelemetry();
}

// a string de conexao vem do appsettings ou de variavel de ambiente
// (na VM eu passo por variavel, assim a senha do banco nao fica no codigo)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// CORS liberado pro site estatico (Blob Storage) conseguir chamar a API
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// deixei o Swagger ligado sempre, e o que uso pra demonstrar a API no MVP
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("FrontendPolicy");
app.UseAuthorization();
app.MapControllers();

// healthcheck simples, ajuda a confirmar que a VM subiu certo antes de testar o resto
app.MapGet("/health", () => Results.Ok(new { status = "ok", timestamp = DateTime.UtcNow }));

app.Run();
