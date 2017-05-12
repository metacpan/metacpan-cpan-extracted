
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

{ 
  my ($fh, $file) = tempfile();
  print $fh $test_data;

  my @csv;
  ok( tie(@csv, 'Tie::Array::CSV::HoldRow', $fh), "Tied CSV" );

  {

    my $row_1a = $csv[1];
    my $row_1b = $csv[1];
  
    is( $row_1a . "", $row_1b . "", "repeated requests for same row return same object" );

  }

  # DANGER: non-api test follow, do not use in your code, these methods are not guaranteed
  ok( ! defined tied(@csv)->{active_rows}{1}, "on destruction of row object, active_row entry is undef");

  { # unshifting one item
    my $row_2 = $csv[2];
    unshift(@csv, [qw/ a b c /]);
    is( tied(@$row_2)->{line_num}, 3, "after unshifting row knows new line number" );

    my $row_3 = $csv[3];
    is( $row_2 . "", $row_3 . "", "after unshifting still get correct singleton");
  }

  { # splicing
    my $row_0 = $csv[0];
    my $old_row_1 = $csv[1];
    my $row_2 = $csv[2];
    my ($spliced) = splice(@csv, 1, 1);

    is( tied(@$row_0)->{line_num}, 0, "after splicing unaffected row line number is unaffected" );
    is( tied(@$row_2)->{line_num}, 1, "after splicing affected row knows new line number" );
    is( ref $spliced, 'ARRAY', "splice returns an arrayref" ); 
    is( scalar @$spliced, 3, "spliced arrayref is of correct length" );
    ok( ! defined tied(@$old_row_1)->{line_num}, "spliced rows have line numbers removed, severing them" );

    my $row_1 = $csv[1];
    is( $row_2 . "", $row_1 . "", "after splicing still get correct singleton");
  }
}

done_testing();

