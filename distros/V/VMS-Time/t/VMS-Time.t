# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VMS-Time.t'

#########################

# change 'tests => 22' to 'tests => last_test_to_print';

use Test::More tests => 22;
BEGIN {
    use_ok('VMS::Time');
    import VMS::Time ':all';
};

use POSIX 'strftime';
use Config;
use Math::BigInt;

$base = time();
@base = gmtime($base);
$comp = uc strftime("%e-%b-%Y %H:%M:%S",@base);

cmp_ok( PACK, '==', 0, 'PACK defined' );
cmp_ok( LONGINT, '==', 1, 'LONGINT defined' );
cmp_ok( FLOAT, '==', 2, 'FLOAT defined' );
cmp_ok( HEX, '==', 3, 'HEX defined' );
cmp_ok( BIGINT, '==', 4, 'BIGINT defined' );

$vmst = epoch_to_vms($base);
$e = vms_to_epoch($vmst);
cmp_ok( $e, '==', $base, 'epoch conversion to vms and back results in same value' );

@numt = numtim($vmst);
ok( $numt[0] == ( $base[5] + 1900 ) &&
    $numt[1] == ( $base[4] + 1 ) &&
    $numt[2] == $base[3] &&
    $numt[3] == $base[2] &&
    $numt[4] == $base[1] &&
    $numt[5] == $base[0], 'numtim components compare correctly' )
    or diag( "gmtime: @base\nnumtim: @numt\n" );

$asc = asctim($vmst);
is( substr($asc,0,20), $comp, "asctim string equals strftime result" );

$p = bintim($asc);
$p2 = bintim($asc,PACK);
is( $p, $p2, 'bintim default format is packed' );
cmp_ok( length($p), '==', 8, 'pack returns 8 byte string' );
cmp_ok( vms_to_epoch($p), '==', $base, 'pack to epoch' );
is( asctim($p), $asc, 'PACKED conversion and back ok' );

SKIP: {
    skip 'No 64 bit integer support',2 unless $Config{use64bitint};
    $i = bintim($asc,LONGINT);
    cmp_ok( vms_to_epoch($i), '==', $base, 'longint to epoch' );
    is( asctim($i), $asc, 'conversion to/from longint' );
}

SKIP: {
    skip 'No 64 bit integer support',2 if $Config{archname} =~ /VAX/;
    $d = bintim($asc,FLOAT);
    cmp_ok( vms_to_epoch($d), '==', $base, 'float to epoch' );
    is( asctim($d), $asc, 'conversion to/from float' );
}

$h = bintim($asc,HEX);
cmp_ok( vms_to_epoch($h), '==', $base, 'hex to epoch' );
is( asctim($h), $asc, 'conversion to/from hex' );

$b = bintim($asc,BIGINT);
isa_ok( $b, "Math::BigInt" );
cmp_ok( vms_to_epoch($b), '==', $base, 'bigint to epoch' );
is( asctim($b), $asc, 'conversion to/from bigint' );
