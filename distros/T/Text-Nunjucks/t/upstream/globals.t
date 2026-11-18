#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw( blessed );
use builtin qw( true false );
use FindBin;
use lib "$FindBin::Bin/../lib";

no warnings 'experimental::builtin';

# Port of upstream/nunjucks/tests/globals.js (describe('global', ...)), k36.
# One subtest per upstream it(), same title, same order. 11 it() upstream,
# 11 it() subtests here.
#
# TODO scheme (as t/upstream/filters.t, k34): an it() that fails today is marked
# TODO through the %TODO table, keyed by the upstream it() title, with a reason
# naming the card. Every assertion runs; a TODO that starts passing shows up as
# "unexpectedly succeeded" and the entry is dropped. Nested TODO blocks mark
# single assertions that wait on a decision or a recorded divergence (ADR 0009).
#
# util.js notes: a local non-dying equal() (render with noThrow, then is())
# replaces Test::Nunjucks::Util::equal, which croaks on a render error and would
# abort the file; finish(done) is never ported.
#
# JS -> Perl: addGlobal -> add_global, getGlobal -> get_global; a JS function is
# a coderef; `expect(fn).to.throwError()` is dies_ok-style eval; the JS `Error`
# check is a blessed Text::Nunjucks error / any die.

plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import('render');
require Text::Nunjucks::Runtime;

sub err_message {
  my ($err) = @_;
  return '' unless defined $err;
  return ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
}

# equal(str, [ctx,] expected [, env]) as in util.js: the optional env is last.
sub equal {
  my ( $template, @rest ) = @_;
  my ( $ctx, $env, $expected );
  $env = pop @rest if @rest && blessed( $rest[-1] ) && $rest[-1]->isa('Text::Nunjucks::Environment');
  if    ( @rest == 1 ) { ($expected)         = @rest }
  elsif ( @rest == 2 ) { ( $ctx, $expected ) = @rest }
  else                 { die 'equal: wrong number of arguments' }
  my ( $err, $res ) = render( $template, $ctx, { noThrow => 1 }, $env );
  diag( 'render error: ' . err_message($err) ) if $err;
  return is( $res, $expected, $template =~ s/\n/\\n/gr );
}

sub new_env { Text::Nunjucks::Environment->new }

my %TODO;

sub it {
  my ( $title, $code ) = @_;
  subtest $title => sub {
    local $TODO = $TODO{$title};
    $code->();
  };
}

sub describe { my ( $title, $code ) = @_; subtest $title => $code }

describe 'global' => sub {

  it 'should have range' => sub {
    equal( '{% for i in range(0, 10) %}{{ i }}{% endfor %}',      '0123456789' );
    equal( '{% for i in range(10) %}{{ i }}{% endfor %}',         '0123456789' );
    equal( '{% for i in range(5, 10) %}{{ i }}{% endfor %}',      '56789' );
    equal( '{% for i in range(-2, 0) %}{{ i }}{% endfor %}',      '-2-1' );
    equal( '{% for i in range(5, 10, 2) %}{{ i }}{% endfor %}',   '579' );
    equal( '{% for i in range(5, 10, 2.5) %}{{ i }}{% endfor %}', '57.5' );
    equal( '{% for i in range(5, 10, 2.5) %}{{ i }}{% endfor %}', '57.5' );

    equal( '{% for i in range(10, 5, -1) %}{{ i }}{% endfor %}',   '109876' );
    equal( '{% for i in range(10, 5, -2.5) %}{{ i }}{% endfor %}', '107.5' );
  };

  it 'should have cycler' => sub {
    equal(
      '{% set cls = cycler("odd", "even") %}'
        . '{{ cls.next() }}'
        . '{{ cls.next() }}'
        . '{{ cls.next() }}',
      'oddevenodd'
    );

    equal(
      '{% set cls = cycler("odd", "even") %}'
        . '{{ cls.next() }}'
        . '{{ cls.reset() }}'
        . '{{ cls.next() }}',
      'oddodd'
    );

    equal(
      '{% set cls = cycler("odd", "even") %}'
        . '{{ cls.next() }}'
        . '{{ cls.next() }}'
        . '{{ cls.current }}',
      'oddeveneven'
    );
  };

  it 'should have joiner' => sub {
    equal(
      '{% set comma = joiner() %}'
        . 'foo{{ comma() }}bar{{ comma() }}baz{{ comma() }}',
      'foobar,baz,'
    );

    equal(
      '{% set pipe = joiner("|") %}'
        . 'foo{{ pipe() }}bar{{ pipe() }}baz{{ pipe() }}',
      'foobar|baz|'
    );
  };

  it 'should allow addition of globals' => sub {
    my $env = new_env();

    $env->add_global( 'hello', sub { my ($arg1) = @_; 'Hello ' . $arg1 } );

    equal( '{{ hello("World!") }}', 'Hello World!', $env );
  };

  it 'should allow chaining of globals' => sub {
    my $env = new_env();

    $env->add_global( 'hello', sub { my ($arg1) = @_; 'Hello ' . $arg1 } )
      ->add_global( 'goodbye', sub { my ($arg1) = @_; 'Goodbye ' . $arg1 } );

    equal( '{{ hello("World!") }}',   'Hello World!',   $env );
    equal( '{{ goodbye("World!") }}', 'Goodbye World!', $env );
  };

  it 'should allow getting of globals' => sub {
    my $env   = new_env();
    my $hello = sub { my ($arg1) = @_; 'Hello ' . $arg1 };

    $env->add_global( 'hello', $hello );

    is( $env->get_global('hello'), $hello );
  };

  it 'should allow getting boolean globals' => sub {
    my $env   = new_env();
    my $hello = false;

    $env->add_global( 'hello', $hello );

    is( $env->get_global('hello'), $hello );
  };

  it 'should fail on getting non-existent global' => sub {
    my $env = new_env();

    ok( !eval { $env->get_global('hello'); 1 }, 'getGlobal throws' );
  };

  it 'should pass context as this to global functions' => sub {
    my $env = new_env();

    # JS: this.lookup('user') -- a bare coderef gets no `this` (ADR 0009), so
    # there is no Context to look up on; the Perl image is the same coderef
    # reading its first argument (nothing is passed) and the observable
    # divergence is asserted in TODO.
    $env->add_global( 'hello', sub { 'Hello ' . ( blessed( $_[0] ) && $_[0]->can('lookup') ? $_[0]->lookup('user') : '' ) } );

  TODO: {
      local $TODO = 'ADR 0009: a bare coderef global is called with no `this` Context';
      equal( '{{ hello() }}', { user => 'James' }, 'Hello James', $env );
    }
  };

  it 'should be exclusive to each environment' => sub {
    my $env = new_env();

    $env->add_global( 'hello', 'konichiwa' );
    my $env2 = new_env();

    ok( !eval { $env2->get_global('hello'); 1 }, 'env2 getGlobal throws' );
  };

  it 'should return errors from globals' => sub {
    my $env = new_env();

    $env->add_global( 'err', sub { die 'Global error' } );

    # JS: try { render(...) } catch (e) { expect(e).to.be.a(Error) } -- the
    # expectation only runs when render throws (Test::Nunjucks::Util::render
    # croaks, as util.js's does without noThrow); no throw passes silently.
    my $ok = eval { render( '{{ err() }}', undef, {}, $env ); 1 };
    if ( !$ok ) {
      my $e = $@;
      ok( blessed($e) && $e->isa('Text::Nunjucks::Lib::Error'), 'the error is an Error' );
    }
    else {
      pass('render did not throw (upstream asserts nothing then either)');
    }
  };
};

done_testing;
