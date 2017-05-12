use strict;

use Test::More tests => 15;
use Time::Piece::DB2;
ok(1, "loaded");

my $lt = localtime;
isa_ok( $lt, 'Time::Piece' );

my $gmt = gmtime;
isa_ok( $gmt, 'Time::Piece' );

for my $t ( $lt, $gmt )
{
    is( $t->db2_date, $t->ymd );

    is( $t->db2_time, $t->hms(":") );

    my $mdt = join ' ', $t->ymd, $t->hms(":");
    is( $t->db2_timestamp, $mdt );
}

# doesn't work right now because of some weirdness with strptime that
# Matt S will fix (I hope) some day.
my $t = Time::Piece->from_db2_timestamp( $lt->db2_timestamp .".010010" );

isa_ok( $t, 'Time::Piece' );

is( $t->db2_timestamp, $lt->db2_timestamp );

my $t2 = Time::Piece->from_db2_date( $lt->db2_date );
isa_ok( $t2, 'Time::Piece' );

is( $t2->ymd, $lt->ymd );

my $t3 = Time::Piece->from_db2_time( $lt->db2_time .".010010");
isa_ok( $t3, 'Time::Piece' );
is( $t3->hms, $lt->hms );

