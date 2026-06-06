namespace HrApp.Api.Entities;

public class AbsenceRequest
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid AbsenceTypeId { get; set; }
    public AbsenceType AbsenceType { get; set; } = null!;

    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }

    public string? Reason { get; set; }
    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public AbsenceDecision? Decision { get; set; }
}