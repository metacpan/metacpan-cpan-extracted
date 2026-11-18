#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny ();
use JSON::MaybeXS ();

use Text::Nunjucks::Environment;
use Text::Nunjucks::Loader;

# Port-only (k83): a render prints no "Deep recursion" warning. The compiled
# code keeps upstream's callback shape (ADR 0003), so whatever upstream runs
# one after another through callbacks -- sequential includes and imports, the
# items of an asyncEach, the levels of a template that includes itself -- nests
# one Perl call per step, as it nests one JavaScript call per step upstream.
# So do upstream's recursive Frame lookup over a deep chain of frames and a
# macro that calls itself. Perl warns when one sub is entered the 100th time
# without having returned; JavaScript has no such warning (upstream stops with
# a RangeError far deeper). The port switches the warning off with a
# commented `no warnings 'recursion'` at each call site that recurses per
# step; each case below goes through at least one of them:
#
#   Environment get_template   the async_iter over the loaders
#   Template render            the call of a cached template's root
#   Template _get_exported     the same, for import / from-import
#   Template root_render_func  a cached parent's root (extends)
#   Context get_super          a cached parent's block (super())
#   Lib async_iter, async_for  the iterator, once per item
#   Runtime async_each         the loop body, and async_iter / async_for
#   Frame lookup, resolve      the parent frame, once per frame up the chain
#   Runtime make_macro         a macro's body, once per level
#   Runtime call_wrap          the macro, once per level
#
# The Frame cases are only as deep as it takes to cross 100 frames, because
# an uncached self-include compiles its template again at every level.
#
# What each case renders is in t/corpus/render-deep-recursion.json, written by
# maint/corpus-regen from the oracle; t/corpus.t compares the output there.
# This file renders the same cases twice more under a $SIG{__WARN__} that
# keeps every warning: through a loader that does not cache (noCache, as the
# corpus and the oracle do), which takes the get_template path for every
# include, and through one that caches, rendered twice on one Environment,
# which runs the cached templates' compiled code. The output must be the
# oracle's each time, and no warning may come.

my $cases = JSON::MaybeXS->new( utf8 => 1 )->decode(
  Path::Tiny->new(__FILE__)->parent->child( 'corpus', 'render-deep-recursion.json' )->slurp_raw );

{
  package T::MemLoader;
  use Moo;
  extends 'Text::Nunjucks::Loader';
  has templates => ( is => 'ro', default => sub { {} } );
  has no_cache  => ( is => 'ro', default => sub { 1 } );
  sub get_source {
    my ( $self, $name ) = @_;
    return undef unless exists $self->templates->{$name};
    return { src => $self->templates->{$name}, path => $name, noCache => $self->no_cache };
  }
}

sub render_case {
  my ( $env, $c ) = @_;
  my ( $err, $res );
  my $cb = sub { ( $err, $res ) = @_ };
  if ( defined $c->{render} ) {
    $env->render( $c->{render}, $c->{context} // {}, $cb );
  }
  else {
    $env->render_string( $c->{template}, $c->{context} // {}, $cb );
  }
  die $err if $err;
  return $res;
}

for my $c (@$cases) {
  subtest $c->{name} => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $env = Text::Nunjucks::Environment->new(
      T::MemLoader->new( templates => $c->{templates} // {}, no_cache => 1 ) );
    is( render_case( $env, $c ), $c->{expected}{output}, 'noCache loader: the oracle\'s output' );
    is_deeply( [ splice @warnings ], [], 'noCache loader: no warning' );

    $env = Text::Nunjucks::Environment->new(
      T::MemLoader->new( templates => $c->{templates} // {}, no_cache => 0 ) );
    for my $pass ( 'first', 'cached' ) {
      is( render_case( $env, $c ), $c->{expected}{output}, "caching loader, $pass render: the oracle's output" );
      is_deeply( [ splice @warnings ], [], "caching loader, $pass render: no warning" );
    }
  };
}

done_testing;
