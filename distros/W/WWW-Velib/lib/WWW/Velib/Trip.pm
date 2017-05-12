# Trip.pm - WWW::Velib::Trip
#
# Copyright (c) 2007 David Landgren
# All rights reserved

package WWW::Velib::Trip;
use strict;

use vars qw/$VERSION/;
$VERSION = '0.03';

sub make {
    my $class = shift;
    my $self  = {
        date     => $_[0],
        from     => $_[1],
        to       => $_[2],
        duration => $_[3] * 60 + $_[4],
        cost     => do {$_[5] =~ tr/,/./; $_[5]} + 0,
    };
    return bless $self, $class;
}

sub date     { $_[0]->{date} }
sub from     { $_[0]->{from} }
sub to       { $_[0]->{to} }
sub duration { $_[0]->{duration} }
sub cost     { $_[0]->{cost} }

'The Lusty Decadent Delights of Imperial Pompeii';
__END__

=head1 NAME

WWW::Velib::Trip - Details of a single trip made on the Velib system

=head1 VERSION

This document describes version 0.03 of WWW::Velib::Trip, released
2007-11-13.

=head1 SYNOPSIS

  use WWW::Velib;

  my $v = WWW::Velib->new(login => '0000123456', password => '1234');
  $v->get_month;
  for my $trip ($v->trips) {
    print "Journey from ", $trip->{from}, " to ", $trip->{to},
      " took", $trip->{duration}, "minutes.\n";
  }

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item make

Make a W::V::Trip object (usually called on your behalf from
C<WWW::Velib>). Requires six parameters, date (in dd/mm/yyyy format,
from station name, to station name, trip duration in hours, trip
duration in additional minutes and cost.

=item from

Name of the station of departure.

=item to

Name of the station of arrival.

=item date

The date the trip took place (in dd/mm/yyyy format).

=item duration

The duration of the trip, in minutes. As an example, for a trip
that took 1 hour and 26 minutes, 86 minutes will be returned.

=item cost

The cost of the trip. Trips that take 30 minutes or less are
free. After that, the price goes up astronomically!

=back

=head1 AUTHOR

David Landgren, copyright (C) 2007. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

