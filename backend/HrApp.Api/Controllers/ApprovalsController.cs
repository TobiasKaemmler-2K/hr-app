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
public class ApprovalsController : ControllerBase
{
    private readonly AppDbContext _dbContext;
    private readonly IAuditLogService _auditLogService;

    // Requested hierarchy (pyramid):
    // 100001 -> 100008, 100013, 100002, 100003
    // 100008 -> remaining assigned soldiers
    // 100013 -> remaining assigned soldiers
    private static readonly Dictionary<string, string[]> ExplicitHierarchy = new(StringComparer.OrdinalIgnoreCase)
    {
        ["100001"] = ["100008", "100013", "100002", "100003"],
        ["100008"] = ["100004", "100005", "100009", "100010"],
        ["100013"] = ["100006", "100007", "100011", "100012", "100014", "100015"]
    };

    public ApprovalsController(AppDbContext dbContext, IAuditLogService auditLogService)
    {
        _dbContext = dbContext;
        _auditLogService = auditLogService;
    }

    [HttpGet("pending")]
    public async Task<ActionResult<IReadOnlyList<ApprovalAbsenceRequestDto>>> GetPending()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var subordinateIds = await GetSubordinateUserIdsAsync(currentUser);
        if (subordinateIds.Count == 0)
        {
            return Ok(Array.Empty<ApprovalAbsenceRequestDto>());
        }

        var pending = await _dbContext.AbsenceRequests
            .Include(x => x.AbsenceType)
            .Include(x => x.User)
            .Where(x => subordinateIds.Contains(x.UserId))
            .Where(x => x.Status == AbsenceStatus.PENDING.ToString())
            .OrderBy(x => x.StartDate)
            .ToListAsync();

