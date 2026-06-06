using HrApp.Api.Data;
using HrApp.Api.Entities;
using HrApp.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace HrApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _dbContext;
    private readonly IAuditLogService _auditLogService;
    private const string ProtectedBootstrapAdminPersonalNumber = "100000";

    public AdminController(AppDbContext dbContext, IAuditLogService auditLogService)
    {
        _dbContext = dbContext;
        _auditLogService = auditLogService;
    }

    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<AdminUserDto>>> GetUsers()
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var users = await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .Include(x => x.NfcTokens)
            .OrderBy(x => x.LastName)
            .ThenBy(x => x.FirstName)
            .ToListAsync();

        return Ok(users.Select(MapUser).ToList());
    }

    [HttpPost("users")]
    public async Task<ActionResult<AdminUserDto>> CreateUser([FromBody] AdminCreateUserRequestDto request)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var validationError = await ValidateCreateOrUpdateRequestAsync(request, null);
        if (validationError is not null)
        {
            return BadRequest(new { message = validationError });
        }

        var roleNames = NormalizeRoleNames(request.Roles);
        if (roleNames.Count == 0)
        {
            roleNames.Add("SOLDAT");
        }

        var availableRoles = await _dbContext.Roles
            .Where(x => roleNames.Contains(x.Name))
            .ToListAsync();

        if (availableRoles.Count != roleNames.Count)
        {
            return BadRequest(new { message = "Mindestens eine angegebene Rolle existiert nicht." });
        }

        var now = DateTime.UtcNow;
        var user = new User
        {
            Id = Guid.NewGuid(),
            PersonalNumber = request.PersonalNumber.Trim(),
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            Email = request.Email.Trim(),
            PhoneNumber = request.PhoneNumber.Trim(),
            Unit = request.Unit.Trim(),
            Rank = request.Rank.Trim(),
            PasswordHash = BCryptHelper.HashPassword(request.InitialPassword.Trim()),
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.Users.Add(user);

        foreach (var role in availableRoles)
        {
            _dbContext.UserRoles.Add(new UserRole
            {
                UserId = user.Id,
                RoleId = role.Id
            });
        }

        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("USER_CREATED", $"PersonalNumber: {user.PersonalNumber}, Roles: {string.Join(",", roleNames)}", currentUser?.Id, ipAddress);

        var createdUser = await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .Include(x => x.NfcTokens)
            .FirstAsync(x => x.Id == user.Id);

        return Ok(MapUser(createdUser));
    }

    [HttpPut("users/{userId:guid}")]
    public async Task<ActionResult<AdminUserDto>> UpdateUser(Guid userId, [FromBody] AdminUpdateUserRequestDto request)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .Include(x => x.UserRoles)
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        var validationError = await ValidateCreateOrUpdateRequestAsync(request, userId);
        if (validationError is not null)
        {
            return BadRequest(new { message = validationError });
        }

        user.PersonalNumber = request.PersonalNumber.Trim();
        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = request.Email.Trim();
        user.PhoneNumber = request.PhoneNumber.Trim();
        user.Unit = request.Unit.Trim();
        user.Rank = request.Rank.Trim();
        user.UpdatedAt = DateTime.UtcNow;

        var roleNames = NormalizeRoleNames(request.Roles);
        if (roleNames.Count == 0)
        {
            roleNames.Add("SOLDAT");
        }

        var availableRoles = await _dbContext.Roles
            .Where(x => roleNames.Contains(x.Name))
            .ToListAsync();

        if (availableRoles.Count != roleNames.Count)
        {
            return BadRequest(new { message = "Mindestens eine angegebene Rolle existiert nicht." });
        }

        var currentRoleIds = user.UserRoles.Select(x => x.RoleId).ToHashSet();
        var newRoleIds = availableRoles.Select(x => x.Id).ToHashSet();

        var toDelete = user.UserRoles.Where(x => !newRoleIds.Contains(x.RoleId)).ToList();
        if (toDelete.Count > 0)
        {
            _dbContext.UserRoles.RemoveRange(toDelete);
        }

        foreach (var roleId in newRoleIds)
        {
            if (!currentRoleIds.Contains(roleId))
            {
                _dbContext.UserRoles.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = roleId
                });
            }
        }

        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("USER_UPDATED", $"PersonalNumber: {user.PersonalNumber}, Roles: {string.Join(",", roleNames)}", currentUser?.Id, ipAddress);

        var updated = await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .Include(x => x.NfcTokens)
            .FirstAsync(x => x.Id == userId);

        return Ok(MapUser(updated));
    }

    [HttpPost("users/{userId:guid}/block")]
    public async Task<IActionResult> BlockUser(Guid userId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        if (string.Equals(user.PersonalNumber, ProtectedBootstrapAdminPersonalNumber, StringComparison.OrdinalIgnoreCase))
        {
            await _auditLogService.LogAsync("USER_BLOCK_DENIED", "Attempt to block bootstrap admin", currentUser?.Id, ipAddress);
            return BadRequest(new { message = "Der Bootstrap-Admin kann nicht gesperrt werden." });
        }

        user.IsActive = false;
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("USER_BLOCKED", $"PersonalNumber: {user.PersonalNumber}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpPost("users/{userId:guid}/unblock")]
    public async Task<IActionResult> UnblockUser(Guid userId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        user.IsActive = true;
        user.FailedPasswordAttempts = 0;
        user.FailedNfcAttempts = 0;
        user.LockedAt = null;
        user.LockReason = null;
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("USER_UNBLOCKED", $"PersonalNumber: {user.PersonalNumber}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpPost("users/{userId:guid}/reset-password")]
    public async Task<IActionResult> ResetPassword(Guid userId, [FromBody] AdminResetPasswordRequestDto request)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var newPassword = request.NewPassword?.Trim();
        if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length < 6)
        {
            return BadRequest(new { message = "Neues Passwort muss mindestens 6 Zeichen haben." });
        }

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        user.PasswordHash = BCryptHelper.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("PASSWORD_RESET_BY_ADMIN", $"PersonalNumber: {user.PersonalNumber}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpDelete("users/{userId:guid}")]
    public async Task<IActionResult> DeleteUser(Guid userId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .Include(x => x.UserRoles)
            .Include(x => x.NfcTokens)
            .Include(x => x.LoginChallenges)
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        var absenceRequests = await _dbContext.AbsenceRequests
            .Where(x => x.UserId == userId)
            .ToListAsync();

        var absenceDecisions = await _dbContext.AbsenceDecisions
            .Where(x => x.AbsenceRequest.UserId == userId)
            .ToListAsync();

        if (absenceRequests.Count > 0)
        {
            _dbContext.AbsenceRequests.RemoveRange(absenceRequests);
        }

        if (absenceDecisions.Count > 0)
        {
            _dbContext.AbsenceDecisions.RemoveRange(absenceDecisions);
        }

        if (user.UserRoles.Count > 0)
        {
            _dbContext.UserRoles.RemoveRange(user.UserRoles);
        }

        if (user.NfcTokens.Count > 0)
        {
            _dbContext.NfcTokens.RemoveRange(user.NfcTokens);
        }

        if (user.LoginChallenges.Count > 0)
        {
            _dbContext.LoginChallenges.RemoveRange(user.LoginChallenges);
        }

        _dbContext.Users.Remove(user);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("USER_DELETED", $"PersonalNumber: {user.PersonalNumber}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpGet("users/{userId:guid}/nfc-tokens")]
    public async Task<ActionResult<IReadOnlyList<AdminNfcTokenDto>>> GetNfcTokens(Guid userId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var userExists = await _dbContext.Users.AnyAsync(x => x.Id == userId);
        if (!userExists)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        var tokens = await _dbContext.NfcTokens
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.IssuedAt)
            .ToListAsync();

        return Ok(tokens.Select(MapToken).ToList());
    }

    [HttpPost("users/{userId:guid}/nfc-tokens")]
    public async Task<ActionResult<AdminNfcTokenDto>> IssueNfcToken(Guid userId, [FromBody] AdminIssueNfcTokenRequestDto request)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        var tokenIdentifier = request.TokenIdentifier?.Trim();
        if (string.IsNullOrWhiteSpace(tokenIdentifier))
        {
            return BadRequest(new { message = "Token-Identifier ist erforderlich." });
        }

        var identifierInUse = await _dbContext.NfcTokens
            .AnyAsync(x => x.TokenIdentifier == tokenIdentifier);
        if (identifierInUse)
        {
            return Conflict(new { message = "Token-Identifier ist bereits vergeben." });
        }

        if (request.RevokeCurrentActive)
        {
            var activeTokens = await _dbContext.NfcTokens
                .Where(x => x.UserId == userId && x.IsActive)
                .ToListAsync();

            foreach (var activeToken in activeTokens)
            {
                activeToken.IsActive = false;
                activeToken.RevokedAt = DateTime.UtcNow;
            }
        }

        var token = new NfcToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenIdentifier = tokenIdentifier,
            IsActive = true,
            IssuedAt = DateTime.UtcNow,
            RevokedAt = null
        };

        _dbContext.NfcTokens.Add(token);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("NFC_TOKEN_ISSUED", $"PersonalNumber: {user.PersonalNumber}, TokenId: {tokenIdentifier}", currentUser?.Id, ipAddress);

        return Ok(MapToken(token));
    }

    [HttpPost("users/{userId:guid}/nfc-tokens/reassign")]
    public async Task<ActionResult<AdminNfcTokenDto>> ReassignNfcToken(Guid userId, [FromBody] AdminReassignNfcTokenRequestDto request)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user is null)
        {
            return NotFound(new { message = "Nutzer nicht gefunden." });
        }

        var tokenIdentifier = request.NewTokenIdentifier?.Trim();
        if (string.IsNullOrWhiteSpace(tokenIdentifier))
        {
            return BadRequest(new { message = "Neuer Token-Identifier ist erforderlich." });
        }

        var identifierInUse = await _dbContext.NfcTokens
            .AnyAsync(x => x.TokenIdentifier == tokenIdentifier);
        if (identifierInUse)
        {
            return Conflict(new { message = "Token-Identifier ist bereits vergeben." });
        }

        var activeTokens = await _dbContext.NfcTokens
            .Where(x => x.UserId == userId && x.IsActive)
            .ToListAsync();

        foreach (var activeToken in activeTokens)
        {
            activeToken.IsActive = false;
            activeToken.RevokedAt = DateTime.UtcNow;
        }

        var newToken = new NfcToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenIdentifier = tokenIdentifier,
            IsActive = true,
            IssuedAt = DateTime.UtcNow,
            RevokedAt = null
        };

        _dbContext.NfcTokens.Add(newToken);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("NFC_TOKEN_REASSIGNED", $"PersonalNumber: {user.PersonalNumber}, NewTokenId: {tokenIdentifier}", currentUser?.Id, ipAddress);

        return Ok(MapToken(newToken));
    }

    [HttpPost("nfc-tokens/{tokenId:guid}/block")]
    public async Task<IActionResult> BlockNfcToken(Guid tokenId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var token = await _dbContext.NfcTokens.FirstOrDefaultAsync(x => x.Id == tokenId);
        if (token is null)
        {
            return NotFound(new { message = "NFC-Token nicht gefunden." });
        }

        token.IsActive = false;
        token.RevokedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("NFC_TOKEN_BLOCKED", $"TokenId: {token.TokenIdentifier}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpDelete("nfc-tokens/{tokenId:guid}")]
    public async Task<IActionResult> DeleteNfcToken(Guid tokenId)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var token = await _dbContext.NfcTokens.FirstOrDefaultAsync(x => x.Id == tokenId);
        if (token is null)
        {
            return NotFound(new { message = "NFC-Token nicht gefunden." });
        }

        _dbContext.NfcTokens.Remove(token);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("NFC_TOKEN_DELETED", $"TokenId: {token.TokenIdentifier}", currentUser?.Id, ipAddress);

        return NoContent();
    }

    [HttpGet("audit-logs")]
    public async Task<ActionResult<AuditLogsResponseDto>> GetAuditLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? actionType = null,
        [FromQuery] Guid? userId = null)
    {
        if (!await IsCurrentUserAdminAsync())
        {
            return Forbid();
        }

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 50;
        if (pageSize > 200) pageSize = 200;

        var query = _dbContext.AuditLogs
            .Include(x => x.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(actionType))
        {
            query = query.Where(x => x.ActionType.Contains(actionType));
        }

        if (userId.HasValue && userId.Value != Guid.Empty)
        {
            query = query.Where(x => x.UserId == userId.Value);
        }

        var total = await query.CountAsync();
        var logs = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new AuditLogDto(
                x.Id,
                x.UserId,
                x.User != null ? $"{x.User.PersonalNumber} - {x.User.FirstName} {x.User.LastName}" : "Unknown",
                x.ActionType,
                x.ActionDetails,
                x.IpAddress,
                x.CreatedAt))
            .ToListAsync();

        return Ok(new AuditLogsResponseDto(
            Total: total,
            Page: page,
            PageSize: pageSize,
            Items: logs));
    }

    private async Task<bool> IsCurrentUserAdminAsync()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser is null)
        {
            return false;
        }

        return await _dbContext.UserRoles
            .Where(x => x.UserId == currentUser.Id)
            .Include(x => x.Role)
            .AnyAsync(x => x.Role.Name == "ADMIN");
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

    private async Task<string?> ValidateCreateOrUpdateRequestAsync(AdminCreateOrUpdateUserRequest request, Guid? currentUserId)
    {
        if (string.IsNullOrWhiteSpace(request.PersonalNumber))
        {
            return "Personalnummer ist erforderlich.";
        }

        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
        {
            return "Vorname und Nachname sind erforderlich.";
        }

        if (string.IsNullOrWhiteSpace(request.Email) || !request.Email.Contains('@'))
        {
            return "E-Mail ist ungültig.";
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return "Telefonnummer ist erforderlich.";
        }

        if (string.IsNullOrWhiteSpace(request.Unit) || string.IsNullOrWhiteSpace(request.Rank))
        {
            return "Einheit und Dienstgrad sind erforderlich.";
        }

        var personalNumber = request.PersonalNumber.Trim();
        var email = request.Email.Trim();

        var personalNumberExists = await _dbContext.Users
            .AnyAsync(x => x.PersonalNumber == personalNumber && (!currentUserId.HasValue || x.Id != currentUserId.Value));

        if (personalNumberExists)
        {
            return "Personalnummer ist bereits vergeben.";
        }

        var emailExists = await _dbContext.Users
            .AnyAsync(x => x.Email == email && (!currentUserId.HasValue || x.Id != currentUserId.Value));

        if (emailExists)
        {
            return "E-Mail ist bereits vergeben.";
        }

        return null;
    }

    private static HashSet<string> NormalizeRoleNames(IEnumerable<string>? roles)
    {
        if (roles is null)
        {
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        return roles
            .Select(x => x?.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x!.ToUpperInvariant())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    private static AdminUserDto MapUser(User user)
    {
        var roles = user.UserRoles
            .Select(x => x.Role.Name)
            .OrderBy(x => x)
            .ToList();

        var activeToken = user.NfcTokens
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.IssuedAt)
            .FirstOrDefault();

        return new AdminUserDto(
            user.Id,
            user.PersonalNumber,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.Unit,
            user.Rank,
            user.IsActive,
            roles,
            activeToken is null ? null : MapToken(activeToken),
                user.LockReason,
                user.LockedAt,
            user.CreatedAt,
            user.UpdatedAt);
    }

    private static AdminNfcTokenDto MapToken(NfcToken token)
    {
        return new AdminNfcTokenDto(
            token.Id,
            token.UserId,
            token.TokenIdentifier,
            token.IsActive,
            token.IssuedAt,
            token.RevokedAt);
    }
}

