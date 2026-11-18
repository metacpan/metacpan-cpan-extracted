package Text::Nunjucks::Context;
# ABSTRACT: The per-render bookkeeping of variables and blocks (environment.js class Context)

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( refaddr weaken );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Environment;
use Text::Nunjucks::Runtime::Frame;
use Text::Nunjucks::Context::Gone;
use namespace::autoclean;

# upstream: class Context extends Obj in src/environment.js, which defines it
# internally (environment.js exports only Environment and Template). Like
# Environment and Template, the constructor's `this.init(...args)` indirection
# is a positional-args BUILDARGS feeding a faithful init().

has env      => ( is => 'rw' );
has ctx      => ( is => 'rw' );
has blocks   => ( is => 'rw' );
has exported => ( is => 'rw' );
has _init_args => ( is => 'ro' );

# Port-only, no upstream counterpart (ADR 0021): what a tracing GC does for
# upstream and a reference count has to be told. See _keep_alive, the three
# methods for an included template, _track_scope and DEMOLISH at the end of
# this file.
has _kept          => ( is => 'ro', default => sub { [] } );
has _includer      => ( is => 'rw' );
has _has_closure   => ( is => 'rw' );
has _has_delivered => ( is => 'rw' );
has _context_vars  => ( is => 'ro', default => sub { {} } );
has _frame_vars    => ( is => 'ro', default => sub { {} } );

sub _lib                 { 'Text::Nunjucks::Lib' }
sub _environment_class   { 'Text::Nunjucks::Environment' }
sub _error_class         { 'Text::Nunjucks::Lib::Error' }
sub _frame_class         { 'Text::Nunjucks::Runtime::Frame' }
sub _gone_class          { 'Text::Nunjucks::Context::Gone' }

sub BUILDARGS {
  my ( $class, @args ) = @_;
  return { _init_args => [@args] };
}

