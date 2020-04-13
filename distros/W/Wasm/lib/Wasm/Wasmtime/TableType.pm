package Wasm::Wasmtime::TableType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;
use Ref::Util qw( is_ref is_plain_arrayref );

# ABSTRACT: Wasmtime table type class
our $VERSION = '0.04'; # VERSION


$ffi_prefix = 'wasm_tabletype_';
$ffi->type('opaque' => 'wasm_tabletype_t');


$ffi->attach( new => ['wasm_valtype_t','uint32[2]'] => 'wasm_tabletype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(defined $_[0] && !is_ref($_[0]) && $_[0] =~ /^[0-9]+$/)
  {
    ($ptr, $owner) = @_;
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
    $ptr = $xsub->(delete $valtype->{ptr}, $limit);
  }
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
});


$ffi->attach( element => ['wasm_tabletype_t'] => 'wasm_valtype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::ValType->new($ptr, $self);
});


$ffi->attach( limits => ['wasm_tabletype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});


# actually returns a wasm_externtype_t, but recursion
$ffi->attach( as_externtype => ['wasm_tabletype_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::ExternType;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::ExternType->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_tabletype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::TableType - Wasmtime table type class

=head1 VERSION

version 0.04

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

=head2 as_externtype

 my $externtype = $tabletype->as_externtype

Returns the L<Wasm::Wasmtime::ExternType> for this table type.

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
