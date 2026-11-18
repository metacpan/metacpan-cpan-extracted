package Text::Nunjucks::Compiler::Compiler;
# ABSTRACT: The code generator, emitting Perl source (compiler.js class Compiler)

our $VERSION = '0.001';

use Moo;
use builtin qw( is_bool created_as_number );
use Text::Nunjucks::Runtime;
use Text::Nunjucks::Nodes;
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::TemplateError;
use Text::Nunjucks::Lib::Error;
use namespace::autoclean;

no warnings 'experimental::builtin';

# upstream: class Compiler extends Obj in compiler.js (ADR 0002: a Moo class).
#
# THE ONE STRUCTURAL DIFFERENCE FROM EVERY OTHER PORTED FILE: compiler.js emits
# *JavaScript* source; this compiler emits *Perl* source (ADR 0003 keeps the CPS
# shape). So a compile* method's control flow follows upstream, but the strings
# it emits are Perl. The systematic JS->Perl translations are:
#   * every emitted local is `$name` (JS bare `name`); the root shape is
#     `$root = sub { my ($env,$context,$frame,$runtime,$cb) = @_; ... }`
#     and blocks are `$b_<name> = sub {...}`, assigned to forward-declared
#     lexicals; inside its own body a block sub names itself with a per-call
#     `my $b_<name> = CORE::__SUB__;` (what JS's `function b_<name>` gives for
#     free), which is what super() passes on -- see compile_root. getCode()'s
#     string eval()s to the { root => \&, b_<name> => \& } hashref (upstream:
#     new Function()).
#   * try/catch -> eval {} + `if (my $e = $@)`; `cb(...)` -> `$cb->(...)`.
#   * EVERY operator goes through a Runtime op_* call, never a native Perl
#     operator (Perl's +,==,... lack JS semantics) -- compileAdd -> op_add,
#     compileCompare -> op_eq/op_lt/... , compileNot -> op_not, &c. This is the
#     runtime surface k14 built for exactly this (ADR 0007 / value model).
#   * every JS-truthiness test on a template value is $runtime->_truthy(...)
#     (compileIf/compileInlineIf/compileFor's if(arr)); internal booleans
#     (err, frame.topLevel, parentTemplate) stay native Perl truthiness.
#   * container output goes through $runtime->_js_to_string(...) so numbers use
#     ADR-0007 number_to_string, not Perl's %.15g (forward note from k14 audit).
#   * template dict literals build a $runtime->make_dict(...) (Hash::Ordered,
#     ADR 0011) to keep insertion order; kwargs stay a plain hashref.
#   * every string that reaches emitted code goes through _quote (one routine):
#     a Perl single-quoted literal, so `$`, `@`, `\`, `'`, newlines are safe.
#
# Open touches, encapsulated and reported (not decided here): regex literals
# (k7 / ADR 0013 -- emitted via a single $runtime->make_regex seam that runtime
# does not implement yet); extensions / compileCallExtension (k8 / k22 -- the
# extension object surface is still open); the Environment/Context method
# surface the emitted code calls (get_filter/get_test/get_template/waterfall,
# lookup/set_variable/get_block/... ) lands with k16.

# init(templateName, throwOnUndefined) -- Moo attributes are the field set.
has template_name      => ( is => 'ro' );
has codebuf            => ( is => 'ro', default => sub { [] } );
has last_id            => ( is => 'rw', default => sub { 0 } );
has buffer             => ( is => 'rw', default => sub { undef } );
has buffer_stack       => ( is => 'ro', default => sub { [] } );
has _scope_closers     => ( is => 'rw', default => sub { '' } );
has in_block           => ( is => 'rw', default => sub { 0 } );
has throw_on_undefined => ( is => 'ro' );

# Collaborators named once, reached through the invocant (house rule).
sub node                  { 'Text::Nunjucks::Nodes::' . $_[1] }
sub frame_class           { 'Text::Nunjucks::Runtime::Frame' }
sub template_error_class  { 'Text::Nunjucks::Lib::TemplateError' }
sub error_class           { 'Text::Nunjucks::Lib::Error' }

#### string quoting -- the one routine every emitted string goes through
# A Perl single-quoted literal: escape \ then ', leave everything else
# (including $, @, newlines, tabs, unicode) verbatim. Single quotes do not
# interpolate, so this is safe for arbitrary template text and values.
sub _quote {
  my ( $self, $str ) = @_;
  $str = '' unless defined $str;
  $str =~ s/\\/\\\\/g;
  $str =~ s/'/\\'/g;
  return "'" . $str . "'";
}

# A number for emission: lineno/colno, or `undef` for a missing position.
sub _num_or_undef {
  my ( $self, $v ) = @_;
  return 'undef' unless defined $v;
  return "$v";
}

sub fail {
  my ( $self, $msg, $lineno, $colno ) = @_;

  $lineno = $lineno + 1 if defined $lineno;
  $colno  = $colno + 1  if defined $colno;

  die $self->template_error_class->new( $msg, $lineno, $colno );
}

sub _push_buffer {
  my ($self) = @_;
  my $id = $self->_tmpid;
  push @{ $self->buffer_stack }, $self->buffer;
  $self->buffer($id);
  $self->_emit( 'my $' . $self->buffer . ' = "";' );
  return $id;
}

sub _pop_buffer {
  my ($self) = @_;
  $self->buffer( pop @{ $self->buffer_stack } );
}

sub _emit {
  my ( $self, $code ) = @_;
  push @{ $self->codebuf }, $code;
}

sub _emit_line {
  my ( $self, $code ) = @_;
  $self->_emit( $code . "\n" );
}

sub _emit_lines {
  my ( $self, @lines ) = @_;
  $self->_emit_line($_) for @lines;
}

sub _emit_func_begin {
  my ( $self, $node, $name ) = @_;
  $self->buffer('output');
  $self->_scope_closers('');
  # $<name> = sub { ... }  -- assigned to a forward-declared lexical
  $self->_emit_line( '$' . $name . ' = sub {' );
  $self->_emit_line('my ($env, $context, $frame, $runtime, $cb) = @_;');

  # Port-only (ADR 0021). In upstream everything in this function closes over
  # `context` -- every continuation callback, every macro -- and the Context
  # holds the macros: cycles a tracing GC collects and a reference count never
  # frees. So no root or block sub holds its Context: this line weakens the
  # sub's $context variable, which is the one variable all its nested subs
  # capture, and registers it and $frame with the Context (Runtime
  # _render_scope). What holds the Context is what is still going to run: the
  # call that started the render, and each continuation until it is called
  # (_continuation_open).
  $self->_emit_line('$runtime->_render_scope(\$context, \$frame);');

  $self->_emit_line( 'my $lineno = ' . $self->_num_or_undef( $node->lineno ) . ';' );
  $self->_emit_line( 'my $colno = ' . $self->_num_or_undef( $node->colno ) . ';' );
  $self->_emit_line( 'my $' . $self->buffer . ' = "";' );
  $self->_emit_line('eval {');
}

sub _emit_func_end {
  my ( $self, $no_return ) = @_;
  if ( !$no_return ) {
    $self->_emit_line( '$cb->(undef, $' . $self->buffer . ');' );
  }

  $self->_close_scope_levels;
  $self->_emit_line('};');    # close eval {
  $self->_emit_line('if (my $e = $@) {');
  $self->_emit_line('  $cb->($runtime->handle_error($e, $lineno, $colno));');
  $self->_emit_line('}');
  $self->_emit_line('};');    # close the sub ( $<name> = sub {...}; )
  $self->buffer(undef);
}

