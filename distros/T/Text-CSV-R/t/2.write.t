use Test::More tests => 12;
use Test::NoWarnings;
use Test::LongString;

use Text::CSV::R qw(:all);
use File::Temp qw(tempfile);
use Data::Dumper;

my $M_ref = read_csv('t/testfiles/imdb3.dat');

my $output = q{};

my ( $FH, $filename ) = tempfile();
write_table( $M_ref, $filename, sep => q{,} );
is_string(
    slurp($filename),
    slurp('t/testfiles/Routtable.dat'),
    'same as input again'
);
close $FH;

( $FH, $filename ) = tempfile();
write_table( $M_ref, $filename, sep => q{,}, col_names => 0, row_names => 0 );
is_string(
    slurp($filename),
    slurp('t/testfiles/RouttableNoColRow.dat'),
    'same as input again, without col/rownames'
);
close $FH;

( $FH, $filename ) = tempfile();
write_csv( $M_ref, $FH );
close $FH;

is_string(
    slurp($filename),
    slurp('t/testfiles/Routcsv.dat'),
    'same as input again'
);

( $FH, $filename ) = tempfile();
write_table( [ [ 1, 2 ], [ 3, 4 ] ], $filename, sep => q{,} );
is_string( slurp($filename), "1,2\n3,4\n", '2D array' );
close $FH;

( $FH, $filename ) = tempfile();
write_table( [ [ 1, 2 ], [ 3, 4 ] ], $filename, sep => q{,}, col_names => [
    'A', 'B' ] );
is_string( slurp($filename), "A,B\n1,2\n3,4\n", '2D array with array colnames' );
close $FH;

( $FH, $filename ) = tempfile();
write_table( [ [ 1, 2 ], [ 3, 4 ] ], $filename, sep => q{,}, col_names => [
    'A', 'B' ], row_names => [ 'I', 'J'] );
is_string( slurp($filename), "A,B\nI,1,2\nJ,3,4\n", 
    '2D array with array colnames and rownames' );
close $FH;

( $FH, $filename ) = tempfile();

print ${FH} "Hello World!\n"; 
close $FH;
write_table( [ [ 1, 2 ], [ 3, 4 ] ], $filename, sep => q{,}, append => 1 );
is_string( slurp($filename), "Hello World!\n1,2\n3,4\n", '2D array' );

( $FH, $filename ) = tempfile();
write_table( [ [ 1.22, 2.33, 'Hello,World' ], [ 3.44, 4.55, 'Hello.World' ] ], $filename, sep => q{;}, dec
    => q{,}, append => 0 );
is_string( slurp($filename), "1,22;2,33;Hello,World\n3,44;4,55;Hello.World\n", 'dec' );

( $FH, $filename ) = tempfile();

write_table( [ [ 1, 2, 3 ], [ 3, 4 ] ], $filename, sep => q{,}, fill => 1 );
is_string( slurp($filename), "1,2,3\n3,4,\n", '2D array fill' );

write_table( [ [ 1, 2, 3 ], [ 3, 4 ] ], $filename, sep => q{,});
is_string( slurp($filename), "1,2,3\n3,4,\n", '2D array fill' );

write_table( [ [ 1, 2, 3 ], [ 3, 4 ] ], $filename, sep => q{,}, fill => 0 );
is_string( slurp($filename), "1,2,3\n3,4\n", '2D array fill' );

sub slurp {
    my ($file) = @_;
    open my $IN, '<', $file;
    undef $/;
    return <$IN>;
}

