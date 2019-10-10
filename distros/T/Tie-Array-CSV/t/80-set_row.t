
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

  @{ $csv[1] } = ('plicease', 'tinkerer', '47');
  @{ $csv[2] } = ();

  seek $fh, 0, 0;
  my $parser = Text::CSV->new();

  is_deeply( $parser->getline($fh), ["name", "rank", "serial number" ], "File was updated 1" );
  is_deeply( $parser->getline($fh), ["plicease", "tinkerer", 47 ], "File was updated 1" );
  is_deeply( $parser->getline($fh), [''], "File was updated 2" );
  is_deeply( $parser->getline($fh), ["damian conway", "colonel", 1001 ], "File was updated 3" );
  
}

done_testing();

