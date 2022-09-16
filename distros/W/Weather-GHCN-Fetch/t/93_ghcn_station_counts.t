use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test::More tests => 2;
use Capture::Tiny       qw( capture );

use Weather::GHCN::App::StationCounts;

my $input_file = $FindBin::Bin . '/test_data/ny_stations.tsv';

my @argv = ( $input_file );

my ($stdout, $stderr) = capture {   
    Weather::GHCN::App::StationCounts->run( \@argv );
};

my @result = split "\n", $stdout;

my $hdr;
my $matches;
foreach my $r (@result) {
    $hdr++      if $r =~ m{ Year }xms;
    $matches++  if $r =~ m{ \A \d{4} \t \d{4}s \t \d+ }xms;
}

is $hdr, 1, 'Weather::GHCN::App::StationCounts returned a header';
is $matches, 154, 'Weather::GHCN::App::StationCounts returned 154 entries';
