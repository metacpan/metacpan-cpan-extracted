
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

use_ok( 'Tie::Array::CSV' );

my $test_data = <<END_DATA;
name,rank,serial number
joel berger,plebe,1010101
larry wall,general,1
damian conway,colonel,1001
END_DATA

{ 
  package My::Text::CSV;
  use Text::CSV;
  our @ISA = ('Text::CSV');

  my $parsed_lines = 0;

  sub my_parsed_lines { return $parsed_lines }

  sub parse {
    my $self = shift;

    $parsed_lines++;

    return $self->SUPER::parse(@_);
  }
}

{
  my ($fh, $file) = tempfile();
  print $fh $test_data;

  my $csv_obj = My::Text::CSV->new();

  my @csv;
  ok( tie(@csv, 'Tie::Array::CSV', $fh, {text_csv => $csv_obj}), "Tied CSV" );

  is( scalar @csv, 4, "Report correct number of rows" );
  is( scalar @{$csv[0]}, 3, "Report correct number of columns" );

  ok( $csv_obj->my_parsed_lines, "Text::CSV subclass" );
 
}

done_testing();

