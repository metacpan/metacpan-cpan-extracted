#!perl

#
# tests for "filename," "fh," "data," etc.
#

use strict;
use File::Spec::Functions;
use File::Temp qw( tempfile );
use FindBin qw( $Bin );
use IO::File;
use Readonly;
use Test::Exception;
use Test::More tests => 41;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new;

    is( $p->filename, '', 'Filename is blank' );

    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    is( $p->filename($file), $file, 'Filename sets OK' );

    throws_ok { $p->filename($TEST_DATA_DIR) } qr/cannot use dir/i, 
        'filename rejects directory for argument';

    my $bad_file = catfile( $TEST_DATA_DIR, 'non-existent' );
    throws_ok { $p->filename($bad_file) } qr/file does not exist/i, 
        'filename rejects non-existent file';

    my @fields = $p->field_list;
    ok( @fields, 'Got field list' );
    my $file2 = catfile( $TEST_DATA_DIR, 'simpsons.tab' );
    $p->filename( $file2 ); 
    my @fields2 = $p->field_list;
    ok( join(',', @fields) ne join(',', @fields2), 
        'Field list is flushed when resetting filename' );
}

#
# Filehandle tests
#
{
    my $p = Text::RecordParser->new;

    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    open my $fh, '<', $file or die "Read of '$file' failed: $!";
    is ( ref $p->fh( $fh ), 'GLOB', 'fh is a filehandle' );

    # Cause an error by closing the existing fh.
    close $fh;
    my $tabfile = catfile( $TEST_DATA_DIR, 'simpsons.tab' );
    open my $fh2, '<', $tabfile or die "Read of '$tabfile' failed: $!";

    throws_ok { $p->fh( $fh2 ) } qr/can't close existing/i, 
        'fh catches bad close';

    throws_ok { $p->fh('') } qr/doesn't look like a filehandle/i, 
        'fh catches bad arg';

    my $file3 = catfile( $TEST_DATA_DIR, 'simpsons.cvs');
    my $io = IO::File->new( $file3 );
    is ( ref $p->fh( $io ), 'GLOB', 'fh is a filehandle' );
}

{
    # cause an error on a closed filehandle
    my ( $fh, $filename ) = tempfile();

    my $p = Text::RecordParser->new( fh => $fh );

    close $fh;
    unlink $filename;

    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );

    throws_ok { $p->filename( $file ) } qr/Can't close previously opened/, 
        'filename dies trying to close a closed filehandle';
}

{
    # cause an error on a disappearing file
    my $p = Text::RecordParser->new;
    my ( $fh, $filename ) = tempfile();
    $p->filename( $filename );
    close $fh;
    unlink $filename;
    throws_ok { my $data = $p->fh } qr/Cannot read '\Q$filename\E'/, 
        'fh dies on bad file'; 
}

#
# Data tests
#
{
    my $p = Text::RecordParser->new;
    throws_ok { $p->data() } qr/without any arguments/, 
        'data called without args dies';
}

{
    my $p = Text::RecordParser->new;
    throws_ok { $p->data('') } qr/no usable/i, 'data dies with no usable data';
}

{
    my $p = Text::RecordParser->new;
    my $scalar = "lname,fname,age\nSmith,Joan,20\nDoe,James,21\n";
    $p->data( \$scalar );
    $p->bind_header;
    my @fields = $p->field_list;

    is( scalar @fields, 3, 'data accepted scalar ref' );
}

{
    my $p = Text::RecordParser->new;
    $p->data( "lname,fname,age\n", "Smith,Joan,20\nDoe,James,21\n" );
    $p->bind_header;
    my @fields = $p->field_list;

    is( scalar @fields, 3, 'data accepted an array' );
}

{
    my $p = Text::RecordParser->new;
    my @array = ( "lname,fname,age\n", "Smith,Joan,20\nDoe,James,21\n" );
    $p->data( \@array );
    $p->bind_header;
    my @fields = $p->field_list;

    is( scalar @fields, 3, 'data accepted an array ref' );
}

{
    my $p      = Text::RecordParser->new;
    my $scalar = "lname,fname,age\nSmith,Joan,20\nDoe,James,21\n";

    ok( $p->data( $scalar ), 'data accepts a scalar' );
    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'lname', 'lname field' );
    is( $fields[1], 'fname', 'fname field' );
    is( $fields[2], 'age', 'age field' );

    my $rec = $p->fetchrow_hashref;
    is( $rec->{'lname'}, 'Smith', 'lname = "Smith"' );
    is( $rec->{'fname'}, 'Joan', 'fname = "Joan"' );
    is( $rec->{'age'}, '20', 'age = "20"' );

    $rec = $p->fetchrow_array;
    is( $rec->[0], 'Doe', 'lname = "Doe"' );
    is( $rec->[1], 'James', 'fname = "James"' );
    is( $rec->[2], '21', 'age = "21"' );

    $p->data( 
        "name\tinstrument\n", 
        "Miles Davis\ttrumpet\n", 
        "Art Blakey\tdrums\n" 
    );

    $p->field_separator("\t");
    $p->bind_header;
    @fields = $p->field_list;
    is( $fields[0], 'name', 'name field' );
    is( $fields[1], 'instrument', 'instrument field' );

    $rec = $p->fetchrow_array;
    is( $rec->[0], 'Miles Davis', 'name = "Miles Davis"' );
    is( $rec->[1], 'trumpet', 'instrument = "trumpet"' );

    $rec = $p->fetchrow_hashref;
    is( $rec->{'name'}, 'Art Blakey', 'name = "Art Blakey"' );
    is( $rec->{'instrument'}, 'drums', 'instrument = "drums"' );

    my $filename = "$Bin/data/simpsons.csv";
    open my $fh, "<$filename" or die "Can't read '$filename': $!";
    is ( $p->data( $fh ), 1, 'data accepts a filehandle' );
    is ( UNIVERSAL::isa( $p->fh, 'GLOB' ), 1, 'fh is a GLOB' );
}

{
    my $p    = Text::RecordParser->new(
        data => "lname,fname,age\nSmith,Joan,20\nDoe,James,21\n"
    );

    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'lname', 'lname field' );
    is( $fields[1], 'fname', 'fname field' );
    is( $fields[2], 'age', 'age field' );

    my $rec = $p->fetchrow_hashref;
    is( $rec->{'lname'}, 'Smith', 'lname = "Smith"' );
    is( $rec->{'fname'}, 'Joan', 'fname = "Joan"' );
    is( $rec->{'age'}, '20', 'age = "20"' );
}
