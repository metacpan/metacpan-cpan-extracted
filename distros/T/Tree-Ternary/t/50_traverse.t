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

BEGIN { plan tests => 12 }

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

@result = $ref->traverse();

ok($result[0], 'banana');
ok($result[1], 'bananas');
ok($result[2], 'firewater');
ok($result[3], 'forms');
ok($result[4], 'pajamas');
ok($result[5], 'telephone');
ok($result[6], 'telephony');
ok($result[7], 'tidewader');
ok($result[8], 'tidewater');
ok($result[9], 'tirewater');
ok($result[10], 'words');
ok($result[11], 'worms');

