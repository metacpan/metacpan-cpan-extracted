package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;

require Wasm::Wasmtime::FuncType;
require Wasm::Wasmtime::GlobalType;
require Wasm::Wasmtime::TableType;
require Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime extern type class
our $VERSION = '0.17'; # VERSION


sub kind { die "internal error" };
use constant is_functype   => 0;
use constant is_globaltype => 0;
use constant is_tabletype  => 0;
use constant is_memorytype => 0;

$ffi_prefix = 'wasm_externtype_';

$ffi->attach( [ kind => '_kind' ] => ['opaque'] => 'uint8' );

my @cast;

sub _cast
{
  my(undef, $index) = @_;
  my $caller = caller;
  my($name) = map { lc $_ } $caller =~ /::([a-z]+Type)$/i;
  $cast[$index] = $ffi->function( "wasm_externtype_as_$name" => ['opaque'] => "wasm_${name}_t" )->sub_ref;
}

$ffi->custom_type('wasm_externtype_t' => {
  native_type => 'opaque',
  native_to_perl => sub {
    my $externtype = shift;
    Carp::croak("externtype error") unless defined $externtype;
    my $kind = _kind($externtype);
    $cast[$kind]->($externtype);
  },
});


sub to_string
{
  die "internal error";  # pure virtual ish
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ExternType - Wasmtime extern type class

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $module = Wasm::Wasmtime::Module->new(wat => q{
   (module
     (func (export "foo") (param i32 i32) (result i32)
       local.get 0
       local.get 1
       i32.add)
     (memory (export "bar") 2 3)
   )
 });
 
 my $foo = $module->exports->foo;
 print $foo->kind, "\n";  # functype
 
 my $bar = $module->exports->bar;
 print $bar->kind, "\n";  # memorytype

=head1 DESCRIPTION

This class represents an extern type. This class cannot be created independently, but subclasses of this class can be retrieved from the L<Wasm::Wasmtime::Module> object.
This is a base class and cannot be instantiated on its own.

=head1 METHODS

=head2 kind

 my $string = $externtype->kind;

Returns the extern type kind as a string.  This will be one of:

=over 4

=item C<functype> L<Wasm::Wasmtime::FuncType>

=item C<globaltype> L<Wasm::Wasmtime::GlobalType>

=item C<tabletype> L<Wasm::Wasmtime::TableType>

=item C<memorytype> L<Wasm::Wasmtime::MemoryType>

=back

=head2 is_functype

 my $bool = $externtype->is_functype;

Returns true if it is a function type.

=head2 is_globaltype

 my $bool = $externtype->is_globaltype;

Returns true if it is a global type.

=head2 is_tabletype

 my $bool = $externtype->is_tabletype;

Returns true if it is a table type.

=head2 is_memorytype

 my $bool = $externtype->is_memorytype;

Returns true if it is a memory type.

=head2 to_string

 my $string = $externtype->to_string;

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
