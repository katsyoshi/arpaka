/* Generated from ruby/ruby 37d60dd3241d5fdb10ca43f36077f5d556ae1b8d. See tool/ruby/actions.rb. */
%no-stdlib
%expect 0
%token END_OF_INPUT 0 "end-of-input"
%token keyword_class 258 "'class'"
%token keyword_module 259 "'module'"
%token keyword_def 260 "'def'"
%token keyword_undef 261 "'undef'"
%token keyword_begin 262 "'begin'"
%token keyword_rescue 263 "'rescue'"
%token keyword_ensure 264 "'ensure'"
%token keyword_end 265 "'end'"
%token keyword_if 266 "'if'"
%token keyword_unless 267 "'unless'"
%token keyword_then 268 "'then'"
%token keyword_elsif 269 "'elsif'"
%token keyword_else 270 "'else'"
%token keyword_case 271 "'case'"
%token keyword_when 272 "'when'"
%token keyword_while 273 "'while'"
%token keyword_until 274 "'until'"
%token keyword_for 275 "'for'"
%token keyword_break 276 "'break'"
%token keyword_next 277 "'next'"
%token keyword_redo 278 "'redo'"
%token keyword_retry 279 "'retry'"
%token keyword_in 280 "'in'"
%token keyword_do 281 "'do'"
%token keyword_do_cond 282 "'do' for condition"
%token keyword_do_block 283 "'do' for block"
%token keyword_do_LAMBDA 284 "'do' for lambda"
%token keyword_return 285 "'return'"
%token keyword_yield 286 "'yield'"
%token keyword_super 287 "'super'"
%token keyword_self 288 "'self'"
%token keyword_nil 289 "'nil'"
%token keyword_true 290 "'true'"
%token keyword_false 291 "'false'"
%token keyword_and 292 "'and'"
%token keyword_or 293 "'or'"
%token keyword_not 294 "'not'"
%token modifier_if 295 "'if' modifier"
%token modifier_unless 296 "'unless' modifier"
%token modifier_while 297 "'while' modifier"
%token modifier_until 298 "'until' modifier"
%token modifier_rescue 299 "'rescue' modifier"
%token keyword_alias 300 "'alias'"
%token keyword_defined 301 "'defined?'"
%token keyword_BEGIN 302 "'BEGIN'"
%token keyword_END 303 "'END'"
%token keyword__LINE__ 304 "'__LINE__'"
%token keyword__FILE__ 305 "'__FILE__'"
%token keyword__ENCODING__ 306 "'__ENCODING__'"
%token tIDENTIFIER 307 "local variable or method"
%token tFID 308 "method"
%token tGVAR 309 "global variable"
%token tIVAR 310 "instance variable"
%token tCONSTANT 311 "constant"
%token tCVAR 312 "class variable"
%token tLABEL 313 "label"
%token tINTEGER 314 "integer literal"
%token tFLOAT 315 "float literal"
%token tRATIONAL 316 "rational literal"
%token tIMAGINARY 317 "imaginary literal"
%token tCHAR 318 "char literal"
%token tNTH_REF 319 "numbered reference"
%token tBACK_REF 320 "back reference"
%token tSTRING_CONTENT 321 "literal content"
%token tREGEXP_END 322
%token tDUMNY_END 323 "dummy end"
%token '.' 46
%token '\\' 92 "backslash"
%token tSP 324 "escaped space"
%token '\t' 9 "escaped horizontal tab"
%token '\f' 12 "escaped form feed"
%token '\r' 13 "escaped carriage return"
%token '\13' 11 "escaped vertical tab"
%token tUPLUS 132 "unary+"
%token tUMINUS 133 "unary-"
%token tPOW 134 "**"
%token tCMP 135 "<=>"
%token tEQ 140 "=="
%token tEQQ 141 "==="
%token tNEQ 142 "!="
%token tGEQ 139 ">="
%token tLEQ 138 "<="
%token tANDOP 148 "&&"
%token tOROP 149 "||"
%token tMATCH 143 "=~"
%token tNMATCH 144 "!~"
%token tDOT2 128 ".."
%token tDOT3 129 "..."
%token tBDOT2 130 "(.."
%token tBDOT3 131 "(..."
%token tAREF 145 "[]"
%token tASET 146 "[]="
%token tLSHFT 136 "<<"
%token tRSHFT 137 ">>"
%token tANDDOT 150 "&."
%token tCOLON2 147 "::"
%token tCOLON3 325 ":: at EXPR_BEG"
%token tOP_ASGN 326 "operator-assignment"
%token tASSOC 327 "=>"
%token tLPAREN 328 "("
%token tLPAREN_ARG 329 "( arg"
%token tLBRACK 330 "["
%token tLBRACE 331 "{"
%token tLBRACE_ARG 332 "{ arg"
%token tSTAR 333 "*"
%token tDSTAR 334 "**arg"
%token tAMPER 335 "&"
%token tLAMBDA 336 "->"
%token tSYMBEG 337 "symbol literal"
%token tSTRING_BEG 338 "string literal"
%token tXSTRING_BEG 339 "backtick literal"
%token tREGEXP_BEG 340 "regexp literal"
%token tWORDS_BEG 341 "word list"
%token tQWORDS_BEG 342 "verbatim word list"
%token tSYMBOLS_BEG 343 "symbol list"
%token tQSYMBOLS_BEG 344 "verbatim symbol list"
%token tSTRING_END 345 "terminator"
%token tSTRING_DEND 346 "'}'"
%token tSTRING_DBEG 347 "'#{'"
%token tSTRING_DVAR 348
%token tLAMBEG 349
%token tLABEL_END 350
%token tIGNORED_NL 351
%token tCOMMENT 352
%token tEMBDOC_BEG 353
%token tEMBDOC 354
%token tEMBDOC_END 355
%token tHEREDOC_BEG 356
%token tHEREDOC_END 357
%token k__END__ 358
%token tLOWEST 359
%token '=' 61
%token '?' 63
%token ':' 58
%token '>' 62
%token '<' 60
%token '|' 124
%token '^' 94
%token '&' 38
%token '+' 43
%token '-' 45
%token '*' 42
%token '/' 47
%token '%' 37
%token tUMINUS_NUM 360
%token '!' 33
%token '~' 126
%token tLAST_TOKEN 361
%token '{' 123
%token '}' 125
%token '[' 91
%token '\n' 10
%token ',' 44
%token '`' 96
%token '(' 40
%token ')' 41
%token ']' 93
%token ';' 59
%token ' ' 32
%nonassoc tLOWEST
%nonassoc tLBRACE_ARG
%nonassoc keyword_in modifier_if modifier_unless modifier_while modifier_until
%left keyword_and keyword_or
%right keyword_not
%nonassoc keyword_defined
%right tOP_ASGN '='
%left modifier_rescue
%right '?' ':'
%nonassoc tDOT2 tDOT3 tBDOT2 tBDOT3
%left tOROP
%left tANDOP
%nonassoc tCMP tEQ tEQQ tNEQ tMATCH tNMATCH
%left tGEQ tLEQ '>' '<'
%left '|' '^'
%left '&'
%left tLSHFT tRSHFT
%left '+' '-'
%left '*' '/' '%'
%right tUMINUS tUMINUS_NUM
%right tPOW
%right tUPLUS '!' '~'
%start program
%%
/* upstream parse.y:3176: $@1: %empty */
midrule_1: %empty { $$ = nil };
/* upstream parse.y:3182: option_terms: %empty */
option_terms: %empty { $$ = nil };
/* upstream parse.y:3182: option_terms: terms */
option_terms: terms { $$ = nil };
/* upstream parse.y:2991: compstmt_top_stmts: top_stmts option_terms */
compstmt_top_stmts: top_stmts option_terms { $$ = $1 };
/* upstream parse.y:3183: program: $@1 compstmt_top_stmts */
program: midrule_1 compstmt_top_stmts { $$ = @builder.program($2) };
/* upstream parse.y:3203: top_stmts: none */
top_stmts: none { $$ = [].freeze };
/* upstream parse.y:3208: top_stmts: top_stmt */
top_stmts: top_stmt { $$ = [$1].freeze };
/* upstream parse.y:3213: top_stmts: top_stmts terms top_stmt */
top_stmts: top_stmts terms top_stmt { $$ = ($1 + [$3]).freeze };
/* upstream parse.y:3220: top_stmt: stmt */
top_stmt: stmt { $$ = $1 };
/* upstream parse.y:3225: top_stmt: "'BEGIN'" begin_block */
top_stmt: keyword_BEGIN begin_block %prec keyword_BEGIN { $$ = @builder.unsupported(10) };
/* upstream parse.y:3231: block_open: '{' */
block_open: '{' %prec '{' { $$ = @builder.unsupported(11) };
/* upstream parse.y:3234: begin_block: block_open compstmt_top_stmts '}' */
begin_block: block_open compstmt_top_stmts '}' %prec '}' { $$ = @builder.unsupported(12) };
/* upstream parse.y:2991: compstmt_stmts: stmts option_terms */
compstmt_stmts: stmts option_terms { $$ = $1 };
/* upstream parse.y:3247: $@2: %empty */
midrule_2: %empty { $$ = @builder.unsupported(14) };
/* upstream parse.y:3252: $@3: %empty */
midrule_3: %empty { $$ = @builder.unsupported(15) };
/* upstream parse.y:3256: bodystmt: compstmt_stmts lex_ctxt opt_rescue k_else $@2 compstmt_stmts $@3 opt_ensure */
bodystmt: compstmt_stmts lex_ctxt opt_rescue k_else midrule_2 compstmt_stmts midrule_3 opt_ensure { $$ = @builder.unsupported(16) };
/* upstream parse.y:3263: $@4: %empty */
midrule_4: %empty { $$ = @builder.unsupported(17) };
/* upstream parse.y:3267: bodystmt: compstmt_stmts lex_ctxt opt_rescue $@4 opt_ensure */
bodystmt: compstmt_stmts lex_ctxt opt_rescue midrule_4 opt_ensure { $$ = @builder.unsupported(18) };
/* upstream parse.y:3274: stmts: none */
stmts: none { $$ = [].freeze };
/* upstream parse.y:3279: stmts: stmt_or_begin */
stmts: stmt_or_begin { $$ = [$1].freeze };
/* upstream parse.y:3284: stmts: stmts terms stmt_or_begin */
stmts: stmts terms stmt_or_begin { $$ = ($1 + [$3]).freeze };
/* upstream parse.y:3290: stmt_or_begin: stmt */
stmt_or_begin: stmt { $$ = $1 };
/* upstream parse.y:3292: $@5: %empty */
midrule_5: %empty { $$ = @builder.unsupported(23) };
/* upstream parse.y:3296: stmt_or_begin: "'BEGIN'" $@5 begin_block */
stmt_or_begin: keyword_BEGIN midrule_5 begin_block %prec keyword_BEGIN { $$ = @builder.unsupported(24) };
/* upstream parse.y:3301: allow_exits: %empty */
allow_exits: %empty { $$ = nil };
/* upstream parse.y:3304: k_END: "'END'" lex_ctxt */
k_END: keyword_END lex_ctxt %prec keyword_END { $$ = @builder.unsupported(26) };
/* upstream parse.y:3313: $@6: %empty */
midrule_6: %empty { $$ = @builder.unsupported(27) };
/* upstream parse.y:3314: stmt: "'alias'" fitem $@6 fitem */
stmt: keyword_alias fitem midrule_6 fitem %prec keyword_alias { $$ = @builder.unsupported(28) };
/* upstream parse.y:3319: stmt: "'alias'" "global variable" "global variable" */
stmt: keyword_alias tGVAR tGVAR %prec tGVAR { $$ = @builder.unsupported(29) };
/* upstream parse.y:3324: stmt: "'alias'" "global variable" "back reference" */
stmt: keyword_alias tGVAR tBACK_REF %prec tBACK_REF { $$ = @builder.unsupported(30) };
/* upstream parse.y:3332: stmt: "'alias'" "global variable" "numbered reference" */
stmt: keyword_alias tGVAR tNTH_REF %prec tNTH_REF { $$ = @builder.unsupported(31) };
/* upstream parse.y:3341: stmt: "'undef'" undef_list */
stmt: keyword_undef undef_list %prec keyword_undef { $$ = @builder.unsupported(32) };
/* upstream parse.y:3348: stmt: stmt "'if' modifier" expr_value */
stmt: stmt modifier_if expr_value %prec modifier_if { $$ = @builder.unsupported(33) };
/* upstream parse.y:3354: stmt: stmt "'unless' modifier" expr_value */
stmt: stmt modifier_unless expr_value %prec modifier_unless { $$ = @builder.unsupported(34) };
/* upstream parse.y:3360: stmt: stmt "'while' modifier" expr_value */
stmt: stmt modifier_while expr_value %prec modifier_while { $$ = @builder.unsupported(35) };
/* upstream parse.y:3371: stmt: stmt "'until' modifier" expr_value */
stmt: stmt modifier_until expr_value %prec modifier_until { $$ = @builder.unsupported(36) };
/* upstream parse.y:3382: stmt: stmt "'rescue' modifier" after_rescue stmt */
stmt: stmt modifier_rescue after_rescue stmt %prec modifier_rescue { $$ = @builder.unsupported(37) };
/* upstream parse.y:3391: stmt: k_END block_open compstmt_stmts '}' */
stmt: k_END block_open compstmt_stmts '}' %prec '}' { $$ = @builder.unsupported(38) };
/* upstream parse.y:3402: stmt: command_asgn */
stmt: command_asgn { $$ = @builder.unsupported(39) };
/* upstream parse.y:3404: stmt: mlhs '=' lex_ctxt command_call_value */
stmt: mlhs '=' lex_ctxt command_call_value %prec '=' { $$ = @builder.unsupported(40) };
/* upstream parse.y:2926: asgn_mrhs: lhs '=' lex_ctxt mrhs */
asgn_mrhs: lhs '=' lex_ctxt mrhs %prec '=' { $$ = @builder.unsupported(41) };
/* upstream parse.y:3408: stmt: asgn_mrhs */
stmt: asgn_mrhs { $$ = @builder.unsupported(42) };
/* upstream parse.y:3411: stmt: mlhs '=' lex_ctxt mrhs_arg "'rescue' modifier" after_rescue stmt */
stmt: mlhs '=' lex_ctxt mrhs_arg modifier_rescue after_rescue stmt %prec modifier_rescue { $$ = @builder.unsupported(43) };
/* upstream parse.y:3421: stmt: mlhs '=' lex_ctxt mrhs_arg */
stmt: mlhs '=' lex_ctxt mrhs_arg %prec '=' { $$ = @builder.unsupported(44) };
/* upstream parse.y:3425: stmt: expr */
stmt: expr { $$ = $1 };
/* upstream parse.y:3427: stmt: error */
stmt: YYerror %prec YYerror { $$ = @builder.unsupported(46) };
/* upstream parse.y:2926: asgn_command_rhs: lhs '=' lex_ctxt command_rhs */
asgn_command_rhs: lhs '=' lex_ctxt command_rhs %prec '=' { $$ = @builder.unsupported(47) };
/* upstream parse.y:3433: command_asgn: asgn_command_rhs */
command_asgn: asgn_command_rhs { $$ = @builder.unsupported(48) };
/* upstream parse.y:3061: op_asgn_command_rhs: var_lhs "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: var_lhs tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(49) };
/* upstream parse.y:3066: op_asgn_command_rhs: primary_value '[' opt_call_args rbracket "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: primary_value '[' opt_call_args rbracket tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(50) };
/* upstream parse.y:3071: op_asgn_command_rhs: primary_value call_op "local variable or method" "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: primary_value call_op tIDENTIFIER tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(51) };
/* upstream parse.y:3076: op_asgn_command_rhs: primary_value call_op "constant" "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: primary_value call_op tCONSTANT tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(52) };
/* upstream parse.y:3081: op_asgn_command_rhs: primary_value "::" "local variable or method" "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: primary_value tCOLON2 tIDENTIFIER tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(53) };
/* upstream parse.y:3086: op_asgn_command_rhs: primary_value "::" "constant" "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: primary_value tCOLON2 tCONSTANT tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(54) };
/* upstream parse.y:3092: op_asgn_command_rhs: ":: at EXPR_BEG" "constant" "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: tCOLON3 tCONSTANT tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(55) };
/* upstream parse.y:3098: op_asgn_command_rhs: backref "operator-assignment" lex_ctxt command_rhs */
op_asgn_command_rhs: backref tOP_ASGN lex_ctxt command_rhs %prec tOP_ASGN { $$ = @builder.unsupported(56) };
/* upstream parse.y:3434: command_asgn: op_asgn_command_rhs */
command_asgn: op_asgn_command_rhs { $$ = @builder.unsupported(57) };
/* upstream parse.y:2966: def_endless_method_endless_command: defn_head f_opt_paren_args '=' endless_command */
def_endless_method_endless_command: defn_head f_opt_paren_args '=' endless_command %prec '=' { $$ = @builder.unsupported(58) };
/* upstream parse.y:2977: def_endless_method_endless_command: defs_head f_opt_paren_args '=' endless_command */
def_endless_method_endless_command: defs_head f_opt_paren_args '=' endless_command %prec '=' { $$ = @builder.unsupported(59) };
/* upstream parse.y:3435: command_asgn: def_endless_method_endless_command */
command_asgn: def_endless_method_endless_command { $$ = @builder.unsupported(60) };
/* upstream parse.y:3438: endless_command: command */
endless_command: command { $$ = @builder.unsupported(61) };
/* upstream parse.y:3440: endless_command: endless_command "'rescue' modifier" after_rescue arg */
endless_command: endless_command modifier_rescue after_rescue arg %prec modifier_rescue { $$ = @builder.unsupported(62) };
/* upstream parse.y:3445: option_'\n': %empty */
option_newline: %empty { $$ = nil };
/* upstream parse.y:3445: option_'\n': '\n' */
option_newline: '\n' %prec '\n' { $$ = nil };
/* upstream parse.y:3446: endless_command: "'not'" option_'\n' endless_command */
endless_command: keyword_not option_newline endless_command %prec keyword_not { $$ = @builder.unsupported(65) };
/* upstream parse.y:3452: command_rhs: command_call_value */
command_rhs: command_call_value %prec tOP_ASGN { $$ = @builder.unsupported(66) };
/* upstream parse.y:3454: command_rhs: command_call_value "'rescue' modifier" after_rescue stmt */
command_rhs: command_call_value modifier_rescue after_rescue stmt %prec modifier_rescue { $$ = @builder.unsupported(67) };
/* upstream parse.y:3460: command_rhs: command_asgn */
command_rhs: command_asgn { $$ = @builder.unsupported(68) };
/* upstream parse.y:3463: expr: command_call */
expr: command_call { $$ = @builder.unsupported(69) };
/* upstream parse.y:3465: expr: expr "'and'" expr */
expr: expr keyword_and expr %prec keyword_and { $$ = @builder.binary(:and, $1, $3) };
/* upstream parse.y:3470: expr: expr "'or'" expr */
expr: expr keyword_or expr %prec keyword_or { $$ = @builder.binary(:or, $1, $3) };
/* upstream parse.y:3475: expr: "'not'" option_'\n' expr */
expr: keyword_not option_newline expr %prec keyword_not { $$ = @builder.unsupported(72) };
/* upstream parse.y:3480: expr: '!' command_call */
expr: '!' command_call %prec '!' { $$ = @builder.unsupported(73) };
/* upstream parse.y:3485: $@7: %empty */
midrule_7: %empty { $$ = @builder.unsupported(74) };
/* upstream parse.y:3490: expr: arg "=>" $@7 p_in_kwarg p_pvtbl p_pktbl p_top_expr_body */
expr: arg tASSOC midrule_7 p_in_kwarg p_pvtbl p_pktbl p_top_expr_body %prec tASSOC { $$ = @builder.unsupported(75) };
/* upstream parse.y:3500: $@8: %empty */
midrule_8: %empty { $$ = @builder.unsupported(76) };
/* upstream parse.y:3505: expr: arg "'in'" $@8 p_in_kwarg p_pvtbl p_pktbl p_top_expr_body */
expr: arg keyword_in midrule_8 p_in_kwarg p_pvtbl p_pktbl p_top_expr_body %prec keyword_in { $$ = @builder.unsupported(77) };
/* upstream parse.y:3514: expr: arg */
expr: arg %prec tLBRACE_ARG { $$ = $1 };
/* upstream parse.y:3518: def_name: fname */
def_name: fname { $$ = @builder.unsupported(79) };
/* upstream parse.y:3529: defn_head: k_def def_name */
defn_head: k_def def_name { $$ = @builder.unsupported(80) };
/* upstream parse.y:3538: $@9: %empty */
midrule_9: %empty { $$ = @builder.unsupported(81) };
/* upstream parse.y:3542: defs_head: k_def singleton dot_or_colon $@9 def_name */
defs_head: k_def singleton dot_or_colon midrule_9 def_name { $$ = @builder.unsupported(82) };
/* upstream parse.y:3161: value_expr_expr: expr */
value_expr_expr: expr { $$ = $1 };
/* upstream parse.y:3551: expr_value: value_expr_expr */
expr_value: value_expr_expr { $$ = $1 };
/* upstream parse.y:3553: expr_value: error */
expr_value: YYerror %prec YYerror { $$ = @builder.unsupported(85) };
/* upstream parse.y:3558: $@10: %empty */
midrule_10: %empty { $$ = nil };
/* upstream parse.y:3558: $@11: %empty */
midrule_11: %empty { $$ = nil };
/* upstream parse.y:3559: expr_value_do: $@10 expr_value do $@11 */
expr_value_do: midrule_10 expr_value do midrule_11 { $$ = $2 };
/* upstream parse.y:3565: command_call: command */
command_call: command { $$ = @builder.unsupported(89) };
/* upstream parse.y:3566: command_call: block_command */
command_call: block_command { $$ = @builder.unsupported(90) };
/* upstream parse.y:3161: value_expr_command_call: command_call */
value_expr_command_call: command_call { $$ = @builder.unsupported(91) };
/* upstream parse.y:3569: command_call_value: value_expr_command_call */
command_call_value: value_expr_command_call { $$ = @builder.unsupported(92) };
/* upstream parse.y:3572: block_command: block_call */
block_command: block_call { $$ = @builder.unsupported(93) };
/* upstream parse.y:3574: block_command: block_call call_op2 operation2 command_args */
block_command: block_call call_op2 operation2 command_args { $$ = @builder.unsupported(94) };
/* upstream parse.y:3581: cmd_brace_block: "{ arg" brace_body '}' */
cmd_brace_block: tLBRACE_ARG brace_body '}' %prec '}' { $$ = @builder.unsupported(95) };
/* upstream parse.y:3589: fcall: "local variable or method" */
fcall: tIDENTIFIER %prec tIDENTIFIER { $$ = $1 };
/* upstream parse.y:3589: fcall: "constant" */
fcall: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(97) };
/* upstream parse.y:3589: fcall: "method" */
fcall: tFID %prec tFID { $$ = @builder.unsupported(98) };
/* upstream parse.y:3596: command: fcall command_args */
command: fcall command_args %prec tLOWEST { $$ = @builder.unsupported(99) };
/* upstream parse.y:3603: command: fcall command_args cmd_brace_block */
command: fcall command_args cmd_brace_block { $$ = @builder.unsupported(100) };
/* upstream parse.y:3612: command: primary_value call_op operation2 command_args */
command: primary_value call_op operation2 command_args %prec tLOWEST { $$ = @builder.unsupported(101) };
/* upstream parse.y:3617: command: primary_value call_op operation2 command_args cmd_brace_block */
command: primary_value call_op operation2 command_args cmd_brace_block { $$ = @builder.unsupported(102) };
/* upstream parse.y:3622: command: primary_value "::" operation2 command_args */
command: primary_value tCOLON2 operation2 command_args %prec tLOWEST { $$ = @builder.unsupported(103) };
/* upstream parse.y:3627: command: primary_value "::" operation2 command_args cmd_brace_block */
command: primary_value tCOLON2 operation2 command_args cmd_brace_block %prec tCOLON2 { $$ = @builder.unsupported(104) };
/* upstream parse.y:3632: command: primary_value "::" "constant" '{' brace_body '}' */
command: primary_value tCOLON2 tCONSTANT '{' brace_body '}' %prec '}' { $$ = @builder.unsupported(105) };
/* upstream parse.y:3638: command: "'super'" command_args */
command: keyword_super command_args %prec keyword_super { $$ = @builder.unsupported(106) };
/* upstream parse.y:3644: command: k_yield command_args */
command: k_yield command_args { $$ = @builder.unsupported(107) };
/* upstream parse.y:3650: command: k_return call_args */
command: k_return call_args { $$ = @builder.unsupported(108) };
/* upstream parse.y:3655: command: "'break'" call_args */
command: keyword_break call_args %prec keyword_break { $$ = @builder.unsupported(109) };
/* upstream parse.y:3662: command: "'next'" call_args */
command: keyword_next call_args %prec keyword_next { $$ = @builder.unsupported(110) };
/* upstream parse.y:3670: mlhs: mlhs_basic */
mlhs: mlhs_basic { $$ = @builder.unsupported(111) };
/* upstream parse.y:3672: mlhs: "(" mlhs_inner rparen */
mlhs: tLPAREN mlhs_inner rparen %prec tLPAREN { $$ = @builder.unsupported(112) };
/* upstream parse.y:3678: mlhs_inner: mlhs_basic */
mlhs_inner: mlhs_basic { $$ = @builder.unsupported(113) };
/* upstream parse.y:3680: mlhs_inner: "(" mlhs_inner rparen */
mlhs_inner: tLPAREN mlhs_inner rparen %prec tLPAREN { $$ = @builder.unsupported(114) };
/* upstream parse.y:3687: mlhs_basic: mlhs_head */
mlhs_basic: mlhs_head { $$ = @builder.unsupported(115) };
/* upstream parse.y:3692: mlhs_basic: mlhs_head mlhs_item */
mlhs_basic: mlhs_head mlhs_item { $$ = @builder.unsupported(116) };
/* upstream parse.y:3697: mlhs_basic: mlhs_head "*" mlhs_node */
mlhs_basic: mlhs_head tSTAR mlhs_node %prec tSTAR { $$ = @builder.unsupported(117) };
/* upstream parse.y:3048: mlhs_items_mlhs_item: mlhs_item */
mlhs_items_mlhs_item: mlhs_item { $$ = @builder.unsupported(118) };
/* upstream parse.y:3053: mlhs_items_mlhs_item: mlhs_items_mlhs_item ',' mlhs_item */
mlhs_items_mlhs_item: mlhs_items_mlhs_item ',' mlhs_item %prec ',' { $$ = @builder.unsupported(119) };
/* upstream parse.y:3702: mlhs_basic: mlhs_head "*" mlhs_node ',' mlhs_items_mlhs_item */
mlhs_basic: mlhs_head tSTAR mlhs_node ',' mlhs_items_mlhs_item %prec ',' { $$ = @builder.unsupported(120) };
/* upstream parse.y:3707: mlhs_basic: mlhs_head "*" */
mlhs_basic: mlhs_head tSTAR %prec tSTAR { $$ = @builder.unsupported(121) };
/* upstream parse.y:3712: mlhs_basic: mlhs_head "*" ',' mlhs_items_mlhs_item */
mlhs_basic: mlhs_head tSTAR ',' mlhs_items_mlhs_item %prec ',' { $$ = @builder.unsupported(122) };
/* upstream parse.y:3717: mlhs_basic: "*" mlhs_node */
mlhs_basic: tSTAR mlhs_node %prec tSTAR { $$ = @builder.unsupported(123) };
/* upstream parse.y:3722: mlhs_basic: "*" mlhs_node ',' mlhs_items_mlhs_item */
mlhs_basic: tSTAR mlhs_node ',' mlhs_items_mlhs_item %prec ',' { $$ = @builder.unsupported(124) };
/* upstream parse.y:3727: mlhs_basic: "*" */
mlhs_basic: tSTAR %prec tSTAR { $$ = @builder.unsupported(125) };
/* upstream parse.y:3732: mlhs_basic: "*" ',' mlhs_items_mlhs_item */
mlhs_basic: tSTAR ',' mlhs_items_mlhs_item %prec ',' { $$ = @builder.unsupported(126) };
/* upstream parse.y:3738: mlhs_item: mlhs_node */
mlhs_item: mlhs_node { $$ = @builder.unsupported(127) };
/* upstream parse.y:3740: mlhs_item: "(" mlhs_inner rparen */
mlhs_item: tLPAREN mlhs_inner rparen %prec tLPAREN { $$ = @builder.unsupported(128) };
/* upstream parse.y:3747: mlhs_head: mlhs_item ',' */
mlhs_head: mlhs_item ',' %prec ',' { $$ = @builder.unsupported(129) };
/* upstream parse.y:3752: mlhs_head: mlhs_head mlhs_item ',' */
mlhs_head: mlhs_head mlhs_item ',' %prec ',' { $$ = @builder.unsupported(130) };
/* upstream parse.y:3760: mlhs_node: user_variable */
mlhs_node: user_variable { $$ = @builder.unsupported(131) };
/* upstream parse.y:3760: mlhs_node: keyword_variable */
mlhs_node: keyword_variable { $$ = @builder.unsupported(132) };
/* upstream parse.y:3765: mlhs_node: primary_value '[' opt_call_args rbracket */
mlhs_node: primary_value '[' opt_call_args rbracket %prec '[' { $$ = @builder.unsupported(133) };
/* upstream parse.y:3770: mlhs_node: primary_value call_op "local variable or method" */
mlhs_node: primary_value call_op tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(134) };
/* upstream parse.y:3770: mlhs_node: primary_value call_op "constant" */
mlhs_node: primary_value call_op tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(135) };
/* upstream parse.y:3776: mlhs_node: primary_value "::" "local variable or method" */
mlhs_node: primary_value tCOLON2 tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(136) };
/* upstream parse.y:3781: mlhs_node: primary_value "::" "constant" */
mlhs_node: primary_value tCOLON2 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(137) };
/* upstream parse.y:3786: mlhs_node: ":: at EXPR_BEG" "constant" */
mlhs_node: tCOLON3 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(138) };
/* upstream parse.y:3791: mlhs_node: backref */
mlhs_node: backref { $$ = @builder.unsupported(139) };
/* upstream parse.y:3799: lhs: user_variable */
lhs: user_variable { $$ = @builder.declare_local($1) };
/* upstream parse.y:3799: lhs: keyword_variable */
lhs: keyword_variable { $$ = @builder.unsupported(141) };
/* upstream parse.y:3804: lhs: primary_value '[' opt_call_args rbracket */
lhs: primary_value '[' opt_call_args rbracket %prec '[' { $$ = @builder.unsupported(142) };
/* upstream parse.y:3809: lhs: primary_value call_op "local variable or method" */
lhs: primary_value call_op tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(143) };
/* upstream parse.y:3809: lhs: primary_value call_op "constant" */
lhs: primary_value call_op tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(144) };
/* upstream parse.y:3814: lhs: primary_value "::" "local variable or method" */
lhs: primary_value tCOLON2 tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(145) };
/* upstream parse.y:3819: lhs: primary_value "::" "constant" */
lhs: primary_value tCOLON2 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(146) };
/* upstream parse.y:3824: lhs: ":: at EXPR_BEG" "constant" */
lhs: tCOLON3 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(147) };
/* upstream parse.y:3829: lhs: backref */
lhs: backref { $$ = @builder.unsupported(148) };
/* upstream parse.y:3837: cname: "local variable or method" */
cname: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(149) };
/* upstream parse.y:3844: cname: "constant" */
cname: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(150) };
/* upstream parse.y:3848: cpath: ":: at EXPR_BEG" cname */
cpath: tCOLON3 cname %prec tCOLON3 { $$ = @builder.unsupported(151) };
/* upstream parse.y:3853: cpath: cname */
cpath: cname { $$ = @builder.unsupported(152) };
/* upstream parse.y:3858: cpath: primary_value "::" cname */
cpath: primary_value tCOLON2 cname %prec tCOLON2 { $$ = @builder.unsupported(153) };
/* upstream parse.y:3864: fname: "local variable or method" */
fname: tIDENTIFIER %prec tIDENTIFIER { $$ = $1 };
/* upstream parse.y:3864: fname: "constant" */
fname: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(155) };
/* upstream parse.y:3864: fname: "method" */
fname: tFID %prec tFID { $$ = @builder.unsupported(156) };
/* upstream parse.y:3866: fname: op */
fname: op { $$ = @builder.unsupported(157) };
/* upstream parse.y:3870: fname: reswords */
fname: reswords { $$ = @builder.unsupported(158) };
/* upstream parse.y:3874: fitem: fname */
fitem: fname { $$ = @builder.unsupported(159) };
/* upstream parse.y:3878: fitem: symbol */
fitem: symbol { $$ = @builder.unsupported(160) };
/* upstream parse.y:3882: undef_list: fitem */
undef_list: fitem { $$ = @builder.unsupported(161) };
/* upstream parse.y:3886: $@12: %empty */
midrule_12: %empty { $$ = @builder.unsupported(162) };
/* upstream parse.y:3887: undef_list: undef_list ',' $@12 fitem */
undef_list: undef_list ',' midrule_12 fitem %prec ',' { $$ = @builder.unsupported(163) };
/* upstream parse.y:3894: op: '|' */
op: '|' %prec '|' { $$ = @builder.unsupported(164) };
/* upstream parse.y:3895: op: '^' */
op: '^' %prec '^' { $$ = @builder.unsupported(165) };
/* upstream parse.y:3896: op: '&' */
op: '&' %prec '&' { $$ = @builder.unsupported(166) };
/* upstream parse.y:3897: op: "<=>" */
op: tCMP %prec tCMP { $$ = @builder.unsupported(167) };
/* upstream parse.y:3898: op: "==" */
op: tEQ %prec tEQ { $$ = @builder.unsupported(168) };
/* upstream parse.y:3899: op: "===" */
op: tEQQ %prec tEQQ { $$ = @builder.unsupported(169) };
/* upstream parse.y:3900: op: "=~" */
op: tMATCH %prec tMATCH { $$ = @builder.unsupported(170) };
/* upstream parse.y:3901: op: "!~" */
op: tNMATCH %prec tNMATCH { $$ = @builder.unsupported(171) };
/* upstream parse.y:3902: op: '>' */
op: '>' %prec '>' { $$ = @builder.unsupported(172) };
/* upstream parse.y:3903: op: ">=" */
op: tGEQ %prec tGEQ { $$ = @builder.unsupported(173) };
/* upstream parse.y:3904: op: '<' */
op: '<' %prec '<' { $$ = @builder.unsupported(174) };
/* upstream parse.y:3905: op: "<=" */
op: tLEQ %prec tLEQ { $$ = @builder.unsupported(175) };
/* upstream parse.y:3906: op: "!=" */
op: tNEQ %prec tNEQ { $$ = @builder.unsupported(176) };
/* upstream parse.y:3907: op: "<<" */
op: tLSHFT %prec tLSHFT { $$ = @builder.unsupported(177) };
/* upstream parse.y:3908: op: ">>" */
op: tRSHFT %prec tRSHFT { $$ = @builder.unsupported(178) };
/* upstream parse.y:3909: op: '+' */
op: '+' %prec '+' { $$ = @builder.unsupported(179) };
/* upstream parse.y:3910: op: '-' */
op: '-' %prec '-' { $$ = @builder.unsupported(180) };
/* upstream parse.y:3911: op: '*' */
op: '*' %prec '*' { $$ = @builder.unsupported(181) };
/* upstream parse.y:3912: op: "*" */
op: tSTAR %prec tSTAR { $$ = @builder.unsupported(182) };
/* upstream parse.y:3913: op: '/' */
op: '/' %prec '/' { $$ = @builder.unsupported(183) };
/* upstream parse.y:3914: op: '%' */
op: '%' %prec '%' { $$ = @builder.unsupported(184) };
/* upstream parse.y:3915: op: "**" */
op: tPOW %prec tPOW { $$ = @builder.unsupported(185) };
/* upstream parse.y:3916: op: "**arg" */
op: tDSTAR %prec tDSTAR { $$ = @builder.unsupported(186) };
/* upstream parse.y:3917: op: '!' */
op: '!' %prec '!' { $$ = @builder.unsupported(187) };
/* upstream parse.y:3918: op: '~' */
op: '~' %prec '~' { $$ = @builder.unsupported(188) };
/* upstream parse.y:3919: op: "unary+" */
op: tUPLUS %prec tUPLUS { $$ = @builder.unsupported(189) };
/* upstream parse.y:3920: op: "unary-" */
op: tUMINUS %prec tUMINUS { $$ = @builder.unsupported(190) };
/* upstream parse.y:3921: op: "[]" */
op: tAREF %prec tAREF { $$ = @builder.unsupported(191) };
/* upstream parse.y:3922: op: "[]=" */
op: tASET %prec tASET { $$ = @builder.unsupported(192) };
/* upstream parse.y:3923: op: '`' */
op: '`' %prec '`' { $$ = @builder.unsupported(193) };
/* upstream parse.y:3926: reswords: "'__LINE__'" */
reswords: keyword__LINE__ %prec keyword__LINE__ { $$ = @builder.unsupported(194) };
/* upstream parse.y:3926: reswords: "'__FILE__'" */
reswords: keyword__FILE__ %prec keyword__FILE__ { $$ = @builder.unsupported(195) };
/* upstream parse.y:3926: reswords: "'__ENCODING__'" */
reswords: keyword__ENCODING__ %prec keyword__ENCODING__ { $$ = @builder.unsupported(196) };
/* upstream parse.y:3927: reswords: "'BEGIN'" */
reswords: keyword_BEGIN %prec keyword_BEGIN { $$ = @builder.unsupported(197) };
/* upstream parse.y:3927: reswords: "'END'" */
reswords: keyword_END %prec keyword_END { $$ = @builder.unsupported(198) };
/* upstream parse.y:3928: reswords: "'alias'" */
reswords: keyword_alias %prec keyword_alias { $$ = @builder.unsupported(199) };
/* upstream parse.y:3928: reswords: "'and'" */
reswords: keyword_and %prec keyword_and { $$ = @builder.unsupported(200) };
/* upstream parse.y:3928: reswords: "'begin'" */
reswords: keyword_begin %prec keyword_begin { $$ = @builder.unsupported(201) };
/* upstream parse.y:3929: reswords: "'break'" */
reswords: keyword_break %prec keyword_break { $$ = @builder.unsupported(202) };
/* upstream parse.y:3929: reswords: "'case'" */
reswords: keyword_case %prec keyword_case { $$ = @builder.unsupported(203) };
/* upstream parse.y:3929: reswords: "'class'" */
reswords: keyword_class %prec keyword_class { $$ = @builder.unsupported(204) };
/* upstream parse.y:3929: reswords: "'def'" */
reswords: keyword_def %prec keyword_def { $$ = @builder.unsupported(205) };
/* upstream parse.y:3930: reswords: "'defined?'" */
reswords: keyword_defined %prec keyword_defined { $$ = @builder.unsupported(206) };
/* upstream parse.y:3930: reswords: "'do'" */
reswords: keyword_do %prec keyword_do { $$ = @builder.unsupported(207) };
/* upstream parse.y:3930: reswords: "'else'" */
reswords: keyword_else %prec keyword_else { $$ = @builder.unsupported(208) };
/* upstream parse.y:3930: reswords: "'elsif'" */
reswords: keyword_elsif %prec keyword_elsif { $$ = @builder.unsupported(209) };
/* upstream parse.y:3931: reswords: "'end'" */
reswords: keyword_end %prec keyword_end { $$ = @builder.unsupported(210) };
/* upstream parse.y:3931: reswords: "'ensure'" */
reswords: keyword_ensure %prec keyword_ensure { $$ = @builder.unsupported(211) };
/* upstream parse.y:3931: reswords: "'false'" */
reswords: keyword_false %prec keyword_false { $$ = @builder.unsupported(212) };
/* upstream parse.y:3932: reswords: "'for'" */
reswords: keyword_for %prec keyword_for { $$ = @builder.unsupported(213) };
/* upstream parse.y:3932: reswords: "'in'" */
reswords: keyword_in %prec keyword_in { $$ = @builder.unsupported(214) };
/* upstream parse.y:3932: reswords: "'module'" */
reswords: keyword_module %prec keyword_module { $$ = @builder.unsupported(215) };
/* upstream parse.y:3932: reswords: "'next'" */
reswords: keyword_next %prec keyword_next { $$ = @builder.unsupported(216) };
/* upstream parse.y:3933: reswords: "'nil'" */
reswords: keyword_nil %prec keyword_nil { $$ = @builder.unsupported(217) };
/* upstream parse.y:3933: reswords: "'not'" */
reswords: keyword_not %prec keyword_not { $$ = @builder.unsupported(218) };
/* upstream parse.y:3933: reswords: "'or'" */
reswords: keyword_or %prec keyword_or { $$ = @builder.unsupported(219) };
/* upstream parse.y:3933: reswords: "'redo'" */
reswords: keyword_redo %prec keyword_redo { $$ = @builder.unsupported(220) };
/* upstream parse.y:3934: reswords: "'rescue'" */
reswords: keyword_rescue %prec keyword_rescue { $$ = @builder.unsupported(221) };
/* upstream parse.y:3934: reswords: "'retry'" */
reswords: keyword_retry %prec keyword_retry { $$ = @builder.unsupported(222) };
/* upstream parse.y:3934: reswords: "'return'" */
reswords: keyword_return %prec keyword_return { $$ = @builder.unsupported(223) };
/* upstream parse.y:3934: reswords: "'self'" */
reswords: keyword_self %prec keyword_self { $$ = @builder.unsupported(224) };
/* upstream parse.y:3935: reswords: "'super'" */
reswords: keyword_super %prec keyword_super { $$ = @builder.unsupported(225) };
/* upstream parse.y:3935: reswords: "'then'" */
reswords: keyword_then %prec keyword_then { $$ = @builder.unsupported(226) };
/* upstream parse.y:3935: reswords: "'true'" */
reswords: keyword_true %prec keyword_true { $$ = @builder.unsupported(227) };
/* upstream parse.y:3935: reswords: "'undef'" */
reswords: keyword_undef %prec keyword_undef { $$ = @builder.unsupported(228) };
/* upstream parse.y:3936: reswords: "'when'" */
reswords: keyword_when %prec keyword_when { $$ = @builder.unsupported(229) };
/* upstream parse.y:3936: reswords: "'yield'" */
reswords: keyword_yield %prec keyword_yield { $$ = @builder.unsupported(230) };
/* upstream parse.y:3936: reswords: "'if'" */
reswords: keyword_if %prec keyword_if { $$ = @builder.unsupported(231) };
/* upstream parse.y:3936: reswords: "'unless'" */
reswords: keyword_unless %prec keyword_unless { $$ = @builder.unsupported(232) };
/* upstream parse.y:3937: reswords: "'while'" */
reswords: keyword_while %prec keyword_while { $$ = @builder.unsupported(233) };
/* upstream parse.y:3937: reswords: "'until'" */
reswords: keyword_until %prec keyword_until { $$ = @builder.unsupported(234) };
/* upstream parse.y:2926: asgn_arg_rhs: lhs '=' lex_ctxt arg_rhs */
asgn_arg_rhs: lhs '=' lex_ctxt arg_rhs %prec '=' { $$ = @builder.assign($1, $4) };
/* upstream parse.y:3940: arg: asgn_arg_rhs */
arg: asgn_arg_rhs { $$ = $1 };
/* upstream parse.y:3061: op_asgn_arg_rhs: var_lhs "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: var_lhs tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(237) };
/* upstream parse.y:3066: op_asgn_arg_rhs: primary_value '[' opt_call_args rbracket "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: primary_value '[' opt_call_args rbracket tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(238) };
/* upstream parse.y:3071: op_asgn_arg_rhs: primary_value call_op "local variable or method" "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: primary_value call_op tIDENTIFIER tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(239) };
/* upstream parse.y:3076: op_asgn_arg_rhs: primary_value call_op "constant" "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: primary_value call_op tCONSTANT tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(240) };
/* upstream parse.y:3081: op_asgn_arg_rhs: primary_value "::" "local variable or method" "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: primary_value tCOLON2 tIDENTIFIER tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(241) };
/* upstream parse.y:3086: op_asgn_arg_rhs: primary_value "::" "constant" "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: primary_value tCOLON2 tCONSTANT tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(242) };
/* upstream parse.y:3092: op_asgn_arg_rhs: ":: at EXPR_BEG" "constant" "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: tCOLON3 tCONSTANT tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(243) };
/* upstream parse.y:3098: op_asgn_arg_rhs: backref "operator-assignment" lex_ctxt arg_rhs */
op_asgn_arg_rhs: backref tOP_ASGN lex_ctxt arg_rhs %prec tOP_ASGN { $$ = @builder.unsupported(244) };
/* upstream parse.y:3941: arg: op_asgn_arg_rhs */
arg: op_asgn_arg_rhs { $$ = @builder.unsupported(245) };
/* upstream parse.y:3120: range_expr_arg: arg ".." arg */
range_expr_arg: arg tDOT2 arg %prec tDOT2 { $$ = @builder.range(:"..", $1, $3) };
/* upstream parse.y:3127: range_expr_arg: arg "..." arg */
range_expr_arg: arg tDOT3 arg %prec tDOT3 { $$ = @builder.range(:"...", $1, $3) };
/* upstream parse.y:3134: range_expr_arg: arg ".." */
range_expr_arg: arg tDOT2 %prec tDOT2 { $$ = @builder.unsupported(248) };
/* upstream parse.y:3140: range_expr_arg: arg "..." */
range_expr_arg: arg tDOT3 %prec tDOT3 { $$ = @builder.unsupported(249) };
/* upstream parse.y:3146: range_expr_arg: "(.." arg */
range_expr_arg: tBDOT2 arg %prec tBDOT2 { $$ = @builder.unsupported(250) };
/* upstream parse.y:3152: range_expr_arg: "(..." arg */
range_expr_arg: tBDOT3 arg %prec tBDOT3 { $$ = @builder.unsupported(251) };
/* upstream parse.y:3942: arg: range_expr_arg */
arg: range_expr_arg { $$ = $1 };
/* upstream parse.y:3944: arg: arg '+' arg */
arg: arg '+' arg %prec '+' { $$ = @builder.binary(:+, $1, $3) };
/* upstream parse.y:3949: arg: arg '-' arg */
arg: arg '-' arg %prec '-' { $$ = @builder.binary(:-, $1, $3) };
/* upstream parse.y:3954: arg: arg '*' arg */
arg: arg '*' arg %prec '*' { $$ = @builder.binary(:*, $1, $3) };
/* upstream parse.y:3959: arg: arg '/' arg */
arg: arg '/' arg %prec '/' { $$ = @builder.binary(:/, $1, $3) };
/* upstream parse.y:3964: arg: arg '%' arg */
arg: arg '%' arg %prec '%' { $$ = @builder.binary(:%, $1, $3) };
/* upstream parse.y:3969: arg: arg "**" arg */
arg: arg tPOW arg %prec tPOW { $$ = @builder.unsupported(258) };
/* upstream parse.y:3974: arg: tUMINUS_NUM simple_numeric "**" arg */
arg: tUMINUS_NUM simple_numeric tPOW arg %prec tPOW { $$ = @builder.unsupported(259) };
/* upstream parse.y:3979: arg: "unary+" arg */
arg: tUPLUS arg %prec tUPLUS { $$ = @builder.unary(:+, $2) };
/* upstream parse.y:3984: arg: "unary-" arg */
arg: tUMINUS arg %prec tUMINUS { $$ = @builder.unary(:-, $2) };
/* upstream parse.y:3989: arg: arg '|' arg */
arg: arg '|' arg %prec '|' { $$ = @builder.binary(:"|", $1, $3) };
/* upstream parse.y:3994: arg: arg '^' arg */
arg: arg '^' arg %prec '^' { $$ = @builder.binary(:"^", $1, $3) };
/* upstream parse.y:3999: arg: arg '&' arg */
arg: arg '&' arg %prec '&' { $$ = @builder.binary(:"&", $1, $3) };
/* upstream parse.y:4004: arg: arg "<=>" arg */
arg: arg tCMP arg %prec tCMP { $$ = @builder.binary(:"<=>", $1, $3) };
/* upstream parse.y:4008: arg: rel_expr */
arg: rel_expr %prec tCMP { $$ = $1 };
/* upstream parse.y:4010: arg: arg "==" arg */
arg: arg tEQ arg %prec tEQ { $$ = @builder.binary(:"==", $1, $3) };
/* upstream parse.y:4015: arg: arg "===" arg */
arg: arg tEQQ arg %prec tEQQ { $$ = @builder.binary(:"===", $1, $3) };
/* upstream parse.y:4020: arg: arg "!=" arg */
arg: arg tNEQ arg %prec tNEQ { $$ = @builder.binary(:"!=", $1, $3) };
/* upstream parse.y:4025: arg: arg "=~" arg */
arg: arg tMATCH arg %prec tMATCH { $$ = @builder.binary(:"=~", $1, $3) };
/* upstream parse.y:4030: arg: arg "!~" arg */
arg: arg tNMATCH arg %prec tNMATCH { $$ = @builder.binary(:"!~", $1, $3) };
/* upstream parse.y:4035: arg: '!' arg */
arg: '!' arg %prec '!' { $$ = @builder.unary(:"!", $2) };
/* upstream parse.y:4040: arg: '~' arg */
arg: '~' arg %prec '~' { $$ = @builder.unary(:"~", $2) };
/* upstream parse.y:4045: arg: arg "<<" arg */
arg: arg tLSHFT arg %prec tLSHFT { $$ = @builder.binary(:"<<", $1, $3) };
/* upstream parse.y:4050: arg: arg ">>" arg */
arg: arg tRSHFT arg %prec tRSHFT { $$ = @builder.binary(:">>", $1, $3) };
/* upstream parse.y:4055: arg: arg "&&" arg */
arg: arg tANDOP arg %prec tANDOP { $$ = @builder.binary(:"&&", $1, $3) };
/* upstream parse.y:4060: arg: arg "||" arg */
arg: arg tOROP arg %prec tOROP { $$ = @builder.binary(:"||", $1, $3) };
/* upstream parse.y:4065: arg: "'defined?'" option_'\n' begin_defined arg */
arg: keyword_defined option_newline begin_defined arg %prec keyword_defined { $$ = @builder.unsupported(278) };
/* upstream parse.y:2966: def_endless_method_endless_arg: defn_head f_opt_paren_args '=' endless_arg */
def_endless_method_endless_arg: defn_head f_opt_paren_args '=' endless_arg %prec '=' { $$ = @builder.unsupported(279) };
/* upstream parse.y:2977: def_endless_method_endless_arg: defs_head f_opt_paren_args '=' endless_arg */
def_endless_method_endless_arg: defs_head f_opt_paren_args '=' endless_arg %prec '=' { $$ = @builder.unsupported(280) };
/* upstream parse.y:4071: arg: def_endless_method_endless_arg */
arg: def_endless_method_endless_arg { $$ = @builder.unsupported(281) };
/* upstream parse.y:4072: arg: ternary */
arg: ternary { $$ = $1 };
/* upstream parse.y:4073: arg: primary */
arg: primary { $$ = $1 };
/* upstream parse.y:4077: ternary: arg '?' arg option_'\n' ':' arg */
ternary: arg '?' arg option_newline ':' arg %prec ':' { $$ = @builder.ternary($1, $3, $6) };
/* upstream parse.y:4085: endless_arg: arg */
endless_arg: arg %prec modifier_rescue { $$ = @builder.unsupported(285) };
/* upstream parse.y:4087: endless_arg: endless_arg "'rescue' modifier" after_rescue arg */
endless_arg: endless_arg modifier_rescue after_rescue arg %prec modifier_rescue { $$ = @builder.unsupported(286) };
/* upstream parse.y:4093: endless_arg: "'not'" option_'\n' endless_arg */
endless_arg: keyword_not option_newline endless_arg %prec keyword_not { $$ = @builder.unsupported(287) };
/* upstream parse.y:4099: relop: '>' */
relop: '>' %prec '>' { $$ = @builder.operator(">") };
/* upstream parse.y:4100: relop: '<' */
relop: '<' %prec '<' { $$ = @builder.operator("<") };
/* upstream parse.y:4101: relop: ">=" */
relop: tGEQ %prec tGEQ { $$ = @builder.operator(">=") };
/* upstream parse.y:4102: relop: "<=" */
relop: tLEQ %prec tLEQ { $$ = @builder.operator("<=") };
/* upstream parse.y:4106: rel_expr: arg relop arg */
rel_expr: arg relop arg %prec '>' { $$ = @builder.binary($2, $1, $3) };
/* upstream parse.y:4111: rel_expr: rel_expr relop arg */
rel_expr: rel_expr relop arg %prec '>' { $$ = @builder.binary($2, $1, $3) };
/* upstream parse.y:4119: lex_ctxt: none */
lex_ctxt: none { $$ = nil };
/* upstream parse.y:4125: begin_defined: lex_ctxt */
begin_defined: lex_ctxt { $$ = nil };
/* upstream parse.y:4132: after_rescue: lex_ctxt */
after_rescue: lex_ctxt { $$ = @builder.unsupported(296) };
/* upstream parse.y:3161: value_expr_arg: arg */
value_expr_arg: arg { $$ = $1 };
/* upstream parse.y:4138: arg_value: value_expr_arg */
arg_value: value_expr_arg { $$ = $1 };
/* upstream parse.y:4141: aref_args: none */
aref_args: none { $$ = [].freeze };
/* upstream parse.y:4142: aref_args: args trailer */
aref_args: args trailer { $$ = $1 };
/* upstream parse.y:4144: aref_args: args ',' assocs trailer */
aref_args: args ',' assocs trailer %prec ',' { $$ = ($1 + $3).freeze };
/* upstream parse.y:4149: aref_args: assocs trailer */
aref_args: assocs trailer { $$ = $1 };
/* upstream parse.y:4156: arg_rhs: arg */
arg_rhs: arg %prec tOP_ASGN { $$ = $1 };
/* upstream parse.y:4161: arg_rhs: arg "'rescue' modifier" after_rescue arg */
arg_rhs: arg modifier_rescue after_rescue arg %prec modifier_rescue { $$ = @builder.unsupported(304) };
/* upstream parse.y:4170: paren_args: '(' opt_call_args rparen */
paren_args: '(' opt_call_args rparen %prec '(' { $$ = $2 };
/* upstream parse.y:4175: paren_args: '(' args ',' args_forward rparen */
paren_args: '(' args ',' args_forward rparen %prec ',' { $$ = @builder.unsupported(306) };
/* upstream parse.y:4185: paren_args: '(' args_forward rparen */
paren_args: '(' args_forward rparen %prec '(' { $$ = @builder.unsupported(307) };
/* upstream parse.y:4196: opt_paren_args: none */
opt_paren_args: none { $$ = nil };
/* upstream parse.y:4198: opt_paren_args: paren_args */
opt_paren_args: paren_args { $$ = $1 };
/* upstream parse.y:4203: opt_call_args: none */
opt_call_args: none { $$ = nil };
/* upstream parse.y:4204: opt_call_args: call_args */
opt_call_args: call_args { $$ = $1 };
/* upstream parse.y:4205: opt_call_args: args ',' */
opt_call_args: args ',' %prec ',' { $$ = $1 };
/* upstream parse.y:4207: opt_call_args: args ',' assocs ',' */
opt_call_args: args ',' assocs ',' %prec ',' { $$ = @builder.unsupported(313) };
/* upstream parse.y:4212: opt_call_args: assocs ',' */
opt_call_args: assocs ',' %prec ',' { $$ = @builder.unsupported(314) };
/* upstream parse.y:3161: value_expr_command: command */
value_expr_command: command { $$ = @builder.unsupported(315) };
/* upstream parse.y:4219: call_args: value_expr_command */
call_args: value_expr_command { $$ = @builder.unsupported(316) };
/* upstream parse.y:4224: call_args: def_endless_method_endless_command */
call_args: def_endless_method_endless_command { $$ = @builder.unsupported(317) };
/* upstream parse.y:4229: call_args: args opt_block_arg */
call_args: args opt_block_arg { $$ = $1 };
/* upstream parse.y:4234: call_args: assocs opt_block_arg */
call_args: assocs opt_block_arg { $$ = @builder.unsupported(319) };
/* upstream parse.y:4240: call_args: args ',' assocs opt_block_arg */
call_args: args ',' assocs opt_block_arg %prec ',' { $$ = @builder.unsupported(320) };
/* upstream parse.y:4245: call_args: block_arg */
call_args: block_arg { $$ = @builder.unsupported(321) };
/* upstream parse.y:4249: $@13: %empty */
midrule_13: %empty { $$ = @builder.unsupported(322) };
/* upstream parse.y:4267: command_args: $@13 call_args */
command_args: midrule_13 call_args { $$ = @builder.unsupported(323) };
/* upstream parse.y:4288: block_arg: "&" arg_value */
block_arg: tAMPER arg_value %prec tAMPER { $$ = @builder.unsupported(324) };
/* upstream parse.y:4293: block_arg: "&" */
block_arg: tAMPER %prec tAMPER { $$ = @builder.unsupported(325) };
/* upstream parse.y:4301: opt_block_arg: ',' block_arg */
opt_block_arg: ',' block_arg %prec ',' { $$ = @builder.unsupported(326) };
/* upstream parse.y:4306: opt_block_arg: none */
opt_block_arg: none { $$ = nil };
/* upstream parse.y:4314: args: arg_value */
args: arg_value { $$ = [$1].freeze };
/* upstream parse.y:4319: args: arg_splat */
args: arg_splat { $$ = @builder.unsupported(329) };
/* upstream parse.y:4324: args: args ',' arg_value */
args: args ',' arg_value %prec ',' { $$ = ($1 + [$3]).freeze };
/* upstream parse.y:4329: args: args ',' arg_splat */
args: args ',' arg_splat %prec ',' { $$ = @builder.unsupported(331) };
/* upstream parse.y:4337: arg_splat: "*" arg_value */
arg_splat: tSTAR arg_value %prec tSTAR { $$ = @builder.unsupported(332) };
/* upstream parse.y:4342: arg_splat: "*" */
arg_splat: tSTAR %prec tSTAR { $$ = @builder.unsupported(333) };
/* upstream parse.y:4350: mrhs_arg: mrhs */
mrhs_arg: mrhs { $$ = @builder.unsupported(334) };
/* upstream parse.y:4351: mrhs_arg: arg_value */
mrhs_arg: arg_value { $$ = @builder.unsupported(335) };
/* upstream parse.y:4356: mrhs: args ',' arg_value */
mrhs: args ',' arg_value %prec ',' { $$ = @builder.unsupported(336) };
/* upstream parse.y:4361: mrhs: args ',' "*" arg_value */
mrhs: args ',' tSTAR arg_value %prec tSTAR { $$ = @builder.unsupported(337) };
/* upstream parse.y:4366: mrhs: "*" arg_value */
mrhs: tSTAR arg_value %prec tSTAR { $$ = @builder.unsupported(338) };
/* upstream parse.y:4383: primary: literal */
primary: literal { $$ = $1 };
/* upstream parse.y:4383: primary: strings */
primary: strings { $$ = $1 };
/* upstream parse.y:4383: primary: xstring */
primary: xstring { $$ = @builder.unsupported(341) };
/* upstream parse.y:4383: primary: regexp */
primary: regexp { $$ = @builder.unsupported(342) };
/* upstream parse.y:4383: primary: words */
primary: words { $$ = @builder.unsupported(343) };
/* upstream parse.y:4383: primary: qwords */
primary: qwords { $$ = @builder.unsupported(344) };
/* upstream parse.y:4383: primary: symbols */
primary: symbols { $$ = $1 };
/* upstream parse.y:4383: primary: qsymbols */
primary: qsymbols { $$ = @builder.unsupported(346) };
/* upstream parse.y:4384: primary: var_ref */
primary: var_ref { $$ = $1 };
/* upstream parse.y:4385: primary: backref */
primary: backref { $$ = $1 };
/* upstream parse.y:4387: primary: "method" */
primary: tFID %prec tFID { $$ = @builder.unsupported(349) };
/* upstream parse.y:4392: $@14: %empty */
midrule_14: %empty { $$ = @builder.unsupported(350) };
/* upstream parse.y:4397: primary: k_begin $@14 bodystmt k_end */
primary: k_begin midrule_14 bodystmt k_end { $$ = @builder.unsupported(351) };
/* upstream parse.y:4404: $@15: %empty */
midrule_15: %empty { $$ = @builder.unsupported(352) };
/* upstream parse.y:4405: primary: "( arg" compstmt_stmts $@15 ')' */
primary: tLPAREN_ARG compstmt_stmts midrule_15 ')' %prec ')' { $$ = @builder.unsupported(353) };
/* upstream parse.y:4411: primary: "(" compstmt_stmts ')' */
primary: tLPAREN compstmt_stmts ')' %prec ')' { $$ = @builder.parentheses($2, 354) };
/* upstream parse.y:4417: primary: primary_value "::" "constant" */
primary: primary_value tCOLON2 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(355) };
/* upstream parse.y:4422: primary: ":: at EXPR_BEG" "constant" */
primary: tCOLON3 tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(356) };
/* upstream parse.y:4427: primary: "[" aref_args ']' */
primary: tLBRACK aref_args ']' %prec ']' { $$ = @builder.array($2) };
/* upstream parse.y:4432: primary: "{" assoc_list '}' */
primary: tLBRACE assoc_list '}' %prec '}' { $$ = @builder.hash($2) };
/* upstream parse.y:4438: primary: k_return */
primary: k_return { $$ = @builder.control(:return) };
/* upstream parse.y:4443: primary: k_yield '(' call_args rparen */
primary: k_yield '(' call_args rparen %prec '(' { $$ = @builder.call(:yield, $3 || []) };
/* upstream parse.y:4448: primary: k_yield '(' rparen */
primary: k_yield '(' rparen %prec '(' { $$ = @builder.call(:yield, []) };
/* upstream parse.y:4453: primary: k_yield */
primary: k_yield { $$ = @builder.call(:yield, []) };
/* upstream parse.y:4458: primary: "'defined?'" option_'\n' '(' begin_defined expr rparen */
primary: keyword_defined option_newline '(' begin_defined expr rparen %prec '(' { $$ = @builder.call(:defined, [$5]) };
/* upstream parse.y:4465: primary: "'not'" '(' expr rparen */
primary: keyword_not '(' expr rparen %prec '(' { $$ = @builder.unary(:"!", $3) };
/* upstream parse.y:4470: primary: "'not'" '(' rparen */
primary: keyword_not '(' rparen %prec '(' { $$ = @builder.unsupported(365) };
/* upstream parse.y:4475: primary: fcall brace_block */
primary: fcall brace_block { $$ = @builder.unsupported(366) };
/* upstream parse.y:4479: primary: method_call */
primary: method_call { $$ = $1 };
/* upstream parse.y:4481: primary: method_call brace_block */
primary: method_call brace_block { $$ = @builder.unsupported(368) };
/* upstream parse.y:4486: primary: lambda */
primary: lambda { $$ = @builder.unsupported(369) };
/* upstream parse.y:4491: primary: k_if expr_value then compstmt_stmts if_tail k_end */
primary: k_if expr_value then compstmt_stmts if_tail k_end { $$ = @builder.if_node($2, $4, $5) };
/* upstream parse.y:4503: primary: k_unless expr_value then compstmt_stmts opt_else k_end */
primary: k_unless expr_value then compstmt_stmts opt_else k_end { $$ = @builder.unless_node($2, $4, $5) };
/* upstream parse.y:4511: primary: k_while expr_value_do compstmt_stmts k_end */
primary: k_while expr_value_do compstmt_stmts k_end { $$ = @builder.loop(:while, $2, $3) };
/* upstream parse.y:4520: primary: k_until expr_value_do compstmt_stmts k_end */
primary: k_until expr_value_do compstmt_stmts k_end { $$ = @builder.loop(:until, $2, $3) };
/* upstream parse.y:4527: @16: %empty */
midrule_16: %empty { $$ = @builder.unsupported(374) };
/* upstream parse.y:4533: primary: k_case expr_value option_terms @16 case_body k_end */
primary: k_case expr_value option_terms midrule_16 case_body k_end { $$ = @builder.unsupported(375) };
/* upstream parse.y:4541: @17: %empty */
midrule_17: %empty { $$ = @builder.unsupported(376) };
/* upstream parse.y:4547: primary: k_case option_terms @17 case_body k_end */
primary: k_case option_terms midrule_17 case_body k_end { $$ = @builder.unsupported(377) };
/* upstream parse.y:4556: primary: k_case expr_value option_terms p_case_body k_end */
primary: k_case expr_value option_terms p_case_body k_end { $$ = @builder.unsupported(378) };
/* upstream parse.y:4561: $@18: %empty */
midrule_18: %empty { $$ = @builder.unsupported(379) };
/* upstream parse.y:4561: $@19: %empty */
midrule_19: %empty { $$ = @builder.unsupported(380) };
/* upstream parse.y:4564: primary: k_for for_var "'in'" $@18 expr_value do $@19 compstmt_stmts k_end */
primary: k_for for_var keyword_in midrule_18 expr_value do midrule_19 compstmt_stmts k_end %prec keyword_in { $$ = @builder.unsupported(381) };
/* upstream parse.y:4606: $@20: %empty */
midrule_20: %empty { $$ = @builder.unsupported(382) };
/* upstream parse.y:4611: primary: k_class cpath superclass $@20 bodystmt k_end */
primary: k_class cpath superclass midrule_20 bodystmt k_end { $$ = @builder.unsupported(383) };
/* upstream parse.y:4628: $@21: %empty */
midrule_21: %empty { $$ = @builder.unsupported(384) };
/* upstream parse.y:4634: primary: k_class "<<" expr_value $@21 term bodystmt k_end */
primary: k_class tLSHFT expr_value midrule_21 term bodystmt k_end %prec tLSHFT { $$ = @builder.unsupported(385) };
/* upstream parse.y:4647: $@22: %empty */
midrule_22: %empty { $$ = @builder.unsupported(386) };
/* upstream parse.y:4652: primary: k_module cpath $@22 bodystmt k_end */
primary: k_module cpath midrule_22 bodystmt k_end { $$ = @builder.unsupported(387) };
/* upstream parse.y:4665: $@23: %empty */
midrule_23: %empty { $$ = @builder.unsupported(388) };
/* upstream parse.y:4670: primary: defn_head f_arglist $@23 bodystmt k_end */
primary: defn_head f_arglist midrule_23 bodystmt k_end { $$ = @builder.unsupported(389) };
/* upstream parse.y:4680: $@24: %empty */
midrule_24: %empty { $$ = @builder.unsupported(390) };
/* upstream parse.y:4685: primary: defs_head f_arglist $@24 bodystmt k_end */
primary: defs_head f_arglist midrule_24 bodystmt k_end { $$ = @builder.unsupported(391) };
/* upstream parse.y:4694: primary: "'break'" */
primary: keyword_break %prec keyword_break { $$ = @builder.control(:break) };
/* upstream parse.y:4699: primary: "'next'" */
primary: keyword_next %prec keyword_next { $$ = @builder.control(:next) };
/* upstream parse.y:4704: primary: "'redo'" */
primary: keyword_redo %prec keyword_redo { $$ = @builder.control(:redo) };
/* upstream parse.y:4709: primary: "'retry'" */
primary: keyword_retry %prec keyword_retry { $$ = @builder.control(:retry) };
/* upstream parse.y:3161: value_expr_primary: primary */
value_expr_primary: primary { $$ = $1 };
/* upstream parse.y:4723: primary_value: value_expr_primary */
primary_value: value_expr_primary { $$ = $1 };
/* upstream parse.y:4727: k_begin: "'begin'" */
k_begin: keyword_begin %prec keyword_begin { $$ = @builder.unsupported(398) };
/* upstream parse.y:4734: k_if: "'if'" */
k_if: keyword_if %prec keyword_if { $$ = nil };
/* upstream parse.y:4752: k_unless: "'unless'" */
k_unless: keyword_unless %prec keyword_unless { $$ = nil };
/* upstream parse.y:4759: k_while: "'while'" allow_exits */
k_while: keyword_while allow_exits %prec keyword_while { $$ = nil };
/* upstream parse.y:4767: k_until: "'until'" allow_exits */
k_until: keyword_until allow_exits %prec keyword_until { $$ = nil };
/* upstream parse.y:4775: k_case: "'case'" */
k_case: keyword_case %prec keyword_case { $$ = @builder.unsupported(403) };
/* upstream parse.y:4782: k_for: "'for'" allow_exits */
k_for: keyword_for allow_exits %prec keyword_for { $$ = @builder.unsupported(404) };
/* upstream parse.y:4790: k_class: "'class'" */
k_class: keyword_class %prec keyword_class { $$ = @builder.unsupported(405) };
/* upstream parse.y:4799: k_module: "'module'" */
k_module: keyword_module %prec keyword_module { $$ = @builder.unsupported(406) };
/* upstream parse.y:4808: k_def: "'def'" */
k_def: keyword_def %prec keyword_def { $$ = @builder.unsupported(407) };
/* upstream parse.y:4816: k_do: "'do'" */
k_do: keyword_do %prec keyword_do { $$ = @builder.unsupported(408) };
/* upstream parse.y:4823: k_do_block: "'do' for block" */
k_do_block: keyword_do_block %prec keyword_do_block { $$ = @builder.unsupported(409) };
/* upstream parse.y:4830: k_rescue: "'rescue'" */
k_rescue: keyword_rescue %prec keyword_rescue { $$ = @builder.unsupported(410) };
/* upstream parse.y:4838: k_ensure: "'ensure'" */
k_ensure: keyword_ensure %prec keyword_ensure { $$ = @builder.unsupported(411) };
/* upstream parse.y:4845: k_when: "'when'" */
k_when: keyword_when %prec keyword_when { $$ = @builder.unsupported(412) };
/* upstream parse.y:4851: k_else: "'else'" */
k_else: keyword_else %prec keyword_else { $$ = nil };
/* upstream parse.y:4866: k_elsif: "'elsif'" */
k_elsif: keyword_elsif %prec keyword_elsif { $$ = nil };
/* upstream parse.y:4873: k_end: "'end'" */
k_end: keyword_end %prec keyword_end { $$ = nil };
/* upstream parse.y:4878: k_end: "dummy end" */
k_end: tDUMNY_END %prec tDUMNY_END { $$ = @builder.unsupported(416) };
/* upstream parse.y:4884: k_return: "'return'" */
k_return: keyword_return %prec keyword_return { $$ = nil };
/* upstream parse.y:4891: k_yield: "'yield'" */
k_yield: keyword_yield %prec keyword_yield { $$ = nil };
/* upstream parse.y:4897: then: term */
then: term { $$ = nil };
/* upstream parse.y:4898: then: "'then'" */
then: keyword_then %prec keyword_then { $$ = nil };
/* upstream parse.y:4899: then: term "'then'" */
then: term keyword_then %prec keyword_then { $$ = nil };
/* upstream parse.y:4902: do: term */
do: term { $$ = @builder.unsupported(422) };
/* upstream parse.y:4903: do: "'do' for condition" */
do: keyword_do_cond %prec keyword_do_cond { $$ = nil };
/* upstream parse.y:4906: if_tail: opt_else */
if_tail: opt_else { $$ = $1 };
/* upstream parse.y:4910: if_tail: k_elsif expr_value then compstmt_stmts if_tail */
if_tail: k_elsif expr_value then compstmt_stmts if_tail { $$ = @builder.elsif_node($2, $4, $5) };
/* upstream parse.y:4917: opt_else: none */
opt_else: none { $$ = nil };
/* upstream parse.y:4919: opt_else: k_else compstmt_stmts */
opt_else: k_else compstmt_stmts { $$ = $2 };
/* upstream parse.y:4925: for_var: lhs */
for_var: lhs { $$ = @builder.unsupported(428) };
/* upstream parse.y:4926: for_var: mlhs */
for_var: mlhs { $$ = @builder.unsupported(429) };
/* upstream parse.y:4930: f_marg: f_norm_arg */
f_marg: f_norm_arg { $$ = @builder.unsupported(430) };
/* upstream parse.y:4935: f_marg: "(" f_margs rparen */
f_marg: tLPAREN f_margs rparen %prec tLPAREN { $$ = @builder.unsupported(431) };
/* upstream parse.y:3048: mlhs_items_f_marg: f_marg */
mlhs_items_f_marg: f_marg { $$ = @builder.unsupported(432) };
/* upstream parse.y:3053: mlhs_items_f_marg: mlhs_items_f_marg ',' f_marg */
mlhs_items_f_marg: mlhs_items_f_marg ',' f_marg %prec ',' { $$ = @builder.unsupported(433) };
/* upstream parse.y:4943: f_margs: mlhs_items_f_marg */
f_margs: mlhs_items_f_marg { $$ = @builder.unsupported(434) };
/* upstream parse.y:4948: f_margs: mlhs_items_f_marg ',' f_rest_marg */
f_margs: mlhs_items_f_marg ',' f_rest_marg %prec ',' { $$ = @builder.unsupported(435) };
/* upstream parse.y:4953: f_margs: mlhs_items_f_marg ',' f_rest_marg ',' mlhs_items_f_marg */
f_margs: mlhs_items_f_marg ',' f_rest_marg ',' mlhs_items_f_marg %prec ',' { $$ = @builder.unsupported(436) };
/* upstream parse.y:4958: f_margs: f_rest_marg */
f_margs: f_rest_marg { $$ = @builder.unsupported(437) };
/* upstream parse.y:4963: f_margs: f_rest_marg ',' mlhs_items_f_marg */
f_margs: f_rest_marg ',' mlhs_items_f_marg %prec ',' { $$ = @builder.unsupported(438) };
/* upstream parse.y:4970: f_rest_marg: "*" f_norm_arg */
f_rest_marg: tSTAR f_norm_arg %prec tSTAR { $$ = @builder.unsupported(439) };
/* upstream parse.y:4976: f_rest_marg: "*" */
f_rest_marg: tSTAR %prec tSTAR { $$ = @builder.unsupported(440) };
/* upstream parse.y:4982: f_any_kwrest: f_kwrest */
f_any_kwrest: f_kwrest { $$ = @builder.unsupported(441) };
/* upstream parse.y:4984: f_any_kwrest: f_no_kwarg */
f_any_kwrest: f_no_kwarg { $$ = @builder.unsupported(442) };
/* upstream parse.y:4990: $@25: %empty */
midrule_25: %empty { $$ = @builder.unsupported(443) };
/* upstream parse.y:4990: f_eq: $@25 '=' */
f_eq: midrule_25 '=' %prec '=' { $$ = @builder.unsupported(444) };
/* upstream parse.y:3020: f_kw_primary_value: f_label primary_value */
f_kw_primary_value: f_label primary_value { $$ = @builder.unsupported(445) };
/* upstream parse.y:3026: f_kw_primary_value: f_label */
f_kw_primary_value: f_label { $$ = @builder.unsupported(446) };
/* upstream parse.y:3035: f_kwarg_primary_value: f_kw_primary_value */
f_kwarg_primary_value: f_kw_primary_value { $$ = @builder.unsupported(447) };
/* upstream parse.y:3040: f_kwarg_primary_value: f_kwarg_primary_value ',' f_kw_primary_value */
f_kwarg_primary_value: f_kwarg_primary_value ',' f_kw_primary_value %prec ',' { $$ = @builder.unsupported(448) };
/* upstream parse.y:2957: opt_f_block_arg_none: ',' f_block_arg */
opt_f_block_arg_none: ',' f_block_arg %prec ',' { $$ = @builder.unsupported(449) };
/* upstream parse.y:4992: opt_f_block_arg_none: none */
opt_f_block_arg_none: none { $$ = @builder.unsupported(450) };
/* upstream parse.y:2934: args_tail_basic_primary_value_none: f_kwarg_primary_value ',' f_kwrest opt_f_block_arg_none */
args_tail_basic_primary_value_none: f_kwarg_primary_value ',' f_kwrest opt_f_block_arg_none %prec ',' { $$ = @builder.unsupported(451) };
/* upstream parse.y:2939: args_tail_basic_primary_value_none: f_kwarg_primary_value opt_f_block_arg_none */
args_tail_basic_primary_value_none: f_kwarg_primary_value opt_f_block_arg_none { $$ = @builder.unsupported(452) };
/* upstream parse.y:2944: args_tail_basic_primary_value_none: f_any_kwrest opt_f_block_arg_none */
args_tail_basic_primary_value_none: f_any_kwrest opt_f_block_arg_none { $$ = @builder.unsupported(453) };
/* upstream parse.y:2949: args_tail_basic_primary_value_none: f_block_arg */
args_tail_basic_primary_value_none: f_block_arg { $$ = @builder.unsupported(454) };
/* upstream parse.y:4992: block_args_tail: args_tail_basic_primary_value_none */
block_args_tail: args_tail_basic_primary_value_none { $$ = @builder.unsupported(455) };
/* upstream parse.y:4996: excessed_comma: ',' */
excessed_comma: ',' %prec ',' { $$ = @builder.unsupported(456) };
/* upstream parse.y:2998: f_opt_primary_value: f_arg_asgn f_eq primary_value */
f_opt_primary_value: f_arg_asgn f_eq primary_value { $$ = @builder.unsupported(457) };
/* upstream parse.y:3007: f_opt_arg_primary_value: f_opt_primary_value */
f_opt_arg_primary_value: f_opt_primary_value { $$ = @builder.unsupported(458) };
/* upstream parse.y:3012: f_opt_arg_primary_value: f_opt_arg_primary_value ',' f_opt_primary_value */
f_opt_arg_primary_value: f_opt_arg_primary_value ',' f_opt_primary_value %prec ',' { $$ = @builder.unsupported(459) };
/* upstream parse.y:3107: opt_args_tail_block_args_tail_none: ',' block_args_tail */
opt_args_tail_block_args_tail_none: ',' block_args_tail %prec ',' { $$ = @builder.unsupported(460) };
/* upstream parse.y:3112: opt_args_tail_block_args_tail_none: none */
opt_args_tail_block_args_tail_none: none { $$ = @builder.unsupported(461) };
/* upstream parse.y:6277: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_rest_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_rest_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(462) };
/* upstream parse.y:6282: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(463) };
/* upstream parse.y:6287: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(464) };
/* upstream parse.y:6292: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_opt_arg_primary_value ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(465) };
/* upstream parse.y:6297: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_rest_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_rest_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(466) };
/* upstream parse.y:6302: args-list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(467) };
/* upstream parse.y:6307: args-list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_rest_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_rest_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(468) };
/* upstream parse.y:6312: args-list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(469) };
/* upstream parse.y:6317: args-list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value opt_args_tail_block_args_tail_none { $$ = @builder.unsupported(470) };
/* upstream parse.y:6322: args-list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_opt_arg_primary_value ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(471) };
/* upstream parse.y:6327: args-list_primary_value_opt_args_tail_block_args_tail_none: f_rest_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_rest_arg opt_args_tail_block_args_tail_none { $$ = @builder.unsupported(472) };
/* upstream parse.y:6332: args-list_primary_value_opt_args_tail_block_args_tail_none: f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none */
args_list_primary_value_opt_args_tail_block_args_tail_none: f_rest_arg ',' f_arg opt_args_tail_block_args_tail_none %prec ',' { $$ = @builder.unsupported(473) };
/* upstream parse.y:5003: block_param: args-list_primary_value_opt_args_tail_block_args_tail_none */
block_param: args_list_primary_value_opt_args_tail_block_args_tail_none { $$ = @builder.unsupported(474) };
/* upstream parse.y:5005: block_param: f_arg excessed_comma */
block_param: f_arg excessed_comma { $$ = @builder.unsupported(475) };
/* upstream parse.y:5011: block_param: f_arg opt_args_tail_block_args_tail_none */
block_param: f_arg opt_args_tail_block_args_tail_none { $$ = @builder.unsupported(476) };
/* upstream parse.y:6340: tail-only-args_block_args_tail: block_args_tail */
tail_only_args_block_args_tail: block_args_tail { $$ = @builder.unsupported(477) };
/* upstream parse.y:5015: block_param: tail-only-args_block_args_tail */
block_param: tail_only_args_block_args_tail { $$ = @builder.unsupported(478) };
/* upstream parse.y:5018: opt_block_param_def: none */
opt_block_param_def: none { $$ = @builder.unsupported(479) };
/* upstream parse.y:5020: opt_block_param_def: block_param_def */
opt_block_param_def: block_param_def { $$ = @builder.unsupported(480) };
/* upstream parse.y:5026: block_param_def: '|' opt_block_param opt_bv_decl '|' */
block_param_def: '|' opt_block_param opt_bv_decl '|' %prec '|' { $$ = @builder.unsupported(481) };
/* upstream parse.y:5035: opt_block_param: %empty */
opt_block_param: %empty { $$ = @builder.unsupported(482) };
/* upstream parse.y:5039: opt_block_param: block_param */
opt_block_param: block_param { $$ = @builder.unsupported(483) };
/* upstream parse.y:5043: opt_bv_decl: option_'\n' */
opt_bv_decl: option_newline { $$ = @builder.unsupported(484) };
/* upstream parse.y:5048: opt_bv_decl: option_'\n' ';' bv_decls option_'\n' */
opt_bv_decl: option_newline ';' bv_decls option_newline %prec ';' { $$ = @builder.unsupported(485) };
/* upstream parse.y:5054: bv_decls: bvar */
bv_decls: bvar { $$ = @builder.unsupported(486) };
/* upstream parse.y:5056: bv_decls: bv_decls ',' bvar */
bv_decls: bv_decls ',' bvar %prec ',' { $$ = @builder.unsupported(487) };
/* upstream parse.y:5061: bvar: "local variable or method" */
bvar: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(488) };
/* upstream parse.y:5065: bvar: f_bad_arg */
bvar: f_bad_arg { $$ = @builder.unsupported(489) };
/* upstream parse.y:5068: max_numparam: %empty */
max_numparam: %empty { $$ = @builder.unsupported(490) };
/* upstream parse.y:5074: numparam: %empty */
numparam: %empty { $$ = @builder.unsupported(491) };
/* upstream parse.y:5079: it_id: %empty */
it_id: %empty { $$ = @builder.unsupported(492) };
/* upstream parse.y:5086: @26: %empty */
midrule_26: %empty { $$ = @builder.unsupported(493) };
/* upstream parse.y:5092: $@27: %empty */
midrule_27: %empty { $$ = @builder.unsupported(494) };
/* upstream parse.y:5096: lambda: "->" @26 max_numparam numparam it_id allow_exits f_larglist $@27 lambda_body */
lambda: tLAMBDA midrule_26 max_numparam numparam it_id allow_exits f_larglist midrule_27 lambda_body %prec tLAMBDA { $$ = @builder.unsupported(495) };
/* upstream parse.y:5120: f_larglist: '(' f_largs opt_bv_decl ')' */
f_larglist: '(' f_largs opt_bv_decl ')' %prec ')' { $$ = @builder.unsupported(496) };
/* upstream parse.y:5127: f_larglist: f_largs */
f_larglist: f_largs { $$ = @builder.unsupported(497) };
/* upstream parse.y:5136: lambda_body: tLAMBEG compstmt_stmts '}' */
lambda_body: tLAMBEG compstmt_stmts '}' %prec '}' { $$ = @builder.unsupported(498) };
/* upstream parse.y:5142: $@28: %empty */
midrule_28: %empty { $$ = @builder.unsupported(499) };
/* upstream parse.y:5146: lambda_body: "'do' for lambda" $@28 bodystmt k_end */
lambda_body: keyword_do_LAMBDA midrule_28 bodystmt k_end %prec keyword_do_LAMBDA { $$ = @builder.unsupported(500) };
/* upstream parse.y:5153: do_block: k_do_block do_body k_end */
do_block: k_do_block do_body k_end { $$ = @builder.unsupported(501) };
/* upstream parse.y:5161: block_call: command do_block */
block_call: command do_block { $$ = @builder.unsupported(502) };
/* upstream parse.y:5167: block_call: block_call call_op2 operation2 opt_paren_args */
block_call: block_call call_op2 operation2 opt_paren_args { $$ = @builder.unsupported(503) };
/* upstream parse.y:5177: block_call: block_call call_op2 operation2 opt_paren_args brace_block */
block_call: block_call call_op2 operation2 opt_paren_args brace_block { $$ = @builder.unsupported(504) };
/* upstream parse.y:5183: block_call: block_call call_op2 operation2 command_args do_block */
block_call: block_call call_op2 operation2 command_args do_block { $$ = @builder.unsupported(505) };
/* upstream parse.y:5188: block_call: block_call call_op2 paren_args */
block_call: block_call call_op2 paren_args { $$ = @builder.unsupported(506) };
/* upstream parse.y:5196: method_call: fcall paren_args */
method_call: fcall paren_args { $$ = @builder.call($1, $2 || []) };
/* upstream parse.y:5203: method_call: primary_value call_op operation2 opt_paren_args */
method_call: primary_value call_op operation2 opt_paren_args { $$ = @builder.unsupported(508) };
/* upstream parse.y:5214: method_call: primary_value "::" operation2 paren_args */
method_call: primary_value tCOLON2 operation2 paren_args %prec tCOLON2 { $$ = @builder.unsupported(509) };
/* upstream parse.y:5220: method_call: primary_value "::" operation3 */
method_call: primary_value tCOLON2 operation3 %prec tCOLON2 { $$ = @builder.unsupported(510) };
/* upstream parse.y:5225: method_call: primary_value call_op2 paren_args */
method_call: primary_value call_op2 paren_args { $$ = @builder.unsupported(511) };
/* upstream parse.y:5231: method_call: "'super'" paren_args */
method_call: keyword_super paren_args %prec keyword_super { $$ = @builder.call(:super, $2 || []) };
/* upstream parse.y:5241: method_call: "'super'" */
method_call: keyword_super %prec keyword_super { $$ = @builder.call(:super, []) };
/* upstream parse.y:5246: method_call: primary_value '[' opt_call_args rbracket */
method_call: primary_value '[' opt_call_args rbracket %prec '[' { $$ = @builder.index($1, $3 || []) };
/* upstream parse.y:5254: brace_block: '{' brace_body '}' */
brace_block: '{' brace_body '}' %prec '}' { $$ = @builder.unsupported(515) };
/* upstream parse.y:5260: brace_block: k_do do_body k_end */
brace_block: k_do do_body k_end { $$ = @builder.unsupported(516) };
/* upstream parse.y:5267: @29: %empty */
midrule_29: %empty { $$ = @builder.unsupported(517) };
/* upstream parse.y:5270: brace_body: @29 max_numparam numparam it_id allow_exits opt_block_param_def compstmt_stmts */
brace_body: midrule_29 max_numparam numparam it_id allow_exits opt_block_param_def compstmt_stmts { $$ = @builder.unsupported(518) };
/* upstream parse.y:5284: @30: %empty */
midrule_30: %empty { $$ = @builder.unsupported(519) };
/* upstream parse.y:5290: do_body: @30 max_numparam numparam it_id allow_exits opt_block_param_def bodystmt */
do_body: midrule_30 max_numparam numparam it_id allow_exits opt_block_param_def bodystmt { $$ = @builder.unsupported(520) };
/* upstream parse.y:5306: case_args: arg_value */
case_args: arg_value { $$ = @builder.unsupported(521) };
/* upstream parse.y:5312: case_args: "*" arg_value */
case_args: tSTAR arg_value %prec tSTAR { $$ = @builder.unsupported(522) };
/* upstream parse.y:5317: case_args: case_args ',' arg_value */
case_args: case_args ',' arg_value %prec ',' { $$ = @builder.unsupported(523) };
/* upstream parse.y:5323: case_args: case_args ',' "*" arg_value */
case_args: case_args ',' tSTAR arg_value %prec tSTAR { $$ = @builder.unsupported(524) };
/* upstream parse.y:5332: case_body: k_when case_args then compstmt_stmts cases */
case_body: k_when case_args then compstmt_stmts cases { $$ = @builder.unsupported(525) };
/* upstream parse.y:5339: cases: opt_else */
cases: opt_else { $$ = @builder.unsupported(526) };
/* upstream parse.y:5340: cases: case_body */
cases: case_body { $$ = @builder.unsupported(527) };
/* upstream parse.y:5343: p_pvtbl: %empty */
p_pvtbl: %empty { $$ = @builder.unsupported(528) };
/* upstream parse.y:5344: p_pktbl: %empty */
p_pktbl: %empty { $$ = @builder.unsupported(529) };
/* upstream parse.y:5346: p_in_kwarg: %empty */
p_in_kwarg: %empty { $$ = @builder.unsupported(530) };
/* upstream parse.y:5359: $@31: %empty */
midrule_31: %empty { $$ = @builder.unsupported(531) };
/* upstream parse.y:5368: p_case_body: "'in'" p_in_kwarg p_pvtbl p_pktbl p_top_expr then $@31 compstmt_stmts p_cases */
p_case_body: keyword_in p_in_kwarg p_pvtbl p_pktbl p_top_expr then midrule_31 compstmt_stmts p_cases %prec keyword_in { $$ = @builder.unsupported(532) };
/* upstream parse.y:5374: p_cases: opt_else */
p_cases: opt_else { $$ = @builder.unsupported(533) };
/* upstream parse.y:5375: p_cases: p_case_body */
p_cases: p_case_body { $$ = @builder.unsupported(534) };
/* upstream parse.y:5378: p_top_expr: p_top_expr_body */
p_top_expr: p_top_expr_body { $$ = @builder.unsupported(535) };
/* upstream parse.y:5380: p_top_expr: p_top_expr_body "'if' modifier" expr_value */
p_top_expr: p_top_expr_body modifier_if expr_value %prec modifier_if { $$ = @builder.unsupported(536) };
/* upstream parse.y:5386: p_top_expr: p_top_expr_body "'unless' modifier" expr_value */
p_top_expr: p_top_expr_body modifier_unless expr_value %prec modifier_unless { $$ = @builder.unsupported(537) };
/* upstream parse.y:5393: p_top_expr_body: p_expr */
p_top_expr_body: p_expr { $$ = @builder.unsupported(538) };
/* upstream parse.y:5395: p_top_expr_body: p_expr ',' */
p_top_expr_body: p_expr ',' %prec ',' { $$ = @builder.unsupported(539) };
/* upstream parse.y:5401: p_top_expr_body: p_expr ',' p_args */
p_top_expr_body: p_expr ',' p_args %prec ',' { $$ = @builder.unsupported(540) };
/* upstream parse.y:5407: p_top_expr_body: p_find */
p_top_expr_body: p_find { $$ = @builder.unsupported(541) };
/* upstream parse.y:5412: p_top_expr_body: p_args_tail */
p_top_expr_body: p_args_tail { $$ = @builder.unsupported(542) };
/* upstream parse.y:5417: p_top_expr_body: p_kwargs */
p_top_expr_body: p_kwargs { $$ = @builder.unsupported(543) };
/* upstream parse.y:5423: p_expr: p_as */
p_expr: p_as { $$ = @builder.unsupported(544) };
/* upstream parse.y:5427: p_as: p_expr "=>" p_variable */
p_as: p_expr tASSOC p_variable %prec tASSOC { $$ = @builder.unsupported(545) };
/* upstream parse.y:5433: p_as: p_alt */
p_as: p_alt { $$ = @builder.unsupported(546) };
/* upstream parse.y:5437: $@32: %empty */
midrule_32: %empty { $$ = @builder.unsupported(547) };
/* upstream parse.y:5441: p_alt: p_alt '|' $@32 p_expr_basic */
p_alt: p_alt '|' midrule_32 p_expr_basic %prec '|' { $$ = @builder.unsupported(548) };
/* upstream parse.y:5449: p_alt: p_expr_basic */
p_alt: p_expr_basic { $$ = @builder.unsupported(549) };
/* upstream parse.y:5453: p_lparen: '(' p_pktbl */
p_lparen: '(' p_pktbl %prec '(' { $$ = @builder.unsupported(550) };
/* upstream parse.y:5460: p_lbracket: '[' p_pktbl */
p_lbracket: '[' p_pktbl %prec '[' { $$ = @builder.unsupported(551) };
/* upstream parse.y:5466: p_expr_basic: p_value */
p_expr_basic: p_value { $$ = @builder.unsupported(552) };
/* upstream parse.y:5467: p_expr_basic: p_variable */
p_expr_basic: p_variable { $$ = @builder.unsupported(553) };
/* upstream parse.y:5469: p_expr_basic: p_const p_lparen p_args rparen */
p_expr_basic: p_const p_lparen p_args rparen { $$ = @builder.unsupported(554) };
/* upstream parse.y:5476: p_expr_basic: p_const p_lparen p_find rparen */
p_expr_basic: p_const p_lparen p_find rparen { $$ = @builder.unsupported(555) };
/* upstream parse.y:5483: p_expr_basic: p_const p_lparen p_kwargs rparen */
p_expr_basic: p_const p_lparen p_kwargs rparen { $$ = @builder.unsupported(556) };
/* upstream parse.y:5490: p_expr_basic: p_const '(' rparen */
p_expr_basic: p_const '(' rparen %prec '(' { $$ = @builder.unsupported(557) };
/* upstream parse.y:5496: p_expr_basic: p_const p_lbracket p_args rbracket */
p_expr_basic: p_const p_lbracket p_args rbracket { $$ = @builder.unsupported(558) };
/* upstream parse.y:5503: p_expr_basic: p_const p_lbracket p_find rbracket */
p_expr_basic: p_const p_lbracket p_find rbracket { $$ = @builder.unsupported(559) };
/* upstream parse.y:5510: p_expr_basic: p_const p_lbracket p_kwargs rbracket */
p_expr_basic: p_const p_lbracket p_kwargs rbracket { $$ = @builder.unsupported(560) };
/* upstream parse.y:5517: p_expr_basic: p_const '[' rbracket */
p_expr_basic: p_const '[' rbracket %prec '[' { $$ = @builder.unsupported(561) };
/* upstream parse.y:5523: p_expr_basic: "[" p_args rbracket */
p_expr_basic: tLBRACK p_args rbracket %prec tLBRACK { $$ = @builder.unsupported(562) };
/* upstream parse.y:5528: p_expr_basic: "[" p_find rbracket */
p_expr_basic: tLBRACK p_find rbracket %prec tLBRACK { $$ = @builder.unsupported(563) };
/* upstream parse.y:5533: p_expr_basic: "[" rbracket */
p_expr_basic: tLBRACK rbracket %prec tLBRACK { $$ = @builder.unsupported(564) };
/* upstream parse.y:5539: $@33: %empty */
midrule_33: %empty { $$ = @builder.unsupported(565) };
/* upstream parse.y:5543: p_expr_basic: "{" p_pktbl lex_ctxt $@33 p_kwargs rbrace */
p_expr_basic: tLBRACE p_pktbl lex_ctxt midrule_33 p_kwargs rbrace %prec tLBRACE { $$ = @builder.unsupported(566) };
/* upstream parse.y:5550: p_expr_basic: "{" rbrace */
p_expr_basic: tLBRACE rbrace %prec tLBRACE { $$ = @builder.unsupported(567) };
/* upstream parse.y:5556: p_expr_basic: "(" p_pktbl p_expr rparen */
p_expr_basic: tLPAREN p_pktbl p_expr rparen %prec tLPAREN { $$ = @builder.unsupported(568) };
/* upstream parse.y:5564: p_args: p_expr */
p_args: p_expr { $$ = @builder.unsupported(569) };
/* upstream parse.y:5570: p_args: p_args_head */
p_args: p_args_head { $$ = @builder.unsupported(570) };
/* upstream parse.y:5575: p_args: p_args_head p_arg */
p_args: p_args_head p_arg { $$ = @builder.unsupported(571) };
/* upstream parse.y:5580: p_args: p_args_head p_rest */
p_args: p_args_head p_rest { $$ = @builder.unsupported(572) };
/* upstream parse.y:5585: p_args: p_args_head p_rest ',' p_args_post */
p_args: p_args_head p_rest ',' p_args_post %prec ',' { $$ = @builder.unsupported(573) };
/* upstream parse.y:5589: p_args: p_args_tail */
p_args: p_args_tail { $$ = @builder.unsupported(574) };
/* upstream parse.y:5592: p_args_head: p_arg ',' */
p_args_head: p_arg ',' %prec ',' { $$ = @builder.unsupported(575) };
/* upstream parse.y:5594: p_args_head: p_args_head p_arg ',' */
p_args_head: p_args_head p_arg ',' %prec ',' { $$ = @builder.unsupported(576) };
/* upstream parse.y:5601: p_args_tail: p_rest */
p_args_tail: p_rest { $$ = @builder.unsupported(577) };
/* upstream parse.y:5606: p_args_tail: p_rest ',' p_args_post */
p_args_tail: p_rest ',' p_args_post %prec ',' { $$ = @builder.unsupported(578) };
/* upstream parse.y:5613: p_find: p_rest ',' p_args_post ',' p_rest */
p_find: p_rest ',' p_args_post ',' p_rest %prec ',' { $$ = @builder.unsupported(579) };
/* upstream parse.y:5621: p_rest: "*" "local variable or method" */
p_rest: tSTAR tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(580) };
/* upstream parse.y:5627: p_rest: "*" */
p_rest: tSTAR %prec tSTAR { $$ = @builder.unsupported(581) };
/* upstream parse.y:5633: p_args_post: p_arg */
p_args_post: p_arg { $$ = @builder.unsupported(582) };
/* upstream parse.y:5635: p_args_post: p_args_post ',' p_arg */
p_args_post: p_args_post ',' p_arg %prec ',' { $$ = @builder.unsupported(583) };
/* upstream parse.y:5642: p_arg: p_expr */
p_arg: p_expr { $$ = @builder.unsupported(584) };
/* upstream parse.y:5649: p_kwargs: p_kwarg ',' p_any_kwrest */
p_kwargs: p_kwarg ',' p_any_kwrest %prec ',' { $$ = @builder.unsupported(585) };
/* upstream parse.y:5654: p_kwargs: p_kwarg */
p_kwargs: p_kwarg { $$ = @builder.unsupported(586) };
/* upstream parse.y:5659: p_kwargs: p_kwarg ',' */
p_kwargs: p_kwarg ',' %prec ',' { $$ = @builder.unsupported(587) };
/* upstream parse.y:5664: p_kwargs: p_any_kwrest */
p_kwargs: p_any_kwrest { $$ = @builder.unsupported(588) };
/* upstream parse.y:5670: p_kwarg: p_kw */
p_kwarg: p_kw { $$ = @builder.unsupported(589) };
/* upstream parse.y:5673: p_kwarg: p_kwarg ',' p_kw */
p_kwarg: p_kwarg ',' p_kw %prec ',' { $$ = @builder.unsupported(590) };
/* upstream parse.y:5680: p_kw: p_kw_label p_expr */
p_kw: p_kw_label p_expr { $$ = @builder.unsupported(591) };
/* upstream parse.y:5686: p_kw: p_kw_label */
p_kw: p_kw_label { $$ = @builder.unsupported(592) };
/* upstream parse.y:5697: p_kw_label: "label" */
p_kw_label: tLABEL %prec tLABEL { $$ = @builder.unsupported(593) };
/* upstream parse.y:5699: p_kw_label: "string literal" string_contents tLABEL_END */
p_kw_label: tSTRING_BEG string_contents tLABEL_END %prec tLABEL_END { $$ = @builder.unsupported(594) };
/* upstream parse.y:5714: p_kwrest: kwrest_mark "local variable or method" */
p_kwrest: kwrest_mark tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(595) };
/* upstream parse.y:5719: p_kwrest: kwrest_mark */
p_kwrest: kwrest_mark { $$ = @builder.unsupported(596) };
/* upstream parse.y:5726: p_kwnorest: kwrest_mark "'nil'" */
p_kwnorest: kwrest_mark keyword_nil %prec keyword_nil { $$ = @builder.unsupported(597) };
/* upstream parse.y:5731: p_any_kwrest: p_kwrest */
p_any_kwrest: p_kwrest { $$ = @builder.unsupported(598) };
/* upstream parse.y:5733: p_any_kwrest: p_kwnorest */
p_any_kwrest: p_kwnorest { $$ = @builder.unsupported(599) };
/* upstream parse.y:5739: p_value: p_primitive */
p_value: p_primitive { $$ = @builder.unsupported(600) };
/* upstream parse.y:3120: range_expr_p_primitive: p_primitive ".." p_primitive */
range_expr_p_primitive: p_primitive tDOT2 p_primitive %prec tDOT2 { $$ = @builder.unsupported(601) };
/* upstream parse.y:3127: range_expr_p_primitive: p_primitive "..." p_primitive */
range_expr_p_primitive: p_primitive tDOT3 p_primitive %prec tDOT3 { $$ = @builder.unsupported(602) };
/* upstream parse.y:3134: range_expr_p_primitive: p_primitive ".." */
range_expr_p_primitive: p_primitive tDOT2 %prec tDOT2 { $$ = @builder.unsupported(603) };
/* upstream parse.y:3140: range_expr_p_primitive: p_primitive "..." */
range_expr_p_primitive: p_primitive tDOT3 %prec tDOT3 { $$ = @builder.unsupported(604) };
/* upstream parse.y:3146: range_expr_p_primitive: "(.." p_primitive */
range_expr_p_primitive: tBDOT2 p_primitive %prec tBDOT2 { $$ = @builder.unsupported(605) };
/* upstream parse.y:3152: range_expr_p_primitive: "(..." p_primitive */
range_expr_p_primitive: tBDOT3 p_primitive %prec tBDOT3 { $$ = @builder.unsupported(606) };
/* upstream parse.y:5740: p_value: range_expr_p_primitive */
p_value: range_expr_p_primitive { $$ = @builder.unsupported(607) };
/* upstream parse.y:5741: p_value: p_var_ref */
p_value: p_var_ref { $$ = @builder.unsupported(608) };
/* upstream parse.y:5742: p_value: p_expr_ref */
p_value: p_expr_ref { $$ = @builder.unsupported(609) };
/* upstream parse.y:5743: p_value: p_const */
p_value: p_const { $$ = @builder.unsupported(610) };
/* upstream parse.y:5746: p_primitive: literal */
p_primitive: literal { $$ = @builder.unsupported(611) };
/* upstream parse.y:5746: p_primitive: strings */
p_primitive: strings { $$ = @builder.unsupported(612) };
/* upstream parse.y:5746: p_primitive: xstring */
p_primitive: xstring { $$ = @builder.unsupported(613) };
/* upstream parse.y:5746: p_primitive: regexp */
p_primitive: regexp { $$ = @builder.unsupported(614) };
/* upstream parse.y:5746: p_primitive: words */
p_primitive: words { $$ = @builder.unsupported(615) };
/* upstream parse.y:5746: p_primitive: qwords */
p_primitive: qwords { $$ = @builder.unsupported(616) };
/* upstream parse.y:5746: p_primitive: symbols */
p_primitive: symbols { $$ = @builder.unsupported(617) };
/* upstream parse.y:5746: p_primitive: qsymbols */
p_primitive: qsymbols { $$ = @builder.unsupported(618) };
/* upstream parse.y:5748: p_primitive: keyword_variable */
p_primitive: keyword_variable { $$ = @builder.unsupported(619) };
/* upstream parse.y:5752: p_primitive: lambda */
p_primitive: lambda { $$ = @builder.unsupported(620) };
/* upstream parse.y:5756: p_variable: "local variable or method" */
p_variable: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(621) };
/* upstream parse.y:5764: p_var_ref: '^' "local variable or method" */
p_var_ref: '^' tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(622) };
/* upstream parse.y:5776: p_var_ref: '^' nonlocal_var */
p_var_ref: '^' nonlocal_var %prec '^' { $$ = @builder.unsupported(623) };
/* upstream parse.y:5783: p_expr_ref: '^' "(" expr_value rparen */
p_expr_ref: '^' tLPAREN expr_value rparen %prec tLPAREN { $$ = @builder.unsupported(624) };
/* upstream parse.y:5790: p_const: ":: at EXPR_BEG" cname */
p_const: tCOLON3 cname %prec tCOLON3 { $$ = @builder.unsupported(625) };
/* upstream parse.y:5795: p_const: p_const "::" cname */
p_const: p_const tCOLON2 cname %prec tCOLON2 { $$ = @builder.unsupported(626) };
/* upstream parse.y:5800: p_const: "constant" */
p_const: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(627) };
/* upstream parse.y:5809: opt_rescue: k_rescue exc_list exc_var then compstmt_stmts opt_rescue */
opt_rescue: k_rescue exc_list exc_var then compstmt_stmts opt_rescue { $$ = @builder.unsupported(628) };
/* upstream parse.y:5827: opt_rescue: none */
opt_rescue: none { $$ = @builder.unsupported(629) };
/* upstream parse.y:5831: exc_list: arg_value */
exc_list: arg_value { $$ = @builder.unsupported(630) };
/* upstream parse.y:5836: exc_list: mrhs */
exc_list: mrhs { $$ = @builder.unsupported(631) };
/* upstream parse.y:5839: exc_list: none */
exc_list: none { $$ = @builder.unsupported(632) };
/* upstream parse.y:5843: exc_var: "=>" lhs */
exc_var: tASSOC lhs %prec tASSOC { $$ = @builder.unsupported(633) };
/* upstream parse.y:5847: exc_var: none */
exc_var: none { $$ = @builder.unsupported(634) };
/* upstream parse.y:5851: opt_ensure: k_ensure stmts option_terms */
opt_ensure: k_ensure stmts option_terms { $$ = @builder.unsupported(635) };
/* upstream parse.y:5857: opt_ensure: none */
opt_ensure: none { $$ = @builder.unsupported(636) };
/* upstream parse.y:5860: literal: numeric */
literal: numeric { $$ = $1 };
/* upstream parse.y:5861: literal: symbol */
literal: symbol { $$ = $1 };
/* upstream parse.y:5865: strings: string */
strings: string { $$ = $1 };
/* upstream parse.y:5876: string: "char literal" */
string: tCHAR %prec tCHAR { $$ = @builder.literal($1) };
/* upstream parse.y:5877: string: string1 */
string: string1 { $$ = $1 };
/* upstream parse.y:5879: string: string string1 */
string: string string1 { $$ = @builder.concat_strings($1, $2) };
/* upstream parse.y:5886: string1: "string literal" string_contents "terminator" */
string1: tSTRING_BEG string_contents tSTRING_END %prec tSTRING_END { $$ = @builder.string(@builder.join_strings($2)) };
/* upstream parse.y:5899: xstring: "backtick literal" xstring_contents "terminator" */
xstring: tXSTRING_BEG xstring_contents tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(644) };
/* upstream parse.y:5911: regexp: "regexp literal" regexp_contents tREGEXP_END */
regexp: tREGEXP_BEG regexp_contents tREGEXP_END %prec tREGEXP_END { $$ = @builder.unsupported(645) };
/* upstream parse.y:5917: nonempty_list_' ': ' ' */
nonempty_list____: ' ' %prec ' ' { $$ = @builder.unsupported(646) };
/* upstream parse.y:5917: nonempty_list_' ': nonempty_list_' ' ' ' */
nonempty_list____: nonempty_list____ ' ' %prec ' ' { $$ = @builder.unsupported(647) };
/* upstream parse.y:3169: words_tWORDS_BEG_word_list: "word list" nonempty_list_' ' word_list "terminator" */
words_tWORDS_BEG_word_list: tWORDS_BEG nonempty_list____ word_list tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(648) };
/* upstream parse.y:5917: words: words_tWORDS_BEG_word_list */
words: words_tWORDS_BEG_word_list { $$ = @builder.unsupported(649) };
/* upstream parse.y:5921: word_list: %empty */
word_list: %empty { $$ = @builder.unsupported(650) };
/* upstream parse.y:5926: word_list: word_list word nonempty_list_' ' */
word_list: word_list word nonempty_list____ { $$ = @builder.unsupported(651) };
/* upstream parse.y:5932: word: string_content */
word: string_content { $$ = @builder.unsupported(652) };
/* upstream parse.y:5935: word: word string_content */
word: word string_content { $$ = @builder.unsupported(653) };
/* upstream parse.y:3169: words_tSYMBOLS_BEG_symbol_list: "symbol list" nonempty_list_' ' symbol_list "terminator" */
words_tSYMBOLS_BEG_symbol_list: tSYMBOLS_BEG nonempty_list____ symbol_list tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(654) };
/* upstream parse.y:5941: symbols: words_tSYMBOLS_BEG_symbol_list */
symbols: words_tSYMBOLS_BEG_symbol_list { $$ = @builder.unsupported(655) };
/* upstream parse.y:5945: symbol_list: %empty */
symbol_list: %empty { $$ = @builder.unsupported(656) };
/* upstream parse.y:5950: symbol_list: symbol_list word nonempty_list_' ' */
symbol_list: symbol_list word nonempty_list____ { $$ = @builder.unsupported(657) };
/* upstream parse.y:3169: words_tQWORDS_BEG_qword_list: "verbatim word list" nonempty_list_' ' qword_list "terminator" */
words_tQWORDS_BEG_qword_list: tQWORDS_BEG nonempty_list____ qword_list tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(658) };
/* upstream parse.y:5956: qwords: words_tQWORDS_BEG_qword_list */
qwords: words_tQWORDS_BEG_qword_list { $$ = @builder.unsupported(659) };
/* upstream parse.y:3169: words_tQSYMBOLS_BEG_qsym_list: "verbatim symbol list" nonempty_list_' ' qsym_list "terminator" */
words_tQSYMBOLS_BEG_qsym_list: tQSYMBOLS_BEG nonempty_list____ qsym_list tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(660) };
/* upstream parse.y:5959: qsymbols: words_tQSYMBOLS_BEG_qsym_list */
qsymbols: words_tQSYMBOLS_BEG_qsym_list { $$ = @builder.unsupported(661) };
/* upstream parse.y:5963: qword_list: %empty */
qword_list: %empty { $$ = @builder.unsupported(662) };
/* upstream parse.y:5968: qword_list: qword_list "literal content" nonempty_list_' ' */
qword_list: qword_list tSTRING_CONTENT nonempty_list____ %prec tSTRING_CONTENT { $$ = @builder.unsupported(663) };
/* upstream parse.y:5975: qsym_list: %empty */
qsym_list: %empty { $$ = @builder.unsupported(664) };
/* upstream parse.y:5980: qsym_list: qsym_list "literal content" nonempty_list_' ' */
qsym_list: qsym_list tSTRING_CONTENT nonempty_list____ %prec tSTRING_CONTENT { $$ = @builder.unsupported(665) };
/* upstream parse.y:5987: string_contents: %empty */
string_contents: %empty { $$ = [] };
/* upstream parse.y:5992: string_contents: string_contents string_content */
string_contents: string_contents string_content { $$ = ($1 + [$2]).freeze };
/* upstream parse.y:5999: xstring_contents: %empty */
xstring_contents: %empty { $$ = @builder.unsupported(668) };
/* upstream parse.y:6004: xstring_contents: xstring_contents string_content */
xstring_contents: xstring_contents string_content { $$ = @builder.unsupported(669) };
/* upstream parse.y:6011: regexp_contents: %empty */
regexp_contents: %empty { $$ = @builder.unsupported(670) };
/* upstream parse.y:6016: regexp_contents: regexp_contents string_content */
regexp_contents: regexp_contents string_content { $$ = @builder.unsupported(671) };
/* upstream parse.y:6041: string_content: "literal content" */
string_content: tSTRING_CONTENT %prec tSTRING_CONTENT { $$ = $1 };
/* upstream parse.y:6044: @34: %empty */
midrule_34: %empty { $$ = @builder.unsupported(673) };
/* upstream parse.y:6051: string_content: tSTRING_DVAR @34 string_dvar */
string_content: tSTRING_DVAR midrule_34 string_dvar %prec tSTRING_DVAR { $$ = @builder.unsupported(674) };
/* upstream parse.y:6058: @35: %empty */
midrule_35: %empty { $$ = @builder.unsupported(675) };
/* upstream parse.y:6066: @36: %empty */
midrule_36: %empty { $$ = @builder.unsupported(676) };
/* upstream parse.y:6070: @37: %empty */
midrule_37: %empty { $$ = @builder.unsupported(677) };
/* upstream parse.y:6074: @38: %empty */
midrule_38: %empty { $$ = @builder.unsupported(678) };
/* upstream parse.y:6079: string_content: "'#{'" @35 @36 @37 @38 compstmt_stmts string_dend */
string_content: tSTRING_DBEG midrule_35 midrule_36 midrule_37 midrule_38 compstmt_stmts string_dend %prec tSTRING_DBEG { $$ = @builder.unsupported(679) };
/* upstream parse.y:6094: string_dend: "'}'" */
string_dend: tSTRING_DEND %prec tSTRING_DEND { $$ = @builder.unsupported(680) };
/* upstream parse.y:6095: string_dend: "end-of-input" */
string_dend: END_OF_INPUT %prec END_OF_INPUT { $$ = @builder.unsupported(681) };
/* upstream parse.y:6099: string_dvar: nonlocal_var */
string_dvar: nonlocal_var { $$ = @builder.unsupported(682) };
/* upstream parse.y:6103: string_dvar: backref */
string_dvar: backref { $$ = @builder.unsupported(683) };
/* upstream parse.y:6106: symbol: ssym */
symbol: ssym { $$ = $1 };
/* upstream parse.y:6107: symbol: dsym */
symbol: dsym { $$ = $1 };
/* upstream parse.y:6111: ssym: "symbol literal" sym */
ssym: tSYMBEG sym %prec tSYMBEG { $$ = @builder.symbol($2) };
/* upstream parse.y:6126: sym: fname */
sym: fname { $$ = $1 };
/* upstream parse.y:6127: sym: nonlocal_var */
sym: nonlocal_var { $$ = $1 };
/* upstream parse.y:6131: dsym: "symbol literal" string_contents "terminator" */
dsym: tSYMBEG string_contents tSTRING_END %prec tSTRING_END { $$ = @builder.unsupported(689) };
/* upstream parse.y:6138: numeric: simple_numeric */
numeric: simple_numeric { $$ = $1 };
/* upstream parse.y:6140: numeric: tUMINUS_NUM simple_numeric */
numeric: tUMINUS_NUM simple_numeric %prec tLOWEST { $$ = @builder.unary(:-, $2) };
/* upstream parse.y:6147: simple_numeric: "integer literal" */
simple_numeric: tINTEGER %prec tINTEGER { $$ = @builder.integer($1) };
/* upstream parse.y:6148: simple_numeric: "float literal" */
simple_numeric: tFLOAT %prec tFLOAT { $$ = @builder.float($1) };
/* upstream parse.y:6149: simple_numeric: "rational literal" */
simple_numeric: tRATIONAL %prec tRATIONAL { $$ = @builder.literal($1) };
/* upstream parse.y:6150: simple_numeric: "imaginary literal" */
simple_numeric: tIMAGINARY %prec tIMAGINARY { $$ = @builder.literal($1) };
/* upstream parse.y:6153: nonlocal_var: "instance variable" */
nonlocal_var: tIVAR %prec tIVAR { $$ = @builder.variable(:instance, $1) };
/* upstream parse.y:6154: nonlocal_var: "global variable" */
nonlocal_var: tGVAR %prec tGVAR { $$ = @builder.variable(:global, $1) };
/* upstream parse.y:6155: nonlocal_var: "class variable" */
nonlocal_var: tCVAR %prec tCVAR { $$ = @builder.variable(:class, $1) };
/* upstream parse.y:6158: user_variable: "local variable or method" */
user_variable: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.identifier($1) };
/* upstream parse.y:6158: user_variable: "constant" */
user_variable: tCONSTANT %prec tCONSTANT { $$ = @builder.variable(:constant, $1) };
/* upstream parse.y:6159: user_variable: nonlocal_var */
user_variable: nonlocal_var { $$ = $1 };
/* upstream parse.y:6162: keyword_variable: "'nil'" */
keyword_variable: keyword_nil %prec keyword_nil { $$ = @builder.literal(nil) };
/* upstream parse.y:6163: keyword_variable: "'self'" */
keyword_variable: keyword_self %prec keyword_self { $$ = @builder.literal(:self) };
/* upstream parse.y:6164: keyword_variable: "'true'" */
keyword_variable: keyword_true %prec keyword_true { $$ = @builder.literal(true) };
/* upstream parse.y:6165: keyword_variable: "'false'" */
keyword_variable: keyword_false %prec keyword_false { $$ = @builder.literal(false) };
/* upstream parse.y:6166: keyword_variable: "'__FILE__'" */
keyword_variable: keyword__FILE__ %prec keyword__FILE__ { $$ = @builder.literal(:__FILE__) };
/* upstream parse.y:6167: keyword_variable: "'__LINE__'" */
keyword_variable: keyword__LINE__ %prec keyword__LINE__ { $$ = @builder.literal(:__LINE__) };
/* upstream parse.y:6168: keyword_variable: "'__ENCODING__'" */
keyword_variable: keyword__ENCODING__ %prec keyword__ENCODING__ { $$ = @builder.literal(:__ENCODING__) };
/* upstream parse.y:6172: var_ref: user_variable */
var_ref: user_variable { $$ = @builder.read_local($1) };
/* upstream parse.y:6182: var_ref: keyword_variable */
var_ref: keyword_variable { $$ = $1 };
/* upstream parse.y:6189: var_lhs: user_variable */
var_lhs: user_variable { $$ = @builder.unsupported(711) };
/* upstream parse.y:6189: var_lhs: keyword_variable */
var_lhs: keyword_variable { $$ = @builder.unsupported(712) };
/* upstream parse.y:6195: backref: "numbered reference" */
backref: tNTH_REF %prec tNTH_REF { $$ = @builder.variable(:backref, $1) };
/* upstream parse.y:6196: backref: "back reference" */
backref: tBACK_REF %prec tBACK_REF { $$ = @builder.variable(:backref, $1) };
/* upstream parse.y:6200: $@39: %empty */
midrule_39: %empty { $$ = @builder.unsupported(715) };
/* upstream parse.y:6205: superclass: '<' $@39 expr_value term */
superclass: '<' midrule_39 expr_value term %prec '<' { $$ = @builder.unsupported(716) };
/* upstream parse.y:6209: superclass: none */
superclass: none { $$ = @builder.unsupported(717) };
/* upstream parse.y:6212: f_opt_paren_args: f_paren_args */
f_opt_paren_args: f_paren_args { $$ = @builder.unsupported(718) };
/* upstream parse.y:6214: f_opt_paren_args: f_empty_arg */
f_opt_paren_args: f_empty_arg { $$ = @builder.unsupported(719) };
/* upstream parse.y:6220: f_empty_arg: %empty */
f_empty_arg: %empty { $$ = @builder.unsupported(720) };
/* upstream parse.y:6228: f_paren_args: '(' f_args rparen */
f_paren_args: '(' f_args rparen %prec '(' { $$ = @builder.unsupported(721) };
/* upstream parse.y:6237: f_arglist: f_paren_args */
f_arglist: f_paren_args { $$ = @builder.unsupported(722) };
/* upstream parse.y:6238: @40: %empty */
midrule_40: %empty { $$ = @builder.unsupported(723) };
/* upstream parse.y:6245: f_arglist: @40 f_args term */
f_arglist: midrule_40 f_args term { $$ = @builder.unsupported(724) };
/* upstream parse.y:3020: f_kw_arg_value: f_label arg_value */
f_kw_arg_value: f_label arg_value { $$ = @builder.unsupported(725) };
/* upstream parse.y:3026: f_kw_arg_value: f_label */
f_kw_arg_value: f_label { $$ = @builder.unsupported(726) };
/* upstream parse.y:3035: f_kwarg_arg_value: f_kw_arg_value */
f_kwarg_arg_value: f_kw_arg_value { $$ = @builder.unsupported(727) };
/* upstream parse.y:3040: f_kwarg_arg_value: f_kwarg_arg_value ',' f_kw_arg_value */
f_kwarg_arg_value: f_kwarg_arg_value ',' f_kw_arg_value %prec ',' { $$ = @builder.unsupported(728) };
/* upstream parse.y:2957: opt_f_block_arg_opt_comma: ',' f_block_arg */
opt_f_block_arg_opt_comma: ',' f_block_arg %prec ',' { $$ = @builder.unsupported(729) };
/* upstream parse.y:6255: opt_f_block_arg_opt_comma: opt_comma */
opt_f_block_arg_opt_comma: opt_comma { $$ = @builder.unsupported(730) };
/* upstream parse.y:2934: args_tail_basic_arg_value_opt_comma: f_kwarg_arg_value ',' f_kwrest opt_f_block_arg_opt_comma */
args_tail_basic_arg_value_opt_comma: f_kwarg_arg_value ',' f_kwrest opt_f_block_arg_opt_comma %prec ',' { $$ = @builder.unsupported(731) };
/* upstream parse.y:2939: args_tail_basic_arg_value_opt_comma: f_kwarg_arg_value opt_f_block_arg_opt_comma */
args_tail_basic_arg_value_opt_comma: f_kwarg_arg_value opt_f_block_arg_opt_comma { $$ = @builder.unsupported(732) };
/* upstream parse.y:2944: args_tail_basic_arg_value_opt_comma: f_any_kwrest opt_f_block_arg_opt_comma */
args_tail_basic_arg_value_opt_comma: f_any_kwrest opt_f_block_arg_opt_comma { $$ = @builder.unsupported(733) };
/* upstream parse.y:2949: args_tail_basic_arg_value_opt_comma: f_block_arg */
args_tail_basic_arg_value_opt_comma: f_block_arg { $$ = @builder.unsupported(734) };
/* upstream parse.y:6255: args_tail: args_tail_basic_arg_value_opt_comma */
args_tail: args_tail_basic_arg_value_opt_comma { $$ = @builder.unsupported(735) };
/* upstream parse.y:6257: args_tail: args_forward */
args_tail: args_forward { $$ = @builder.unsupported(736) };
/* upstream parse.y:2934: args_tail_basic_arg_value_none: f_kwarg_arg_value ',' f_kwrest opt_f_block_arg_none */
args_tail_basic_arg_value_none: f_kwarg_arg_value ',' f_kwrest opt_f_block_arg_none %prec ',' { $$ = @builder.unsupported(737) };
/* upstream parse.y:2939: args_tail_basic_arg_value_none: f_kwarg_arg_value opt_f_block_arg_none */
args_tail_basic_arg_value_none: f_kwarg_arg_value opt_f_block_arg_none { $$ = @builder.unsupported(738) };
/* upstream parse.y:2944: args_tail_basic_arg_value_none: f_any_kwrest opt_f_block_arg_none */
args_tail_basic_arg_value_none: f_any_kwrest opt_f_block_arg_none { $$ = @builder.unsupported(739) };
/* upstream parse.y:2949: args_tail_basic_arg_value_none: f_block_arg */
args_tail_basic_arg_value_none: f_block_arg { $$ = @builder.unsupported(740) };
/* upstream parse.y:6265: largs_tail: args_tail_basic_arg_value_none */
largs_tail: args_tail_basic_arg_value_none { $$ = @builder.unsupported(741) };
/* upstream parse.y:6267: largs_tail: args_forward */
largs_tail: args_forward { $$ = @builder.unsupported(742) };
/* upstream parse.y:2998: f_opt_arg_value: f_arg_asgn f_eq arg_value */
f_opt_arg_value: f_arg_asgn f_eq arg_value { $$ = @builder.unsupported(743) };
/* upstream parse.y:3007: f_opt_arg_arg_value: f_opt_arg_value */
f_opt_arg_arg_value: f_opt_arg_value { $$ = @builder.unsupported(744) };
/* upstream parse.y:3012: f_opt_arg_arg_value: f_opt_arg_arg_value ',' f_opt_arg_value */
f_opt_arg_arg_value: f_opt_arg_arg_value ',' f_opt_arg_value %prec ',' { $$ = @builder.unsupported(745) };
/* upstream parse.y:3107: opt_args_tail_args_tail_opt_comma: ',' args_tail */
opt_args_tail_args_tail_opt_comma: ',' args_tail %prec ',' { $$ = @builder.unsupported(746) };
/* upstream parse.y:3112: opt_args_tail_args_tail_opt_comma: opt_comma */
opt_args_tail_args_tail_opt_comma: opt_comma { $$ = @builder.unsupported(747) };
/* upstream parse.y:6277: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(748) };
/* upstream parse.y:6282: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(749) };
/* upstream parse.y:6287: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(750) };
/* upstream parse.y:6292: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_opt_arg_arg_value ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(751) };
/* upstream parse.y:6297: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_rest_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_rest_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(752) };
/* upstream parse.y:6302: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(753) };
/* upstream parse.y:6307: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(754) };
/* upstream parse.y:6312: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(755) };
/* upstream parse.y:6317: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value opt_args_tail_args_tail_opt_comma { $$ = @builder.unsupported(756) };
/* upstream parse.y:6322: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_opt_arg_arg_value ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(757) };
/* upstream parse.y:6327: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_rest_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_rest_arg opt_args_tail_args_tail_opt_comma { $$ = @builder.unsupported(758) };
/* upstream parse.y:6332: args-list_arg_value_opt_args_tail_args_tail_opt_comma: f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma */
args_list_arg_value_opt_args_tail_args_tail_opt_comma: f_rest_arg ',' f_arg opt_args_tail_args_tail_opt_comma %prec ',' { $$ = @builder.unsupported(759) };
/* upstream parse.y:6357: f_args-list_args_tail_opt_comma: args-list_arg_value_opt_args_tail_args_tail_opt_comma */
f_args_list_args_tail_opt_comma: args_list_arg_value_opt_args_tail_args_tail_opt_comma { $$ = @builder.unsupported(760) };
/* upstream parse.y:6349: f_args-list_args_tail_opt_comma: f_arg opt_args_tail_args_tail_opt_comma */
f_args_list_args_tail_opt_comma: f_arg opt_args_tail_args_tail_opt_comma { $$ = @builder.unsupported(761) };
/* upstream parse.y:6340: tail-only-args_args_tail: args_tail */
tail_only_args_args_tail: args_tail { $$ = @builder.unsupported(762) };
/* upstream parse.y:6357: f_args-list_args_tail_opt_comma: tail-only-args_args_tail */
f_args_list_args_tail_opt_comma: tail_only_args_args_tail { $$ = @builder.unsupported(763) };
/* upstream parse.y:6357: f_args-list_args_tail_opt_comma: f_empty_arg */
f_args_list_args_tail_opt_comma: f_empty_arg { $$ = @builder.unsupported(764) };
/* upstream parse.y:6357: f_args: f_args-list_args_tail_opt_comma */
f_args: f_args_list_args_tail_opt_comma { $$ = @builder.unsupported(765) };
/* upstream parse.y:3107: opt_args_tail_largs_tail_none: ',' largs_tail */
opt_args_tail_largs_tail_none: ',' largs_tail %prec ',' { $$ = @builder.unsupported(766) };
/* upstream parse.y:3112: opt_args_tail_largs_tail_none: none */
opt_args_tail_largs_tail_none: none { $$ = @builder.unsupported(767) };
/* upstream parse.y:6277: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(768) };
/* upstream parse.y:6282: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(769) };
/* upstream parse.y:6287: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(770) };
/* upstream parse.y:6292: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_opt_arg_arg_value ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(771) };
/* upstream parse.y:6297: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_rest_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_rest_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(772) };
/* upstream parse.y:6302: args-list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_arg ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(773) };
/* upstream parse.y:6307: args-list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_rest_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(774) };
/* upstream parse.y:6312: args-list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_rest_arg ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(775) };
/* upstream parse.y:6317: args-list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value opt_args_tail_largs_tail_none { $$ = @builder.unsupported(776) };
/* upstream parse.y:6322: args-list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_opt_arg_arg_value ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(777) };
/* upstream parse.y:6327: args-list_arg_value_opt_args_tail_largs_tail_none: f_rest_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_rest_arg opt_args_tail_largs_tail_none { $$ = @builder.unsupported(778) };
/* upstream parse.y:6332: args-list_arg_value_opt_args_tail_largs_tail_none: f_rest_arg ',' f_arg opt_args_tail_largs_tail_none */
args_list_arg_value_opt_args_tail_largs_tail_none: f_rest_arg ',' f_arg opt_args_tail_largs_tail_none %prec ',' { $$ = @builder.unsupported(779) };
/* upstream parse.y:6360: f_args-list_largs_tail_none: args-list_arg_value_opt_args_tail_largs_tail_none */
f_args_list_largs_tail_none: args_list_arg_value_opt_args_tail_largs_tail_none { $$ = @builder.unsupported(780) };
/* upstream parse.y:6349: f_args-list_largs_tail_none: f_arg opt_args_tail_largs_tail_none */
f_args_list_largs_tail_none: f_arg opt_args_tail_largs_tail_none { $$ = @builder.unsupported(781) };
/* upstream parse.y:6340: tail-only-args_largs_tail: largs_tail */
tail_only_args_largs_tail: largs_tail { $$ = @builder.unsupported(782) };
/* upstream parse.y:6360: f_args-list_largs_tail_none: tail-only-args_largs_tail */
f_args_list_largs_tail_none: tail_only_args_largs_tail { $$ = @builder.unsupported(783) };
/* upstream parse.y:6360: f_args-list_largs_tail_none: f_empty_arg */
f_args_list_largs_tail_none: f_empty_arg { $$ = @builder.unsupported(784) };
/* upstream parse.y:6360: f_largs: f_args-list_largs_tail_none */
f_largs: f_args_list_largs_tail_none { $$ = @builder.unsupported(785) };
/* upstream parse.y:6364: args_forward: "(..." */
args_forward: tBDOT3 %prec tBDOT3 { $$ = @builder.unsupported(786) };
/* upstream parse.y:6371: f_bad_arg: "constant" */
f_bad_arg: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(787) };
/* upstream parse.y:6380: f_bad_arg: "instance variable" */
f_bad_arg: tIVAR %prec tIVAR { $$ = @builder.unsupported(788) };
/* upstream parse.y:6389: f_bad_arg: "global variable" */
f_bad_arg: tGVAR %prec tGVAR { $$ = @builder.unsupported(789) };
/* upstream parse.y:6398: f_bad_arg: "class variable" */
f_bad_arg: tCVAR %prec tCVAR { $$ = @builder.unsupported(790) };
/* upstream parse.y:6408: f_norm_arg: f_bad_arg */
f_norm_arg: f_bad_arg { $$ = @builder.unsupported(791) };
/* upstream parse.y:6410: f_norm_arg: "local variable or method" */
f_norm_arg: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(792) };
/* upstream parse.y:6420: f_arg_asgn: f_norm_arg */
f_arg_asgn: f_norm_arg { $$ = @builder.unsupported(793) };
/* upstream parse.y:6427: f_arg_item: f_arg_asgn */
f_arg_item: f_arg_asgn { $$ = @builder.unsupported(794) };
/* upstream parse.y:6432: f_arg_item: "(" f_margs rparen */
f_arg_item: tLPAREN f_margs rparen %prec tLPAREN { $$ = @builder.unsupported(795) };
/* upstream parse.y:6450: f_arg: f_arg_item */
f_arg: f_arg_item { $$ = @builder.unsupported(796) };
/* upstream parse.y:6453: f_arg: f_arg ',' f_arg_item */
f_arg: f_arg ',' f_arg_item %prec ',' { $$ = @builder.unsupported(797) };
/* upstream parse.y:6464: f_label: "label" */
f_label: tLABEL %prec tLABEL { $$ = @builder.unsupported(798) };
/* upstream parse.y:6483: kwrest_mark: "**" */
kwrest_mark: tPOW %prec tPOW { $$ = @builder.unsupported(799) };
/* upstream parse.y:6484: kwrest_mark: "**arg" */
kwrest_mark: tDSTAR %prec tDSTAR { $$ = @builder.unsupported(800) };
/* upstream parse.y:6488: f_no_kwarg: p_kwnorest */
f_no_kwarg: p_kwnorest { $$ = @builder.unsupported(801) };
/* upstream parse.y:6494: f_kwrest: kwrest_mark "local variable or method" */
f_kwrest: kwrest_mark tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(802) };
/* upstream parse.y:6500: f_kwrest: kwrest_mark */
f_kwrest: kwrest_mark { $$ = @builder.unsupported(803) };
/* upstream parse.y:6507: restarg_mark: '*' */
restarg_mark: '*' %prec '*' { $$ = @builder.unsupported(804) };
/* upstream parse.y:6508: restarg_mark: "*" */
restarg_mark: tSTAR %prec tSTAR { $$ = @builder.unsupported(805) };
/* upstream parse.y:6512: f_rest_arg: restarg_mark "local variable or method" */
f_rest_arg: restarg_mark tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(806) };
/* upstream parse.y:6518: f_rest_arg: restarg_mark */
f_rest_arg: restarg_mark { $$ = @builder.unsupported(807) };
/* upstream parse.y:6525: blkarg_mark: '&' */
blkarg_mark: '&' %prec '&' { $$ = @builder.unsupported(808) };
/* upstream parse.y:6526: blkarg_mark: "&" */
blkarg_mark: tAMPER %prec tAMPER { $$ = @builder.unsupported(809) };
/* upstream parse.y:6530: f_block_arg: blkarg_mark "local variable or method" */
f_block_arg: blkarg_mark tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(810) };
/* upstream parse.y:6536: f_block_arg: blkarg_mark "'nil'" */
f_block_arg: blkarg_mark keyword_nil %prec keyword_nil { $$ = @builder.unsupported(811) };
/* upstream parse.y:6541: f_block_arg: blkarg_mark */
f_block_arg: blkarg_mark { $$ = @builder.unsupported(812) };
/* upstream parse.y:6548: option_',': %empty */
option____: %empty { $$ = @builder.unsupported(813) };
/* upstream parse.y:6548: option_',': ',' */
option____: ',' %prec ',' { $$ = @builder.unsupported(814) };
/* upstream parse.y:6549: opt_comma: option_',' */
opt_comma: option____ { $$ = @builder.unsupported(815) };
/* upstream parse.y:3161: value_expr_singleton_expr: singleton_expr */
value_expr_singleton_expr: singleton_expr { $$ = @builder.unsupported(816) };
/* upstream parse.y:6557: singleton: value_expr_singleton_expr */
singleton: value_expr_singleton_expr { $$ = @builder.unsupported(817) };
/* upstream parse.y:6586: singleton_expr: var_ref */
singleton_expr: var_ref { $$ = @builder.unsupported(818) };
/* upstream parse.y:6588: $@41: %empty */
midrule_41: %empty { $$ = @builder.unsupported(819) };
/* upstream parse.y:6593: singleton_expr: '(' $@41 expr rparen */
singleton_expr: '(' midrule_41 expr rparen %prec '(' { $$ = @builder.unsupported(820) };
/* upstream parse.y:6600: assoc_list: none */
assoc_list: none { $$ = [].freeze };
/* upstream parse.y:6602: assoc_list: assocs trailer */
assoc_list: assocs trailer { $$ = $1 };
/* upstream parse.y:6608: assocs: assoc */
assocs: assoc { $$ = [$1].freeze };
/* upstream parse.y:6611: assocs: assocs ',' assoc */
assocs: assocs ',' assoc %prec ',' { $$ = ($1 + [$3]).freeze };
/* upstream parse.y:6634: assoc: arg_value "=>" arg_value */
assoc: arg_value tASSOC arg_value %prec tASSOC { $$ = @builder.pair($1, $3) };
/* upstream parse.y:6639: assoc: "label" arg_value */
assoc: tLABEL arg_value %prec tLABEL { $$ = @builder.pair(@builder.symbol($1), $2) };
/* upstream parse.y:6644: assoc: "label" */
assoc: tLABEL %prec tLABEL { $$ = @builder.unsupported(827) };
/* upstream parse.y:6651: assoc: "string literal" string_contents tLABEL_END arg_value */
assoc: tSTRING_BEG string_contents tLABEL_END arg_value %prec tLABEL_END { $$ = @builder.unsupported(828) };
/* upstream parse.y:6657: assoc: "**arg" arg_value */
assoc: tDSTAR arg_value %prec tDSTAR { $$ = @builder.unsupported(829) };
/* upstream parse.y:6662: assoc: "**arg" */
assoc: tDSTAR %prec tDSTAR { $$ = @builder.unsupported(830) };
/* upstream parse.y:6674: operation2: "local variable or method" */
operation2: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(831) };
/* upstream parse.y:6674: operation2: "constant" */
operation2: tCONSTANT %prec tCONSTANT { $$ = @builder.unsupported(832) };
/* upstream parse.y:6674: operation2: "method" */
operation2: tFID %prec tFID { $$ = @builder.unsupported(833) };
/* upstream parse.y:6675: operation2: op */
operation2: op { $$ = @builder.unsupported(834) };
/* upstream parse.y:6678: operation3: "local variable or method" */
operation3: tIDENTIFIER %prec tIDENTIFIER { $$ = @builder.unsupported(835) };
/* upstream parse.y:6679: operation3: "method" */
operation3: tFID %prec tFID { $$ = @builder.unsupported(836) };
/* upstream parse.y:6680: operation3: op */
operation3: op { $$ = @builder.unsupported(837) };
/* upstream parse.y:6683: dot_or_colon: '.' */
dot_or_colon: '.' %prec '.' { $$ = @builder.unsupported(838) };
/* upstream parse.y:6684: dot_or_colon: "::" */
dot_or_colon: tCOLON2 %prec tCOLON2 { $$ = @builder.unsupported(839) };
/* upstream parse.y:6687: call_op: '.' */
call_op: '.' %prec '.' { $$ = @builder.unsupported(840) };
/* upstream parse.y:6688: call_op: "&." */
call_op: tANDDOT %prec tANDDOT { $$ = @builder.unsupported(841) };
/* upstream parse.y:6691: call_op2: call_op */
call_op2: call_op { $$ = @builder.unsupported(842) };
/* upstream parse.y:6692: call_op2: "::" */
call_op2: tCOLON2 %prec tCOLON2 { $$ = @builder.unsupported(843) };
/* upstream parse.y:6695: rparen: option_'\n' ')' */
rparen: option_newline ')' %prec ')' { $$ = nil };
/* upstream parse.y:6698: rbracket: option_'\n' ']' */
rbracket: option_newline ']' %prec ']' { $$ = nil };
/* upstream parse.y:6701: rbrace: option_'\n' '}' */
rbrace: option_newline '}' %prec '}' { $$ = @builder.unsupported(846) };
/* upstream parse.y:6704: trailer: option_'\n' */
trailer: option_newline { $$ = nil };
/* upstream parse.y:6705: trailer: ',' */
trailer: ',' %prec ',' { $$ = nil };
/* upstream parse.y:6709: term: ';' */
term: ';' %prec ';' { $$ = nil };
/* upstream parse.y:6717: term: '\n' */
term: '\n' %prec '\n' { $$ = nil };
/* upstream parse.y:6723: terms: term */
terms: term { $$ = nil };
/* upstream parse.y:6724: terms: terms ';' */
terms: terms ';' %prec ';' { $$ = nil };
/* upstream parse.y:6728: none: %empty */
none: %empty { $$ = nil };
