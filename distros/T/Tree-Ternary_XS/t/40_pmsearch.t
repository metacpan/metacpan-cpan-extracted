#!/usr/local/bin/perl
###########################################################################
# $Id: 40_pmsearch.t,v 1.2 1999/09/21 05:42:25 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:25 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################

use Test;
use Tree::Ternary_XS;

BEGIN { plan tests => 31 }

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


