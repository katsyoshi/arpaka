# frozen_string_literal: true

require "json"
require "tmpdir"

require_relative "test_helper"
require_relative "../benchmark/compatibility"

class BenchmarkCompatibilityTest < Test::Unit::TestCase
  def test_ractor_checks_fixture_with_pre_generated_frontend
    ruby_source = File.expand_path("../vendor/ruby", __dir__)
    Dir.mktmpdir("compatibility-test-") do |directory|
      frontend = File.join(directory, "frontend.rb")
      reference = File.join(directory, "reference.jsonl")
      source_file = File.expand_path("../benchmark/fixtures/basic_match.rb", __dir__)

      File.write(frontend, Arpaka.generate(ruby_source: ruby_source, class_name: "CompatibilityFrontend"))
      source = File.binread(source_file).force_encoding(Encoding::UTF_8)
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))
      normalized = [:sequence, normalized.nil? ? [] : [normalized]] unless normalized.is_a?(Array) && normalized.first == :sequence
      File.write(reference, JSON.generate(
        "type" => "reference", "corpus" => "fixture", "path" => "basic_match.rb",
        "sha256" => Digest::SHA256.hexdigest(source), "status" => "ok",
        "elapsed_seconds" => 0.0, "tree" => normalized
      ) + "\n")

      results, = Compatibility::Runner.new(
        ruby_source: ruby_source,
        corpora: [["fixture", source_file]],
        frontend: frontend,
        reference_cache: reference,
        parallel: :ractor,
        threads: 1
      ).run

      assert_equal 1, results.length
      assert_not_include %w[parse_failure timeout error], results.first.fetch("status")
      assert_equal "ok", results.first.fetch("outcomes").fetch("arpaka").fetch("status")
    end
  end
end