sub BUILD {
  my ($self) = @_;
  $self->init( @{ $self->_init_args // [] } );
  delete $self->{_init_args};
}

sub init {
  my ( $self, $ctx, $blocks, $env ) = @_;

  # Has to be tied to an environment so we can tap into its globals.
  $self->env( $env || $self->_environment_class->new );

  # Make a duplicate of ctx.
  $self->ctx( $self->_lib->extend( {}, $ctx ) );

  $self->blocks( {} );
  $self->exported( [] );

  for my $name ( @{ $self->_lib->keys($blocks) } ) {
    $self->add_block( $name, $blocks->{$name} );
  }
}

sub lookup {
  my ( $self, $name ) = @_;
  # Optimize for the typical case where the name isn't in the globals.
  if ( exists $self->env->globals->{$name} && !exists $self->ctx->{$name} ) {
    return $self->env->globals->{$name};
  }
  else {
    return $self->ctx->{$name};
  }
}

sub set_variable {
  my ( $self, $name, $val ) = @_;
  $self->ctx->{$name} = $val;
}

sub get_variables {
  my ($self) = @_;
  return $self->ctx;
}

sub add_block {
  my ( $self, $name, $block ) = @_;
  $self->blocks->{$name} = $self->blocks->{$name} || [];
  push @{ $self->blocks->{$name} }, $block;
  return $self;
}

sub get_block {
  my ( $self, $name ) = @_;
  if ( !$self->blocks->{$name} ) {
    die $self->_error_class->new( 'unknown block "' . $name . '"' );
  }
  return $self->blocks->{$name}[0];
}

sub get_super {
  my ( $self, $env, $name, $block, $frame, $runtime, $cb ) = @_;
  my $idx     = $self->_lib->index_of( $self->blocks->{$name} || [], $block );
  my $blk     = $self->blocks->{$name}[ $idx + 1 ];
  my $context = $self;

  if ( $idx == -1 || !$blk ) {
    die $self->_error_class->new( 'no super block available for "' . $name . '"' );
  }

  # Port-only (k83): the block of a cached parent, called by a template that
  # includes itself N deep, runs N calls deep, as upstream nests it (ADR 0003).
  # Perl warns at the 100th nested call of a sub, at the call site; the depth
  # is bounded by memory, not by Perl (see Lib async_iter).
  no warnings 'recursion';
  $blk->( $env, $context, $frame, $runtime, $cb );
}

# addExport(name) -- pushes the name; the compiler may pass an extra value arg
# (compile_set), which is ignored, exactly as upstream ignores it.
sub add_export {
  my ( $self, $name ) = @_;
  push @{ $self->exported }, $name;
}

sub get_exported {
  my ($self) = @_;
  my $exported = {};
  for my $name ( @{ $self->exported } ) {
    $exported->{$name} = $self->ctx->{$name};
  }
  return $exported;
}

#### lifetime -- port-only, no upstream counterpart (ADR 0021)
#
# No compiled sub holds its Context (Runtime _render_scope): the call that
# started the render does, and each continuation until it is called (Runtime
# _continuation). The rest of what a tracing GC does for upstream is here.

# The Context of a template that imported a library keeps the library's
# Context: the macros it took from the library call each other and read the
# library's variables through it. The compiled `import` and `from ... import`
# callbacks call this with the third argument Template _get_exported hands
# them. It also keeps the Context of a template it included, if that one has
# to outlive its render (_included_by).
#
# A Context that keeps another one has to outlive its own render too: a macro
# of the kept one may be in the hands of whoever included this one.
sub _keep_alive {
  my ( $self, $context ) = @_;
  return unless $context;
  push @{ $self->_kept }, $context;
  $self->_made_closure;
  return;
}

# An included template renders in a Context of its own, and nothing holds
# that once its render has delivered its result. Upstream's stays reachable
# through whatever the included template handed out: a macro or call block it
# put into an array of the including template or passed to a function of the
# application, an extension that kept the body it was given, a macro of a
# library it imported. So the Context of the including template keeps it --
# but only if there is such a thing, because a partial included in a loop of
# 100,000 rows would otherwise hold 100,000 Contexts until the render ends.
#
# Template render calls this for the fourth argument a compiled `include`
# passes, and uses what it returns as the callback. From here on this Context
# holds its includer. When its render delivers, the includer takes it over
# (_keep_alive) if it has made a closure; if it has not, the includer does so
# at the moment it makes its first one -- an `include` inside `if` or `for`
# whose template waits for an async filter delivers after the includer went
# on. The includer never keeps a Context that still holds it, so the two are
# no cycle.
#
# Why not take it over the moment the closure is made: until the render
# delivers, the include's continuation holds the including Context, and a
# macro of the included template that contains an async construct holds that
# continuation, as its `$cb`. An included render that never completes would
# keep both Contexts for good.
#
# A render that delivers an error is taken over like any other: code of the
# including template still runs after it -- what follows an `if`, a `for` or a
# macro call around the include, a sibling asyncAll branch -- and can call a
# macro the included template handed out before it failed. That the rest of
# the include is never called then, and would hold the includer through the
# same `$cb`, is dealt with where the include's callback is compiled
# (Compiler compile_include).
sub _included_by {
  my ( $self, $includer, $cb ) = @_;
  $self->_includer($includer);
  weaken( my $included = $self );
  return sub {
    $included->_delivered if $included;
    return $cb->(@_);
  };
}

# The compiled code calls this before it makes a macro or a call block and
# before it hands a body to an extension (Compiler _emit_made_closure).
sub _made_closure {
  my ($self) = @_;
  return if $self->_has_closure;
  $self->_has_closure(1);
  $self->_hand_over if $self->_has_delivered;
  return;
}

sub _delivered {
  my ($self) = @_;
  $self->_has_delivered(1);
  $self->_hand_over if $self->_has_closure;
  return;
}

sub _hand_over {
  my ($self) = @_;
  my $includer = $self->_includer or return;
  $self->_includer(undef);
  $includer->_keep_alive($self);
  return;
}

# Every root and block sub registers its `$context` and `$frame` variables
# here when it is entered. They are remembered weakly, by address: a variable
# no closure captured is gone when its sub returns, one that was captured
# lives as long as the closures do.
#
# The `$frame` variable is a cycle of its own. A macro swaps and restores it
# (upstream: `frame = callerFrame`), so the macro captures it; a macro
# reachable from the Frame the variable holds -- stored with `set`, imported
# into a frame that Frame is a parent of, the `caller` of a macro call that
# died before it restored the variable, or simply defined after an `include`,
# whose continuation it then keeps -- can never be freed by a reference count.
sub _track_scope {
  my ( $self, $context_ref, $frame_ref ) = @_;
  $self->_track_var( $self->_context_vars, $context_ref );
  $self->_track_var( $self->_frame_vars,   $frame_ref );
  return;
}

sub _track_var {
  my ( $self, $vars, $ref ) = @_;
  my $addr = refaddr($ref);
  weaken( $vars->{$addr} = $ref ) unless defined $vars->{$addr};
  return;
}

# The Context is freed: nothing of its render is running or waiting to be
# called, and nothing else -- an importing or including Context, the hash
# Template get_exported returned or a function out of it -- holds it. Code of
# that render can still run: a macro the application kept, a continuation
# that is called a second time. Every `$context` variable it can see gets the
# stand-in that dies with a clear error on first use (instead of the undef the
# weak reference would leave), every `$frame` variable an empty Frame: what a
# frame variable holds
# from here on is only ever saved and put back by a macro, or pushed on by a
# call block, so the empty Frame is enough for a macro that reads nothing
# outside itself, and the Frame that was there, with the macros it holds, is
# freed.
sub DEMOLISH {
  my ( $self, $in_global_destruction ) = @_;
  return if $in_global_destruction;

  my @context_refs = grep { defined } values %{ $self->_context_vars };
  for my $context_ref (@context_refs) {
    $$context_ref = $self->_gone_class->instance;
  }

  my @frame_refs = grep { defined } values %{ $self->_frame_vars };
  for my $frame_ref (@frame_refs) {
    # the old Frame is let go only after the variable holds the new one:
    # freeing it can free the macros that hold the variable itself
    my $frame = $$frame_ref;
    $$frame_ref = $self->_frame_class->new;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Context - The per-render bookkeeping of variables and blocks (environment.js class Context)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the variables and blocks of one render. A
L<Text::Nunjucks::Template> creates it for each render; callers do not use it.
Its constructor takes its arguments by position, as upstream's does, not as a
hash.

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
