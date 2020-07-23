package Wasm::Wasmtime::ImportType;

use strict;
use warnings;
use 5.008004;
use Carp ();
use Ref::Util qw( is_blessed_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime import type class
our $VERSION = '0.18'; # VERSION


$ffi_prefix = 'wasm_importtype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_importtype_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'opaque'] => 'wasm_importtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(defined $_[2] && is_blessed_ref $_[2])
  {
    my $externtype = $_[2];
    # not sure this is actually useful?
    if(is_blessed_ref($externtype) && $externtype->isa('Wasm::Wasmtime::ExternType'))
    {
      my $module = Wasm::Wasmtime::ByteVec->new(shift);
      my $name = Wasm::Wasmtime::ByteVec->new(shift);
      my $self = $xsub->($module, $name, $externtype->{ptr});
      $module->delete;
      $name->delete;
      return $self;
    }
    else
    {
      Carp::croak("Not an externtype");
    }
  }
  else
  {
    my($ptr,$owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});


$ffi->attach( name => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});


$ffi->attach( type => ['wasm_importtype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});


$ffi->attach( module => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});


sub to_string
{
  my($self) = @_;
  my $kind   = $self->type->kind;
  $kind =~ s/type$//;
  # TODO: escape strings ?
  sprintf '(%s (import "%s" "%s") %s)', $kind, $self->module, $self->name, $self->type->to_string;
}

_generate_destroy();
_generate_vec_class();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ImportType - Wasmtime import type class

=head1 VERSION

version 0.18

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new( wat => q{
   (module
     (func $hello (import "xx" "hello"))
   )
 });
 
 my $hello = $module->imports->[0];
 
 print $hello->module, "\n";     # xx
 print $hello->name, "\n";       # hello
 print $hello->type->kind, "\n"; # functype

=head1 DESCRIPTION

This class represents an import from a module.  It is essentially a name
and an L<Wasm::Wasmtime::ExternType>.  The latter gives you the function
signature and other configuration details for import objects.

=head1 CONSTRUCTOR

=head2 new

 my $importtype = Wasm::Wasmtime::ImportType->new(
   $module,       # Wasm::Wasmtime::Module
   $name,         # string
   $externtype,   # Wasm::Wasmtime::FuncType, ::MemoryType, ::GlobalType or ::TableType
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

=head2 to_string

 my $string = $importtype->to_string;

Converts the type into a string for diagnostics.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
