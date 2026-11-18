package Text::Nunjucks::Environment;
# ABSTRACT: 1:1 port of Nunjucks src/environment.js -- the template Environment

our $VERSION = '0.001';

use Moo;
use builtin qw( true false );
use feature qw( current_sub );
use Scalar::Util qw( blessed weaken );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Runtime;
use Text::Nunjucks::Compiler;
use Text::Nunjucks::Loader;
use Text::Nunjucks::Loader::FileSystem;
use Text::Nunjucks::Filters;
use Text::Nunjucks::Tests;
use Text::Nunjucks::Globals;
use Text::Nunjucks::Context;
use Text::Nunjucks::Template;
use namespace::autoclean;

no warnings 'experimental::builtin';

with 'Text::Nunjucks::EmitterObj';

# environment.js exports { Environment, Template } and defines Context internally;
# the porting map lists Text::Nunjucks::Environment / ::Context / ::Template, all
# from this one upstream file. Each is a class in its own file (ADR 0020):
# Environment here, Text::Nunjucks::Context and Text::Nunjucks::Template beside
# it, both `use`d above. object.js's Obj/EmitterObj become Moo +
# the EmitterObj role (ADR 0002); the constructor's `this.init(...args)`
# indirection becomes a positional-args BUILDARGS feeding a faithful init() (so
# the files can still be reviewed method-for-method against environment.js).
#
# The compiler-emitted code (k15) calls into $env / $context / a Template through
# exactly the method surface built here; $runtime is passed as the class name
# 'Text::Nunjucks::Runtime' (class-method-only module), so $runtime->None,
# $runtime->Frame->new, $runtime->member_lookup(...) all resolve.
#
# PORTING-ORDER NOTES -- how init's dependencies arrived:
#   * environment.js require()s ./filters, ./tests, ./globals and registers them
#     all in init. All three are plain loads (`use` above): the transitional
#     guarded require of ADR 0015 is gone since k18. Filters exports($env)
#     builds the filter bag per Environment, Tests exports the test bag, and
#     Globals globals() returns a fresh globals bag per Environment.
#   * init's no-loaders default is upstream's server-side one, a
#     FileSystemLoader('views') (Text::Nunjucks::Loader::FileSystem, k19).
#     The WebLoader fallback and window.nunjucksPrecompiled are browser-only
#     and out of scope (ADR 0018).

#### callbackAsap -- upstream defers the callback via asap; Perl core has no event
#### loop, so the callback fires synchronously (ADR 0003). Kept as a named seam so
#### an event-loop binding can later make it truly async without touching callers.
sub _callback_asap {
  my ( $self, $cb, $err, $res ) = @_;
  $cb->( $err, $res );
  return;
}

#### noopTmplSrc -- a no-op template for {% include ignore missing %}
my $NOOP_TMPL_SRC = {
  type => 'code',
  obj  => {
    root => sub {
      my ( $env, $context, $frame, $runtime, $cb ) = @_;
      my $ok = eval { $cb->( undef, '' ); 1 };
      if ( !$ok ) { $cb->( $runtime->handle_error( $@, undef, undef ) ); }
    }
  }
};

# init's field set (upstream sets these on `this`). All rw: init assigns them.
has opts            => ( is => 'rw' );
has loaders         => ( is => 'rw' );
has globals         => ( is => 'rw' );
has filters         => ( is => 'rw' );
has tests           => ( is => 'rw' );
has async_filters   => ( is => 'rw' );
has extensions      => ( is => 'rw' );
has extensions_list => ( is => 'rw' );
has _init_args      => ( is => 'ro' );

# Collaborators named once, reached through the invocant (house rule).
sub template_class   { 'Text::Nunjucks::Template' }
sub _lib             { 'Text::Nunjucks::Lib' }
sub _runtime_class   { 'Text::Nunjucks::Runtime' }
sub _error_class     { 'Text::Nunjucks::Lib::Error' }
sub filters_module   { 'Text::Nunjucks::Filters' }
sub tests_module     { 'Text::Nunjucks::Tests' }
sub globals_module   { 'Text::Nunjucks::Globals' }
sub file_system_loader_class { 'Text::Nunjucks::Loader::FileSystem' }

