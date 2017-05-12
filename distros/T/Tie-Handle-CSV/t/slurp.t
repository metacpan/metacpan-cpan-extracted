use strict;
use warnings;

use Test::More tests => 21;
use File::Temp 'tempfile';

## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
foo,"b$/ar",baz
potato,monkey,rutabaga
fred,barney,wilma
EOCSV

close $tmp_fh;


## load module

use_ok('Tie::Handle::CSV');

## NO-HEADER

my $csv_fh;

ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file, header => 0), 'new - good - no header' );

## test reading with no header

my @lines = <$csv_fh>;

is( ref $lines[0], 'Tie::Handle::CSV::Array', 'tie - ref' );
is( scalar @lines, 3, 'tie - line count' );

is( $lines[0], qq(foo,"b$/ar",baz),      'tie - lines[0] - stringify' );
is( $lines[1], 'potato,monkey,rutabaga', 'tie - lines[1] - stringify' );
is( $lines[2], 'fred,barney,wilma',      'tie - lines[2] - stringify' );
is( $lines[3], undef,                    'tie - lines[3] - undef' );

is( $lines[0]->[0], 'foo', 'tie - lines[0] - 0' );
is( $lines[0]->[1], qq(b$/ar), 'tie - lines[0] - 1' );
is( $lines[0]->[2], 'baz', 'tie - lines[0] - 2' );
is( $lines[0]->[3], undef, 'tie - lines[0] - 3' );

is( $lines[1]->[0], 'potato',   'tie - lines[1] - 0' );
is( $lines[1]->[1], 'monkey',   'tie - lines[1] - 1' );
is( $lines[1]->[2], 'rutabaga', 'tie - lines[1] - 2' );
is( $lines[1]->[3], undef,      'tie - lines[1] - 3' );

is( $lines[2]->[0], 'fred',   'tie - lines[2] - 0' );
is( $lines[2]->[1], 'barney', 'tie - lines[2] - 1' );
is( $lines[2]->[2], 'wilma',  'tie - lines[2] - 2' );
is( $lines[2]->[3], undef,    'tie - lines[2] - 3' );

ok( close($csv_fh), 'new - close' );
