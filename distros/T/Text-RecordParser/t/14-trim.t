#!perl

#
# tests for "trim"
#

use strict;
use File::Spec::Functions;
use FindBin '$Bin';
use Readonly;
use Test::Exception;
use Test::More tests => 4;
use Text::RecordParser;
use Text::RecordParser::Tab;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $file = catfile( $TEST_DATA_DIR, 'trim.csv' );
    my $p    = Text::RecordParser->new( $file );
    my $r1   = $p->fetchrow_hashref;
    is( $r1->{'SerialNumber'}, '1656401  ', 'Serial number OK' ); 

    my $r2   = $p->fetchrow_hashref;
    is( $r2->{'SerialNumber'}, '    ', 'Blank serial number OK' ); 
}

{
    my $file = catfile( $TEST_DATA_DIR, 'trim.csv' );
    my $p    = Text::RecordParser->new( $file );
    $p->trim(1);
    my $r1   = $p->fetchrow_hashref;
    is( $r1->{'SerialNumber'}, '1656401', 'Serial number OK' ); 

    my $r2   = $p->fetchrow_hashref;
    is( $r2->{'SerialNumber'}, '', 'Blank serial number OK' ); 
}
