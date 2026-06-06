namespace HrApp.Api.Helpers;

public static class BCryptHelper
{
	// Hash a plaintext password
	public static string HashPassword(string password) =>
		BCrypt.Net.BCrypt.HashPassword(password);

	// Verify a plaintext password against a stored hash
	public static bool Verify(string password, string hash) =>
		BCrypt.Net.BCrypt.Verify(password, hash);
}
