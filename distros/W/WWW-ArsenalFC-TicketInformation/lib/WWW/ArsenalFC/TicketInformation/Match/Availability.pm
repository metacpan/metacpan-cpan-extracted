use strict;
use warnings;

package WWW::ArsenalFC::TicketInformation::Match::Availability;
{
  $WWW::ArsenalFC::TicketInformation::Match::Availability::VERSION = '1.123160';
}

# ABSTRACT: Represents the availability of a match ticket.

use constant {

    # memberships
    GENERAL_SALE  => 1,
    RED           => 2,
    SILVER        => 3,
    GOLD          => 4,
    PLATINUM_GOLD => 5,
    TRAVEL_CLUB   => 6,

    # types
    FOR_SALE  => 1,
    SCHEDULED => 2,
};

use Object::Tiny qw{
  date
  memberships
  type
};

1;



=pod

=head1 NAME

WWW::ArsenalFC::TicketInformation::Match::Availability - Represents the availability of a match ticket.

=head1 VERSION

version 1.123160

=head1 ATTRIBUTES

=head2 date

The date the ticket becomes available, if scheduled for release.

=head2 memberships

An array of membership levels this availability applies too.

=head2 type

The type of availibility. I.e. is it scheduled for release or for sale.

Use as follows:

  given ($availability->type) {
    when (WWW::ArsenalFC::TicketInformation::Match::Availability->SCHEDULED) {...}
    when (WWW::ArsenalFC::TicketInformation::Match::Availability->FOR_SALE) {...}
  }

Tip: If you don't like the long names, use L<aliased>.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

