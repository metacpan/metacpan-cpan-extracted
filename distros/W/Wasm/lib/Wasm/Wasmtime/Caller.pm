package Wasm::Wasmtime::Caller;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Extern;
use base qw( Exporter );

our @EXPORT = qw( wasmtime_caller );

$ffi_prefix = 'wasmtime_caller_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_caller_t' => __PACKAGE__);

# ABSTRACT: Wasmtime caller interface
our $VERSION = '0.17'; # VERSION


our @callers;

sub wasmtime_caller (;$)
{
  $callers[$_[0]||0]
}


sub new
{
  my($class, $ptr) = @_;
  bless {
    ptr => $ptr,
  }, $class;
}

$ffi->attach( export_get => ['wasmtime_caller_t','wasm_byte_vec_t*'] => 'wasm_extern_t' => sub {
  my $xsub = shift;
  my $self = shift;
  return undef unless $self->{ptr};
  my $name = Wasm::Wasmtime::ByteVec->new($_[0]);
  $xsub->($self, $name);
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Caller - Wasmtime caller interface

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 use Wasm::Wasmtime::Caller qw( wasmtime_caller );
 
 {
   # this just uses Platypus to create a utility function
   # to convert a pointer to a C string into a Perl string.
   use FFI::Platypus 1.00;
   my $ffi = FFI::Platypus->new( api => 1 );
   $ffi->attach_cast( 'cstring' => 'opaque' => 'string' );
 }
 
 sub print_wasm_string
 {
   my $ptr = shift;
   my $caller = wasmtime_caller;
   my $memory = $caller->export_get('memory');
   print cstring($ptr + $memory->data);
 }
 
 my $store = Wasm::Wasmtime::Store->new;
 my $instance = Wasm::Wasmtime::Instance->new(
   Wasm::Wasmtime::Module->new($store, wat => q{
     (module
       (import "" "print_wasm_string" (func $print_wasm_string (param i32)))
       (func (export "run")
         i32.const 0
         call $print_wasm_string
       )
       (memory (export "memory") 1)
       (data (i32.const 0) "Hello, world!\n\00")
     )
   }),
   $store,
   [\&print_wasm_string],
 );
 
 $instance->exports->run->();

=head1 DESCRIPTION

This class represents the caller's context when calling a Perl L<Wasm::Wasmtime::Func> from
WebAssembly.  The primary purpose of this structure is to provide access to the caller's
exported memory.  This allows functions which take pointers as arguments to easily read the
memory the pointers point into.

This is intended to be a pretty temporary mechanism for accessing the Caller's memory until
interface types has been fully standardized and implemented.

=head1 FUNCTIONS

=head2 wasmtime_caller

 my $caller = wasmtime_caller;
 my $caller = wasmtime_caller $index;

This returns the current caller context (an instance of L<Wasm::Wasmtime::Caller>).  If
the current Perl code wasn't called from WebAssembly, then it will return C<undef>.  If
C<$index> is given, then that indicates how many WebAssembly call frames to go back
before the current one.  (This is vaguely similar to how the Perl C<caller> function
works).

This function is exported by default using L<Exporter>.

=head1 METHODS

=head2 export_get

 my $extern = $caller->export_get($name);

Returns the L<Wasm::Wasmtime::Extern> for the named export C<$name>.  As of this writing,
only L<Wasm::Wasmtime::Memory> types are supported.

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
