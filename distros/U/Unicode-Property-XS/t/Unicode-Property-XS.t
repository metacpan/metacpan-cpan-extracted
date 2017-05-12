# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unicode-Property-XS.t'

#########################
use utf8;
use Test::More;

BEGIN {
    $Required_Version = 5.010;
}
# The unicode property data is from 5.10 
# and is not consistent with 5.8
BEGIN {
    print "Current Version $] \n";
    if( $] < $Required_Version ) {
        plan tests => 4;
    }
    else {
        plan tests => 9;
    }
}

BEGIN { use_ok( 'Unicode::Property::XS', qw(:all) ) };

#########################

# Turn on LOG if you want to know the details.
my $LOG = 0;

my $okey;
my $okey2;
my @ords = (0x0000..0xd7ff, 0xE000..0xFDCF, 0xFDF0..0xFFFD, 
            0x10000..0x1FFFD,
            0x20000..0x2FFFD,
            0xE0000..0xE0FFF,
           );
my @ords_original = @ords;

$_ = 'a';
my $val  = ( /\p{L}/ ) ? 1 : 0;
my $val2 = ucs_L(ord('a'));
ok( $val == $val2 , "First test.");

##### IsLegal ######
$okey = 1;
for my $ord (@ords) {
    $okey = 0 if (!ucs_Legal($ord));
    $lastChar = $ord;
    if (!$okey) {
        last;
    } 
};

$okey2 = 1;
for my $i (0..$#ords_original) {
    $okey2 = 0 if ($ords_original[$i] != $ords[$i]);
}
    
ok($okey, "[IsLegal] Legal check: Last character: $lastChar");
ok($okey2, "[IsLegal] Input consistancy test");


# if using 10.0 or newer version
if ( $] >= $Required_Version ) {

##### Scalar Test #####
$LOG && (open TEST, ">test_scalar.log");
$okey = 1;
for my $ord (@ords) {
    my $ord2 = $ord;
#    next if (!ucs_Legal($ord2));
    $_ = chr($ord);
    my $val = ( /\p{L}/ ) ? 1 : 0;
    my $val2 = ucs_L($ord) ;
    $LOG && (print TEST "#$ord:($val,$val2)\n");
    # my $val = 1;
    $okey = 0 if ( $val != $val2 );
    die if !defined( $ord );
};
$LOG && (close TEST);

$okey2 = 1;
for my $i (0..$#ords_original) {
    $okey2 = 0 if ($ords_original[$i] != $ords[$i]);
}

ok($okey, "[Scalar] L property test");
ok($okey2, "[Scalar] Input consistancy test");

##### Array Test #####
$LOG && (open TEST, ">test_array.log");

my @a2 = ucs_L(@ords);
#$LOG && (print TEST join ' ', @a2);
$okey  = 1;
$okey2 = 1;
for my $i (0..$#ords) {
    my $property = (chr($ords[$i])=~/\p{L}/) ? 1 : 0;
    $LOG && (print TEST "($property,$a2[$i])\n"); 
    $okey  = 0 if ( $a2[$i] != $property );
    $okey2 = 0 if ( $ords_original[$i] != $ords[$i] );
}
ok($okey,  "[Array] L property test");
ok($okey2, "[Array] Input consistancy test");


my @a3 = chr(@ords);
/\p{L}/ for (@a3);

my @myChars = q( a b c d e f g 1 2 3 );
my @property_list2 = ucs_L( ord(@myChars) );

$LOG && (open TEST, ">test_legal.log");
$okey = 1;
for ((0xd800..0xdFFF),(0xFDD0..0xFDEF),(0x30000..0xDFFFF),(0x10FFFE..0x10FFFF),(0x110000..0x11FFFF),(0x220000..0x220005)) {
    my $ret = ucs_Legal($_);
    if ($ret != 0) {
        $okey = 0;
        $LOG && print TEST sprintf("(%x,%d)\t", $_, $ret);
    };
}
$LOG && close TEST;
ok($okey, "[Legal] Forbidden area test");
 
##### EastAsianWidth Test #####
# use Unicode::EastAsianWidth;
# 
# $LOG && (open TEST, ">test_east_asian_width.log");
# $okey = 1;
# local $Unicode::EastAsianWidth::EastAsian = 0;
# for my $ord (@ords) {
#     my $ord2 = $ord;
#     next if (!ucs_Legal($ord2));
#     $_ = chr($ord);
#     my $val = ( /\p{InFullwidth}/ ) ? 1 : 0;
#     my $val2 = ucs_EaFullwidth0($ord) ;
#     $LOG && (print TEST "#$ord:($val,$val2)\n");
#     # my $val = 1;
#     $okey = 0 if ( $val != $val2 );
#     die if !defined( $ord );
# };
# $LOG && (close TEST);
# 
# $okey2 = 1;
# for my $i (0..$#ords_original) {
#     $okey2 = 0 if ($ords_original[$i] != $ords[$i]);
# }
# 
# ok($okey,  "[EastAsian] InFullWidth property test");
# ok($okey2, "[EastAsian] Input consistancy test");

} # version > 10

__END__
