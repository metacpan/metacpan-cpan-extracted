#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use builtin qw( true false );

no warnings 'experimental::builtin';

use Text::Nunjucks::Compiler;
use Text::Nunjucks::Runtime;

# End-to-end compiler tests. The compiler emits Perl source (ADR 0003 keeps the
# CPS shape); this drives the whole pipeline:
#   template -> Parser (k12) -> Transformer (k13) -> Compiler (k15)
#           -> string eval -> run root() with Runtime (k14) + the stub below
#           -> output, compared to the oracle-committed corpus expected.
# The Environment/Context here is a *minimal stub* -- the real ones land with
# k16. It provides what the emitted code calls on them for these cases:
# opts/get_filter/get_test, and lookup/set_variable/get_variables/add_export
# plus the port-only _made_closure, which the code calls before it makes a
# macro or a call block and before it hands a body to an extension (ADR 0021).
#
# That is not all the emitted code calls. The first statement of every root
# and block sub is $runtime->_render_scope(\$context, \$frame), and every
# continuation is made by $runtime->_continuation(...) (both ADR 0021). The
# stub has no _track_scope, so _render_scope returns at once: nothing is
# weakened, nothing is registered, and every closure holds the stub strongly.
# This file deliberately runs the emitted code WITHOUT the lifetime mechanism;
# that mechanism is tested with the real Context in t/10-leaks.t and
# t/10-macro-lifetime.t.

