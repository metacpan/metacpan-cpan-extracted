package Zonemaster::LDNS::RR::DNAME;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::DNAME - Type DNAME record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item dname()

Returns the delegation name, i.e. the <target> field from the RDATA of a DNAME record.

=back
