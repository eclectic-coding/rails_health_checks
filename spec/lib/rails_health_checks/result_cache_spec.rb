# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::ResultCache do
  subject(:cache) { described_class.new }

  describe "#fetch" do
    it "calls the block on the first access and returns its value" do
      result = cache.fetch("key", ttl: 60) { :fresh }
      expect(result).to eq(:fresh)
    end

    it "returns the cached value without calling the block again within TTL" do
      calls = 0
      cache.fetch("key", ttl: 60) { calls += 1; :value }
      result = cache.fetch("key", ttl: 60) { calls += 1; :value }

      expect(calls).to eq(1)
      expect(result).to eq(:value)
    end

    it "re-executes the block after TTL expires" do
      calls = 0
      cache.fetch("key", ttl: 0.01) { calls += 1 }
      sleep 0.02
      cache.fetch("key", ttl: 0.01) { calls += 1 }

      expect(calls).to eq(2)
    end

    it "caches different keys independently" do
      cache.fetch("a", ttl: 60) { :a }
      cache.fetch("b", ttl: 60) { :b }

      expect(cache.fetch("a", ttl: 60) { :miss }).to eq(:a)
      expect(cache.fetch("b", ttl: 60) { :miss }).to eq(:b)
    end
  end

  describe "#clear" do
    it "removes all cached entries so the next fetch re-executes the block" do
      cache.fetch("key", ttl: 60) { :original }
      cache.clear
      result = cache.fetch("key", ttl: 60) { :refreshed }

      expect(result).to eq(:refreshed)
    end
  end
end
