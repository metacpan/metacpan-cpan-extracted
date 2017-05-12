#!/usr/bin/perl -w

use Test::More tests => 3;

BEGIN {
	use_ok('Text::Buffer');
	use_ok('Text::Modify');
	use_ok('Text::Modify::Rule');
}