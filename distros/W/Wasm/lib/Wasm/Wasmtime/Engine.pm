package Wasm::Wasmtime::Engine;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Config;

# ABSTRACT: Wasmtime engine class
our $VERSION = '0.06'; # VERSION


$ffi_prefix = 'wasm_engine_';
$ffi->load_custom_type('::PtrObject' => 'wasm_engine_t' => __PACKAGE__ );


$ffi->attach( [ 'new_with_config' => 'new' ] => ['wasm_config_t'] => 'wasm_engine_t' => sub {
  my($xsub, $class, $config) = @_;
  $config ||= Wasm::Wasmtime::Config->new;
  my $self = $xsub->($config),
  delete $config->{ptr};
  $self;
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Engine - Wasmtime engine class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $engine = Wasm::Wasmtime::Engine->new;

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the main WebAssembly engine.  It can optionally
be configured with a L<Wasm::Wasmtime::Config> object.

=head1 CONSTRUCTOR

=head2 new

 my $engine = Wasm::Wasmtime::Engine->new;
 my $engine = Wasm::Wasmtime::Engine->new(
   $config, # Wasm::Wasmtime::Config
 );

Creates a new instance of the engine class.

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
