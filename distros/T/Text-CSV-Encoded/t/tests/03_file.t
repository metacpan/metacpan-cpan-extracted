use Encode;
use utf8;

my $csv  = Text::CSV::Encoded->new({
    encoding_in  => 'utf8',
    encoding_out => 'shiftjis',
});
my $file = sprintf('sample/test_%s.csv' , $csv->backend =~ /PP/ ? 'pp' : 'xs' );



open (my $fh, "sample/utf8.csv") or die $!;
open (my $fh2, ">$file") or die $!;


#
# column_names & getline_hr
#

$csv->column_names( $csv->getline($fh) );

while( my $hr = $csv->getline_hr( $fh ) ) {
    $csv->print( $fh2, [ $hr->{text} ] );
    $fh2->print("\n");
}

close($fh);
close($fh2);


my $checker = Text::CSV->new({ binary => 1});

open ($fh,  $file) or die $!;
open ($fh2,  "sample/sjis.csv") or die $!;

<$fh2>;

$csv->encoding_in( 'shiftjis' );


while( 1 ) {
    my $row = $csv->getline( $fh );
    $csv->eof and last;
    is( Encode::encode( 'shiftjis', $row->[0] ), $checker->getline( $fh2 )->[1] );
}

close($fh);
close($fh2);


# convert directly

# shiftjis

open ($fh,  $file) or die $!;
open ($fh2,  "sample/sjis.csv") or die $!;

<$fh2>;

$csv->encoding_in( 'shiftjis' );
$csv->encoding( 'shiftjis' );

while( 1 ) {
    my $row = $csv->getline( $fh );
    $csv->eof and last;
    is( $row->[0], $checker->getline( $fh2 )->[1] );
}

close($fh);
close($fh2);


# utf8

open ($fh,  $file) or die $!;
open ($fh2,  "sample/utf8.csv") or die $!;

<$fh2>;

$csv->encoding_in( 'shiftjis' );
$csv->encoding( 'utf8' );

while( 1 ) {
    my $row = $csv->getline( $fh );
    $csv->eof and last;
    my $string = $checker->getline( $fh2 )->[1];
    $string = encode_utf8( $string ) if ( $csv->automatic_UTF8 );
    is( $row->[0], $string );
}

close($fh);
close($fh2);


# unicode

open ($fh,  $file) or die $!;
open ($fh2,  "sample/utf8.csv") or die $!;

<$fh2>;

$csv->encoding_in( 'shiftjis' );
$csv->encoding( undef );

while( 1 ) {
    my $row = $csv->getline( $fh );
    $csv->eof and last;
    my $data = $checker->getline( $fh2 )->[1];
    is( $row->[0], utf8::is_utf8 ($data) ? $data : Encode::decode_utf8( $data ) );
}

close($fh);
close($fh2);


#
# bind_columns
#

my ( $id, $text );
$csv->bind_columns( \$id, \$text );

$csv->encoding_in( 'utf8' );
$csv->encoding( 'shiftjis' );

open ($fh,  $file) or die $!;
open ($fh2,  "sample/utf8.csv") or die $!;

<$fh2>;

while( my $col = $csv->getline( $fh2 ) ) {
    is( $text, $checker->getline( $fh )->[0] );
}

close($fh);
close($fh2);



unlink( $file ) or warn $!;

1;
