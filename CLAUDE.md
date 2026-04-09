# lex-claude: Claude Anthropic Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-ai/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to the Claude Anthropic API. Provides runners for message creation (streaming and non-streaming), token counting, model listing, and asynchronous batch processing. Full support for prompt caching, extended thinking, structured output, web search, effort control, fast mode, and context management betas.

**GitHub**: https://github.com/LegionIO/lex-claude
**License**: MIT
**Version**: 0.3.3
**Specs**: 134 examples (12 spec files)

## Architecture

```
Legion::Extensions::Claude
├── Runners/
│   ├── Messages           # create, create_stream, count_tokens
│   ├── Models             # list, retrieve
│   └── Batches            # create_batch, list_batches, retrieve_batch, cancel_batch, batch_results
├── Helpers/
│   ├── Client             # Faraday-based Anthropic API client (module + streaming_client factory)
│   ├── Errors             # structured exception hierarchy (ApiError, RateLimitError, AuthenticationError, etc.)
│   ├── Models             # model symbol alias resolution (Helpers::Models.resolve)
│   ├── Response           # response handling + usage parsing (handle_response, parse_usage)
│   ├── Retry              # Helpers::Retry.with_retry (configurable max_attempts)
│   ├── Sse                # SSE stream parser (parse_stream, collect_text, collect_usage)
│   └── Tools              # tool descriptor builders (web_search)
└── Client                 # Standalone client class (includes all runners, holds @config)
```

`Helpers::Client` is a **module** with two factory methods:
- `client(api_key:, betas: nil, ...)` — standard Faraday connection, sets `x-api-key` and `anthropic-version` headers, encodes betas as `anthropic-beta` header.
- `streaming_client(api_key:, betas: nil)` — same connection but configured for streaming responses.

`API_VERSION = '2023-06-01'`. `DEFAULT_HOST = 'https://api.anthropic.com'`.

`Client` (class) provides a standalone instantiable wrapper. It `include`s all runner modules and holds a persistent `@config` hash. Its private `client(**override_opts)` merges config with per-call overrides and delegates to `Helpers::Client.client(...)`.

## Key Design Decisions

- `Messages#create` auto-resolves beta headers based on opts: `cache_scope: :global` adds `:prompt_caching_scope`, `thinking:` adds `:interleaved_thinking`, `output_config.format` adds `:structured_outputs`, `output_config.effort` adds `:effort`, `fast_mode: true` adds `:fast_mode`, `context_management:` adds `:context_management`.
- `Messages#create_stream` uses `Helpers::Sse.parse_stream` for SSE event parsing. Returns `{ result: accumulated_text, events:, usage:, status: 200 }`.
- `Messages#count_tokens` posts to `/v1/messages/count_tokens`.
- `Batches` runner uses JSON-only payloads — no multipart dependency.
- `Helpers::Errors.from_response` builds typed exceptions from HTTP status codes.
- `Helpers::Retry.with_retry` retries on rate limit and server errors with exponential backoff.
- `include Legion::Extensions::Helpers::Lex` is guarded: only included when `lex-lex` is loaded.

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` >= 2.0 | HTTP client for Anthropic API |
| `multi_json` | JSON parser abstraction |
| `legion-cache`, `legion-crypt`, `legion-data`, `legion-json`, `legion-logging`, `legion-settings`, `legion-transport` | LegionIO core |

## Testing

```bash
bundle install
bundle exec rspec        # 134 examples
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
**Last Updated**: 2026-04-06
