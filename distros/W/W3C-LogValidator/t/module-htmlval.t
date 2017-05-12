#! /usr/bin/perl -w


use strict;
print "1..4\n";
use  W3C::LogValidator::HTMLValidator;
print "ok 1\n";

my %config = ("verbose" => 2);
my $validator = W3C::LogValidator::HTMLValidator->new(\%config);
print "ok 2\n";


$validator->uris('http://www.w3.org/Overview.html', 'http://www.yahoo.com/index.html');
print "ok 3\n";

my %result= $validator->process_list;
if (not %result) {print "not"}
print "ok 4\n";
