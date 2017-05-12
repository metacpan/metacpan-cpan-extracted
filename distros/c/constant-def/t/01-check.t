#!/usr/bin/perl

use strict;
use warnings;
use ex::lib '../lib';
use Test::More;
BEGIN { 
	my $tests = 5;
	eval { require Test::NoWarnings; Test::NoWarnings->import; 1 } and $tests++;
	plan tests => $tests;
}
use constant::abs 't::TEST' => 0;
BEGIN {
	local $@;
	local $SIG{__WARN__} = sub {};
	eval q{use constant::def undef, 0;};
	ok($@, 'undef name acts like constant');
}
BEGIN {
	local $@;
	local $SIG{__WARN__} = sub {};
	eval q{use constant::abs 't::ARGV' => 0;};
	like($@, qr/forced into main::/, 'bad name acts like constant');
}
use constant::abs {
    't::DEBUG' => 1,
};

# emulation of use t
{
	package t;
	
	use strict;
	use constant::def TEST => 1;
	use constant::def {
	    DEF => 1
	};
	
}

is(t::TEST,  0, 'TEST is set by abs');
is(t::DEBUG, 1, 'DEBUG is set by abs');
is(t::DEF,   1, 'DEF is set by def');
