namespace HrApp.Api.Entities;

public class AuditLog
{
    public Guid Id { get; set; }

    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public string ActionType { get; set; } = null!;
    public string? ActionDetails { get; set; }
    public string? IpAddress { get; set; }

    public DateTime CreatedAt { get; set; }
}