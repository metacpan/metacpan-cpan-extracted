#!/bin/perl
# 
#  Compare generated files with frozen reference files
#
use strict qw(vars);
use warnings;
use Test::More tests=>1;
use Capture::Tiny qw(capture);


#  Setup ENV vars for using different meta file
#
$ENV{'WEBDYNE_CONF'}='t/webdyne_meta.conf.pl';
$ENV{'WEBDYNE_TEST_FILE_PREFIX'}='03';


#  And run on the meta file
#
my $ret;
capture { $ret=system($^X, 't/02-render.t', 't/meta.psp') };
ok($ret==0);
