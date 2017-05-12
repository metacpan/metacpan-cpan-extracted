# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-FindFile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan' => () ;

use lib 'lib';
use Data::Dumper;
use constant T=> 'Win32::FindFile';
use strict;
use warnings;

BEGIN{
    my $T = T;
    eval "use ExtUtils::testlib;" unless grep { m/::testlib/ } keys %INC;
    print "not ok $@" if $@;
    eval "use $T ();";
    die "Can't load $T: $@." if $@;

    my $d_glob = \%main::;
    no strict 'refs';

    my $s_glob = \%{ "$T\::" };
    $d_glob->{$_} = $s_glob->{$_} for 'wchar', 'wfchar', 'uchar';

};
use Encode qw(from_to);
sub _uchar{
    my $x = shift;
    Encode::from_to( $x, "UTF-16LE", "utf8");
    $x=~s/\x00.*//s;
    return $x;
}
sub _wchar{
    my $x = shift;
    $x=~s/\x00.*//s;
    $x.="\x00";
    Encode::from_to( $x, "utf8", "UTF-16LE");
    return $x;
}




my $x = "Hello.txt";
my $y;
ok( wchar( $x ) eq _wchar( $x ), "wchar ASCII-1" );
$y = _wchar( $x );
ok( uchar( $y ) eq _uchar( $y ), "uchar ASCII-1" );
$x .= $_ for map chr, 1..127;
utf8::encode($x);

ok( wchar( $x ) eq _wchar( $x ), "wchar ASCII-2" );
$y = _wchar( $x );
ok( uchar( $y ) eq _uchar( $y ), "uchar ASCII-2" );
$x ='';
$x .= $_ for map chr,128..2047;
utf8::encode( $x );
ok( wchar( $x ) eq _wchar( $x ), "wchar ext-r1" );
$y = _wchar( $x );
ok( uchar( $y ) eq _uchar( $y ), "uchar ext-r2" );

$x ='';
$x .= $_ for map chr,2048..0x0B7FF;
utf8::encode( $x );
ok( wchar( $x ) eq _wchar( $x ), "wchar ext-r2" );
$y = _wchar( $x );
ok( uchar( $y ) eq _uchar( $y ), "uchar ext-r2" );


$x = "123\\txt\\xmk.";
ok( _wchar( $x ) eq wfchar($x), "wfchar -1");
$x = "x" x 250 . $x;
my $prefix =  "\\\x00\\\x00?\x00\\\x00";
my $uprefix = $prefix ; Encode::from_to( $_, "UTF-16LE", "utf8") for $uprefix;

ok( $prefix . _wchar( $x ) eq wfchar($x), "wfchar -2");
ok( _wchar($uprefix . $x) eq wfchar( $uprefix . $x), "wfchar -3");

$y = "123/txt/xmk.";
$y = "x" x 250 . $y;

ok( $prefix . _wchar( $x ) eq wfchar($y), "wfchar -4");
ok( _wchar($uprefix . $y) eq wfchar( $uprefix . $y), "wfchar -5");
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

