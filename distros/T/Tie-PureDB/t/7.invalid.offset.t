
use strict;
use Test::Simple tests => 10;
use Tie::PureDB;
require Errno;

my $final = 'fina.db';

my @rand = ( rand, rand, $final);
my $t = Tie::PureDB::Write->new(@rand);

ok(
    $t,
    "creating object(and intermediary files)"
);

ok( $t->add(roscoe => 1234) );

undef $t;

ok(
    ! -e $rand[0]
 && ! -e $rand[1] ,
    "intermediate files have been deleted"
);


$t = Tie::PureDB::Read->new($final);
ok( $t, "created read obect ok");

ok( $t->find('roscoe') , "roscoe key found");
ok( $t->FETCH('roscoe') eq 1234, "roscoe read and value equals 1234");

ok(
    $t->read( $t->getsize(), 6 )
    || int($!)
    , "invalid offset ($!)=".int($!)
);

ok(
    $t->read( $t->getsize(), 9 )
    || int($!)
    , "invalid offset ($!)=".int($!)
);


undef $t;

ok( not defined $t );

ok( unlink( $rand[2] ), "deleting final file");
