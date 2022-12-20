package Zonemaster::LDNS::RR::SPF;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

sub spfdata() {
    my ($rr) = @_;

    return join( "", map { substr($rr->rdf($_ - 1), 1) } 1..$rr->rd_count() );
}

1;

=head1 NAME

Zonemaster::LDNS::RR::SPF - Type SPF record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item spfdata()

Returns the concatenation of all the strings composing the data of the resource record.

For example, if an SPF resource record has the following presentation format:

    test.example. 3600 IN SPF "v=spf1 " "mx " "a " "-all"

then C<spfdata()> returns the string C<"v=spf1 mx a -all">.

=back
