# frozen_string_literal: true

module Compatibility
  class Unsupported < StandardError
    attr_reader :side, :detail

    def initialize(side, detail)
      @side = side
      @detail = detail
      super("#{side}: #{detail}")
    end
  end

  class Normalizer
    MISSING = [:missing].freeze

    def arpaka(node)
      return nil if node.nil?
      return [:symbol, text(node.to_s)] if node.is_a?(Symbol)
      return [:sequence, node.map { |item| arpaka(item) }] if node.is_a?(Array)
      name = node.class.name.to_s.split("::").last
      fields = node.members.map(&:to_sym)
      expected = {
        "Program" => [:statements], "Sequence" => [:statements], "Literal" => [:value], "EncodingLiteral" => [:value], "Self" => [],
        "LocalRead" => [:name], "LocalWrite" => [:name, :value], "BareCall" => [:name],
        "Assignment" => [:target, :value], "OpAssign" => [:target, :operator, :value],
        "MultipleAssign" => [:targets, :rest, :post, :value], "Field" => [:receiver, :operator, :name],
        "Alias" => [:kind, :new_name, :old_name], "Undef" => [:names],
        "Call" => [:name, :arguments], "Super" => [:arguments], "BlockPass" => [:arguments, :value],
        "ReceiverCall" => [:receiver, :operator, :name, :arguments], "Parameter" => [:kind, :name, :value],
        "Pattern" => [:kind, :values],
        "ArrayLiteral" => [:elements], "HashLiteral" => [:pairs],
        "KeywordArguments" => [:pairs], "Pair" => [:key, :value],
        "Binary" => [:operator, :left, :right], "Unary" => [:operator, :operand],
        "If" => [:condition, :then_body, :else_body], "RangeLiteral" => [:operator, :begin_value, :end_value],
        "Ternary" => [:condition, :then_value, :else_value], "StringLiteral" => [:value],
        "InterpolatedString" => [:parts], "DynamicSymbol" => [:parts],
        "RegexpLiteral" => [:value, :options, :encoding, :once], "Def" => [:name, :arguments, :body],
        "BlockCall" => [:call, :parameters, :body], "BlockParameters" => [:kind, :value],
        "Variable" => [:kind, :name], "Index" => [:receiver, :arguments],
        "Control" => [:kind, :value], "Case" => [:expression, :whens, :else_body],
        "When" => [:patterns, :body], "Loop" => [:kind, :condition, :body],
        "Rescue" => [:expression, :fallback], "XStringLiteral" => [:value],
        "FullRescue" => [:body, :clauses, :else_body, :ensure_body],
        "RescueClause" => [:exceptions, :variable, :body],
        "ClassDef" => [:name, :superclass, :body], "ModuleDef" => [:name, :body],
        "BeginBlock" => [:body], "EndBlock" => [:body],
        "ConstantPath" => [:receiver, :name], "AbsoluteConstant" => [:name],
        "SingletonMethodDef" => [:receiver, :name, :arguments, :body],
        "SingletonClassDef" => [:receiver, :body], "Lambda" => [:arguments, :body],
        "For" => [:variable, :enumerable, :body],
        "Splat" => [:value]
      }[name]
      unsupported!(:arpaka, "node #{name}") unless expected
      # Older generated frontends expose BlockCall as (call, body) and did
      # not retain explicit block parameters. Treat that shape as nil
      # parameters so it keeps the legacy comparison semantics.
      expected = [:call, :body] if name == "BlockCall" && fields == [:call, :body]
      # Older generated frontends expose only the regexp pattern. Fill in the
      # metadata defaults used by the current AST so static literals retain
      # their legacy comparison semantics.
      values = if name == "RegexpLiteral" && fields == [:value]
        expected = [:value]
        pattern = node.value
        {
          value: pattern,
          options: 0,
          encoding: pattern.is_a?(String) ? Encoding::UTF_8.name : nil,
          once: false
        }
      end
      # Current frontends omit the nil value field for controls without an
      # argument. Treat that abbreviated shape as the legacy equivalent.
      values ||= if name == "Control" && fields == [:kind]
        expected = [:kind]
        { kind: node.kind, value: nil }
      end
      unsupported!(:arpaka, "#{name} fields #{fields.inspect}, expected #{expected.inspect}") unless fields == expected
      values ||= fields.to_h { |field| [field, node.public_send(field)] }
      case name
      when "Program", "Sequence" then [:sequence, values[:statements].map { |item| arpaka(item) }]
      when "Literal"
        case values[:value]
        when :__FILE__ then [:file, text("".b)]
        when Symbol then [:symbol, text(values[:value].to_s)]
        when String then [:string, text(values[:value])]
        when Integer then [:integer, values[:value]]
        when Float then [:float, [values[:value]].pack("G").unpack1("H*")]
        when Rational then rational(values[:value])
        when Complex then complex(values[:value])
        else [:literal, atom(values[:value], :arpaka)]
        end
      when "EncodingLiteral" then [:encoding, values[:value].to_s]
      when "Self" then [:self]
      when "Alias"
        [:alias, symbol(values[:kind]), arpaka_alias_name(values[:new_name]), arpaka_alias_name(values[:old_name])]
      when "Undef" then [:undef, Array(values[:names]).map { |name| arpaka_alias_name(name) }]
      when "LocalRead" then [:local_read, symbol(values[:name])]
      when "LocalWrite" then arpaka_write(values[:name], values[:value])
      when "BareCall" then [:bare_call, symbol(values[:name])]
      when "Call"
        arguments = arpaka_arguments(values[:arguments])
        values[:name] == :defined && arguments.length == 1 ? [:defined, arguments.first] :
          [:call, nil, false, symbol(values[:name]), arguments]
      when "Super"
        [:super, values[:arguments].nil? ? MISSING : arpaka_arguments(values[:arguments])]
      when "BlockPass"
        [:block_pass, arpaka_arguments(values[:arguments]), arpaka(values[:value])]
      when "ReceiverCall"
        unless [:".", :"::", :"&."].include?(values[:operator])
          unsupported!(:arpaka, "receiver operator #{values[:operator].inspect}")
        end
        [:call, arpaka(values[:receiver]), values[:operator] == :"&.", symbol(values[:name]), arpaka_arguments(values[:arguments])]
      when "ArrayLiteral" then [:array, Array(values[:elements]).map { |v| arpaka(v) }]
      when "Splat" then [:splat, arpaka_splat_value(values[:value])]
      when "HashLiteral" then [:hash, values[:pairs].map { |v| arpaka(v) }]
      when "KeywordArguments" then [:keyword_arguments, values[:pairs].map { |v| arpaka(v) }]
      when "Pair"
        key = values[:key].nil? ? [:missing_child] : arpaka(values[:key])
        [:pair, key, arpaka(values[:value])]
      when "Binary"
        left = arpaka(values[:left])
        right = arpaka(values[:right])
        if values[:operator] == :=~
          left_regexp = ast_name(values[:left]) == "RegexpLiteral"
          dynamic_right_regexp = ast_name(values[:right]) == "RegexpLiteral" && values[:right].value.is_a?(Array)
          unless left_regexp || dynamic_right_regexp
            return [:call, left, false, symbol(:=~), [right]]
          end
        end
        if values[:operator] == :=~
          [left, right].each do |operand|
            if operand.is_a?(Array) && operand.first == :interpolated_regexp
              operand[2] = ["unknown", "options"]
              operand[3] = ["unknown", "encoding"]
            end
          end
        end
        result = [:binary, symbol(logical_operator(values[:operator])), left, right]
        if values[:operator] == :=~
          captures = arpaka_regexp_capture_names(values[:left])
          result << [:captures, captures] unless captures.empty?
        end
        result
      when "Unary"
        operand = values[:operand]
        normalized_operand = arpaka(operand)
        if values[:operator] == :! && ast_name(operand) == "Binary" &&
            [:'&&', :'||'].include?(operand.operator) && defined_expression?(normalized_operand[2])
          return [:binary, symbol(operand.operator),
            [:unary, symbol(:!), normalized_operand[2]], normalized_operand[3]]
        end
        if [:+, :-].include?(values[:operator]) && operand.class.name.to_s.split("::").last == "Literal" && operand.value.is_a?(Numeric)
          value = values[:operator] == :- ? -operand.value : +operand.value
          value.is_a?(Integer) ? [:integer, value] : [:float, [value].pack("G").unpack1("H*")]
        else
          [:unary, symbol(values[:operator]), normalized_operand]
        end
      when "If" then [:conditional, arpaka(values[:condition]), body(values[:then_body]), body(values[:else_body])]
      when "RangeLiteral"
        [:range, symbol(values[:operator]), range_endpoint(values[:begin_value]), range_endpoint(values[:end_value])]
      when "Ternary" then [:conditional, arpaka(values[:condition]), [arpaka(values[:then_value])], [arpaka(values[:else_value])]]
      when "StringLiteral" then [:string, text(values[:value])]
      when "InterpolatedString"
        parts = merge_text_parts(values[:parts].map do |v|
          v.is_a?(String) ? [:text, text(v)] : [:interpolation, arpaka(v)]
        end)
        dynamic_string(parts) || [:interpolated, parts]
      when "DynamicSymbol"
        [:dynamic_symbol, merge_text_parts(values[:parts].map do |v|
          v.is_a?(String) ? [:text, text(v)] : [:interpolation, arpaka(v)]
        end)]
      when "RegexpLiteral"
        value = values[:value]
        if value.is_a?(String)
          regexp(regexp_source(value).b.unpack1("H*"), values[:options], values[:encoding])
        elsif value.is_a?(Array)
          normalized = [:interpolated_regexp, arpaka_dynamic_parts(value), ["unknown", "options"], ["unknown", "encoding"]]
          normalized << ["known", true] if values[:once]
          normalized
        else
          unsupported!(:arpaka, "regexp value #{value.class}")
        end
      when "Def"
        args = arpaka_method_arguments(values[:arguments])
        [:def, symbol(values[:name]), args, method_body(values[:body])]
      when "BlockCall" then [:block, arpaka(values[:call]), block_parameters(values[:parameters]), body(values[:body])]
      when "BlockParameters" then block_parameters_node(values[:kind], values[:value])
      when "Parameter"
        [:parameter, symbol(values[:kind]), values[:name].nil? ? MISSING : symbol(values[:name]), arpaka(values[:value])]
      when "Pattern"
        kind = values[:kind].to_sym
        pattern_values = case kind
        when :array
          pre, rest, post = values[:values]
          [Array(pre).map { |item| arpaka(item) }, arpaka_pattern_rest(rest), Array(post).map { |item| arpaka(item) }]
        when :hash
          pairs, rest, constant = values[:values]
          normalized = [Array(pairs).map { |pair| arpaka(pair) }, arpaka_pattern_rest(rest)]
          normalized << arpaka(constant) unless constant.nil?
          normalized
        when :find
          pre_rest, items, post_rest = values[:values]
          [arpaka(pre_rest), Array(items).map { |item| arpaka(item) }, arpaka(post_rest)]
        when :rest
          [arpaka_pattern_value(values[:values].first)]
        when :variable
          [symbol(values[:values].first)]
        when :pin
          [arpaka(values[:values].first)]
        when :guard, :guard_unless
          [arpaka(values[:values].first), arpaka(values[:values].last)]
        else
          values[:values].map { |item| arpaka(item) }
        end
        [:pattern, symbol(kind), pattern_values]
      when "Index" then [:call, arpaka(values[:receiver]), false, symbol(:[]), arpaka_arguments(values[:arguments])]
      when "Control" then [:control, symbol(values[:kind]), arpaka(values[:value])]
      when "Case"
        [:case, arpaka(values[:expression]), values[:whens].map { |clause| arpaka(clause) }, body(values[:else_body])]
      when "When"
        patterns = values[:patterns].is_a?(Array) ? values[:patterns] : [values[:patterns]]
        [:when, patterns.map { |pattern| arpaka(pattern) }, body(values[:body])]
      when "Loop"
        # RubyVM stores whether the loop body is evaluated before the first
        # condition check as a trailing boolean on WHILE/UNTIL. Arpaka's
        # public Loop node intentionally keeps the structural shape only, so
        # recover the value from the nested body shape used for begin-style
        # loops instead of adding a VM-specific field to the AST.
        begin_style = values[:body].is_a?(Array) && values[:body].length == 1 &&
          values[:body].first.is_a?(Array)
        loop_body = begin_style ? values[:body].first : values[:body]
        [:loop, symbol(values[:kind]), arpaka(values[:condition]), body(loop_body), !begin_style]
      when "BeginBlock" then [:begin_block, body(values[:body])]
      when "EndBlock" then [:end_block, body(values[:body])]
      when "For" then [:for, arpaka_target(values[:variable]), arpaka(values[:enumerable]), body(values[:body])]
      when "Rescue" then [:rescue_modifier, arpaka(values[:expression]), arpaka(values[:fallback])]
      when "XStringLiteral"
        value = values[:value]
        value.is_a?(Array) ? [:dynamic_xstring, arpaka_dynamic_parts(value)] : [:xstring, text(value)]
      when "Assignment" then arpaka_write(values[:target], values[:value])
      when "OpAssign"
        target = values[:target]
        if ast_name(target) == "Field"
          [:op_assign_attribute, arpaka(target.receiver), false, symbol(target.name),
            symbol(values[:operator]), arpaka(values[:value])]
        elsif ast_name(target) == "Index"
          [:op_assign_index, arpaka(target.receiver), arpaka_arguments(target.arguments),
            symbol(values[:operator]), arpaka(values[:value])]
        elsif target.is_a?(Symbol)
          name = symbol(target)
          value = arpaka(values[:value])
          if [:"&&", :"||"].include?(values[:operator])
            # RubyVM represents a logical local opassign as a read followed by
            # the write. Keep the public OpAssign AST unchanged and normalize
            # only the comparison shape here.
            [:op_assign, [:local_read, name], symbol(values[:operator]),
              [:local_write, name, value]]
          else
            [:local_write, name, [:call, [:local_read, name], false,
              symbol(values[:operator]), [value]]]
          end
        elsif ast_name(target) == "Variable"
          name = symbol(target.name)
          read = variable_read(target.kind, target.name, :arpaka)
          value = arpaka(values[:value])
          if [:"&&", :"||"].include?(values[:operator])
            [:op_assign, read, symbol(values[:operator]),
              variable_write(target.kind, target.name, value, :arpaka)]
          else
            variable_write(target.kind, target.name,
              [:call, read, false, symbol(values[:operator]), [value]], :arpaka)
          end
        else
          [:op_assign, arpaka_target(target), symbol(values[:operator]), arpaka(values[:value])]
        end
      when "MultipleAssign"
        result = [:multiple_assign, Array(values[:targets]).map { |target| arpaka_target(target) },
          values[:rest] && arpaka_target(values[:rest]), arpaka(values[:value])]
        post = Array(values[:post]).map { |target| arpaka_target(target) }
        result.insert(3, post) unless post.empty?
        result
      when "Field" then [:field, arpaka(values[:receiver]), symbol(values[:operator]), symbol(values[:name])]
      when "FullRescue"
        if values[:clauses].empty? && values[:else_body].nil? && !values[:ensure_body].nil?
          # RubyVM does not wrap an ensure-only expression in an empty rescue
          # node. Keep the frontend's FullRescue shape, but normalize it to
          # the VM's direct ensure body representation.
          [:ensure, body(values[:body]), body(values[:ensure_body])]
        elsif values[:ensure_body].nil?
          [:rescue, body(values[:body]), values[:clauses].map { |clause| arpaka(clause) }, body(values[:else_body])]
        else
          rescue_body = [:rescue, body(values[:body]), values[:clauses].map { |clause| arpaka(clause) }, body(values[:else_body])]
          [:ensure, [rescue_body], body(values[:ensure_body])]
        end
      when "RescueClause"
        [:rescue_clause, values[:exceptions].map { |exception| arpaka(exception) },
          values[:variable].nil? ? nil : arpaka_target(values[:variable]), body(values[:body])]
      when "ClassDef"
        [:class, arpaka_declaration_name(values[:name]), arpaka(values[:superclass]), body(values[:body])]
      when "ModuleDef"
        [:module, arpaka_declaration_name(values[:name]), body(values[:body])]
      when "SingletonMethodDef"
        [:singleton_def, arpaka(values[:receiver]), symbol(values[:name]),
          retained_arpaka_arguments(values[:arguments]), method_body(values[:body])]
      when "SingletonClassDef" then [:singleton_class, arpaka(values[:receiver]), body(values[:body])]
      when "Lambda" then [:lambda, retained_arpaka_arguments(values[:arguments]), body(values[:body])]
      when "Variable"
        variable_read(values[:kind], values[:name], :arpaka)
      when "ConstantPath" then [:constant_path, arpaka(values[:receiver]), symbol(values[:name])]
      when "AbsoluteConstant" then [:absolute_constant, symbol(values[:name])]
      end
    rescue NoMethodError => error
      unsupported!(:arpaka, "#{name} field access: #{error.message}")
    end

    def rubyvm(node)
      return nil if node.nil?
      unsupported!(:rubyvm, "expected AST node, got #{node.class}") unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
      c = node.children
      validate_arity!(node)
      case node.type
      when :SCOPE
        unsupported!(:rubyvm, "nested SCOPE")
      when :MASGN
        value, targets, rest = c
        normalized_value = if value.is_a?(RubyVM::AbstractSyntaxTree::Node) && value.type == :DVAR && value.children == [nil]
          nil
        else
          rubyvm(value)
        end
        rest_target = nil
        post_targets = []
        if rest.is_a?(RubyVM::AbstractSyntaxTree::Node) && rest.type == :POSTARG
          rest_target, post = rest.children
          rest_target = rubyvm_target(rest_target)
          post_targets = rubyvm_targets(post)
        else
          rest_target = rubyvm_target(rest)
        end
        result = [:multiple_assign, rubyvm_targets(targets), rest_target, normalized_value]
        result.insert(3, post_targets) unless post_targets.empty?
        result
      when :BLOCK
        rubyvm_block(node)
      when :BEGIN then c[0].nil? ? [:sequence, []] : rubyvm(c[0])
      when :POSTEXE
        scope = c.fetch(0)
        unsupported!(:rubyvm, "POSTEXE child is not a SCOPE") unless scope.is_a?(RubyVM::AbstractSyntaxTree::Node) && scope.type == :SCOPE
        [:end_block, vm_body(scope.children[2])]
      when :NIL then [:literal, nil]
      when :LINE then [:integer, c.fetch(0)]
      when :TRUE then [:literal, true]
      when :FALSE then [:literal, false]
      when :SELF then [:self]
      when :LIT, :INTEGER, :FLOAT
        value = c[0]
        if value.is_a?(Regexp)
          regexp(regexp_source(value.source).b.unpack1("H*"), value.options, value.encoding.name)
        elsif value.is_a?(Symbol)
          [:symbol, text(value.to_s)]
        elsif value.is_a?(Integer)
          [:integer, value]
        elsif value.is_a?(Float)
          [:float, [value].pack("G").unpack1("H*")]
        elsif value.is_a?(Rational)
          rational(value)
        elsif value.is_a?(Complex)
          complex(value)
        else
          [:literal, atom(value, :rubyvm)]
        end
      when :RATIONAL then rational(c[0])
      when :IMAGINARY, :COMPLEX then complex(c[0])
      when :SYM then [:symbol, text(c[0].to_s)]
      when :STR then [:string, text(c[0])]
      when :CONST then [:constant, symbol(c[0])]
      when :FILE then [:file, text(c[0])]
      when :NTH_REF then [:backref, backref_number(c[0])]
      when :BACK_REF then variable_read(:global, c[0], :rubyvm)
      when :COLON2 then rubyvm_expression_constant_path(c)
      when :COLON3 then [:absolute_constant, symbol(c[0])]
      when :LVAR then [:local_read, symbol(c[0])]
      when :DVAR then c[0].nil? ? [:implicit_keyword_rest] : [:local_read, symbol(c[0])]
      when :LASGN, :DASGN then [:local_write, symbol(c[0]), rubyvm(c[1])]
      when :IVAR then variable_read(:instance, c[0], :rubyvm)
      when :CVAR then variable_read(:class, c[0], :rubyvm)
      when :GVAR then variable_read(:global, c[0], :rubyvm)
      when :IASGN then variable_write(:instance, c[0], rubyvm(c[1]), :rubyvm)
      when :CVASGN then variable_write(:class, c[0], rubyvm(c[1]), :rubyvm)
      when :GASGN then variable_write(:global, c[0], rubyvm(c[1]), :rubyvm)
      when :CDECL then constant_declaration(c)
      when :VCALL then [:bare_call, symbol(c[0])]
      when :FCALL then [:call, nil, false, symbol(c[0]), args(c[1])]
      when :CALL, :QCALL then [:call, rubyvm(c[0]), node.type == :QCALL, symbol(c[1]), args(c[2])]
      when :ATTRASGN then attribute_assignment(c)
      when :BLOCK_PASS then [:block_pass, args(c[0]), rubyvm(c[1])]
      when :YIELD then [:call, nil, false, symbol(:yield), args(c[0])]
      when :OPCALL
        recv, name, list = c
        values = args(list)
        return [:unary, symbol({ :+@ => :+, :-@ => :- }.fetch(name, name)), rubyvm(recv)] if values.empty? && [:+@, :-@, :!, :~].include?(name)
        return [:binary, symbol(name), rubyvm(recv), values.fetch(0)] if values.length == 1
        unsupported!(:rubyvm, "OPCALL arity #{values.length}")
      when :MATCH2
        regexp, value, captures = c
        result = [:binary, symbol(:=~), rubyvm(regexp), rubyvm(value)]
        capture_names = rubyvm_match_capture_names(captures)
        result << [:captures, capture_names] unless capture_names.empty?
        result
      when :MATCH3
        regexp, value = c
        [:binary, symbol(:=~), rubyvm(value), rubyvm(regexp)]
      when :LIST then [:array, list_items(node)]
      when :ZLIST then [:array, []]
      when :SPLAT then [:array, [[:splat, rubyvm(c[0])]]]
      when :ARGSCAT then [:array, args(c[0]) + [[:splat, rubyvm(c[1])]]]
      when :ARGSPUSH then [:array, args(c[0]) + [rubyvm(c[1])]]
      when :ARRAY then [:array, list_items(c[0])]
      when :HASH
        entries = list_items(c[0])
        unsupported!(:rubyvm, "odd HASH entry count #{entries.length}") if entries.length.odd?
        [:hash, entries.each_slice(2).map { |key, value| [:pair, key, value] }]
      when :PAIR then [:pair, rubyvm(c[0]), rubyvm(c[1])]
      when :IF then [:conditional, rubyvm(c[0]), vm_body(c[1]), vm_body(c[2])]
      when :UNLESS then [:conditional, [:unary, symbol(:!), rubyvm(c[0])], vm_body(c[1]), vm_body(c[2])]
      when :CASE, :CASE2 then rubyvm_case(c)
      when :CASE3 then rubyvm_case3(c)
      when :FOR then rubyvm_for(c)
      when :ONCE
        regexp = rubyvm(c[0])
        unsupported!(:rubyvm, "ONCE child is not an interpolated regexp") unless regexp.is_a?(Array) && regexp.first == :interpolated_regexp
        regexp + [["known", true]]
      when :ALIAS then [:alias, symbol(:method), rubyvm(c[0]), rubyvm(c[1])]
      when :VALIAS then [:alias, symbol(:variable), symbol(c[0]), symbol(c[1])]
      when :UNDEF then [:undef, Array(c[0]).map { |name| rubyvm(name) }]
      when :AND, :OR
        operator = symbol(node.type == :AND ? :"&&" : :"||")
        values = c.map { |child| rubyvm(child) }
        values.drop(1).reduce(values.first) { |left, right| [:binary, operator, left, right] }
      when :DOT2, :DOT3 then [:range, symbol(node.type == :DOT2 ? :".." : :"..."), rubyvm(c[0]), rubyvm(c[1])]
      when :DREGX
        parts = dynamic_parts(c)
        if parts.all? { |part| part.first == :text }
          regexp(parts.map { |part| part.last }.join.b.unpack1("H*"), 0, Encoding::US_ASCII.name)
        else
          [:interpolated_regexp, parts, ["unknown", "options"], ["unknown", "encoding"]]
        end
      when :ENCODING
        [:encoding, c.fetch(0).name]
      when :DSYM
        parts = dynamic_parts(c)
        # RubyVM uses DSYM for some statically written symbol forms (notably
        # percent symbols), while Arpaka quite reasonably stores them as a
        # plain symbol literal.  There is no interpolation to preserve here.
        if parts.all? { |part| part.first == :text }
          [:symbol, text(parts.map { |part| part.last }.join)]
        else
          [:dynamic_symbol, parts]
        end
      when :DXSTR
        parts = dynamic_parts(c)
        if parts.all? { |part| part.first == :text }
          [:xstring, text(parts.map { |part| part.last }.join)]
        else
          [:dynamic_xstring, parts]
        end
      when :REGX
        value = c[0]
        if value.is_a?(Regexp)
          regexp(regexp_source(value.source).b.unpack1("H*"), value.options, value.encoding.name)
        else
          unsupported!(:rubyvm, "REGX value #{value.class}")
        end
      when :DSTR
        parts = dynamic_parts(c)
        dynamic_string(parts) || [:interpolated, parts]
      when :EVSTR then rubyvm(c[0])
      when :XSTR then [:xstring, text(c[0])]
      when :DEFN
        name, scope = c
        params, b = scope.children[1], scope.children[2]
        [:def, symbol(name), scoped_arguments(scope.children[0], params), vm_body(b)]
      when :DEFS
        receiver, name, scope = c
        params, b = scope.children[1], scope.children[2]
        [:singleton_def, rubyvm(receiver), symbol(name), scoped_arguments(scope.children[0], params), vm_body(b)]
      when :LAMBDA
        scope = c[0]
        [:lambda, scoped_arguments(scope.children[0], scope.children[1]), vm_body(scope.children[2])]
      when :SCLASS then [:singleton_class, rubyvm(c[0]), scoped_body(c[1])]
      when :WHILE, :UNTIL
        [:loop, symbol(node.type == :WHILE ? :while : :until), rubyvm(c[0]), vm_body(c[1]), c[2]]
      when :RETURN, :NEXT, :BREAK
        [:control, symbol(node.type.to_s.downcase.to_sym), rubyvm(c[0])]
      when :REDO, :RETRY then [:control, symbol(node.type.to_s.downcase.to_sym), nil]
      when :SUPER then [:super, args(c[0])]
      when :ZSUPER then [:super, MISSING]
      when :OP_ASGN_OR, :OP_ASGN_AND
        [:op_assign, rubyvm(c[0]), symbol(c[1]), rubyvm(c[2])]
      when :OP_ASGN1
        [:op_assign_index, rubyvm(c[0]), args(c[2]), symbol(c[1]), rubyvm(c[3])]
      when :OP_ASGN2
        [:op_assign_attribute, rubyvm(c[0]), c[1], symbol(c[2]), symbol(c[3]), rubyvm(c[4])]
      when :DEFINED then [:defined, rubyvm(c[0])]
      when :KW_ARG then rubyvm_keyword_arguments(node)
      when :ENSURE then [:ensure, vm_body(c[0]), vm_body(c[1])]
      when :RESCUE then rubyvm_rescue(node)
      when :ARGS then unsupported!(:rubyvm, "ARGS without scope context")
      when :OPT_ARG then [:optional_args, vm_body(c[0]), vm_body(c[1])]
      when :ITER
        call, scope = c
        [:block, rubyvm(call), scoped_arguments(scope.children[0], scope.children[1], block: true), vm_body(scope.children[2])]
      when :CLASS
        path, superclass, scope = c
        [:class, rubyvm_declaration_name(path), rubyvm(superclass), scoped_body(scope)]
      when :MODULE
        path, scope = c
        [:module, rubyvm_declaration_name(path), scoped_body(scope)]
      else unsupported!(:rubyvm, "node #{node.type}")
      end
    end

    private

    # The frontend keeps only the declared constant's final component for
    # qualified class/module declarations. RubyVM represents the same name as
    # a constant_path whose receiver is a constant. Keep the legacy comparison
    # shape by applying that projection only in declaration-name position.
    def rubyvm_declaration_name(node)
      normalized = rubyvm(node)
      if normalized.is_a?(Array) && normalized.first == :constant_path &&
          normalized[1].is_a?(Array) && normalized[1].first == :constant
        [:constant, normalized[2]]
      else
        normalized
      end
    end

    def rubyvm_expression_constant_path(children)
      receiver = rubyvm(children.fetch(0))
      name = symbol(children.fetch(1))
      receiver.is_a?(Array) && receiver.first == :constant ? [:constant, name] : [:constant_path, receiver, name]
    end

    def arpaka_arguments(value)
      arguments = value.is_a?(Array) ? value : value.nil? ? [] : [value]
      forwarding_index = arguments.index do |argument|
        ast_name(argument) == "Parameter" && argument.kind == :forwarding
      end
      return arguments.map { |argument| arpaka_argument(argument) } unless forwarding_index

      forwarded_arguments = arguments.take(forwarding_index).map { |argument| arpaka_argument(argument) }
      forwarded_arguments << [:splat, [:local_read, symbol(:*)]]
      forwarded_arguments << [:hash, [[:pair, [:missing_child], [:local_read, symbol(:**)]]]]
      [[:block_pass, forwarded_arguments, [:local_read, symbol(:&)]]]
    end

    def arpaka_argument(value)
      if value.is_a?(Array)
        [:splat, value.length == 1 ? arpaka(value.first) : [:sequence, value.map { |item| arpaka(item) }]]
      else
        arpaka(value)
      end
    end

    def arpaka_splat_value(value)
      if value.is_a?(Array)
        [:array, value.map { |item| arpaka(item) }]
      else
        arpaka(value)
      end
    end

    def retained_arpaka_arguments(value)
      arpaka_method_arguments(value)
    end

    def arpaka_method_arguments(value)
      parameters = value.is_a?(Array) ? value : value.nil? ? [] : [value]
      unless parameters.any? { |parameter| ast_name(parameter) == "Parameter" }
        return [:retained_arguments, parameters.map { |parameter| parameter.is_a?(Symbol) ? symbol(parameter) : arpaka(parameter) }]
      end

      required = []
      post = []
      optional = []
      optional_seen = false
      keywords = []
      rest = nil
      block = nil
      keyword_rest = nil
      keyword_rest_present = false
      keyword_rest_disabled = false
      forwarding = false
      parameters.each do |parameter|
        if parameter.is_a?(Symbol)
          (rest || optional_seen ? post : required) << symbol(parameter)
        elsif ast_name(parameter) == "Parameter"
          case parameter.kind
          when :optional
            optional << parameter
            optional_seen = true
          when :rest then rest = parameter.name.nil? ? :* : parameter.name
          when :block then block = parameter.name || :&
          when :keyword_required then keywords << [:required_keyword, symbol(parameter.name)]
          when :keyword_optional
            keywords << [:local_write, symbol(parameter.name), arpaka(parameter.value)]
          when :keyword_rest
            keyword_rest_present = true
            keyword_rest = [:local_read, symbol(parameter.name || :**)]
          when :keyword_rest_disabled then keyword_rest_disabled = true
          when :forwarding then forwarding = true
          else unsupported!(:arpaka, "method parameter kind #{parameter.kind.inspect}")
          end
        else
          unsupported!(:arpaka, "method parameter #{parameter.class}")
        end
      end

      result = [:retained_arguments, required]
      result << [:optional_defaults, arpaka_optional_parameters(optional)] unless optional.empty?
      unless post.empty?
        result << [:first_post, post.first]
        result << [:post_count, post.length]
        result << [:post_names, post]
      end
      result << [:rest, symbol(rest || :*)] if rest || forwarding
      result << [:keywords, [:keyword_parameters, keywords]] unless keywords.empty?
      if keyword_rest_disabled
        result << [:keywords, false] if keywords.empty?
        result << [:keyword_rest, false]
      elsif keyword_rest_present
        result << [:keyword_rest, keyword_rest]
      elsif forwarding
        result << [:keyword_rest, [:local_read, symbol(:**)]]
      elsif !keywords.empty?
        result << [:keyword_rest, [:implicit_keyword_rest]]
      end
      result << [:block, symbol(block || :&)] if block || forwarding
      result
    end

    def arpaka_block_pattern_target(value)
      if value.is_a?(Array)
        [:multiple_target, value.map { |name| arpaka_block_pattern_target(name) }]
      else
        [:local_target, symbol(value)]
      end
    end

    def arpaka_optional_parameters(parameters)
      parameters.reverse_each.reduce([]) do |next_optional, parameter|
        assignment = [:local_write, symbol(parameter.name), arpaka(parameter.value)]
        [:optional_args, [assignment], next_optional.empty? ? [] : [next_optional]]
      end
    end

    def block_parameters(value)
      return [:retained_arguments, []] if value.nil?
      unsupported!(:arpaka, "block parameters node #{ast_name(value)}") unless ast_name(value) == "BlockParameters"
      block_parameters_node(value.kind, value.value)
    end

    def block_parameters_node(kind, value)
      case kind
      when :none then [:retained_arguments, []]
      when :required
        parameters = Array(value)
        locals = parameters.select { |parameter| ast_name(parameter) == "BlockParameters" && parameter.kind == :locals }
        parameters = parameters.reject { |parameter| ast_name(parameter) == "BlockParameters" && parameter.kind == :locals }
        names = parameters.grep(Symbol).map { |name| symbol(name) }
        optional = parameters.select { |parameter| ast_name(parameter) == "Parameter" && parameter.kind == :optional }
        blocks = parameters.select { |parameter| ast_name(parameter) == "Parameter" && parameter.kind == :block }
        keywords = []
        keyword_rest = nil
        keyword_rest_present = false
        keyword_rest_disabled = false
        parameters.each do |parameter|
          next unless ast_name(parameter) == "Parameter"

          case parameter.kind
          when :keyword_required
            keywords << [:required_keyword, symbol(parameter.name)]
          when :keyword_optional
            keywords << [:local_write, symbol(parameter.name), arpaka(parameter.value)]
          when :keyword_rest
            keyword_rest_present = true
            keyword_rest = [:local_read, symbol(parameter.name || :**)]
          when :keyword_rest_disabled
            keyword_rest_disabled = true
          end
        end
        patterns = parameters.select do |parameter|
          ast_name(parameter) == "BlockParameters" && parameter.kind == :destructured
        end
        rests = parameters.select { |parameter| ast_name(parameter) == "BlockParameters" && parameter.kind == :rest }
        posts = parameters.select { |parameter| ast_name(parameter) == "BlockParameters" && parameter.kind == :post }
        result = [:retained_arguments, names]
        unless locals.empty?
          result << [:block_locals, locals.flat_map { |parameter| Array(parameter.value).map { |name| symbol(name) } }]
        end
        result << [:optional_defaults, arpaka_optional_parameters(optional)] unless optional.empty?
        unless patterns.empty?
          assignments = patterns.map do |pattern|
            targets = pattern.value.map { |name| arpaka_block_pattern_target(name) }
            [:multiple_assign, targets, nil, nil]
          end
          pre_init = assignments.length == 1 ? assignments.first : [:sequence, assignments]
          result << [:pre_init, pre_init]
        end
        unless posts.empty?
          post_names = posts.map { |parameter| symbol(parameter.value) }
          result << [:first_post, post_names.first]
          result << [:post_count, post_names.length]
          result << [:post_names, post_names]
        end
        unsupported!(:arpaka, "multiple rest block parameters") if rests.length > 1
        unless rests.empty?
          rest_name = rests.first.value.nil? ? :* : rests.first.value
          result << [:rest, symbol(rest_name)]
        end
        result << [:keywords, [:keyword_parameters, keywords]] unless keywords.empty?
        if keyword_rest_disabled
          result << [:keywords, false] if keywords.empty?
          result << [:keyword_rest, false]
        elsif keyword_rest_present
          result << [:keyword_rest, keyword_rest]
        elsif !keywords.empty?
          result << [:keyword_rest, [:implicit_keyword_rest]]
        end
        result << [:block, symbol(blocks.first.name || :&)] unless blocks.empty?
        result
      when :destructured
        targets = Array(value).map { |name| arpaka_block_pattern_target(name) }
        [:retained_arguments, [], [:pre_init, [:multiple_assign, targets, nil, nil]]]
      else unsupported!(:arpaka, "block parameter form #{kind.inspect}")
      end
    end

    def arpaka_declaration_name(value)
      if value.is_a?(Symbol)
        [:constant_path, nil, symbol(value)]
      elsif ast_name(value) == "Variable" && value.kind == :constant
        [:constant_path, nil, symbol(value.name)]
      else
        arpaka(value)
      end
    end

    def arpaka_alias_name(value)
      value.is_a?(Symbol) ? symbol(value) : arpaka(value)
    end

    def arpaka_write(target, value)
      normalized_value = arpaka(value)
      return [:local_write, symbol(target), normalized_value] if target.is_a?(Symbol)
      if ast_name(target) == "ConstantPath"
        return [:constant_write, arpaka(target), symbol(target.name), normalized_value]
      end
      if ast_name(target) == "AbsoluteConstant"
        return [:constant_write, nil, symbol(target.name), normalized_value]
      end
      if ast_name(target) == "Variable"
        return variable_write(target.kind, target.name, normalized_value, :arpaka)
      end
      if ast_name(target) == "Index"
        return [:index_write, arpaka(target.receiver), arpaka_arguments(target.arguments), normalized_value]
      end
      if ast_name(target) == "Field"
        return [:attribute_write, arpaka(target.receiver), symbol(target.name), [], normalized_value]
      end
      [:lost_write_target, arpaka(target), normalized_value]
    end

    def arpaka_target(target)
      return [:local_target, symbol(target)] if target.is_a?(Symbol)
      return [:multiple_target, target.map { |item| arpaka_target(item) }] if target.is_a?(Array)
      return [:variable_target, target.kind, symbol(target.name)] if ast_name(target) == "Variable"
      if ast_name(target) == "Index"
        return [:attribute_target, arpaka(target.receiver), symbol(:[]=), arpaka_arguments(target.arguments)]
      end
      if ast_name(target) == "Field"
        return [:attribute_target, arpaka(target.receiver), symbol("#{target.name}=".to_sym), []]
      end
      [:lost_target, arpaka(target)]
    end

    def ast_name(value)
      value.class.name.to_s.split("::").last
    end

    def variable_read(kind, name, side)
      return [:constant, symbol(name)] if kind == :constant
      return [:backref, name] if kind == :backref
      unsupported!(side, "Variable kind #{kind.inspect}") unless [:instance, :class, :global].include?(kind)
      [:variable_read, symbol(kind), symbol(name)]
    end

    def variable_write(kind, name, value, side)
      return [:constant_write, nil, symbol(name), value] if kind == :constant
      if kind == :backref
        global_name = name.to_s.start_with?("$") ? name.to_sym : "$#{name}".to_sym
        return [:variable_write, symbol(:global), symbol(global_name), value]
      end
      unsupported!(side, "Variable assignment kind #{kind.inspect}") unless [:instance, :class, :global].include?(kind)
      [:variable_write, symbol(kind), symbol(name), value]
    end

    def constant_declaration(children)
      if children.length == 2
        [:constant_write, nil, symbol(children[0]), rubyvm(children[1])]
      elsif children.length == 3
        if children[0].is_a?(RubyVM::AbstractSyntaxTree::Node) && children[0].type == :COLON3
          # RubyVM stores an absolute constant assignment as COLON3(name),
          # while the frontend represents it as a constant write with no
          # receiver.  The COLON3 wrapper carries no semantic metadata.
          return [:constant_write, nil, symbol(children[0].children.fetch(0)), rubyvm(children[2])]
        end
        [:constant_write, rubyvm_constant_write_receiver(children[0]), symbol(children[1]), rubyvm(children[2])]
      else
        unsupported!(:rubyvm, "CDECL fields #{children.length}")
      end
    end

    def rubyvm_constant_write_receiver(node)
      case node.type
      when :COLON2
        [:constant_path, rubyvm_constant_write_receiver(node.children.fetch(0)), symbol(node.children.fetch(1))]
      when :COLON3
        [:absolute_constant, symbol(node.children.fetch(0))]
      else
        rubyvm(node)
      end
    end

    def attribute_assignment(children)
      receiver, name, list = children
      values = list_items(list)
      unsupported!(:rubyvm, "ATTRASGN without value") if values.empty?
      value = values.pop
      return [:index_write, rubyvm(receiver), values, value] if name == :[]=
      normalized_name = name.to_s.delete_suffix("=").to_sym
      [:attribute_write, rubyvm(receiver), symbol(normalized_name), values, value]
    end

    def rubyvm_case(children)
      expression, current = children
      clauses = []
      while current.is_a?(RubyVM::AbstractSyntaxTree::Node) && current.type == :WHEN
        patterns, clause_body, current = current.children
        clauses << [:when, list_items(patterns), vm_body(clause_body)]
      end
      [:case, rubyvm(expression), clauses, vm_body(current)]
    end

    def rubyvm_case3(children)
      expression, current = children
      clauses = []
      while current.is_a?(RubyVM::AbstractSyntaxTree::Node) && current.type == :IN
        pattern, clause_body, current = current.children
        clauses << [:when, [rubyvm_pattern(pattern)], vm_body(clause_body)]
      end
      [:case, rubyvm(expression), clauses, vm_body(current)]
    end

    def rubyvm_for(children)
      enumerable, scope = children
      unsupported!(:rubyvm, "FOR scope is not a SCOPE node") unless scope.is_a?(RubyVM::AbstractSyntaxTree::Node) && scope.type == :SCOPE
      _locals, arguments, content = scope.children
      unsupported!(:rubyvm, "FOR scope has no ARGS node") unless arguments.is_a?(RubyVM::AbstractSyntaxTree::Node) && arguments.type == :ARGS
      pre_init = arguments.children[1]
      unsupported!(:rubyvm, "FOR has no loop variable") unless pre_init.is_a?(RubyVM::AbstractSyntaxTree::Node)
      [:for, rubyvm_target(pre_init), rubyvm(enumerable), vm_body(content)]
    end

    def rubyvm_pattern(node)
      return nil if node.nil?
      unsupported!(:rubyvm, "pattern node #{node.class}") unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
      case node.type
      when :ARYPTN
        constant, pre, rest, post = node.children
        unsupported!(:rubyvm, "qualified array pattern") unless constant.nil?
        [:pattern, symbol(:array), [rubyvm_pattern_list(pre), rubyvm_pattern_rest_node(rest), rubyvm_pattern_list(post)]]
      when :FNDPTN
        constant, pre_rest, values, post_rest = node.children
        unsupported!(:rubyvm, "qualified find pattern") unless constant.nil?
        [:pattern, symbol(:find), [rubyvm_pattern_rest_node(pre_rest, anonymous: true),
          rubyvm_pattern_list(values), rubyvm_pattern_rest_node(post_rest, anonymous: true)]]
      when :HSHPTN
        constant, hash, rest = node.children
        normalized = [rubyvm_pattern_hash(hash), rubyvm_pattern_rest_node(rest)]
        normalized << rubyvm(constant) unless constant.nil?
        [:pattern, symbol(:hash), normalized]
      when :HASH
        list = node.children[0]
        values = list&.children&.reject(&:nil?) || []
        if values.length == 2 && values[1].is_a?(RubyVM::AbstractSyntaxTree::Node) && values[1].type == :LASGN
          [:pattern, symbol(:as), [rubyvm_pattern(values[0]), rubyvm_pattern(values[1])]]
        else
          unsupported!(:rubyvm, "unexpected HASH in pattern")
        end
      when :LASGN
        [:pattern, symbol(:variable), [symbol(node.children[0])]]
      when :LVAR
        [:pattern, symbol(:pin), [rubyvm(node)]]
      when :IF
        condition, pattern, fallback = node.children
        unsupported!(:rubyvm, "pattern guard with fallback") unless fallback.nil?
        [:pattern, symbol(:guard), [rubyvm_pattern(pattern), rubyvm(condition)]]
      when :UNLESS
        condition, pattern, fallback = node.children
        unsupported!(:rubyvm, "pattern guard with fallback") unless fallback.nil?
        [:pattern, symbol(:guard_unless), [rubyvm_pattern(pattern), rubyvm(condition)]]
      when :OR
        left, right = node.children
        [:pattern, symbol(:or), [rubyvm_pattern(left), rubyvm_pattern(right)]]
      else
        [:pattern, symbol(:value), [rubyvm(node)]]
      end
    end

    def rubyvm_pattern_list(node)
      return [] if node.nil?
      unsupported!(:rubyvm, "pattern list node #{node.type}") unless node.type == :LIST
      node.children.reject(&:nil?).map { |item| rubyvm_pattern(item) }
    end

    def rubyvm_pattern_hash(node)
      return [] if node.nil?
      unsupported!(:rubyvm, "hash pattern node #{node.type}") unless node.type == :HASH
      list = node.children[0]
      return [] if list.nil?
      unsupported!(:rubyvm, "hash pattern list node #{list.type}") unless list.type == :LIST
      values = list.children.reject(&:nil?)
      unsupported!(:rubyvm, "odd hash pattern entry count #{values.length}") if values.length.odd?
      values.each_slice(2).map { |key, value| [:pair, rubyvm(key), rubyvm_pattern(value)] }
    end

    def rubyvm_pattern_rest_node(node, anonymous: false)
      return (anonymous ? [:pattern, symbol(:rest), [nil]] : nil) if node.nil? || node == :NODE_SPECIAL_NO_NAME_REST
      [:pattern, symbol(:rest), [rubyvm_pattern(node)]]
    end

    def rubyvm_match_capture_names(node)
      return [] if node.nil?
      if node.is_a?(RubyVM::AbstractSyntaxTree::Node) && [:LASGN, :DASGN].include?(node.type)
        return [symbol(node.children.fetch(0))]
      end
      unsupported!(:rubyvm, "MATCH2 captures node #{node.type}") unless node.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.type == :BLOCK
      node.children.compact.flat_map { |child| rubyvm_match_capture_names(child) }
    end

    def arpaka_regexp_capture_names(node)
      return [] unless ast_name(node) == "RegexpLiteral" && node.value.is_a?(String)
      Regexp.new(node.value).names.map { |name| symbol(name.to_sym) }
    rescue RegexpError
      unsupported!(:arpaka, "invalid static regexp while reading named captures")
    end

    def arpaka_pattern_value(value)
      return arpaka(value) unless value.is_a?(Symbol)
      [:pattern, symbol(:variable), [symbol(value)]]
    end

    def arpaka_pattern_rest(value)
      return nil if value.nil?
      [:pattern, symbol(:rest), [arpaka_pattern_value(value.values.first)]]
    end

    def rubyvm_targets(node)
      return [] if node.nil?
      return [rubyvm_target(node)] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.type == :LIST
      node.children.reject(&:nil?).map { |target| rubyvm_target(target) }
    end

    def rubyvm_target(node)
      return nil if node.nil?
      # RubyVM uses a bare Symbol for a local target in a few grammar
      # positions where it omits the LASGN wrapper.  It carries the same
      # information as LASGN's first child.
      return [:local_target, symbol(node)] if node.is_a?(Symbol)
      unsupported!(:rubyvm, "assignment target #{node.class}") unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
      children = node.children
      case node.type
      when :LASGN, :DASGN then [:local_target, symbol(children[0])]
      when :CDECL then [:variable_target, :constant, symbol(children[0])]
      when :IASGN then [:variable_target, :instance, symbol(children[0])]
      when :CVASGN then [:variable_target, :class, symbol(children[0])]
      when :GASGN then [:variable_target, :global, symbol(children[0])]
      when :ATTRASGN then [:attribute_target, rubyvm(children[0]), symbol(children[1]), args(children[2])]
      when :SPLAT then [:splat_target, rubyvm_target(children[0])]
      when :MASGN
        [:multiple_target, rubyvm_targets(children[1])]
      else unsupported!(:rubyvm, "assignment target #{node.type}")
      end
    end

    def rubyvm_keyword_arguments(node)
      parameters = []
      current = node
      while current.is_a?(RubyVM::AbstractSyntaxTree::Node) && current.type == :KW_ARG
        validate_arity!(current)
        assignment, current = current.children
        if assignment.nil?
          parameters << [:missing_keyword_parameter]
        elsif [:LASGN, :DASGN].include?(assignment.type) && assignment.children[1] == :NODE_SPECIAL_REQUIRED_KEYWORD
          parameters << [:required_keyword, symbol(assignment.children[0])]
        else
          parameters << rubyvm(assignment)
        end
      end
      [:keyword_parameters, parameters]
    end

    def rubyvm_block(node)
      values = vm_body(node)
      return values.first if values.length == 1

      [:sequence, values]
    end

    def rubyvm_rescue(node)
      body, clause, else_body = node.children
      if rubyvm_rescue_modifier?(node, body, clause, else_body)
        return [:rescue_modifier, rubyvm(body), rubyvm(clause.children[2])]
      end

      clauses = []
      while clause.is_a?(RubyVM::AbstractSyntaxTree::Node) && clause.type == :RESBODY
        validate_arity!(clause)
        exceptions, target, clause_body, clause = clause.children
        clauses << [:rescue_clause, list_items(exceptions), rubyvm_target(target), vm_body(clause_body)]
      end
      [:rescue, vm_body(body), clauses, vm_body(else_body)]
    end

    def rubyvm_rescue_modifier?(node, body, clause, else_body)
      return false unless else_body.nil?
      return false unless clause.is_a?(RubyVM::AbstractSyntaxTree::Node) && clause.type == :RESBODY
      return false unless clause.children[0].nil? && clause.children[1].nil? && clause.children[3].nil?
      return false if body.nil?

      # A begin-rescue statement's RESCUE and body start together and its body
      # block carries the BEGIN marker. A begin expression used with modifier
      # rescue starts before its body; a parenthesized expression has one
      # expression child instead of the statement's BEGIN marker.
      return false if body.first_lineno != node.first_lineno || body.first_column != node.first_column
      return false if clause.first_column <= body.first_column
      return true unless body.type == :BLOCK
      return false if body.children.first&.type == :BEGIN

      body.children.length == 1 && body.children.first&.type != :BEGIN
    end

    def args(node)
      return [] if node.nil?
      return args(node.children[0]) + [[:splat, rubyvm(node.children[1])]] if node.type == :ARGSCAT
      return args(node.children[0]) + [rubyvm(node.children[1])] if node.type == :ARGSPUSH
      return [[:splat, rubyvm(node.children[0])]] if node.type == :SPLAT
      return [rubyvm(node)] unless node.type == :LIST
      list_items(node)
    end

    def dynamic_parts(parts)
      merge_text_parts(parts.flat_map do |part|
        if part.is_a?(String)
          part.empty? ? [] : [[:text, text(part)]]
        elsif part.nil?
          []
        elsif part.type == :STR
          [[:text, text(part.children[0])]]
        elsif part.type == :EVSTR
          [[:interpolation, rubyvm(part.children[0])]]
        elsif part.type == :LIST
          dynamic_parts(part.children.compact)
        else
          [rubyvm(part)]
        end
      end)
    end

    def arpaka_dynamic_parts(parts)
      merge_text_parts(parts.flat_map do |part|
        if part.is_a?(String)
          part.empty? ? [] : [[:text, text(part)]]
        else
          [[:interpolation, arpaka(part)]]
        end
      end)
    end

    def merge_text_parts(parts)
      parts.each_with_object([]) do |part, merged|
        if part.first == :text && merged.last&.first == :text &&
            (payload = merge_text_payloads(merged[-1][1], part[1]))
          merged[-1] = [:text, payload]
        else
          merged << part
        end
      end
    end

    def dynamic_string(parts)
      return unless parts.length == 1 && parts.first.first == :text

      [:string, parts.first[1]]
    end

    def merge_text_payloads(left, right)
      return unless left.is_a?(Array) && right.is_a?(Array)
      return unless left.length == 3 && right.length == 3
      return unless left.first == :bytes && right.first == :bytes
      return unless left.last == right.last

      [:bytes, left[1].to_s + right[1].to_s, left.last]
    end

    def backref_number(name)
      match = /\A\$(\d+)\z/.match(name.to_s)
      unsupported!(:rubyvm, "numbered back reference #{name.inspect}") unless match
      match[1].to_i
    end

    def list_items(node)
      return [] if node.nil?
      return [rubyvm(node)] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.type == :LIST
      values = node.children.dup
      values.pop if values.last.nil?
      values.map { |item| item.nil? ? [:missing_child] : vm_value(item) }
    end

    def body(value)
      return [] if value.nil?
      return value.map { |item| arpaka(item) } if value.is_a?(Array)
      [arpaka(value)]
    end

    def body_value(value)
      nodes = body(value)
      nodes.length == 1 ? nodes.first : [:sequence, nodes]
    end

    def implicit_rescue_modifier?(value)
      return false unless ast_name(value) == "FullRescue"
      return false unless value.else_body.nil? && value.ensure_body.nil?

      clauses = value.clauses
      return false unless value.body.length == 1
      clauses.length == 1 && clauses.first.exceptions.empty? && clauses.first.variable.nil? &&
        clauses.first.body.length == 1
    end

    def range_endpoint(value)
      value.nil? ? [:literal, nil] : arpaka(value)
    end

    def method_body(value)
      if implicit_rescue_modifier?(value)
        clause = value.clauses.fetch(0)
        return [[:rescue_modifier, body_value(value.body), body_value(clause.body)]]
      end
      normalize_terminal_nil_body(body(value))
    end

    def normalize_terminal_nil_body(nodes)
      return [] if nodes == [[:literal, nil]]
      return nodes if nodes.empty?

      last = nodes.last
      return nodes unless last.is_a?(Array) && last.first == :conditional

      normalized = last.dup
      normalized[2] = normalize_terminal_nil_body(normalized[2])
      normalized[3] = normalize_terminal_nil_body(normalized[3])
      nodes[0...-1] + [normalized]
    end

    def vm_body(value)
      return [] if value.nil?
      return [] if value.type == :BEGIN && value.children == [nil]
      if value.type == :BLOCK
        return value.children.each_with_index.map do |item, index|
          if item.nil?
            [:literal, nil]
          elsif item.type == :BEGIN && item.children.all?(&:nil?)
            next if index < value.children.length - 1
            [:literal, nil]
          else
            rubyvm(item)
          end
        end.compact
      end
      [rubyvm(value)]
    end

    def scoped_body(scope)
      unsupported!(:rubyvm, "class/module scope node #{scope.class}") unless scope.is_a?(RubyVM::AbstractSyntaxTree::Node) && scope.type == :SCOPE
      validate_arity!(scope)
      locals, arguments, content = scope.children
      unsupported!(:rubyvm, "class/module scope arguments") unless arguments.nil?
      unsupported!(:rubyvm, "class/module scope locals metadata") unless locals.is_a?(Array) && locals.all? { |name| name.is_a?(Symbol) }
      vm_body(content)
    end

    def scoped_arguments(locals, node, block: false)
      return [:retained_arguments, []] if node.nil?
      unsupported!(:rubyvm, "parameter node #{node.type}") unless node.type == :ARGS
      unsupported!(:rubyvm, "ARGS fields #{node.children.length}, expected 10") unless node.children.length == 10
      required, pre_init, optional, first_post, post_count, post_init, rest, keywords, keyword_rest, block_parameter = node.children
      local_names = Array(locals)
      names = local_names.first(required.to_i).compact.map { |name| symbol(name) }
      result = [:retained_arguments, names]
      result << [:pre_init, vm_value(pre_init)] unless pre_init.nil?
      result << [:optional_defaults, rubyvm(optional)] unless optional.nil?
      result << [:first_post, vm_value(first_post)] unless first_post.nil?
      result << [:post_count, post_count] unless post_count.nil? || post_count == 0
      if post_count.to_i.positive?
        unsupported!(:rubyvm, "post arguments missing first_post") if first_post.nil?
        index = local_names.index(first_post)
        unsupported!(:rubyvm, "post argument #{first_post.inspect} missing from scope locals") unless index
        post_names = local_names[index, post_count.to_i]
        unsupported!(:rubyvm, "post argument count #{post_names&.length}, expected #{post_count}") unless post_names&.length == post_count
        result << [:post_names, post_names.map { |name| symbol(name) }]
      end
      result << [:post_init, vm_value(post_init)] unless post_init.nil?
      result << [:rest, vm_value(rest)] unless rest.nil?
      result << [:keywords, vm_value(keywords)] unless keywords.nil?
      result << [:keyword_rest, vm_value(keyword_rest)] unless keyword_rest.nil?
      result << [:block, vm_value(block_parameter)] unless block_parameter.nil?
      result
    end

    def vm_value(value)
      value.is_a?(RubyVM::AbstractSyntaxTree::Node) ? rubyvm(value) : value.is_a?(Symbol) ? symbol(value) : atom(value, :rubyvm)
    end

    def symbol(value)
      unsupported!(:rubyvm, "symbol value #{value.class}") unless value.is_a?(Symbol)
      [:symbol, text(value.to_s)]
    end

    def logical_operator(value)
      { :and => :"&&", :or => :"||" }.fetch(value, value)
    end

    def atom(value, side)
      return text(value) if value.is_a?(String)
      return value if value.nil? || value == true || value == false
      return [:integer, value] if value.is_a?(Integer)
      return [:float, [value].pack("G").unpack1("H*")] if value.is_a?(Float)
      return rational(value) if value.is_a?(Rational)
      return complex(value) if value.is_a?(Complex)
      unsupported!(side, "literal value #{value.class}")
    end

    def complex(value)
      [:complex, complex_component(value.real), complex_component(value.imag)]
    end

    def complex_component(value)
      return [:integer, value.to_i] if value.is_a?(Float) && value.finite? && value == value.to_i
      atom(value, :rubyvm)
    end

    def rational(value)
      [:rational, value.numerator, value.denominator]
    end

    def text(value)
      [:bytes, value.b.unpack1("H*"), value.encoding.name]
    end

    def regexp(pattern_bytes, options, encoding)
      [:regexp, pattern_bytes, options, encoding]
    end

    def regexp_source(value)
      value.gsub(/(?<!\\)(?:\\\\)*\\\//) { |match| match[0...-2] + "/" }
    end

    def defined_expression?(node)
      return false unless node.is_a?(Array)

      node.first == :defined ||
        (node.first == :unary && node[1] == [:symbol, [:bytes, "21", "US-ASCII"]] && defined_expression?(node[2]))
    end

    def unsupported!(side, detail)
      raise Unsupported.new(side, detail)
    end

    def validate_arity!(node)
      arities = {
        BEGIN: 1, NIL: 0, TRUE: 0, FALSE: 0, SELF: 0, ZLIST: 0, SCOPE: 3, MASGN: 3,
        LIT: 1, INTEGER: 1, FLOAT: 1, RATIONAL: 1, IMAGINARY: 1, COMPLEX: 1, SYM: 1, STR: 1, CONST: 1,
        LVAR: 1, DVAR: 1, IVAR: 1, CVAR: 1, GVAR: 1,
        VCALL: 1, LASGN: 2, DASGN: 2, IASGN: 2, CVASGN: 2, GASGN: 2,
        FCALL: 2, CALL: 3, QCALL: 3, ATTRASGN: 3, BLOCK_PASS: 2,
        OPCALL: 3, SPLAT: 1, ARRAY: 1, HASH: 1, PAIR: 2, IF: 3,
        UNLESS: 3, CASE: 2, WHEN: 3, DOT2: 2, DOT3: 2, COLON2: 2, COLON3: 1, REGX: 1,
        DEFN: 2, DEFS: 3, LAMBDA: 1, CLASS: 3, MODULE: 2, SCLASS: 2,
        ARGS: 10, OPT_ARG: 2, ITER: 2, EVSTR: 1, XSTR: 1,
        WHILE: 3, UNTIL: 3, FOR: 2, ONCE: 1, RETURN: 1, NEXT: 1, BREAK: 1, REDO: 0, RETRY: 0,
        SUPER: 1, ZSUPER: 0, OP_ASGN_OR: 3, OP_ASGN_AND: 3, KW_ARG: 2,
        YIELD: 1, OP_ASGN1: 4, OP_ASGN2: 5, DEFINED: 1, ARGSCAT: 2, ARGSPUSH: 2,
        FILE: 1, NTH_REF: 1, BACK_REF: 1,
        ENSURE: 2, RESCUE: 3, RESBODY: 4
      }
      expected = arities[node.type]
      if [:AND, :OR].include?(node.type)
        unsupported!(:rubyvm, "#{node.type} fields #{node.children.length}, expected at least 2") if node.children.length < 2
        return
      end
      if node.type == :MATCH2
        unsupported!(:rubyvm, "MATCH2 fields #{node.children.length}, expected 2 or 3") unless [2, 3].include?(node.children.length)
        return
      end
      return if expected.nil?
      unsupported!(:rubyvm, "#{node.type} fields #{node.children.length}, expected #{expected}") unless node.children.length == expected
    end
  end
end
