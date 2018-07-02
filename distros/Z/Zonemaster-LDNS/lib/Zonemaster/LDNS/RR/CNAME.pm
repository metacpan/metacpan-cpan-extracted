package Zonemaster::LDNS::RR::CNAME;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::CNAME - Type CNAME record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item cname()

Returns the canonical name.

=back
