# frozen_string_literal: true

require "test_helper"
require "lrama/ruby/action_scanner"

class ActionScannerTest < Test::Unit::TestCase
  Scanner = Lrama::Ruby::ActionScanner

  def scan(source, **options)
    Scanner.new(source).scan(**options)
  end

  def reference_texts(source)
    scan(source).references.map { |ref| source.byteslice(ref.first_column...ref.last_column) }
  end

  test "action stops before its closing brace and preserves byte offsets" do
    source = "text = \"日本語\"; $$ = $12 + $left } following grammar {"
    result = scan(source, action: true)
    assert_equal(source.b.index("} following"), result.end_offset)
    assert_equal(["$$", "$12", "$left"], result.references.map { |r| source.byteslice(r.first_column...r.last_column) })
    assert_equal([nil, 12, nil], result.references.map(&:number))
    assert_equal(["$", nil, "left"], result.references.map(&:name))
  end

  test "strings comments and variable names do not become references" do
    source = <<~'RUBY'
      @foo = @@foo
      # } $comment
      =begin
      } $comment
      =end
      a = '$single }'
      b = "$double } \""
      c = `echo '$backtick }'`
      $$ = $real
    RUBY
    assert_equal(["$$", "$real"], reference_texts(source))
  end

  test "nested interpolation and shorthand references are distinguished" do
    source = <<~'RUBY'
      $$ = "#{ { value: "#{$1}" } } #$left #@foo #@@foo \#$ignored"
    RUBY
    refs = scan(source).references
    assert_equal(["$$", "$1", "$left"], reference_texts(source))
    assert_equal([false, false, true], refs.map(&:short_interpolation))
  end

  test "percent literal nesting and interpolation follow literal type" do
    %w[q w i s].each do |kind|
      source = "%#{kind}{nested { } $ignored \#{ $ignored } }"
      assert_empty(scan(source).references, kind)
    end
    %w[Q W I x].each do |kind|
      source = "%#{kind}{nested { } $ignored \#{ $1 } }"
      assert_equal(["$1"], reference_texts(source), kind)
    end
    ["%{\#{ $1 }}", "%Q(\#{ $1 })", "%Q[\#{ $1 }]", "%Q<\#{ $1 }>", "%Q!\#{ $1 }!"].each do |source|
      assert_equal(["$1"], reference_texts(source))
    end
  end

  test "regexp classes escapes and interpolation preserve action boundaries" do
    sources = [
      '/[}$]/', '/[[:alpha:]}]/', '/[]}$]/', '/[\]}/]/',
      '%r{[}]\#{ignored}}', '/foo\/bar}/', '/\#{ { a: $1 } }/'
    ]
    sources.each do |source|
      result = scan(source + " } next", action: true)
      assert_equal(source.bytesize + 1, result.end_offset, source)
    end
    assert_equal(["$1"], reference_texts('/#{ { a: $1 } }/'))
    assert_equal(["$1"], reference_texts('%r!#{ $1 }!im'))
  end

  test "division modulo shifts and explicit calls are supported" do
    ["$1 / $2", "$1 % $2", "$1 << $2", "(value) / 2", "(value) % 2", "(value) << 2",
     "call(%r!}! )", "obj./(2)", "obj.%(2)", "obj.<<(2)"].each do |source|
      assert_nothing_raised(source) { scan(source) }
    end
  end

  test "ordinary Ruby declarations and operators are supported" do
    ["value / 2", "value % 2", "value << 2", "def value; end", "alias other value", "undef value"].each do |source|
      assert_nothing_raised(source) { scan(source) }
    end
  end

  test "the lexer can scan its own Ruby source" do
    [__FILE__, File.expand_path("../../lib/lrama/ruby/action_scanner.rb", __dir__)].each do |path|
      assert_nothing_raised(path) { scan(File.binread(path)) }
    end
  end

  test "heredoc references are ordered by physical source position" do
    source = <<~'RUBY'
      $$ = [<<ONE, $1, <<-'TWO', <<~"THREE"]
      one: #{$2}
      ONE
        } #{$ignored}
        TWO
        three: #$name
        THREE
      $last
    RUBY
    assert_equal(["$$", "$1", "$2", "$name", "$last"], reference_texts(source))
    assert_equal([false, false, false, true, false], scan(source).references.map(&:short_interpolation))
  end

  test "heredoc inside interpolation has its own pending bodies" do
    source = <<~'RUBY'
      $$ = <<OUTER
      #{ [<<INNER, $1]
      inner #{$2}
      INNER
      }
      OUTER
    RUBY
    assert_equal(["$$", "$1", "$2"], reference_texts(source))
  end

  test "quoted heredoc delimiter and CRLF are preserved" do
    source = "$$ = <<-`END TEXT`\r\n\#{ $1 } }\r\n\tEND TEXT\r\n } tail"
    result = scan(source, action: true)
    assert_equal(source.b.index("} tail"), result.end_offset)
    assert_equal(["$$", "$1"], result.references.map { |r| source.byteslice(r.first_column...r.last_column) })
  end

  test "symbols character literals lambdas and hashes protect braces" do
    source = <<~'RUBY'
      [:'}', :"#{ $1 }", :+, :[], ?}, ?あ, ?\u{7d}, ?\M-\C-a,
       ->(x) { { x: $2 } }]
    RUBY
    assert_equal(["$1", "$2"], reference_texts(source))
  end

  test "unsupported references fail in code and interpolation only" do
    %w[$0 $01 $& $~ $? $! $-w $<int>1 $[name] $1name $:].each do |ref|
      assert_raise(Scanner::Error, ref) { scan(ref) }
      assert_raise(Scanner::Error, ref) { scan('"#{' + ref + '}"') }
      assert_empty(scan("'#{ref}'").references)
    end
  end

  test "unclosed constructs and mismatched brackets report source positions" do
    ["'text", '"text', '%q{text', '/[abc/', '"#{ $1', "([)]", "(1", "$$ = <<X\nno end\n",
      "=begin\nno end\n", "?\\", "%Q", "__END__"].each do |source|
      error = assert_raise(Scanner::Error, source) { scan(source) }
      assert_include(error.message, "(grammar):")
    end
    error = assert_raise(Scanner::Error) do
      Scanner.new("\"日本語\"\r\n$0", filename: "test.y", line: 10, column: 5).scan
    end
    assert_include(error.message, "test.y:11:0:")
    assert_raise(Scanner::Error) { scan("$$ = 1", action: true) }
    assert_raise(Scanner::Error) { scan("$$ = <<X }\ntext\nX\n", action: true) }
  end

  test "large inputs and bounded nested interpolation terminate" do
    source = "'#{'}$ignored' * 10_000}' + $1"
    assert_equal(["$1"], reference_texts(source))
    source = ('"#{' * 200) + "1" + ('}"' * 200)
    error = assert_raise(Scanner::Error) { scan(source) }
    assert_include(error.message, "Interpolation nesting exceeds")
  end
end
