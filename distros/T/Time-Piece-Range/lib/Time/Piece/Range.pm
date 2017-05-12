package Time::Piece::Range;

=head1 NAME

Time::Piece::Range - deal with a range of Time::Piece objects

=head1 SYNOPSIS

	use Time::Piece::Range;

	my $range = Time::Piece::Range->new($t1, $d2);

	my $earliest = $range->start;
	my $latest = $range->end;
	my $days = $range->length;

	if ($range->includes($d3)) { ... }
	if ($range->includes($range2)) { ... }

	if ($range->overlaps($range2)) {
		my $range3 = $range->overlap($range2);
	}

	foreach my $date ($range->dates) { ... }

	my $range3 = $range->gap($range2);

	if ($range->abuts($range2)) { ... }

=head1 DESCRIPTION

This is a subclass of Date::Range that uses Time::Piece objects rather
than Date::Simple objects.

It only works at the precision of complete days - times are ignored in
all calculations.

=cut

$VERSION = '1.2';

use strict;

use base 'Date::Range';

use Carp;
use Time::Seconds;
use Time::Piece;

sub want_class { 'Time::Piece' }
sub _day_length { ONE_DAY }

1;

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Time-Piece-Range@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

