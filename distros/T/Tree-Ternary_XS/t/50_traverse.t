#!/usr/local/bin/perl
###########################################################################
# $Id: 50_traverse.t,v 1.2 1999/09/21 05:42:26 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:26 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################

use Test;
use Tree::Ternary_XS;

BEGIN { plan tests => 12 }

$ref = new Tree::Ternary_XS;

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

