use Test2::V0;
#
# this test is for methods that depend on Text::CSV being installed
# like the parse_data() method

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use WebService::OurWorldInData::Chart;

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'LWP::UserAgent::Mockable';
use Test2::Require::Module 'URI';
use Test2::Require::Module 'Text::CSV';
use Time::Piece; # core module

my $dataset = 'sea-surface-temperature-anomaly';
my $ua    = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.1');
my $chart = WebService::OurWorldInData::Chart->new( chart => $dataset, ua => $ua );

my $body = get_data_subset();

my $data = $chart->parse_data( $body );
is ref $data, 'ARRAY';
        
ok my $result = $chart->data(), "Fetch chart data for $dataset";
like $result, qr/^Entity,Code,Year,\w+/, 'returns CSV data';

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}

sub get_data_subset {
    return <<DATA;
Entity,Code,Year,Annual sea surface temperature anomalies,Annual sea surface temperature anomalies (lower bound),Annual sea surface temperature anomalies (upper bound)
Northern Hemisphere,,1850,-0.053766724,-0.12948489,-0.0016253028
Northern Hemisphere,,1851,0.06586428,-0.008639886,0.11984695
Northern Hemisphere,,1852,0.14944454,0.079167694,0.20091112
Northern Hemisphere,,1853,0.11939995,0.054722864,0.17239437
DATA
}
