/// Represents the possible states of the local authentication flow.
enum LocalAuthState {
  loading,      // Initial check (SPLASH/Loading)
  unauthenticated, // Auth is enabled but user hasn't proven identity
  authenticated,   // User is allowed to see the content
  disabled         // Security lock is turned off in settings
}
