use strictures 1;
package Weather::Underground::Forecast;
BEGIN {
  $Weather::Underground::Forecast::VERSION = '0.07';
}
use Moose;
use namespace::autoclean;
use LWP::Simple;
use XML::Simple;
use XML::LibXML;
use XML::Validate::LibXML;

use Data::Dumper::Concise;

=head1 Name

Weather::Underground::Forecast - Simple API to Weather Underground Forecast Data

=head1 Synopsis

    Get the weather forecast:
    
    my $forecast = Weather::Underground::Forecast->new( 
                    location          => $location,
                    temperature_units => 'fahrenheit',  # or 'celsius'
                 );
                                 
    Where the $location can be:
    * 'city,state'          Example: location => 'Bloomington,IN'
    *  zip_code             Example: location => 11030
    * 'latitude,longitude'  Example: location => '21.3069444,-157.8583333'
    
    my ($highs, $lows) = $forecast->temperatures;

NOTE: I<location> is the only required parameter to C<new()>


=cut

has 'location' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    writer   => 'set_location',
);
has 'temperature_units' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'fahrenheit',
);
has 'data' => (
    is         => 'rw',
    isa        => 'ArrayRef[HashRef]',
    lazy_build => 1,
);
has 'raw_data' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);
has 'source_URL' => (
    is         => 'ro',
    isa        => 'Any',
    'default'  => 'http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=',
);

# When the location changes, we want to clear the data to insure a new data fetch will happen.
# We need this since data is lazily built, and we used a distinct name for the writer
# so we only clear data when we set the location anytime after initial object construction.
after 'set_location' => sub {
    my $self = shift;
    $self->clear_data;
};

=head1 Methods

=head2 temperatures

Get the high and low temperatures for the number of days specified.

    Returns: Array of two ArrayRefs being the high and low temperatures
    Example: my ($highs, $lows) = $wunder->temperatures;

=cut

sub temperatures {
    my $self = shift;
    return ( $self->highs, $self->lows );
}

=head2 highs

Get an ArrayRef[Int] of the forecasted high temperatures.

=cut

sub highs {
    my $self = shift;

    my $key1 = 'high';
    my $key2 = $self->temperature_units;
    return $self->_get_forecast_data_by_two_keys( $key1, $key2 );
}

=head2 lows

Get an ArrayRef[Int] of the forecasted low temperatures.

=cut

sub lows {
    my $self = shift;

    my $key1 = 'low';
    my $key2 = $self->temperature_units;
    return $self->_get_forecast_data_by_two_keys( $key1, $key2 );
}

=head2 precipitation

Get an ArrayRef[Int] of the forecasted chance of precipitation.

        Example: my $chance_of_precip = $wunder->precipitation;

=cut

sub precipitation {
    my $self = shift;

    return $self->_get_forecast_data_by_one_key('pop');
}

# =head2 _get_forecast_data_by_one_key

# Get the values for a single forecast metric that is
# only one key deep.  An examples is: 'pop' (prob. of precip.)

# NOTE: One can dump the data attribute to see 
# the exact data structure and keys available.

# =cut

sub _get_forecast_data_by_one_key {
    my ( $self, $key ) = @_;

    return [ map { $_->{$key} } @{ $self->data } ];
}

# =head2 _get_forecast_data_by_two_keys

# Like the one_key method above but for values that are 
# two keys deep in the data structure.

# =cut

sub _get_forecast_data_by_two_keys {
    my ( $self, $key1, $key2 ) = @_;

    return [ map { $_->{$key1}->{$key2} } @{ $self->data } ];
}

sub _query_URL {
    my $self = shift;
    return $self->source_URL . $self->location;
}

# Builders

sub _build_data {
    my $self = shift;

    my $xml       = XML::Simple->new;
    my $data_ref  = $xml->XMLin( $self->raw_data );
    my $forecasts = $data_ref->{simpleforecast}->{forecastday};

    return $forecasts;
}

sub _build_raw_data {
    my $self = shift;

    my $content = get( $self->_query_URL );
    die "Couldn't get URL: ", $self->_query_URL unless defined $content;

    my $xml_validator = new XML::Validate::LibXML;
    if ( !$xml_validator->validate($content) ) {
        my $intro   = "Document is invalid\n";
        my $message = $xml_validator->last_error()->{message};
        my $line    = $xml_validator->last_error()->{line};
        my $column  = $xml_validator->last_error()->{column};
        die "Error: $intro $message at line $line, column $column";
    }

    # return and set attribute to raw xml when we make it this far.
    return $content;
}

__PACKAGE__->meta->make_immutable;
1

__END__

=head1 Limitations

It is possible that a location could have more than one forecast.
The behavior of that possibility has not been tested.

=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2010, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
