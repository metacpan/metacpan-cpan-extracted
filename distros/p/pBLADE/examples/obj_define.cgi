#! /usr/bin/perl -w
use strict;

use BLADE;

blade_obj_simple_init(\@ARGV, \&draw, undef);
blade_orb_run();

sub draw {
	my ($blade, $name, $args, $data) = @_;

	$blade->disp('Hello World');
}
