package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;

require Wasm::Wasmtime::Func;
require Wasm::Wasmtime::Global;
require Wasm::Wasmtime::Table;
require Wasm::Wasmtime::Memory;

# ABSTRACT: Wasmtime extern class
our $VERSION = '0.23'; # VERSION


$ffi_prefix = 'wasm_extern_';

$ffi->attach( [ kind => '_kind' ] => ['opaque'] => 'uint8' );

my @cast;

sub _cast
{
  my(undef, $index) = @_;
  my $caller = caller;
  my($name) = map { lc $_ } $caller =~ /::([a-z]+)$/i;
  $cast[$index] = $ffi->function( "wasm_extern_as_$name" => ['opaque'] => "wasm_${name}_t" )->sub_ref;
}

$ffi->custom_type('wasm_extern_t' => {
  native_type => 'opaque',
  native_to_perl => sub {
    my $extern = shift;
    Carp::croak("extern error") unless defined $extern;
    my $kind = _kind($extern);
    $cast[$kind]->($extern);
  },
});

$ffi->attach_cast('new', 'opaque', 'wasm_extern_t',  sub {
  my($xsub, undef, $ptr, $owner) = @_;
  my $self = $xsub->($ptr);
  $self->{owner} = $owner;
  $self;
});

use constant is_func   => 0;
use constant is_global => 0;
use constant is_table  => 0;
use constant is_memory => 0;

sub kind { die "internal error" };

_generate_vec_class();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Extern - Wasmtime extern class

=head1 VERSION

version 0.23

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $instance = Wasm::Wasmtime::Instance->new(
   Wasm::Wasmtime::Module->new($store->engine, wat => q{
     (module
       (func (export "foo") (param i32 i32) (result i32)
         local.get 0
         local.get 1
         i32.add)
       (memory (export "bar") 2 3)
     )
   }),
   $store,
 );
 
 my $foo = $instance->exports->foo;
 print $foo->kind, "\n";  # func
 
 my $bar = $instance->exports->bar;
 print $bar->kind, "\n";  # memory

=head1 DESCRIPTION

This class represents an object exported from or imported into a L<Wasm::Wasmtime::Instance>.
This class cannot be created independently, but subclasses of this class can be retrieved from
the L<Wasm::Wasmtime::Instance> object.  This is a base class and cannot be instantiated on its own.

It is a base class.

=head1 METHODS

=head2 kind

 my $string = $extern->kind;

Returns the extern kind as a string.  This will be one of:

=over 4

=item C<func> L<Wasm::Wasmtime::Func>

=item C<global> L<Wasm::Wasmtime::Global>

=item C<table> L<Wasm::Wasmtime::Table>

=item C<memory> L<Wasm::Wasmtime::Memory>

=back

=head2 is_func

 my $bool = $extern->is_func;

Returns true if it is a function.

=head2 is_global

 my $bool = $extern->is_global;

Returns true if it is a global.

=head2 is_table

 my $bool = $extern->is_table;

Returns true if it is a table.

=head2 is_memory

 my $bool = $extern->is_memory;

Returns true if it is a memory.

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
