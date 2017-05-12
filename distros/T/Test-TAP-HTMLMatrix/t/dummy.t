#!/usr/bin/perl

my @cases = (1 .. 15);

print "1.." . scalar @cases . "\n";

for (@cases) {
	print "not " if $ENV{TEST_FAIL_RANDOMLY} && rand > .7;
	print "ok $_ - dummy case\n";
}

