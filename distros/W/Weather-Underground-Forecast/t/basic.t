use strict;
use warnings;
use Test::More;
use Weather::Underground::Forecast;
use LWP::Simple;
use Data::Dumper::Concise;

my @locations = ( 'Bloomington,IN', 11030, '21.3069444,-157.8583333' );

my $did_isa_check = 0;
foreach my $location (@locations) {
    my $wunder_forecast = Weather::Underground::Forecast->new(
        location          => $location,
        temperature_units => 'fahrenheit',    # or 'celsius'
    );
    if ( !$did_isa_check ) {
        isa_ok( $wunder_forecast, 'Weather::Underground::Forecast' );
        can_ok(
            'Weather::Underground::Forecast',
            ( 'temperatures', 'precipitation' )
        );
        $did_isa_check = 1;
    }
    live_test($wunder_forecast);
}

sub live_test {
    my $wunder_forecast = shift;

  SKIP:
    {

        # Test internet connection
        my $source_URL = $wunder_forecast->_query_URL;
        my $content       = get($source_URL);
        skip( 'Skipping live test using Internet', 3 ) if !$content;

        # If we're not skipping the test then let's use the $content to set the raw_data
        # and thereby avoiding another request (which has been known to fail).  
        # Thus, we are guaranteed to have data if we get this far.
        $wunder_forecast->raw_data($content);
        my ( $highs, $lows ) = $wunder_forecast->temperatures;
        my $chance_of_precip = $wunder_forecast->precipitation;
        is( ref($highs),            'ARRAY', 'highs data structure for location: '   . $wunder_forecast->location );
        is( ref($lows),             'ARRAY', 'lows data structure for location: '    . $wunder_forecast->location );
        is( ref($chance_of_precip), 'ARRAY', 'precips data structure for location: ' . $wunder_forecast->location );
    }
}

done_testing();
