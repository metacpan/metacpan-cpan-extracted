package Zonemaster::LDNS::RR::SOA;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::SOA - Type SOA record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item mname()

Returns the master server name.

=item rname()

Returns the contact mail address, in DNAME format.

=item serial()

Returns the serial number.

=item refresh()

=item retry()

=item refresh()

=item minimum()

Returns the respective timing values from the record.

=back
