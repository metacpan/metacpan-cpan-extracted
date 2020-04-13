package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime extern class
our $VERSION = '0.03'; # VERSION


$ffi_prefix = 'wasm_extern_';
$ffi->type('opaque' => 'wasm_extern_t');

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}


$ffi->attach( type => ['wasm_extern_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new($xsub->($self->{ptr}), undef);
});

my %kind = (
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
);


$ffi->attach( kind => ['wasm_extern_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});


$ffi->attach( [ kind => 'kind_num' ] => ['wasm_extern_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});


$ffi->attach( as_func => ['wasm_extern_t'] => 'wasm_func_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  return undef unless $ptr;
  Wasm::Wasmtime::Func->new($ptr, $self->{owner} || $self);
});


$ffi->attach( as_memory => ['wasm_extern_t'] => 'wasm_memory_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  return undef unless $ptr;
  Wasm::Wasmtime::Memory->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_extern_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

_generate_vec_class();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::Extern - Wasmtime extern class

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 
 my $instance = Wasm::Wasmtime::Instance->new(
   Wasm::Wasmtime::Module->new(wat => q{
     (module
       (func (export "foo") (param i32 i32) (result i32)
         local.get 0
         local.get 1
         i32.add)
       (memory (export "bar") 2 3)
     )
   }),
 );
 
 my $externtype_foo = $instance->get_export('foo');
 print $externtype_foo->kind, "\n";  # func
 
 my $externtype_bar = $instance->get_export('bar');
 print $externtype_bar->kind, "\n";  # memory

=head1 DESCRIPTION

This class represents an object exported from L<Wasm::Wasmtime::Instance>.

=head1 METHODS

=head2 type

 my $externtype = $extern->type;

Returns the L<Wasm::Wasmtime::ExternType> for this extern.

=head2 kind

 my $kind = $extern->kind;

Returns the kind of extern.  Should be one of:

=over 4

=item C<func>

=item C<global>

=item C<table>

=item C<memory>

=back

=head2 kind_num

 my $kind = $extern->kind_num;

Returns the kind of extern as the internal integer used by Wasmtime.

=head2 as_func

 my $func = $extern->as_func;

If the extern is a C<func>, returns its L<Wasm::Wasmtime::Func>.
Otherwise returns C<undef>.

=head2 as_memory

 my $memory = $extern->as_memory;

If the extern is a C<memory>, returns its L<Wasm::Wasmtime::Memory>.
Otherwise returns C<undef>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
