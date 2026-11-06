# frozen_string_literal: true

require "optparse"
require "tempfile"
require_relative "sample_runner"

module Arpaka
  module Plugins
    class CLI
      def self.run(argv, out: $stdout, err: $stderr)
        options = { class_name: "SampleParser" }
        force = false
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: arpaka sample generate -y FILE -o FILE [--class-name NAME] [--force]"
          opts.on("-y FILE", "--grammar FILE", "Grammar file") { |v| options[:grammar] = v }
          opts.on("-c NAME", "--class-name NAME", "Generated class name (default: SampleParser)") do |v|
            options[:class_name] = v
          end
          opts.on("-o FILE", "--output FILE", "Write the generated parser") { |v| options[:output] = v }
          opts.on("--force", "Replace an existing output file") { force = true }
          opts.on("-h", "--help", "Show usage") { out.puts(parser); return 0 }
        end

        args = argv.dup
        command = args.shift
        if ["--help", "-h"].include?(command)
          out.puts(parser)
          return 0
        end
        raise OptionParser::InvalidArgument, "expected generate" unless command == "generate"
        parser.parse!(args)
        raise OptionParser::InvalidArgument, args.join(" ") unless args.empty?
        raise OptionParser::MissingArgument, "--grammar" unless options[:grammar]
        raise OptionParser::MissingArgument, "--output" unless options[:output]

        output = File.expand_path(options.delete(:output))
        if !force && (File.exist?(output) || File.symlink?(output))
          raise ::Arpaka::Error, "Output already exists: #{output}; use --force to replace it"
        end

        source = SampleRunner.generate(**options)
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
end
