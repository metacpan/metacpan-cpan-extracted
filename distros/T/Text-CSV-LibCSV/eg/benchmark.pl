#!/usr/local/bin/perl
use strict;
use warnings;

use Benchmark qw(timethese cmpthese);
use Text::CSV_XS;
use Text::CSV::LibCSV;

my $data = <<'END_DATA';
0,1,2,3,4,5,6,7,8,9
0,1,2,3,4,5,6,7,8,9
0,1,2,3,4,5,6,7,8,9
0,1,2,3,4,5,6,7,8,9
0,1,2,3,4,5,6,7,8,9
END_DATA
my $bench = timethese(10000, {
    'Text::CSV_XS' => sub {
        my $csv = Text::CSV_XS->new;
        for my $line (split /\n/, $data) {
            if ($csv->parse($line)) {
                my @columns = $csv->fields;
            }
        }
    },
    'Text::CSV::LibCSV' => sub {
        csv_parse($data, sub { my @columns = @_ });
    },
});
cmpthese($bench);

__END__

