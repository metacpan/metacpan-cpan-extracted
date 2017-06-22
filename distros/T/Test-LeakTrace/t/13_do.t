#!perl -w
# related to https://rt.cpan.org/Public/Bug/Display.html?id=58133
use strict;
use Test::More tests => 1;

use Test::LeakTrace;

sub foo{
	do './t/lib/foo.pl';
}


no_leaks_ok \&foo, 'do $file';
