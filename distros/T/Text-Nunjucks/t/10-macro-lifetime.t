#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken blessed );

use Text::Nunjucks::Environment;
use Text::Nunjucks::Context;
use Text::Nunjucks::Template;
use Text::Nunjucks::Lib::Error;

# Port-only behaviour pins for the Perl API around macro lifetime (k108,
# ADR 0021). Nothing here has an upstream test: a Perl caller of
# Template->get_exported, a Perl function that keeps a macro, an async filter
# that answers later -- JavaScript has no counterpart for what happens to the
# render's Context in those cases, because its GC keeps everything reachable.
#
# What a template alone can express (the output of macros after import,
# include, extends ...) is pinned as corpus cases in
# t/corpus/render-macro-lifetime.json; that the objects are freed is in
# t/10-leaks.t. This file holds what needs Perl on the other side.
#
# Expected values of the deferred cases (the async filters below answer from
# a queue the test drains) come from real upstream, run with a setTimeout
# async filter over the same templates and context: macro with a deferred
# filter in its body "[!" ; asyncAll with a failing first item
# "(unknown path)\n  Error: boom-1" ; asyncEach / asyncAll with a macro
# "&lt;1&gt;(1Y)&lt;2&gt;(2Y)...". The oracle cannot defer, so these are not
# corpus cases.
#
# Second round (k108 rework, include inside if / for / a macro body): the
# deferred include shapes, the interleaved renders, the application-kept macro
# with a nested macro, the get_exported surface and the extension that keeps
# its body. Every expected value of this round was produced by real upstream
# (upstream/nunjucks v3.2.4), never read off the port:
#  - deferred include shapes: the same templates and context ({x:'X', y:'Y'})
#    rendered by upstream with a setTimeout-drained async filter `later`
#    (queue.push(() => cb(null, '<' + v + '>')), answers in queue order, one
#    per macrotask), e.g. "include in for, later after" -> "&lt;X&gt;<VX><VX>";
#  - interleaved renders: two env.render calls of cached templates started
#    back to back, answered in the order B, A, A, B;
#  - kept macro with nested macros: env.renderString with a global that keeps
#    its argument, called afterwards: [<A>], [<B>], (C)(C);
#  - getExported: new Template(src, env).getExported({x:'X'}, cb): argument
#    count 1 on a compile error ("unexpected token: %}"), 2 on a render error
#    and on success; the callback is the second argument if that is a
#    function, else the first, else the third ("cb is not a function" when
#    there is none); x.a[0]() and x.o.f() give <VXh>, a library whose only
#    exports are an array and a dict holding a macro gives <VX>;
#  - extension keeping its body: render of "a{% include 'i.njk' %}b{{ call_kept() }}"
#    with i.njk = "{% set v = 'V' %}{% keep %}<{{ v }}{{ x }}>{% endkeep %}"
#    -> "akb&lt;VX&gt;" (include in an if: the same; in a for loop over two
#    items: "akkb&lt;VX&gt;&lt;VX&gt;").

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

sub msg { my $e = shift; ( blessed($e) && $e->can('message') ) ? $e->message : "$e" }

my $env = Text::Nunjucks::Environment->new;

# ---------------------------------------------------------------------------
# get_exported: the returned macros keep their Context alive (maintainer
# decision on k108, edge (b))
# ---------------------------------------------------------------------------
subtest 'get_exported: returned macros outlive the hash, the Template and the call' => sub {
  my $lib = Text::Nunjucks::Template->new(
    q({% set v = 'V' %}{% macro a() %}[{{ v }}{{ range(0,3) | join('') }}{{ b() }}{{ _helper() }}]{% endmacro %})
      . q({% macro b() %}b{% endmacro %}{% macro _helper() %}h{% endmacro %}),
    $env, 'lib-lifetime.njk'
  );

  @ctxs = ();
  my ( $err, $exported );
  $lib->get_exported( {}, sub { ( $err, $exported ) = @_ } );
  is( $err, undef, 'no error' );

  my $a = $exported->{a};
  my $b = $exported->{b};
  undef $exported;
  undef $lib;
  is( ref $a, 'CODE', 'a macro is a code reference' );
  is( ( $a->() ) . '', '[V012bh]', 'a macro reading a library variable, a global and two siblings works after the hash and the Template are gone' );
  is( ( $a->() ) . '', '[V012bh]', '... and again' );
  is( ( $b->() ) . '', 'b', 'the plain macro too' );
  ok( live_contexts() >= 1, 'the Context of the library is alive while a returned macro is' );

  undef $a;
  ok( live_contexts() >= 1, 'still alive while the other returned macro is' );
  undef $b;
  is( live_contexts(), 0, 'the Context is freed once the last returned macro is dropped' );
};

