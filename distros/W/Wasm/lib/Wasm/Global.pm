package Wasm::Global;

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

Wasm::Global - Interface to WebAssembly Memory

=head1 VERSION

version 0.18

=head1 SYNOPSIS

Import globals into Perl from WebAssembly

 use Wasm
   -api => 0,
   -wat => q{
     (module
       (global (export "global") (mut i32) (i32.const 42))
     )
   }
 ;
 
 print "$global\n";  # 42
 $global = 99;
 print "$global\n";  # 99

Import globals from Perl into WebAssembly

 package Foo;
 
 use Wasm
   -api    => 0,
   -global => [
     'foo',  # name
     'i32',  # type
     'var',  # mutability
     42,     # initial value
   ]
 ;
 
 package Bar;
 
 use Wasm
   -api      => 0,
   -wat      => q{
     (module
       (global $foo (import "Foo" "foo") (mut i32))
       (func (export "get_foo") (result i32)
         (global.get $foo))
       (func (export "inc_foo")
         (global.set $foo
           (i32.add (global.get $foo) (i32.const 1))))
     )
   }
 ;
 
 package main;
 
 print Bar::get_foo(), "\n";   # 42
 Bar::inc_foo();
 print Bar::get_foo(), "\n";   # 43
 $Foo::foo = 0;
 print Bar::get_foo(), "\n";   # 0

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This documents the interface to global variables for L<Wasm>.
Each global variable exported from WebAssembly is automatically
imported into Perl space as a tied scalar, which allows you to get
and set the variable easily from Perl.  Going the other way
requires a bit more boilerplate, but is almost as easy.  Using
the C<-global> option on the L<Wasm> module, you can define global
variables in Pure Perl modules that can be imported into WebAssembly
from Perl.

=head1 CAVEATS

Note that depending on the
storage of the global variable setting might be lossy and round-trip
isn't guaranteed.  For example for integer types, if you set a string
value it will be converted to an integer using the normal Perl string
to integer conversion, and when it comes back you will just have
the integer value.

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
