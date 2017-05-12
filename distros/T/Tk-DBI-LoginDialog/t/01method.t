#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01method.t'
#
# 01method.t - test harness for module Tk::DBI::LoginDialog
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

use Log::Log4perl qw/ :easy /;
use Tk;
use Data::Dumper;
use Test::More;

# ---- test harness ----
use lib 't';
use tester;

my $ot = tester->new;
$ot->tests(35);


# ---- module ----
my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $top = $ot->top;


# ---- main ----
my $ld0 = $top->LoginDialog;

isa_ok( $ld0, $c_this, "new no parm");
is( Tk::Exists($ld0), 1,	"exists");

eval { $ld0->update; };
is($@, "", "update $c_this");

eval { $ld0->destroy; };
is($@, "", "destroy $c_this");

isnt(Tk::Exists($ld0), 1, "destroyed $c_this");

my $ld1 = $top->LoginDialog;
isa_ok( $ld1, $c_this, "new no parm");

isnt($ld1->driver, "",			"driver non-null");
isnt($ld1->driver("DUMMY"), "DUMMY",	"driver override invalid");

for my $method (qw/ password dsn username /) {

	my $condition = "method get $method";
	my $value = $ld1->$method;
	is($value, "",			$condition);

	$condition = "method set $method";
	$value = $ld1->$method("DUMMY");
	ok($value eq "DUMMY",			$condition);
}

for my $method (qw/ error /) {

	is($ld1->$method, "",		"null default $method");
	is($ld1->$method("DUMMY"), "",	"read-only null $method");
}

for my $method (qw/ version /) {

	isnt($ld1->$method, "",			"non-null default $method");
	isnt($ld1->$method("DUMMY"), "",	"read-only non-null $method");
}

for my $option (qw/ -mask -retry /) {
	my $value = $ld1->cget($option);
	isnt($value, "",	"option get $option");

	isa_ok($ld1->configure($option => "X"), "ARRAY", "option configure $option");
	$value = $ld1->cget($option);
	is($value, "X",	"option verify $option");
}


for my $widget (qw/ driver dsn username password error /) {

	my $w = $ld1->Subwidget($widget);
	ok(Exists($w) == 1,	"exists $widget");

	my $c = $w->Class;

	if ($c eq 'Entry') {
		is($w->get, "DUMMY",		"subwidget get $c $widget");
	} elsif ($c eq 'ROText') {
		like($w->Contents, qr/^\s*$/,	"subwidget get $c $widget");
	} elsif ($c eq 'BrowseEntry') {

		my $sw = $w->Subwidget('entry');
		isnt($sw->get, "DUMMY",		"subwidget get $c $widget");
	}
}

