enum ResponseSource { network, cache, queued }

enum ErrorType {
  offline,
  timeout,
  unauthorized,
  forbidden,
  badRequest,
  server,
  contract,
  parse,
  unknown,
}