        return Ok(pending.Select(MapRequest).ToList());
    }

    [HttpGet("approved")]
    public async Task<ActionResult<IReadOnlyList<ApprovalAbsenceRequestDto>>> GetApproved()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var subordinateIds = await GetSubordinateUserIdsAsync(currentUser);
        if (subordinateIds.Count == 0)
        {
            return Ok(Array.Empty<ApprovalAbsenceRequestDto>());
        }

        var approved = await _dbContext.AbsenceRequests
            .Include(x => x.AbsenceType)
            .Include(x => x.User)
            .Where(x => subordinateIds.Contains(x.UserId))
            .Where(x => x.Status == AbsenceStatus.APPROVED.ToString())
            .OrderByDescending(x => x.UpdatedAt)
            .ToListAsync();

        return Ok(approved.Select(MapRequest).ToList());
    }

    [HttpPost("{id:guid}/approve")]
    public async Task<IActionResult> Approve(Guid id, [FromBody] ApprovalDecisionRequestDto? request)
    {
        return await DecideAsync(id, approve: true, request?.Comment);
    }

    [HttpPost("{id:guid}/reject")]
    public async Task<IActionResult> Reject(Guid id, [FromBody] ApprovalDecisionRequestDto? request)
    {
        return await DecideAsync(id, approve: false, request?.Comment);
    }

    [HttpGet("subordinates")]
    public async Task<ActionResult<IReadOnlyList<ApprovalSubordinateDto>>> GetSubordinates()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var subordinateIds = await GetSubordinateUserIdsAsync(currentUser);
        if (subordinateIds.Count == 0)
        {
            return Ok(Array.Empty<ApprovalSubordinateDto>());
        }

        var subordinates = await _dbContext.Users
            .Where(x => subordinateIds.Contains(x.Id))
            .OrderBy(x => x.Unit)
            .ThenBy(x => x.LastName)
            .ThenBy(x => x.FirstName)
            .Select(x => new ApprovalSubordinateDto(
                x.Id,
                x.PersonalNumber,
                x.FirstName,
                x.LastName,
                x.Email,
                x.PhoneNumber,
                x.Rank,
                x.Unit))
            .ToListAsync();

        return Ok(subordinates);
    }

    [HttpGet("subordinates/{subordinateId:guid}/requests")]
    public async Task<ActionResult<IReadOnlyList<ApprovalAbsenceRequestDto>>> GetSubordinateRequests(Guid subordinateId)
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var subordinateIds = await GetSubordinateUserIdsAsync(currentUser);
        if (!subordinateIds.Contains(subordinateId))
        {
            return Forbid();
        }

        var requests = await _dbContext.AbsenceRequests
            .Include(x => x.AbsenceType)
            .Include(x => x.User)
            .Where(x => x.UserId == subordinateId)
            .OrderByDescending(x => x.StartDate)
            .ToListAsync();

        return Ok(requests.Select(MapRequest).ToList());
    }

    private async Task<IActionResult> DecideAsync(Guid requestId, bool approve, string? comment)
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var subordinateIds = await GetSubordinateUserIdsAsync(currentUser);
        if (subordinateIds.Count == 0)
        {
            return Forbid();
        }

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var absence = await _dbContext.AbsenceRequests
            .Include(x => x.Decision)
            .FirstOrDefaultAsync(x => x.Id == requestId);

        if (absence is null)
        {
            return NotFound(new { message = "Antrag nicht gefunden." });
        }

        if (!subordinateIds.Contains(absence.UserId))
        {
            return Forbid();
        }

        if (!string.Equals(absence.Status, AbsenceStatus.PENDING.ToString(), StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "Nur offene Anträge können entschieden werden." });
        }

        var newStatus = approve ? AbsenceStatus.APPROVED.ToString() : AbsenceStatus.REJECTED.ToString();
        var decidedAt = DateTime.UtcNow;

        absence.Status = newStatus;
        absence.UpdatedAt = decidedAt;

        if (absence.Decision is null)
        {
            var decision = new AbsenceDecision
            {
                Id = Guid.NewGuid(),
                AbsenceRequestId = absence.Id,
                DecidedByUserId = currentUser.Id,
                Decision = newStatus,
                DecisionReason = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim(),
                DecidedAt = decidedAt
            };

            _dbContext.AbsenceDecisions.Add(decision);
            absence.Decision = decision;
        }
        else
        {
            absence.Decision.DecidedByUserId = currentUser.Id;
            absence.Decision.Decision = newStatus;
            absence.Decision.DecisionReason = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();
            absence.Decision.DecidedAt = decidedAt;
        }

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            return Conflict(new { message = "Der Antrag wurde zwischenzeitlich geändert. Bitte aktualisieren und erneut versuchen." });
        }

        var actionType = approve ? "ABSENCE_APPROVED" : "ABSENCE_REJECTED";
        await _auditLogService.LogAsync(actionType, $"Absence request {requestId}, Decision: {newStatus}", currentUser.Id, ipAddress);

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

    private async Task<HashSet<Guid>> GetSubordinateUserIdsAsync(User currentUser)
    {
        var roleNames = await _dbContext.UserRoles
            .Where(x => x.UserId == currentUser.Id)
            .Include(x => x.Role)
            .Select(x => x.Role.Name)
            .ToListAsync();

        var isAdmin = roleNames.Contains("ADMIN");
        var isApprover = isAdmin || roleNames.Contains("VORGESETZTER") || roleNames.Contains("GENEHMIGER");

        if (!isApprover)
        {
            return new HashSet<Guid>();
        }

        if (isAdmin)
        {
            return await _dbContext.Users
                .Where(x => x.IsActive && x.Id != currentUser.Id)
                .Select(x => x.Id)
                .ToHashSetAsync();
        }

        var usersByPersonalNumber = await _dbContext.Users
            .Where(x => x.IsActive)
            .ToDictionaryAsync(x => x.PersonalNumber, x => x, StringComparer.OrdinalIgnoreCase);

        // Prefer explicit hierarchy mapping when current user is part of the pyramid.
        var explicitResult = ResolveExplicitSubordinates(currentUser.PersonalNumber, usersByPersonalNumber);
        if (explicitResult.Count > 0)
        {
            return explicitResult;
        }

        var allUsers = await _dbContext.Users
            .Where(x => x.IsActive)
            .ToListAsync();

        var userRoles = await _dbContext.UserRoles
            .Include(x => x.Role)
            .ToListAsync();

        var result = new HashSet<Guid>();

        foreach (var user in allUsers)
        {
            if (user.Id == currentUser.Id)
            {
                continue;
            }

            var roles = userRoles
                .Where(x => x.UserId == user.Id)
                .Select(x => x.Role.Name)
                .ToList();

            if (roles.Contains("ADMIN"))
            {
                continue;
            }

            if (isAdmin)
            {
                result.Add(user.Id);
                continue;
            }

            var sameUnit = string.Equals(user.Unit, currentUser.Unit, StringComparison.OrdinalIgnoreCase);
            var subordinateCapable = roles.Contains("SOLDAT") || roles.Contains("VORGESETZTER") || roles.Contains("GENEHMIGER");

            if (sameUnit && subordinateCapable)
            {
                result.Add(user.Id);
            }
        }

        return result;
    }

    private static HashSet<Guid> ResolveExplicitSubordinates(
        string managerPersonalNumber,
        IReadOnlyDictionary<string, User> usersByPersonalNumber)
    {
        var result = new HashSet<Guid>();

        if (!ExplicitHierarchy.ContainsKey(managerPersonalNumber))
        {
            return result;
        }

        var queue = new Queue<string>();
        queue.Enqueue(managerPersonalNumber);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            if (!ExplicitHierarchy.TryGetValue(current, out var directSubordinates))
            {
                continue;
            }

            foreach (var subordinatePersonalNumber in directSubordinates)
            {
                if (usersByPersonalNumber.TryGetValue(subordinatePersonalNumber, out var subordinate))
                {
                    if (result.Add(subordinate.Id))
                    {
                        queue.Enqueue(subordinatePersonalNumber);
                    }
                }
            }
        }

        return result;
    }

    private static ApprovalAbsenceRequestDto MapRequest(AbsenceRequest request)
    {
        return new ApprovalAbsenceRequestDto(
            Id: request.Id,
            Type: new ApprovalAbsenceTypeDto(request.AbsenceType.Id, request.AbsenceType.Name, request.AbsenceType.Description),
            StartDate: request.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            EndDate: request.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            Reason: request.Reason ?? string.Empty,
            Status: request.Status,
            CreatedAt: request.CreatedAt,
            UpdatedAt: request.UpdatedAt,
            RequestedByPersonalNumber: request.User.PersonalNumber,
            RequestedByName: $"{request.User.FirstName} {request.User.LastName}");
    }
}

public sealed record ApprovalDecisionRequestDto(string? Comment);

public sealed record ApprovalAbsenceRequestDto(
    Guid Id,
    ApprovalAbsenceTypeDto Type,
    string StartDate,
    string EndDate,
    string Reason,
    string Status,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    string RequestedByPersonalNumber,
    string RequestedByName);

public sealed record ApprovalAbsenceTypeDto(Guid Id, string Name, string? Description);

public sealed record ApprovalSubordinateDto(
    Guid Id,
    string PersonalNumber,
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    string Rank,
    string Unit);