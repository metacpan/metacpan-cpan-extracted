#!perl

#
# tests for alternate parsing
#

use strict;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::More tests => 4;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.tab' );
    my $p    = Text::RecordParser->new(
        filename        => $file,
        field_separator => "\t",
    );
    $p->bind_header;
    my $row = $p->fetchrow_hashref;
    is( $row->{'Wife'}, 'Marge', 'Wife is Marge' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.alt' );
    my $p = Text::RecordParser->new(
        filename         => $file,
        field_separator  => "\n",
        record_separator => "\n//\n",
    );
    $p->bind_header;
    my $row = $p->fetchrow_hashref;
    is( $row->{'Wife'}, 'Marge', 'Wife is still Marge' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'pipe.dat' );
    my $p    = Text::RecordParser->new(
        filename         => $file,
        field_separator  => qr/\|/,
    );
    my $row = $p->fetchrow_array;
    is( $row->[0], 'MSH', 'First field is "MSH"' );
    is( $row->[-1], '2.2', 'Last field is "2.2"' );
}
