#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Win32::API;
use Win32::API::Callback;

use Config;
if($Config{useithreads}) {
    plan tests => 1;
} else {
    plan skip_all => 'no threading on this perl';
}

my $function = new Win32::API('kernel32' , ' HANDLE  CreateThread(
  UINT_PTR lpThreadAttributes,
  SIZE_T dwStackSize,
  UINT_PTR lpStartAddress,
  UINT_PTR lpParameter,
  DWORD dwCreationFlags,
  UINT_PTR lpThreadId
)');

sub cb {
    die "unreachable";
}
my $callback = Win32::API::Callback->new(\&cb, "L", "N");

diag("This might crash");

#$callback->{'code'}, no other way to do it ATM, even though not "public"
my $hnd = $function->Call(0, 0, $callback->{'code'}, 0, 0, 0);
sleep 1; #try to stop a CPANTesters fail report 596da136-6c02-1014-8ad3-3babd0345282
#which looks like a crash, if global destruction in Perl happen, the function
#stub might be freed before the thread runs, so add sleep
ok($hnd, "CreateThread worked");

#this test is badly designed, it doesn't check whether the error message
#reached the console i'm not sure whats the safest way to monitor CRT's stderr

