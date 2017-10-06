package Zonemaster::LDNS::RRList;

1;

=head1 NAME

Zonemaster::LDNS::RR - common baseclass for all classes representing resource records.

=head1 SYNOPSIS

    my $rrlist = $packet->all;

=head1 INSTANCE METHODS

=over

=item count()

Returns the number of items in the list.

=item push($rr)

Pushes an RR onto the list.

=item pop()

Pops an RR off the list.

=item is_rrset()

Returns true or false depending on if the list is an RRset or not.

=back
