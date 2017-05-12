#!perl

#
# tests for "header_filter" and "field_filter"
#

use strict;
use File::Spec::Functions;
use FindBin '$Bin';
use Readonly;
use Test::Exception;
use Test::More tests => 14;
use Text::RecordParser;

Readonly my $EMPTY_STR => q{};
Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new;
    is( $p->header_filter, $EMPTY_STR, 'Header filter is blank' );

    throws_ok { $p->header_filter('foo') } qr/doesn't look like code/, 
        'Header filter rejects bad argument';

    $p->bind_fields( qw[ One Two Three ] );

    is( ref $p->header_filter( sub { lc shift } ),
        'CODE', 'Header filter takes value' 
    );

    is( join(',', $p->field_list), 'one,two,three', 
        'setting header filter after binding fields changes field names' );

    is( $p->header_filter($EMPTY_STR), $EMPTY_STR, 
        'Header filter resets to nothing' );

    is( $p->field_filter, $EMPTY_STR, 'Field filter is blank' );

    throws_ok { $p->field_filter('foo') } qr/doesn't look like code/, 
        'Field filter rejects bad argument';

    is( ref $p->field_filter( sub { lc shift } ),
        'CODE', 'Field filter takes value' 
    );

    is( $p->field_filter($EMPTY_STR), $EMPTY_STR, 
        'Field filter resets to nothing' );

    $p->header_filter( sub { lc shift } );
    $p->field_filter( sub { uc shift } );
    $p->filename( catfile( $TEST_DATA_DIR, 'simpsons.csv' ) );
    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'name', 'Field "name"' );
    is( $fields[2], 'city', 'Field "city"' );
    is( $fields[-1], 'dependents', 'Field "dependents"' );

    my @row = $p->fetchrow_array;
    is( $row[2], 'SPRINGFIELD', 'City is "SPRINGFIELD"' );
    is( $row[4], 'MARGE', 'Wife is "MARGE"' );
}
