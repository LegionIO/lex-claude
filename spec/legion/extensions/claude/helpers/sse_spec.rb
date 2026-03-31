# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/claude/helpers/sse'

RSpec.describe Legion::Extensions::Claude::Helpers::Sse do
  let(:mod) { described_class }

  let(:sample_stream) do
    <<~SSE
      event: message_start
      data: {"type":"message_start","message":{"id":"msg_1","role":"assistant","content":[],"model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}

      event: content_block_start
      data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":", world!"}}

      event: content_block_stop
      data: {"type":"content_block_stop","index":0}

      event: message_delta
      data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}

      event: message_stop
      data: {"type":"message_stop"}

    SSE
  end

  describe '.parse_stream' do
    let(:events) { mod.parse_stream(sample_stream) }

    it 'returns an array of event hashes' do
      expect(events).to be_an(Array)
    end

    it 'parses message_start event' do
      start_event = events.find { |e| e[:event] == 'message_start' }
      expect(start_event).not_to be_nil
      expect(start_event[:data]['message']['id']).to eq('msg_1')
    end

    it 'parses all content_block_delta events' do
      deltas = events.select { |e| e[:event] == 'content_block_delta' }
      expect(deltas.length).to eq(2)
      expect(deltas.first[:data]['delta']['text']).to eq('Hello')
    end

    it 'parses message_stop' do
      stop = events.find { |e| e[:event] == 'message_stop' }
      expect(stop).not_to be_nil
    end

    it 'skips ping events by default' do
      stream_with_ping = "event: ping\ndata: {}\n\n#{sample_stream}"
      events_with_ping = mod.parse_stream(stream_with_ping)
      ping_events = events_with_ping.select { |e| e[:event] == 'ping' }
      expect(ping_events).to be_empty
    end
  end

  describe '.collect_text' do
    it 'assembles full text from delta events' do
      events = mod.parse_stream(sample_stream)
      text   = mod.collect_text(events)
      expect(text).to eq('Hello, world!')
    end
  end

  describe '.collect_usage' do
    it 'returns a usage hash with input and output tokens from the stream' do
      events = mod.parse_stream(sample_stream)
      usage  = mod.collect_usage(events)
      expect(usage[:input_tokens]).to eq(10)
      expect(usage[:output_tokens]).to eq(5)
    end

    it 'includes cache tokens when present in stream' do
      cached_stream = <<~SSE
        event: message_start
        data: {"type":"message_start","message":{"id":"msg_c","usage":{"input_tokens":8,"output_tokens":0,"cache_read_input_tokens":500,"cache_creation_input_tokens":200}}}

        event: message_delta
        data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":10}}

        event: message_stop
        data: {"type":"message_stop"}

      SSE
      events = mod.parse_stream(cached_stream)
      usage  = mod.collect_usage(events)
      expect(usage[:input_tokens]).to eq(8)
      expect(usage[:output_tokens]).to eq(10)
      expect(usage[:cache_read_tokens]).to eq(500)
      expect(usage[:cache_write_tokens]).to eq(200)
    end

    it 'defaults cache fields to zero when absent' do
      events = mod.parse_stream(sample_stream)
      usage  = mod.collect_usage(events)
      expect(usage[:cache_read_tokens]).to eq(0)
      expect(usage[:cache_write_tokens]).to eq(0)
      expect(usage[:cache_ephemeral_1h_tokens]).to eq(0)
      expect(usage[:cache_ephemeral_5m_tokens]).to eq(0)
      expect(usage[:cache_deleted_tokens]).to eq(0)
    end
  end
end
