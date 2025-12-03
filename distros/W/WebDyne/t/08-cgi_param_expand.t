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
$ENV{'WEBDYNE_TEST_FILE_PREFIX'}='08';
$ENV{'QUERY_STRING'}='foo%26bar%3D1%26bar%3D2=Submit&bar=3';
$ENV{'REQUEST_METHOD'}='GET';


#  And run on the cgi file
#
my $ret;
my ($stdout, $stderr)=capture { $ret=system($^X, 't/02-render.t', 't/cgi_param_expand.psp') };
#diag("ret: $ret, stdout: $stdout, stderr: $stderr");
ok($ret==0);
