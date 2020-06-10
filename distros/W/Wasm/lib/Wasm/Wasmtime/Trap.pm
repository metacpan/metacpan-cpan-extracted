package Wasm::Wasmtime::Trap;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;

# ABSTRACT: Wasmtime trap class
our $VERSION = '0.14'; # VERSION


$ffi_prefix = 'wasm_trap_';
$ffi->load_custom_type('::PtrObject' => 'wasm_trap_t' => __PACKAGE__);


$ffi->attach( new => [ 'wasm_store_t', 'wasm_byte_vec_t*' ] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(@_ == 1)
  {
    my $ptr = shift;
    return bless {
      ptr => $ptr,
    }, $class;
  }
  else
  {
    my $store = shift;
    my $message = Wasm::Wasmtime::ByteVec->new($_[0]);
    return $xsub->($store, $message);
  }
});


$ffi->attach( message => ['wasm_trap_t', 'wasm_byte_vec_t*'] => sub {
  my($xsub, $self) = @_;
  my $message = Wasm::Wasmtime::ByteVec->new;
  $xsub->($self, $message);
  my $ret = $message->get;
  $ret =~ s/\0$//;
  $message->delete;
  $ret;
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Trap - Wasmtime trap class

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $trap = Wasm::Wasmtime::Trap->new(
   $store,
   "something went bump in the night\0",
 );

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a trap, usually something unexpected that happened in Wasm land.
This is usually converted into an exception in Perl land, but you can create your
own trap here.

=head1 CONSTRUCTORS

=head2 new

 my $trap = Wasm::Wasmtime::Trap->new(
   $store,    # Wasm::Wasmtime::Store
   $message,  # Null terminated string
 );

Create a trap instance.  C<$message> MUST be null terminated.

=head1 METHODS

=head2 message

 my $message = $trap->message;

Returns the trap message as a string.

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
