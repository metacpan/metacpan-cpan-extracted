package Wasm;

use strict;
use warnings;
use 5.008001;
use Carp ();

# ABSTRACT: Write Perl extensions using Wasm
our $VERSION = '0.05'; # VERSION


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
  my @imports;
  my $package = $caller;

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
      @module = (file => "$path");
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
        @module = (file => shift @maybe);
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
    elsif($key eq '-imports')
    {
      @imports = @{ shift() };
    }
    else
    {
      Carp::croak("Unknown Wasm option: $key");
    }
  }

  @module = (wat => '(module)') unless @module;

  require Wasm::Wasmtime;
  my $config = Wasm::Wasmtime::Config->new;
  $config->wasm_multi_value(1);
  my $engine = Wasm::Wasmtime::Engine->new($config);
  my $store = Wasm::Wasmtime::Store->new($engine);
  my $module = Wasm::Wasmtime::Module->new($store, @module);
  my $instance = Wasm::Wasmtime::Instance->new($module, \@imports);

  my @me = $module->exports;
  my @ie = $instance->exports;

  my @function_names;

  for my $i (0..$#ie)
  {
    my $exporttype = $me[$i];
    my $name = $me[$i]->name;
    my $externtype = $exporttype->type;
    my $extern = $ie[$i];
    if($externtype->kind eq 'func')
    {
      my $func = $extern->as_func;
      $func->attach($package, $name);
      push @function_names, $name;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm - Write Perl extensions using Wasm

=head1 VERSION

version 0.05

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

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The C<Wasm> Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

=head1 OPTIONS

=head2 -api

 use Wasm -api => 0;

As of this writing, since the API is subject to change, this must be provided and set to C<0>.

=head2 -exporter

 use Wasm -api => 0, -exporter => 'all';
 use Wasm -api => 0, -exporter => 'ok';

Configure the caller as an L<Exporter>, with all the functions in the WebAssembly either C<@EXPORT> (C<all>)
or C<@EXPORT_OK> (C<ok>).

=head2 -file

 use Wasm -api => 0, -file => $file;

Path to a WebAssembly file in either WebAssembly Text (.wat) or WebAssembly binary (.wasm) format.

=head2 -imports

 use Wasm -api => 0, -imports => \@imports;

Use the given imports when creating the module instance.

=head2 -package

 use Wasm -api => 0, -package => $package;

Install subroutines in to C<$package> namespace instead of the calling namespace.

=head2 -self

 use Wasm -api => 0, -self;

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file with the same base name as
the Perl source this is called from.

For example if you are calling this from C<lib/Foo/Bar.pm>, it will look for C<lib/Foo/Bar.wat> and
C<lib/Foo/Bar.wasm>.  If both exist, then it will use the newer of the two.

=head2 -wat

 use Wasm -api => 0, -wat => $wat;

String containing WebAssembly Text (WAT).  Helpful for inline WebAssembly inside your Perl source file.

=head1 CAVEATS

As mentioned before as of this writing this dist is a work in progress.  I won't intentionally break
stuff if I don't have to, but practicality may demand it in some situations.

This interface is implemented using the bundled L<Wasm::Wasmtime> family of modules, which depends
on the Wasmtime project.  Because of the way Wasmtime handles out-of-bounds memory errors, large
C<PROT_NONE> pages are allocated at startup.  While these pages do not consume any actual resources
(as used by Wasmtime), they can cause out-of-memory errors on Linux systems with virtual memory
limits (C<ulimit -v>).  Similar techniques are common in modern programming languages, and this
seems to be more a limitation of the Linux kernel.

=head1 SEE ALSO

=over 4

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
