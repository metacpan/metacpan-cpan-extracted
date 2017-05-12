#!perl -w
#
# RT #74578, http://rt.cpan.org/Ticket/Display.html?id=74578
# Struct packing/unpacking test case
#

use strict;
use warnings;
use Test::More;

# BEGIN {
#     $Win32::API::DEBUG = 1;
# }

plan tests => 3;


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

my $pe32 = Win32::API::Struct->new('PROCESSENTRY32');
ok($pe32, 'ProcessEntry32 struct defined');

my $size = $pe32->sizeof;
is($size, 296, 'Size is calculated correctly');

my @pack = $pe32->getPack();
diag("\@pack=(".join(', ', @pack).")");

# TODO
# complete the test with something that makes sense

#fail("Test is incomplete");

