using System.Globalization;
using System.Security.Claims;
using HrApp.Api.Data;
using HrApp.Api.Entities;
using HrApp.Api.Enums;
using HrApp.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HrApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AbsencesController : ControllerBase
{
    private const int YearlyVacationAllowanceDays = 30;
    private readonly AppDbContext _dbContext;
    private readonly IAuditLogService _auditLogService;

    public AbsencesController(AppDbContext dbContext, IAuditLogService auditLogService)
    {
        _dbContext = dbContext;
        _auditLogService = auditLogService;
    }

    [HttpGet("my")]
    public async Task<ActionResult<IReadOnlyList<AbsenceRequestDto>>> GetMyAbsences()
    {
        var user = await GetCurrentUserAsync();
        if (user is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var absences = await _dbContext.AbsenceRequests
            .Include(x => x.AbsenceType)
            .Where(x => x.UserId == user.Id)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(absences.Select(MapAbsenceRequest).ToList());
    }

    [HttpGet("types")]
    public async Task<ActionResult<IReadOnlyList<AbsenceTypeDto>>> GetAbsenceTypes()
    {
        var types = await _dbContext.AbsenceTypes
            .Where(x => x.IsActive)
            .OrderBy(x => x.Name)
            .ToListAsync();

        return Ok(types.Select(MapAbsenceType).ToList());
    }

    [HttpPost]
    public async Task<ActionResult<AbsenceRequestDto>> CreateAbsence([FromBody] CreateAbsenceRequestDto request)
    {
        var user = await GetCurrentUserAsync();
        if (user is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (request.AbsenceTypeId == Guid.Empty)
        {
            return BadRequest(new { message = "Abwesenheitsart ist erforderlich." });
        }

        var startDate = ParseDateOnly(request.StartDate);
        var endDate = ParseDateOnly(request.EndDate);
        if (startDate is null || endDate is null)
        {
            return BadRequest(new { message = "Start- und Enddatum müssen gültig sein." });
        }

        if (endDate < startDate)
        {
            return BadRequest(new { message = "Enddatum muss nach dem Startdatum liegen." });
        }

        var absenceType = await _dbContext.AbsenceTypes
            .FirstOrDefaultAsync(x => x.Id == request.AbsenceTypeId && x.IsActive);

        if (absenceType is null)
        {
            return NotFound(new { message = "Abwesenheitsart nicht gefunden." });
        }

        if (string.Equals(absenceType.Name, "Urlaub", StringComparison.OrdinalIgnoreCase))
        {
            var requestWeekdays = CountWeekdaysInRange(startDate.Value, endDate.Value);
            if (requestWeekdays == 0)
            {
                return BadRequest(new { message = "Der gewählte Zeitraum enthält keine Urlaubstage (nur Montag bis Freitag zählen)." });
            }

            var alreadyBooked = await _dbContext.AbsenceRequests
                .Where(x => x.UserId == user.Id)
                .Where(x => x.AbsenceTypeId == absenceType.Id)
                .Where(x => x.Status == AbsenceStatus.PENDING.ToString() || x.Status == AbsenceStatus.APPROVED.ToString())
                .ToListAsync();

            var startYear = startDate.Value.Year;
            var endYear = endDate.Value.Year;

            for (var year = startYear; year <= endYear; year++)
            {
                var requestedDaysInYear = CountWeekdaysInYear(startDate.Value, endDate.Value, year);
                if (requestedDaysInYear == 0)
                {
                    continue;
                }

                var usedDaysInYear = alreadyBooked.Sum(x => CountWeekdaysInYear(x.StartDate, x.EndDate, year));
                var newTotal = usedDaysInYear + requestedDaysInYear;

                if (newTotal > YearlyVacationAllowanceDays)
                {
                    var remaining = Math.Max(0, YearlyVacationAllowanceDays - usedDaysInYear);
                    return BadRequest(new
                    {
                        message = $"Nicht genügend Urlaubstage übrig für {year}. Verfügbar: {remaining}, angefragt: {requestedDaysInYear}."
                    });
                }
            }
        }

        var now = DateTime.UtcNow;
        var absence = new AbsenceRequest
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            AbsenceTypeId = absenceType.Id,
            StartDate = startDate.Value,
            EndDate = endDate.Value,
            Reason = request.Reason?.Trim(),
            Status = AbsenceStatus.PENDING.ToString(),
            CreatedAt = now,
            UpdatedAt = now,
            AbsenceType = absenceType,
            User = user
        };

        _dbContext.AbsenceRequests.Add(absence);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("ABSENCE_REQUEST_CREATED", $"AbsenceType: {absenceType.Name}, From: {startDate:yyyy-MM-dd}, To: {endDate:yyyy-MM-dd}", user.Id, ipAddress);

        return Ok(MapAbsenceRequest(absence));
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> CancelAbsence(Guid id)
    {
        var user = await GetCurrentUserAsync();
        if (user is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var absence = await _dbContext.AbsenceRequests
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == user.Id);

        if (absence is null)
        {
            return NotFound(new { message = "Abwesenheitsantrag nicht gefunden." });
        }

        if (!string.Equals(absence.Status, AbsenceStatus.PENDING.ToString(), StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "Nur offene Anträge können zurückgezogen werden." });
        }

        absence.Status = AbsenceStatus.CANCELLED.ToString();
        absence.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("ABSENCE_REQUEST_CANCELLED", $"AbsenceRequestId: {id}", user.Id, ipAddress);

        return NoContent();
    }

    private async Task<User?> GetCurrentUserAsync()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return null;
        }

        return await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive);
    }

    private static AbsenceRequestDto MapAbsenceRequest(AbsenceRequest absence)
    {
        return new AbsenceRequestDto(
            Id: absence.Id,
            Type: MapAbsenceType(absence.AbsenceType),
            StartDate: absence.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            EndDate: absence.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            Reason: absence.Reason ?? string.Empty,
            Status: absence.Status,
            CreatedAt: absence.CreatedAt,
            UpdatedAt: absence.UpdatedAt);
    }

    private static AbsenceTypeDto MapAbsenceType(AbsenceType type)
    {
        return new AbsenceTypeDto(
            Id: type.Id,
            Name: type.Name,
            Description: type.Description);
    }

    private static DateOnly? ParseDateOnly(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        if (DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsedDateTime))
        {
            return DateOnly.FromDateTime(parsedDateTime);
        }

        if (DateOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedDateOnly))
        {
            return parsedDateOnly;
        }

        return null;
    }

    private static int CountWeekdaysInRange(DateOnly start, DateOnly end)
    {
        if (end < start)
        {
            return 0;
        }

        var weekdays = 0;
        var cursor = start;
        while (cursor <= end)
        {
            if (cursor.DayOfWeek is >= DayOfWeek.Monday and <= DayOfWeek.Friday)
            {
                weekdays++;
            }

            cursor = cursor.AddDays(1);
        }

        return weekdays;
    }

    private static int CountWeekdaysInYear(DateOnly start, DateOnly end, int year)
    {
        var yearStart = new DateOnly(year, 1, 1);
        var yearEnd = new DateOnly(year, 12, 31);

        var effectiveStart = start < yearStart ? yearStart : start;
        var effectiveEnd = end > yearEnd ? yearEnd : end;

        return CountWeekdaysInRange(effectiveStart, effectiveEnd);
    }
}

public sealed record CreateAbsenceRequestDto(Guid AbsenceTypeId, string? StartDate, string? EndDate, string? Reason);

public sealed record AbsenceRequestDto(
    Guid Id,
    AbsenceTypeDto Type,
    string StartDate,
    string EndDate,
    string Reason,
    string Status,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public sealed record AbsenceTypeDto(Guid Id, string Name, string? Description);