subtest 'get_exported: a function exported under two names' => sub {
  my $lib = Text::Nunjucks::Template->new(
    q({% set v = 'V' %}{% macro a() %}[{{ v }}{{ x }}]{% endmacro %}{% set a2 = a %}),
    $env, 'lib-twice.njk'
  );
  @ctxs = ();
  my ( $err, $exported );
  $lib->get_exported( { x => 'X' }, sub { ( $err, $exported ) = @_ } );
  is( $err, undef, 'no error' );
  ok( exists $exported->{$_}, "exported has '$_'" ) for qw( a a2 );

  my ( $a, $a2 ) = @{$exported}{qw( a a2 )};
  undef $exported;
  undef $lib;
  is( ( $a->() ) . '',  '[VX]', 'the macro under its own name' );
  is( ( $a2->() ) . '', '[VX]', 'the macro under its second name' );

  undef $a;
  is( ( $a2->() ) . '', '[VX]', 'the second name still works after the first one is dropped' );
  ok( live_contexts() >= 1, 'the Context is alive while one of the two names is' );
  undef $a2;
  is( live_contexts(), 0, 'the Context is freed once both are dropped' );
};

# ---------------------------------------------------------------------------
# deferred async filters: the code that runs after the answer finds its Context
# ---------------------------------------------------------------------------
my @queue;
my $aenv = Text::Nunjucks::Environment->new;
$aenv->add_filter( later => sub { my ( $v, $cb ) = @_; push @queue, sub { $cb->( undef, "<$v>" ) }; return }, 1 );
$aenv->add_filter( later_fail => sub { my ( $v, $cb ) = @_; push @queue, sub { $cb->( Text::Nunjucks::Lib::Error->new("boom-$v") ) }; return }, 1 );

# Render $src, then answer the parked filters in order; returns the results
# the user callback got and the errors the answers died with.
sub deferred {
  my ($src) = @_;
  @queue = ();
  my ( @calls, @died );
  $aenv->render_string( $src, { x => 'X', y => 'Y' }, sub { push @calls, [@_] } );
  while ( my $job = shift @queue ) {
    eval { $job->(); 1 } or push @died, msg($@);
  }
  return ( \@calls, \@died );
}

