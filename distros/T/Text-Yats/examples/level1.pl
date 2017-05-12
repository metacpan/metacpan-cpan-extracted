#!/usr/bin/perl

use Text::Yats;

my $tpl = Text::Yats->new(
		level => 1,
		file  => "../templates/form.html");

print $tpl->section->[0]->replace(
		title      => "Yats",
		version    => "$Text::Yats::VERSION", );

print $tpl->section->[1]->replace(
		list       => ['hdias','anita','cubitos'],
		selected   => { value => "selected",
				array => "list",
				match => "anita", });

print $tpl->section->[2]->text;

undef $tpl;

exit(0);
