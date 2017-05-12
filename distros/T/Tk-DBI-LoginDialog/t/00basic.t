#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00basic.t'
#
# 00basic.t - test harness for module Tk::DBI::LoginDialog
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
use Tk;
use Log::Log4perl qw/ :easy /;
use Test::More;

# ---- test harness ----
use lib 't';
use tester;

my $ot = tester->new;
$ot->tests(18);

# ---- module ----
my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $s_ok = "onnected";
my ($dbh, $msg);


# ---- create ----
my $ld = $ot->top->LoginDialog;
isa_ok($ld, $c_this,		"new");


# ---- cancel ----
$ot->queue_button($ld, "Cancel");
ok(defined($ld->dbh) == 0,	"null dbh");

# ---- exit ----
$ot->dummy_exit($ld);
$ot->queue_button($ld, "Exit");


# ---- disconnection invalid ----
$msg = $ld->disconnect;
like($msg, qr/no database/,	"disconnect premature");


# ---- login ----
$ld->driver("ExampleP");
$ot->queue_button($ld, "Login");


# ---- connection ----
my $driver = $ld->driver;
isnt("", $driver,		"driver initialisation");
#($dbh, $msg) = $ld->connect();
($dbh, $msg) = $ld->connect($driver, "", "", "");
ok(defined($dbh),		"connect default handle");
like($msg, qr/$s_ok/,		"connect default message");


# ---- disconnection valid ----
$msg = $ld->disconnect;
like($msg, qr/$s_ok/,		"disconnect after connect");


$ot->queue_button($ld, "Login");
like($ld->error, qr/$s_ok/,	"login okay");


# ---- clean-up ----
$ld->destroy;
ok(Tk::Exists($ld) == 0,	"destroy");

