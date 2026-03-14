# lex-claude: Claude Anthropic Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-ai/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to the Claude Anthropic API. Provides runners for message creation, token counting, model listing, and asynchronous batch processing.

**GitHub**: https://github.com/LegionIO/lex-claude
**License**: MIT
**Version**: 0.1.0

## Architecture

```
Legion::Extensions::Claude
├── Runners/
│   ├── Messages           # Create messages (create), count tokens (count_tokens)
│   ├── Models             # List (list) and retrieve (retrieve) models
│   └── Batches            # create_batch, list_batches, retrieve_batch, cancel_batch, batch_results
├── Helpers/
│   └── Client             # Faraday-based Anthropic API client (module, factory method)
└── Client                 # Standalone client class (includes all runners)
```

`Helpers::Client` is a **module** with a `client(api_key:, ...)` factory method. It sets `x-api-key` and `anthropic-version` headers. The `API_VERSION` constant is `'2023-06-01'` and `DEFAULT_HOST` is `'https://api.anthropic.com'`. All runner modules `extend` it. `Client` (class) provides a standalone instantiable wrapper that configures a persistent `@config` and delegates `client(...)` calls through the helpers module.

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` | HTTP client for Anthropic API |
| `multi_json` | JSON parser abstraction |

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
