# ABSTRACT: provides perl API to VisualCrossing
package VisualCrossing::API;

use JSON;
use HTTP::Tiny;
use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '1.0.0';

my $DEBUG = 0;

my $api = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline";
my $docs = "https://www.visualcrossing.com/resources/documentation/weather-api/timeline-weather-api/";
my %unitGroups = (
    us     => 1,
    base   => 1,
    metric => 1,
    uk     => 1,
);
my %includes = (
    days      => 1,
    hours     => 1,
    current   => 1,
    events    => 1,
    obs       => 1,
    remote    => 1,
    fcst      => 1,
    stats     => 1,
    statsfcst => 1,
);

has url => (
    is    => 'lazy',
    'default' =>  sub {
        my $self = shift;
        return $self->_getUrl();
    },
);
# key must be specified
has key => (
    is    => 'ro',
    'isa' => sub {
        die "Invalid key specified: see $docs\n"
            unless defined($_[0]);
    },
    required => 1,
);

# location or latitude/longitude must be specified
has location => (is => 'ro');
has latitude => (is => 'ro');
has longitude => (is => 'ro');

# date is optional
has date => (is => 'ro');
has date2 => (is => 'ro');

# uncommon options
has include => (
    is        => 'ro',
    'isa'     => sub {
        die "Invalid include specified: see $docs\n"
            unless exists($includes{ $_[0] });
    },
);
has unitGroup => (
    is    => 'ro',
    'isa' => sub {
        die "Invalid unitGroup specified: see $docs\n"
            unless exists($unitGroups{ $_[0] });
    },
);
has lang => (is => 'ro');
has options => (is => 'ro');
has nonulls => (is => 'ro');
has noheaders => (is => 'ro');
has contentType => (is => 'ro');
has timezone => (is => 'ro');
has maxDistance => (is => 'ro');
has maxStations => (is => 'ro');
has elevationDifference => (is => 'ro');
has locationNames => (is => 'ro');
has forecastBasisDate => (is => 'ro');
has forecastBasisDay => (is => 'ro');
has degreeDayTempBase => (is => 'ro');
has degreeDayTempMaxThreshold => (is => 'ro');

sub getWeather {
    my $self = shift;
    my $http = HTTP::Tiny->new;
    my $url = $self->url;
    my $response = $http->get($url);

    die "Request to '$url' failed: $response->{status} $response->{reason}\n"
        unless $response->{success};

    my $coder = JSON->new->utf8;
    my $result = $coder->decode($response->{content});
    return $result;
}

sub BUILD {
    my ($self, $args) = @_;
    # validate the resulting object

    if (defined($self->{location})) {
        # ok
    } elsif (defined($self->{latitude}) && defined($self->{longitude})) {
        # ok
    } else {
        die "Invalid request either location or latitude/longitude must be specified: see $docs\n";
    }

    if (defined($self->{date}) && defined($self->{date2})) {
        # ok
    } elsif (!defined($self->{date}) && defined($self->{date2})) {
        die "Invalid request date must exist if date2 is specified: see $docs\n";
    }
}

