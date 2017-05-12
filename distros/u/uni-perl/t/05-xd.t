#!/usr/bin/env perl

use Test::More tests => 4
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };
use uni::perl ':xd';

my $imported = \&xd;

my $have = eval { require Devel::Hexdump; 1};

if ($have && 0) {
	diag "Have installed, use native";
	ok $imported != \&Devel::Hexdump::xd, 'loader method';
	ok my $first = xd("t"), 'first';
	$imported = \&xd;
	ok $imported == \&Devel::Hexdump::xd, 'loaded';
	is $first, xd("t"), 'equal';
} else {
	diag "Have no installed, use fallback";
	ok my $first = xd("t"), 'first';
	is $first, xd("t"), 'equal';
	ok $imported != \&xd, 'loaded';
	is xd("1"),xd("1"), 'equal2';
}
