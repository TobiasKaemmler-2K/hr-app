namespace HrApp.Api.Entities;

public class NfcToken
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string TokenIdentifier { get; set; } = null!;

    public bool IsActive { get; set; } = true;

    public DateTime IssuedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}