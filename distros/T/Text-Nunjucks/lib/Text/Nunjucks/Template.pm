package Text::Nunjucks::Template;
# ABSTRACT: A compiled template that renders (environment.js class Template)

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( refaddr weaken );
use Hash::Util::FieldHash qw( fieldhash );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Runtime;
use Text::Nunjucks::Compiler;
use Text::Nunjucks::Context;
use Text::Nunjucks::Context::Gone;
use Text::Nunjucks::Environment;
use namespace::autoclean;

# upstream: class Template extends Obj in src/environment.js, exported with
# Environment. The constructor's `this.init(...args)` indirection is a
# positional-args BUILDARGS feeding a faithful init().

has env             => ( is => 'rw' );
has path            => ( is => 'rw' );
has tmpl_props      => ( is => 'rw' );
has tmpl_str        => ( is => 'rw' );
has compiled          => ( is => 'rw' );
has blocks            => ( is => 'rw' );
has _root_render_func => ( is => 'rw' );
has _init_args        => ( is => 'ro' );

# In JS `this.rootRenderFunc = props.root` stores a function and
# `parentTemplate.rootRenderFunc(env, ...)` CALLS it -- a callable property.
# The compiler emits that same `$parentTemplate->root_render_func($env, ...)`
# call shape (compile_root's extends tail), so root_render_func is a method
# that INVOKES the stored coderef; the coderef itself lives in the private
# _root_render_func slot, set at compile.
sub root_render_func {
  my ( $self, @args ) = @_;
  # a cached parent of a template that includes itself N deep: N calls deep,
  # as in render (k83)
  no warnings 'recursion';
  return $self->_root_render_func->(@args);
}

sub _lib               { 'Text::Nunjucks::Lib' }
sub _runtime_class     { 'Text::Nunjucks::Runtime' }
sub _compiler_class    { 'Text::Nunjucks::Compiler' }
sub _context_class     { 'Text::Nunjucks::Context' }
sub _environment_class { 'Text::Nunjucks::Environment' }
sub _gone_class        { 'Text::Nunjucks::Context::Gone' }

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
  my ( $self, $src, $env, $path, $eager_compile ) = @_;
  $self->env( $env || $self->_environment_class->new );

  if ( $self->_lib->is_object($src) ) {
    my $type = $src->{type};
    if ( defined($type) && $type eq 'code' ) {
      $self->tmpl_props( $src->{obj} );
    }
    elsif ( defined($type) && $type eq 'string' ) {
      $self->tmpl_str( $src->{obj} );
    }
    else {
      die $self->_lib_error(
        "Unexpected template object type " . ( $type // 'undefined' )
          . "; expected 'code', or 'string'" );
    }
  }
  elsif ( $self->_lib->is_string($src) ) {
    $self->tmpl_str($src);
  }
  else {
    die $self->_lib_error('src must be a string or an object describing the source');
  }

  $self->path($path);

  if ($eager_compile) {
    my $ok = eval { $self->_compile; 1 };
    if ( !$ok ) {
      die $self->_lib->_prettify_error( $self->path, $self->env->opts->{dev}, $@ );
    }
  }
  else {
    $self->compiled(0);
  }
}

sub _lib_error {
  my ( $self, $msg ) = @_;
  return Text::Nunjucks::Lib::Error->new($msg);
}

sub render {
  my ( $self, $ctx, $parent_frame, $cb, $including ) = @_;
  if ( $self->_lib->is_function($ctx) ) {
    $cb  = $ctx;
    $ctx = {};
  }
  elsif ( $self->_lib->is_function($parent_frame) ) {
    $cb           = $parent_frame;
    $parent_frame = undef;
  }

  # A parent frame means we're called from another template's internals; the
  # sync/async nature is inherited, so force an async callback otherwise.
  my $force_async = !$parent_frame;

  # Catch compile errors for async rendering.
  my $ok = eval { $self->compile; 1 };
  if ( !$ok ) {
    my $err = $self->_lib->_prettify_error( $self->path, $self->env->opts->{dev}, $@ );
    if ($cb) {
      return $self->env->_callback_asap( $cb, $err );
    }
    else {
      die $err;
    }
  }

  my $context = $self->_context_class->new( $ctx || {}, $self->blocks, $self->env );

  # Port-only (ADR 0021). A compiled `include` passes its own Context as a
  # fourth argument, which upstream's render does not have: the including
  # Context has to keep this one alive if a macro of the included template
  # outlives this render (Context _included_by).
  $cb = $context->_included_by( $including, $cb ) if $including;

  my $frame = $parent_frame ? $parent_frame->push(1) : $self->_runtime_class->Frame->new;
  $frame->top_level(1);
  my $sync_result = undef;
  my $did_error   = 0;

  # Port-only (k83): a cached template included N times in a row, or one that
  # includes itself N deep, runs its root N calls deep, the next include
  # running in the previous one's continuation -- as upstream nests them
  # (ADR 0003). Perl warns at the 100th nested call of a sub, at the call site;
  # the depth is bounded by memory, not by Perl (see Lib async_iter).
  no warnings 'recursion';
  $self->_root_render_func->(
    $self->env, $context, $frame, $self->_runtime_class,
    sub {
      my ( $err, $res ) = @_;
      # See upstream note: a waterfall task may fail to propagate up the chain
      # AND fail to return from the top render; guard against a double cb call.
      if ( $did_error && $cb && defined $res ) {
        return;
      }

      if ($err) {
        $err = $self->_lib->_prettify_error( $self->path, $self->env->opts->{dev}, $err );
        $did_error = 1;
      }

      if ($cb) {
        if ($force_async) {
          $self->env->_callback_asap( $cb, $err, $res );
        }
        else {
          $cb->( $err, $res );
        }
      }
      else {
        if ($err) {
          die $err;
        }
        $sync_result = $res;
      }
    }
  );

  return $sync_result;
}

