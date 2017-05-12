
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

use Text::CSV;

use_ok( 'Tie::Array::CSV' );

my $test_data = <<END_DATA;
name,rank,serial number
joel berger,plebe,1010101
larry wall,general,1
damian conway,colonel,1001
END_DATA

{
  my ($fh, $file) = tempfile();
  print $fh $test_data;

  my @csv;
  ok( tie(@csv, 'Tie::Array::CSV', $fh), "Tied CSV" );

  is( scalar @csv, 4, "Report correct number of rows" );
  is( scalar @{$csv[0]}, 3, "Report correct number of columns" );

  is( $csv[0][0], "name", "Find individual element" );
  is( $csv[1][1], "plebe", "Find another element" );

  $csv[1][1] = "peon";

  is( $csv[1][1], "peon", "Modified element" );

  is( shift @{ $csv[3] }, "damian conway", "Shifted element gotten" );
  is( $csv[3][0], "colonel", "Shifted element removed from array" );

  is( pop @{ $csv[3] }, 1001, "Popped element gotten" );
  is( scalar @{ $csv[3] }, 1, "Popped element removed" );

  push @{ $csv[3] }, 1002;
  is( $csv[3][1], 1002, "Pushed element added" );

  pop @csv;
  is( scalar @csv, 3, "Pop outer array removes row" );

  my $header = ["name", "rank", "serial number"];
  is_deeply( shift @csv, $header, "Shifted outer array row gotten" );

  push @csv, $header;
  is_deeply( delete $csv[-1], $header, "Delete on outer array, row gotten" );

  is( $csv[0][0], "joel berger", "Shift outer array removed row" );

  $csv[1][2] += 2;

  is( $csv[1][2], 3, "In place addition" );
  is( ++$csv[1][2], 4, "In place pre-increment" );

  $csv[1][2] .= '2';
  is( $csv[1][2], 42, "In place string join" );

  ok( exists $csv[0], "First element exists" );
  ok( ! exists $csv[1000], "1000th element doesn't exist" );

  push @csv, [ "tom christiansen", "major", 1101 ];

  ok( untie @csv, "Untie succeeds" );

  seek $fh, 0, 0;
  my $parser = Text::CSV->new();

  is_deeply( $parser->getline($fh), ["joel berger", "peon", 1010101 ], "File was updated 1" );
  is_deeply( $parser->getline($fh), ["larry wall", "general", 42 ], "File was updated 2" );
  is_deeply( $parser->getline($fh), [ "tom christiansen", "major", 1101 ], "File was updated 3" );
  
}

done_testing();

