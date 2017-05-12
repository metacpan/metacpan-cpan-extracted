#!/usr/bin/perl -w
use strict;
use warnings;

BEGIN { eval{ require threads}; push(@INC, '..') }
use Win32::API::Callback;
use W32ATest;
use Test::More;
use Config;

if($^O eq 'cygwin'){
    plan skip_all => 'Win32::API::Callback on Cygwin crashes during a fork';
}
else {
    plan tests => 2;
}


# This test was originally useless without the Windows debugging heap, by
# raising the alloc size to 50 MB, a call to the paging system is forced
# a double free will get access violation rather THAN no symptoms failure mode of
# VirtualAlloced but freed Heap memory

SKIP: {
    skip("This Perl doesn't have fork", 2) if ! Win32::API::Test::can_fork();
#a HeapAlloc block is not copied to a Cygwin Child Proc's address space
#POSIX has no executable privilage enabled equivelent of malloc. HeapAlloc
#has an exectuable option. Using Cygwin's mprotect on a Cygwin malloc
#pointer seems too crude, since bytes from other blocks that aren't machine
#code will be made executable in the same page as the ::Callback function


    # HeapBlock class is not public API

    # 50 megs should be enough to force a VirtualAlloc and a VirtualFree
    my $ptrobj = new Win32::API::Callback::HeapBlock 5000000;
    my $pid = fork();
    if ($pid) {
        diag("in parent\n");
        { #block to force destruction on scope leave
            undef($ptrobj);
        }
        ok(1, "didn't crash parent");
        waitpid $pid, 0;
    }
    else {
        diag("in child\n");
        { #block to force destruction on scope leave
            undef($ptrobj);
        }
        ok(1, "didn't crash child");
    }
}
