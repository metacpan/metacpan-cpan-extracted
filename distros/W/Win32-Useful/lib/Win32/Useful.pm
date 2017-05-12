package Win32::Useful;

use strict;
use warnings;

use vars qw/$VERSION/;
$VERSION = '0.02';

use Win32 ();

=head1 NAME

Win32::Useful - Collection of useful functions that extend Win32 functionality 

=head1 FUNCTIONS

=head2 IsLastError( $errorcode )

Checks whether or not I<Win32::GetLastError()> is equal to the the given
errorcode. Returns a I<True> value if they are equal, 0 otherwise.

Compares the values as unsigned values, so you do not have to cope
with I<Win32::GetLastError()> returning a signed integer.  

=cut

sub IsLastError {
	return sprintf("%u", shift) == sprintf("%u", Win32::GetLastError());
}

=head1 AUTHOR

Sascha Kiefer, L<esskar@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Sascha Kiefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;