public interface AdminCreateOrUpdateUserRequest
{
    string PersonalNumber { get; }
    string FirstName { get; }
    string LastName { get; }
    string Email { get; }
    string PhoneNumber { get; }
    string Unit { get; }
    string Rank { get; }
}

public sealed record AdminCreateUserRequestDto(
    string PersonalNumber,
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    string Unit,
    string Rank,
    string InitialPassword,
    IReadOnlyList<string> Roles) : AdminCreateOrUpdateUserRequest;

public sealed record AdminUpdateUserRequestDto(
    string PersonalNumber,
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    string Unit,
    string Rank,
    IReadOnlyList<string> Roles) : AdminCreateOrUpdateUserRequest;

public sealed record AdminResetPasswordRequestDto(string NewPassword);

public sealed record AdminIssueNfcTokenRequestDto(string TokenIdentifier, bool RevokeCurrentActive);

public sealed record AdminReassignNfcTokenRequestDto(string NewTokenIdentifier);

public sealed record AdminNfcTokenDto(
    Guid Id,
    Guid UserId,
    string TokenIdentifier,
    bool IsActive,
    DateTime IssuedAt,
    DateTime? RevokedAt);

public sealed record AdminUserDto(
    Guid Id,
    string PersonalNumber,
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    string Unit,
    string Rank,
    bool IsActive,
    IReadOnlyList<string> Roles,
    AdminNfcTokenDto? ActiveNfcToken,
    string? LockReason,
    DateTime? LockedAt,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public sealed record AuditLogDto(
    Guid Id,
    Guid? UserId,
    string UserDisplay,
    string ActionType,
    string? ActionDetails,
    string? IpAddress,
    DateTime CreatedAt);

public sealed record AuditLogsResponseDto(
    int Total,
    int Page,
    int PageSize,
    IReadOnlyList<AuditLogDto> Items);