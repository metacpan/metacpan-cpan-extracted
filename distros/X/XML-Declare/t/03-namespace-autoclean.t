#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs '../lib';
use Test::More;
use Test::NoWarnings ();

BEGIN {
	eval{ require namespace::autoclean; 1 } or plan skip_all => "namespace::autoclean required";
}
use XML::Declare;
use namespace::autoclean;
plan tests => 4;
my $doc = doc {
	element 'test', sub {
		text 'sample';
	};
};

is
	$doc->documentElement->toString(),
	'<test>sample</test>',
	'assembled';

my $el = element 'test', 'sample';

is
	$el->toString(),
	'<test>sample</test>',
	'standalone element';

ok !eval{ attr "x","x"; 1 }, 'no attr outside';

Test::NoWarnings::had_no_warnings();

exit;
require Test::NoWarnings; # Stupid hack for cpants::kwalitee
