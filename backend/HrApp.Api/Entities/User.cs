namespace HrApp.Api.Entities;

public class User
{
    public Guid Id { get; set; }

    public string PersonalNumber { get; set; } = null!;
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string PhoneNumber { get; set; } = null!;
    public string Unit { get; set; } = null!;
    public string Rank { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;

    public bool IsActive { get; set; } = true;
    public int FailedPasswordAttempts { get; set; }
    public int FailedNfcAttempts { get; set; }
    public DateTime? LockedAt { get; set; }
    public string? LockReason { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    public ICollection<AbsenceRequest> AbsenceRequests { get; set; } = new List<AbsenceRequest>();
    public ICollection<AbsenceDecision> AbsenceDecisions { get; set; } = new List<AbsenceDecision>();
    public ICollection<NfcToken> NfcTokens { get; set; } = new List<NfcToken>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    public ICollection<LoginChallenge> LoginChallenges { get; set; } = new List<LoginChallenge>();
}