package Wasm::Wasmtime::Global;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::CBC qw( perl_to_wasm wasm_allocate wasm_to_perl );

# ABSTRACT: Wasmtime global class
our $VERSION = '0.06'; # VERSION


$ffi_prefix = 'wasm_global_';
$ffi->load_custom_type('::PtrObject' => 'wasm_global_t' => __PACKAGE__);


$ffi->attach( new => ['wasm_store_t', 'wasm_globaltype_t', 'string'] => 'wasm_global_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_ref $_[0])
  {
    my($store, $globaltype, $value) = @_;
    my $self = $xsub->($store, $globaltype, perl_to_wasm([$value], [$globaltype->content]));
    $self->{store} = $store;
    return $self;
  }
  else
  {
    my($ptr, $owner) = @_;
    bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});


$ffi->attach( type => ['wasm_global_t'] => 'wasm_globaltype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});


$ffi->attach( get => ['wasm_global_t', 'string'] => sub {
  my($xsub, $self) = @_;
  my $value = wasm_allocate(1);
  $xsub->($self, $value);
  ($value) = wasm_to_perl($value);
  $value;
});


$ffi->attach( set => ['wasm_global_t','string'] => sub {
  my($xsub, $self, $value) = @_;
  $xsub->($self, perl_to_wasm([$value],[$self->type->content]));
});


# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_global_t'] => 'opaque' => sub {
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

Wasm::Wasmtime::Global - Wasmtime global class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $store = Wasm::Wasmtime::Store->new;
 my $global = Wasm::Wasmtime::Global->new(
   $store,
   Wasm::Wasmtime::GlobalType->new('i32','var'),
   42,
 );
 
 print $global->get, "\n";  # 42
 $global->set(99);
 print $global->get, "\n";  # 99

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly global object.

=head1 CONSTRUCTOR

=head2 new

 my $global = Wasm::Wasmtime::Global->new(
   $store,      # Wasm::Wasmtime::Store
   $globaltype, # Wasm::Wasmtime::GlobalType
 );

Creates a new global object.

=head1 METHODS

=head2 type

 my $globaltype = $global->type;

Returns the L<Wasm::Wasmtime::GlobalType> object for this global object.

=head2 get

 my $value = $global->get;

Gets the global value.

=head2 set

 my $global->set($value);

Sets the global to the given value.

=head2 as_extern

 my $extern = $global->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this global object.

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
