#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken blessed );
use Path::Tiny ();
use JSON::MaybeXS ();

use Text::Nunjucks::Environment;
use Text::Nunjucks::Context;
use Text::Nunjucks::Loader;

# Port-only pins for what a render does AFTER an included template failed
# (k108, third round). The included template makes a closure (a macro, a
# macro holding an include) and then fails; the render callback gets the
# error. In JavaScript nothing more is at stake. In the port the Context of the
# included render is kept alive by what the includer holds, and the error
# branch of the include's render callback drops that hold (one emitted
# statement, `undef $callback;`). The first idea for the fix was "no hand-over
# when the included render delivers an error"; it passes the leak tests and
# changes what the TEMPLATE does: the code after an if / for / macro call /
# set capture around a failing include, and the next iteration of a for loop,
# still run after the error callback upstream, and with that idea they die with
# "its Context is gone" and call the render callback a second time. The
# 'after' group below is what such a fix would break.
#
# Every expectation is in t/data/include-failure.json, written by
# maint/include-failure-fixtures from real upstream (nunjucks v3.2.4):
# env.render('main.njk', context, callback) on a memory loader, with async
# filters `later` (parks its callback; answered one per macrotask, in order)
# and `twice` (parks two answers, the second one a second call of the same
# callback) and a global `note` that records its argument. What this test
# compares for each case is
#   - the calls of the render callback (the error text, the output), in order,
#   - the arguments the template passed to note(),
#   - that no parked answer died,
# plus, port-only, that no Context is left alive afterwards (t/10-leaks.t
# holds the larger leak matrix over the same data).
# The oracle cannot take a callback or defer, so this is not a corpus case;
# the filter-free shapes of these templates are in
# t/corpus/render-include-failure.json.

my $data = JSON::MaybeXS->new( utf8 => 1 )->decode( Path::Tiny->new( __FILE__ )->parent->child( 'data', 'include-failure.json' )->slurp_raw );

{
  package T::MemLoader;
  use Moo;
  extends 'Text::Nunjucks::Loader';
  has templates => ( is => 'ro', default => sub { {} } );
  sub get_source {
    my ( $self, $name ) = @_;
    return undef unless exists $self->templates->{$name};
    return { src => $self->templates->{$name}, path => $name, noCache => 1 };
  }
}

my @ctxs;
{
  no strict 'refs';
  no warnings 'redefine';
  my $orig = Text::Nunjucks::Context->can('new');
  *{'Text::Nunjucks::Context::new'} = sub {
    my $obj = $orig->(@_);
    push @ctxs, $obj;
    weaken( $ctxs[-1] );
    return $obj;
  };
}
sub live_contexts { scalar grep { defined } @ctxs }

sub msg {
  my $e = shift;
  return undef unless defined $e;
  return ( blessed($e) && $e->can('message') ) ? $e->message : "$e";
}

