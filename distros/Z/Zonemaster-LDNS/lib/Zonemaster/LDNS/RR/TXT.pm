package Zonemaster::LDNS::RR::TXT;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

sub txtdata() {
    my ($rr) = @_;

    return join( "", map { substr($rr->rdf($_ - 1), 1) } 1..$rr->rd_count() );
}

1;

=head1 NAME

Zonemaster::LDNS::RR::TXT - Type TXT record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item txtdata()

Returns the concatenation of all the strings composing the data of the resource record.

For example, if a TXT resource record has the following presentation format:

    txt.test.example. 3600 IN TXT "I " "am " "split up in " "lit" "tle pieces"

then C<txtdata()> returns the string C<"I am split up in little pieces">.

=back
