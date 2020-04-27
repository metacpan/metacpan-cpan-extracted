package Wasm::Wasmtime::Table;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::TableType;

# ABSTRACT: Wasmtime table class
our $VERSION = '0.06'; # VERSION


$ffi_prefix = 'wasm_table_';
$ffi->load_custom_type('::PtrObject' => 'wasm_table_t' => __PACKAGE__);

sub new
{
  # TODO: add wasm_table_new for standalone support
  # TODO: add wasm_table_set
  # TODO: add wasm_table_get
  # TODO: add wasm_table_grow
  my($class, $ptr, $owner) = @_;
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
}


$ffi->attach( type => ['wasm_table_t'] => 'wasm_tabletype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});


$ffi->attach( size => ['wasm_table_t'] => 'uint32' );


# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_table_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self);
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Table - Wasmtime table class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $instance = Wasm::Wasmtime::Instance->new(
   Wasm::Wasmtime::Module->new(wat => q{
     (module
       (table (export "table") 1 funcref)
     )
   }),
 );
 
 my $table = $instance->get_export('table')->as_table;
 print $table->type->element->kind, "\n";   # funcref
 print $table->size, "\n";                  # 1

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly table object.

=head1 METHODS

=head2 type

 my $tabletype = $table->type;

Returns the L<Wasm::Wasmtime::TableType> object for this table object.

=head2 size

 my $size = $table->size;

Returns the size of the table.

=head2 as_extern

 my $extern = $table->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this table object.

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
