# frozen_string_literal: true

require "optparse"
require "tempfile"
require_relative "../arpaka"

module Arpaka
  class CLI
    def self.run(argv, out: $stdout, err: $stderr)
      options = { class_name: "RubyParser" }
      force = false
      help = false
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: arpaka generate --ruby-source DIR --output FILE [--class-name NAME] [--force]"
        opts.on("--ruby-source DIR", "Ruby source tree (provided by the user)") { |v| options[:ruby_source] = v }
        opts.on("--output FILE", "Write a standalone Ruby frontend") { |v| options[:output] = v }
        opts.on("--class-name NAME", "Generated class name (default: RubyParser)") { |v| options[:class_name] = v }
        opts.on("--force", "Replace an existing output file") { force = true }
        opts.on("-h", "--help", "Show usage") { help = true }
      end
      args = argv.dup
      command = args.shift
      if ["--help", "-h"].include?(command)
        out.puts(parser)
        return 0
      end
      raise OptionParser::InvalidArgument, "expected generate" unless command == "generate"
      parser.parse!(args)
      if help
        out.puts(parser)
        return 0
      end
      raise OptionParser::InvalidArgument, args.join(" ") unless args.empty?
      %i[ruby_source output].each do |key|
        raise OptionParser::MissingArgument, "--#{key.to_s.tr('_', '-')}" unless options[key]
      end
      output = File.expand_path(options.delete(:output))
      if !force && (File.exist?(output) || File.symlink?(output))
        raise Error, "Output already exists: #{output}; use --force to replace it"
      end
      source = Arpaka.generate(**options)
      Tempfile.create([".arpaka-", ".rb"], File.dirname(output)) do |file|
        file.write(source)
        file.flush
        file.chmod(0o644)
        if force
          File.rename(file.path, output)
        else
          # Publish only the complete file, without overwriting a concurrent writer.
          File.link(file.path, output)
        end
      end
      out.puts("Generated #{output}")
      0
    rescue OptionParser::ParseError, Lrama::Ruby::Error, SystemCallError => error
      err.puts("arpaka: #{error.message}")
      1
    end
  end
end