# constructor(...args) { this.init(...args) } -- positional (loaders, opts).
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
  my ( $self, $loaders, $opts ) = @_;

  # dev flag: the trace shown on errors (default false).
  $opts = $self->opts( $opts || {} );
  $self->opts->{dev} = $self->_runtime_class->_truthy( $opts->{dev} ) ? true : false;

  # autoescape: global autoescaping, default true. `!= null` keeps an explicit
  # false, defaults only for undefined/null.
  $self->opts->{autoescape} =
    ( defined( $opts->{autoescape} ) && !$self->_runtime_class->_is_none( $opts->{autoescape} ) )
    ? $opts->{autoescape}
    : true;

  $self->opts->{throwOnUndefined} = $self->_runtime_class->_truthy( $opts->{throwOnUndefined} ) ? true : false;
  $self->opts->{trimBlocks}       = $self->_runtime_class->_truthy( $opts->{trimBlocks} )       ? true : false;
  $self->opts->{lstripBlocks}     = $self->_runtime_class->_truthy( $opts->{lstripBlocks} )     ? true : false;

  $self->loaders( [] );

  if ( !$loaders ) {
    # The filesystem loader is only available server-side -- which the port
    # always is: upstream's `if (FileSystemLoader) ... else if (WebLoader)`
    # always takes its first branch under node (ADR 0018).
    $self->loaders( [ $self->file_system_loader_class->new('views') ] );
  }
  else {
    $self->loaders( $self->_lib->is_array($loaders) ? $loaders : [$loaders] );
  }

  # window.nunjucksPrecompiled -- browser-only, out of scope.

  $self->_init_loaders;

  $self->globals( $self->_load_globals );
  $self->filters( {} );
  $self->tests( {} );
  $self->async_filters( [] );
  $self->extensions( {} );
  $self->extensions_list( [] );

  for my $pair ( @{ $self->_lib->_entries( $self->_load_filters ) } ) {
    $self->add_filter(@$pair);
  }
  for my $pair ( @{ $self->_lib->_entries( $self->_load_tests ) } ) {
    $self->add_test(@$pair);
  }
}

# The built-in bags (see PORTING-ORDER NOTES): filters.js's exports, built for
# this Environment; tests.js's exports; globals.js's globals(), a fresh bag
# per call.
sub _load_filters { $_[0]->filters_module->exports( $_[0] ) }
sub _load_tests   { $_[0]->tests_module->exports }
sub _load_globals { $_[0]->globals_module->globals }

sub _init_loaders {
  my ($self) = @_;
  for my $loader ( @{ $self->loaders } ) {
    # Caching and cache busting.
    $loader->cache( {} );
    if ( $loader->can('on') ) {
      # The listeners hold the Environment and the loader weakly, as the
      # filters hold their Environment: Environment -> loaders -> loader ->
      # listeners -> Environment / loader would be reference cycles Perl
      # never frees (JS collects them). A listener runs while its loader
      # emits, so the loader is there. An Environment dropped by its caller
      # is freed even while a shared loader lives on, and its own listeners
      # with it, where node's loader keeps it and them alive -- a difference
      # the Perl API can see, the worker's interim choice until k96 settles
      # the cycles (ADR 0018).
      weaken( my $env = $self );
      weaken( my $l   = $loader );
      $loader->on(
        'update',
        sub {
          my ( $name, $fullname ) = @_;
          $l->cache->{$name} = undef;
          $env->emit( 'update', $name, $fullname, $l ) if $env;
        }
      );
      $loader->on(
        'load',
        sub {
          my ( $name, $source ) = @_;
          $env->emit( 'load', $name, $source, $l ) if $env;
        }
      );
    }
  }
}

sub invalidate_cache {
  my ($self) = @_;
  for my $loader ( @{ $self->loaders } ) {
    $loader->cache( {} );
  }
}

sub add_extension {
  my ( $self, $name, $extension ) = @_;
  $extension->{__name} = $name;    # extension.__name = name (k8/k22: object surface open)
  $self->extensions->{$name} = $extension;
  push @{ $self->extensions_list }, $extension;
  return $self;
}

sub remove_extension {
  my ( $self, $name ) = @_;
  my $extension = $self->get_extension($name);
  return unless $extension;

  $self->extensions_list( $self->_lib->without( $self->extensions_list, $extension ) );
  delete $self->extensions->{$name};
}

sub get_extension {
  my ( $self, $name ) = @_;
  return $self->extensions->{$name};
}

sub has_extension {
  my ( $self, $name ) = @_;
  return $self->extensions->{$name} ? 1 : 0;
}

sub add_global {
  my ( $self, $name, $value ) = @_;
  $self->globals->{$name} = $value;
  return $self;
}

