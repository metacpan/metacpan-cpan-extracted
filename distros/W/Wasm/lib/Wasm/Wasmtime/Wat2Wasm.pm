package Wasm::Wasmtime::Wat2Wasm;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use base qw( Exporter );

# ABSTRACT: Convert WebAssembly Text to Wasm
our $VERSION = '0.23'; # VERSION


our @EXPORT = qw( wat2wasm );

$ffi_prefix = 'wasmtime_';


$ffi->attach( wat2wasm => ['wasm_byte_vec_t*','wasm_byte_vec_t*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $wat = Wasm::Wasmtime::ByteVec->new($_[0]);
  my $ret = Wasm::Wasmtime::ByteVec->new;
  my $error = $xsub->($wat, $ret);
  if($error)
  {
    Carp::croak($error->message . "\nwat2wasm error");
  }
  else
  {
    my $wasm = $ret->get;
    $ret->delete;
    return $wasm;
  }
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Wat2Wasm - Convert WebAssembly Text to Wasm

=head1 VERSION

version 0.23

=head1 SYNOPSIS

 use Wasm::Wasmtime::Wat2Wasm;
 
 my $wasm = wat2wasm('(module)');

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This module provides C<wat2wasm>, a function for converting WebAssembly Text to WebAssembly binary format (Wasm).
It is exported by default.

=head1 FUNCTIONS

=head2 wat2wasm

 my $wasm = wat2wasm($wat);

Takes WebAssembly Text C<$wat> and converts it into the WebAssembly binary C<$wasm>.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
