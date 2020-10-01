#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02sub.t'
#
# 02sub.t - test harness for module Tk::DBI::LoginDialog
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

my $ot = tester->new('Tk::DBI::LoginDialog');
$ot->planned(308);


# ---- module ----
require_ok($ot->this);


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $top = $ot->top;


# ---- create ----
my %field = (dsn => "val_0", username => "val_1", password => "val_2");
my $ld0 = $top->LoginDialog(%field);
isa_ok($ld0, $ot->this, "new with parms");


# ---- destroy some subwidgets ----
$ot->queue_button($ld0, "Cancel");

for (keys %field, "error") {

	my $w = $ld0->Subwidget($_);

	$w->destroy;

	ok(Tk::Exists($w) == 0,	"destroy subwidget $_");

	$ld0->update;
}

my $ld1 = $top->LoginDialog;
isa_ok($ld1, $ot->this, "new no parms");


# ---- test properties of dialog ----
my %prop = (
  -title => 'foobar',
  -foreground => 'red',
  -background => 'blue',
);

while (my ($property, $value) = each %prop) {
	my $old_value = $ld1->cget($property);
	isnt($old_value, "",	"property $property default non-null");

	$ld1->configure($property => $value);
	isnt($ld1->cget($property), $old_value,	"property $property override");

	$prop{$property} = $old_value;
}
$ot->queue_button($ld1, "Cancel");

while (my ($property, $old_value) = each %prop) {

	$ld1->configure($property => $old_value);
	is($ld1->cget($property), $old_value,	"property $property reset");
}


# ---- test common properties of appropriate subwidgets ----
my %common;	# maintain a count of common properties
my $c_widget = 0;
my @subwidgets;

for my $w ($ld1->Subwidget) {

	next if ($w->class =~ /Frame|LoginDialog/);

	$c_widget++;
	my $properties = "";

	map {
		$properties .= sprintf "%s ", $_->[0];

		if (exists($common{$_->[0]})) {
			$common{$_->[0]}++;
		} else {
			$common{$_->[0]} = 1;
		}
	} $w->configure;

#	$log->debug(sprintf "subwidget [%s] class [%s] properties [%s]",
#		$w->name, $w->class, $properties);

	push @subwidgets, $w;
}

while (my ($property, $count) = each %common) {

	delete $common{$property} unless ($count == $c_widget);
	delete $common{$property} if ($property =~ /\-(takefocus|cursor|fg|bg)/);
}

#$log->debug(sprintf "c_widget [$c_widget] common [%s]", Dumper(\%common));

my %substitute = (
	'^[bB]lack$' => 'white',
	'^\d$' => '4',
	'^\d\d$' => '40',
	'^\#d9d9d9$' => 'red',
	'^[wW]hite$' => 'blue',
	'^raised$' => 'sunken',
	'^sunken$' => 'ridge',
);

for my $w (@subwidgets) {

	my $name = $w->name;

	while (my ($property, $value) = each %common) {
		my $value = $w->cget($property);
		$common{$property} = $value;

		isnt($value, "",	"widget $name property $property default non-null");

#		$log->debug("property [$property] value [$value]");
		while (my ($re, $swap) = each %substitute) {
			if ($value =~ /$re/) {
				$value = $swap;
#				$log->debug("swap [$swap]");
				last;
			}
		}
		
		$w->configure($property => $value);
		is($w->cget($property), $value,	"widget $name property $property apply");

	}
}

$ot->queue_button($ld1, "Cancel");