sub _getUrl {
    my ($self) = @_;
    my $url = $api;

    if (defined($self->{location})) {
        $url = $url . '/' . $self->{location};
    } elsif (defined($self->{latitude}) && defined($self->{longitude})) {
        $url = $url . '/' . $self->{latitude} . ',' . $self->{longitude};
    } else {
        die "Invalid request either location or latitude/longitude must be specified: see $docs\n";
    }

    if (defined($self->{date}) && defined($self->{date2})) {
        $url = $url . '/' . $self->{date} . '/' . $self->{date2};
    } elsif (!defined($self->{date}) && defined($self->{date2})) {
        die "Invalid request date must exist if date2 is specified: see $docs\n";
    } elsif (defined($self->{date})) {
        $url = $url . '/' . $self->{date} ;
    }

    if (!defined($self->{key})) {
        die "Invalid request key must be specified: see $docs\n";
    }
    $url = $url . "?key=" . $self->{key};

    if (defined($self->{include})) {
        $url = $url . '&include=' . $self->{include};
    }
    if (defined($self->{unitGroup})) {
        $url = $url . '&unitGroup=' . $self->{unitGroup};
    }
    if (defined($self->{lang})) {
        $url = $url . '&lang=' . $self->{lang};
    }
    if (defined($self->{options})) {
        $url = $url . '&options=' . $self->{options};
    }
    if (defined($self->{nonulls})) {
        $url = $url . '&nonulls=' . $self->{nonulls};
    }
    if (defined($self->{noheaders})) {
        $url = $url . '&noheaders=' . $self->{noheaders};
    }
    if (defined($self->{contentType})) {
        $url = $url . '&contentType=' . $self->{contentType};
    }
    if (defined($self->{timezone})) {
        $url = $url . '&timezone=' . $self->{timezone};
    }
    if (defined($self->{maxDistance})) {
        $url = $url . '&maxDistance=' . $self->{maxDistance};
    }
    if (defined($self->{maxStations})) {
        $url = $url . '&maxStations=' . $self->{maxStations};
    }
    if (defined($self->{elevationDifference})) {
        $url = $url . '&elevationDifference=' . $self->{elevationDifference};
    }
    if (defined($self->{locationNames})) {
        $url = $url . '&locationNames=' . $self->{locationNames};
    }
    if (defined($self->{forecastBasisDate})) {
        $url = $url . '&forecastBasisDate=' . $self->{forecastBasisDate};
    }
    if (defined($self->{forecastBasisDay})) {
        $url = $url . '&forecastBasisDay=' . $self->{forecastBasisDay};
    }
    if (defined($self->{degreeDayTempBase})) {
        $url = $url . '&degreeDayTempBase=' . $self->{degreeDayTempBase};
    }
    if (defined($self->{degreeDayTempMaxThreshold})) {
        $url = $url . '&degreeDayTempMaxThreshold=' . $self->{degreeDayTempMaxThreshold};
    }

    $DEBUG && print "DEBUG: ddURL=" . $url . "\n";
    return $url;
}

sub TO_JSON {return { %{shift()} };}

1;


=pod

=encoding utf-8

=head1 NAME

VisualCrossing::API - Provides Perl API to VisualCrossing

=head1 SYNOPSIS

    use VisualCrossing::API;
    use JSON::XS;
    use feature 'say';

    my $location = "AU419";
    my $date = "2023-05-25"; # example  time (optional)
    my $key = "ABCDEFGABCDEFGABCDEFGABCD"; # example VisualCrossing API key

    ## Current Data (limit to current, saves on API cost)
    my $weatherApi = VisualCrossing::API->new(
        key       => $key,
        location => $location,
        include  => "current",
    );
    my $current = $weatherApi->getWeather;

    say "current temperature: " . $current->{currentConditions}->{temp};
    say "current conditions: " . $current->{currentConditions}->{conditions};

    ## Historical Data (limit to single day, saves on API cost)
    my $weatherApi = VisualCrossing::API->new(
        key       => $key,
        location => $location,
        date      => $date
        date2      => $date
        include  => "days",
    );
    my $history = $weatherApi->getWeather;

    say "$date temperature: " . $history->{days}[0]->{temp};
    say "$date conditions: " . $history->{days}[0]->{conditions};

=head1 DESCRIPTION

This module is a wrapper around the VisualCrossing API.

=head1 REFERENCES

Git repository: L<https://github.com/duanemay/VisualCrossing-API>

VisualCrossing API docs: L<https://www.visualcrossing.com/resources/documentation/weather-api/timeline-weather-api/>

Based on DarkSky-API: L<https://github.com/mlbright/DarkSky-API>

=head1 COPYRIGHT

Copyright (c) 2023 L<Duane May>

=head1 LICENSE

This library is free software and may be distributed under the APACHE LICENSE, VERSION 2.0 L<https://www.apache.org/licenses/LICENSE-2.0>.

=cut