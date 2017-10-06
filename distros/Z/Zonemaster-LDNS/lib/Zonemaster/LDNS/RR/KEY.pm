
package Zonemaster::LDNS::RR::KEY;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::KEY - Type KEY record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item flags()

Returns the flag field as a number.

=item protocol()

Returns the protocol number.

=item algorithm()

Returns the algorithm number.

=item keydata()

Returns the cryptographic key in binary form.

=cut
