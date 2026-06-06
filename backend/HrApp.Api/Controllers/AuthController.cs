using HrApp.Api.Data;
using HrApp.Api.Entities;
using HrApp.Api.Helpers;
using HrApp.Api.Services;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace HrApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private static readonly TimeSpan LoginChallengeLifetime = TimeSpan.FromMinutes(5);
    private const int MaxFailedPasswordAttempts = 3;
    private const int MaxFailedNfcAttempts = 3;
    private readonly AppDbContext _dbContext;
    private readonly IAuditLogService _auditLogService;
    private readonly IJwtTokenService _jwtTokenService;

    public AuthController(
        AppDbContext dbContext,
        IAuditLogService auditLogService,
        IJwtTokenService jwtTokenService)
    {
        _dbContext = dbContext;
        _auditLogService = auditLogService;
        _jwtTokenService = jwtTokenService;
    }

    [EnableRateLimiting("auth-login")]
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponseDto>> Login([FromBody] LoginRequestDto request)
    {
        var personalNumber = request.PersonalNumber?.Trim();
        var password = request.Password?.Trim();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (string.IsNullOrWhiteSpace(personalNumber) || string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Personalnummer und Passwort sind erforderlich." });
        }

        var user = await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.PersonalNumber == personalNumber);

        if (user is null)
        {
            await _auditLogService.LogAsync("LOGIN_FAILED", $"Attempt with PersonalNumber {personalNumber}", null, ipAddress);
            return Unauthorized(new { message = "Ungültige Anmeldedaten." });
        }

        if (!user.IsActive)
        {
            await _auditLogService.LogAsync("LOGIN_BLOCKED", $"Blocked user login attempt: {personalNumber}", user.Id, ipAddress);
            return Unauthorized(new { message = "Benutzer ist gesperrt. Bitte Admin kontaktieren." });
        }

        if (!BCryptHelper.Verify(password, user.PasswordHash))
        {
            var wasLocked = await RegisterFailedPasswordAttemptAsync(user, ipAddress, personalNumber);
            return Unauthorized(new
            {
                message = wasLocked
                    ? "Benutzer wurde nach 3 fehlerhaften Passwortversuchen gesperrt. Bitte Admin kontaktieren."
                    : "Ungültige Anmeldedaten."
            });
        }

        var now = DateTime.UtcNow;
        var expiredChallenges = await _dbContext.LoginChallenges
            .Where(x => x.ExpiresAt <= now || x.IsUsed || x.UserId == user.Id)
            .ToListAsync();

        if (expiredChallenges.Count > 0)
        {
            _dbContext.LoginChallenges.RemoveRange(expiredChallenges);
        }

        if (user.FailedPasswordAttempts > 0)
        {
            user.FailedPasswordAttempts = 0;
            user.UpdatedAt = now;
        }

        var challenge = new LoginChallenge
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            CreatedAt = now,
            ExpiresAt = now.Add(LoginChallengeLifetime),
            IsUsed = false
        };

        _dbContext.LoginChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("LOGIN_INITIATED", "Login challenge created, awaiting NFC verification", user.Id, ipAddress);

        return Ok(new LoginResponseDto(
            RequiresNfc: true,
            LoginChallengeId: challenge.Id,
            Message: "Anmeldedaten korrekt. NFC-Verifikation erforderlich."));
    }

    [EnableRateLimiting("auth-nfc")]
    [HttpPost("verify-nfc")]
    public async Task<ActionResult<VerifyNfcResponseDto>> VerifyNfc([FromBody] VerifyNfcRequestDto request)
    {
        var tokenIdentifier = request.TokenIdentifier?.Trim();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (request.LoginChallengeId == Guid.Empty || string.IsNullOrWhiteSpace(tokenIdentifier))
        {
            return BadRequest(new { message = "Login-Challenge und Token sind erforderlich." });
        }

        var now = DateTime.UtcNow;
        var challenge = await _dbContext.LoginChallenges
            .Include(x => x.User)
                .ThenInclude(x => x.UserRoles)
                    .ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == request.LoginChallengeId);

        if (challenge is null)
        {
            return NotFound(new { message = "Login-Challenge nicht gefunden." });
        }

        if (challenge.IsUsed || challenge.ExpiresAt <= now)
        {
            await _auditLogService.LogAsync("NFC_VERIFY_FAILED", "Challenge expired or already used", null, ipAddress);
            return Unauthorized(new { message = "Login-Challenge ist abgelaufen oder bereits verwendet." });
        }

        var user = challenge.User;

        if (!user.IsActive)
        {
            challenge.IsUsed = true;
            await _dbContext.SaveChangesAsync();
            await _auditLogService.LogAsync("NFC_VERIFY_BLOCKED", $"Blocked user NFC attempt: {user.PersonalNumber}", user.Id, ipAddress);
            return Unauthorized(new { message = "Benutzer ist gesperrt. Bitte Admin kontaktieren." });
        }

        var token = await _dbContext.NfcTokens
            .FirstOrDefaultAsync(x =>
                x.UserId == challenge.UserId &&
                x.TokenIdentifier == tokenIdentifier &&
                x.IsActive &&
                x.RevokedAt == null);

        if (token is null)
        {
            var wasLocked = await RegisterFailedNfcAttemptAsync(user, challenge, ipAddress);
            return Unauthorized(new
            {
                message = wasLocked
                    ? "Benutzer wurde nach 3 fehlerhaften NFC-Versuchen gesperrt. Bitte Admin kontaktieren."
                    : "NFC-Token ungültig."
            });
        }

        challenge.IsUsed = true;
        if (user.FailedNfcAttempts > 0)
        {
            user.FailedNfcAttempts = 0;
            user.UpdatedAt = DateTime.UtcNow;
        }

        var roles = user.UserRoles
            .Select(x => x.Role.Name)
            .OrderBy(x => x)
            .ToList();

        var response = new VerifyNfcResponseDto(
            Jwt: _jwtTokenService.CreateToken(user, roles),
            User: new AuthenticatedUserDto(
                Id: user.Id,
                PersonalNumber: user.PersonalNumber,
                FirstName: user.FirstName,
                LastName: user.LastName,
                Email: user.Email,
                PhoneNumber: user.PhoneNumber,
                Rank: user.Rank,
                Unit: user.Unit,
                Roles: roles),
            Roles: roles,
            Message: "Anmeldung erfolgreich.");

        await _auditLogService.LogAsync("LOGIN_SUCCESS", "NFC verification successful", user.Id, ipAddress);
        await _dbContext.SaveChangesAsync();
        return Ok(response);
    }

    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto request)
    {
        var user = await GetCurrentUserAsync();
        if (user is null)
        {
            return Unauthorized(new { message = "Ungültiger oder fehlender Benutzerkontext." });
        }

        var currentPassword = request.CurrentPassword?.Trim();
        var newPassword = request.NewPassword?.Trim();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (string.IsNullOrWhiteSpace(currentPassword) || string.IsNullOrWhiteSpace(newPassword))
        {
            await _auditLogService.LogAsync("PASSWORD_CHANGE_FAILED", "Invalid password input", user.Id, ipAddress);
            return BadRequest(new { message = "Aktuelles und neues Passwort sind erforderlich." });
        }

        if (!BCryptHelper.Verify(currentPassword, user.PasswordHash))
        {
            await _auditLogService.LogAsync("PASSWORD_CHANGE_FAILED", "Incorrect current password", user.Id, ipAddress);
            return BadRequest(new { message = "Aktuelles Passwort ist nicht korrekt." });
        }

        if (newPassword.Length < 6)
        {
            await _auditLogService.LogAsync("PASSWORD_CHANGE_FAILED", "New password too short", user.Id, ipAddress);
            return BadRequest(new { message = "Neues Passwort muss mindestens 6 Zeichen haben." });
        }

        user.PasswordHash = BCryptHelper.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        await _auditLogService.LogAsync("PASSWORD_CHANGED", "Password successfully changed", user.Id, ipAddress);

        return Ok(new { message = "Passwort wurde erfolgreich geändert." });
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

    private async Task<bool> RegisterFailedPasswordAttemptAsync(User user, string? ipAddress, string personalNumber)
    {
        user.FailedPasswordAttempts += 1;
        user.UpdatedAt = DateTime.UtcNow;

        var wasLocked = false;
        if (user.FailedPasswordAttempts >= MaxFailedPasswordAttempts)
        {
            ApplySecurityLock(user, "PASSWORD", "3 falsche Passwortversuche");
            wasLocked = true;
        }

        await _dbContext.SaveChangesAsync();
        await _auditLogService.LogAsync(
            "LOGIN_FAILED",
            $"PersonalNumber: {personalNumber}, Attempt: {user.FailedPasswordAttempts}/{MaxFailedPasswordAttempts}",
            user.Id,
            ipAddress);

        if (wasLocked)
        {
            await _auditLogService.LogAsync(
                "USER_LOCKED_AUTOMATIC",
                $"PersonalNumber: {personalNumber}, Reason: PASSWORD",
                user.Id,
                ipAddress);
        }

        return wasLocked;
    }

    private async Task<bool> RegisterFailedNfcAttemptAsync(User user, LoginChallenge challenge, string? ipAddress)
    {
        user.FailedNfcAttempts += 1;
        user.UpdatedAt = DateTime.UtcNow;

        var wasLocked = false;
        if (user.FailedNfcAttempts >= MaxFailedNfcAttempts)
        {
            ApplySecurityLock(user, "NFC", "3 falsche NFC-Versuche");
            challenge.IsUsed = true;
            wasLocked = true;
        }

        await _dbContext.SaveChangesAsync();
        await _auditLogService.LogAsync(
            "NFC_VERIFY_FAILED",
            $"PersonalNumber: {user.PersonalNumber}, Attempt: {user.FailedNfcAttempts}/{MaxFailedNfcAttempts}",
            user.Id,
            ipAddress);

        if (wasLocked)
        {
            await _auditLogService.LogAsync(
                "USER_LOCKED_AUTOMATIC",
                $"PersonalNumber: {user.PersonalNumber}, Reason: NFC",
                user.Id,
                ipAddress);
        }

        return wasLocked;
    }

    private static void ApplySecurityLock(User user, string lockReasonCode, string lockReasonText)
    {
        user.IsActive = false;
        user.LockedAt = DateTime.UtcNow;
        user.LockReason = $"{lockReasonCode}:{lockReasonText}";
    }
}

public sealed record LoginRequestDto(string? PersonalNumber, string? Password);

public sealed record LoginResponseDto(bool RequiresNfc, Guid LoginChallengeId, string Message);

public sealed record VerifyNfcRequestDto(Guid LoginChallengeId, string? TokenIdentifier);

public sealed record ChangePasswordRequestDto(string? CurrentPassword, string? NewPassword);

public sealed record VerifyNfcResponseDto(
    string Jwt,
    AuthenticatedUserDto User,
    IReadOnlyList<string> Roles,
    string Message);

public sealed record AuthenticatedUserDto(
    Guid Id,
    string PersonalNumber,
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    string Rank,
    string Unit,
    IReadOnlyList<string> Roles);