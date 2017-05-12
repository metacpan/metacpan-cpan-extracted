
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

use Text::CSV;

use_ok( 'Tie::Array::CSV' );

my @test_data = (
  ['name', 'rank', 'serial number'],
  ['joel berger', 'plebe', 1010101],
  ['larry wall', 'general', 1],
  ['damian conway', 'colonel', 1001],
);

sub make_test_string {
  my $sep = shift || ',';

  my $string;
  for (@test_data) {
    $string .= join($sep, @$_) . "\n";
  }

  return $string;
}

{ # test constructors with only file arguments

  my ($fh, $file) = tempfile();
  print $fh make_test_string();

  {
    tie my @csv, 'Tie::Array::CSV', $fh;
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, no args');
  }

  {
    tie my @csv, 'Tie::Array::CSV', {file => $fh};
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, no args');
  }

  {
    tie my @csv, 'Tie::Array::CSV', file => $fh;
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, no args');
  }

  {
    my $csv = Tie::Array::CSV->new($fh);
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, no args');
  }

  {
    my $csv = Tie::Array::CSV->new( {file => $fh} );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, no args');
  }

  {
    my $csv = Tie::Array::CSV->new( file => $fh );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, no args');
  }

}

{ # test contructors with sep_char arguments

  my ($fh, $file) = tempfile();
  print $fh make_test_string(';');

  {
    tie my @csv, 'Tie::Array::CSV', $fh, { text_csv => { sep_char => ';' } };
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, opts->text_csv->sep_char');
  }

  {
    tie my @csv, 'Tie::Array::CSV', $fh, text_csv => { sep_char => ';' };
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, opts->text_csv->sep_char');
  }

  {
    tie my @csv, 'Tie::Array::CSV', $fh, { sep_char => ';' };
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, opts->text_csv->sep_char');
  }

  {
    tie my @csv, 'Tie::Array::CSV', $fh, sep_char => ';';
    isa_ok( tied(@csv), 'Tie::Array::CSV' );
    is_deeply( \@csv, \@test_data, 'tie contructor, opts->text_csv->sep_char');
  }

  {
    my $csv = Tie::Array::CSV->new($fh, { text_csv => { sep_char => ';' } } );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, opts->text_csv->sep_char');
  }

  {
    my $csv = Tie::Array::CSV->new($fh, text_csv => { sep_char => ';' } );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, text_csv->sep_char');
  }

  {
    my $csv = Tie::Array::CSV->new($fh, { sep_char => ';' } );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, text_csv->sep_char');
  }

  {
    my $csv = Tie::Array::CSV->new($fh, sep_char => ';' );
    isa_ok( tied(@$csv), 'Tie::Array::CSV' );
    is_deeply( $csv, \@test_data, 'new contructor, text_csv->sep_char');
  }

}

done_testing();
