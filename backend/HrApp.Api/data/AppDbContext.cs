using HrApp.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace HrApp.Api.Data;

public class AppDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<AbsenceType> AbsenceTypes => Set<AbsenceType>();
    public DbSet<AbsenceRequest> AbsenceRequests => Set<AbsenceRequest>();
    public DbSet<AbsenceDecision> AbsenceDecisions => Set<AbsenceDecision>();
    public DbSet<NfcToken> NfcTokens => Set<NfcToken>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<LoginChallenge> LoginChallenges => Set<LoginChallenge>();

    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureUser(modelBuilder);
        ConfigureRole(modelBuilder);
        ConfigureUserRole(modelBuilder);
        ConfigureAbsenceType(modelBuilder);
        ConfigureAbsenceRequest(modelBuilder);
        ConfigureAbsenceDecision(modelBuilder);
        ConfigureNfcToken(modelBuilder);
        ConfigureAuditLog(modelBuilder);
        ConfigureLoginChallenge(modelBuilder);
    }

    private static void ConfigureUser(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasIndex(x => x.PersonalNumber).IsUnique();
            entity.HasIndex(x => x.Email).IsUnique();

            entity.Property(x => x.PersonalNumber).HasMaxLength(50).IsRequired();
            entity.Property(x => x.FirstName).HasMaxLength(100).IsRequired();
            entity.Property(x => x.LastName).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(255).IsRequired();
            entity.Property(x => x.PhoneNumber).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Unit).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Rank).HasMaxLength(100).IsRequired();
            entity.Property(x => x.PasswordHash).HasMaxLength(255).IsRequired();
            entity.Property(x => x.IsActive).IsRequired();
            entity.Property(x => x.FailedPasswordAttempts).IsRequired().HasDefaultValue(0);
            entity.Property(x => x.FailedNfcAttempts).IsRequired().HasDefaultValue(0);
            entity.Property(x => x.LockedAt);
            entity.Property(x => x.LockReason).HasMaxLength(255);
            entity.Property(x => x.CreatedAt).IsRequired();
            entity.Property(x => x.UpdatedAt).IsRequired();
        });
    }

    private static void ConfigureRole(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasIndex(x => x.Name).IsUnique();

            entity.Property(x => x.Name).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(255);
        });
    }

    private static void ConfigureUserRole(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(x => new { x.UserId, x.RoleId });

            entity.HasOne(x => x.User)
                .WithMany(x => x.UserRoles)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Role)
                .WithMany(x => x.UserRoles)
                .HasForeignKey(x => x.RoleId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigureAbsenceType(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AbsenceType>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasIndex(x => x.Name).IsUnique();

            entity.Property(x => x.Name).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(255);
            entity.Property(x => x.IsActive).IsRequired();
        });
    }

    private static void ConfigureAbsenceRequest(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AbsenceRequest>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.Property(x => x.StartDate).IsRequired();
            entity.Property(x => x.EndDate).IsRequired();
            entity.Property(x => x.Reason);
            entity.Property(x => x.Status).HasMaxLength(30).IsRequired();
            entity.Property(x => x.CreatedAt).IsRequired();
            entity.Property(x => x.UpdatedAt).IsRequired();

            entity.HasOne(x => x.User)
                .WithMany(x => x.AbsenceRequests)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.AbsenceType)
                .WithMany(x => x.AbsenceRequests)
                .HasForeignKey(x => x.AbsenceTypeId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigureAbsenceDecision(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AbsenceDecision>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasIndex(x => x.AbsenceRequestId).IsUnique();

            entity.Property(x => x.Decision).HasMaxLength(30).IsRequired();
            entity.Property(x => x.DecisionReason);
            entity.Property(x => x.DecidedAt).IsRequired();

            entity.HasOne(x => x.AbsenceRequest)
                .WithOne(x => x.Decision)
                .HasForeignKey<AbsenceDecision>(x => x.AbsenceRequestId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.DecidedByUser)
                .WithMany(x => x.AbsenceDecisions)
                .HasForeignKey(x => x.DecidedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigureNfcToken(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<NfcToken>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasIndex(x => x.TokenIdentifier).IsUnique();

            entity.Property(x => x.TokenIdentifier).HasMaxLength(255).IsRequired();
            entity.Property(x => x.IsActive).IsRequired();
            entity.Property(x => x.IssuedAt).IsRequired();
            entity.Property(x => x.RevokedAt);

            entity.HasOne(x => x.User)
                .WithMany(x => x.NfcTokens)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigureAuditLog(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.Property(x => x.ActionType).HasMaxLength(100).IsRequired();
            entity.Property(x => x.ActionDetails);
            entity.Property(x => x.IpAddress).HasMaxLength(64);
            entity.Property(x => x.CreatedAt).IsRequired();

            entity.HasOne(x => x.User)
                .WithMany(x => x.AuditLogs)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });
    }

    private static void ConfigureLoginChallenge(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<LoginChallenge>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.Property(x => x.CreatedAt).IsRequired();
            entity.Property(x => x.ExpiresAt).IsRequired();
            entity.Property(x => x.IsUsed).IsRequired();

            entity.HasOne(x => x.User)
                .WithMany(x => x.LoginChallenges)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}