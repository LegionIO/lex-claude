# lex-claude: Claude Anthropic Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-ai/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to the Claude Anthropic API. Provides runners for message creation, token counting, model listing, and asynchronous batch processing.

**GitHub**: https://github.com/LegionIO/lex-claude
**License**: MIT
**Version**: 0.1.2
**Specs**: 18 examples

## Architecture

```
Legion::Extensions::Claude
├── Runners/
│   ├── Messages           # create(api_key:, model:, messages:, ...), count_tokens(api_key:, model:, messages:, ...)
│   ├── Models             # list(api_key:, ...), retrieve(api_key:, model_id:, ...)
│   └── Batches            # create_batch, list_batches, retrieve_batch, cancel_batch, batch_results
├── Helpers/
│   └── Client             # Faraday-based Anthropic API client (module, factory method)
└── Client                 # Standalone client class (includes all runners, holds @config)
```

`Helpers::Client` is a **module** with a `client(api_key:, ...)` factory method. It sets `x-api-key` and `anthropic-version` headers. The `API_VERSION` constant is `'2023-06-01'` and `DEFAULT_HOST` is `'https://api.anthropic.com'`. All runner modules `extend` it.

`Client` (class) provides a standalone instantiable wrapper. It `include`s all runner modules and holds a persistent `@config` hash. Its private `client(**override_opts)` merges config with any per-call overrides and delegates to `Helpers::Client.client(...)`.

## Key Design Decisions

- `Helpers::Client` uses `module_function`, making `client(...)` callable as both a module-level method and as an instance method when mixed in. Runners use `extend Helpers::Client` to get `client(...)` as a module-level method.
- `Client` class uses `include` (not `extend`) so runner methods become instance methods on the client object.
- The Batches runner uses JSON-only payloads — no multipart dependency.
- `include Legion::Extensions::Helpers::Lex` is guarded: only included when `lex-lex` is loaded.

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` >= 2.0 | HTTP client for Anthropic API |
| `multi_json` | JSON parser abstraction |

## Testing

```bash
bundle install
bundle exec rspec        # 18 examples
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
