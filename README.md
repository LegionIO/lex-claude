# lex-claude

Production-grade Claude Anthropic API integration for LegionIO. Provides runners for creating messages (streaming and batch), counting tokens, listing models, managing message batches, and accessing all modern Anthropic API features.

## Purpose

Wraps the Anthropic Claude REST API as named runners consumable by any LegionIO task chain. Supports streaming, prompt caching, extended thinking, structured output, web search, effort control, fast mode, and all beta API features. For simple chat/embed workflows, consider `legion-llm` instead.

## Installation

```bash
gem install lex-claude
```

Or add to your Gemfile:

```ruby
gem 'lex-claude'
```

## Functions

### Messages
- `create` — Create a message (supports caching, thinking, tools, structured output)
- `create_stream` — Streaming message creation with SSE event yielding
- `count_tokens` — Count input tokens (supports tools, thinking, caching)

### Models
- `list` — List available Claude models
- `retrieve` — Get details for a specific model

### Batches
- `create_batch` — Create an asynchronous message batch
- `list_batches` — List message batches
- `retrieve_batch` — Get details for a specific batch
- `cancel_batch` — Cancel an in-progress batch
- `batch_results` — Retrieve results for a completed batch

### Helpers
- `Helpers::Tools.web_search` — Build web search tool descriptor
- `Helpers::Models.resolve` — Resolve model Symbol aliases to canonical IDs
- `Helpers::Errors` — Structured exception hierarchy

## Configuration

```json
{
  "claude": {
    "api_key": "sk-ant-..."
  }
}
```

## Usage

### Basic message

```ruby
require 'legion/extensions/claude/client'

client = Legion::Extensions::Claude::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

result = client.create(
  model: 'claude-sonnet-4-6',
  messages: [{ role: 'user', content: 'Hello!' }],
  max_tokens: 1024
)
puts result[:result]['content'].first['text']
puts result[:usage].inspect
```

### Streaming

```ruby
client.create_stream(
  model: 'claude-sonnet-4-6',
  messages: [{ role: 'user', content: 'Tell me a story.' }],
  max_tokens: 2048
) do |event|
  print event[:data].dig('delta', 'text') if event[:event] == 'content_block_delta'
end
```

### Prompt caching

```ruby
result = client.create(
  model: 'claude-sonnet-4-6',
  messages: [{ role: 'user', content: 'Summarize this.' }],
  system: 'You are a helpful assistant with deep context about...',
  cache_system: true,
  cache_scope: :global,
  max_tokens: 512
)
puts result[:usage][:cache_read_tokens]
```

### Extended thinking

```ruby
result = client.create(
  model: 'claude-opus-4-6',
  messages: [{ role: 'user', content: 'Solve this complex problem...' }],
  thinking: { type: 'adaptive' },
  max_tokens: 8192
)
```

### Structured output

```ruby
result = client.create(
  model: 'claude-sonnet-4-6',
  messages: [{ role: 'user', content: 'Extract the name and age.' }],
  max_tokens: 256,
  output_config: {
    format: {
      type: 'json_schema',
      json_schema: {
        type: 'object',
        properties: { name: { type: 'string' }, age: { type: 'integer' } },
        required: %w[name age]
      }
    }
  }
)
```

### Web search

```ruby
web_tool = Legion::Extensions::Claude::Helpers::Tools.web_search(max_uses: 3)

result = client.create(
  model: 'claude-sonnet-4-6',
  messages: [{ role: 'user', content: 'What happened in the news today?' }],
  tools: [web_tool],
  betas: [:web_search],
  max_tokens: 1024
)
```

### Effort control and fast mode

```ruby
result = client.create(
  model: 'claude-sonnet-4-6',
  messages: messages,
  max_tokens: 2048,
  output_config: { effort: 'high' }
)

result = client.create(
  model: 'claude-sonnet-4-6',
  messages: messages,
  max_tokens: 512,
  fast_mode: true
)
```

### Beta headers

```ruby
result = client.create(
  model: 'claude-sonnet-4-6',
  messages: messages,
  max_tokens: 1024,
  betas: [:token_efficient_tools, :advanced_tool_use]
)
```

### Error handling

```ruby
begin
  result = client.create(model: 'claude-sonnet-4-6', messages: messages, max_tokens: 512)
rescue Legion::Extensions::Claude::Helpers::Errors::RateLimitError => e
  puts "Rate limited (#{e.status}): #{e.message}"
rescue Legion::Extensions::Claude::Helpers::Errors::AuthenticationError
  puts 'Check your API key'
rescue Legion::Extensions::Claude::Helpers::Errors::ApiError => e
  puts "API error #{e.status}: #{e.message}"
end
```

### Auto-retry

```ruby
result = Legion::Extensions::Claude::Helpers::Retry.with_retry(max_attempts: 3) do
  client.create(model: 'claude-sonnet-4-6', messages: messages, max_tokens: 512)
end
```

## Dependencies

- `faraday` >= 2.0 — HTTP client
- `multi_json` — JSON parser abstraction

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (optional for standalone client usage)
- Anthropic API key

## Related

- `lex-bedrock` — Access Claude models via AWS Bedrock
- `legion-llm` — High-level LLM interface
- `extensions-ai/CLAUDE.md` — Architecture patterns shared across all AI extensions

## License

MIT
