use Test2::V0;
use Test2::Require::Module 'Text::CSV';

use WebService::OurWorldInData::Chart;

note 'testing the Chart::parse_data method';

my $dataset = 'sea-surface-temperature-anomaly';
my $chart   = WebService::OurWorldInData::Chart->new( chart => $dataset );

my $body = get_data_subset();

my $data = $chart->parse_data( $body );
is ref $data, 'ARRAY';

done_testing();

sub get_data_subset {
    return <<DATA;
Entity,Code,Year,Annual sea surface temperature anomalies,Annual sea surface temperature anomalies (lower bound),Annual sea surface temperature anomalies (upper bound)
Northern Hemisphere,,1850,-0.053766724,-0.12948489,-0.0016253028
Northern Hemisphere,,1851,0.06586428,-0.008639886,0.11984695
Northern Hemisphere,,1852,0.14944454,0.079167694,0.20091112
Northern Hemisphere,,1853,0.11939995,0.054722864,0.17239437
DATA
}
