use strict;
use warnings;

use Test::More tests => 5;
use File::Temp 'tempfile';

## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
foo,bar,baz
potato,monkey,rutabaga
fred,barney,wilma
EOCSV

close $tmp_fh;


## load module

use_ok('Tie::Handle::CSV');

## NO-HEADER

my $csv_fh;

ok( $csv_fh = Tie::Handle::CSV->new($tmp_file, header => 0), 'new - good - no header' );

is( tell $csv_fh, 0, 'tell - 0' );

scalar <$csv_fh>;

ok( tell $csv_fh > 0, 'tell > 0' );

ok( close($csv_fh), 'new - close' );
