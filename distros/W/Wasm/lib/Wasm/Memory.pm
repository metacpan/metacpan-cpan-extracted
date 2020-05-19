package Wasm::Memory;

use strict;
use warnings;

# ABSTRACT: Interface to Web Assembly Memory
our $VERSION = '0.10'; # VERSION


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

Wasm::Memory - Interface to Web Assembly Memory

=head1 VERSION

version 0.10

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class represents a region of memory exported from a WebAssembly
module.  A L<Wasm::Memory> instance is automatically imported into
Perl space for each WebAssembly memory region with the same name.

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

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
