#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed weaken );
use builtin qw( true false );

no warnings 'experimental::builtin';

# Perl-side API tests for the Environment/Context/Template/Loader surface ported
# in k16 that the render corpus does not exercise: the registration methods and
# their exact (upstream-text) errors, globals, extensions, and the on/emit event
# surface. Behaviour that the oracle grounds (rendering, tests, inheritance)
# lives in t/corpus/*.json, not here.

use Text::Nunjucks::Environment;
use Text::Nunjucks::Loader;
use Text::Nunjucks::Runtime;

sub msg { my ($e) = @_; blessed($e) && $e->can('message') ? $e->message : "$e" }

#### render API -- sync return and callback form

subtest 'render_string sync and callback forms' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );

  is( $env->render_string( 'Hi {{ x }}', { x => 'there' } ), 'Hi there', 'sync return' );

  my ( $err, $res );
  $env->render_string( '{{ 1 + 1 }}', {}, sub { ( $err, $res ) = @_ } );
  is( $err, undef, 'callback: no error' );
  is( $res, '2',   'callback: result' );
};

subtest 'render_string reports a template error through the callback' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );
  my ( $err, $res );
  $env->render_string( '{% foo %}', {}, sub { ( $err, $res ) = @_ } );
  ok( $err, 'callback received an error' );
  is( $err->name, 'Template render error', 'error name is the Nunjucks name' );
  like( $err->message, qr/unknown block tag: foo/, 'message carries the cause' );
  like( $err->message, qr/\Q(unknown path) [Line 1, Column 4]\E/, 'positioned message' );
};

#### filters / tests registration + not-found errors (upstream message text)

subtest 'add_filter / get_filter' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );
  is( $env->add_filter( 'shout', sub { uc $_[0] } ), $env, 'add_filter returns self' );
  is( $env->render_string( '{{ "hi" | shout }}', {} ), 'HI', 'custom filter runs' );

  my $err;
  eval { $env->get_filter('nope'); 1 } or $err = $@;
  is( msg($err), 'filter not found: nope', 'get_filter throws upstream text' );
};

# The built-in filter bag holds the Environment in the closures of the filters
# that read this.env (groupby, select, reject, sort); Filters exports weakens it,
# else Environment -> filters -> closure -> Environment is a cycle Perl never
# frees. No upstream counterpart: JS collects cycles.
subtest 'the built-in filters do not keep their Environment alive' => sub {
  my $env  = Text::Nunjucks::Environment->new;
  my $weak = $env;
  weaken($weak);
  undef $env;
  ok( !defined $weak, 'a fresh Environment is freed once dropped' );

  $env = Text::Nunjucks::Environment->new;
  is( $env->render_string(
      q{{{ [1, 0, 2]|select|join(',') }} {{ [1, 0]|reject|join }} {{ [{'a': 1}]|groupby('a')|dump|safe }} {{ [2, 1]|sort|join }}},
      {} ),
    '1,2 0 {"1":[{"a":1}]} 12', 'the filters that read this.env ran' );
  $weak = $env;
  weaken($weak);
  undef $env;
  ok( !defined $weak, '... and it is freed after a render through them' );
};

subtest 'add_test / get_test' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );
  $env->add_test( 'big', sub { $_[0] > 100 ? true : false } );
  is( $env->render_string( '{{ 200 is big }}{{ 5 is big }}', {} ), 'truefalse', 'custom test runs' );

  # built-in tests are registered by init (Text::Nunjucks::Tests)
  is( $env->render_string( '{{ 5 is odd }}', {} ), 'true', 'built-in test present' );

  my $err;
  eval { $env->get_test('nope'); 1 } or $err = $@;
  is( msg($err), 'test not found: nope', 'get_test throws upstream text' );
};

