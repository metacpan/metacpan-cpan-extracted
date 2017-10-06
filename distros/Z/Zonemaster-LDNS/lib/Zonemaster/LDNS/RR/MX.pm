package Zonemaster::LDNS::RR::MX;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::MX - Type MX record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item exchange()

Returns the name of the mail server.

=item preference()

Returns the preference value of the record.

=back
