#!/usr/bin/perl

use strict;
use warnings;
use utf8;

#use Test::More 'no_plan';
use Test::More tests => 25;

binmode(Test::More->builder->$_ => q(encoding(:UTF-8)))
	for qw(output failure_output todo_output);

BEGIN {
	use_ok ( 'XML::Char' ) or exit;
}

exit main();

sub main {
	ok(XML::Char->valid(undef), 'undef is valid');
	ok(XML::Char->valid("abc"), '"abc" is valid');
	ok(XML::Char::valid("abc"), '"abc" is valid');
	ok(XML::Char->valid("slniečok"), '"slniečok" is valid');
	ok(XML::Char->valid("slnko".chr(10)), '"slnko\n" is valid');
	ok(!XML::Char->valid("mesi".chr(11)."ac"), '"mesi".chr(11)."ac" is not valid');
	ok(!XML::Char->valid("m".chr(0)), '"m".chr(0) also not');
	ok(!XML::Char::valid("eot ".chr(4)), '"eot ".chr(5) also not');
	ok(!XML::Char->valid("bell ".chr(7)), '"bell ".chr(7) also not');
	ok(XML::Char->valid("\t tab"), '"\t tab " is ok');
	ok(XML::Char->valid("m".chr(0x7f)), '"m".chr(0x7f) is fine (just not recommended)');
	ok(XML::Char->valid("x04E9".chr(0x04E9)."\n"), "0x04E9 is valid");
	ok(XML::Char->valid("x8FEA".chr(0x8FEA)."\n"), "0x8FEA is valid");
	ok(XML::Char->valid("迪"), "迪 is valid");
	ok(XML::Char->valid("x8FEA".chr(0x62C9)."\n"), "0x62C9 is valid");
	ok(XML::Char->valid("拉"), "拉 is valid");
	ok(XML::Char->valid("x8FEA".chr(0x65AF)."\n"), "0x65AF is valid");
	ok(XML::Char->valid("斯"), "斯 is valid");
	ok(XML::Char->valid("xFFFD".chr(0xFFFD))."\n", '0xFFFD is valid');
	ok(!XML::Char->valid("xFFFE".chr(0xFF).chr(0xFE))."\n", '0xFFFE is not valid');
	ok(!XML::Char->valid("xFFFF".chr(0xFF).chr(0xFF))."\n", '0xFFFF is not valid');
	ok(XML::Char->valid(chr(0x1FFF0)), '1FFF0 is valid');
	do {
		no warnings 'utf8';    # 1FFFF is illegal, but valid. shhhhhh
		ok(XML::Char->valid(chr(0x1FFFF)), '1FFFF is valid');
	};
	ok(!XML::Char->valid(chr(0x20000)), '20000 is not valid');
	
	return 0;
}

