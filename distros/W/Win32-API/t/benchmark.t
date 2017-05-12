#!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

use Test::More;
use Math::Int64 ('uint64', 'uint64_to_number');
use W32ATest;
use Config;

plan tests => 7;
use vars qw($function $result $return $test_dll );


#use B::Concise;
use_ok('Win32::API');

$test_dll = Win32::API::Test::find_test_dll();
diag('API test dll found at (' . $test_dll . ')');
ok(-e $test_dll, 'found API test dll');

if(*Win32::API::_ResetTimes{CODE}) {
    if($Config{ptrsize} == 4) {
    my $GCP = new Win32::API('kernel32.dll', 'GetCurrentProcess', '', 'N');
    my $prochand = $GCP->Call();
    my $GPAM = new Win32::API::More('kernel32.dll', 'BOOL WINAPI GetProcessAffinityMask('
                   .'HANDLE hProcess, PHANDLE lpProcessAffinityMask, '
                   .'PHANDLE lpSystemAffinityMask);');
    die 'API obj for GetProcessAffinityMask failed' if !$GPAM;
    my ($ProcessAffinityMask, $SystemAffinityMask) = (0,0);
    die 'GetProcessAffinityMask failed' if !$GPAM->Call($prochand, $ProcessAffinityMask, $SystemAffinityMask);
    my $bitsinptr =  length(pack(PTR_LET(),0))*8;
    #low cpus on left side in string
    my $availcpus = unpack('b'.$bitsinptr, pack(PTR_LET, $SystemAffinityMask));
    my $highestCPU = index($availcpus, '0');
    die 'can\'t find highest CPU' if $highestCPU < 1;
    my $mask = 2**($highestCPU-1);
    diag("highest CPU mask is $mask\n");
    my $SPAM = new Win32::API('kernel32.dll',
    'BOOL WINAPI SetProcessAffinityMask(HANDLE hProcess, DWORD_PTR dwProcessAffinityMask);');
    die 'API obj for SetProcessAffinityMask failed '.($^E+0) if !$SPAM;
    die 'SPAM failed' if !$SPAM->Call($prochand, $mask);
    }
    Win32::API::_ResetTimes();
}

sub benchmark {
my $c_slr_loop= new Win32::API($test_dll, 'char * setlasterror_loop(int interations)');
ok(defined($c_slr_loop), 'setlasterror_loop() function defined');

my $QPC = Win32::API::More->new('kernel32.dll', "BOOL WINAPI QueryPerformanceCounter(
                        UINT64 * lpPerformanceCount );");
ok($QPC, "QueryPerformanceCounter Win32::API obj created");
$QPC->UseMI64(1) if IV_SIZE == 4;
my $freq;
$freq = uint64(0);
my $QPF = Win32::API::More->new('kernel32.dll', "BOOL WINAPI QueryPerformanceFrequency(
                            UINT64 *lpFrequency);");
$QPF->UseMI64(1) if IV_SIZE == 4;
ok($QPF->Call($freq), "QueryPerformanceFrequency Win32::API obj created and call success");

#note that we capture the garbage return value for SLR, this is to simulate that most
#c funcs have a return value
my $SLR = Win32::API->new('kernel32.dll', 'BOOL WINAPI SetLastError( DWORD dwErrCode );');
my $start = uint64(0);
my $end = uint64(0);
my ($startbool, $SLRret, $endbool);
my $iterations = 1000000;
$startbool = $QPC->Call($start);
$SLRret = $SLR->Call(1) for(0..$iterations);
$endbool = $QPC->Call($end);
ok($startbool && $endbool, "QPC calls succeeded");
my $delta = (uint64_to_number($end-$start)/uint64_to_number($freq));
diag("time was $delta secs, ".(($delta/scalar(@{[0..$iterations, 1,1]}))*1000)." ms per Win32::API call");

Win32::API->Import('kernel32.dll', 'BOOL WINAPI SetLastError( DWORD dwErrCode );');
$startbool = $QPC->Call($start);
$SLRret = SetLastError(1) for(0..$iterations);
$endbool = $QPC->Call($end);
ok($startbool && $endbool, "QPC calls succeeded");
$delta = (uint64_to_number($end-$start)/uint64_to_number($freq));
diag("time was $delta secs, ".(($delta/scalar(@{[0..$iterations, 1,1]}))*1000)." ms per Win32::AP::Import style call");

my $msg = $c_slr_loop->Call($iterations);
diag($msg);

if(*Win32::API::_xxSetLastError{CODE}) {
    $startbool = $QPC->Call($start);
    $SLRret = Win32::API::_xxSetLastError(1) for(0..$iterations);
    $endbool = $QPC->Call($end);
    die "QPC calls failed" unless $startbool && $endbool;
    $delta = (uint64_to_number($end-$start)/uint64_to_number($freq));
    diag("time was $delta secs, ".(($delta/scalar(@{[0..$iterations, 1,1]}))*1000)." ms per _xxSetLastError call");    
}
}

SKIP: {
    skip('debugging is on', 5)
        if *Win32::API::IsWIN32_API_DEBUG{CODE} && Win32::API::IsWIN32_API_DEBUG();
    benchmark();
}

#my $walker = B::Concise::compile('-src','-exec', *benchmark{CODE});
#$walker->();