sub get_global {
  my ( $self, $name ) = @_;
  if ( !defined $self->globals->{$name} ) {
    die $self->_error_class->new( 'global not found: ' . $name );
  }
  return $self->globals->{$name};
}

sub add_filter {
  my ( $self, $name, $func, $async ) = @_;
  my $wrapped = $func;
  if ( $self->_runtime_class->_truthy($async) ) {
    push @{ $self->async_filters }, $name;
  }
  $self->filters->{$name} = $wrapped;
  return $self;
}

sub get_filter {
  my ( $self, $name ) = @_;
  if ( !$self->filters->{$name} ) {
    die $self->_error_class->new( 'filter not found: ' . $name );
  }
  return $self->filters->{$name};
}

sub add_test {
  my ( $self, $name, $func ) = @_;
  $self->tests->{$name} = $func;
  return $self;
}

sub get_test {
  my ( $self, $name ) = @_;
  # this.tests[name] and 'test not found: ' + name read the name's JS
  # ToString -- the select / reject filters hand it any template value
  # (oracle: select(null) finds the null test, select(testName='odd') gives
  # "test not found: [object Object]")
  my $key = $self->_runtime_class->_member_key($name);
  if ( !$self->tests->{$key} ) {
    die $self->_error_class->new( 'test not found: ' . $key );
  }
  return $self->tests->{$key};
}

sub resolve_template {
  my ( $self, $loader, $parent_name, $filename ) = @_;
  my $is_relative =
    ( $loader->can('is_relative') && $parent_name ) ? $loader->is_relative($filename) : 0;
  return ( $is_relative && $loader->can('resolve') )
    ? $loader->resolve( $parent_name, $filename )
    : $filename;
}

sub get_template {
  my ( $self, $name, $eager_compile, $parent_name, $ignore_missing, $cb ) = @_;
  my $that = $self;
  my $tmpl = undef;
  if ( $name && ref($name) eq 'HASH' && $name->{raw} ) {
    # this fixes autoescape for templates referenced in symbols
    $name = $name->{raw};
  }

  if ( $self->_lib->is_function($parent_name) ) {
    $cb          = $parent_name;
    $parent_name = undef;
    $eager_compile = $eager_compile || 0;
  }

  if ( $self->_lib->is_function($eager_compile) ) {
    $cb            = $eager_compile;
    $eager_compile = 0;
  }

  if ( blessed($name) && $name->isa( $self->template_class ) ) {
    $tmpl = $name;
  }
  elsif ( !$self->_lib->is_string($name) ) {
    die $self->_error_class->new( 'template names must be a string: ' . $name );
  }
  else {
    for my $loader ( @{ $self->loaders } ) {
      $tmpl = $loader->cache->{ $self->resolve_template( $loader, $parent_name, $name ) };
      last if $tmpl;
    }
  }

  if ($tmpl) {
    $tmpl->compile if $eager_compile;

    if ($cb) {
      $cb->( undef, $tmpl );
      return undef;
    }
    else {
      return $tmpl;
    }
  }
  my $sync_result;

  my $create_template = sub {
    my ( $err, $info ) = @_;
    if ( !$info && !$err && !$ignore_missing ) {
      $err = $self->_error_class->new( 'template not found: ' . $name );
    }

    if ($err) {
      if ($cb) {
        $cb->($err);
        return;
      }
      else {
        die $err;
      }
    }
    my $new_tmpl;
    if ( !$info ) {
      $new_tmpl = $self->template_class->new( $NOOP_TMPL_SRC, $self, '', $eager_compile );
    }
    else {
      $new_tmpl =
        $self->template_class->new( $info->{src}, $self, $info->{path}, $eager_compile );
      if ( !$info->{noCache} ) {
        $info->{loader}->cache->{$name} = $new_tmpl;
      }
    }
    if ($cb) {
      $cb->( undef, $new_tmpl );
    }
    else {
      $sync_result = $new_tmpl;
    }
  };

  # Port-only (k83): an include, import or extends that loads its template
  # runs the rest of the including template in this call's continuation, so N
  # sequential (or N nested) loads enter async_iter N deep -- one JS call per
  # load upstream as well (ADR 0003). Perl warns at the 100th nested call of a
  # sub, at the call site; the depth is bounded by memory, not by Perl, so that
  # warning is off from here to the end of get_template (see Lib async_iter).
  no warnings 'recursion';
  $self->_lib->async_iter(
    $self->loaders,
    sub {
      my ( $loader, $i, $next, $done ) = @_;
      my $handle = sub {
        my ( $err, $src ) = @_;
        if ($err) {
          $done->($err);
        }
        elsif ($src) {
          $src->{loader} = $loader;
          $done->( undef, $src );
        }
        else {
          $next->();
        }
      };

      # Resolve name relative to parentName
      $name = $that->resolve_template( $loader, $parent_name, $name );

      if ( $loader->can('async') && $loader->async ) {
        $loader->get_source( $name, $handle );
      }
      else {
        $handle->( undef, $loader->get_source($name) );
      }
    },
    $create_template
  );

  return $sync_result;
}

