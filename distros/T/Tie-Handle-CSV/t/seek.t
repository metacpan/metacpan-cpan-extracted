use strict;
use warnings;

use Test::More tests => 10;
use File::Temp 'tempfile';
use Fcntl ':seek';

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

ok( $csv_fh = Tie::Handle::CSV->new($tmp_file, header => 0, open_mode => '+<'), 'new - good - no header' );

ok( seek($csv_fh, 0, SEEK_END), 'seek 0, SEEK_END');

is( scalar <$csv_fh>, undef, 'readline - undef');

ok( seek($csv_fh, 0, SEEK_SET), 'seek 0, SEEK_SET');

is( ( scalar <$csv_fh> )->[0], 'foo', 'readline - bar');

ok( seek($csv_fh, 0, SEEK_END), 'seek 0, SEEK_END');

is( scalar <$csv_fh>, undef, 'readline - undef');

ok( print $csv_fh 1, 'print' );

ok( close($csv_fh), 'new - close' );
