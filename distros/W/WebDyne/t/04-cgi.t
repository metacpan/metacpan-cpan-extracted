#!/bin/perl
# 
#  Compare generated files with frozen reference files
#
use strict qw(vars);
use warnings;
use Test::More tests=>1;
use Capture::Tiny qw(capture);


#  Setup ENV vars for simulating form submission
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'}='04';
$ENV{'QUERY_STRING'}='name=Andrew&words=moe&color=blue';
$ENV{'REQUEST_METHOD'}='GET';


#  And run on the cgi file
#
my $ret;
capture { $ret=system($^X, 't/02-render.t', 't/cgi.psp') };
ok($ret==0);
