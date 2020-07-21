package Wasm::Wasmtime::Table;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::TableType;
use constant is_table => 1;
use constant kind => 'table';

# ABSTRACT: Wasmtime table class
our $VERSION = '0.17'; # VERSION


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

__PACKAGE__->_cast(2);
_generate_destroy();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Table - Wasmtime table class

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $instance = Wasm::Wasmtime::Instance->new(
   Wasm::Wasmtime::Module->new($store, wat => q{
     (module
       (table (export "table") 1 funcref)
     )
   }),
   $store,
 );
 
 my $table = $instance->exports->table;
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
