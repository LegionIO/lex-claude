# Changelog

## [0.3.2] - 2026-03-31

### Added
- Specs for `context_management` beta support in `Runners::Messages#create` and `#create_stream`: body inclusion, beta header auto-injection (`context-management-2025-06-27`), and nil omission

## [0.3.1] - 2026-03-31

### Added
- Extended cache fields in `parse_usage`: `cache_ephemeral_1h_tokens`, `cache_ephemeral_5m_tokens`, `cache_deleted_tokens` from Anthropic's `cache_creation` nested object
- `count_tokens` now returns `:usage` key with standardized usage hash
- SSE `collect_usage` returns full 7-field usage hash including cache tokens from stream events

### Changed
- `parse_usage` refactored to use `uval` helper for dual string/symbol key access
- SSE `collect_usage` uses `merge_usage` to generically accumulate all usage fields including nested `cache_creation`

## [0.3.0] - 2026-03-31

### Added
- `Helpers::Errors` — structured exception hierarchy (`ApiError`, `RateLimitError`, `OverloadedError`, `AuthenticationError`, `PermissionError`, `NotFoundError`, `InvalidRequestError`, `ServerError`, `StreamingError`); `from_response` factory; `retryable?` predicate
- `Helpers::Retry` — exponential backoff retry wrapper (`with_retry`) with configurable `max_attempts`, `base_delay`, `max_delay`
- `Helpers::Sse` — SSE event stream parser (`parse_stream`), text assembler (`collect_text`), usage merger (`collect_usage`)
- `Helpers::Response` — `handle_response` raises typed exceptions on non-2xx, parses 9 Anthropic rate limit headers, `parse_usage` extracts standard + cache token counts
- `Helpers::Client::BETA_HEADERS` — registry of 18 named beta identifiers; `client` factory accepts `betas:` array
- `Helpers::Client.streaming_client` — Faraday connection for SSE responses
- `Helpers::Tools` — `web_search` factory, `cache_control` helper, `required_betas_for` inspector
- `Helpers::Models` — registry of 11 canonical Claude model IDs with Symbol alias resolution; `adaptive_thinking?` predicate
- `Runners::Messages#create_stream` — streaming message creation with SSE event yielding
- `cache_system:` wraps system prompt in ephemeral cache_control block
- `cache_scope: :global` auto-injects `prompt-caching-scope-2026-01-05` beta
- `thinking:` for extended thinking with temperature auto-omission and beta auto-injection
- `output_config:` for structured output (JSON schema), effort control, task budgets with auto-beta
- `fast_mode: true` sends `speed: 'fast'` with `fast-mode-2026-02-01` beta
- `context_management:` with `context-management-2025-06-27` beta auto-injection
- `:usage` key in all `create` results with `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`
- All new helpers wired into main `require 'legion/extensions/claude'` tree
- Updated README with comprehensive examples for all new features

### Changed
- All runners raise typed `Helpers::Errors::*` exceptions instead of returning raw status codes
- `Messages#create` and `#create_stream` refactored to use shared `build_message_body` and `resolve_feature_betas` helpers
- `Messages#count_tokens` now accepts `thinking:`, `cache_system:` keywords
- Added `rubocop-legion` for consistent linting

## [0.1.3] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

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
