=pod

=head1 NAME

WWW:LiveDepartureBoards - presents an OO interface to the National Rail Live Departure Boards (LDB's)
Website (http://www.livedepartureboards.co.uk).

=head1 DESCRIPTION

Queries and then screenscrapes the LDB's website, making a guess as to what day
the given arrival or departure time is on and constructing a DateTime object as
part of the details returned. Can also filter by the stations you are interested
in.

=head1 METHODS

=cut


package WWW::LiveDepartureBoards;

use strict;
use warnings;

use LWP;
use DateTime;

our $VERSION = '0.03';

use constant {
    BASE_DEPARTURE_URL => 'http://www.livedepartureboards.co.uk/ldb/sumdep.aspx?T=',
    BASE_ARRIVAL_URL   => 'http://www.livedepartureboards.co.uk/ldb/sumarr.aspx?T='
};

# pinched from AlarmClock::Plan, which in turn was pictured from alarmclock/gac
sub _split_hours_and_minutes {
    my $time = shift;
    return split(/:/,$time);
}

# pinched from AlarmClock::Plan, which in turn was pictured from alarmclock/gac
sub _convert_hours_and_minutes_to_future_datetime {

    my $hour = shift;
    my $minute = shift;

    my $tz = shift;

    $tz = 'Europe/London' unless defined $tz;

    my $now = DateTime->now( time_zone => $tz );
    my $datetime = DateTime->new(
				 year      => $now->year(),
				 month     => $now->month(),
				 day       => $now->day(),
				 hour      => $hour,
				 minute    => $minute,
				 time_zone => $tz,
				);


    my $duration =  $datetime - $now; # this makes absolutely no sense
    if ($duration->is_negative()) {    
      $datetime->add_duration(DateTime::Duration->new( days => 1 ));
    }

    return $datetime;
}

sub _content_to_details {
    my $self = shift;
    my $content = shift;
    my $other_station_name = shift;

    $self->{last_content} = $content;

    my @details;

    while ($content =~ m/
	   \<tr.class=.row.*?
	   \<td.*?\>.*?\>(.*?)\<.*?
	   \<td.>(.*?)\<.*?
	   \<td.>(.*?)\<.*?
	   /sixg) {
    
	my $details = {};
	$details->{$other_station_name} = $1;
	$details->{time}        = $2;
	$details->{status}      = $3;
	$details->{datetime}    = _convert_hours_and_minutes_to_future_datetime(_split_hours_and_minutes($details->{time}));

	push(@details,$details);
    }

    return @details;
}

sub _get_content {
    my $url = shift;

    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/5.0');

    my $request = HTTP::Request->new(GET => $url);

    my $response = $ua->request($request);
    my $content = $response->content;

    die "Error at LDB" if ($content =~ m/We were unable to service your request/);

    return $content;
}


sub _get_lookup_hash {
    my @elements = @_;
    my $lookup_hash = {};
    $lookup_hash->{$_} = 1 for (@elements);
    return $lookup_hash;
}

sub _lookup_either {
    my $self = shift;

    my $filter_list = shift;
    my $base_url = shift;
    my $other_station_name = shift;

    my @details = $self->_content_to_details(_get_content($base_url.$self->{station_code}),$other_station_name);

    #warn scalar(@details).' details got before filtration';

    if (defined($filter_list)) {
	#warn 'doing filtration';
	my $lookup_hash=_get_lookup_hash(@$filter_list);
	@details = grep { exists($lookup_hash->{$_->{destination}}) } @details;
    }

    #warn scalar(@details).' details after filtration';

    return @details;
}

sub _lookup_destination {
	my $self        = shift;
	my $destination = shift;
	my $base_url    = shift;
 	
	my @details = $self->_content_to_details(_get_content($base_url.$self->{station_code}.'&S='.$destination),$destination);

    return @details;
}

=head2 new({station_code => 'XXX'})

Takes a 3 letter station code such as PNE (Penge East) and returns the
corresponding object. You can find out what your local station's code
is by visiting the website mentioned above.

=cut

sub new {
    my $class = shift;

    my $self = shift;

    for (qw(station_code)) {
	die "Mandatory parameter '$_' doesn't exist" unless exists($self->{$_});
    }

    return bless $self, $class;
}

=head2 arrivals(['Station Name'])

Returns an array of hashes with arrival details as follows,

    origin   - the origin of the train
    time     - time in the form of 'hh:mm'
    datetime - a DateTime object that has been tied to the best guess of
               what day the train arrives/departs on
    status   - the status of the train

Also a reference to a list can be supplied that will act as a filter. 

=cut

sub arrivals {
    my $self = shift;

    my $filter_list = shift;

    return $self->_lookup_either($filter_list,BASE_ARRIVAL_URL,'origin');
}

=head2 departures(['Station Name'])

Returns an array of hashes with departure details as follows,

    destination - the origin of the train
    time        - time in the form of 'hh:mm'
    datetime    - a DateTime object that has been tied to the best guess of
                  what day the train arrives/departs on
    status      - the status of the train

Also a reference to a list can be supplied that will act as a filter. 

=cut

sub departures {
    my $self = shift;

    my $filter_list = shift;

    return $self->_lookup_either($filter_list,BASE_DEPARTURE_URL,'destination');
}

=head2 destination({station_code => 'XXX'})

Returns an array of hashes with departure details as follows,

    station_code - the final destination name of the train
    time         - time in the form of 'hh:mm'
    datetime     - a DateTime object that has been tied to the best guess of
                   what day the train arrives/departs on
    status       - the status of the train

=cut

sub destination {
	my $self        = shift;
	my $destination = shift;

    if (ref $destination eq 'HASH') {
        $destination = $destination->{station_code};
    }
    $destination = uc($destination);

    die "You MUST provide a destination station.\n" unless $destination;

	return $self->_lookup_destination($destination, BASE_DEPARTURE_URL, 'destination');
}

=head1 AUTHOR

Greg McCarroll <greg@mccarroll.org.uk>
Adam Trickett <adam.trickett@iredale.net>

=head1 COPYRIGHT

Copyright 2005-2007 Greg McCarroll. All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW:NationalRail>

=cut

1;

