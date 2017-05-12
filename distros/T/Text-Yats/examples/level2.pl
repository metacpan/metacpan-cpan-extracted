#!/usr/bin/perl

use Text::Yats;

my $tpl = Text::Yats->new(
		level => 2,
		file  => "../templates/complex.html");

print $tpl->section->[0]->replace(
		title      => "Yats",
		version    => "$Text::Yats::VERSION", );

print $tpl->section->[1]->section->[0]->replace(
		list       => ['hdias','anita','cubitos'],
		value      => [1,2,3],
		selected   => { value => "selected",
				array => "list",
				match => "anita", });

print $tpl->section->[1]->section->[1]->replace(
		list       => ['hdias','anita','cubitos'],
		value      => [1,2,3],
		selected   => { value => "selected",
				array => "list",
				match => "anita", });

print $tpl->section->[1]->section->[2]->replace(
		list       => ['hdias','anita','cubitos','cindy'],
		value      => [1,2,3,4],
		selected   => { value => "selected",
				array => "list",
				match => ["anita","cindy"], }) or print "not ";

print $tpl->section->[2]->text;

undef $tpl;

exit(0);
