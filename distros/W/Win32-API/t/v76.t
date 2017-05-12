#!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

use Test::More;
use Math::Int64 qw( hex_to_int64 );
use W32ATest;

plan tests => 22;
use vars qw($function $result $return $test_dll $dllhandle);
use Win32::API 'IsBadReadPtr';
use Win32API::File qw(SetErrorMode SEM_FAILCRITICALERRORS);
use Win32;

$test_dll = Win32::API::Test::find_test_dll();
ok(-e $test_dll, 'found API test dll');

#test that when the sub created by ::Import is deleted, the API obj is destroyed
ok($dllhandle = Win32::LoadLibrary($test_dll), "loaded test dll");
ok(Import Win32::API($test_dll, 'int sum_integers(int a, int b)'), "Import() on sum_integers worked");
ok(Win32::FreeLibrary($dllhandle), 'refcnt --ed on test dll');
is(sum_integers(2, 3), 5, 'function call with integer arguments and return value (Import)');
*sum_integers = *nothing;
eval{ sum_integers(2, 3); };
ok($@, 'undefed ::Import sub fails $@="'.(chomp($@), $@).'"');
ok(IsBadReadPtr($dllhandle, 1), "test dll unloaded");

#make sure ::More::Import packs and unpacks, and didn't create a ::API instead
#of ::API::More
ok(Import Win32::API::More($test_dll, 'USHORT  __stdcall sum_shorts_ref(short a, short b, signed short *c)')
    , "Import() on sum_shorts_ref worked");
$result = 0;
is(sum_shorts_ref(2, 3, $result), 32768, 'sum_shorts_ref() returns the expected unsigned value');
is($result, 5, 'sum_shorts_ref() correctly modifies its ref argument');

ok(!(Import Win32::API::More($test_dll, 'void __stdcall ThisDoesntExist()'))
   && $^E == 127 #ERROR_PROC_NOT_FOUND
    , "Import() on non existant func failed");
ok(!(Import Win32::API::More('dlldoesntexist8132y49.dll', 'void __stdcall ThisDoesntExist()'))
   && $^E == 126  #ERROR_MOD_NOT_FOUND
    , "Import() on non existant dll failed");

{
    my $wrong_arch_dll_name = Win32::API::Test::find_test_dll(
        Win32::API::Test::is_perl_64bit() ? 'API_test.dll' : 'API_test64.dll');
    ok(-e $wrong_arch_dll_name, 'found wrong architecture API test dll');
    my $olderrmode = SetErrorMode(SEM_FAILCRITICALERRORS); #don't hang with a dialog box
    $function = new Win32::API::More($wrong_arch_dll_name, 'HANDLE __stdcall GetGetHandle()');
    ok(!defined($function) && Win32::GetLastError() == 193 #ERROR_BAD_EXE_FORMAT
       , "wrong architecture DLL load has correct GLR");
    SetErrorMode($olderrmode);
}

{
$function = new Win32::API::More($test_dll, 'HANDLE __stdcall GetGetHandle()');
my $funcptr = $function->Call();

$function = Import Win32::API::More(undef, $funcptr, 'GetHandle', 'P', 'I');
my $hnd = pack(PTR_LET(), 0);
my $pass = 1;
#print "pn ".${Win32::API::GetMagicSV($function)}{procname} ."\n";
$pass = $pass && defined($function);
$result = GetHandle($hnd);
$pass = $pass && $result == 1;
$pass = $pass && unpack(PTR_LET(), $hnd) == 4000;
ok($pass, 'GetHandle from func pointer using letter interface operates correctly');
$function = Import Win32::API::More(undef, $funcptr, undef, 'P', 'I');
ok(!$function && Win32::GetLastError() == Win32::API::ERROR_INVALID_PARAMETER
   , "empty string as func name for func * not allowed");
}

SKIP: {
    skip('Quads are native on this computer', 4) if
        IV_SIZE == 8;
    my $function; #small scope intentional
    ok($function = Import Win32::API::More($test_dll, 'LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c)')
        , "Import() on sum_quads_ref worked");
    ok(!$function->UseMI64(1), "UseMI64 works correctly");

    $result = 0; #cant be undef
    $return = $function->Call(hex_to_int64("0x0200000000000000"),
                   1, $result); #note, 1 isn't an int64 obj
    is($return,
        hex_to_int64("0x0200000000000001"),
       '::More::Import() with MI64 sum_quads_ref() returns the expected value');
    is($result, hex_to_int64("0x0200000000000001"), 'sum_quads_ref() correctly modifies its ref argument');
}

# Sum 2 shorts
$function = new Win32::API::More($test_dll, 'short sum_shorts(short a, short b)');
ok(defined($function), 'sum_shorts() function defined');

is($function->Call(-1, 0), -1, 'function call with negative short arguments and return value (Call) #94906');
