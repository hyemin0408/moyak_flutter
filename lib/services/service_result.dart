/// Stable error categories for UI handling; no server payloads or credentials.
enum ServiceErrorCode {
  notConfigured,
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  invalidResponse,
  unavailable,
  unknown,
}

class ServiceError {
  const ServiceError({required this.code, required this.message});
  final ServiceErrorCode code;

  /// Safe user-facing text, never raw responses, tokens or personal data.
  final String message;
}

/// No nullable success flag/data combination. Callers handle both cases.
sealed class ServiceResult<T> {
  const ServiceResult();
}

/// Only future backend adapters should construct live success results.
final class ServiceSuccess<T> extends ServiceResult<T> {
  const ServiceSuccess(this.value);
  final T value;
}

final class ServiceFailure<T> extends ServiceResult<T> {
  const ServiceFailure(this.error);
  final ServiceError error;
}
