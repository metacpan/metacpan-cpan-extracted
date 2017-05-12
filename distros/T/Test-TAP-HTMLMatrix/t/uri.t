#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

my ($f, $s);

BEGIN {
	use_ok($f = "Test::TAP::Model::File::Visual");
	use_ok($s = "Test::TAP::Model::Subtest::Visual");
}

my ($ef, $es) = ("foo/bar.txt", "foo/bar.txt#line_4");

my %cases = (
	darwin => {
		file => "foo/bar.txt",
		subtest => "file foo/bar.txt line 4",
	},
	win32 => {
		file => "foo\\bar.txt",
		subtest => "file foo\\bar.txt line 4",
	},
);

foreach $^O (keys %cases){
	my $file = $f->new({
		file => $cases{$^O}{file},
	});

	isa_ok($file->link, "URI::file", "file link");
	is($file->link, $ef, "file link on $^O");


	my $subtest = $s->new({
		type => "test",
		pos => $cases{$^O}{subtest},
	});

	isa_ok($subtest->link, "URI::file", "subtest link");
	is(my $l = $subtest->link, $es, "subtest link on $^O");

	is($l->fragment, "line_4", "fragment looks good");
}

