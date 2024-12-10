package Zonemaster::LDNS::RR::CDS;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR::DS';

1;

=head1 NAME

Zonemaster::LDNS::RR::CDS - Type CDS record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR::DS>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

No other specific methods implemented.

Note that the inherited parent methods L<Zonemaster::LDNS::RR::DS/verify($other)> will always return false, as LDNS currently only supports the DS and DNSKEY RR types for this method.

=cut
