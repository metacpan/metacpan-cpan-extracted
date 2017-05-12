#!/usr/bin/perl

use Text::Yats;

my $tpl = Text::Yats->new(
		level => 1,
		file  => "../templates/inline.html");

print $tpl->section->[0]->replace(
		title      => "Yats",
		version    => "$Text::Yats::VERSION", );

print $tpl->section->[1]->replace(
		selected   => { value => "selected",
				array => "list",
				match => "anita", });

print $tpl->section->[2]->text;

undef $tpl;

exit(0);