{
  package T::Ctx;
  sub new { my ( $c, $vars ) = @_; bless { vars => { %{ $vars // {} } }, exported => {} }, $c }
  sub lookup { my ( $s, $n ) = @_; exists $s->{vars}{$n} ? $s->{vars}{$n} : undef }
  sub set_variable { my ( $s, $n, $v ) = @_; $s->{vars}{$n} = $v; return }
  sub get_variables { $_[0]->{vars} }
  sub add_export { my ( $s, $n ) = @_; $s->{exported}{$n} = 1; return }
  sub _made_closure { return }
}
{
  package T::Env;
  sub new { my ( $c, %a ) = @_; bless { opts => $a{opts} // {}, filters => $a{filters} // {}, tests => $a{tests} // {} }, $c }
  sub opts       { $_[0]->{opts} }
  sub get_filter { my ( $s, $n ) = @_; $s->{filters}{$n} // die "no filter: $n" }
  sub get_test   { my ( $s, $n ) = @_; $s->{tests}{$n}   // die "no test: $n" }
}

my $RT        = 'Text::Nunjucks::Runtime';
my $JSON_BOOL = ref( JSON::MaybeXS::true() );
my $JT        = JSON::MaybeXS::true();
my $JF        = JSON::MaybeXS::false();

my $CANON = JSON::MaybeXS->new(
  canonical       => 1,
  convert_blessed => 1,
  allow_nonref    => 1,
  utf8            => 0,
);
sub canon { $CANON->encode( $_[0] ) }

# Normalise a JSON-decoded context into the port's value model (ADR 0001/0006):
# JSON booleans -> builtin booleans, JSON null (undef) -> None sentinel. This is
# the boundary normalisation the real Environment will own (k16).
sub normalize {
  my ($v) = @_;
  return $RT->None unless defined $v;
  if ( blessed($v) && ref($v) eq $JSON_BOOL ) { return $v ? true : false }
  if ( ref $v eq 'ARRAY' ) { return [ map { normalize($_) } @$v ] }
  if ( ref $v eq 'HASH' )  { return { map { ( $_ => normalize( $v->{$_} ) ) } keys %$v } }
  return $v;
}

# A few built-in-ish tests the corpus cases reach; the full set lands in k18.
sub stub_tests {
  return {
    # `is none` compiles to get_test("null") -- upstream registers it as `null`.
    null => sub { $RT->_is_none( $_[0] ) ? true : false },
    odd  => sub { ( $_[0] % 2 != 0 ) ? true : false },
    even => sub { ( $_[0] % 2 == 0 ) ? true : false },
  };
}

sub error_result {
  my ($err) = @_;
  if ( blessed($err) && $err->can('name') && $err->can('message') ) {
    return { ok => $JF, error => { name => $err->name, message => $err->message } };
  }
  die $err;
}

# Render one case through compiler + stub; return the oracle result shape.
sub render_case {
  my ( $case, $extra_filters ) = @_;

  my $opts = { %{ $case->{opts} // {} } };
  $opts->{autoescape} =
    exists $opts->{autoescape}
    ? ( $opts->{autoescape} ? 1 : 0 )
    : 1;    # autoescape ON by default (upstream)

  my $ctx = normalize( $case->{context} // {} );

  my $src = eval {
    Text::Nunjucks::Compiler->compile( $case->{template}, [], undef, undef, $opts );
  };
  return error_result($@) if $@;

  my $props = eval $src;
  if ($@) {
    die "emitted Perl failed to eval for '$case->{name}':\n$@\n--- SOURCE ---\n$src\n";
  }

  my $env = T::Env->new(
    opts    => $opts,
    filters => $extra_filters // {},
    tests   => stub_tests(),
  );
  my $context = T::Ctx->new($ctx);
  my $frame   = $RT->Frame->new;
  $frame->top_level(1);

  my ( $out, $err, $called );
  $props->{root}->(
    $env, $context, $frame, $RT,
    sub {
      my ( $e, $r ) = @_;
      $called = 1;
      if ($e) { $err = $e }
      else    { $out = $r }
    }
  );
  die "root() callback never fired for '$case->{name}' (deferred?)" unless $called;
  return error_result($err) if defined $err;
  return { ok => $JT, output => $out };
}

#### 1) replay the oracle-grounded render corpus through the compiler + stub

my $corpus = path(__FILE__)->parent->child('corpus')->child('render-compiler.json');
my $cases  = JSON::MaybeXS->new( utf8 => 1 )->decode( $corpus->slurp_raw );

for my $case (@$cases) {
  my $got = render_case($case);
  is( canon($got), canon( $case->{expected} ),
    "render-compiler: $case->{name}" );
}

#### 2) compile-smoke: every remaining node type emits eval-able Perl
# These need the full Environment/loader (k16) to run, but the *compiler* must
# emit syntactically valid Perl for them now. eval $src must yield the props
# hashref (root + any b_<name>), proving the emission is well-formed.

my @smoke = (
  [ 'block',           '{% block a %}x{% endblock %}',                                   [qw( b_a root )] ],
  [ 'extends+block',   '{% extends "base.njk" %}{% block a %}x{% endblock %}',           [qw( b_a root )] ],
  [ 'super',           '{% extends "b.njk" %}{% block a %}{{ super() }}Z{% endblock %}', [qw( b_a root )] ],
  [ 'include',         '{% include "x.njk" %}',                                          [qw( root )] ],
  [ 'include ignore',  '{% include "x.njk" ignore missing %}',                           [qw( root )] ],
  [ 'import',          '{% import "x.njk" as i %}{{ i.foo() }}',                          [qw( root )] ],
  [ 'from import',     '{% from "x.njk" import foo as baz, bar %}{{ baz() }}{{ bar }}',   [qw( root )] ],
  [ 'call block',      '{% macro w(el) %}<{{el}}>{{ caller() }}</{{el}}>{% endmacro %}{% call w("d") %}hi{% endcall %}', [qw( root )] ],
  [ 'call with args',  '{% call(item) lister(["a","b"]) %}{{ item }}{% endcall %}',       [qw( root )] ],
  [ 'filter block',    '{% filter upper %}hey{% endfilter %}',                            [qw( root )] ],
  [ 'filter with arg', '{{ x | join(",") }}',                                             [qw( root )] ],
  [ 'block set',       '{% set foo %}captured{% endset %}{{ foo }}',                      [qw( root )] ],
  [ 'nested blocks',   '{% block a %}{% block b %}z{% endblock %}{% endblock %}',         [qw( b_a b_b root )] ],
);

for my $s (@smoke) {
  my ( $label, $tmpl, $keys ) = @$s;
  my $src = eval {
    Text::Nunjucks::Compiler->compile( $tmpl, [], undef, 'tmpl.njk', {} );
  };
  ok( !$@ && defined $src, "compile-smoke compiles: $label" ) or diag $@;

  my $props = eval $src;
  ok( !$@ && ref $props eq 'HASH', "compile-smoke emits eval-able Perl: $label" )
    or diag "$@\n--- SOURCE ---\n$src";
  is_deeply( [ sort keys %$props ], $keys, "compile-smoke props keys: $label" );
}

#### 3) duplicate block is a compile error (upstream message)

{
  my $src = eval {
    Text::Nunjucks::Compiler->compile(
      '{% block t %}{% endblock %}{% block t %}{% endblock %}',
      [], undef, undef, {} );
  };
  my $err = $@;
  ok( $err, 'duplicate block name throws at compile time' );
  my $msg = ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
  like( $msg, qr/Block "t" defined more than once\./,
    'duplicate block error message matches upstream' );
}

#### 4) filter/test registration mechanism (the surface k16/k17/k18 build on)

{
  # a custom filter with args is invoked with (@args), no `this` (ADR 0009)
  my $got = render_case(
    { name => 'custom filter', template => '{{ foo | wrap("[", "]") }}', context => { foo => 'hi' } },
    { wrap => sub { my ( $s, $l, $r ) = @_; $l . $s . $r } }
  );
  is( $got->{output}, '[hi]', 'registered filter invoked with args, no this' );
}

{
  # a custom test used in a python-style ternary
  my $got = render_case(
    { name => 'custom test', template => '{{ "y" if n is odd else "n" }}', context => { n => 3 } }
  );
  is( $got->{output}, 'y', 'registered test invoked via is-operator' );
}

done_testing;
