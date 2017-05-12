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

BEGIN { plan tests => 31 }

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

@stuff = $ref->pmsearch('.', ".orms");
ok(scalar(@stuff), 2);
ok(scalar(grep /^forms$/, @stuff), 1);
ok(scalar(grep /^worms$/, @stuff), 1);

@stuff = $ref->pmsearch('.', "telephon.");
ok(scalar(@stuff), 2);
ok(scalar(grep /^telephone$/, @stuff), 1);
ok(scalar(grep /^telephony$/, @stuff), 1);

@stuff = $ref->pmsearch('.', ".orm");
ok(scalar(@stuff), 0);

@stuff = $ref->pmsearch('.', ".a.a.a.");
ok(scalar(@stuff), 2);
ok(scalar(grep /^bananas$/, @stuff), 1);
ok(scalar(grep /^pajamas$/, @stuff), 1);

@stuff = $ref->pmsearch('.', ".irewater");
ok(scalar(@stuff), 2);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);

@stuff = $ref->pmsearch('.', ".irewa.er");
ok(scalar(@stuff), 2);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);

@stuff = $ref->pmsearch('.', ".i.ewa.er");
ok(scalar(@stuff), 4);
ok(scalar(grep /^firewater$/, @stuff), 1);
ok(scalar(grep /^tirewater$/, @stuff), 1);
ok(scalar(grep /^tidewater$/, @stuff), 1);
ok(scalar(grep /^tidewader$/, @stuff), 1);

@stuff = $ref->pmsearch('.', ".i.ewader");
ok(scalar(@stuff), 1);
ok(scalar(grep /^tidewader$/, @stuff), 1);

ok($ref->pmsearch('F', "Forms") == 2);
ok($ref->pmsearch('L', "telephonL") == 2);
ok($ref->pmsearch('A', "Aorm") == 0);
ok($ref->pmsearch('M', "MaMaMaM") == 2);
ok($ref->pmsearch('I', "Iirewater") == 2);
ok($ref->pmsearch('N', "NirewaNer") == 2);
ok($ref->pmsearch('G', "GiGewaGer") == 4);
ok($ref->pmsearch('O', "OiOewader") == 1);


