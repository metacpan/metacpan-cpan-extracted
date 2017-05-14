#!/usr/bin/perl -w

use Test::More;
if ( $^O eq 'MSWin32' ) {
  plan tests => 2;
} else {
  plan skip_all => 'Test irrelevant on anything except MSWin32';
}


use Win32::Exchange;
$test_object = Win32::Exchange->new("5.5");

ok(defined $test_object,"success creating win32 ADsNamespaces object passing class\n");

$test_object_2 = Win32::Exchange::new("5.5");

ok(defined $test_object_2,"success creating win32 ADsNamespaces object without passing class\n");
