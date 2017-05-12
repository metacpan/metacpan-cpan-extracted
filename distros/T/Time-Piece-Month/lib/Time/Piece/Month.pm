package Time::Piece::Month;

use strict;
use warnings;
use base 'Time::Piece::Range';
use Time::Seconds;

our $VERSION = '1.00';

=head1 NAME

Time::Piece::Month - a month of Time::Piece objects

=head1 SYNOPSIS

  use Time::Piece::Month;

	my $month = Time::Piece::Month->new(Time::Piece $tp);
	my $month = Time::Piece::Month->new("2002-01-03");

	my Time::Piece::Month $prev = $month->prev_month;
	my Time::Piece::Month $next = $month->next_month;

	my @dates = $month->dates;
	my @dates = $month->wraparound_dates;

=head1 DESCRIPTION

This is an extension to Time::Piece::Range that represents a complete
calendar month.

=head1 CONSTRUCTOR

=head2 new

	my $month = Time::Piece::Month->new(Time::Piece $tp);

	my $month = Time::Piece::Month->new("2002-01-03");

A Month object can be instantiated from either a Time::Piece object,
or a Y-m-d format string. 

=cut

sub new {
	my ($class, $date) = @_;
	my $tp    = ref $date ? $date : _tp($date);
	my $first = _tp($tp->strftime("%Y-%m-01"));
	my $last  = _tp($tp->strftime("%Y-%m-" . $first->month_last_day));
	return $class->SUPER::new($first, $last);
}

sub _tp { Time::Piece->strptime(shift, "%Y-%m-%d") }

=head1 METHODS

As well as the inherited Time::Piece::Range methods, we also include:

=head2 prev_month / next_month

	my Time::Piece::Month $prev = $month->prev_month;
	my Time::Piece::Month $next = $month->next_month;

The next and previous months.

=cut

sub prev_month {
	my $self = shift;
	$self->new($self->start - ONE_DAY);
}

sub next_month {
	my $self = shift;
	$self->new($self->end + ONE_DAY);
}

=head2 wraparound_dates

This returns a list of Time::Piece objects representing each day in
the month, but also including the days on either side that ensure that
the full list runs from a Sunday to a Saturday. This is useful for
displaying calendars.

=cut

sub wraparound_dates {
	my $self    = shift;
	my $preceed = 0 - ($self->start->day_of_week || 7);
	my $follow  = 6 - ($self->end + ONE_DAY)->day_of_week;
	return ($self->prev_month->dates)[ $preceed .. -1 ], ($self->dates),
		($self->next_month->dates)[ 0 .. $follow ];
}

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Business-Barcode-EAN13@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2005 Kasei

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;
