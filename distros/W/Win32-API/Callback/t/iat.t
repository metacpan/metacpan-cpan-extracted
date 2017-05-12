#!/usr/bin/perl -w
use strict;
use Config;
use Test::More;
if($^O eq 'cygwin'){plan skip_all => 'Cygwin allocates >0x80000000 memory';}
else{plan tests => 27;}
use vars qw(
    $function
    $function2
    $result
    $callback
    $patch
    $test_dll
    $arg
    $arg2
    $module
    $ptrsize
);
BEGIN {
    eval "sub PTR_SIZE () { ".$Config{ptrsize}." }";
    push(@INC, '..'); #for W32ATest
}
use Win32::API ('WriteMemory', 'ReadMemory', 'IsBadReadPtr');
use Win32::API::Callback;
use W32ATest;
use Win32;


ok(1, 'loaded');

$test_dll = Win32::API::Test::find_test_dll();
ok(-e $test_dll, 'found API_Test.dll');

sub NT_SUCCESS ($) {return $_[0] >= 0 ? !0: !1;}

$ptrsize = PTR_SIZE;
#We set up a fake QueryPerformanceCounter implemented in Perl
my $i = 0;
$callback = Win32::API::Callback->new(
    sub {
        my($low, $hi) = unpack('LL', unpack('P8', pack(IV_LET , $_[0])));
        $hi = 0;
        $low = $i;
        $i++;
        my $PackedLongInteger = pack('LL', $low, $hi);
        WriteMemory($_[0], $PackedLongInteger, 8);
        return 1;
    },
    'N',
    'I'
);

$function = new Win32::API($test_dll, 'MyQueryPerformanceCounter', 'P', 'I');

ok(defined ($patch = Win32::API::Callback::IATPatch
    ->new($callback, $test_dll, 'kernel32.dll', 'QueryPerformanceCounter'))
   ,"Patch obj created");

$arg = "\xFF" x 8;
is($function->Call($arg), 1, "MyQueryPerformanceCounter in test dll returns success");
is($arg, "\x00\x00\x00\x00\x00\x00\x00\x00", "Patch 1st call worked");
$function->Call($arg);
is($arg, "\x01\x00\x00\x00\x00\x00\x00\x00", "Patch 2nd call worked");
$function->Call($arg);
is($arg, "\x02\x00\x00\x00\x00\x00\x00\x00", "Patch 3rd call worked");
ok($patch->Unpatch(), "Unpatch meth return success");
#ERROR_NO_MORE_ITEMS == 259
ok(! defined($patch->Unpatch()) && $^E == 259, "can not Unpatch twice");
$function->Call($arg);
#use Data::Dumper;
#print Dumper($arg);
unlike($arg, qr/\x00\x00\x00\x00\x00\x00\x00/, "using real QPC now check 1");
$arg2 = "\xFF" x 8;
$function->Call($arg2);
#comparing only 32 bits of i64, revisit XXX
ok(unpack('L', $arg2) != unpack('L', $arg)+1, "using real QPC now check 2");

$function2 = new Win32::API($test_dll, 'GetTestDllHModule', 'V', 'N');
$module = $function2->Call();
ok($module && !IsBadReadPtr($module, 8), "Test DLL's HMODULE can't be NULL");

$patch = Win32::API::Callback::IATPatch
    ->new($callback, $module, 'kernel32.dll', 'QueryPerformanceCounter');
$function->Call($arg);
is($arg, "\x03\x00\x00\x00\x00\x00\x00\x00", "Patch 4th call worked");
is($patch->GetOriginalFunctionPtr(),
   Win32::GetProcAddress(Win32::LoadLibrary("kernel32.dll"), 'QueryPerformanceCounter'),
   "GetOriginalFunctionPtr returns real QPC");

SKIP: {
    Win32::API::Type->typedef('PRTL_PROCESS_MODULES', 'char *');

    my $LdrQueryProcessModuleInformation =
    Win32::API::More->new("ntdll.dll",
    "NTSTATUS NTAPI  LdrQueryProcessModuleInformation(".
    "PRTL_PROCESS_MODULES ModuleInformation,
    ULONG Size, PULONG ReturnedSize)");

    skip("This Perl doesn't have fork and/or this Windows OS "
        . " doesn't have LdrQueryProcessModuleInformation", 6)
        if ! Win32::API::Test::can_fork()
        || ! $LdrQueryProcessModuleInformation; #Native API changed, thats ok

    is(GetAPITestDLLLoadCount($LdrQueryProcessModuleInformation), 1,
       "DLL load count is 1 before fork");
    my ($child, $parent);
    #pipe is to keep child proc alive for the dll count check
    pipe($child, $parent) or die;
    my $old = select( $parent );
    $|++;
    select($old);

    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        #print "child waiting\n";
        getc($child);
        #print "child exiting\n";        
        exit(0);
    }
    is(GetAPITestDLLLoadCount($LdrQueryProcessModuleInformation), 2,
       "DLL load count is 2 while 2 procs of fork are live");
    print $parent "exit now\n";
    waitpid($pid, 0);
    is(GetAPITestDLLLoadCount($LdrQueryProcessModuleInformation), 1,
       "DLL load count is 1 after child exits");
    $pid = fork();
    if($pid) {
        #check to make sure DLL was not unloaded from process
        ok(!IsBadReadPtr($module, 8), "APItest dll is still here");
        ok($patch->GetOriginalFunctionPtr(), "Patch obj works in parent fork");
        waitpid($pid, 0);
        ok($?  >> 8 == 9, "Patch obj does not work in child fork");
    }
    else{
        eval {
            $patch->GetOriginalFunctionPtr();
        };
        exit(9)if $@; #9 is a randomly picked number
        exit(0);
    }
}

