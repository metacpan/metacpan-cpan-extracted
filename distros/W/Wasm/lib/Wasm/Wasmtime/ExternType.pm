package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::TableType;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime extern type class
our $VERSION = '0.04'; # VERSION


$ffi_prefix = 'wasm_externtype_';
$ffi->type('opaque' => 'wasm_externtype_t');

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

my %kind = (
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
);


$ffi->attach( kind => ['wasm_externtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});


$ffi->attach( [ kind => 'kind_num' ] => ['wasm_externtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});


$ffi->attach( as_functype => ['wasm_externtype_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::FuncType->new($ptr, $self->{owner} || $self) : undef;
});


$ffi->attach( as_globaltype => ['wasm_externtype_t'] => 'wasm_globaltype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::GlobalType->new($ptr, $self->{owner} || $self) : undef;
});


$ffi->attach( as_tabletype => ['wasm_externtype_t'] => 'wasm_tabletype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::TableType->new($ptr, $self->{owner} || $self) : undef;
});


$ffi->attach( as_memorytype => ['wasm_externtype_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::MemoryType->new($ptr, $self->{owner} || $self) : undef;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_externtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime::ExternType - Wasmtime extern type class

=head1 VERSION

version 0.04

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
 
 my $externtype_foo = $module->get_export('foo');
 print $externtype_foo->kind, "\n";  # func
 
 my $externtype_bar = $module->get_export('bar');
 print $externtype_bar->kind, "\n";  # memory

=head1 DESCRIPTION

This class represents an extern type.  This class cannot be created independently, but can be
retrieved from the L<Wasm::Wasmtime::Module> class.

=head1 METHODS

=head2 kind

 my $kind = $externtype->kind;

Returns the kind of extern type.  Should be one of:

=over 4

=item C<func>

=item C<global>

=item C<table>

=item C<memory>

=back

=head2 kind_num

 my $kind = $externtype->kind_num;

Returns the kind of extern type as the internal integer code.

=head2 as_functype

 my $functype = $externtype->as_functype;

If the extern type is a function, returns the L<Was::Wasmtime::FuncType> for it.
Otherwise returns C<undef>.

=head2 as_globaltype

 my $globaltype = $externtype->as_globaltype;

If the extern type is a global object, returns the L<Was::Wasmtime::GlobalType> for it.
Otherwise returns C<undef>.

=head2 as_tabletype

 my $tabletype = $externtype->as_tabletype;

If the extern type is a table object, returns the L<Was::Wasmtime::TableType> for it.
Otherwise returns C<undef>.

=head2 as_memorytype

 my $memorytype = $externtype->as_memorytype;

If the extern type is a memory object, returns the L<Was::Wasmtime::MemoryType> for it.
Otherwise returns C<undef>.

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
