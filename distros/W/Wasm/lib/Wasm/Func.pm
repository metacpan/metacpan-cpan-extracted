package Wasm::Func;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Interface to WebAssembly Memory
our $VERSION = '0.18'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Func - Interface to WebAssembly Memory

=head1 VERSION

version 0.18

=head1 SYNOPSIS

Call Wasm from Perl:

 use Wasm
   -api => 0,
   -wat => q{
     (module
       (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
     )
   }
 ;
 
 print add(1,2), "\n";  # 3

Call Perl from Wasm:

 sub hello {
   print "hello world!\n";
 }
 
 use Wasm
   -api => 0,
   -wat => q{
     (module
       (func $hello (import "main" "hello"))
       (func (export "run") (call $hello))
     )
   }
 ;
 
 run();   # hello world!

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This documents the interface to functions for L<Wasm>.
Each function exported from WebAssembly is automatically
imported into Perl space as a Perl subroutine.  Wasm modules
can import Perl subroutines using their standard import process.

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