subtest 'deferred async filters complete without "its Context is gone"' => sub {
  for my $case (
    [ 'a deferred async filter inside a macro body, an outer read after it',
      '{% macro m() %}[{{ x | later }}{{ y }}]{% endmacro %}{{ m() }}!', '[!' ],
    [ 'a deferred async filter inside a macro body, nothing after it',
      '{% macro m() %}[{{ x | later }}]{% endmacro %}{{ m() }}!', '[!' ],
    [ 'asyncEach with a deferred filter and a macro reading an outer name',
      '{% macro m(i) %}({{ i }}{{ y }}){% endmacro %}{% asyncEach i in [1,2] %}{{ i | later }}{{ m(i) }}{% endeach %}',
      '&lt;1&gt;(1Y)&lt;2&gt;(2Y)' ],
    [ 'asyncAll with a deferred filter and a macro reading an outer name',
      '{% macro m(i) %}({{ i }}{{ y }}){% endmacro %}{% asyncAll i in [1,2,3] %}{{ i | later }}{{ m(i) }}{% endall %}',
      '&lt;1&gt;(1Y)&lt;2&gt;(2Y)&lt;3&gt;(3Y)' ],
    [ 'a deferred filter, then a macro reading nothing',
      '{{ x | later }}{% macro n() %}plain{% endmacro %}{{ n() }}', '&lt;X&gt;plain' ],
    )
  {
    my ( $name, $src, $expect ) = @$case;
    my ( $calls, $died ) = deferred($src);
    is_deeply( $died, [], "$name: no answer died" );
    is( scalar @$calls, 1, "$name: the callback is called once" );
    is( $calls->[0][0], undef, "$name: without an error" );
    is( ( $calls->[0][1] // '' ) . '', $expect, "$name: result" );
  }

  # asyncAll with a partial failure: the first item fails, the second one reads
  # the context after its own deferred answer.
  my ( $calls, $died ) = deferred(
    '{% asyncAll i in [1,2] %}{% if i == 1 %}{{ i | later_fail }}{% else %}{{ i | later }}{{ y }}{% endif %}{% endall %}');
  is_deeply( $died, [], 'asyncAll with a partial failure: no answer died, "Context is gone" or anything else' );
  is( scalar @$calls, 1, 'asyncAll with a partial failure: the callback is called once' );
  is( msg( $calls->[0][0] ), "(unknown path)\n  Error: boom-1", 'asyncAll with a partial failure: the render error of upstream' );
};

# ---------------------------------------------------------------------------
# Limitation (a) of ADR 0021: a macro that the application's own Perl code
# keeps and calls after the render that defined it has ended
# ---------------------------------------------------------------------------
subtest 'a macro kept by the application after its render ended' => sub {
  my $kenv = Text::Nunjucks::Environment->new;
  my %kept;
  $kenv->add_global( keep => sub { my ( $name, $m ) = @_; $kept{$name} = $m; return '' } );

  my $out = $kenv->render_string(
    q({% macro own(a) %}<{{ a }}>{% endmacro %})
      . q({% macro locals(a) %}{% set t = a %}[{{ t }}]{% endmacro %})
      . q({% macro outer() %}{{ x }}{% endmacro %})
      . q({% macro glob() %}{{ range(0,2) | join('') }}{% endmacro %})
      . q({{ keep('own', own) }}{{ keep('locals', locals) }}{{ keep('outer', outer) }}{{ keep('glob', glob) }}end),
    { x => 'X' }
  );
  is( $out, 'end', 'the render itself is fine' );
  is( scalar keys %kept, 4, 'the application kept four macros' );

  is( ( $kept{own}->('A') ) . '',    '<A>', 'a macro reading only its own arguments still works after the render ended' );
  is( ( $kept{locals}->('B') ) . '', '[B]', 'a macro reading only its arguments and locals still works' );

  for my $name (qw( outer glob )) {
    my $r = eval { $kept{$name}->(); 1 };
    my $e = $@;
    ok( !$r, "a macro reading a name outside itself ($name) dies after the render ended" );
    isa_ok( $e, 'Text::Nunjucks::Lib::Error', "the error of '$name'" );
    like( msg($e), qr/render had ended/, "the error of '$name' says that the render had ended" );
  }
};

# ---------------------------------------------------------------------------
# k108 round 2
# ---------------------------------------------------------------------------
{
  package T::MemLoader;
  use Moo;
  extends 'Text::Nunjucks::Loader';
  has templates => ( is => 'ro', default => sub { {} } );
  has no_cache  => ( is => 'ro', default => 1 );
  sub get_source {
    my ( $self, $name ) = @_;
    return undef unless exists $self->templates->{$name};
    return { src => $self->templates->{$name}, path => $name, noCache => $self->no_cache };
  }
}

sub mem_env {
  my ( $templates, %o ) = @_;
  return Text::Nunjucks::Environment->new( T::MemLoader->new( templates => $templates, %o ) );
}

# A template of the includer's closure family: sets v, makes a macro, hands it
# to the includer's array `bag`.
my $INC = q({% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}>{% endmacro %}{% set _ = bag.push(m) %});
my $USE = q({% for f in bag %}{{ f() }}{% endfor %});
my $SB  = q({% set bag = [] %});

# Render main.njk of $templates with a parked async filter `later` and a global
# `note`, answer the parked calls in order, and report what happened.
sub run_deferred {
  my ($templates) = @_;
  my $env = mem_env($templates);
  my @q;
  my @notes;
  $env->add_filter( later => sub { my ( $v, $cb ) = @_; push @q, sub { $cb->( undef, "<$v>" ) }; return }, 1 );
  $env->add_global( note => sub { push @notes, $_[0]; return '' } );

  @ctxs = ();
  my ( @calls, @died );
  $env->render( 'main.njk', { x => 'X', y => 'Y' }, sub { push @calls, [@_] } );
  while ( my $job = shift @q ) {
    eval { $job->(); 1 } or push @died, msg($@);
  }
  return { calls => \@calls, died => \@died, notes => \@notes, live => live_contexts() };
}

subtest 'deferred includes that hand a macro to the includer (expected: upstream with a setTimeout filter)' => sub {
  my $lib = q({% set v = 'V' %}{% macro m() %}<{{ v }}>{% endmacro %});
  my $late_inc = q({{ x | later }}{% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}>{% endmacro %}{% set _ = bag.push(m) %});
  for my $case (
    [ 'include, then a deferral, then the call (top level)',
      { 'main.njk' => $SB . q({% include 'inc.njk' %}{{ x | later }}) . $USE, 'inc.njk' => $INC },
      '&lt;X&gt;<VX>' ],
    [ 'include inside an if, a deferral after the if, then the call',
      { 'main.njk' => $SB . q({% if true %}{% include 'inc.njk' %}{% endif %}{{ x | later }}) . $USE, 'inc.njk' => $INC },
      '&lt;X&gt;<VX>' ],
    [ 'include inside a for loop, a deferral after it, then the call',
      { 'main.njk' => $SB . q({% for i in [1,2] %}{% include 'inc.njk' %}{% endfor %}{{ x | later }}) . $USE, 'inc.njk' => $INC },
      '&lt;X&gt;<VX><VX>' ],
    [ 'the included template defers before it makes its macro',
      { 'main.njk' => $SB . q({% include 'i2.njk' %}{{ y }}) . $USE, 'i2.njk' => $late_inc },
      '&lt;X&gt;Y<VX>' ],
    [ 'the included template defers after it made its macro',
      { 'main.njk' => $SB . q({% include 'i2.njk' %}{{ y }}) . $USE,
        'i2.njk'   => q({% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}>{% endmacro %}{% set _ = bag.push(m) %}{{ x | later }}) },
      '&lt;X&gt;Y<VX>' ],
    [ 'include inside an if, the included template defers, the includer defers again',
      { 'main.njk' => $SB . q({% if true %}{% include 'i2.njk' %}{% endif %}{{ y | later }}) . $USE, 'i2.njk' => $late_inc },
      '&lt;X&gt;&lt;Y&gt;<VX>' ],
    [ 'the late chain: plain grandparent, an if-include, the included template defers and then pushes a macro',
      { 'main.njk' => $SB . q({% include 'g.njk' %}{{ y | later }}{{ y | later }}) . $USE,
        'g.njk'    => q(g{% include 'p.njk' %}),
        'p.njk'    => q(p{% if true %}{% include 'i2.njk' %}{% endif %}),
        'i2.njk'   => $late_inc },
      'gp&lt;Y&gt;&lt;Y&gt;<VX>' ],
    [ 'a call block registered through an includer macro, the includer defers before the call',
      { 'main.njk' => $SB . q({% macro reg() %}{% set _ = bag.push(caller) %}{% endmacro %}{% for i in [1,2] %}{% include 'i2.njk' %}{% endfor %}{{ y | later }}) . $USE,
        'i2.njk'   => q({% set v = 'V' %}{% call reg() %}<{{ v }}{{ i }}{{ x }}>{% endcall %}) },
      '&lt;Y&gt;<V2X><V2X>' ],
    [ 'the included template from-imports a macro and hands it up, a deferral after the if',
      { 'main.njk' => $SB . q({% if true %}{% include 'i2.njk' %}{% endif %}{{ y | later }}) . $USE,
        'lib.njk'  => $lib,
        'i2.njk'   => q({% from 'lib.njk' import m %}{% set _ = bag.push(m) %}) },
      '&lt;Y&gt;<V>' ],
    [ 'asyncAll includes that defer and push a macro',
      { 'main.njk' => $SB . q({% asyncAll i in [1,2,3] %}{% include 'i2.njk' %}{% endall %}) . $USE,
        'i2.njk'   => q(({{ i | later }}){% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}>{% endmacro %}{% set _ = bag.push(m) %}) },
      '(&lt;1&gt;)(&lt;2&gt;)(&lt;3&gt;)<VX><VX><VX>' ],
    [ 'asyncEach includes that defer and push a macro',
      { 'main.njk' => $SB . q({% asyncEach i in [1,2,3] %}{% include 'i2.njk' %}{% endeach %}) . $USE,
        'i2.njk'   => q(({{ i | later }}){% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}>{% endmacro %}{% set _ = bag.push(m) %}) },
      '(&lt;1&gt;)(&lt;2&gt;)(&lt;3&gt;)<VX><VX><VX>' ],
    [ 'late code calls a macro of an ancestor that already delivered',
      { 'main.njk' => q({% macro m0() %}[{{ x }}]{% endmacro %}{% if true %}{% include 'xx.njk' %}{% endif %}end{{ y | later }}{{ y | later }}{{ y | later }}),
        'xx.njk'   => q({% if true %}{% include 'yy.njk' %}{% endif %}),
        'yy.njk'   => q({{ x | later }}{{ m0() }}) },
      'end&lt;Y&gt;&lt;Y&gt;&lt;Y&gt;' ],
    )
  {
    my ( $name, $templates, $expect ) = @$case;
    my $r = run_deferred($templates);
    is_deeply( $r->{died}, [], "$name: no answer died" );
    is( scalar @{ $r->{calls} }, 1, "$name: the render callback is called exactly once" );
    is( $r->{calls}[0][0], undef, "$name: without an error" );
    is( ( $r->{calls}[0][1] // '' ) . '', $expect, "$name: output equals upstream" );
    is( $r->{live}, 0, "$name: no live Context afterwards" );
  }

  # late code in an included template that runs after the root delivered: upstream
  # delivers 'end' and the late `note` call still happens
  my $r = run_deferred(
    {
      'main.njk' => q({% macro m0() %}[{{ x }}]{% endmacro %}{% if true %}{% include 'xx.njk' %}{% endif %}end),
      'xx.njk'   => q({% if true %}{% include 'yy.njk' %}{% endif %}),
      'yy.njk'   => q({{ x | later }}{{ m0() }}{{ note('late') }}),
    }
  );
  is_deeply( $r->{died}, [], 'late code after the root delivered: no answer died' );
  is( scalar @{ $r->{calls} }, 1, 'late code after the root delivered: callback called exactly once' );
  is( $r->{calls}[0][1] . '', 'end', 'late code after the root delivered: output equals upstream' );
  is_deeply( $r->{notes}, ['late'], 'late code after the root delivered: the late global call happened (upstream: notes=late)' );
  is( $r->{live}, 0, 'late code after the root delivered: no live Context afterwards' );
};

subtest 'two renders of cached templates interleaved by a deferral' => sub {
  my $env = mem_env(
    {
      'main.njk' => q({% from 'lib.njk' import m with context %}{% include 'part.njk' %}{{ x | later }}{{ m() }}{% macro n() %}[{{ x }}]{% endmacro %}{{ n() }}{{ y | later }}{{ m() }}{{ n() }}),
      'lib.njk'  => q({% macro m() %}<{{ x }}>{% endmacro %}),
      'part.njk' => q(p{{ x }}),
    },
    no_cache => 0
  );
  my %parked;
  $env->add_filter( later => sub { my ( $v, $cb ) = @_; $parked{$v} = sub { $cb->( undef, "<$v>" ) }; return }, 1 );

  # one render first, so the cached templates exist before the interleaving
  my %res;
  my %calls;
  @ctxs = ();
  for my $who (qw( A B )) {
    $env->render( 'main.njk', { x => $who, y => "y$who" }, sub { $calls{$who}++; $res{$who} = [@_] } );
  }
  is_deeply( [ sort keys %parked ], [qw( A B )], 'both renders wait for their first deferral' );
  ok( live_contexts() >= 2, 'two renders are alive at once' );

  my @died;
  for my $answer (qw( B A yA yB )) {
    my $job = delete $parked{$answer} or do { push @died, "nothing parked for $answer"; next };
    eval { $job->(); 1 } or push @died, msg($@);
  }
  is_deeply( \@died, [], 'answering in the order B, A, A, B: nothing died' );
  is_deeply( \%calls, { A => 1, B => 1 }, 'each render callback is called exactly once' );
  is( $res{A}[0], undef, 'A: no error' );
  is( $res{B}[0], undef, 'B: no error' );
  is( $res{A}[1] . '', 'pA&lt;A&gt;<A>[A]&lt;yA&gt;<A>[A]', 'A: output equals upstream' );
  is( $res{B}[1] . '', 'pB&lt;B&gt;<B>[B]&lt;yB&gt;<B>[B]', 'B: output equals upstream' );
  is( live_contexts(), 0, 'no live Context afterwards' );
};

subtest 'a macro kept by the application that defines nested macros and reads nothing outside' => sub {
  my $kenv = Text::Nunjucks::Environment->new;
  my %kept;
  $kenv->add_global( keep => sub { my ( $name, $m ) = @_; $kept{$name} = $m; return '' } );
  @ctxs = ();
  my $out = $kenv->render_string(
    q({% macro outer(a) %}{% macro inner(b) %}<{{ b }}>{% endmacro %}[{{ inner(a) }}]{% endmacro %})
      . q({% macro deep(a) %}{% macro mid(b) %}{% macro leaf(c) %}({{ c }}){% endmacro %}{{ leaf(b) }}{% endmacro %}{{ mid(a) }}{{ mid(a) }}{% endmacro %})
      . q({{ keep('outer', outer) }}{{ keep('deep', deep) }}end),
    { x => 'X' }
  );
  is( $out, 'end', 'the render itself is fine' );
  # upstream's compileMacro defines a macro that is nested in a macro body with
  # context.addExport / context.setVariable (the body frame has no parent), so
  # such a kept macro WRITES to the render's Context when it runs; the port's
  # Context is gone by then. The stand-in takes those two writes and drops
  # them (Context::Gone add_export, set_variable): nobody can read a Context
  # that is gone, and every read of it still dies.
  my @r = map { my $m = $kept{ $_->[0] }; my $v = eval { ( $m->( $_->[1] ) ) . '' }; $v // 'DIED: ' . msg($@) }
    ( [ outer => 'A' ], [ outer => 'B' ], [ deep => 'C' ] );
  is( $r[0], '[<A>]', 'the macro with a nested macro works after the render ended' );
  is( $r[1], '[<B>]', '... again, with another argument' );
  is( $r[2], '(C)(C)', 'two levels of nested macros work too' );
  delete @kept{qw( outer deep )};
  is( live_contexts(), 0, 'no live Context once the application drops them' );
};

# ---------------------------------------------------------------------------
# get_exported surface
# ---------------------------------------------------------------------------
subtest 'get_exported: functions nested in an exported list and dict' => sub {
  my $src = q({% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}{{ h() }}>{% endmacro %}{% macro h() %}h{% endmacro %})
          . q({% set o = { f: m } %}{% set a = [m] %});
  @ctxs = ();
  my ( $err, $e );
  Text::Nunjucks::Template->new( $src, $env, 'lib-nested.njk' )->get_exported( { x => 'X' }, sub { ( $err, $e ) = @_ } );
  is( $err, undef, 'no error' );
  is( join( ',', sort keys %$e ), 'a,h,m,o,v', 'the exported names are the ones upstream exports' );
  is( ( $e->{a}[0]->() ) . '',     '<VXh>', 'a function in an exported list works (upstream: <VXh>)' );
  is( ( $e->{o}->get('f')->() ) . '', '<VXh>', 'a function in an exported dict works (upstream: <VXh>)' );
  ok( live_contexts() >= 1, 'the Context is alive while the hash is' );
  undef $e;
  is( live_contexts(), 0, 'the Context is freed with the hash' );
};

subtest 'get_exported: a library whose only exports are an array and a dict holding a macro' => sub {
  my $src = q({% set v = 'V' %}{% macro _m() %}<{{ v }}{{ x }}>{% endmacro %}{% set o = { f: _m } %}{% set a = [_m] %});
  @ctxs = ();
  my ( $err, $e );
  Text::Nunjucks::Template->new( $src, $env, 'lib-nested-only.njk' )->get_exported( { x => 'X' }, sub { ( $err, $e ) = @_ } );
  is( $err, undef, 'no error' );
  is( join( ',', sort keys %$e ), 'a,o,v', 'no top-level function is exported (upstream: v,o,a)' );
  is( ( $e->{a}[0]->() ) . '',        '<VX>', 'the function in the list works while the hash lives (upstream: <VX>)' );
  is( ( $e->{o}->get('f')->() ) . '', '<VX>', 'the function in the dict works while the hash lives' );
  is( ( $e->{a}[0]->() ) . '',        '<VX>', '... and again' );
  undef $e;
  is( live_contexts(), 0, 'the Context is freed with the hash' );
};

subtest 'get_exported: a library exporting no function at all' => sub {
  @ctxs = ();
  my ( $err, $e );
  Text::Nunjucks::Template->new( q({% set n = 5 %}{% set l = [1,2] %}), $env, 'lib-plain.njk' )
    ->get_exported( {}, sub { ( $err, $e ) = @_ } );
  is( $err, undef, 'no error' );
  is( $e->{n}, 5, 'the value is exported (upstream: {n:5,l:[1,2]})' );
  is_deeply( $e->{l}, [ 1, 2 ], 'the list too' );
  undef $e;
  is( live_contexts(), 0, 'the Context is freed with the hash' );

  # the caller that does not keep the hash: nothing is left once get_exported returned
  @ctxs = ();
  Text::Nunjucks::Template->new( q({% set n = 5 %}), $env, 'lib-plain2.njk' )->get_exported( {}, sub { } );
  is( live_contexts(), 0, 'a callback that drops the hash: no live Context once get_exported has returned' );
};

subtest 'get_exported: callback argument counts' => sub {
  my @got;
  my $cb = sub { @got = ( scalar(@_), @_ ) };

  Text::Nunjucks::Template->new( '{% if %}', $env, 'lib.njk' )->get_exported( {}, $cb );
  is( $got[0], 1, 'compile error: one argument (upstream: argc=1)' );
  isa_ok( $got[1], 'Text::Nunjucks::Lib::TemplateError', 'the error' );
  like( msg( $got[1] ), qr/unexpected token: %\}/, 'with the upstream text (unexpected token: %})' );

  Text::Nunjucks::Template->new( '{{ nope() }}', $env, 'lib.njk' )->get_exported( {}, $cb );
  is( $got[0], 2, 'render error: two arguments (upstream: argc=2)' );
  isa_ok( $got[1], 'Text::Nunjucks::Lib::TemplateError', 'the error' );
  like( msg( $got[1] ), qr/Unable to call `nope`, which is undefined or falsey/, 'with the upstream text' );
  is( $got[2], undef, 'and an undefined second argument (upstream: null)' );

  # k108 round 4: the Context of a failed library is handed to the compiled
  # import as a third argument inside the port (so that it can keep it); the
  # public method strips it, also when the library made a macro before it failed
  Text::Nunjucks::Template->new( q({% set v = 'V' %}{% macro m() %}<{{ v }}>{% endmacro %}{{ nope() }}), $env, 'lib.njk' )->get_exported( {}, $cb );
  is( $got[0], 2, 'render error after a macro was made: still two arguments' );
  like( msg( $got[1] ), qr/Unable to call `nope`/, 'with the error of the library' );
  is( $got[2], undef, 'and the second one undefined' );

  Text::Nunjucks::Template->new( '{% set n = 5 %}', $env, 'lib.njk' )->get_exported( {}, $cb );
  is( $got[0], 2, 'success: two arguments (upstream: argc=2)' );
  is( $got[1], undef, 'the error is undefined' );
  is( ref $got[2], 'HASH', 'the exports are a hash' );
};

subtest 'get_exported: the callback as first, second or third argument' => sub {
  my $lib = q({% set v = 'V' %}{% macro m() %}<{{ v }}{{ x }}{{ h() }}>{% endmacro %}{% macro h() %}h{% endmacro %})
          . q({% set o = { f: m } %}{% set a = [m] %}{% set n = 5 %});
  my $t   = Text::Nunjucks::Template->new( $lib, $env, 'lib-pos.njk' );
  my @which;
  my $mk = sub { my $tag = shift; sub { push @which, $tag . ':' . ( $_[1] ? ( $_[1]{m}->() ) : 'undef' ) } };

  $t->get_exported( $mk->('first') );
  $t->get_exported( { x => 'X' }, $mk->('second') );
  $t->get_exported( { x => 'X' }, undef, $mk->('third') );
  is_deeply( \@which, [ 'first:<Vh>', 'second:<VXh>', 'third:<VXh>' ], 'each position works (upstream: first:<Vh> second:<VXh> third:<VXh>)' );

  @which = ();
  $t->get_exported( sub { push @which, 'FIRST' }, sub { push @which, 'second-of-two:' . scalar keys %{ $_[1] } } );
  is_deeply( \@which, ['second-of-two:6'], 'two functions: the second one is the callback (upstream: second-of-two:6)' );

  @which = ();
  $t->get_exported( sub { push @which, 'FIRST' }, sub { push @which, 'second-of-three' }, sub { push @which, 'THIRD' } );
  is_deeply( \@which, ['second-of-three'], 'three functions: the second one is the callback (upstream: second-of-three)' );

  my $r = eval { $t->get_exported( { x => 'X' } ); 1 };
  ok( !$r, 'no callback: it dies, as upstream does ("cb is not a function")' );
};

# ---------------------------------------------------------------------------
# extension that keeps the body it was given (content argument)
# ---------------------------------------------------------------------------
{
  package T::Keep;
  sub new        { bless {}, shift }
  sub tags       { ['keep'] }
  sub autoescape { undef }
  sub __name     { my $self = shift; $self->{__name} = shift if @_; return $self->{__name} }
  sub parse {
    my ( $self, $parser, $nodes ) = @_;
    my $tok  = $parser->next_token;
    my $args = $parser->parse_signature( undef, 1 );
    $parser->advance_after_block_end( $tok->value );
    my $body = $parser->parse_until_blocks('endkeep');
    $parser->advance_after_block_end;
    return ( $nodes . '::CallExtension' )->new( $self, 'run', $args, [$body] );
  }
  sub run { my ( $self, $context, $body ) = @_; push @T::Keep::kept, $body; return 'k' }
}

subtest 'an extension that keeps its body and calls it within the render, also from an included template' => sub {
  for my $case (
    [ 'top-level include',  q(a{% include 'i.njk' %}b{{ call_kept() }}),                                  'akb&lt;VX&gt;' ],
    [ 'include in an if',   q(a{% if true %}{% include 'i.njk' %}{% endif %}b{{ call_kept() }}),          'akb&lt;VX&gt;' ],
    [ 'include in a for loop', q(a{% for q in [1,2] %}{% include 'i.njk' %}{% endfor %}b{{ call_kept() }}), 'akkb&lt;VX&gt;&lt;VX&gt;' ],
    )
  {
    my ( $name, $main, $expect ) = @$case;
    @T::Keep::kept = ();
    my $kenv = mem_env( { 'main.njk' => $main, 'i.njk' => q({% set v = 'V' %}{% keep %}<{{ v }}{{ x }}>{% endkeep %}) } );
    $kenv->add_extension( keep => T::Keep->new );
    $kenv->add_global( call_kept => sub { join '', map { $_->() } @T::Keep::kept } );
    @ctxs = ();
    my $out = eval { $kenv->render( 'main.njk', { x => 'X' } ) };
    is( $out, $expect, "$name: output equals upstream" ) or diag($@);
    @T::Keep::kept = ();
    is( live_contexts(), 0, "$name: no live Context once the application drops the bodies" );
  }
};

# ---------------------------------------------------------------------------
# k108, third round: a macro kept by the application whose BODY imports a
# library. The library's Context belongs to the macro's body run, which is
# synchronous in these shapes, so the macro works after the render ended.
#
# Expected values: upstream (nunjucks v3.2.4) rendering
#   {% macro m() %}{% from 'l.njk' import a %}[{{ a() }}]{% endmacro %}{{ keep(m) }}
# with a global `keep` that stores its argument, then calling the stored macro
# from the test after the render (and after its parked answers, one per
# macrotask):
#   l.njk = {% macro a() %}L{% endmacro %}                                  -> "[L]"
#   l.njk = {% set v = 'V' %}{% macro b() %}b{% endmacro %}{% macro a() %}{{ v }}{{ b() }}{% endmacro %}
#                                                                           -> "[Vb]"
#   {% macro m() %}{% import 'l.njk' as l %}[{{ l.a() }}{{ l.v }}]{% endmacro %}
#   l.njk = {% set v = 'V' %}{% macro a() %}{{ v }}{% endmacro %}           -> "[VV]"
# and, where the port differs (Context::Gone, ADR 0021):
#   {% macro m() %}{% from 'l.njk' import a %}{{ 1 | later }}[{{ a() }}]{% endmacro %}
#   -> upstream: the call returns '' and the answer to `later` completes
#      silently; the port: the call returns '' and the answer dies;
#   {% macro m() %}{% from 'l.njk' import a with context %}[{{ a() }}]{% endmacro %}
#   with l.njk = {% macro a() %}{{ x }}{% endmacro %} and x = 'X'
#   -> upstream "[X]"; the port: the call dies (the macro's body reads the
#      render's variables, and that Context is gone).
# ---------------------------------------------------------------------------
subtest 'a macro kept by the application whose body imports a library' => sub {
  my $run = sub {
    my ($templates) = @_;
    my $kenv = mem_env($templates);
    my ( @kept, @q );
    $kenv->add_global( keep => sub { push @kept, $_[0]; return '' } );
    $kenv->add_filter( later => sub { my ( $v, $cb ) = @_; push @q, sub { $cb->( undef, "<$v>" ) }; return }, 1 );
    @ctxs = ();
    my @calls;
    $kenv->render( 'main.njk', { x => 'X' }, sub { push @calls, [@_] } );
    return ( \@kept, \@q, \@calls );
  };

  for my $case (
    [ 'from-import of a self-contained library macro', q({% macro a() %}L{% endmacro %}),
      q({% macro m() %}{% from 'l.njk' import a %}[{{ a() }}]{% endmacro %}{{ keep(m) }}), '[L]' ],
    [ 'from-import of a library macro that reads a library variable and a sibling',
      q({% set v = 'V' %}{% macro b() %}b{% endmacro %}{% macro a() %}{{ v }}{{ b() }}{% endmacro %}),
      q({% macro m() %}{% from 'l.njk' import a %}[{{ a() }}]{% endmacro %}{{ keep(m) }}), '[Vb]' ],
    [ 'import as a namespace, a macro and a variable of the library',
      q({% set v = 'V' %}{% macro a() %}{{ v }}{% endmacro %}),
      q({% macro m() %}{% import 'l.njk' as l %}[{{ l.a() }}{{ l.v }}]{% endmacro %}{{ keep(m) }}), '[VV]' ],
    )
  {
    my ( $name, $lib, $main, $expect ) = @$case;
    my ( $kept, $q, $calls ) = $run->( { 'l.njk' => $lib, 'main.njk' => $main } );
    is( scalar @$kept, 1, "$name: the application kept one macro" );
    is( scalar @$calls, 1, "$name: the render called back once" );
    is( $calls->[0][0], undef, "$name: without an error" );
    my $got = eval { ( $kept->[0]->() ) . '' };
    is( $got, $expect, "$name: the kept macro renders like upstream after the render ended" ) or diag($@);
    is( $got, eval { ( $kept->[0]->() ) . '' }, "$name: ... and a second time" );
    @$kept = ();
    is( live_contexts(), 0, "$name: no live Context once the application drops the macro" );
  }

  # the deferred shape: the answer arrives after the render ended and dies
  my ( $kept, $q ) = $run->(
    {
      'l.njk'    => q({% set v = 'V' %}{% macro a() %}{{ v }}{% endmacro %}),
      'main.njk' => q({% macro m() %}{% from 'l.njk' import a %}{{ 1 | later }}[{{ a() }}]{% endmacro %}{{ keep(m) }}),
    }
  );
  my $got = eval { ( $kept->[0]->() ) . '' };
  is( $got, '', 'the deferred shape: the call returns the empty string, as upstream' );
  is( scalar @$q, 1, 'the deferred shape: one answer is parked' );
  my $ok = eval { $q->[0]->(); 1 };
  my $e  = $@;
  ok( !$ok, 'the deferred shape: the answer dies (upstream: it completes silently)' );
  isa_ok( $e, 'Text::Nunjucks::Lib::Error', 'the error of the deferred answer' );
  like( msg($e), qr/render had ended/, 'the deferred shape: the error says the render had ended' );

  # with context: the library's macro reads the render's variables
  ( $kept ) = $run->(
    {
      'l.njk'    => q({% macro a() %}{{ x }}{% endmacro %}),
      'main.njk' => q({% macro m() %}{% from 'l.njk' import a with context %}[{{ a() }}]{% endmacro %}{{ keep(m) }}),
    }
  );
  $ok = eval { $kept->[0]->(); 1 };
  $e  = $@;
  ok( !$ok, 'with context: the call dies (upstream: "[X]")' );
  isa_ok( $e, 'Text::Nunjucks::Lib::Error', 'the error of the with-context call' );
  like( msg($e), qr/render had ended/, 'with context: the error says the render had ended' );
  @$kept = ();
  is( live_contexts(), 0, 'no live Context afterwards' );
};

done_testing;