# Port-only (ADR 0021). The macros a template exports do not hold the Context
# they read their library's variables, globals and sibling macros through
# (Runtime _render_scope); whoever takes them has to. A compiled `import` does
# that itself and calls _get_exported, upstream's getExported. This is the
# method a Perl caller uses. The Context lives as long as the hash the
# callback gets (_hold_context), and as long as any function that was a value
# of that hash: each of those is a wrapper that holds the Context, so a macro
# taken out of the hash works for as long as the caller keeps it. The same
# function exported under two names gets one wrapper.
#
# What that does not reach: a function inside an exported array or object,
# taken out and called after the hash and every function that was a value of
# it are gone.
sub get_exported {
  my ( $self, @args ) = @_;

  # the callback _get_exported is going to call: the second argument if that
  # is a function, else the first if that is one, else the third
  my ($at) = grep { $self->_lib->is_function( $args[$_] ) } 1, 0;
  $at //= 2;

  if ( $self->_lib->is_function( $args[$at] ) ) {
    my $cb = $args[$at];
    $args[$at] = sub {
      # an error goes on with the one or two arguments upstream passes: one
      # for a compile error, two for a render error, which comes with the
      # Context as a third one that is for a compiled `import` only
      return $cb->(@_) if @_ < 3;
      my ( $err, $exported, $context ) = @_;
      return $cb->( $err, $exported ) if $err;
      return $cb->( $err, $self->_hold_context( $exported, $context ) );
    };
  }

  return $self->_get_exported(@args);
}

# The Context of each hash get_exported handed out, by that hash: the entry
# goes when the hash is freed (Hash::Util::FieldHash), and the Context with it
# unless a wrapper still holds it. It is not an attribute of anything because
# nothing of ours outlives the hash for sure -- not this Template, which may
# be a temporary, and not the Environment -- and it cannot be an entry of the
# hash itself, which is the exported names and nothing else.
fieldhash my %context_of;

sub _hold_context {
  my ( $self, $exported, $context ) = @_;
  return $exported unless $context;

  $context_of{$exported} = $context;

  my %holder;
  for my $name ( keys %$exported ) {
    my $func = $exported->{$name};
    next unless $self->_lib->is_function($func);
    $exported->{$name} = $holder{ refaddr($func) } //= sub {
      my $held = $context;    # naming it is what makes this sub hold it
      return $func->(@_);
    };
  }
  return $exported;
}

# upstream getExported. Port-only: the callback gets the Context the template
# ran in as a third argument, for the caller to keep alive (ADR 0021) -- with
# a render error too, because a template that failed may have handed a macro
# out before it did (Compiler _keep_alive_statement).
sub _get_exported {
  my ( $self, $ctx, $parent_frame, $cb ) = @_;
  if ( $self->_lib->is_function($ctx) ) {
    $cb  = $ctx;
    $ctx = {};
  }

  if ( $self->_lib->is_function($parent_frame) ) {
    $cb           = $parent_frame;
    $parent_frame = undef;
  }

  # Catch compile errors for async rendering.
  my $ok = eval { $self->compile; 1 };
  if ( !$ok ) {
    if ($cb) {
      return $cb->($@);
    }
    else {
      die $@;
    }
  }

  my $frame = $parent_frame ? $parent_frame->push : $self->_runtime_class->Frame->new;
  $frame->top_level(1);

  # Run the rootRenderFunc to populate the context with exported vars.
  my $context = $self->_context_class->new( $ctx || {}, $self->blocks, $self->env );

  # Port-only (ADR 0021). The compiled code does not hold its Context
  # (Runtime _render_scope), and neither may this callback: a macro of the
  # template can hold the callback. The Context is alive when the template is
  # done -- this call or a continuation holds it -- and whoever takes the
  # exports keeps it from then on.
  weaken( my $exporting = $context );

  # N sequential imports of a cached template: N calls deep, as in render (k83)
  no warnings 'recursion';
  $self->_root_render_func->(
    $self->env, $context, $frame, $self->_runtime_class,
    sub {
      my ($err) = @_;
      if ($err) {
        $cb->( $err, undef, $exporting );
      }
      else {
        my $held    = $exporting;
        my $context = $held // $self->_gone_class->instance;
        $cb->( undef, $context->get_exported, $held );
      }
    }
  );
}

