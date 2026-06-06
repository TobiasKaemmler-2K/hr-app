namespace HrApp.Api.Entities;

public class LoginChallenge
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }
}