# A scope level is a continuation (_make_callback, or the waterfall callback
# of compile_include). A continuation is an argument of
# $runtime->_continuation( -- hence the second parenthesis, which upstream's
# '})' does not have -- unless it was made plain (see _make_callback), which
# closes like upstream's. With two kinds of closers they have to come in the
# reverse order of opening, so the newest goes in front.
sub _add_scope_level {
  my ( $self, $plain ) = @_;
  $self->_scope_closers( ( $plain ? '})' : '}))' ) . $self->_scope_closers );
}

sub _close_scope_levels {
  my ($self) = @_;
  $self->_emit_line( $self->_scope_closers . ';' );
  $self->_scope_closers('');
}

sub _with_scoped_syntax {
  my ( $self, $func ) = @_;
  my $scope_closers = $self->_scope_closers;
  $self->_scope_closers('');

  $func->();

  $self->_close_scope_levels;
  $self->_scope_closers($scope_closers);
}

# Port-only (ADR 0021): what upstream emits as `function(...) {` for a
# continuation -- a callback handed to something that calls it when it is
# done. The compiled subs do not hold their Context (_emit_func_begin); a
# continuation that is still waiting to be called has to, or the Context of a
# render would be gone before an async filter calls back. Runtime
# _continuation wraps the sub so that it holds the Context from here until it
# is called. It is closed with '}))', see _add_scope_level.
sub _continuation_open {
  my ($self) = @_;
  return '$runtime->_continuation($context, sub {';
}

