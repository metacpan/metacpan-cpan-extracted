#! /usr/bin/perl -w


use strict;
print "1..4\n";
use  W3C::LogValidator::SurveyEngine;
print "ok 1\n";

my %config = ("verbose" => 3);
my $validator = W3C::LogValidator::SurveyEngine->new(\%config);
print "ok 2\n";


$validator->uris('http://www.w3.org/Overview.html', 'http://yoda.zoy.org/');
print "ok 3\n";

my %result= $validator->process_list;
if (not %result) {print "not"}
print "ok 4\n";
