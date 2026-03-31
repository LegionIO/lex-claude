# Changelog

## [0.2.0] - 2026-03-31

### Added
- `Helpers::Errors` — structured exception hierarchy with `ApiError`, `RateLimitError`, `OverloadedError`, `AuthenticationError`, `PermissionError`, `NotFoundError`, `InvalidRequestError`, `ServerError`, `StreamingError`; `from_response` factory maps HTTP status codes to typed exceptions; `retryable?` predicate
- `Helpers::Retry` — exponential backoff retry wrapper (`with_retry`) with configurable `max_attempts`, `base_delay`, `max_delay`; skips non-retryable errors immediately
- `Helpers::Sse` — SSE event stream parser (`parse_stream`), text assembler (`collect_text`), usage merger (`collect_usage`)
- `Helpers::Response` — `handle_response` raises typed exceptions on non-2xx, parses 9 Anthropic rate limit headers into `:rate_limit` hash, `parse_usage` extracts standard + cache token counts
- `Helpers::Client::BETA_HEADERS` — registry of 18 named beta identifiers; `client` factory now accepts `betas:` array of Strings or Symbols, injects `anthropic-beta` header
- `Helpers::Client.streaming_client` — Faraday connection with `text/event-stream` Accept header for SSE responses
- `Runners::Messages#create_stream` — streaming message creation returning `{ result:, events:, usage:, status: }`; yields each SSE event to optional block
- `betas:` keyword argument on `Messages#create`, `Messages#count_tokens`
- All runners now raise typed `Helpers::Errors::*` exceptions instead of returning raw status codes

## [0.1.2] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies in gemspec
- Update spec_helper to require real sub-gem helpers and define Helpers::Lex with all 7 includes instead of a bare stub

## [0.1.1] - 2026-03-18

### Changed
- deleted gemfile.lock

## [0.1.0] - 2026-03-13

### Added
- Initial release
