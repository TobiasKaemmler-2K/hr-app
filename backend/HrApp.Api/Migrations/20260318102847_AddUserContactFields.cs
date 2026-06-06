using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HrApp.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddUserContactFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "Users",
                type: "character varying(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "Users",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE "Users"
                SET "Email" = COALESCE(NULLIF("Email", ''), "PersonalNumber" || '@bw.org')
                WHERE "Email" IS NULL OR "Email" = '';
                """);

            migrationBuilder.Sql("""
                UPDATE "Users"
                SET "PhoneNumber" = COALESCE(NULLIF("PhoneNumber", ''), '+49-151-' || LPAD("PersonalNumber", 6, '0'))
                WHERE "PhoneNumber" IS NULL OR "PhoneNumber" = '';
                """);

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Users",
                type: "character varying(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(255)",
                oldMaxLength: 255,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "Users",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_Email",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PhoneNumber",
                table: "Users");
        }
    }
}
