namespace HrApp.Api.Entities;

public class AbsenceDecision
{
    public Guid Id { get; set; }

    public Guid AbsenceRequestId { get; set; }
    public AbsenceRequest AbsenceRequest { get; set; } = null!;

    public Guid DecidedByUserId { get; set; }
    public User DecidedByUser { get; set; } = null!;

    public string Decision { get; set; } = null!;
    public string? DecisionReason { get; set; }

    public DateTime DecidedAt { get; set; }
}