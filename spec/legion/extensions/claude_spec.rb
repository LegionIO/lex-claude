# frozen_string_literal: true

RSpec.describe Legion::Extensions::Claude do
  it 'has a version number' do
    expect(Legion::Extensions::Claude::VERSION).not_to be_nil
  end

  it 'has a version that is a string' do
    expect(Legion::Extensions::Claude::VERSION).to be_a(String)
  end
end
