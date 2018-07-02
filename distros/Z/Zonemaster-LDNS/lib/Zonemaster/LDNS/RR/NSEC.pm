package Zonemaster::LDNS::RR::NSEC;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

sub nxtdname {
    return $_[0]->next;
}

1;

=head1 NAME

Zonemaster::LDNS::RR::NSEC - Type NSEC record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item next()

Returns the next name.

=item nxtdname()

Alias for C<next()>.

=item typelist()

Returns a string with the typelist. The string has the type names separated by spaces.

=item typehref()

Returns a reference to a hash, where the keys are the type names and the corresponding values are true. That is, if you look for a type in this hash
you get a true value back if the record covers it and false if not.

=item covers($name)

Returns true or false depending on if the record covers the given name or not.

=back
