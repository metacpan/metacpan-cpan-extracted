# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::IDN;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::IDN - Internationalized Domain Names (IDNs) via ICU

=head1 SYNOPSIS

    use utf8;

    my $idn = Unicode::ICU::IDN->new();

    # This takes a *character* string!
    my $ascii = $idn->name2ascii('épée.com');

    # This outputs a character string.
    my $unicode = $idn->name2unicode('xn--kxawhkp.gr');

=head1 DESCRIPTION

This module exposes simple IDN (i.e.,
L<Internationalized Domain Name|https://en.wikipedia.org/wiki/Internationalized_domain_name>) ASCII/Unicode (punycode) converters.

=head1 ERROR HANDLING: INVALID IDNs

In addition to the usual L<Unicode::ICU::X::ICU> errors, this
module also throws L<Unicode::ICU::X::BadIDN> errors if a bad IDN
is detected. If you want to tolerate bad IDNs you’ll need to convert
invalid sequences yourself beforehand.

=head1 COMPATIBILITY

This require ICU 4.6 or later.

=head1 SEE ALSO

L<Net::LibIDN2>

L<Net::IDN::UTS46>

=cut

#----------------------------------------------------------------------

use Unicode::ICU ();

our %ERROR;

#----------------------------------------------------------------------

=head1 CONSTANTS

=head2 Constructor options

See below.

=head2 %ERROR

Correlates IDN error names with error numbers.
These derive from ICU’s C<UIDNA_ERROR_*> constants.

=head1 STATIC FUNCTIONS

=head2 @labels = get_error_labels( $ERROR_NUMBER )

A convenient function that returns a list of names (e.g., C<DISALLOWED>)
from C<%ERROR> that $ERROR_NUMBER indicates. In scalar context this
returns the number of such names that would be returned in list context.

=cut

=head1 METHODS

=head2 $obj = I<CLASS>->new( [$OPTIONS] )

Instantiates this class. $OPTIONS, if given, is a numeric mask
of this module’s C<UIDNA_*> constants: C<UIDNA_DEFAULT>, etc.
(See IDN’s API documentation for others.)

=head2

=cut

sub get_error_labels {
    my ($num) = @_;

    return grep { $num & $ERROR{$_} } sort keys %ERROR;
}

1;
