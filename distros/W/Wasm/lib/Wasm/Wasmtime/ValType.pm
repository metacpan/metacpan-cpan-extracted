package Wasm::Wasmtime::ValType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime value type class
our $VERSION = '0.04'; # VERSION


$ffi_prefix = 'wasm_valtype_';
$ffi->type('opaque' => 'wasm_valtype_t');

my %kind = (
  0   => 'i32',
  1   => 'i64',
  2   => 'f32',
  3   => 'f64',
  128 => 'anyref',
  129 => 'funcref',
);

my %rkind;
foreach my $key (keys %kind)
{
  my $value = $kind{$key};
  $rkind{$value} = $key;
}


$ffi->attach( new => ['uint8'] => 'wasm_valtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner);
  if($_[0] =~ /^[0-9]+$/)
  {
    ($ptr, $owner) = @_;
  }
  else
  {
    my($kind) = @_;
    my $kind_num = $rkind{$kind};
    Carp::croak("no such value type: $kind") unless defined $kind_num;
    $ptr = $xsub->($kind_num);
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});


$ffi->attach( kind => ['wasm_valtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});


$ffi->attach( [kind => 'kind_num'] => ['wasm_valtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_valtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

_generate_vec_class( delete => 0 );

$ffi->attach( [ wasm_valtype_vec_new => 'Wasm::Wasmtime::ValTypeVec::set' ] => ['wasm_valtype_vec_t*','size_t','opaque[]'] => sub {
  my($xsub, $self, $valtypes) = @_;
  $xsub->($self, scalar(@$valtypes), $valtypes);
  $self;
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ValType - Wasmtime value type class

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $valtype = Wasm::Wasmtime::ValType->new('i32');

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a Wasm type.

=head1 CONSTRUCTOR

=head2 new

 my $valtype = Wasm::Wasmtime::ValType->new($type);

Creates a new value type instance.  Acceptable values for C<$type> are:

=over 4

=item C<i32>

Signed 32 bit integer.

=item C<i64>

Signed 64 bit integer.

=item C<f32>

Floating point.

=item C<f64>

Double precision floating point.

=item C<anyref>

A pointer.

=item C<funcref>

A function pointer.

=back

=head1 METHODS

=head2 kind

 my $kind = $valtype->kind;

Returns the value type as a string (ie C<i32>).

=head2 kind_num

 my $kind = $valtype->kind_num;

Returns the number used internally to represent the type.

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
