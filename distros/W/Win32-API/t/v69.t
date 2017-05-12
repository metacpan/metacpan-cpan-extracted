#!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

#use Config; # ?not used
use File::Spec;
use Test::More;
BEGIN {
    eval { require Encode; };
    if($@){
        require Encode::compat;
    }
    Encode->import();
}

plan tests => 36;
use vars qw($function $function2 $result $test_dll $input $ptr);

use_ok('Win32::API', qw( ReadMemory IsBadReadPtr MoveMemory WriteMemory));
use_ok('W32ATest');
use_ok('Win32');


$test_dll = Win32::API::Test::find_test_dll();
diag('API test dll found at (' . $test_dll . ')');
ok(-e $test_dll, 'found API test dll');

my $cygwin = $^O eq 'cygwin';

#pointer types
{
#$Win32::API::DEBUG = 1;
my $pass = 1;
my $hnd = 0;
$function = new Win32::API::More($test_dll, 'BOOL __stdcall GetHandle(LPHANDLE pHandle)');

$pass = $pass && defined($function);
$result = $function->Call($hnd);
$pass = $pass && $result == 1;
$pass = $pass && $hnd == 4000;
ok($pass, 'GetHandle operates correctly');
$pass = 1;
$function = new Win32::API::More($test_dll, 'BOOL __stdcall FreeHandle(HANDLE Handle)');
$pass = $pass && defined($function);
$pass = $pass && $function->Call($hnd) == 1;
ok($pass, 'FreeHandle operates correctly');
}

# test return value is unsigned for unsigned proto
$function = new Win32::API::More($test_dll, 'ULONG __stdcall highbit_unsigned()');
ok(defined($function), 'highbit_unsigned() function defined');

is($function->Call(), 0x80005000, 'return value for unsigned is unsigned');

# test return value is unsigned for unsigned proto, 2 word type
$function = new Win32::API::More($test_dll, 'unsigned long __stdcall highbit_unsigned()');
ok(defined($function), '2 word ret type highbit_unsigned() function defined');

is($function->Call(), 0x80005000, 'return value for unsigned is unsigned');

#test shorts on new api
$function = new Win32::API::More($test_dll, 'short  __stdcall sum_shorts_ref(short a, short b, short* c)');
ok(defined($function), 'sum_shorts_ref() function defined');

#diag("$function->{procname} \$^E=", $^E);
$result = 0;
is($function->Call(2, 3, $result), -32768, 'sum_shorts_ref() returns the expected value');
is($result, 5, 'sum_shorts_ref() correctly modifies its ref argument');

#type pun to unsigned short, and "short* c" to "short *c" ("*c" is bug check)
$function = new Win32::API::More($test_dll, 'USHORT  __stdcall sum_shorts_ref(short a, short b, signed short *c)');

#diag("$function->{procname} \$^E=", $^E);
$result = 0;
is($function->Call(2, 3, $result), 32768, 'sum_shorts_ref() returns the expected unsigned value');
is($result, 5, 'sum_shorts_ref() correctly modifies its ref argument');

#test chars, "char*c" and "2" are not mistakes
$function = new Win32::API::More($test_dll, 'char __stdcall sum_char_ref(unsigned char a, unsigned char b, unsigned char*c)');

$result = '0';
is($function->Call("2", "3", $result), pack('c', -128), 'sum_char_ref() returns the expected character value');
is($result, 5, 'sum_char_ref() correctly modifies its ref argument');

#test zero/sign extend logic
$function = new Win32::API::More($test_dll, 'int __stdcall sum_uchar_ret_int(UCHAR a, UCHAR b)');
is($function->Call("\xFD", "\x32"), 303, 'sum_uchar_ret_int() returns the expected numeric value');

#test signed chars
$function = new Win32::API::More($test_dll, 'signed char __stdcall sum_char_ref(signed char a, signed char b, signed char*c)');

$result = '0';
is($function->Call("-3", "-2", $result), -128, 'signed sum_char_ref() returns the expected numeric value');
is($result, -5, 'sum_char_ref() correctly modifies its ref argument');

#unsigned numeric ret, and unsigned char *
$function = new Win32::API::More($test_dll, 'unsigned char __stdcall sum_char_ref(char a, char b, char*c)');

