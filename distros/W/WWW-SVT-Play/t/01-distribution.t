#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

eval { require Test::Distribution };

if($@) {
	plan skip_all => 'Test::Distribution is not installed';
} else {
	import Test::Distribution;
}

