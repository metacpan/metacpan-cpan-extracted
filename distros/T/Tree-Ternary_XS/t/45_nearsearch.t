#!/usr/local/bin/perl
###########################################################################
# $Id: 45_nearsearch.t,v 1.2 1999/09/21 05:42:26 wendigo Exp $
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

BEGIN { plan tests => 33 }

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


