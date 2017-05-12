#!perl -w
#
# RT #48006, http://rt.cpan.org/Ticket/Display.html?id=48006
# Simple struct size calculation and alignment test case
#
# NOTE: This test is 32-bit architecture dependent
#       What about switching to 64-bits?
#
# $Id: 03_undef.t 452 2009-01-17 16:16:08Z cosimo.streppone $

use strict;
use warnings;
use Test::More;

# BEGIN {
#     $Win32::API::DEBUG = 1;
# }

plan tests => 4;

use_ok('Win32::API');

typedef Win32::API::Struct PROCESSENTRY32 => qw(
    DWORD dwSize;
    DWORD cntUsage;
    DWORD th32ProcessID;
    DWORD th32DefaultHeapID;
    DWORD th32ModuleID;
    DWORD cntThreads;
    DWORD th32ParentProcessID;
    LONG pcPriClassBase;
    DWORD dwFlags;
    char szExeFile[260];
    );    # 9*4=36+260=296

my $pe32 = new Win32::API::Struct('PROCESSENTRY32');
ok($pe32, 'ProcessEntry32 struct defined');

my $size = $pe32->sizeof;
is($size, 296, 'Size is calculated correctly');
warn("\n\nUninit warnings are intentional\n\n");
$pe32->Pack();
is($pe32->{buffer}, "\x00" x 296, "uninitialized struct is all nulls");
diag("Size is $size. Should be 296");

