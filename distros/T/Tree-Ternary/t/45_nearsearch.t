#!/usr/local/bin/perl
###########################################################################
#
#  Tree::Ternary
#
#  Copyright (C) 1999, Mark Rogaski; all rights reserved.
#
#  This module is free software.  You can redistribute it and/or
#  modify it under the terms of the Artistic License 2.0.
#
#  This program is distributed in the hope that it will be useful,
#  but without any warranty; without even the implied warranty of
#  merchantability or fitness for a particular purpose.
#
###########################################################################

use Test;
use Tree::Ternary;

BEGIN { plan tests => 33 }

$ref = new Tree::Ternary;

@wordlist = qw(
	banana
	bananas
	pajamas
	words
	forms
	worms
	firewater
	tirewater
	tidewater
	tidewader
	telephone
	telephony
);

for my $word (@wordlist) {
	$ref->insert($word);
}

@stuff = $ref->nearsearch(1, "dorms");
ok(scalar(@stuff), 2);
ok(scalar(grep /^forms$/, @stuff), 1);
ok(scalar(grep /^worms$/, @stuff), 1);

@stuff = $ref->nearsearch(3, "telephone");
ok(scalar(@stuff), 2);
ok(scalar(grep /^telephone$/, @stuff), 1);
ok(scalar(grep /^telephony$/, @stuff), 1);

@stuff = $ref->nearsearch(1, "norm");
ok(scalar(@stuff), 0);

@stuff = $ref->nearsearch(3, "bananas");
ok(scalar(@stuff), 3);
ok(scalar(grep /^banana$/, @stuff), 1);
ok(scalar(grep /^bananas$/, @stuff), 1);
ok(scalar(grep /^pajamas$/, @stuff), 1);

@stuff = $ref->nearsearch(0, "firewater");
ok(scalar(@stuff), 1);
ok(scalar(grep /^firewater$/, @stuff), 1);

@stuff = $ref->nearsearch(1, "firewater");
ok(scalar(@stuff), 2);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);

@stuff = $ref->nearsearch(2, "firewater");
ok(scalar(@stuff), 3);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);
ok(scalar(grep /^tidewater$/, @stuff), 1);

@stuff = $ref->nearsearch(3, "firewater");
ok(scalar(@stuff), 4);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);
ok(scalar(grep /^tidewater$/, @stuff), 1);
ok(scalar(grep /^tidewader$/, @stuff), 1);

ok($ref->nearsearch(1, "dorms") == 2);
ok($ref->nearsearch(3, "telephone") == 2);
ok($ref->nearsearch(1, "norm") == 0);
ok($ref->nearsearch(2, "bananas") == 2);
ok($ref->nearsearch(0, "firewater") == 1);
ok($ref->nearsearch(1, "firewater") == 2);
ok($ref->nearsearch(2, "firewater") == 3);
ok($ref->nearsearch(3, "firewater") == 4);