# tests.js's functions are module-level, so every Environment registers the
# same ones (environment.js: lib._entries(tests).forEach(... addTest ...)).
subtest 'the built-in tests are the same functions in every Environment' => sub {
  my $env  = Text::Nunjucks::Environment->new;
  my $env2 = Text::Nunjucks::Environment->new;
  is( $env->get_test('odd'), $env2->get_test('odd'), 'two Environments, one odd' );
  is( $env->get_test($_), $env->get_test('equalto'), "$_ is equalto" ) for qw( eq sameas );
  is( $env->get_test('gt'), $env->get_test('greaterthan'), 'gt is greaterthan' );
  is( $env->get_test('lt'), $env->get_test('lessthan'), 'lt is lessthan' );
  my ( $bag, $bag2 ) = map { Text::Nunjucks::Tests->exports } 1 .. 2;
  isnt( $bag, $bag2, 'exports hands out a fresh hash per call' );
  is( $bag->{odd}, $bag2->{odd}, '... of the same coderefs' );
};

#### globals

subtest 'add_global / get_global' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );
  is( $env->add_global( 'site', 'acme' ), $env, 'add_global returns self' );
  is( $env->get_global('site'), 'acme', 'get_global reads it back' );
  is( $env->render_string( '{{ site }}', {} ), 'acme', 'global visible in template' );
  is( $env->render_string( '{{ site }}', { site => 'local' } ), 'local', 'ctx shadows global' );

  my $err;
  eval { $env->get_global('missing'); 1 } or $err = $@;
  is( msg($err), 'global not found: missing', 'get_global throws upstream text' );
};

# globals.js's globals() builds a fresh bag per call, so each Environment owns
# its range / cycler / joiner (environment.js: this.globals = globals()).
subtest 'the built-in globals are a fresh bag per Environment' => sub {
  my $env  = Text::Nunjucks::Environment->new;
  my $env2 = Text::Nunjucks::Environment->new;
  is_deeply( [ sort keys %{ $env->globals } ], [qw( cycler joiner range )], 'range, cycler, joiner' );
  isnt( $env->globals, $env2->globals, 'two Environments, two bags' );
  $env->add_global( 'range', 'mine' );
  is( $env2->render_string( '{{ range(3) }}', {} ), '0,1,2', 'add_global on one leaves the other alone' );
};

# A cycler's methods close over the cycler through a weakened copy -- the
# interim choice while decision k93 is open (ADR 0009 covers user coderefs
# only); the cycler holds the methods, so a strong copy would be a cycle Perl
# never frees. No upstream counterpart: JS collects cycles.
subtest 'a cycler is freed with its last reference' => sub {
  my $env = Text::Nunjucks::Environment->new;
  my $cls = $env->get_global('cycler')->( 'odd', 'even' );
  my $weak = $cls;
  weaken($weak);
  is( $cls->get('next')->(), 'odd', 'next() steps' );
  is( $cls->get('current'), 'odd', '... and sets current' );
  my $next = $cls->get('next');
  undef $cls;
  ok( !defined $weak, 'the cycler is freed once dropped' );
  is( $next->(), 'even', 'a next() kept past its cycler still steps' );
};

#### extensions

subtest 'extensions add / has / get / remove' => sub {
  my $env = Text::Nunjucks::Environment->new( undef, {} );
  my $ext = {};
  is( $env->has_extension('e'), 0, 'not present initially' );
  is( $env->add_extension( 'e', $ext ), $env, 'add_extension returns self' );
  is( $env->has_extension('e'), 1, 'present after add' );
  is( $env->get_extension('e'), $ext, 'get_extension returns it' );
  is( $ext->{__name}, 'e', '__name stamped on the extension' );
  is_deeply( $env->extensions_list, [$ext], 'extensions_list has it' );

  $env->remove_extension('e');
  is( $env->has_extension('e'), 0, 'gone after remove' );
  is_deeply( $env->extensions_list, [], 'extensions_list emptied' );
};

#### the output buffer joins in UTF-16 code units (ADR 0012)