sub compile {
  my ($self) = @_;
  if ( !$self->compiled ) {
    $self->_compile;
  }
}

sub _compile {
  my ($self) = @_;
  my $props;

  if ( $self->tmpl_props ) {
    $props = $self->tmpl_props;
  }
  else {
    my $source = $self->_compiler_class->compile(
      $self->tmpl_str,
      $self->env->async_filters,
      $self->env->extensions_list,
      $self->path,
      $self->env->opts
    );

    $props = $self->_eval_source($source);    # new Function(source)(); returns props
  }

  $self->blocks( $self->_get_blocks($props) );
  $self->_root_render_func( $props->{root} );
  $self->compiled(1);
}

# new Function(source) -- eval the emitted Perl source, which ends in a
# +{ root => \&, b_<name> => \&, ... } hashref. Compiled template bodies are
# sloppy-mode in JS (new Function is non-strict); eval'ing without strict/
# warnings matches that and avoids spurious undef-concat warnings from the
# generated code (values flow through suppress_value/_js_to_string).
sub _eval_source {
  my ( $self, $source ) = @_;
  my $props = do {
    no strict;      ## no critic
    no warnings;
    my $p = eval $source;    ## no critic (ProhibitStringyEval)
    die $@ if $@;
    $p;
  };
  return $props;
}

sub _get_blocks {
  my ( $self, $props ) = @_;
  my $blocks = {};

  for my $k ( @{ $self->_lib->keys($props) } ) {
    if ( substr( $k, 0, 2 ) eq 'b_' ) {
      $blocks->{ substr( $k, 2 ) } = $props->{$k};
    }
  }

  return $blocks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Template - A compiled template that renders (environment.js class Template)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $tmpl = $env->get_template('page.njk');
    my $html = $tmpl->render( { title => 'Hi' } );

    my $tmpl = Text::Nunjucks::Template->new( 'Hello {{ name }}', $env, 'greeting.njk' );

=head1 DESCRIPTION

A template, compiled to Perl code on first use. Obtain one from
L<Text::Nunjucks::Environment/get_template>, or construct it yourself.

=head2 new

    Text::Nunjucks::Template->new( $src, $env, $path, $eager_compile );

Positional. C<$src> is the template's source as a string, or a hash reference
C<< { type => 'string', obj => $source } >> or, for a template that is already
compiled, C<< { type => 'code', obj => \%compiled } >> (what
L<Text::Nunjucks::Loader::Precompiled> hands out); any other C<type> dies.
C<$env> is the Environment whose filters, tests, globals and loaders the
template uses; without one a fresh default Environment is made. C<$path> is the
name shown in error messages. With a true C<$eager_compile> the template is
compiled now, and a syntax error dies here rather than on the first render.

=head2 env

The L<Text::Nunjucks::Environment> the template belongs to.

=head2 path

The path or name given at construction, shown in error messages.

=head2 render

    my $html = $tmpl->render( \%context );
    $tmpl->render( \%context, sub { my ( $err, $html ) = @_; ... } );

Renders the template. Compiles it first if needed. The return value, the death
on error and the callback form are those of C<render> of the Environment. The
context is copied, so the template's C<set> never changes the hash you passed.

A fourth positional argument exists for the compiled C<include> of a template;
it is internal and not part of the interface.

=head2 compile

    $tmpl->compile;

Compiles the template if it is not compiled yet. A syntax error dies with the
raw L<Text::Nunjucks::Lib::TemplateError>, without the path and line prefix a
render adds (as C<compile> does in Nunjucks). Called by C<render>; call it yourself
to find errors early.

=head2 get_exported

    $tmpl->get_exported( \%context, sub { my ( $err, $exported ) = @_; ... } );

Runs the template and passes its callback the hash of the top-level variables
it exports, as C<import> and C<from ... import> read them. The callback is
required. It gets C<( $err, $exported )>; on a compile error that is one
argument, on a render error two, as in Nunjucks.

The macros in the hash read the template's variables through its context, which
the template does not keep once it is done. This method makes it live as long as
the returned hash or any function that was a value in it: every top-level
function in the hash is a wrapper that holds the context (one function under two
names gets one wrapper), so a macro you take out of the hash keeps working for as
long as you keep it. That includes a coderef of yours which the template
re-exports: it comes back as a wrapper, not as the reference you passed in.

A shallow copy of the hash holds the context only through the functions it
contains. A function inside an exported array or object, taken out and called
after the hash and every function that was a value in it are gone, finds the
context gone and dies with C<template code ran after its render had ended>. A
returned hash that you store into data the template's context holds leaks that
context. A template that failed is not kept: macros it handed out before the
error find their context gone. See ADR 0021 in F<docs/adr/>.

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