$result = '0';
is($function->Call("\x03", "\x02", $result), unpack('C', pack('c', -128)), 'unsigned sum_char_ref() returns the expected numeric value');
is($result, "\x05", 'sum_char_ref() correctly modifies its ref argument');


$function = new Win32::API::More($test_dll, 'BOOL __stdcall str_cmp(char *string)');
is($function->Call("Just another perl hacker"), 1, 'str_cmp() returns the expected value');



$function = new Win32::API::More($test_dll, 'BOOL __stdcall wstr_cmp(LPWSTR string)');
is($function->Call(Encode::encode("UTF-16LE","Just another perl hacker"))
   , 1, 'wstr_cmp() returns the expected value');
{
$function = new Win32::API::More($test_dll, 'HANDLE __stdcall GetGetHandle()');
my $funcptr = $function->Call();
#if $function goes out of scope, test dll is unloaded and $funcptr will crash
my $function2 = new Win32::API::More(undef, $funcptr, 'BOOL __stdcall GetHandle(LPHANDLE pHandle)');
my $pass = 1;
my $hnd = 0;
$pass = $pass && defined($function2);
$result = $function2->Call($hnd);
$pass = $pass && $result == 1;
$pass = $pass && $hnd == 4000;
ok($pass, 'GetHandle from func pointer using C prototype operates correctly');

$function2 = new Win32::API::More(undef, $funcptr, 'GetHandle', 'P', 'I');
$hnd = pack(PTR_LET(), 0);
$pass = 1;
$pass = $pass && defined($function2);
$result = $function2->Call($hnd);
$pass = $pass && $result == 1;
$pass = $pass && unpack(PTR_LET(), $hnd) == 4000;
ok($pass, 'GetHandle from func pointer using letter interface operates correctly');

$function2 = new Win32::API::More(undef, 2, 'GetHandle', 'P', 'I');
#$^E is not really implemented on Cygwin
my $err = $cygwin ? Win32::GetLastError() : $^E+0;
eval {
    $result = $function2->Call($hnd);
};#ERROR_NOACCESS
ok($@ && ! defined $function2 && $err == 998, 'Can\'t create a Win32::API obj to func ptr 2');

}

#Find a char in a string, proper unpacking of return type pointers isn't done
$function = new Win32::API::More($test_dll, 'char * find_char(char* string, signed char ch)');
ok(defined($function), 'find_char() function defined');

#diag("$function->{procname} \$^E=", $^E);
my $string = "\x01\x02\x03\x04";
my $char   = 3;
is($function->Call($string, $char), "\x03\x04", 'numeric return find_char() function call works');


#here we are testing moving a scalar's contents to a foreign
#memory allocator and getting is back from a foreign memory block
#back into a scalar
$input = "Just another perl hacker\x00";
$function = new Win32::API::More( 'kernel32.dll' ,
    'UINT_PTR HeapAlloc(HANDLE hHeap, DWORD dwFlags, SIZE_T dwBytes)');
$function2 = new Win32::API::More( 'kernel32.dll' , 'HANDLE  GetProcessHeap()');
$ptr = $function->Call($function2->Call(), 0, length($input));
MoveMemory($ptr, unpack(PTR_LET(), pack('p', $input)), length($input));

$result = ReadMemory($ptr, length($input));
is($result,$input,'MoveMemory() and ReadMemory() work');

WriteMemory($ptr, "\x00" x length($input), length($input));
$result = ReadMemory($ptr, length($input));
is($result,"\x00" x length($input),'WriteMemory() works');

eval {WriteMemory($ptr, "\x00" x length($input), length($input)+1);};
ok(index($@, '$length > length($source)') != -1, "WriteMemory() length check works");

$function = new Win32::API::More( 'kernel32.dll' ,
    'BOOL HeapFree( HANDLE hHeap, DWORD dwFlags, UINT_PTR lpMem)'
);

ok($function->Call($function2->Call(), 0, $ptr), "HeapFree works");
ok(IsBadReadPtr(1, 4), "1 is a bad pointer for IsBadReadPtr");
ok(!IsBadReadPtr(unpack(PTR_LET(),pack('p', $input)), length($input)),
   "IsBadReadPtr returned false on a good pointer");

diag('"bad prototype" warning is intentional');
$function2 = new Win32::API::More( 'kernel32.dll' , 'HANDLE  GetProcessHeap( void ** ptr )');
is($function2, undef, "** types do not parse currently");