# Every `buffer += value` the compiler emits is Runtime js_string_append, which
# re-pairs a lone high surrogate at the buffer's end with a lone low one at the
# start of what is appended. t/corpus/render-strings-utf16.json pins the
# expression, block, include, caller, asyncEach and asyncAll appends; a lone
# surrogate in a template literal or an extension's result has no JSON form, so
# those appends are asserted here, each confirmed in node.
{
  package T::LoExtension;    # {% lo 1 %}: CallExtension(Async) whose run gives a lone low surrogate
  sub new        { my ( $class, $async ) = @_; bless { async => $async }, $class }
  sub tags       { ['lo'] }
  sub autoescape { undef }
  sub __name     { my $self = shift; $self->{__name} = shift if @_; return $self->{__name} }
  sub parse {
    my ( $self, $parser, $nodes ) = @_;
    my $tok  = $parser->next_token;
    my $args = $parser->parse_signature( undef, 1 );
    $parser->advance_after_block_end( $tok->value );
    my $class = $nodes . '::' . ( $self->{async} ? 'CallExtensionAsync' : 'CallExtension' );
    return $class->new( $self, 'run', $args );
  }
  sub run {
    my ( $self, $context, @args ) = @_;
    return "\x{DE00}" unless $self->{async};
    my $cb = pop @args;
    $cb->( undef, "\x{DE00}" );
    return;
  }
}

subtest 'output appends re-pair a split surrogate pair' => sub {
  my $em = "\x{1F600}";
  # node: renderString('{{ hi }}\ude00x', {hi: '\ud83d'}) -> d83d de00 78, 2 code points
  is( Text::Nunjucks::Environment->new->render_string( "{{ hi }}\x{DE00}x", { hi => "\x{D83D}" } ),
    "${em}x", 'a template literal starting with a low surrogate' );
  # node: renderString('a\ud83d{{ lo }}', {lo: '\ude00'}) -> 61 d83d de00
  is( Text::Nunjucks::Environment->new->render_string( "a\x{D83D}{{ lo }}", { lo => "\x{DE00}" } ),
    "a${em}", 'an expression after a literal ending in a high surrogate' );

  # node: an extension {% lo 1 %} whose run returns '\ude00' (sync) or cb(null,
  # '\ude00') (CallExtensionAsync) after {{ hi }}: d83d de00 78 either way
  for my $async ( 0, 1 ) {
    my $env = Text::Nunjucks::Environment->new;
    $env->add_extension( 'E', T::LoExtension->new($async) );
    is( $env->render_string( '{{ hi }}{% lo 1 %}x', { hi => "\x{D83D}" } ),
      "${em}x", ( $async ? 'CallExtensionAsync' : 'CallExtension' ) . ' result' );
  }
};

#### loader event surface (on/emit): loader emits -> Environment re-emits

subtest 'loader on/emit propagates to the Environment' => sub {
  my $loader = Text::Nunjucks::Loader->new;
  my $env    = Text::Nunjucks::Environment->new( [$loader], {} );

  my @updates;
  $env->on( 'update', sub { push @updates, [@_] } );
  my @loads;
  $env->on( 'load', sub { push @loads, [@_] } );

  # _init_loaders wired loader.on('update'|'load') -> env.emit(...); reset cache
  # first so we can observe the cache-busting the 'update' listener performs.
  $loader->cache->{'a.njk'} = 'cached';
  $loader->emit( 'update', 'a.njk', '/abs/a.njk' );
  is( scalar @updates, 1, 'env re-emitted update' );
  is( $updates[0][0], 'a.njk', 'update name forwarded' );
  is( $updates[0][1], '/abs/a.njk', 'update fullname forwarded' );
  is( $updates[0][2], $loader, 'update carries the loader' );
  ok( !defined $loader->cache->{'a.njk'}, 'update listener busted the cache entry' );

  $loader->emit( 'load', 'b.njk', 'body' );
  is( scalar @loads, 1, 'env re-emitted load' );
  is( $loads[0][1], 'body', 'load source forwarded' );
};

#### loader base: is_relative

subtest 'Loader is_relative' => sub {
  my $loader = Text::Nunjucks::Loader->new;
  is( $loader->is_relative('./x.njk'),  1, './ is relative' );
  is( $loader->is_relative('../x.njk'), 1, '../ is relative' );
  is( $loader->is_relative('x.njk'),    0, 'plain name is not relative' );
};

done_testing;