# `$runtime->_continuation($context, sub { my ($t_err[, $res]) = @_;
# if ($t_err) { $cb->($t_err); return; }` -- an unclosed continuation, closed
# by a later scope closer.
#
# Port-only (ADR 0021): with $plain it is upstream's bare `sub {`, which holds
# nothing. That is for the callback handed to a block (compile_block,
# compile_super): the block runs in the same Context, so whatever of the block
# is still going to run holds that Context already, and the block calls this
# callback from inside it. A hold of its own would be one a macro of the block
# keeps for good: a macro whose body contains an async construct captures the
# block's `$cb`, which is this callback, and the block's frame holds the
# macro -- a block that never finishes would keep its Context for ever.
#
# Port-only (ADR 0021): $on_error is a statement that goes in front of the
# `$cb->($t_err)` of the error branch, see compile_include and
# _keep_alive_statement.
sub _make_callback {
  my ( $self, $res, $plain, $on_error ) = @_;
  my $err = $self->_tmpid;

  return
      ( $plain ? 'sub {' : $self->_continuation_open ) . "\n"
    . 'my ($' . $err . ( $res ? ', $' . $res : '' ) . ') = @_;' . "\n"
    . 'if($' . $err . ') { ' . ( $on_error // '' ) . '$cb->($' . $err . '); return; }';
}

sub _tmpid {
  my ($self) = @_;
  $self->last_id( $self->last_id + 1 );
  return 't_' . $self->last_id;
}

sub _template_name {
  my ($self) = @_;
  return defined $self->template_name
    ? $self->_quote( $self->template_name )
    : 'undef';
}

sub _compile_children {
  my ( $self, $node, $frame ) = @_;
  for my $child ( @{ $node->children } ) {
    $self->compile( $child, $frame );
  }
}

sub _compile_aggregate {
  my ( $self, $node, $frame, $start_char, $end_char ) = @_;
  $self->_emit($start_char) if defined $start_char && length $start_char;

  my $children = $node->children;
  for my $i ( 0 .. $#$children ) {
    $self->_emit(', ') if $i > 0;
    $self->compile( $children->[$i], $frame );
  }

  $self->_emit($end_char) if defined $end_char && length $end_char;
}

sub _compile_expression {
  my ( $self, $node, $frame ) = @_;
  $self->assert_type(
    $node,
    map { $self->node($_) } qw(
      Literal Symbol Group Array Dict FunCall Caller Filter LookupVal
      Compare InlineIf In Is And Or Not Add Concat Sub Mul Div FloorDiv
      Mod Pow Neg Pos NodeList
    )
  );
  $self->compile( $node, $frame );
}

sub assert_type {
  my ( $self, $node, @types ) = @_;
  unless ( grep { $node->isa($_) } @types ) {
    $self->fail( 'assertType: invalid type: ' . $node->typename,
      $node->lineno, $node->colno );
  }
}

sub compile_call_extension {
  my ( $self, $node, $frame, $async ) = @_;
  # k8/k22: the extension object surface is still open. Ported 1:1 in shape;
  # get_extension(name)->prop(context, ...) assumes a blessed extension whose
  # tag handler is a method (mirrors ext.getExtension(name)[prop](context,...)).
  my $args         = $node->args;
  my $content_args = $node->contentArgs;
  my $autoescape =
    ( defined( $node->autoescape ) && is_bool( $node->autoescape ) )
    ? $node->autoescape
    : 1;
  my $ae = $autoescape ? '1' : '0';

  # Port-only (ADR 0021): a content argument is a function the extension can
  # keep and call later, see _emit_made_closure.
  $self->_emit_made_closure if grep { $_ } @$content_args;

  # `buffer += ...` is Runtime js_string_append throughout: JS's buffer joins
  # code units, so it re-pairs two halves of a surrogate pair (ADR 0012).
  if ( !$async ) {
    $self->_emit( '$runtime->js_string_append($' . $self->buffer
        . ', $runtime->_js_to_string($runtime->suppress_value(' );
  }

  $self->_emit( '$env->get_extension(' . $self->_quote( $node->extName )
      . ')->' . $node->prop . '(' );
  $self->_emit('$context');

  if ( $args || @$content_args ) {
    $self->_emit(', ');
  }

  if ($args) {
    if ( !$args->isa( $self->node('NodeList') ) ) {
      $self->fail( 'compileCallExtension: arguments must be a NodeList, '
          . 'use `parser.parseSignature`' );
    }

    my $arg_children = $args->children;
    for my $i ( 0 .. $#$arg_children ) {
      $self->_compile_expression( $arg_children->[$i], $frame );

      if ( $i != $#$arg_children || @$content_args ) {
        $self->_emit(', ');
      }
    }
  }

  if (@$content_args) {
    for my $i ( 0 .. $#$content_args ) {
      my $arg = $content_args->[$i];
      $self->_emit(', ') if $i > 0;

      if ($arg) {
        $self->_emit_line('sub { my ($cb) = @_;');
        $self->_emit_line(
          'if(!$cb) { $cb = sub { my ($err) = @_; if($err) { die $err; } } }');
        my $id = $self->_push_buffer;

        $self->_with_scoped_syntax(
          sub {
            $self->compile( $arg, $frame );
            $self->_emit_line( '$cb->(undef, $' . $id . ');' );
          }
        );

        $self->_pop_buffer;
        $self->_emit_line( 'return $' . $id . ';' );
        $self->_emit_line('}');
      }
      else {
        $self->_emit('undef');
      }
    }
  }

  if ($async) {
    my $res = $self->_tmpid;
    $self->_emit_line( ', ' . $self->_make_callback($res) );
    $self->_emit_line( '$runtime->js_string_append($' . $self->buffer
        . ', $runtime->_js_to_string($runtime->suppress_value($'
        . $res . ', ' . $ae . ' && $env->opts->{autoescape})));' );
    $self->_add_scope_level;
  }
  else {
    $self->_emit(')');
    $self->_emit( ', ' . $ae . " && \$env->opts->{autoescape})));\n" );
  }
}

sub compile_call_extension_async {
  my ( $self, $node, $frame ) = @_;
  $self->compile_call_extension( $node, $frame, 1 );
}

sub compile_node_list {
  my ( $self, $node, $frame ) = @_;
  $self->_compile_children( $node, $frame );
}

sub compile_literal {
  my ( $self, $node ) = @_;
  my $v = $node->value;

  if ( !defined $v ) {
    $self->_emit('$runtime->None');    # JS null
  }
  elsif ( is_bool($v) ) {
    $self->_emit( $v ? '!!1' : '!!0' );    # JS boolean (is_bool-flagged)
  }
  elsif ( created_as_number($v) ) {
    # node.value.toString(): ADR 0007's shortest round-trip form, not Perl's
    # "$v" (which collapses e.g. 0.30000000000000004 to 0.3). The result is a
    # valid Perl numeric literal for every finite double a number literal can
    # hold (NaN/Infinity cannot reach here from the lexer).
    $self->_emit( Text::Nunjucks::Lib->number_to_string($v) );
  }
  elsif ( ref($v) eq 'HASH' && exists $v->{regex} ) {
    # regex literal -- k7 / ADR 0013 open, runtime support not wired yet.
    $self->_emit( '$runtime->make_regex('
        . $self->_quote( $v->{regex} ) . ', '
        . $self->_quote( defined $v->{flags} ? $v->{flags} : '' )
        . ')' );
  }
  else {
    $self->_emit( $self->_quote($v) );      # string
  }
}

sub compile_symbol {
  my ( $self, $node, $frame ) = @_;
  my $name = $node->value;
  my $v    = $frame->lookup($name);

  if ($v) {
    $self->_emit( '$' . $v );
  }
  else {
    $self->_emit( '$runtime->context_or_frame_lookup($context, $frame, '
        . $self->_quote($name) . ')' );
  }
}

sub compile_group {
  my ( $self, $node, $frame ) = @_;
  $self->_compile_aggregate( $node, $frame, '(', ')' );
}

sub compile_array {
  my ( $self, $node, $frame ) = @_;
  $self->_compile_aggregate( $node, $frame, '[', ']' );
}

# Template dict literals build a $runtime->make_dict(k1, v1, ...), a
# Hash::Ordered, so insertion order survives (ADR 0011). This diverges from
# upstream's `{k: v}` JS-object literal only in the representation.
sub compile_dict {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->make_dict(');
  my $children = $node->children;
  for my $i ( 0 .. $#$children ) {
    $self->_emit(', ') if $i > 0;
    $self->compile( $children->[$i], $frame );
  }
  $self->_emit(')');
}

sub compile_pair {
  my ( $self, $node, $frame ) = @_;
  my $key = $node->key;
  my $val = $node->value;

  if ( $key->isa( $self->node('Symbol') ) ) {
    $key = $self->node('Literal')->new( $key->lineno, $key->colno, $key->value );
  }
  elsif (
    !( $key->isa( $self->node('Literal') )
      && Text::Nunjucks::Lib->is_string( $key->value ) )
    )
  {
    $self->fail( 'compilePair: Dict keys must be strings or names',
      $key->lineno, $key->colno );
  }

  $self->compile( $key, $frame );
  $self->_emit(', ');    # was ': ' -- key, value pairs for make_dict / hashref
  $self->_compile_expression( $val, $frame );
}

sub compile_inline_if {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('($runtime->_truthy(');
  $self->compile( $node->cond, $frame );
  $self->_emit(') ? ');
  $self->compile( $node->body, $frame );
  $self->_emit(' : ');
  if ( defined $node->else_ ) {
    $self->compile( $node->else_, $frame );
  }
  else {
    $self->_emit("''");
  }
  $self->_emit(')');
}

sub compile_in {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->in_operator(');
  $self->compile( $node->left, $frame );
  $self->_emit(', ');
  $self->compile( $node->right, $frame );
  $self->_emit(')');
}

sub compile_is {
  my ( $self, $node, $frame ) = @_;
  # name of the test function: the callable's name (a Filter/FunCall), else
  # the operand value. JS reads a missing property as undefined (hence the
  # can() guard: a bare Symbol has no name/args accessor) and then coerces the
  # value into the test-name string -- crucially `x is none` parses `none` as
  # a Literal(null), and `"env.getTest(\"" + null + "\")"` yields getTest("null")
  # (upstream registers the test under `null`). _literal_to_string reproduces
  # that JS ToString (null -> "null", numbers/bools too).
  my $right_val =
    ( $node->right->can('name') && $node->right->name )
    ? $node->right->name->value
    : $node->right->value;
  my $right = $self->_literal_to_string($right_val);
  # env.getTest(name).call(context, left[, args]) === true. Per ADR 0009 the
  # Perl test receives (@args) with no `this`, and === is op_seq.
  $self->_emit(
    '$runtime->op_seq($env->get_test(' . $self->_quote($right) . ')->(' );
  $self->compile( $node->left, $frame );
  if ( $node->right->can('args') && $node->right->args ) {
    $self->_emit(', ');
    $self->compile( $node->right->args, $frame );
  }
  $self->_emit('), !!1)');
}

# Every operator is emitted as a Runtime op_* call (never a native Perl
# operator, which lacks JS semantics). The AST already encodes precedence, and
# each operand is a full sub-expression inside the call's parens, so no
# parenthesisation is needed. compileCompare is the exception (see below).
sub _bin_op_emitter {
  my ( $self, $node, $frame, $op ) = @_;
  $self->_emit( '$runtime->' . $op . '(' );
  $self->compile( $node->left, $frame );
  $self->_emit(', ');
  $self->compile( $node->right, $frame );
  $self->_emit(')');
}

sub compile_or  { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_or' ) }
sub compile_and { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_and' ) }
sub compile_add { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_add' ) }
sub compile_concat { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_concat' ) }
sub compile_sub { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_sub' ) }
sub compile_mul { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_mul' ) }
sub compile_div { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_div' ) }
sub compile_mod { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_mod' ) }

sub compile_not {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->op_not(');
  $self->compile( $node->target, $frame );
  $self->_emit(')');
}

sub compile_floor_div { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_floordiv' ) }
sub compile_pow       { $_[0]->_bin_op_emitter( $_[1], $_[2], 'op_pow' ) }

sub compile_neg {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->op_neg(');
  $self->compile( $node->target, $frame );
  $self->_emit(')');
}

sub compile_pos {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->op_pos(');
  $self->compile( $node->target, $frame );
  $self->_emit(')');
}

my %CMP_OP = (
  '=='  => 'op_eq',  '===' => 'op_seq',
  '!='  => 'op_ne',  '!==' => 'op_sne',
  '<'   => 'op_lt',  '>'   => 'op_gt',
  '<='  => 'op_le',  '>='  => 'op_ge',
);
# JS operator precedence: relational (< > <= >=) binds tighter than equality
# (== != === !==), both left-associative.
my %CMP_PREC = (
  '=='  => 1, '===' => 1, '!='  => 1, '!==' => 1,
  '<'   => 2, '>'   => 2, '<='  => 2, '>='  => 2,
);

# Upstream emits native infix comparison operators and relies on JS precedence
# (`2 == 1 < 5` -> `2 == (1 < 5)`). op_* runtime calls have no infix form, so
# we rebuild that precedence as nested calls via precedence climbing. A single
# comparison (the overwhelmingly common case) reduces to one op_* call.
sub compile_compare {
  my ( $self, $node, $frame ) = @_;
  my @toks = ( { operand => $node->expr } );
  for my $op ( @{ $node->ops } ) {
    push @toks, { op => $op->type }, { operand => $op->expr };
  }
  my $pos  = 0;
  my $tree = $self->_compare_climb( \@toks, \$pos, 0 );
  $self->_emit_compare( $tree, $frame );
}

sub _compare_climb {
  my ( $self, $toks, $pos, $min_prec ) = @_;
  my $lhs = { leaf => $toks->[$$pos]{operand} };
  $$pos++;
  while ( $$pos < @$toks
    && exists $toks->[$$pos]{op}
    && $CMP_PREC{ $toks->[$$pos]{op} } >= $min_prec )
  {
    my $op = $toks->[$$pos]{op};
    $$pos++;    # consume operator
    my $rhs = $self->_compare_climb( $toks, $pos, $CMP_PREC{$op} + 1 );
    $lhs = { op => $op, left => $lhs, right => $rhs };
  }
  return $lhs;
}

sub _emit_compare {
  my ( $self, $tree, $frame ) = @_;
  if ( exists $tree->{leaf} ) {
    $self->compile( $tree->{leaf}, $frame );
    return;
  }
  $self->_emit( '$runtime->' . $CMP_OP{ $tree->{op} } . '(' );
  $self->_emit_compare( $tree->{left}, $frame );
  $self->_emit(', ');
  $self->_emit_compare( $tree->{right}, $frame );
  $self->_emit(')');
}

sub compile_lookup_val {
  my ( $self, $node, $frame, $seam ) = @_;
  # ADR 0016: the seam is the property-read one by default
  # ($runtime->member_lookup); FunCall hands us 'method' so a blessed-object
  # member comes back as a callable for call_wrap. compile_fun_call is the
  # only caller that flips the seam.
  my $sym = ( $seam && $seam eq 'method' )
    ? '$runtime->member_lookup_method(('
    : '$runtime->member_lookup((';
  $self->_emit($sym);
  $self->_compile_expression( $node->target, $frame );
  $self->_emit('), ');
  $self->_compile_expression( $node->val, $frame );
  $self->_emit(')');
}

sub _get_node_name {
  my ( $self, $node ) = @_;
  my $t = $node->typename;
  if ( $t eq 'Symbol' ) {
    return $node->value;
  }
  elsif ( $t eq 'FunCall' ) {
    return 'the return value of (' . $self->_get_node_name( $node->name ) . ')';
  }
  elsif ( $t eq 'LookupVal' ) {
    return
        $self->_get_node_name( $node->target ) . '["'
      . $self->_get_node_name( $node->val ) . '"]';
  }
  elsif ( $t eq 'Literal' ) {
    return $self->_literal_to_string( $node->value );    # node.value.toString()
  }
  else {
    return '--expression--';
  }
}

sub _literal_to_string {
  my ( $self, $v ) = @_;
  return 'null' if !defined $v;    # avoid a null.toString() crash (rare)
  return ( $v ? 'true' : 'false' ) if is_bool($v);
  return Text::Nunjucks::Lib->number_to_string($v) if created_as_number($v);
  return $v unless ref $v;
  return '[object Object]';
}

sub compile_fun_call {
  my ( $self, $node, $frame ) = @_;
  # Keep line/col at runtime: a JS `(x, y, z)` returns z; the Perl equivalent
  # that runs the assignments then returns the last value in any context is
  # `do { ...; EXPR }`.
  $self->_emit( 'do { $lineno = '
      . $self->_num_or_undef( $node->lineno )
      . '; $colno = '
      . $self->_num_or_undef( $node->colno )
      . '; ' );

  $self->_emit('$runtime->call_wrap(');

  # ADR 0016: the callable argument comes from the method-call seam
  # (member_lookup_method), not the property-read one -- otherwise a
  # blessed object's `obj.foo` would render its value rather than hand
  # call_wrap something to invoke. A bare Symbol (foo()) goes through the
  # normal expression compile (Frame/Context lookup yields the coderef).
  if ( $node->name->typename eq 'LookupVal' ) {
    $self->compile_lookup_val( $node->name, $frame, 'method' );
  } else {
    $self->_compile_expression( $node->name, $frame );
  }

  # Name of what we're calling, for friendly errors on a failed lookup.
  $self->_emit(
    ', ' . $self->_quote( $self->_get_node_name( $node->name ) ) . ', $context, ' );

  $self->_compile_aggregate( $node->args, $frame, '[', ']' );

  $self->_emit(')');      # close call_wrap
  $self->_emit(' }');     # close do
}

sub compile_filter {
  my ( $self, $node, $frame ) = @_;
  my $name = $node->name;
  $self->assert_type( $name, $self->node('Symbol') );
  # ADR 0009: a sync filter receives (@args), no `this`/context.
  $self->_emit( '$env->get_filter(' . $self->_quote( $name->value ) . ')->(' );
  $self->_compile_aggregate( $node->args, $frame );
  $self->_emit(')');
}

sub compile_filter_async {
  my ( $self, $node, $frame ) = @_;
  my $name   = $node->name;
  my $symbol = $node->symbol->value;

  $self->assert_type( $name, $self->node('Symbol') );

  $frame->set( $symbol, $symbol );

  $self->_emit( '$env->get_filter(' . $self->_quote( $name->value ) . ')->(' );
  $self->_compile_aggregate( $node->args, $frame );
  $self->_emit_line( ', ' . $self->_make_callback($symbol) );

  $self->_add_scope_level;
}

# kwargs are looked up by name, never iterated in order, so they stay a plain
# hashref (KwArgs), not the ordered dict compileDict builds (ADR 0011).
sub compile_keyword_args {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('$runtime->make_keyword_args({');
  my $children = $node->children;
  for my $i ( 0 .. $#$children ) {
    $self->_emit(', ') if $i > 0;
    $self->compile( $children->[$i], $frame );
  }
  $self->_emit('})');
}

sub compile_set {
  my ( $self, $node, $frame ) = @_;
  my @ids;

  # Look up the variable names for each identifier, minting new ones if needed.
  for my $target ( @{ $node->targets } ) {
    my $name = $target->value;
    my $id   = $frame->lookup($name);

    if ( !defined $id ) {
      $id = $self->_tmpid;
      # In JS `var id;` hoists to function scope even when created inside an
      # `if`; the Perl tmpid never escapes its own block here, so a plain
      # `my` at this point is correct.
      $self->_emit_line( 'my $' . $id . ';' );
    }

    push @ids, $id;
  }

  my $lhs = join( ' = ', map { '$' . $_ } @ids );

  if ( $node->value ) {
    $self->_emit( $lhs . ' = ' );
    $self->_compile_expression( $node->value, $frame );
    $self->_emit_line(';');
  }
  else {
    $self->_emit( $lhs . ' = ' );
    $self->compile( $node->body, $frame );
    $self->_emit_line(';');
  }

  my $targets = $node->targets;
  for my $i ( 0 .. $#$targets ) {
    my $id   = $ids[$i];
    my $name = $targets->[$i]->value;

    $self->_emit_line( '$frame->set(' . $self->_quote($name) . ', $' . $id . ', 1);' );

    $self->_emit_line('if($frame->top_level) {');
    $self->_emit_line( '$context->set_variable(' . $self->_quote($name) . ', $' . $id . ');' );
    $self->_emit_line('}');

    if ( substr( $name, 0, 1 ) ne '_' ) {
      $self->_emit_line('if($frame->top_level) {');
      $self->_emit_line( '$context->add_export(' . $self->_quote($name) . ', $' . $id . ');' );
      $self->_emit_line('}');
    }
  }
}

# JS `switch` matches with === and falls through until a break. Perl has no
# such construct, so this emulates it with a run-once bare block: op_seq for
# ===, a matched-flag for fall-through, and `last` for break. `default` sits
# last and runs whenever execution reaches it (no break stopped us), exactly
# like JS. (Structural divergence: Perl has no switch/fall-through.)
sub compile_switch {
  my ( $self, $node, $frame ) = @_;
  my $expr    = $self->_tmpid;
  my $matched = $self->_tmpid;

  $self->_emit_line('{');
  $self->_emit( 'my $' . $expr . ' = ' );
  $self->compile( $node->expr, $frame );
  $self->_emit_line(';');
  $self->_emit_line( 'my $' . $matched . ' = 0;' );

  for my $c ( @{ $node->cases } ) {
    $self->_emit( 'if ($' . $matched . ' || $runtime->op_seq($' . $expr . ', ' );
    $self->compile( $c->cond, $frame );
    $self->_emit_line(')) {');
    $self->_emit_line( '$' . $matched . ' = 1;' );
    $self->compile( $c->body, $frame );
    # preserve fall-throughs
    if ( @{ $c->body->children } ) {
      $self->_emit_line('last;');
    }
    $self->_emit_line('}');
  }

  if ( $node->default ) {
    $self->compile( $node->default, $frame );
  }

  $self->_emit_line('}');
}

sub compile_if {
  my ( $self, $node, $frame, $async ) = @_;
  $self->_emit('if($runtime->_truthy(');
  $self->_compile_expression( $node->cond, $frame );
  $self->_emit_line(')) {');

  $self->_with_scoped_syntax(
    sub {
      $self->compile( $node->body, $frame );

      $self->_emit('$cb->();') if $async;
    }
  );

  if ( $node->else_ ) {
    $self->_emit_line("}\nelse {");

    $self->_with_scoped_syntax(
      sub {
        $self->compile( $node->else_, $frame );

        $self->_emit('$cb->();') if $async;
      }
    );
  }
  elsif ($async) {
    $self->_emit_line("}\nelse {");
    $self->_emit('$cb->();');
  }

  $self->_emit_line('}');
}

sub compile_if_async {
  my ( $self, $node, $frame ) = @_;
  $self->_emit('(sub { my ($cb) = @_;');
  $self->compile_if( $node, $frame, 1 );
  $self->_emit( '})->(' . $self->_make_callback() );
  $self->_add_scope_level;
}

sub _emit_loop_bindings {
  my ( $self, $node, $arr, $i, $len ) = @_;
  my @bindings = (
    [ 'index',     '$' . $i . ' + 1' ],
    [ 'index0',    '$' . $i ],
    [ 'revindex',  '$' . $len . ' - $' . $i ],
    [ 'revindex0', '$' . $len . ' - $' . $i . ' - 1' ],
    [ 'first',     '($' . $i . ' == 0)' ],
    [ 'last',      '($' . $i . ' == $' . $len . ' - 1)' ],
    [ 'length',    '$' . $len ],
  );

  for my $b (@bindings) {
    $self->_emit_line(
      '$frame->set("loop.' . $b->[0] . '", ' . $b->[1] . ');' );
  }
}

sub compile_for {
  my ( $self, $node, $frame ) = @_;

  my $i   = $self->_tmpid;
  my $len = $self->_tmpid;
  my $arr = $self->_tmpid;
  $frame = $frame->push;

  $self->_emit_line('$frame = $frame->push;');

  $self->_emit( 'my $' . $arr . ' = ' );
  $self->_compile_expression( $node->arr, $frame );
  $self->_emit_line(';');

  # `len` is used by the else_ check after the if(arr) block; JS var-hoists it,
  # Perl needs it declared here so it survives past the branch.
  $self->_emit_line( 'my $' . $len . ';' );

  # forward note (k14 audit): JS-truthiness guard, not `if defined`, so a null
  # iterable never reaches keys()/deref.
  $self->_emit( 'if($runtime->_truthy($' . $arr . ')) {' );
  $self->_emit_line( '$' . $arr . ' = $runtime->from_iterator($' . $arr . ');' );

  if ( $node->name->isa( $self->node('Array') ) ) {
    $self->_emit_line( 'my $' . $i . ';' );

    # The object could be an array or object. Note that the body of the loop
    # is duplicated for each condition, but we are optimizing for speed.
    $self->_emit_line( 'if($runtime->is_array($' . $arr . ')) {' );
    $self->_emit_line( '$' . $len . ' = scalar @{$' . $arr . '};' );
    $self->_emit_line( 'for($' . $i . '=0; $' . $i . ' < scalar @{$' . $arr . '}; $' . $i . '++) {' );

    # Bind each declared var. arr is isArray-guarded, so arr[i] is a safe
    # deref; the inner [u] goes through member_lookup (element may be short).
    my $name_children = $node->name->children;
    for my $u ( 0 .. $#$name_children ) {
      my $child = $name_children->[$u];
      my $tid   = $self->_tmpid;
      $self->_emit_line( 'my $' . $tid . ' = $runtime->member_lookup($' . $arr . '->[$' . $i . '], ' . $u . ');' );
      $self->_emit_line( '$frame->set(' . $self->_quote( $child->value ) . ', $runtime->member_lookup($' . $arr . '->[$' . $i . '], ' . $u . '));' );
      $frame->set( $name_children->[$u]->value, $tid );
    }

    $self->_emit_loop_bindings( $node, $arr, $i, $len );
    $self->_with_scoped_syntax( sub { $self->compile( $node->body, $frame ) } );
    $self->_emit_line('}');

    $self->_emit_line('} else {');
    # Iterate over the key/values of an object.
    my ( $key, $val ) = @{ $node->name->children };
    my $k       = $self->_tmpid;
    my $v       = $self->_tmpid;
    my $keys_id = $self->_tmpid;
    $frame->set( $key->value, $k );
    $frame->set( $val->value, $v );

    $self->_emit_line( '$' . $i . ' = -1;' );
    $self->_emit_line( 'my $' . $keys_id . ' = $runtime->keys($' . $arr . ');' );
    $self->_emit_line( '$' . $len . ' = scalar @{$' . $keys_id . '};' );
    $self->_emit_line( 'for my $' . $k . ' (@{$' . $keys_id . '}) {' );
    $self->_emit_line( '$' . $i . '++;' );
    $self->_emit_line( 'my $' . $v . ' = $runtime->member_lookup($' . $arr . ', $' . $k . ');' );
    $self->_emit_line( '$frame->set(' . $self->_quote( $key->value ) . ', $' . $k . ');' );
    $self->_emit_line( '$frame->set(' . $self->_quote( $val->value ) . ', $' . $v . ');' );

    $self->_emit_loop_bindings( $node, $arr, $i, $len );
    $self->_with_scoped_syntax( sub { $self->compile( $node->body, $frame ) } );
    $self->_emit_line('}');

    $self->_emit_line('}');
  }
  else {
    # Typical single-var iteration. Base may be an array or a string; length
    # and element go through member_lookup so a non-array does not crash
    # (JS `.length`/`[i]` tolerate it; a Perl deref would not).
    my $v = $self->_tmpid;
    $frame->set( $node->name->value, $v );

    # A string is indexed through its code units, split once rather than
    # measured per element (ADR 0012); the loop below keeps upstream's shape.
    $self->_emit_line( '$' . $arr . ' = $runtime->_for_code_units($' . $arr . ');' );
    $self->_emit_line( '$' . $len . ' = $runtime->member_lookup($' . $arr . ', "length");' );
    $self->_emit_line( 'for(my $' . $i . '=0; defined($' . $len . ') && $' . $i . ' < $' . $len . '; $' . $i . '++) {' );
    $self->_emit_line( 'my $' . $v . ' = $runtime->member_lookup($' . $arr . ', $' . $i . ');' );
    $self->_emit_line( '$frame->set(' . $self->_quote( $node->name->value ) . ', $' . $v . ');' );

    $self->_emit_loop_bindings( $node, $arr, $i, $len );

    $self->_with_scoped_syntax( sub { $self->compile( $node->body, $frame ) } );

    $self->_emit_line('}');
  }

  $self->_emit_line('}');
  if ( $node->else_ ) {
    $self->_emit_line( 'if (!$' . $len . ') {' );
    $self->compile( $node->else_, $frame );
    $self->_emit_line('}');
  }

  $self->_emit_line('$frame = $frame->pop;');
}

sub _compile_async_loop {
  my ( $self, $node, $frame, $parallel ) = @_;
  # Shares some code with compileFor. Iterates an object asynchronously.

  my $i            = $self->_tmpid;
  my $len          = $self->_tmpid;
  my $arr          = $self->_tmpid;
  my $async_method = $parallel ? 'async_all' : 'async_each';
  $frame = $frame->push;

  $self->_emit_line('$frame = $frame->push;');

  $self->_emit( 'my $' . $arr . ' = $runtime->from_iterator(' );
  $self->_compile_expression( $node->arr, $frame );
  $self->_emit_line(');');

  if ( $node->name->isa( $self->node('Array') ) ) {
    my $array_len = scalar @{ $node->name->children };
    $self->_emit( '$runtime->' . $async_method . '($' . $arr . ', ' . $array_len . ', sub {' );
    $self->_emit('my (');

    for my $name ( @{ $node->name->children } ) {
      $self->_emit( '$' . $name->value . ', ' );
    }

    $self->_emit( '$' . $i . ', $' . $len . ', $next) = @_;' );

    for my $name ( @{ $node->name->children } ) {
      my $id = $name->value;
      $frame->set( $id, $id );
      $self->_emit_line( '$frame->set(' . $self->_quote($id) . ', $' . $id . ');' );
    }
  }
  else {
    my $id = $node->name->value;
    $self->_emit_line( '$runtime->' . $async_method . '($' . $arr . ', 1, sub { my ($' . $id . ', $' . $i . ', $' . $len . ', $next) = @_;' );
    $self->_emit_line( '$frame->set(' . $self->_quote($id) . ', $' . $id . ');' );
    $frame->set( $id, $id );
  }

  $self->_emit_loop_bindings( $node, $arr, $i, $len );

  $self->_with_scoped_syntax(
    sub {
      my $buf;
      if ($parallel) {
        $buf = $self->_push_buffer;
      }

      $self->compile( $node->body, $frame );
      $self->_emit_line(
        '$next->($' . $i . ( $buf ? ', $' . $buf : '' ) . ');' );

      if ($parallel) {
        $self->_pop_buffer;
      }
    }
  );

  my $output = $self->_tmpid;
  $self->_emit_line( '}, ' . $self->_make_callback($output) );
  $self->_add_scope_level;

  if ($parallel) {
    $self->_emit_line( '$runtime->js_string_append($' . $self->buffer . ', $' . $output . ');' );
  }

  if ( $node->else_ ) {
    # !arr.length via member_lookup, crash-safe for non-array iterables.
    $self->_emit_line( 'if (!$runtime->member_lookup($' . $arr . ', "length")) {' );
    $self->compile( $node->else_, $frame );
    $self->_emit_line('}');
  }

  $self->_emit_line('$frame = $frame->pop;');
}

sub compile_async_each {
  my ( $self, $node, $frame ) = @_;
  $self->_compile_async_loop( $node, $frame );
}

sub compile_async_all {
  my ( $self, $node, $frame ) = @_;
  $self->_compile_async_loop( $node, $frame, 1 );
}

# Port-only (ADR 0021), the statement in front of everything a template makes
# that can be called after the render it was made in has delivered its result:
# a macro, a call block (_compile_macro) and the body an extension is handed
# (compile_call_extension). It tells the Context, so that the Context of a
# template that included this one keeps it (Context _made_closure).
sub _emit_made_closure {
  my ($self) = @_;
  $self->_emit_line('$context->_made_closure;');
}

sub _compile_macro {
  my ( $self, $node, $frame ) = @_;
  my @args;
  my $kwargs;
  my $func_id    = 'macro_' . $self->_tmpid;
  my $keep_frame = defined($frame);

  # Type check the definition of the args.
  my $arg_children = $node->args->children;
  for my $i ( 0 .. $#$arg_children ) {
    my $arg = $arg_children->[$i];
    if ( $i == $#$arg_children && $arg->isa( $self->node('Dict') ) ) {
      $kwargs = $arg;
    }
    else {
      $self->assert_type( $arg, $self->node('Symbol') );
      push @args, $arg;
    }
  }

  my @real_names = ( ( map { 'l_' . $_->value } @args ), 'kwargs' );

  # Quoted argument names.
  my @arg_names   = map { $self->_quote( $_->value ) } @args;
  my @kwarg_names = map { $self->_quote( $_->key->value ) }
    @{ ( $kwargs && $kwargs->children ) || [] };

  # A function passed to makeMacro destructures the arguments, so positional
  # args can be set with keyword args and keyword args passed positionally
  # (default values). See runtime.pm.
  my $curr_frame =
    $keep_frame ? $frame->push(1) : $self->frame_class->new;

  $self->_emit_made_closure;
  $self->_emit_lines(
    'my $' . $func_id . ' = $runtime->make_macro(',
    '[' . join( ', ', @arg_names ) . '], ',
    '[' . join( ', ', @kwarg_names ) . '], ',
    'sub {',
    'my (' . join( ', ', map { '$' . $_ } @real_names ) . ') = @_;',
    'my $callerFrame = $frame;',
    '$frame = '
      . ( $keep_frame ? '$frame->push(1);' : '$runtime->Frame->new;' ),
    '$kwargs = $kwargs || {};',
    'if (exists $kwargs->{\'caller\'}) {',
    '$frame->set("caller", $kwargs->{\'caller\'}); }'
  );

  # Expose the arguments to the template. No random names needed -- the sub
  # creates a new run-time scope.
  for my $arg (@args) {
    $self->_emit_line(
      '$frame->set(' . $self->_quote( $arg->value ) . ', $l_' . $arg->value . ');' );
    $curr_frame->set( $arg->value, 'l_' . $arg->value );
  }

  # Expose the keyword arguments.
  if ($kwargs) {
    for my $pair ( @{ $kwargs->children } ) {
      my $name = $pair->key->value;
      $self->_emit( '$frame->set(' . $self->_quote($name) . ', ' );
      $self->_emit( 'exists $kwargs->{' . $self->_quote($name) . '}' );
      $self->_emit( ' ? $kwargs->{' . $self->_quote($name) . '} : ' );
      $self->_compile_expression( $pair->value, $curr_frame );
      $self->_emit(');');
    }
  }

  my $buffer_id = $self->_push_buffer;

  $self->_with_scoped_syntax( sub { $self->compile( $node->body, $curr_frame ) } );

  $self->_emit_line(
    '$frame = ' . ( $keep_frame ? '$frame->pop;' : '$callerFrame;' ) );
  $self->_emit_line( 'return $runtime->SafeString->new($' . $buffer_id . ');' );
  $self->_emit_line('});');
  $self->_pop_buffer;

  return $func_id;
}

sub compile_macro {
  my ( $self, $node, $frame ) = @_;
  my $func_id = $self->_compile_macro($node);

  # Expose the macro to the templates.
  my $name = $node->name->value;
  $frame->set( $name, $func_id );

  if ( $frame->parent ) {
    $self->_emit_line( '$frame->set(' . $self->_quote($name) . ', $' . $func_id . ');' );
  }
  else {
    if ( substr( $node->name->value, 0, 1 ) ne '_' ) {
      $self->_emit_line( '$context->add_export(' . $self->_quote($name) . ');' );
    }
    $self->_emit_line( '$context->set_variable(' . $self->_quote($name) . ', $' . $func_id . ');' );
  }
}

sub compile_caller {
  my ( $self, $node, $frame ) = @_;
  # Basically an anonymous "macro expression".
  $self->_emit('(sub {');
  my $func_id = $self->_compile_macro( $node, $frame );
  $self->_emit( 'return $' . $func_id . ';})->()' );
}

sub _compile_get_template {
  my ( $self, $node, $frame, $eager_compile, $ignore_missing ) = @_;
  my $parent_template_id = $self->_tmpid;
  my $parent_name        = $self->_template_name;
  my $cb                 = $self->_make_callback($parent_template_id);
  my $eager              = $eager_compile  ? '1' : '0';
  my $ignore             = $ignore_missing ? '1' : '0';
  $self->_emit('$env->get_template(');
  $self->_compile_expression( $node->template, $frame );
  $self->_emit_line( ', ' . $eager . ', ' . $parent_name . ', ' . $ignore . ', ' . $cb );
  return $parent_template_id;
}

# Port-only (ADR 0021), a statement of an import's getExported callback, in
# both branches of its error check. The macros of the imported template do not
# hold the Context they were made in (see _emit_func_begin); the importing
# Context does, from the third callback argument (Template _get_exported).
#
# A library that failed is kept like one that did not: it may have handed a
# macro out before it failed -- into an array of the importing template, to a
# function of the application -- and the importing template goes on after the
# error with whatever follows the `if`, the `for`, the macro call or the `set`
# block the import stands in.
sub _keep_alive_statement {
  my ($self) = @_;
  return '$context->_keep_alive($_[2]);';
}

sub _emit_keep_alive {
  my ($self) = @_;
  $self->_emit_line( $self->_keep_alive_statement );
}

sub compile_import {
  my ( $self, $node, $frame ) = @_;
  my $target = $node->target->value;
  my $id     = $self->_compile_get_template( $node, $frame, 0, 0 );
  $self->_add_scope_level;

  $self->_emit_line( '$' . $id . '->_get_exported('
      . ( $node->withContext ? '$context->get_variables(), $frame, ' : '' )
      . $self->_make_callback( $id, 0, $self->_keep_alive_statement . ' ' ) );
  $self->_emit_keep_alive;
  $self->_add_scope_level;

  $frame->set( $target, $id );

  if ( $frame->parent ) {
    $self->_emit_line( '$frame->set(' . $self->_quote($target) . ', $' . $id . ');' );
  }
  else {
    $self->_emit_line( '$context->set_variable(' . $self->_quote($target) . ', $' . $id . ');' );
  }
}

sub compile_from_import {
  my ( $self, $node, $frame ) = @_;
  my $imported_id = $self->_compile_get_template( $node, $frame, 0, 0 );
  $self->_add_scope_level;

  $self->_emit_line( '$' . $imported_id . '->_get_exported('
      . ( $node->withContext ? '$context->get_variables(), $frame, ' : '' )
      . $self->_make_callback( $imported_id, 0, $self->_keep_alive_statement . ' ' ) );
  $self->_emit_keep_alive;
  $self->_add_scope_level;

  for my $name_node ( @{ $node->names->children } ) {
    my ( $name, $alias );
    my $id = $self->_tmpid;

    if ( $name_node->isa( $self->node('Pair') ) ) {
      $name  = $name_node->key->value;
      $alias = $name_node->value->value;
    }
    else {
      $name  = $name_node->value;
      $alias = $name;
    }

    # `var id` is used past the if/else, so hoist the my (JS var-hoist).
    $self->_emit_line( 'my $' . $id . ';' );
    $self->_emit_line( 'if(exists $' . $imported_id . '->{' . $self->_quote($name) . '}) {' );
    $self->_emit_line( '$' . $id . ' = $' . $imported_id . '->{' . $self->_quote($name) . '};' );
    $self->_emit_line('} else {');
    $self->_emit_line( '$cb->(' . $self->error_class . '->new(' . $self->_quote( "cannot import '" . $name . "'" ) . ')); return;' );
    $self->_emit_line('}');

    $frame->set( $alias, $id );

    if ( $frame->parent ) {
      $self->_emit_line( '$frame->set(' . $self->_quote($alias) . ', $' . $id . ');' );
    }
    else {
      $self->_emit_line( '$context->set_variable(' . $self->_quote($alias) . ', $' . $id . ');' );
    }
  }
}

sub compile_block {
  my ( $self, $node ) = @_;
  my $id = $self->_tmpid;

  # Outside a block (a top-level block), don't execute its code -- it would
  # run twice (once here, once when the parent renders). See upstream comment.
  if ( !$self->in_block ) {
    $self->_emit(
      '($parentTemplate ? sub { my (undef, undef, undef, undef, $cb) = @_; $cb->(undef, ""); } : ' );
  }
  $self->_emit( '$context->get_block(' . $self->_quote( $node->name->value ) . ')' );
  if ( !$self->in_block ) {
    $self->_emit(')');
  }
  $self->_emit_line( '->($env, $context, $frame, $runtime, ' . $self->_make_callback( $id, 1 ) );
  $self->_emit_line( '$runtime->js_string_append($' . $self->buffer . ', $' . $id . ');' );
  $self->_add_scope_level(1);
}

sub compile_super {
  my ( $self, $node, $frame ) = @_;
  my $name = $node->blockName->value;
  my $id   = $node->symbol->value;

  my $cb = $self->_make_callback( $id, 1 );
  $self->_emit_line( '$context->get_super($env, ' . $self->_quote($name) . ', $b_' . $name . ', $frame, $runtime, ' . $cb );
  $self->_emit_line( '$' . $id . ' = $runtime->mark_safe($' . $id . ');' );
  $self->_add_scope_level(1);
  $frame->set( $id, $id );
}

sub compile_extends {
  my ( $self, $node, $frame ) = @_;
  my $k = $self->_tmpid;

  my $parent_template_id = $self->_compile_get_template( $node, $frame, 1, 0 );

  # extends is dynamic and can occur within a block like `if`, so capture the
  # parent template in the top-level scope.
  $self->_emit_line( '$parentTemplate = $' . $parent_template_id . ';' );

  $self->_emit_line( 'for my $' . $k . ' (keys %{$parentTemplate->blocks}) {' );
  $self->_emit_line( '$context->add_block($' . $k . ', $parentTemplate->blocks->{$' . $k . '});' );
  $self->_emit_line('}');

  $self->_add_scope_level;
}

sub compile_include {
  my ( $self, $node, $frame ) = @_;
  $self->_emit_line('my @tasks;');
  $self->_emit_line('push @tasks, sub {');
  $self->_emit_line('my ($callback) = @_;');
  my $id = $self->_compile_get_template( $node, $frame, 0, $node->ignoreMissing );
  $self->_emit_line( '$callback->(undef, $' . $id . ');}));' );
  $self->_emit_line('};');

  # Port-only (ADR 0021): the fourth argument of render, after the callback's
  # closers. The included template gets a Context of its own, and nothing
  # holds that once its render has delivered -- but a macro it made can be in
  # the hands of this template by then. So the included Context is told who
  # included it, and this Context takes it over when it has to (Template
  # render, Context _included_by).
  #
  # Port-only (ADR 0021) as well: `undef $callback;` in the error branch of
  # that callback. An error goes to `$cb` and not on through the waterfall, so
  # the waterfall's last callback -- the rest of this template, which holds
  # this Context until it is called -- is never called; upstream's is garbage
  # then. Here a macro of the included template can hold this callback (it is
  # behind the included template's `$cb`, which a macro containing an async
  # construct captures), and this Context keeps the included one, so the two
  # Contexts would hold each other for good. Once the callback has seen an
  # error it never needs `$callback` again: Template render drops every result
  # that comes after an error, and a second error takes this branch again.
  # The statement comes first because `$cb` may die.
  my $id2 = $self->_tmpid;
  $self->_emit_line('push @tasks, sub {');
  $self->_emit_line('my ($template, $callback) = @_;');
  $self->_emit_line( '$template->render($context->get_variables(), $frame, '
      . $self->_make_callback( $id2, 0, 'undef $callback; ' ) );
  $self->_emit_line( '$callback->(undef, $' . $id2 . ');}), $context);' );
  $self->_emit_line('};');

  $self->_emit_line('push @tasks, sub {');
  $self->_emit_line('my ($result, $callback) = @_;');
  $self->_emit_line( '$runtime->js_string_append($' . $self->buffer . ', $result);' );
  $self->_emit_line('$callback->(undef);');
  $self->_emit_line('};');
  $self->_emit_line( '$env->waterfall(\@tasks, ' . $self->_continuation_open );
  $self->_add_scope_level;
}

sub compile_template_data {
  my ( $self, $node, $frame ) = @_;
  $self->compile_literal( $node, $frame );
}

sub compile_capture {
  my ( $self, $node, $frame ) = @_;
  # Temporarily override the buffer id as 'output' so the set block writes to
  # the capture output instead of the buffer.
  my $buffer = $self->buffer;
  $self->buffer('output');
  $self->_emit_line('(sub {');
  $self->_emit_line('my $output = "";');
  $self->_with_scoped_syntax( sub { $self->compile( $node->body, $frame ) } );
  $self->_emit_line('return $output;');
  $self->_emit_line('})->()');
  # Revert back to the old buffer id.
  $self->buffer($buffer);
}

sub compile_output {
  my ( $self, $node, $frame ) = @_;
  my $buffer = $self->buffer;
  for my $child ( @{ $node->children } ) {
    # TemplateData is never autoescaped, so simply output it for optimization.
    if ( $child->isa( $self->node('TemplateData') ) ) {
      my $val = $child->value;
      if ( defined($val) && length($val) ) {    # JS if(child.value): "" falsy, "0" truthy
        $self->_emit( '$runtime->js_string_append($' . $buffer . ', ' );
        $self->compile_literal($child);
        $self->_emit_line(');');
      }
    }
    else {
      # forward note (k14 audit): the append goes through _js_to_string so a
      # raw value from suppress_value (autoescape off) uses number_to_string.
      # `buffer += ...` is js_string_append: it joins in code units (ADR 0012).
      $self->_emit( '$runtime->js_string_append($' . $buffer
          . ', $runtime->_js_to_string($runtime->suppress_value(' );
      $self->_emit('$runtime->ensure_defined(') if $self->throw_on_undefined;
      $self->compile( $child, $frame );
      $self->_emit( ', '
          . $self->_num_or_undef( $node->lineno ) . ', '
          . $self->_num_or_undef( $node->colno ) . ')' )
        if $self->throw_on_undefined;
      $self->_emit( ", \$env->opts->{autoescape})));\n" );
    }
  }
}

sub compile_root {
  my ( $self, $node, $frame ) = @_;
  if ($frame) {
    $self->fail("compileRoot: root node can't have frame");
  }

  $frame = $self->frame_class->new;

  # Collect block names up front: they double as the forward-declared lexicals
  # ($b_<name>) the block subs are assigned to and the returned hashref reads.
  # The dedup check is upstream's ("defined more than once"), moved ahead of
  # emission so the forward declaration is well-formed (it throws either way,
  # same message).
  my $blocks = $node->find_all( $self->node('Block') );
  my @block_names;
  my %seen;
  for my $block (@$blocks) {
    my $name = $block->name->value;
    if ( $seen{$name} ) {
      die $self->error_class->new(
        'Block "' . $name . '" defined more than once.' );
    }
    $seen{$name} = 1;
    push @block_names, $name;
  }

  $self->_emit_line( 'my ($root'
      . join( '', map { ', $b_' . $_ } @block_names ) . ');' );

  $self->_emit_func_begin( $node, 'root' );
  $self->_emit_line('my $parentTemplate;');
  $self->_compile_children( $node, $frame );
  $self->_emit_line('if($parentTemplate) {');
  $self->_emit_line('$parentTemplate->root_render_func($env, $context, $frame, $runtime, $cb);');
  $self->_emit_line('} else {');
  $self->_emit_line( '$cb->(undef, $' . $self->buffer . ');' );
  $self->_emit_line('}');
  $self->_emit_func_end(1);

  $self->in_block(1);

  for my $block (@$blocks) {
    my $name = $block->name->value;

    $self->_emit_func_begin( $block, 'b_' . $name );

    # Port-only (k109). Upstream's `function b_<name>(...)` is a named
    # function: inside its body the name is the function itself, and
    # compile_super passes it to get_super, which finds the block by identity.
    # A Perl anonymous sub has no name, and reading the file-level $b_<name>
    # from inside the sub would make the sub capture the variable that holds
    # it -- a reference cycle that keeps the compiled code of the template
    # alive for the life of the process. So every block sub binds its own name
    # per call; whatever the body emits as $b_<name>, at any closure depth,
    # reads this lexical. CORE:: because the source is eval'd with no feature
    # bundle in scope, and must not depend on who evals it.
    $self->_emit_line( 'my $b_' . $name . ' = CORE::__SUB__;' );

    my $tmp_frame = $self->frame_class->new;
    $self->_emit_line('$frame = $frame->push(1);');
    $self->compile( $block->body, $tmp_frame );
    $self->_emit_func_end;
  }

  $self->_emit_line('+{');

  for my $block (@$blocks) {
    my $block_name = 'b_' . $block->name->value;
    $self->_emit_line( $block_name . ' => $' . $block_name . ',' );
  }

  $self->_emit_line("root => \$root\n};");
}

# typename (CamelCase) -> compile_<snake_case> method name.
sub _method_for {
  my ( $self, $typename ) = @_;
  my $s = $typename;
  $s =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  return 'compile_' . lc($s);
}

sub compile {
  my ( $self, $node, $frame ) = @_;
  my $method = $self->_method_for( $node->typename );
  if ( $self->can($method) ) {
    $self->$method( $node, $frame );
  }
  else {
    $self->fail( 'compile: Cannot compile node: ' . $node->typename,
      $node->lineno, $node->colno );
  }
}

sub get_code {
  my ($self) = @_;
  return join( '', @{ $self->codebuf } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Compiler::Compiler - The code generator, emitting Perl source (compiler.js class Compiler)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: upstream's exported C<Compiler> class, reachable as
C<< Text::Nunjucks::Compiler->compiler_class >>. It walks a transformed AST and
emits the Perl source of a template (ADR 0003); L<Text::Nunjucks::Compiler>'s
C<compile> drives it. See L<Text::Nunjucks::Compiler>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
