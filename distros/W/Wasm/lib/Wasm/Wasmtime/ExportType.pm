package Wasm::Wasmtime::ExportType;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_blessed_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime export type class
our $VERSION = '0.19'; # VERSION


$ffi_prefix = 'wasm_exporttype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_exporttype_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_byte_vec_t*', 'opaque'] => 'wasm_exporttype_t' => sub {
  my $xsub = shift;
  my $class = shift;

  # not sure this is actually useful...
  if(defined $_[1] && is_blessed_ref $_[1] && $_[1]->isa('Wasm::Wasmtime::ExternType'))
  {
    my $name = Wasm::Wasmtime::ByteVec->new(shift);
    my $externtype = shift;
    my $self = $xsub->($name, $externtype->{ptr});
    $name->delete;
    return $self;
  }
  else
  {
    my ($ptr,$owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});


$ffi->attach( name => ['wasm_exporttype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});


$ffi->attach( type => ['wasm_exporttype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});


sub to_string
{
  my($self) = @_;
  my $kind   = $self->type->kind;
  $kind =~ s/type$//;
  # TODO: escape strings ?
  sprintf '(%s (export "%s") %s)', $kind, $self->name, $self->type->to_string;
}

_generate_destroy();
_generate_vec_class();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ExportType - Wasmtime export type class

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new(wat => q{
   (module
     (func (export "foo") (param i32 i32) (result i32)
       local.get 0
       local.get 1
       i32.add)
     (memory (export "bar") 2 3)
   )
 });
 
 
 my($foo, $bar) = @{ $module->exports };
 
 print $foo->name, "\n";        # foo
 print $foo->type->kind, "\n";  # func
 print $bar->name, "\n";        # bar
 print $bar->type->kind, "\n";  # memory

=head1 DESCRIPTION

This class represents an export from a module.  It is essentially a name
and an L<Wasm::Wasmtime::ExternType>.  The latter gives you the function
signature and other configuration details for exportable objects.

=head1 CONSTRUCTOR

=head2 new

 my $exporttype = Wasm::Wasmtime::ExportType->new(
   $name,         # string
   $externtype,   # Wasm::Wasmtime::ExternType
 );

Creates a new export type object.

=head1 METHODS

=head2 name

 my $name = $exporttype->name;

Returns the name of the export.

=head2 type

 my $externtype = $exporttype->type;

Returns the L<Wasm::Wasmtime::ExternType> for the export.

=head2 to_string

 my $string = $exporttype->to_string;

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
