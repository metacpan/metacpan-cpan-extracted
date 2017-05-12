#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03driver.t'
#
# 03driver.t - test harness for module Tk::DBI::LoginDialog
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#########################
use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl qw/ :easy /;
use Tk;
use Test::More;

# ---- test harness ----
use lib 't';
use tester;

my $ot = tester->new;
#$ot->tests(18);
my $tests = 18;  # we dynamically increment as number of DBI drivers unknown


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $top = $ot->top;


# ---- module ----
my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);


# ---- create ----
my $ld0 = $top->LoginDialog;
my $ld1 = $top->LoginDialog;

isa_ok($ld0, $c_this, "new object 0");
isa_ok($ld1, $c_this, "new object 1");


# ---- override driver ----
my $default = $ld0->driver;
my $invalid = "_invalid_";

$ld0->_error("condition: $invalid");	# just to show us what is happening

isnt($default, "",			"default driver");
isnt($ld0->driver($invalid), $invalid,	"prevent invalid override");
is($ld0->driver, $default,		"driver still valid");

#$log->debug(sprintf "default drivers [%s]", Dumper($ld0->drivers));

# ---- override drivers ----
my @drivers = qw/ Oracle ODBC CSV DB2 /;

is_deeply($ld0->drivers(@drivers), [@drivers], "configure drivers");

$ot->queue_button($ld0, "Cancel");

for my $driver (@drivers) {

	is($ld0->driver($driver), $driver,	"driver override $driver");

	$ld0->_error("condition: DSN $driver");

	$ot->queue_button($ld0, "Cancel");

	isnt($ld0->driver, "",			"driver set after $driver");

	$tests += 2;
}


# ---- constrain drivers ----
my $drivers = $ld1->drivers;
my $count = @$drivers;
my $driver = $ld1->driver;
my $removed;

ok($count > 0,			"drivers are available");

$removed = shift @{ $ld1->drivers };
$ld1->_error("condition: removed $removed");
isnt($removed, "",			"remove driver non-null");
isnt($removed, $ld1->driver,		"remove a driver");
isnt($driver, $ld1->driver,		"check removed");
ok(@{ $ld1->drivers } == $count - 1,	"one less driver available");
$ot->queue_button($ld1, "Cancel");

$removed = pop @{ $ld1->drivers };
$ld1->_error("condition: removed $removed");
isnt($removed, "",			"remove another driver non-null");
isnt($removed, $ld1->driver,		"remove another driver");
isnt($driver, $ld1->driver,		"check another removed");
ok(@{ $ld1->drivers } == $count - 2,	"have removed again");
isnt($ld1->driver, $driver,		"revised default");

$ot->queue_button($ld1, "Cancel");

my $max = @{ $ld1->drivers };
for (my $i = 0; $i < $max; $i++) {

	$removed = pop @{ $ld1->drivers };
	$ld1->_error("condition: removing $removed");
	ok(@{ $ld1->drivers } > 0,	"removing $removed");
	$ot->queue_button($ld1, "Cancel");

	$tests++;
}

ok(@{ $ld1->drivers } == $count,	"restored default drivers");

$ot->queue_button($ld1, "Cancel");

done_testing($tests + $ot->count);

