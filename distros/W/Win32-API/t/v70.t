#!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

use File::Spec;
use Test::More;
use Math::Int64 qw( hex_to_int64 );
use W32ATest;

plan tests => 17;
use vars qw($function $result $return $test_dll );

SKIP: {
    skip('Quads are native on this computer', 17) if 
        IV_SIZE == 8;

use_ok('Win32::API');
use_ok('Win32');


$test_dll = Win32::API::Test::find_test_dll();
diag('API test dll found at (' . $test_dll . ')');
ok(-e $test_dll, 'found API test dll');

#$Win32::API::DEBUG = 1;

#old api
$function = new Win32::API($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)');
ok(defined($function), 'sum_quads_ref() function defined');

$result = "\x00\x00\x00\x00\x00\x00\x00\x00"; #or buffer overflow
is($function->Call("\x00\x00\x00\x00\x00\x00\x00\x02",
                   "\x00\x00\x00\x00\x00\x00\x00\x03", $result),
    "\x00\x00\x00\x00\x00\x00\x00\x05",
   'old api sum_quads_ref() returns the expected value');
is($result, "\x00\x00\x00\x00\x00\x00\x00\x05",
   'sum_quads_ref() correctly modifies its ref argument');

#now new api
$function = new Win32::API::More($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)');
ok(defined($function), 'sum_quads_ref() function defined');

$result = "\x00\x00\x00\x00\x00\x00\x00\x00"; #or buffer overflow
#now you'd think we automatically pack/unpack this since its a *, but we can't
#even though Win32::API::Type::Pack() gets this parameter, it can't pack it
#without Math::Int64 support, so in effect, Quad *, without Math::Int64,
#act like Win32::API not Win32::API::More
is($function->Call("\x00\x00\x00\x00\x00\x00\x00\x02",
                   "\x00\x00\x00\x00\x00\x00\x00\x03", $result),
    "\x00\x00\x00\x00\x00\x00\x00\x05",
   'new api sum_quads_ref() returns the expected value');
is($result, "\x00\x00\x00\x00\x00\x00\x00\x05", 'sum_quads_ref() correctly modifies its ref argument');

#old api with MI64
$function = new Win32::API($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)');
ok(defined($function), 'sum_quads_ref() function defined');
$function->UseMI64(1);
$result = "\x00\x00\x00\x00\x00\x00\x00\x00";
#no automatic un/packing for ptrs
{
    my @arr = $function->Call(hex_to_int64("0x0200000000000000"),
                   hex_to_int64("0x0300000000000000"),
                   $result);
    is(scalar(@arr), 1, 'MI64 sum_quads_ref() returns 1 value');
    is($arr[0],
        hex_to_int64("0x0500000000000000"),
       'old api with MI64 sum_quads_ref() returns the expected value');
}


is($result, "\x00\x00\x00\x00\x00\x00\x00\x05",
   'sum_quads_ref() correctly modifies its ref argument');

#now new api with MI64
$function = new Win32::API::More($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)');
ok(defined($function), 'sum_quads_ref() function defined');

my $pass = 1;
$return = $function->UseMI64();
$pass = $pass && ! $return;
$return = $function->UseMI64(1);
$pass = $pass && ! $return;
$return = $function->UseMI64();
$pass = $pass && $return;
$return = $function->UseMI64(0);
$pass = $pass && $return;
$return = $function->UseMI64();
$pass = $pass && ! $return;
$return = $function->UseMI64(1);
$pass = $pass && ! $return;
ok($pass, "UseMI64 works correctly");

$result = 0; #cant be undef
$return = $function->Call(hex_to_int64("0x0200000000000000"),
                   1, $result); #note, 1 isn't an int64 obj
#print $return." ".hex_to_int64("0x0500000000000001")."\n";
is($return,
    hex_to_int64("0x0200000000000001"),
   'new api with MI64 sum_quads_ref() returns the expected value');
is($result, hex_to_int64("0x0200000000000001"), 'sum_quads_ref() correctly modifies its ref argument');
}
