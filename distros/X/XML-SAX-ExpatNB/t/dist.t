#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	eval "use Test::Distribution not => 'description'";
	plan skip_all => "Test::Distribution must be installed" if $@;
}

