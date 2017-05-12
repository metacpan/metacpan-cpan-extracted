#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04version.t'
#
# 04version.t - test harness for module Tk::DBI::LoginDialog
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
$ot->tests(20);


# ---- module ----
my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $top = $ot->top;


# ---- create ----
my $ld = $top->LoginDialog;

isa_ok($ld, $c_this, "new object");


# ---- show version ----
my $default = $ld->version;
isnt($default, "",		"retrieve version string");
$ot->queue_button($ld, "Cancel");

is($ld->version(1), $default,	"render version");
$ot->queue_button($ld, "Cancel");

is($ld->version, $default,	"hide version");
$ot->queue_button($ld, "Cancel");

is($ld->version, $default,	"hide-again version");
$ot->queue_button($ld, "Cancel");

is($ld->version(1), $default,	"re-render version");
$ot->queue_button($ld, "Cancel");

is($ld->version(0), $default,	"re-hide version");
$ot->queue_button($ld, "Cancel");