ok($patch->Unpatch(0), "never Unpatch meth return success");
$function->Call($arg);
is($arg, "\x04\x00\x00\x00\x00\x00\x00\x00", "Patch 5th call worked");
is($patch->GetOriginalFunctionPtr(), 0, "Unpatched IATPatch looses OrigFunc after an Unpatch");

#note that MZ and PE signature bytes are here
my $BrokenModule = "MZ\220\0\3\0\0\0\4\0\0\0\377\377\0\0\270\0\0\0\0\0\0\0\@\0\0\0\0\0\0\0\
0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\350\0\0\0\16\37\272\16\0
\264\t\315!\270\1L\315!This program cannot be run in DOS mode.\r\r\n\$\0\0\0\0\0
\0\0000\2\1\355tco\276tco\276tco\276\372t`\276`co\276\372t0\276\37co\276\367k2\2
76wco\276tcn\276 co\276\372t\17\276}co\276\372t3\276uco\276\372t5\276uco\276Rich
tco\276\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0PE\0\0L\1\6\0\223\0028P\0
\0\0\0\0\0\0\0\340\0\16!";

undef($patch); #done let old IATPatch change the GLR for the next call, DESTROY happens
#after the obj was assigned to but before next line
$patch = Win32::API::Callback::IATPatch ->new($callback,
    unpack(PTR_LET, pack('P', $BrokenModule)), 'kernel32.dll', 'QueryPerformanceCounter');
ok($^E == 193 && ! defined $patch , "IATPatch claims corrupt DLL is corrupt ".($^E+0));
#193 = ERROR_BAD_EXE_FORMAT
$patch = Win32::API::Callback::IATPatch ->new($callback,
    $module, 'jugjsadflasjd.dll', 'DoesntExist');
#126 = ERROR_MOD_NOT_FOUND
ok(! defined $patch && $^E == 126, "DLL name of Import to patch not found is not found");
$patch = Win32::API::Callback::IATPatch ->new($callback,
    $module, 'kernel32.dll', 'DoesntExist823ia4hjk23');
#127 = ERROR_PROC_NOT_FOUND
ok(! defined $patch && $^E == 127, "Function name of Import to patch not found is not found");
$patch = Win32::API::Callback::IATPatch ->new($callback,
    $module, 'kernel32.dll', 1);
#182 = ERROR_INVALID_ORDINAL
ok(! defined $patch && $^E == 182, "ordinal of Import to patch not found is not found");



#$loadcount = GetAPITestDLLLoadCount($Win32_api_obj_set_to_use_LdrQueryProcessModuleInformation)
sub GetAPITestDLLLoadCount{
    my ($arg2, $arg, $result) = (0);
    my $LdrQueryProcessModuleInformation = shift;
    $result = 
    $LdrQueryProcessModuleInformation->Call($arg, 0, $arg2);
    die "LdrQueryProcessModuleInformation failed ".sprintf("%x", $result)
        if unpack('L', pack('l', $result)) != 0xC0000004;
    die "LdrQueryProcessModuleInformation failed len is 0 "
        if $arg2 == 0;
    #print "LdrQueryProcessModuleInformation wants $arg2 bytes\n";
    $arg = "\x00"; #must be null filled MS has some bugs in LdrQueryProcessModuleInformation
    #I tried "\xFF", InitOrderIndex changed/screw up
    #technically InitOrderIndex is ++ed in a loop without ever being initialized to zero
    #also LoadOrderIndex, Section, MappedBase are never filled/touched in WinXP 32 bit
    #Ask MS on that one
    $arg x= $arg2;
    $result = $LdrQueryProcessModuleInformation->Call($arg, length($arg), $arg2);
    die "LdrQueryProcessModuleInformation failed ".sprintf("%x", $result)
        if ! NT_SUCCESS($result);
    #remember about 8 byte member alignment on x64, alot of ULONGs in RTL_PROCESS_MODULES
    #and in RTL_PROCESS_MODULE_INFORMATION
    my($count, $modinfoarr) = unpack('Lx!['.PTR_SIZE.']a*', $arg);
    @{($modinfoarr = [])} = unpack('(a[Lx!['.PTR_SIZE.']'.PTR_LET.PTR_LET."LLSSSSZ[256]])[$count]",$modinfoarr);
    my $procmodinfo = [];
    for(@{$modinfoarr}){
        my %procmod;
        ($procmod{Section},         $procmod{MappedBase},   $procmod{ImageBase},
        $procmod{ImageSize},        $procmod{Flags},        $procmod{LoadOrderIndex},
        $procmod{InitOrderIndex},   $procmod{LoadCount},    $procmod{OffsetToFileName},
        $procmod{FullPathName}) = unpack('Lx!['.PTR_SIZE.']'.PTR_LET.PTR_LET.'LLSSSSZ[256]', $_);
        $_ = \%procmod;
    }
    for(@{$modinfoarr}){
        if($_->{FullPathName} =~ /API_test/){
            return $_->{LoadCount};
        }
    }
}
