#!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

use File::Spec;
use Test::More;
use W32ATest;
BEGIN {
    eval { require Encode; };
    if($@){
        require Encode::compat;
    }
    Encode->import();
}
use Math::Int64 ('hex_to_int64');

plan tests => 22;
use vars qw($function $result $return $test_dll );


use_ok('Win32::API', 'SafeReadWideCString');


$test_dll = Win32::API::Test::find_test_dll();
diag('API test dll found at (' . $test_dll . ')');
ok(-e $test_dll, 'found API test dll');

#in 0.70 and older, if you typedef to a string, you actually a typedef
#to a char, C func won't get a pointer but a extended char

# Find a char in a string
Win32::API::Type->typedef('MYSTRING','char *');
$function = new Win32::API($test_dll, 'char* find_char(MYSTRING string, char ch)');
ok(defined($function), 'find_char() function defined');

#diag("$function->{procname} \$^E=", $^E);
{
my $string = 'japh';
my $char   = 'a';
is($function->Call($string, $char), 'aph', 'find_char() function call works');
}

{
my $source = Encode::encode("UTF-16LE","Just another perl hacker\x00");
my $string = '';
$string = SafeReadWideCString(unpack(PTR_LET(),pack('p', $source)));
is($string, "Just another perl hacker", "SafeReadWideCString ASCII");
$string = '';
$source = Encode::encode("UTF-16LE","Just another perl h\x{00E2}cker\x00");
$string = SafeReadWideCString(unpack(PTR_LET(),pack('p', $source)));
is($string, "Just another perl h\x{00E2}cker", "SafeReadWideCString Wide");
$string = SafeReadWideCString(0);
ok(! defined $string, "SafeReadWideCString null pointer");
}

eval {
    $function = new Win32::API($test_dll, 'GetHandle', 'N', 'S', '__stdcall');
};
ok(index($@, 'Win32::API invalid return type, structs and callbacks') != -1,
   "Struct 'S' invalid return type");
eval {
    $function = new Win32::API($test_dll, 'GetHandle', 'N', 'T', '__stdcall');
};
ok(index($@, 'Win32::API invalid return type, structs and callbacks') != -1,
   "Struct 'T' invalid return type");
eval {
    $function = new Win32::API($test_dll, 'GetHandle', 'N', 'K', '__stdcall');
};
ok(index($@, 'Win32::API invalid return type, structs and callbacks') != -1,
   "Callback invalid return type");
eval {
    $function = new Win32::API::More($test_dll, 'GetHandle', 'N', 'T', '__stdcall');
};
ok(index($@, 'Win32::API invalid return type, structs and callbacks') != -1,
   "::More Struct 'T' invalid return type");
eval {
    $function = new Win32::API::More($test_dll, 'GetHandle', 'N', 'K', '__stdcall');
};
ok(index($@, 'Win32::API invalid return type, structs and callbacks') != -1,
   "::More Callback invalid return type");

{
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', 'V', 'N');
    ok($function->Call(), "GetCurrentThreadId with 'V' in proto works");
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', ['V'], 'N');
    ok($function->Call(), "GetCurrentThreadId with array 'V' in proto works");
eval{
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', ['V', 'N'], 'N');
};
    ok(index($@, "Win32::API 'V' for in prototype must be the only parameter") != -1,
    "in V proto param + other param fails");
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', '', 'N');
    ok($function->Call(), "GetCurrentThreadId with '' in proto works");
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', '', '');
    ok(! defined $function->Call(), "GetCurrentThreadId with '' out proto works");
    $function = Win32::API->new('kernel32.dll', 'GetCurrentThreadId', '', 'V');
    ok(! defined $function->Call(), "GetCurrentThreadId with '' out proto works");
}

SKIP: {
    skip('Quads are native on this computer', 4) if 
        IV_SIZE == 8;
    #test that UseMI64 is not required for non Callback "in" params
    $function = new Win32::API::More($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)');
    $result = 0; #cant be undef
    diag("under 8 byte warnings are intended");
    eval {
        $return = $function->Call(hex_to_int64("0x0200000000000000"),
                   1, $result); #note, 1 isn't an int64 obj, and will produce garbage
    };
    ok(index($@, 'Win32::API::Call: parameter 2 must be a packed 8 bytes long string')
       != -1, "in UseMI64 off mode, numeric scalar '1' turns to bad 1 char string");
    #note, 10,000,000 isn't an int64 obj, but passes length check when converted to string
    #nothing can be done to protect against this usage mistake
    $return = $function->Call(hex_to_int64("0x0200000000000000"), 10000000, $result);
    is($return, $result, "garbage return and garbage pointer fill the same");
    ok($return && $return != hex_to_int64("0x0200000000000001"),
       "in UseMI64 off mode, 8 digit numeric scalar defeats 8 byte length check but produces garbage output");
    $result = 0;
    $return = $function->Call(hex_to_int64("0x0200000000000000"),
                   hex_to_int64("0x1"), $result); #note, 1 isn't an int64 obj, and will produce garbage
    ok($return eq "\x01\x00\x00\x00\x00\x00\x00\x02"
       && $result eq "\x01\x00\x00\x00\x00\x00\x00\x02",
       "pointer to quad is equal to returned quad without UseMI64");
}
