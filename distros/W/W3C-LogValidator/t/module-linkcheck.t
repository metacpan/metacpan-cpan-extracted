#! /usr/bin/perl -w


use strict;
#print "1..4\n";
print "1..3\n";
use  W3C::LogValidator::LinkChecker;
print "ok 1\n";

my %config = ("verbose" => 2);
my $checker = W3C::LogValidator::LinkChecker->new(\%config);
print "ok 2\n";


$checker->uris('http://www.w3.org/People/olivier/stuff/test-link.html');
print "ok 3\n";

#my %result= $checker->process_list;
#if (not %result) {print "not"}
#print "ok 4\n";
