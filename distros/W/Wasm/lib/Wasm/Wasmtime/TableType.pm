package Wasm::Wasmtime::TableType;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::ExternType );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;
use Ref::Util qw( is_ref is_plain_arrayref );
use constant is_tabletype => 1;
use constant kind => 'tabletype';

# ABSTRACT: Wasmtime table type class
our $VERSION = '0.10'; # VERSION


$ffi_prefix = 'wasm_tabletype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_tabletype_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_valtype_t','uint32[2]'] => 'wasm_tabletype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(defined $_[0] && !is_ref($_[0]) && $_[0] =~ /^[0-9]+$/)
  {
    my($ptr, $owner) = @_;
    return bless {
      ptr => $ptr,
      owner => $owner,
    }, $class;
  }
  else
  {
    my($valtype, $limit) = @_;
    if(ref($valtype) eq 'Wasm::Wasmtime::ValType')
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype->kind);
    }
    else
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype);
    }
    Carp::croak("bad limits") unless is_plain_arrayref($limit);
    Carp::croak("no minumum in limit") unless defined $limit->[0];
    $limit->[1] = 0xffffffff unless defined $limit->[1];
    my $self = $xsub->($valtype, $limit);
    delete $valtype->{ptr};
    return $self;
  }
});


$ffi->attach( element => ['wasm_tabletype_t'] => 'wasm_valtype_t' => sub {
  my($xsub, $self) = @_;
  my $valtype = $xsub->($self);
  $valtype->{owner} = $self;
  $valtype;
});


$ffi->attach( limits => ['wasm_tabletype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});


sub to_string
{
  my($self) = @_;
  my($min, $max) = @{ $self->limits };
  my $string = "$min ";
  $string .= "$max " if $max != 0xffffffff;
  $string .= $self->element->to_string;
}

__PACKAGE__->_cast(2);
_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::TableType - Wasmtime table type class

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $tabletype = Wasm::Wasmtime::TableType->new('i32',[2,10]);

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a module table type.

=head1 CONSTRUCTOR

=head2 new

 my $tabletype = Wasm::Wasmtime::TableType->new(
   $valtype,     # Wasm::Wasmtime::ValType
   [$min,$max],  # integer limits
 );

Creates a new table type object.

As a shortcut, the type names (ie C<i32>, etc) maybe used instead of a L<Wasm::Wasmtime::ValType>
for C<$valtype>.

=head2 element

 my $valtype = $tabletype->element;

Returns the L<Wasm::Wasmtime::ValType> for this table type.

=head2 limits

 my $limits = $tabletype->limits;

Returns the limits as an array reference.

=head2 to_string

 my $string = $tabletype->to_string;

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
