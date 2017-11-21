package WWW::Oxontime;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

use constant +{
	NEXTBUS_FROM_HEADINGTON_CAMPUS => 'headington',
	NEXTBUS_FROM_HARCOURT_HILL     => 'harcourt',
	NEXTBUS_FROM_MARSTON_ROAD      => 'marston',
	NEXTBUS_FROM_WHEATLEY_CAMPUS   => 'wheatley',
	NEXTBUS_FROM_CRESCENT_HALL     => 'crescent',
	NEXTBUS_FROM_PAUL_KENT_HALL    => 'paulkent',
	NEXTBUS_FROM_SLADE_PARK        => 'sladepark',
	NEXTBUS_FROM_CITY_CENTRE       => 'citycentre',
};

my @CONSTANTS =
  qw/NEXTBUS_FROM_HEADINGTON_CAMPUS
     NEXTBUS_FROM_HARCOURT_HILL
     NEXTBUS_FROM_MARSTON_ROAD
     NEXTBUS_FROM_WHEATLEY_CAMPUS
     NEXTBUS_FROM_CRESCENT_HALL
     NEXTBUS_FROM_PAUL_KENT_HALL
     NEXTBUS_FROM_SLADE_PARK
     NEXTBUS_FROM_CITY_CENTRE/;

our $VERSION = '0.002';
our @EXPORT_OK = (qw/stops_for_route departures_for_stop nextbus_from_to/, @CONSTANTS);
our @EXPORT = ();
our %EXPORT_TAGS = (all => [@EXPORT_OK], constants => [@CONSTANTS]);

use HTML::TreeBuilder;
use HTTP::Tiny;
use JSON::MaybeXS;
use Time::Piece;

our $STOPS_URL = 'http://www.buscms.com/Nimbus/operatorpages/widgets/departureboard/ssi.aspx?method=updateRouteStops&routeid=%d&callback=cb&_=%d';
our $DEPARTS_URL = 'http://www.buscms.com/api/REST/html/departureboard.aspx?clientid=Nimbus&stopid=%d&format=jsonp&cachebust=123&sourcetype=siri&requestor=Netescape&includeTimestamp=true&_=%d';
our $DEPART_TIME_FORMAT = '%d/%m/%Y %T';
our $NEXTBUS_URL = 'http://nextbus.brookes.ac.uk/%s?format=json&%s';

our $ht = HTTP::Tiny->new(agent => "WWW-Oxontime/$VERSION");

sub stops_for_route {
	my ($route_id) = @_;
	my $url = sprintf $STOPS_URL, int $route_id, time;
	my $result = $ht->get($url);
	die $result->{reason} unless $result->{success};
	my $json = $result->{content};
	$json = substr $json, 3, (length $json) - 5;
	my $stops = decode_json($json)->{stops};
	wantarray ? @$stops : $stops
}

sub departures_for_stop {
	my ($stop_id) = @_;
	my $url = sprintf $DEPARTS_URL, int $stop_id, time;
	my $result = $ht->get($url);
	die $result->{reason} unless $result->{success};
	my $content = $result->{content};
	$content =~ s/\s/ /g; # replaces tabs with spaces
	$content = JSON->new->allow_nonref(1)->decode(qq/"$content"/);
	my $html = HTML::TreeBuilder->new_from_content($content);

	my @lines = $html->look_down(class => qr/\browServiceDeparture\b/);
	my @result = map {
		my @cells = $_->find('td');
		my $departs = $cells[2]->attr('data-departureTime');
		+{
			service     => $cells[0]->as_trimmed_text,
			destination => $cells[1]->as_trimmed_text,
			departs     => Time::Piece->strptime($departs, $DEPART_TIME_FORMAT),
		}
	} @lines;
	wantarray ? @result : \@result
}

sub nextbus_from_to {
	my ($from, $to) = @_;
	my $data = $ht->www_form_urlencode({ destination => $to});
	my $url = sprintf $NEXTBUS_URL, $from, $data;
	my $result = $ht->get($url);
	die $result->{reason} unless $result->{success};
	my $content = $result->{content};
	my $departures = JSON->new->decode($content)->{departures};
	wantarray ? @$departures : $departures
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Oxontime - live Oxford bus departures from Oxontime

=head1 SYNOPSIS

  use WWW::Oxontime qw/stops_for_route departures_for_stop nextbus_from_to :constants/;
  my @stops_on_8_outbound = stops_for_route 15957;
  my $queens_lane = $stops_on_8_outbound[2]->{stopId};
  my @from_queens_lane = departures_for_stop $queens_lane;
  for my $entry (@from_queens_lane) {
    say $entry->{service}, ' towards ', $entry->{destination}, ' departs at ', $entry->{departs};
  }
  my @from_city_centre_to_headington_campus =
    nextbus_from_to NEXTBUS_FROM_CITY_CENTRE, 'Headington Campus';
  for my $line (@from_city_centre_to_headington_campus) {
    my ($from, $service, $departs_in, $departs_in_mins) = @$line;
    say "Bus $service leaves from $from in $departs_in";
  }

=head1 DESCRIPTION

This module wraps L<http://www.oxontime.com> to provide live bus
departures in Oxford.

Two methods can be exported (none by default):

=over

=item B<stops_for_route>(I<$route_id>)

Given a route ID (these can be obtained by inspecting the homepage of
Oxontime), returns in list context a list of hashrefs having the keys
C<stopName> (name of stop) and C<stopId> (ID of stop, suitable for
passing to C<departures_for_stop>). In scalar context, an arrayref
containing this list is returned.

=item B<departures_for_stop>(I<$stop_id>)

Given a stop ID (these can be obtained by inspecting the homepage of
Oxontime or by calling C<stops_for_route>), returns in list context a
list of hashrefs having the keys C<service> (name of service and
company that runs it), C<destination> (where the service is finishing)
and C<departs> (L<Time::Piece> object representing the time when the
service departs). In scalar context, an arrayref containing the list
is returned.

Note that C<departs> is in the time zone of Oxford, but Time::Piece
interprets it as being in local time. If local time is different from
time in Oxford, this needs to be taken into account.

=item B<nextbus_from_to>(I<$from>, I<$to>)

Given a place to start from and a place to arrive at this method
returns a list of the next buses to serve that route. I<$from> must be
one of the 8 provided constants:

  NEXTBUS_FROM_HEADINGTON_CAMPUS
  NEXTBUS_FROM_HARCOURT_HILL
  NEXTBUS_FROM_MARSTON_ROAD
  NEXTBUS_FROM_WHEATLEY_CAMPUS
  NEXTBUS_FROM_CRESCENT_HALL
  NEXTBUS_FROM_PAUL_KENT_HALL
  NEXTBUS_FROM_SLADE_PARK
  NEXTBUS_FROM_CITY_CENTRE

whereas I<$to> is the name of an important station.

This function calls the Nextbus service at
L<http://nextbus.brookes.ac.uk/>. It is unclear what values for I<$to>
are implemented by Nextbus; it is probably best to inspect the website
to see what destinations are available.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