# express(app) -- express-app.js is out of scope (not ported).

sub render {
  my ( $self, $name, $ctx, $cb ) = @_;
  if ( $self->_lib->is_function($ctx) ) {
    $cb  = $ctx;
    $ctx = undef;
  }

  # Synchronous API: if nothing defers, the whole thing runs synchronously.
  my $sync_result = undef;

  $self->get_template(
    $name,
    sub {
      my ( $err, $tmpl ) = @_;
      if ( $err && $cb ) {
        $self->_callback_asap( $cb, $err );
      }
      elsif ($err) {
        die $err;
      }
      else {
        $sync_result = $tmpl->render( $ctx, $cb );
      }
    }
  );

  return $sync_result;
}

sub render_string {
  my ( $self, $src, $ctx, $opts, $cb ) = @_;
  if ( $self->_lib->is_function($opts) ) {
    $cb   = $opts;
    $opts = {};
  }
  $opts = $opts || {};

  my $tmpl = $self->template_class->new( $src, $self, $opts->{path} );
  return $tmpl->render( $ctx, $cb );
}

sub waterfall {
  my ( $self, $tasks, $callback, $force_async ) = @_;
  # Minimal a-sync-waterfall: run tasks in sequence, threading each task's
  # results into the next, first error short-circuits to the final callback.
  # Synchronous unless a task defers (ADR 0003); forceAsync is a no-op here.
  # Only compile_include emits waterfall -- no corpus case exercises it yet
  # (k18/k20 include/extends suites will), so the deep-recursion trampoline of
  # the real a-sync-waterfall is deferred.
  my @tasks = @$tasks;
  my $i     = 0;

  # Port-only (k107): the step hands itself on as __SUB__, never as a captured
  # $next -- a closure that closes over the variable holding it is a reference
  # cycle, and Perl frees by reference count: tasks and callback, and through
  # them the render's Context, Frame and Template, would live forever. $next
  # only starts the chain.
  my $next = sub {
    my ( $err, @args ) = @_;
    if ($err) {
      $callback->($err) if $callback;
      return;
    }
    if ( $i >= scalar @tasks ) {
      $callback->( undef, @args ) if $callback;
      return;
    }
    my $task = $tasks[ $i++ ];
    $task->( @args, __SUB__ );
  };
  $next->(undef);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Environment - 1:1 port of Nunjucks src/environment.js -- the template Environment

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The upstream file C<src/environment.js> defines three classes. The port gives each
its own file (ADR 0020): Text::Nunjucks::Environment, below, the object an
application holds; L<Text::Nunjucks::Template>, a template that renders; and
L<Text::Nunjucks::Context>, the per-render bookkeeping of variables and blocks,
which the engine creates itself and callers do not use. Loading this module
loads the other two. Callbacks follow ADR 0003 and the render API ADR 0009.

Every one of these classes takes its constructor arguments by position, as
upstream's constructors do, not as a hash.

=head1 Text::Nunjucks::Environment

    my $env = Text::Nunjucks::Environment->new( $loaders, \%opts );

    $env->add_filter( reverse_words => sub { join ' ', reverse split ' ', $_[0] } );
    my $out = $env->render( 'page.njk', { title => 'Hi' } );

An Environment owns the loaders, the options, the filters, tests, globals and
extensions, and a cache of compiled templates per loader. Keep one around and
render through it: a template is compiled once and cached.

=head2 new

    Text::Nunjucks::Environment->new;
    Text::Nunjucks::Environment->new( $loader );
    Text::Nunjucks::Environment->new( [ $loader_a, $loader_b ], \%opts );

Positional: the loaders, then the options. C<$loaders> is one loader object or
an array reference of them, tried in order. When it is omitted (or false) the
Environment uses a single L<Text::Nunjucks::Loader::FileSystem> over the
directory C<views> of the current working directory. An empty array reference
means no loaders: only C<render_string> can then render, and C<render> fails
with C<template not found>.

The options are a hash reference with the keys of Nunjucks:

=over 4

=item autoescape

Escape every output with C<{{ }}> unless it is marked safe. B<True by default>:
an C<undef> or null value leaves the default in place, any other value is taken
as given.

=item throwOnUndefined

Make outputting an undefined or null value an error
(C<attempted to output null or undefined value>). Off by default.

=item trimBlocks

Remove the first newline after a block tag. Off by default.

=item lstripBlocks

Remove leading whitespace from the start of a line up to a block tag. Off by
default.

=item dev

Throw the error objects as they are (L<Text::Nunjucks::Lib::TemplateError>,
with line, column and cause) instead of the plain
L<Text::Nunjucks::Lib::Error> carrying the same name and message. Off by
default. Errors that are not template errors, such as C<template not found>,
are L<Text::Nunjucks::Lib::Error> either way.

=item tags

A hash reference overriding the template delimiters: any of C<blockStart>,
C<blockEnd>, C<variableStart>, C<variableEnd>, C<commentStart>, C<commentEnd>.
The defaults are C<{%>, C<%}>, C<{{>, C<}}>, C<{#> and C<#}>.

=back

The option keys keep their JavaScript spelling because they are the names of
the template engine's options. The hash reference you pass is the Environment's
C<opts> itself, changed in place: the defaults are filled in, and the four
boolean options become booleans.

=head2 loaders

Array reference of the loaders, in lookup order.

=head2 opts

The options hash reference, with defaults filled in. It is the hash you passed
to C<new>, not a copy.

=head2 globals

Hash reference of the global names to values. Use L</add_global> and
L</get_global> instead of writing to it.

=head2 filters

Hash reference of the filter names to code references. Use L</add_filter> and
L</get_filter>.

=head2 tests

Hash reference of the C<is> test names to code references. Use L</add_test> and
L</get_test>.

=head2 async_filters

Array reference of the names of the filters registered as asynchronous.

=head2 extensions

Hash reference of the extension names to extensions, and C<extensions_list> the
same extensions as an array reference in registration order. Use
L</add_extension>.

=head2 add_filter

    $env->add_filter( shout => sub { my ($text) = @_; return uc($text) . '!' } );
    $env->add_filter( $name, sub { my ( $value, @args ) = @_; ... } );
    $env->add_filter( $name, sub { my $cb = pop; my ( $value, @args ) = @_; $cb->( $err, $result ) }, 1 );

Registers a filter and returns the Environment. A synchronous filter is called
with the value being filtered followed by the filter's arguments and returns the
result. With a true third argument the filter is asynchronous: it receives a
trailing callback instead of returning, and calls C<< $cb->( $err, $result ) >>
(ADR 0009); take the callback off the end of C<@_> first, as in the example.
Keyword arguments in the template arrive as a trailing
C<Text::Nunjucks::Runtime::KwArgs> object; for an asynchronous filter it comes
before the callback. A name registered twice is
replaced, so a built-in filter can be overridden.

=head2 get_filter

    my $code = $env->get_filter($name);

Returns the filter's code reference. Dies with a
L<Text::Nunjucks::Lib::Error> C<filter not found: NAME> when there is none.

=head2 add_test

    $env->add_test( $name, sub { my ( $value, @args ) = @_; ... } );

Registers an C<is> test (C<{{ x is NAME }}>) and returns the Environment. The
code reference gets the tested value and the test's arguments and returns the
truth value.

=head2 get_test

    my $code = $env->get_test($name);

Returns the test's code reference. Dies with C<test not found: NAME> when there
is none.

=head2 add_global

    $env->add_global( $name, $value );

Sets a global, visible to every template rendered through this Environment
unless the context has a variable of the same name. A code reference is a
function the template can call. Returns the Environment.

=head2 get_global

    my $value = $env->get_global($name);

Returns the global. Dies with C<global not found: NAME> when it is not set (or
undefined). The built-in globals are C<range>, C<cycler> and C<joiner>.

=head2 add_extension

    $env->add_extension( $name, $extension );

Registers an extension and returns the Environment. C<$extension> must be a
hash-based object; the Environment stores C<$name> in its C<__name> key. How an
extension object is shaped (the tags it claims and how it parses and renders
them) is not settled and not documented here.

=head2 get_extension

    my $extension = $env->get_extension($name);

Returns the registered extension, or C<undef>.

=head2 has_extension

True when an extension of that name is registered.

=head2 remove_extension

    $env->remove_extension($name);

Unregisters the extension. Does nothing when there is none.

=head2 get_template

    my $tmpl = $env->get_template($name);
    my $tmpl = $env->get_template( $name, $eager_compile, $parent_name, $ignore_missing );
    $env->get_template( $name, $eager_compile, $parent_name, $ignore_missing, sub {
      my ( $err, $tmpl ) = @_;
    } );

Returns the L<Text::Nunjucks::Template> called C<$name>. The cache of each
loader is consulted first, then each loader's C<get_source> in turn until one
returns a source; a source whose C<noCache> is false is cached under the resolved
name (C<$name> resolved against C<$parent_name>, see below).
C<$name> may also be a template object, which is returned as it is.

C<$eager_compile> compiles the template now instead of on its first render.
C<$parent_name> is the name of the template doing the asking: a C<$name> that
starts with C<./> or C<../> is resolved against it (see L</resolve_template>).
With a true C<$ignore_missing> a template no loader has is an empty template
instead of an error.

Without a callback the template is returned, or the method dies with a
L<Text::Nunjucks::Lib::Error> (C<template not found: NAME>, or
C<template names must be a string: ...>). The callback is the fifth
argument, or takes the place of C<$eager_compile> or C<$parent_name> (and the
arguments after it). It cannot take the place of C<$ignore_missing>: a code
reference there is only a true value, and the callback is never called. With a
callback, errors go to C<< $cb->($err) >> and the template to
C<< $cb->( undef, $tmpl ) >>. A loader that is asynchronous
(see L<Text::Nunjucks::Loader>) can only be used with a callback: without one,
the method returns before the template has arrived.

=head2 resolve_template

    my $name = $env->resolve_template( $loader, $parent_name, $filename );

Returns the name to look up: C<$filename> resolved against C<$parent_name> by
the loader's C<resolve> when the filename is relative (C<./x>, C<../x>), the
parent name is given and the loader has C<is_relative> and C<resolve>;
otherwise C<$filename> unchanged.

=head2 render

    my $html = $env->render( 'page.njk', \%context );
    $env->render( 'page.njk', \%context, sub { my ( $err, $html ) = @_; ... } );

Loads the template with C<get_template> and renders it with the context hash
reference (the context may be left out). Without a callback it returns the
text and dies on error. With a callback it calls
C<< $cb->( $err, $result ) >>, exactly one of the two being set; errors in
loading and rendering the template go there instead of dying. A name that is
not a string (C<render( undef, {}, $cb )>) still dies before the callback is
reached, as in Nunjucks. Rendering is synchronous unless something in the
template or its loaders defers; a render without a callback that does defer
returns C<undef> without an error, as Nunjucks returns null. A failed render
is a L<Text::Nunjucks::Lib::Error>, or a
L<Text::Nunjucks::Lib::TemplateError> with C<dev>; C<template not found> is a
L<Text::Nunjucks::Lib::Error> in both cases.

=head2 render_string

    my $html = $env->render_string( $source, \%context );
    my $html = $env->render_string( $source, \%context, { path => 'inline.njk' } );
    $env->render_string( $source, \%context, $opts, sub { my ( $err, $html ) = @_; ... } );

Renders a template given as a string, with this Environment's filters, tests,
globals and loaders (so C<include> and C<extends> inside it work). The third
argument is a hash reference whose only key is C<path>, the name shown in error
messages (C<unknown path> otherwise); it may be left out, and the callback
given in its place. Return value, errors and callback are as for L</render>.

=head2 invalidate_cache

    $env->invalidate_cache;

Empties the compiled-template cache of every loader.

=head2 on

    $env->on( update => sub { my ( $name, $fullname, $loader ) = @_; ... } );
    $env->on( load   => sub { my ( $name, $source,   $loader ) = @_; ... } );

From L<Text::Nunjucks::EmitterObj>. The Environment re-emits its loaders'
events: C<update> when a loader reports that a template changed (the loader's
cache entry for it is dropped first), and C<load> when a loader emits it
(L<Text::Nunjucks::Loader::FileSystem> does when it reads a template;
L<Text::Nunjucks::Loader::Precompiled> never does). Both carry the loader as
the last argument.
C<emit> calls the listeners in registration order.

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
