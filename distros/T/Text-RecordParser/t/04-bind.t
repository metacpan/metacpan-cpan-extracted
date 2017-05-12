#!perl

#
# tests for "bind_fields" and "bind_header"
#

use strict;
use File::Spec::Functions;
use FindBin '$Bin';
use Test::Exception;
use Test::More tests => 16;
use Text::RecordParser;
use Readonly;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new;
    
    throws_ok { my @field_list = $p->field_list } qr/no file/i, 
        'Error on "field_list" with no file';

    is( $p->bind_fields(qw[ foo bar baz ]), 1, 'Bind fields successful' );
    my @fields = $p->field_list;
    is( $fields[0], 'foo', 'Field "foo"' );
    is( $fields[1], 'bar', 'Field "bar"' );
    is( $fields[2], 'baz', 'Field "baz"' );

    my $f1 = catfile($TEST_DATA_DIR, 'simpsons.csv');
    $p->filename( $f1 );
    is( $p->bind_header, 1, 'Bind header successful' );
    @fields = $p->field_list;
    is( $fields[0], 'Name', 'Field "Name"' );
    is( $fields[2], 'City', 'Field "City"' );
    is( $fields[-1], 'Dependents', 'Field "Dependents"' );
}

{
    my $p = Text::RecordParser->new;
    
    throws_ok { $p->bind_fields() } qr/called without field list/i, 
        'Error on bind_field without args';
}

{
    my $p    = Text::RecordParser->new;
    my %pos1 = $p->field_positions;
    ok( !%pos1, 'No field positions with unbound headers' );

    $p->bind_fields( qw[ foo bar baz ] );
    my %pos2 = $p->field_positions;
    my %should_be = (
        foo => 0,
        bar => 1,
        baz => 2,
    );

    is_deeply( \%pos2, \%should_be, 'field positions OK' );
}

{
    my $empty_file = catfile( $TEST_DATA_DIR, 'empty' );
    my $p = Text::RecordParser->new( $empty_file );
    
    throws_ok { $p->bind_header() } qr/can't find columns in file/i,
        'Error on bind_header with empty file';
}

{
    my $p = Text::RecordParser->new;
    $p->field_separator("\t");
    my $f2 = catfile($TEST_DATA_DIR, 'simpsons.tab');
    $p->filename( $f2 );
    ok( my @fields = $p->field_list, 'bind_header implicitly called' );
    is( scalar @fields, 7, 'Found seven fields' );
    is( join(',', @fields), 'Name,Address,City,State,Wife,Children,Pets', 
        'Fields OK');
}
