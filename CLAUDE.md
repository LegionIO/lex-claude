# lex-claude: Claude Anthropic Integration for LegionIO

**Repository Level 3 Documentation**
- **Category**: `/Users/miverso2/rubymine/legion/extensions/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to the Claude Anthropic API. Provides runners for message creation, token counting, model listing, and asynchronous batch processing.

**GitHub**: https://github.com/LegionIO/lex-claude
**License**: MIT

## Architecture

```
Legion::Extensions::Claude
├── Runners/
│   ├── Messages           # Create messages, count tokens
│   ├── Models             # List and retrieve models
│   └── Batches            # Create, list, retrieve, cancel batches
├── Helpers/
│   └── Client             # Faraday-based Anthropic API client
└── Client                 # Standalone client class (includes all runners)
```

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
