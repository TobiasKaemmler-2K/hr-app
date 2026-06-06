using HrApp.Api.Data;
using HrApp.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace HrApp.Api.Services;

public interface IAuditLogService
{
    Task LogAsync(string actionType, string? actionDetails, Guid? userId, string? ipAddress);
}

public class AuditLogService : IAuditLogService
{
    private readonly AppDbContext _context;
    private const int MaxAuditLogEntries = 1000;

    public AuditLogService(AppDbContext context)
    {
        _context = context;
    }

    public async Task LogAsync(string actionType, string? actionDetails, Guid? userId, string? ipAddress)
    {
        var auditLog = new AuditLog
        {
            Id = Guid.NewGuid(),
            ActionType = actionType,
            ActionDetails = actionDetails,
            UserId = userId,
            IpAddress = ipAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.AuditLogs.Add(auditLog);
        await _context.SaveChangesAsync();

        // Cleanup: Wenn mehr als MaxAuditLogEntries Einträge existieren, die ältesten löschen
        var count = await _context.AuditLogs.CountAsync();
        if (count > MaxAuditLogEntries)
        {
            var entriesToDelete = count - MaxAuditLogEntries;
            var oldestEntries = await _context.AuditLogs
                .OrderBy(x => x.CreatedAt)
                .Take(entriesToDelete)
                .ToListAsync();

            _context.AuditLogs.RemoveRange(oldestEntries);
            await _context.SaveChangesAsync();
        }
    }
}
