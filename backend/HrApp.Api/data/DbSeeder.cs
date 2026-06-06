using System;
using HrApp.Api.Entities;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;

namespace HrApp.Api.Data;

public static class DbSeeder
{
    private static readonly Random Random = new();

    public static async Task SeedAsync(AppDbContext context)
    {
        var roles = await SeedRolesAsync(context);
        var absenceTypes = await SeedAbsenceTypesAsync(context);
        var users = await SeedUsersAsync(context);
        await SeedUserRolesAsync(context, users, roles);
        await SeedNfcTokensAsync(context, users);

        var absenceRequests = await SeedAbsenceRequestsAsync(context, users, absenceTypes);
        await SeedAbsenceDecisionsAsync(context, users, absenceRequests);
        await SeedLoginChallengesAsync(context, users);
        await SeedAuditLogsAsync(context, users);
    }

    private static async Task<List<Role>> SeedRolesAsync(AppDbContext context)
    {
        var existingRoles = await context.Roles.ToListAsync();
        var rolesToAdd = new List<Role>();

        if (!existingRoles.Any(r => r.Name == "SOLDAT"))
        {
            rolesToAdd.Add(new Role
            {
                Id = Guid.NewGuid(),
                Name = "SOLDAT",
                Description = "Standardbenutzer für eigene Abwesenheitsanträge"
            });
        }

        if (!existingRoles.Any(r => r.Name == "VORGESETZTER"))
        {
            rolesToAdd.Add(new Role
            {
                Id = Guid.NewGuid(),
                Name = "VORGESETZTER",
                Description = "Darf Anträge prüfen und entscheiden"
            });
        }

        if (!existingRoles.Any(r => r.Name == "ADMIN"))
        {
            rolesToAdd.Add(new Role
            {
                Id = Guid.NewGuid(),
                Name = "ADMIN",
                Description = "Darf Benutzer, Rollen und Tokens verwalten"
            });
        }

        if (rolesToAdd.Count > 0)
        {
            await context.Roles.AddRangeAsync(rolesToAdd);
            await context.SaveChangesAsync();
        }

        return await context.Roles.ToListAsync();
    }

    private static async Task<List<AbsenceType>> SeedAbsenceTypesAsync(AppDbContext context)
    {
        var existingTypes = await context.AbsenceTypes.ToListAsync();
        var typesToAdd = new List<AbsenceType>();

        if (!existingTypes.Any(t => t.Name == "Urlaub"))
        {
            typesToAdd.Add(new AbsenceType
            {
                Id = Guid.NewGuid(),
                Name = "Urlaub",
                Description = "Geplanter Erholungsurlaub",
                IsActive = true
            });
        }

        if (!existingTypes.Any(t => t.Name == "Krankheit"))
        {
            typesToAdd.Add(new AbsenceType
            {
                Id = Guid.NewGuid(),
                Name = "Krankheit",
                Description = "Krankheitsbedingte Abwesenheit",
                IsActive = true
            });
        }

        if (!existingTypes.Any(t => t.Name == "Dienstbefreiung"))
        {
            typesToAdd.Add(new AbsenceType
            {
                Id = Guid.NewGuid(),
                Name = "Dienstbefreiung",
                Description = "Genehmigte Dienstbefreiung",
                IsActive = true
            });
        }

        if (typesToAdd.Count > 0)
        {
            await context.AbsenceTypes.AddRangeAsync(typesToAdd);
            await context.SaveChangesAsync();
        }

        return await context.AbsenceTypes.ToListAsync();
    }

