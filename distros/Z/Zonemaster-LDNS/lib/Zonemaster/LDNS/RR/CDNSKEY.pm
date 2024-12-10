package Zonemaster::LDNS::RR::CDNSKEY;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR::DNSKEY';

1;

=head1 NAME

Zonemaster::LDNS::RR::CDNSKEY - Type CDNSKEY record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR::DNSKEY>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

No other specific methods implemented.

Note that the inherited parent methods L<Zonemaster::LDNS::RR::DNSKEY/keytag()> and L<Zonemaster::LDNS::RR::DNSKEY/ds($hash)> will always return 0, as LDNS currently only supports the DNSKEY RR type for those methods.

=cut