# Render main.njk the way the fixture generator does and report what happened.
sub run_case {
  my ($c) = @_;
  my $env = Text::Nunjucks::Environment->new( T::MemLoader->new( templates => $c->{templates} ) );
  my ( @q, @notes, @marks, @kept, @calls, @died );
  $env->add_filter( later => sub { my ( $v, $cb ) = @_; $v //= 'undefined'; push @q, sub { $cb->( undef, "<$v>" ) }; return }, 1 );
  $env->add_filter( af    => sub { my ( $v, $cb ) = @_; $v //= 'undefined'; $cb->( undef, "<$v>" ) }, 1 );
  $env->add_filter(
    twice => sub {
      my ( $v, $cb ) = @_;
      $v //= 'undefined';
      push @q, sub { $cb->( undef, "<$v>" ) }, sub { $cb->( undef, "<$v again>" ) };
      return;
    },
    1
  );
  $env->add_global( note     => sub { push @notes, "$_[0]"; return '' } );
  $env->add_global( mark     => sub { push @marks, join( ',', map { defined $_ ? "$_" : 'undef' } @_ ); return '' } );
  $env->add_global( reg      => sub { push @kept, $_[0]; return '' } );
  $env->add_global( regc     => sub { push @kept, $_[-1]{caller}; return '' } );
  $env->add_global( callkept => sub { return join '', map { $_->() . '' } @kept } );
  $env->add_global( callreg  => sub { return '' } );

  @ctxs = ();
  my $threw;
  eval {
    $env->render( 'main.njk', $c->{context}, sub { push @calls, [ msg( $_[0] ), defined $_[1] ? "$_[1]" : undef ] } );
    1;
  } or $threw = msg($@);
  while ( my $job = shift @q ) {
    eval { $job->(); 1 } or push @died, msg($@);
  }
  @kept = ();
  return { calls => \@calls, notes => \@notes, marks => \@marks, died => \@died, threw => $threw, live => live_contexts() };
}

sub check_case {
  my ($c) = @_;
  my $name = $c->{name};
  my $got  = run_case($c);
  is( scalar @{ $got->{calls} }, scalar @{ $c->{calls} },
    "$name: the render callback is called " . scalar( @{ $c->{calls} } ) . ' time(s), as upstream does' );
  is_deeply( $got->{calls}, $c->{calls}, "$name: the error and the output of every call equal upstream's" );
  is_deeply( $got->{notes}, $c->{notes}, "$name: the template code after the failure ran like upstream (note() calls)" );
  is_deeply( $got->{marks}, $c->{marks}, "$name: the marks of the template (mark() calls) equal upstream's" );
  is_deeply( $got->{died}, $c->{died}, "$name: no parked answer died" );
  is( $got->{threw}, $c->{threw}, "$name: render itself threw nothing" );
  if ( $c->{name} =~ /^async(?:All|Each): .*\[macro w\/ include\]$/ ) {
    TODO: {
      local $TODO = 'k121: an included template that hands a macro containing an async construct to the includer and then fails inside asyncAll / asyncEach keeps its Contexts alive';
      is( $got->{live}, 0, "$name: no live Context afterwards" );
    }
  }
  else {
    is( $got->{live}, 0, "$name: no live Context afterwards" );
  }
}

my %by;
push @{ $by{ $_->{group} } }, $_ for @{ $data->{cases} };

# ---------------------------------------------------------------------------
# Template code after the failing include. What a "no hand-over on error" fix
# would break: the macro a failed included template made and pushed into the
# includer's array is still called by the includer's tail.
# ---------------------------------------------------------------------------
subtest 'after a failing include: the code behind it still runs like upstream' => sub {
  is( scalar @{ $by{after} }, 18, 'the 18 shapes' );
  for my $c ( @{ $by{after} } ) {
    subtest $c->{name} => sub { check_case($c) };
  }
};

# ---------------------------------------------------------------------------
# An async filter answering twice around a failing include
# ---------------------------------------------------------------------------
subtest 'double answers around a failing include' => sub {
  is( scalar @{ $by{twice} }, 4, 'the 4 shapes' );
  for my $c ( @{ $by{twice} } ) {
    subtest $c->{name} => sub { check_case($c) };
  }
};

# ---------------------------------------------------------------------------
# A library that fails AFTER it handed a macro out (k108, round 4). An import
# is a render of the library through getExported; when it fails, the importing
# template still goes on with whatever follows the if / for / macro call /
# block it stands in (upstream calls the render callback with the error and
# the code behind it still runs: the marks below), and may call what the
# library handed out. The Context of the library has to be kept for that, as
# it is when the library did not fail (compile_import / compile_from_import:
# `$context->_keep_alive($_[2]);` in the error branch of the callback too).
# M1-M3 are the minimal shapes, M4-M6 controls, N1-N8 further shapes where the
# failing import sits in an extends child, behind an include, an import, an
# extends, a macro body or a call block.
# ---------------------------------------------------------------------------
subtest 'a library that fails after it handed a macro out' => sub {
  is( scalar @{ $by{import} }, 14, 'the 14 shapes' );
  for my $c ( @{ $by{import} } ) {
    subtest $c->{name} => sub { check_case($c) };
  }
};

done_testing;
