#!/bin/perl
# 
#  Check constants loaded properly
#
use strict qw(vars);
use warnings;
use vars   qw($VERSION);


#  Load local test version of constant file with updated dump flag
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='t/webdyne_constant.conf.pl';
}


#  Test modules we need
#
use Test::More qw(no_plan);


#  Now load WebDyne module
#
use WebDyne;
use WebDyne::Constant;
ok($WEBDYNE_DUMP_FLAG == 1);
ok($WebDyne::WEBDYNE_DUMP_FLAG == 1);
ok(WEBDYNE_DUMP_FLAG == 1);
ok(&WebDyne::WEBDYNE_DUMP_FLAG == 1);
ok($WebDyne::Constant::Constant{'WEBDYNE_DUMP_FLAG'} == 1);


#  Manual vary, only change variable
#
$WEBDYNE_DUMP_FLAG=2;
$WebDyne::WEBDYNE_DUMP_FLAG=2;
ok($WEBDYNE_DUMP_FLAG == 2);
ok($WebDyne::WEBDYNE_DUMP_FLAG == 2);


#  Expected subroutines will stay at value 1 + haven't changed 
#  constants hash ref so that stays same also
#
ok(WEBDYNE_DUMP_FLAG == 1);
ok(&WebDyne::WEBDYNE_DUMP_FLAG == 1);
ok($WebDyne::Constant::Constant{'WEBDYNE_DUMP_FLAG'} == 1);


# Load test config file
#
WebDyne::Constant->import('t/webdyne_constant_import.conf.pl');
ok($WebDyne::Constant::Constant{'WEBDYNE_DUMP_FLAG'} == 3);
ok($WEBDYNE_DUMP_FLAG == 3);
ok($WebDyne::WEBDYNE_DUMP_FLAG == 3);


#  Expect constrant folded WEBDYNE_DUMP_FLAG not to changed, but 
#  subroutine evaluated one should
#
ok(WEBDYNE_DUMP_FLAG==1);
ok(&WEBDYNE_DUMP_FLAG == 3);

