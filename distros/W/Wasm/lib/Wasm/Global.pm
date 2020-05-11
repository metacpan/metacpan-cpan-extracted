package Wasm::Global;

use strict;
use warnings;

# ABSTRACT: Interface to Web Assembly Memory
our $VERSION = '0.09'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Global - Interface to Web Assembly Memory

=head1 VERSION

version 0.09

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class represents a global variable exported from a WebAssembly
module.  Each global variable exported from WebAssembly is automatically
imported into Perl space as a tied scalar, which allows you to get
and set the variable easily from Perl.

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
