package Wasm::Wasmtime::Store;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;

# ABSTRACT: Wasmtime store class
our $VERSION = '0.10'; # VERSION


$ffi_prefix = 'wasm_store_';
$ffi->load_custom_type('::PtrObject' => 'wasm_store_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
  my($xsub, $class, $engine) = @_;
  $engine ||= Wasm::Wasmtime::Engine->new;
  my $self = $xsub->($engine);
  $self->{engine} = $engine;
  $self;
});


sub engine { shift->{engine} }

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Store - Wasmtime store class

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents storage used by the WebAssembly engine.

=head1 CONSTRUCTOR

=head2 new

 my $store = Wasm::Wasmtime::Store->new;
 my $store = Wasm::Wasmtime::Store->new(
   $engine,   # Wasm::Wasmtime::Engine
 );

Creates a new storage instance.  If the optional L<Wasm::Wasmtime::Engine> object
isn't provided, then a new one will be created.

=head2 engine

 my $engine = $store->engine;

Returns the L<Wasm::Wasmtime::Engine> object for this storage object.

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
