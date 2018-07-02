package Zonemaster::LDNS::RR::NSEC3PARAM;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::NSEC3PARAM - Type NSEC3PARAM record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item algorithm()

Returns the algorithm number.

=item flags()

Returns the flags field.

=item iterations()

Returns the iteration count.

=item salt()

Returns the cryptographic salt in binary form.

=back
