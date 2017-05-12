#!perl

#
# tests for skipping records matching a comment regex
#

use strict;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::Exception;
use Test::More tests => 5;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new; 
    throws_ok { $p->comment('foo') } qr/look like a regex/i, 
        '"comment" rejects non-regex argument';
}

{
    my $file     = catfile( $TEST_DATA_DIR, 'commented.dat' );
    my $p        =  Text::RecordParser->new( 
        filename => $file,
        comment  => qr/^#/,
    );

    $p->bind_header;
    my $row1 = $p->fetchrow_hashref;
    is( $row1->{'field1'}, 'foo', 'Field is "foo"' );

    my $row2 = $p->fetchrow_hashref;
    is( $row2->{'field2'}, 'bang', 'Field is "bang"' );
}

{
    my $file     = catfile( $TEST_DATA_DIR, 'commented2.dat' );
    my $p        =  Text::RecordParser->new( 
        filename => $file,
        comment  => qr/^--/,
    );

    $p->bind_header;
    my $row1 = $p->fetchrow_hashref;
    is( $row1->{'field1'}, 'foo', 'Field is "foo"' );

    my $row2 = $p->fetchrow_hashref;
    is( $row2->{'field2'}, 'bang', 'Field is "bang"' );
}
