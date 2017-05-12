#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif qw(XmALIGNMENT_END);
use Math::Units;

my $toplevel = X::Toolkit::initialize("CvtUnits");

my $form = give $toplevel -Form;

my $menubar = give $form -MenuBar;
my $menu;

$menu = give $menubar -Menu, -name => 'File';
	give $menu -Button, -text => 'Quit', -command => sub { exit 0 };

$menu = give $menubar -Menu, -name => 'Help';
	give $menu -Button, -text => 'Help!';

my $subform = give $form -Form, -fractionBase => 2;

my $in_label = give $subform -Label,
		-text => 'Input:',
		-alignment => XmALIGNMENT_END,
		-width => 100;

my $out_label = give $subform -Label,
		-text => 'Output:',
		-alignment => XmALIGNMENT_END,
		-width => 100;

my $in_value = give $subform -Field,
		-width => 200,
		-command => \&do_compute;

my $out_value = give $subform -Field,
		-editable => 0,
		-traversalOn => 0,
		-cursorPositionVisible => 0,
		-width => 200;

my $w;

my $in_unit;
($in_unit, $menu) = give $subform -OptionMenu, -label => 'unit';
    $w = give $menu -Button, -text => 'mm', -command => \&do_set_input;
    give $menu -Button, -text => 'cm', -command => \&do_set_input;
    give $menu -Button, -text => 'm', -command => \&do_set_input;
    give $menu -Button, -text => 'km', -command => \&do_set_input;
    give $menu -Button, -text => 'in', -command => \&do_set_input;
    give $menu -Button, -text => 'ft', -command => \&do_set_input;
    give $menu -Button, -text => 'yd', -command => \&do_set_input;
    give $menu -Button, -text => 'mi', -command => \&do_set_input;

my $in_u = "mm";
change $in_unit -menuHistory => $w;

my $out_unit;
($out_unit, $menu) = give $subform -OptionMenu, -label => 'unit';
    give $menu -Button, -text => 'mm', -command => \&do_set_output;
    give $menu -Button, -text => 'cm', -command => \&do_set_output;
    give $menu -Button, -text => 'm', -command => \&do_set_output;
    give $menu -Button, -text => 'km', -command => \&do_set_output;
    $w = give $menu -Button, -text => 'in', -command => \&do_set_output;
    give $menu -Button, -text => 'ft', -command => \&do_set_output;
    give $menu -Button, -text => 'yd', -command => \&do_set_output;
    give $menu -Button, -text => 'mi', -command => \&do_set_output;

my $out_u = "in";
change $out_unit -menuHistory => $w;

sub do_compute {
    my $v = query $in_value -text;
    $v = Math::Units::Convert($v, $in_u, $out_u);
    change $out_value -text => "$v";
}

sub do_set_input {
    my($widget) = @_;
    my $u = (query $widget -text)->plain;
    $in_u = $u;
    do_compute();
}

sub do_set_output {
    my($widget) = @_;
    my $u = (query $widget -text)->plain;
    $out_u = $u;
    do_compute();
}

constrain $in_label	-top => -form,	    -bottom => -none,	-left => -form,		-right => -none;
constrain $in_value	-top => -form,	    -bottom => 1,	-left => $in_label,	-right => $in_unit;
constrain $in_unit	-top => -form,	    -bottom => 1,	-left => -none,		-right => -form;

constrain $out_label	-top => $in_value,  -bottom => -none,	-left => -form,		-right => -none;
constrain $out_value	-top => $in_value,  -bottom => -form,	-left => $in_label,	-right => $in_unit;
constrain $out_unit	-top => $in_unit,   -bottom => -form,	-left => -none,		-right => -form;

arrange $form -fill => 'xy', -top => [ $menubar, $subform ];

handle $toplevel;
