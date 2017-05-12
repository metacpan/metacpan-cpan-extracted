package t::Util;
use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';

my $datadir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), 'data'));
my $forecastmap_data;

sub slurp {
    my $file = shift;
    my $data = '';
    open my $fh, '<', File::Spec->catfile($datadir, $file) or die $!;
    $data .= $_ while <$fh>;
    close $fh;
    return $data;
}

sub load_forecastmap_data {
    $forecastmap_data = slurp('primary_area.xml') unless $forecastmap_data;
    return $forecastmap_data;
}

sub load_forecast {
    my ($class, $city_id) = @_;
    slurp($city_id.'.json');
}

1;
