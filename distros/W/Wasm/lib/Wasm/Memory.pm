package Wasm::Memory;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::Caller ();
use base qw( Exporter );

our @EXPORT_OK = qw( wasm_caller_memory );

# ABSTRACT: Interface to WebAssembly Memory
our $VERSION = '0.22'; # VERSION


sub wasm_caller_memory
{
  my $caller = Wasm::Wasmtime::Caller::wasmtime_caller();
  defined $caller
    ? do {
      my $wm = $caller->export_get('memory');
      defined $wm && $wm->is_memory
        ? __PACKAGE__->new($wm)
        : undef;
    } : undef;
}

sub new
{
  my($class, $memory) = @_;
  bless \$memory, $class;
}


sub address { ${shift()}->data      }
sub size    { ${shift()}->data_size }


sub limits
{
  my $self   = shift;
  my $memory = $$self;
  my $type   = $memory->type;
  ($memory->size, @{ $type->limits });
}


sub grow
{
  my($self, $count) = @_;
  ${$self}->grow($count);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Memory - Interface to WebAssembly Memory

=head1 VERSION

version 0.22

=head1 SYNOPSIS

Use WebAssembly memory from plain Perl:

 use PeekPoke::FFI qw( peek poke );
 use Wasm
   -api => 0,
   -wat => q{
     (module
       (memory (export "memory") 3 9)
     )
   }
 ;
 
 # $memory isa Wasm::Memory
 poke($memory->address + 10, 42);                # store the byte 42 at offset
                                                 # 10 inside the data region
 
 my($current, $min, $max) = $memory->limits;
 printf "size    = %x\n", $memory->size;         # 30000
 printf "current = %d\n", $current;              # 3
 printf "min     = %d\n", $min;                  # 3
 printf "max     = %d\n", $max;                  # 9
 
 $memory->grow(4);                               # increase data region by 4 pages
 
 ($current, $min, $max) = $memory->limits;
 printf "size    = %x\n", $memory->size;         # 70000
 printf "current = %d\n", $current;              # 7
 printf "min     = %d\n", $min;                  # 3
 printf "max     = %d\n", $max;                  # 9

Use WebAssembly memory from Perl in callback from WebAssembly:

 use Wasm::Memory qw( wasm_caller_memory );
 
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
   my $memory = wasm_caller_memory;
   print cstring($ptr + $memory->address);
 }
 
 use Wasm
   -api => 0,
   -wat => q{
     (module
       (import "main" "print_wasm_string" (func $print_wasm_string (param i32)))
       (func (export "run")
         i32.const 0
         call $print_wasm_string
       )
       (memory (export "memory") 1)
       (data (i32.const 0) "Hello, world!\n\00")
     )
   },
 ;
 
 run();

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This class represents a region of memory exported from a WebAssembly
module.  A L<Wasm::Memory> instance is automatically imported into
Perl space for each WebAssembly memory region with the same name.

=head1 FUNCTIONS

=head2 wasm_caller_memory

 my $memory = wasm_caller_memory;

Returns the memory region of the WebAssembly caller, if Perl has been
called by Wasm, otherwise it returns C<undef>.

This function can be exported by request via L<Exporter>.

=head1 METHODS

=head2 address

 my $pointer = $memory->address;

Returns an opaque pointer to the start of memory.

=head2 size

 my $size = $memory->size;

Returns the size of the memory in bytes.

=head2 limits

 my($current, $min, $max) = $memory->limits;

Returns the current memory limit, the minimum and maximum.  All sizes
are in pages.

=head2 grow

 $memory->grow($count);

Grown the memory region by C<$count> pages.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
