package Zonemaster::LDNS::RRList;

use strict;
use warnings;

use overload '<=>' => \&do_compare, 'cmp' => \&do_compare, '""' => \&to_string;

sub do_compare {
    my ( $self, $other, $swapped ) = @_;

    return $self->compare( $other );
}

sub to_string {
    my ( $self ) = @_;

    return $self->string;
}

1;

=head1 NAME

Zonemaster::LDNS::RRList - class representing lists of resource records.

=head1 SYNOPSIS

    my $rrlist = Zonemaster::LDNS::RRList->new( $rrs_aref );

=head1 CLASS METHODS

=over

=item new()

Creates a new empty L<Zonemaster::LDNS::RRList> object.

=back

=item new($rrs)

Creates a new L<Zonemaster::LDNS::RRList> object for the given resource records.

Takes a reference to an array of L<Zonemaster::LDNS::RR> objects.

Returns a L<Zonemaster::LDNS::RRList> object.

=back

=head1 INSTANCE METHODS

=over

=item count()

Returns the number of RRs in the list.

=item compare($other)

Compares two L<Zonemaster::LDNS::RRList>. The order of L<Zonemaster::LDNS::RR> objects in the list does not matter.
The TTL field is ignored, and the comparison of domain names is case insensitive.

Returns an integer, where 0 indicates equality.

=item get($pos)

    my $rr = Zonemaster::LDNS::RRList->get( 0 );

Retrieves the RR in the given position from the list.

Takes an integer.

Returns a L<Zonemaster::LDNS::RR> object, or C<undef> if there was no RR.

=item push($rr)

Pushes an RR onto the list.

=item pop()

Pops an RR off the list.

=item is_rrset()

Returns true or false depending on if the list is an RRset or not.

Note that the underlying LDNS function appears to have a bug as the comparison of the owner name field is case sensitive. See https://github.com/NLnetLabs/ldns/pull/251.

=item string()

Returns a string with the list of RRs in presentation format.

=item do_compare($other)

Calls the XS C<compare> method with the arguments it needs, rather than the ones overloading gives.

=item to_string

Calls the XS C<string> method with the arguments it needs, rather than the ones overloading gives. Functionally identical to L<string()> from the
Perl level, except for being a tiny little bit slower.

=back
