use strictures;
package Weather::WWO;
use Moo;
use MooX::Types::MooseLike::Base qw/Str Int HashRef Bool/;
use HTTP::Tiny;
use JSON;

our $VERSION = '0.07';

=head1 Name

Weather::WWO - API to World Weather Online

=head1 Synopsis

    Get the 5-day weather forecast:
    
    my $wwo = Weather::WWO->new( api_key           => $your_api_key,
                                 use_new_api       => 1,
                                 location          => $location,
                                 temperature_units => 'F',
                                 wind_units        => 'Miles');
                                 
    Where the $location can be:
    * zip code
    * IP address
    * latitude,longitude
    * City[,State] name

    my ($highs, $lows) = $wwo->forecast_temperatures;

NOTE: I<api_key> and I<location> are required parameters to C<new()>
As of May 2013 there is a new API that will replace the old.
One can set use_new_api to 1 in the constructor to retrieve from the new api.

=cut

has 'api_key' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);
has 'location' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    writer   => 'set_location',
);
has 'num_of_days' => (
    is        => 'ro',
    isa       => Int,
    default => sub { 5 },
);

# We are only using the JSON format
has 'format' => (
    is        => 'ro',
    isa       => Str,
    default => sub { 'json' },
    init_arg  => undef,
);
has 'temperature_units' => (
    is        => 'ro',
    isa       => Str,
    default => sub { 'C' },
);
has 'wind_units' => (
    is        => 'ro',
    isa       => Str,
    default => sub { 'Kmph' },
);
has 'data' => (
    is         => 'rw',
    isa        => HashRef,
    lazy       => 1,
    builder    => '_build_data',
);
has 'source_URL' => (
    is         => 'lazy',
    isa        => Str,
);
has 'use_new_api' => (
    is         => 'lazy',
    isa        => Bool,
);

# When the location changes, we want to clear the data to insure a new data fetch will happen.
# We need this since data is lazily built, and we used a distinct name for the writer
# so we only clear data when we set the location anytime after initial object construction.
after 'set_location' => sub {
    my $self = shift;
    $self->clear_data;
};

=head1 Methods

=head2 forecast_temperatures

Get the high and low temperatures for the number of days specified.

    Returns: Array of two ArrayRefs being the high and low temperatures
    Example: my ($highs, $lows) = $wwo->forecast_temperaures;

=cut

sub forecast_temperatures {
    my $self = shift;
    return ($self->highs, $self->lows);
}

=head2 highs

Get an ArrayRef[Int] of the forecasted high temperatures.

=cut

sub highs {
    my $self = shift;
    
    my $high_key = 'tempMax' . $self->temperature_units;
    return $self->get_forecast_data_by_key($high_key);
}

=head2 lows

Get an ArrayRef[Int] of the forecasted low temperatures.

=cut

sub lows {
    my $self = shift;
    
    my $low_key = 'tempMin' . $self->temperature_units;
    return $self->get_forecast_data_by_key($low_key);
}

=head2 winds

Get an ArrayRef[Int] of the forecasted wind speeds.

=cut

sub winds {
    my $self = shift;
    
    my $wind_key = 'windspeed' . $self->wind_units;
    return $self->get_forecast_data_by_key($wind_key);
}

=head2 get_forecast_data_by_key

Get the values for a single forecast metric.
Examples are: tempMinF, tempMaxC, windspeedMiles etc...

NOTE: One can dump the data attribute to see 
the exact data structure and keys available.

=cut

sub get_forecast_data_by_key {
    my ($self, $key) = @_;
    
    return [ map { $_->{$key} } @{$self->weather_forecast} ];
}

=head2 query_string

Construct the query string based on object attributes.

=cut

sub query_string {
    my $self = shift;

    my $query_pieces = {
        q           => $self->location,
        format      => $self->format,
        num_of_days => $self->num_of_days,
        key         => $self->api_key,
    };

    my @query_parts =
      map { $_ . '=' . $query_pieces->{$_} } keys %{$query_pieces};
    my $query_string = join '&', @query_parts;

    return $query_string;
}

=head2 query_URL

Construct the to URL to get by putting the source URL and query_string together.

=cut

sub query_URL {
    my $self = shift;
    return $self->source_URL . '?' . $self->query_string;
}

=head2 current_conditions

The current conditions data structure.

=cut

sub current_conditions {
    my $self = shift;
    return $self->data->{current_condition};
}

=head2 weather_forecast

The weather forecast data structure.

=cut

sub weather_forecast {
    my $self = shift;
    return $self->data->{weather};
}

=head2 request

Information about the request.

=cut

sub request {
    my $self = shift;
    return $self->data->{request};
}

# Builders

sub _build_data {
    my $self = shift;

    my $URL = $self->query_URL;
    my $response = HTTP::Tiny->new->get($URL);
    die "Failed to get $URL\n" unless $response->{success};
    my $content = $response->{content};
    die "No content for $URL\n" unless defined $content;

    my $data = decode_json($content);
    # Are there any errors?
    if (my $errors = $data->{data}->{error}) {
        foreach my $error (@{$errors}) {
            warn $error->{msg};
        }
        die "Error: Can not get data for location: ", $self->location;
    }

    return $data->{data};
}

sub _build_use_new_api {
    return 0;
}

# We currently have two different APIs to choose from
# According to WWO, the old API will only work through 31 August 2013
sub _build_source_URL {
    my $self = shift;
    if ($self->use_new_api) {
        return 'http://api.worldweatheronline.com/free/v1/weather.ashx';
    }
    else {
        return 'http://free.worldweatheronline.com/feed/weather.ashx';
    }
}

1

__END__

=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2010, 2011, 2013 Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
