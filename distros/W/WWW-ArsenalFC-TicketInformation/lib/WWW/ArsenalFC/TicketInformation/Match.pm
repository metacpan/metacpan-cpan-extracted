use strict;
use warnings;

package WWW::ArsenalFC::TicketInformation::Match;
{
  $WWW::ArsenalFC::TicketInformation::Match::VERSION = '1.123160';
}

use WWW::ArsenalFC::TicketInformation::Match::Availability;

use WWW::ArsenalFC::TicketInformation::Util ':all';

# ABSTRACT: Represents an Arsenal match with ticket information.

use Object::Tiny qw{
  availability
  can_exchange
  competition
  category
  datetime_string
  fixture
  hospitality
  is_soldout
};

sub is_home {
    my ($self) = @_;
    return $self->fixture =~ /^Arsenal/;
}

sub is_premier_league {
    my ($self) = @_;
    return $self->competition =~ /Premier League/;
}

sub datetime {
    my ($self) = @_;

    if ( $self->datetime_string =~ /\w+\W+(\w+)\D+(\d+)\D+(\d+)\D+(\d\d:\d\d)/ )
    {
        my $month = month_to_number($1);
        my $day   = $2;
        my $year  = $3;
        my $time  = $4;

        $day = "0$day" if $day =~ /^\d$/;
        return sprintf( "%s-%s-%sT%s:00", $year, $month, $day, $time );
    }
}

sub date {
    my ($self) = @_;
    return substr( $self->datetime, 0, 10 );
}

sub opposition {
    my ($self) = @_;
    if (   $self->fixture =~ /Arsenal vs (.*)/
        || $self->fixture =~ /(.*) vs Arsenal/ )
    {
        return $1;
    }
}

1;



=pod

=head1 NAME

WWW::ArsenalFC::TicketInformation::Match - Represents an Arsenal match with ticket information.

=head1 VERSION

version 1.123160

=head1 ATTRIBUTES

=head2 availability

An array of L<WWW::ArsenalFC::TicketInformation::Match::Availability> objects.

The first item in the array is the current availability. Second item is the next availability, and so on.

Note if the match is sold out or if the ticket exchange is open, this will not be set.

=head2 can_exchange

True if the ticket exchange is open, otherwise false.

=head2 competition

The competition the game is being played in (i.e. 'Barclays Premier League').

=head2 category

The category of the game, if its a Permier League game.

=head2 datetime_string

The date and time of the game as it is displayed on the website (i.e. 'Saturday, May 5, 2012, 12:45').

=head2 fixture

The fixture (i.e. 'Arsenal vs Norwich').

=head2 hospitality

True if hospitality is available, otherwise false.

=head2 is_soldout

True if sold out, otherwise false.

=head1 METHODS

=head2 is_home

True if Arsenal are at home, otherwise false.

=head2 is_premier_league

True if this is a Premier League game.

=head2 datetime

Returns the date and time of the match as C<YYYY-MM-DDThh:mm:ss>.

=head2 date

Returns the date of the match as C<YYYY-MM-DD>

=head2 opposition

Returns the opposition.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

