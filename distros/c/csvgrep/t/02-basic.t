#!perl

use strict;
use warnings;

use Test::More tests => 5;

use File::Temp;
use FindBin qw($RealBin);
use Capture::Tiny ':all';

# create the CSV file to grep on
my $fh = File::Temp->new(UNLINK => 1);
while (<DATA>) {
    print $fh $_;
}
close $fh;

{
    my $stdout = do_csvgrep("Murakami");
    my $expected_output =<<'EOD';
+-------------------+-----------------+-------+------+
| Book              | Author          | Pages | Date |
+-------------------+-----------------+-------+------+
| Norwegian Wood    | Haruki Murakami | 400   | 1987 |
| Men without Women | Haruki Murakami | 228   | 2017 |
+-------------------+-----------------+-------+------+
EOD

    is($stdout, $expected_output, "Simple word lookup");
}

{
    my $stdout = do_csvgrep("-i wood");
    my $expected_output =<<'EOD';
+-----------------------+-----------------+-------+------+
| Book                  | Author          | Pages | Date |
+-----------------------+-----------------+-------+------+
| Norwegian Wood        | Haruki Murakami | 400   | 1987 |
| A Walk in the Woods   | Bill Bryson     | 276   | 1997 |
| Death Walks the Woods | Cyril Hare      | 222   | 1954 |
+-----------------------+-----------------+-------+------+
EOD

    is($stdout, $expected_output, "Case insensitive word lookup");
}

{
    my $stdout = do_csvgrep("-c 0,1,3 -i mary");
    my $expected_output =<<'EOD';
+--------------+--------------+------+
| Book         | Author       | Date |
+--------------+--------------+------+
| Mary Poppins | PL Travers   | 1934 |
| Frankenstein | Mary Shelley | 1818 |
+--------------+--------------+------+
EOD

    is($stdout, $expected_output, "Display a subset of columns");
}

SKIP: {
    skip "Can't match first column with -mc 0: https://github.com/neilb/csvgrep/issues/14", 1 if 1;
    my $stdout = do_csvgrep("-mc 0 -c 0,1,3 -i mary");
    my $expected_output =<<'EOD';
+--------------+--------------+------+
| Book         | Author       | Date |
+--------------+--------------+------+
| Mary Poppins | PL Travers   | 1934 |
+--------------+--------------+------+
EOD

    is($stdout, $expected_output, "Match on first column");
}

{
    my $stdout = do_csvgrep("-i 'walk.*wood'");
    my $expected_output =<<'EOD';
+-----------------------+-------------+-------+------+
| Book                  | Author      | Pages | Date |
+-----------------------+-------------+-------+------+
| A Walk in the Woods   | Bill Bryson | 276   | 1997 |
| Death Walks the Woods | Cyril Hare  | 222   | 1954 |
+-----------------------+-------------+-------+------+
EOD

    is($stdout, $expected_output, "Perl regex as matcher");
}

sub do_csvgrep {
    my $grep_args = shift;
    my $filename = $fh->filename;
    my $stdout = capture_stdout {
        system("perl $RealBin/../bin/csvgrep $grep_args $filename")
    };

    return $stdout;
}

__DATA__
Book,Author,Pages,Date
Norwegian Wood,Haruki Murakami,400,1987
Men without Women,Haruki Murakami,228,2017
A Walk in the Woods,Bill Bryson,276,1997
Death Walks the Woods,Cyril Hare,222,1954
Mary Poppins,PL Travers,208,1934
Frankenstein,Mary Shelley,280,1818