    private static async Task<List<User>> SeedUsersAsync(AppDbContext context)
    {
        var existingUsers = await context.Users.ToListAsync();

        var predefinedUsers = new List<UserSeedModel>
        {
            new("100000", "System", "Administrator", "Stab", "Hauptmann", "admin123", true, new[] { "ADMIN" }),
            new("100001", "Peter", "Meier", "1./PzBtl 104", "Oberleutnant", "test123", true, new[] { "VORGESETZTER" }),
            new("100002", "Max", "Müller", "1./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100003", "Anna", "Schmidt", "1./PzBtl 104", "Obergefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100004", "Lukas", "Weber", "2./PzBtl 104", "Hauptgefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100005", "Laura", "Fischer", "2./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100006", "Jonas", "Wagner", "3./PzBtl 104", "Stabsgefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100007", "Lisa", "Schneider", "3./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100008", "Tom", "Hoffmann", "Stab", "Major", "test123", true, new[] { "VORGESETZTER" }),
            new("100009", "Paul", "Becker", "SanBereich", "Unteroffizier", "test123", true, new[] { "SOLDAT" }),
            new("100010", "Marie", "Koch", "SanBereich", "Stabsunteroffizier", "test123", true, new[] { "SOLDAT" }),
            new("100011", "Felix", "Richter", "Logistik", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100012", "Nina", "Klein", "Logistik", "Obergefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100013", "Tim", "Wolf", "Stab", "Hauptfeldwebel", "test123", true, new[] { "VORGESETZTER" }),
            new("100014", "Leon", "Neumann", "Fernmeldezug", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100015", "Sophie", "Schröder", "Fernmeldezug", "Obergefreiter", "test123", true, new[] { "SOLDAT" })
        };

        var usersToAdd = new List<User>();

        foreach (var seedUser in predefinedUsers)
        {
            var existingUser = existingUsers.FirstOrDefault(u => u.PersonalNumber == seedUser.PersonalNumber);
            if (existingUser is not null)
            {
                var expectedEmail = BuildEmail(seedUser.PersonalNumber);
                var expectedPhone = BuildPhoneNumber(seedUser.PersonalNumber);

                var shouldUpdate = false;
                if (!string.Equals(existingUser.Email, expectedEmail, StringComparison.OrdinalIgnoreCase))
                {
                    existingUser.Email = expectedEmail;
                    shouldUpdate = true;
                }

                if (!string.Equals(existingUser.PhoneNumber, expectedPhone, StringComparison.OrdinalIgnoreCase))
                {
                    existingUser.PhoneNumber = expectedPhone;
                    shouldUpdate = true;
                }

                if (shouldUpdate)
                {
                    existingUser.UpdatedAt = DateTime.UtcNow;
                }

                continue;
            }

            usersToAdd.Add(new User
            {
                Id = Guid.NewGuid(),
                PersonalNumber = seedUser.PersonalNumber,
                FirstName = seedUser.FirstName,
                LastName = seedUser.LastName,
                Email = BuildEmail(seedUser.PersonalNumber),
                PhoneNumber = BuildPhoneNumber(seedUser.PersonalNumber),
                Unit = seedUser.Unit,
                Rank = seedUser.Rank,
                PasswordHash = BCryptHelper.HashPassword(seedUser.Password),
                IsActive = seedUser.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }

        if (usersToAdd.Count > 0)
        {
            await context.Users.AddRangeAsync(usersToAdd);
            await context.SaveChangesAsync();
        }

        return await context.Users.ToListAsync();
    }

    private static string BuildEmail(string personalNumber)
    {
        return $"{personalNumber}@bw.org";
    }

    private static string BuildPhoneNumber(string personalNumber)
    {
        return $"+49-151-{personalNumber.PadLeft(6, '0')}";
    }

    private static async Task SeedUserRolesAsync(
        AppDbContext context,
        List<User> users,
        List<Role> roles)
    {
        var existingUserRoles = await context.UserRoles.ToListAsync();
        var seedModels = GetUserSeedModels();
        var userRolesToAdd = new List<UserRole>();

        foreach (var seedUser in seedModels)
        {
            var user = users.FirstOrDefault(u => u.PersonalNumber == seedUser.PersonalNumber);
            if (user is null)
                continue;

            foreach (var roleName in seedUser.RoleNames)
            {
                var role = roles.First(r => r.Name == roleName);

                var alreadyExists = existingUserRoles.Any(ur =>
                    ur.UserId == user.Id &&
                    ur.RoleId == role.Id);

                if (alreadyExists)
                    continue;

                userRolesToAdd.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = role.Id
                });
            }
        }

        if (userRolesToAdd.Count > 0)
        {
            await context.UserRoles.AddRangeAsync(userRolesToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedNfcTokensAsync(AppDbContext context, List<User> users)
    {
        var existingTokens = await context.NfcTokens.ToListAsync();
        var tokensToAdd = new List<NfcToken>();

        foreach (var user in users)
        {
            var identifier = $"NFC-{user.PersonalNumber}";

            if (existingTokens.Any(t => t.TokenIdentifier == identifier))
                continue;

            tokensToAdd.Add(new NfcToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                TokenIdentifier = identifier,
                IsActive = true,
                IssuedAt = DateTime.UtcNow.AddDays(-Random.Next(10, 200)),
                RevokedAt = null
            });
        }

        if (tokensToAdd.Count > 0)
        {
            await context.NfcTokens.AddRangeAsync(tokensToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static async Task<List<AbsenceRequest>> SeedAbsenceRequestsAsync(
        AppDbContext context,
        List<User> users,
        List<AbsenceType> absenceTypes)
    {
        await ResetAbsenceDataAsync(context);

        var soldierUsers = users.Where(u => u.PersonalNumber != "100000").ToList();

        await EnsureYearlyVacationDataAsync(context, soldierUsers, absenceTypes);

        return await context.AbsenceRequests.ToListAsync();
    }

    private static async Task ResetAbsenceDataAsync(AppDbContext context)
    {
        var existingDecisions = await context.AbsenceDecisions.ToListAsync();
        if (existingDecisions.Count > 0)
        {
            context.AbsenceDecisions.RemoveRange(existingDecisions);
        }

        var existingRequests = await context.AbsenceRequests.ToListAsync();
        if (existingRequests.Count > 0)
        {
            context.AbsenceRequests.RemoveRange(existingRequests);
        }

        if (existingDecisions.Count > 0 || existingRequests.Count > 0)
        {
            await context.SaveChangesAsync();
        }
    }

    private static async Task EnsureYearlyVacationDataAsync(
        AppDbContext context,
        List<User> soldierUsers,
        List<AbsenceType> absenceTypes)
    {
        var vacationType = absenceTypes.FirstOrDefault(x => x.Name == "Urlaub");
        if (vacationType is null)
            return;

        var currentYear = DateTime.UtcNow.Year;
        var previousYear = currentYear - 1;

        var requestsToAdd = new List<AbsenceRequest>();

        for (int i = 0; i < soldierUsers.Count; i++)
        {
            var user = soldierUsers[i];
            var monthShift = i % 3;

            // Previous year: exactly 30 days approved in 1-2 week blocks, distributed across the year.
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, previousYear, 1 + monthShift, 1, 5, "APPROVED", "Erholungsurlaub Vorjahr"));
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, previousYear, 5 + monthShift, 2, 10, "APPROVED", "Erholungsurlaub Vorjahr"));
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, previousYear, 9 + monthShift, 1, 10, "APPROVED", "Erholungsurlaub Vorjahr"));
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, previousYear, 11, 2, 5, "APPROVED", "Erholungsurlaub Vorjahr"));

            // Current year: only part booked/approved, remaining days stay available.
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, currentYear, 2 + monthShift, 1, 5, "APPROVED", "Erholungsurlaub laufendes Jahr"));
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, currentYear, 6 + monthShift, 2, 10, "APPROVED", "Erholungsurlaub laufendes Jahr"));
            requestsToAdd.Add(CreateVacationBlock(user, vacationType, currentYear, 9 + monthShift, 1, 5, "PENDING", "Beantragter Erholungsurlaub laufendes Jahr"));
        }

        if (requestsToAdd.Count > 0)
        {
            await context.AbsenceRequests.AddRangeAsync(requestsToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static DateOnly MoveToNextWeekday(DateOnly date)
    {
        var current = date;
        while (current.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
        {
            current = current.AddDays(1);
        }

        return current;
    }

    private static DateOnly AddWeekdays(DateOnly start, int daysToAdd)
    {
        var current = start;
        var added = 0;

        while (added < daysToAdd)
        {
            current = current.AddDays(1);
            if (current.DayOfWeek is >= DayOfWeek.Monday and <= DayOfWeek.Friday)
            {
                added++;
            }
        }

        return current;
    }


    private static AbsenceRequest CreateVacationBlock(
        User user,
        AbsenceType vacationType,
        int year,
        int month,
        int weekInMonth,
        int weekdays,
        string status,
        string reason)
    {
        var normalizedMonth = Math.Clamp(month, 1, 12);
        var start = GetStartWeekdayInMonth(year, normalizedMonth, weekInMonth);
        var end = AddWeekdays(start, Math.Max(0, weekdays - 1));

        if (end.Year > year)
        {
            end = new DateOnly(year, 12, 31);
        }

        var createdAt = new DateTime(year, start.Month, start.Day, 8, 0, 0, DateTimeKind.Utc);

        return new AbsenceRequest
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            AbsenceTypeId = vacationType.Id,
            StartDate = start,
            EndDate = end,
            Reason = reason,
            Status = status,
            CreatedAt = createdAt,
            UpdatedAt = createdAt.AddHours(4)
        };
    }

    private static DateOnly GetStartWeekdayInMonth(int year, int month, int weekInMonth)
    {
        var baseDay = ((Math.Max(1, weekInMonth) - 1) * 7) + 1;
        var maxDay = DateTime.DaysInMonth(year, month);
        if (baseDay > maxDay)
        {
            baseDay = Math.Max(1, maxDay - 6);
        }

        var date = new DateOnly(year, month, baseDay);
        return MoveToNextWeekday(date);
    }

    private static async Task SeedAbsenceDecisionsAsync(
        AppDbContext context,
        List<User> users,
        List<AbsenceRequest> absenceRequests)
    {
        var existingDecisions = await context.AbsenceDecisions.ToListAsync();
        var userRoles = await context.UserRoles.ToListAsync();
        var roles = await context.Roles.ToListAsync();

        var supervisorRoleIds = roles
            .Where(r => r.Name == "VORGESETZTER" || r.Name == "ADMIN")
            .Select(r => r.Id)
            .ToHashSet();

        var supervisorUserIds = userRoles
            .Where(ur => supervisorRoleIds.Contains(ur.RoleId))
            .Select(ur => ur.UserId)
            .Distinct()
            .ToList();

        var supervisors = users.Where(u => supervisorUserIds.Contains(u.Id)).ToList();
        var decisionsToAdd = new List<AbsenceDecision>();

        foreach (var request in absenceRequests)
        {
            if (request.Status == "PENDING")
                continue;

            if (existingDecisions.Any(d => d.AbsenceRequestId == request.Id))
                continue;

            var decidedBy = supervisors[Random.Next(supervisors.Count)];

            decisionsToAdd.Add(new AbsenceDecision
            {
                Id = Guid.NewGuid(),
                AbsenceRequestId = request.Id,
                DecidedByUserId = decidedBy.Id,
                Decision = request.Status,
                DecisionReason = GenerateDecisionReason(request.Status),
                DecidedAt = (request.UpdatedAt == default ? DateTime.UtcNow : request.UpdatedAt).AddMinutes(Random.Next(5, 300))
            });
        }

        if (decisionsToAdd.Count > 0)
        {
            await context.AbsenceDecisions.AddRangeAsync(decisionsToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedLoginChallengesAsync(AppDbContext context, List<User> users)
    {
        var existingChallenges = await context.LoginChallenges.ToListAsync();
        var challengesToAdd = new List<LoginChallenge>();

        foreach (var user in users.Take(8))
        {
            var alreadyHasChallenge = existingChallenges.Any(c =>
                c.UserId == user.Id &&
                c.ExpiresAt > DateTime.UtcNow.AddHours(-1));

            if (alreadyHasChallenge)
                continue;

            var createdAt = DateTime.UtcNow.AddMinutes(-Random.Next(1, 20));

            challengesToAdd.Add(new LoginChallenge
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                CreatedAt = createdAt,
                ExpiresAt = createdAt.AddMinutes(5),
                IsUsed = Random.Next(0, 2) == 1
            });
        }

        if (challengesToAdd.Count > 0)
        {
            await context.LoginChallenges.AddRangeAsync(challengesToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedAuditLogsAsync(AppDbContext context, List<User> users)
    {
        var existingCount = await context.AuditLogs.CountAsync();
        if (existingCount >= 120)
            return;

        var logsToAdd = new List<AuditLog>();
        var actionTypes = new[]
        {
            "LOGIN",
            "LOGOUT",
            "CREATE_ABSENCE_REQUEST",
            "APPROVE_ABSENCE_REQUEST",
            "REJECT_ABSENCE_REQUEST",
            "REGISTER_NFC_TOKEN"
        };

        for (int i = existingCount; i < 120; i++)
        {
            var user = users[Random.Next(users.Count)];
            var actionType = actionTypes[Random.Next(actionTypes.Length)];

            logsToAdd.Add(new AuditLog
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ActionType = actionType,
                ActionDetails = GenerateAuditDetails(actionType, user),
                IpAddress = $"192.168.0.{Random.Next(10, 200)}",
                CreatedAt = DateTime.UtcNow.AddDays(-Random.Next(0, 90)).AddMinutes(-Random.Next(0, 1440))
            });
        }

        if (logsToAdd.Count > 0)
        {
            await context.AuditLogs.AddRangeAsync(logsToAdd);
            await context.SaveChangesAsync();
        }
    }

    private static List<UserSeedModel> GetUserSeedModels()
    {
        return new List<UserSeedModel>
        {
            new("100000", "System", "Administrator", "Stab", "Hauptmann", "admin123", true, new[] { "ADMIN" }),
            new("100001", "Peter", "Meier", "1./PzBtl 104", "Oberleutnant", "test123", true, new[] { "VORGESETZTER" }),
            new("100002", "Max", "Müller", "1./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100003", "Anna", "Schmidt", "1./PzBtl 104", "Obergefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100004", "Lukas", "Weber", "2./PzBtl 104", "Hauptgefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100005", "Laura", "Fischer", "2./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100006", "Jonas", "Wagner", "3./PzBtl 104", "Stabsgefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100007", "Lisa", "Schneider", "3./PzBtl 104", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100008", "Tom", "Hoffmann", "Stab", "Major", "test123", true, new[] { "VORGESETZTER" }),
            new("100009", "Paul", "Becker", "SanBereich", "Unteroffizier", "test123", true, new[] { "SOLDAT" }),
            new("100010", "Marie", "Koch", "SanBereich", "Stabsunteroffizier", "test123", true, new[] { "SOLDAT" }),
            new("100011", "Felix", "Richter", "Logistik", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100012", "Nina", "Klein", "Logistik", "Obergefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100013", "Tim", "Wolf", "Stab", "Hauptfeldwebel", "test123", true, new[] { "VORGESETZTER" }),
            new("100014", "Leon", "Neumann", "Fernmeldezug", "Gefreiter", "test123", true, new[] { "SOLDAT" }),
            new("100015", "Sophie", "Schröder", "Fernmeldezug", "Obergefreiter", "test123", true, new[] { "SOLDAT" })
        };
    }

    private static string GenerateReason(string absenceTypeName)
    {
        return absenceTypeName switch
        {
            "Urlaub" => "Geplanter Erholungsurlaub",
            "Krankheit" => "Krankheitsbedingte Abwesenheit",
            "Dienstbefreiung" => "Beantragte Dienstbefreiung aus dienstlichem Anlass",
            _ => "Automatisch generierter Testantrag"
        };
    }

    private static string GenerateDecisionReason(string status)
    {
        return status switch
        {
            "APPROVED" => "Antrag geprüft und genehmigt",
            "REJECTED" => "Antrag geprüft und abgelehnt",
            "CANCELLED" => "Antrag durch Benutzer storniert",
            _ => "Keine Entscheidung vorhanden"
        };
    }

    private static string GenerateAuditDetails(string actionType, User user)
    {
        return actionType switch
        {
            "LOGIN" => $"Benutzer {user.PersonalNumber} hat sich angemeldet",
            "LOGOUT" => $"Benutzer {user.PersonalNumber} hat sich abgemeldet",
            "CREATE_ABSENCE_REQUEST" => $"Benutzer {user.PersonalNumber} hat einen Abwesenheitsantrag erstellt",
            "APPROVE_ABSENCE_REQUEST" => $"Benutzer {user.PersonalNumber} hat einen Antrag genehmigt",
            "REJECT_ABSENCE_REQUEST" => $"Benutzer {user.PersonalNumber} hat einen Antrag abgelehnt",
            "REGISTER_NFC_TOKEN" => $"Für Benutzer {user.PersonalNumber} wurde ein NFC-Token registriert",
            _ => "Automatisch generierter Audit-Eintrag"
        };
    }

    private sealed record UserSeedModel(
        string PersonalNumber,
        string FirstName,
        string LastName,
        string Unit,
        string Rank,
        string Password,
        bool IsActive,
        string[] RoleNames);
}