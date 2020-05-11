package Wasm;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_plain_arrayref );
use Carp ();

# ABSTRACT: Write Perl extensions using Wasm
our $VERSION = '0.09'; # VERSION


our %WASM;
my $linker;
my %inst;
my $wasi;
my @keep;

sub import
{
  my $class = shift;
  my($caller, $fn) = caller;

  return unless @_;

  if(defined $_[0] && $_[0] ne '-api')
  {
    Carp::croak("You MUST specify an api level as the first option");
  }

  my $api;
  my $exporter;
  my @module;
  my $package = $caller;
  my $file    = $fn;

  my @global;

  while(@_)
  {
    my $key = shift;
    if($key eq '-api')
    {
      if(defined $api)
      {
        Carp::croak("Specified -api more than once");
      }
      $api = shift;
      unless(defined $api && $api == 0)
      {
        Carp::croak("Currently only -api => 0 is supported");
      }
    }
    elsif($key eq '-wat')
    {
      my $wat = shift;
      Carp::croak("-wat undefined") unless defined $wat;
      @module = (wat => $wat);
    }
    elsif($key eq '-file')
    {
      my $path = shift;
      unless(defined $path && -f $path)
      {
        $path = 'undef' unless defined $path;
        Carp::croak("no such file $path");
      }
      $file = "$path";
      @module = (file => $file);
    }
    elsif($key eq '-self')
    {
      require Path::Tiny;
      my $perl_path = Path::Tiny->new($fn);
      my $basename = $perl_path->basename;
      $basename =~ s/\.(pl|pm)$//;
      my @maybe = sort { $b->stat->mtime <=> $a->stat->mtime } grep { -f $_ } (
        $perl_path->parent->child($basename . ".wasm"),
        $perl_path->parent->child($basename . ".wat"),
      );
      if(@maybe == 0)
      {
        Carp::croak("unable to find .wasm or .wat file relative to Perl source");
      }
      else
      {
        $file = shift @maybe;
        @module = (file => $file);
      }
    }
    elsif($key eq '-exporter')
    {
      $exporter = shift;
    }
    elsif($key eq '-package')
    {
      $package = shift;
    }
    elsif($key eq '-global')
    {
      if(is_plain_arrayref $_[0])
      {
        push @global, shift;
      }
      else
      {
        Carp::croak("-global should be an array reference");
      }
    }
    elsif($key eq '-imports')
    {
      Carp::croak("-imports was removed in Wasm.pm 0.08");
    }
    else
    {
      Carp::croak("Unknown Wasm option: $key");
    }
  }

  Carp::croak("The wasm_ namespace is reserved for internal use") if $package =~ /^wasi_/;

  require Wasm::Wasmtime;
  $linker ||= do {
    my $linker = Wasm::Wasmtime::Linker->new(
      Wasm::Wasmtime::Store->new(
        Wasm::Wasmtime::Engine->new(
          Wasm::Wasmtime::Config
            ->new
            ->wasm_multi_value(1)
            ->cache_config_default,
        ),
      ),
    );
    $linker->allow_shadowing(0);
    $linker;
  };

  if(@global)
  {
    Carp::croak("Cannot specify both Wasm and -global") if @module;
    foreach my $spec (@global)
    {
      my($name, $content, $mutability, $value) = @$spec;
      my $global = Wasm::Wasmtime::Global->new(
        $linker->store,
        Wasm::Wasmtime::GlobalType->new($content, $mutability),
        $value,
      );
      no strict 'refs';
      *{"${package}::$name"} = $global->tie;
    }
    return;
  }

  @module = (wat => '(module)') unless @module;

  Carp::croak("Wasm for $package already loaded") if $inst{$package};

  my $module = Wasm::Wasmtime::Module->new($linker->store, @module);

  foreach my $import (@{ $module->imports })
  {

    my $module = $import->module;

    if($module =~ /^(wasi_unstable|wasi_snapshot_preview1)$/)
    {
      next if $WASM{$module};
      $linker->define_wasi(
        $wasi ||= Wasm::Wasmtime::WasiInstance->new(
          $linker->store,
          $module,
          Wasm::Wasmtime::WasiConfig
            ->new
            ->set_argv($0, @ARGV)
            ->inherit_env
            ->inherit_stdin
            ->inherit_stdout
            ->inherit_stderr
            ->preopen_dir("/", "/"),
        )
      );
      $linker->allow_shadowing(1);
      my $proc_exit = Wasm::Wasmtime::Func->new(
        $linker->store,
        ['i32'], [],
        sub { _wasi_proc_exit($_[0]) },
      );
      push @keep, $proc_exit;
      $linker->define($module, "proc_exit", $proc_exit);
      $linker->allow_shadowing(0);
      $WASM{$module} = __FILE__;  # Maybe Wasi::Snapshot::Preview1 etc.
      next;
    }

    if($module ne 'main')
    {
      my $pm = "$module.pm";
      $pm =~ s{::}{/}g;
      eval { require $pm };
      if(my $error = $@)
      {
        $error =~ s/ at (.*?)$//;
        $error .= " module required by WebAssembly at $file";
        Carp::croak("$error");
      }
    }

    next if $inst{$module};

    my $name = $import->name;
    my $type = $import->type;
    my $kind = $type->kind;

    my $extern;

    if($kind eq 'functype')
    {
      if(my $f = $module->can("${module}::$name"))
      {
        $extern = Wasm::Wasmtime::Func->new(
          $linker->store,
          $type,
          $f,
        );
        push @keep, $extern;
      }
    }
    elsif($kind eq 'globaltype')
    {
      if(my $global = do { no strict 'refs'; tied ${"${module}::$name"} })
      {
        $extern = $global;
      }
    }

    if($extern)
    {
      # TODO: check that the store is the same?
      eval {
        $linker->define(
          $module,
          $name,
          $extern,
        );
      };
      if(my $error = $@)
      {
        if(Wasm::Wasmtime::Error->can('new'))
        {
          # TODO: if we can do a get on the define that would
          # be better than doing this regex on the diagnostic.
          # this is available in the rust api, but not the c api
          # as of this writing.
          die $error unless $error =~ /defined twice/;
        }
        else
        {
          # TODO: also for the prod version of wasmtime we don't
          # have an error so we end up swallowing other types
          # of errors, if there are any.
        }
      }
    }
  }

  my $instance = $inst{$package} = $linker->instantiate($module);
  $linker->define_instance($package, $instance);
  $WASM{$package} = "$file";

  my @me = @{ $module->exports   };
  my @ie = @{ $instance->exports };

  my @function_names;

  for my $i (0..$#ie)
  {
    my $exporttype = $me[$i];
    my $name = $me[$i]->name;
    my $externtype = $exporttype->type;
    my $extern = $ie[$i];
    my $kind = $extern->kind;
    if($kind eq 'func')
    {
      my $func = $extern;
      $func->attach($package, $name);
      push @function_names, $name;
    }
    elsif($kind eq 'global')
    {
      my $global = $extern;
      no strict 'refs';
      *{"${package}::$name"} = $global->tie;
    }
    elsif($kind eq 'memory')
    {
      require Wasm::Memory;
      my $memory = Wasm::Memory->new($extern);
      no strict 'refs';
      *{"${package}::$name"} = \$memory;
    }
  }

  if($exporter)
  {
    require Exporter;
    no strict 'refs';
    push @{ "${package}::ISA"       }, 'Exporter';
    if($exporter eq 'all')
    {
      push @{ "${package}::EXPORT" }, @function_names;
    }
    else
    {
      push @{ "${package}::EXPORT_OK" }, @function_names;
    }
  }
}

# nothing non-standard here right now,
# but one day we migh want to be able
# to intercept this and exit out of
# Wasm, but not out of Perl.
sub _wasi_proc_exit
{
  my($value) = @_;
  exit($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm - Write Perl extensions using Wasm

=head1 VERSION

version 0.09

=head1 SYNOPSIS

lib/MathStuff.pm:

 package MathStuff;
 
 use strict;
 use warnings;
 use base qw( Exporter );
 use Wasm
   -api => 0,
   -exporter => 'ok',
   -wat => q{
     (module
       (func (export "add") (param i32 i32) (result i32)
         local.get 0
         local.get 1
         i32.add)
       (func (export "subtract") (param i32 i32) (result i32)
         local.get 0
         local.get 1
         i32.sub)
       (memory (export "frooble") 2 3)
     )
   };
 
 1;

mathstuff.pl:

 use MathStuff qw( add subtract );
 
 print add(1,2), "\n";      # prints 3
 print subtract(3,2), "\n", # prints 1

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

The goal of this project is for Perl and WebAssembly to be able to call
each other transparently without having to know or care which module is
implemented in which language.  Perl and WebAssembly functions and
global variables can be imported/exported between Perl and WebAssembly.
WebAssembly global variables are imported into Perl space as tied scalar
variables of the same name.  L<Wasm::Memory> provides a Perl interface
into WebAssembly memory.  L<Wasm::Hook> provides a hook for loading
WebAssembly files directly with zero Perl wrappers.

The example above shows WebAssembly Text (WAT) inlined into the
Perl code for readability. In most cases you will want to compile your
WebAssembly from a higher level language (Rust, C, Go, etc.), and
install it alongside your Perl Module (.pm file) and use the C<-self>
option below.  That is for C<lib/Math.pm> you would install the Wasm
file into C<lib/Math.wasm>, and use the C<-self> option.

L<Wasm> can optionally L<Exporter> to export WebAssembly functions into
other modules.  Using C<-export 'ok'> functions can be imported from a
calling module on requests.  C<-export 'all'> will export all exported
functions by default.

The current implementation uses L<Wasm::Wasmtime>, which is itself based
on the Rust project Wasmtime.  This module doesn't expose the
L<Wasm::Wasmtime> interface, and implementation could be changed in the
future.

=head1 OPTIONS

=head2 -api

 use Wasm -api => 0;

As of this writing, since the API is subject to change, this must be
provided and set to C<0>.

=head2 -exporter

 use Wasm -api => 0, -exporter => 'all';
 use Wasm -api => 0, -exporter => 'ok';

Configure the caller as an L<Exporter>, with all the functions in the
WebAssembly either C<@EXPORT> (C<all>) or C<@EXPORT_OK> (C<ok>).

=head2 -file

 use Wasm -api => 0, -file => $file;

Path to a WebAssembly file in either WebAssembly Text (.wat) or
WebAssembly binary (.wasm) format.

=head2 -package

 use Wasm -api => 0, -package => $package;

Install subroutines in to C<$package> namespace instead of the calling
namespace.

=head2 -self

 use Wasm -api => 0, -self;

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file
with the same base name as the Perl source this is called from.

For example if you are calling this from C<lib/Foo/Bar.pm>, it will look
for C<lib/Foo/Bar.wat> and C<lib/Foo/Bar.wasm>.  If both exist, then it
will use the newer of the two.

=head2 -wat

 use Wasm -api => 0, -wat => $wat;

String containing WebAssembly Text (WAT).  Helpful for inline
WebAssembly inside your Perl source file.

=head1 GLOBALS

=head2 %Wasm::WASM

This hash maps the Wasm module names to the files from which the Wasm
was loaded. It is roughly analogous to the C<@INC> array in Perl.

=head1 CAVEATS

As mentioned before as of this writing this dist is a work in progress.
I won't intentionally break stuff if I don't have to, but practicality
may demand it in some situations.

This interface is implemented using the bundled L<Wasm::Wasmtime> family
of modules, which depends on the Wasmtime project.

The default way of handling out-of-bounds memory errors is to allocate
large C<PROT_NONE> pages at startup.  While these pages do not consume
many resources in practice (at least in the way that they are used by
Wasmtime), they can cause out-of-memory errors on Linux systems with
virtual memory limits (C<ulimi -v> in the C<bash> shell).  Similar
techniques are common in other modern programming languages, and this is
more a limitation of the Linux kernel than anything else.  Setting the
limits on the virtual memory address size probably doesn't do what you
think it is doing and you are probably better off finding a way to place
limits on process memory.

However, as a workaround for environments that choose to set a virtual
memory address size limit anyway, Wasmtime provides configurations to
not allocate the large C<PROT_NONE> pages at some performance cost.  The
testing plugin L<Test2::Plugin::Wasm> tries to detect environments that
have the virtual memory address size limits and sets this configuration
for you.  For production you can set the environment variable
C<PERL_WASM_WASMTIME_MEMORY> to tune the appropriate memory settings
exactly as you want to (see the environment section of
L<Wasm::Wasmtime>.

=head1 SEE ALSO

=over 4

=item L<Wasm::Memory>

Interface to WebAssembly memory from Perl.

=item L<Wasm::Wasmtime>

Low level interface to C<wasmtime>.

=item L<Wasm::Hook>

Load WebAssembly modules as though they were Perl modules.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
