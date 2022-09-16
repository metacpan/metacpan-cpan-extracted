use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test::More tests => 3;
use Weather::GHCN::App::Extremes;

use Capture::Tiny       qw( capture );

my $input_file = $FindBin::Bin . '/test_data/ny_data.tsv';

subtest 'ghcn_extremes (no args)' => sub {
    my $argv = [ $input_file ];

    my ($stdout, $stderr) = capture {
        Weather::GHCN::App::Extremes->run( $argv );
    };

    my @result = split "\n", $stdout;

    my $hdr;
    my $matches;
    foreach my $r (@result) {
        $hdr++      if $r =~ m{ \A StnId \t Location \t Year \t YMD }xms;
        $matches++  if $r =~ m{ NEW \s YORK .*? \d{4}-\d{2}-\d{2} }xms;
    }

    is $hdr,      1, 'Weather::GHCN::App::Extremes returned a header';
    is $matches, 18, 'Weather::GHCN::App::Extremes returned 18 entries';
};

subtest 'ghcn_extremes -peryear' => sub {
    my $argv = [ '-peryear', $input_file ];

    my ($stdout, $stderr) = capture {
        Weather::GHCN::App::Extremes->run( $argv );
    };

    my @result = split "\n", $stdout;

    my $hdr;
    my $matches;
    foreach my $r (@result) {
        $hdr++      if $r =~ m{ \A StnId \t Location \t Year }xms;
        $matches++  if $r =~ m{ NEW \s YORK }xms;
    }

    is $hdr,      1, 'Weather::GHCN::App::Extremes returned a header';
    is $matches, 12, 'Weather::GHCN::App::Extremes returned 12 entries';
};

subtest 'ghcn_extremes -cold -limit -10 -ndays 3' => sub {
    my $argv = [ '-cold', '-limit', -10, '-ndays', 3, $input_file ];

    my ($stdout, $stderr) = capture {
        Weather::GHCN::App::Extremes->run( $argv );
    };

    my @result = split "\n", $stdout;

    my $hdr;
    my $matches;
    foreach my $r (@result) {
        $hdr++      if $r =~ m{ \A StnId \t Location \t Year \t YMD }xms;
        $matches++  if $r =~ m{ NEW \s YORK .*? \d{4}-\d{2}-\d{2} }xms;
    }

    is $hdr,      1, 'Weather::GHCN::App::Extremes returned a header';
    is $matches, 40, 'Weather::GHCN::App::Extremes returned 18 entries';
};

