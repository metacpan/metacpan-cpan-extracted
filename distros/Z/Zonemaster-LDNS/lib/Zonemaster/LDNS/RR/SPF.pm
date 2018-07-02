package Zonemaster::LDNS::RR::SPF;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::SPF - Type SPF record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item spfdata()

Returns the SPF string.

=back
