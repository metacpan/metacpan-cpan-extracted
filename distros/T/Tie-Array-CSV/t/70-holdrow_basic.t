
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

use Text::CSV;
my $parser = Text::CSV->new();

use_ok( 'Tie::Array::CSV::HoldRow' );

my $test_data = <<END_DATA;
name,rank,serial number
joel berger,plebe,1010101
larry wall,general,1
damian conway,colonel,1001
END_DATA

{ # hold_row => 1
  my ($fh, $file) = tempfile();
  print $fh $test_data;

  my @csv;
  ok( tie(@csv, 'Tie::Array::CSV::HoldRow', $fh), "Tied CSV" );

  {
    my $row = $csv[0];
    push @$row, 'favorite color';

    seek $fh, 0, 0;
    is_deeply( $parser->getline($fh), ['name', 'rank', 'serial number' ], "Row is held" );
  }

  seek $fh, 0, 0;
  is_deeply( $parser->getline($fh), ['name', 'rank', 'serial number', 'favorite color' ], "File is updated after row object goes out of scope" );
  
}

{ # hold_row => 0
  my ($fh, $file) = tempfile();
  print $fh $test_data;

  my @csv;
  ok( tie(@csv, 'Tie::Array::CSV', $fh, hold_row => 0), "Tied CSV" );

  my $row = $csv[0];
  push @$row, 'favorite color';

  seek $fh, 0, 0;
  is_deeply( $parser->getline($fh), ['name', 'rank', 'serial number', 'favorite color' ], "File is updated immmediately" );
  
}

done_testing();
