package Wasm::Wasmtime::ImportType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime import type class
our $VERSION = '0.03'; # VERSION


$ffi_prefix = 'wasm_importtype_';
$ffi->type('opaque' => 'wasm_importtype_t');


$ffi->attach( new => ['wasm_byte_vec_t*', 'wasm_externtype_t'] => 'wasm_importtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner);
  if(defined $_[2] && ref($_[2]) eq 'Wasm::Wasmtime::ExternType')
  {
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name = Wasm::Wasmtime::ByteVec->new(shift);
    my $externtype = shift;
    my $ptr = $xsub->($module, $name, $externtype->{ptr});
    $module->delete;
    $name->delete;
  }
  else
  {
    ($ptr,$owner) = @_;
    bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});


$ffi->attach( name => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self->{ptr});
  $name->get;
});


$ffi->attach( type => ['wasm_importtype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new(
    $xsub->($self->{ptr}),
    $self->{owner} || $self,
  );
});


$ffi->attach( module => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self->{ptr});
  $name->get;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_importtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

_generate_vec_class();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ImportType - Wasmtime import type class

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new( wat => q{
   (module
     (func $hello (import "xx" "hello"))
   )
 });
 
 my($hello) = $module->imports;
 
 print $hello->module, "\n";     # xx
 print $hello->name, "\n";       # hello
 print $hello->type->kind, "\n"; # func

=head1 DESCRIPTION

This class represents an import from a module.  It is essentially a name
and an L<Wasm::Wasmtime::ExternType>.  The latter gives you the function
signature and other configuration details for import objects.

=head1 CONSTRUCTOR

=head2 new

 my $importtype = Wasm::Wasmtime::ImportType->new(
   $module,       # Wasm::Wasmtime::Module
   $name,         # string
   $externtype,   # Wasm::Wasmtime::ExternType
 );

Creates a new import type object.

=head1 METHODS

=head2 name

 my $name = $importtype->name;

Returns the name of the import.

=head2 type

 my $externtype = $importtype->type;

Returns the L<Wasm::Wasmtime::ExternType> for the import.

=head2 module

 my $name = $importtype->module;

Returns the name of the module for the import.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
