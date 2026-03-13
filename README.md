# lex-claude

Claude Anthropic API integration for [LegionIO](https://github.com/LegionIO/LegionIO). Provides runners for creating messages, listing models, counting tokens, and managing message batches.

## Installation

```bash
gem install lex-claude
```

## Functions

### Messages
- `create` - Create a message (chat completion) with Claude
- `count_tokens` - Count input tokens for a message request

### Models
- `list` - List available Claude models
- `retrieve` - Get details for a specific model

### Batches
- `create_batch` - Create an asynchronous message batch
- `list_batches` - List message batches
- `retrieve_batch` - Get details for a specific batch
- `cancel_batch` - Cancel an in-progress batch
- `batch_results` - Retrieve results for a completed batch

## Configuration

Set your API key in your LegionIO settings or pass it directly:

```yaml
# config/settings.yml
claude:
  api_key: "sk-ant-..."
```

## Standalone Usage

```ruby
require 'legion/extensions/claude/client'

client = Legion::Extensions::Claude::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

# Create a message
result = client.create(
  model: 'claude-sonnet-4-20250514',
  messages: [{ role: 'user', content: 'Hello, Claude!' }],
  max_tokens: 1024
)
puts result[:result]['content'].first['text']

# List models
models = client.list
puts models[:result]['data'].map { |m| m['id'] }

# Count tokens
tokens = client.count_tokens(
  model: 'claude-sonnet-4-20250514',
  messages: [{ role: 'user', content: 'How many tokens is this?' }]
)
puts tokens[:result]['input_tokens']

# Create an async batch
batch = client.create_batch(
  requests: [
    { custom_id: 'req-1', params: { model: 'claude-sonnet-4-20250514',
                                    messages: [{ role: 'user', content: 'Hello' }],
                                    max_tokens: 100 } }
  ]
)
puts batch[:result]['id']
```

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (optional for standalone client usage)
- Anthropic API key

## License

MIT
