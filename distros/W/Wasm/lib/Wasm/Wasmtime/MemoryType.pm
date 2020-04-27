package Wasm::Wasmtime::MemoryType;

use strict;
use warnings;
use Ref::Util qw( is_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime memory type class
our $VERSION = '0.06'; # VERSION


$ffi_prefix = 'wasm_memorytype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_memorytype_t' => __PACKAGE__);


$ffi->attach( new => ['uint32[2]'] => 'wasm_memorytype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_ref $_[0])
  {
    my $limit = shift;
    Carp::croak("bad limits") unless is_plain_arrayref($limit);
    Carp::croak("no minumum in limit") unless defined $limit->[0];
    $limit->[1] = 0xffffffff unless defined $limit->[1];
    return $xsub->($limit);
  }
  else
  {
    my ($ptr, $owner) = @_;
    return bless {
      ptr => $ptr,
      owner => $owner,
    }, $class;
  }
});


$ffi->attach( limits => ['wasm_memorytype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  my $limits = $xsub->($self);
  $limits;
});


# actually returns a wasm_externtype_t, but recursion
$ffi->attach( as_externtype => ['wasm_memorytype_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::ExternType;
  my $ptr = $xsub->($self);
  Wasm::Wasmtime::ExternType->new($ptr, $self->{owner} || $self);
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::MemoryType - Wasmtime memory type class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 # new memory type with minimum 3 and maximum 5 pages
 my $memorytype = Wasm::Wasmtime::MemoryType->new([3,5]);

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a module memory type.  It models the minimum and
maximum number of pages.

=head1 CONSTRUCTOR

=head2 new

 my $memorytype = Wasm::Wasmtime::MemoryType->new([
   $min,  # minumum number of pages
   $max   # maximum number of pages
 ]);

Creates a new memory type object.

=head2 limits

 my $limits = $memorytype->limits;

Returns the minimum and maximum number of pages as an array reference.

=head2 as_externtype

 my $externtype = $memorytype->as_externtype

Returns the L<Wasm::Wasmtime::ExternType> for this memory type.

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
