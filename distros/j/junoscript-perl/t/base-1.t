#
# $Id: base-1.t,v 1.4 2003/03/02 11:12:13 dsw Exp $
#
# Copyright (c) 2000-2003, Juniper Networks, Inc.
# All rights reserved.
#

$testno = 1;
$testmax = 5;
print "${testno}..${testmax}\n";

use JUNOS::Device;
use JUNOS::Access::stubs;

sub collaspe {
    for my $t ($testno .. $testmax) {
	print "not ok $t\n";
    }
    exit 1;
}

@input = (
	  "<?xml version=\"1.0\" encoding=\"us-ascii\"?>",
	  "<junoscript os=\"perl-test\" version=\"1.0\">",

	  "<rpc-reply>",
	  "<top-level-tag>",
	  "<fred>",
	  "This is way cool",
	  "</fred>",
	  "</top-level-tag>",
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "<another-top-level-tag>",
	  "<george>",
	  "This is absolutely too cool",
	  "</george>",
	  "</another-top-level-tag>",
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "<yet-another-top-level-tag>",
	  "<jim>",
	  "No, this is beyond that",
	  "</jim>",
	  "</yet-another-top-level-tag>",
	  "</rpc-reply>",

	  "</junoscript>"
);

&JUNOS::Access::stubs::set_read_data(@input);

$jnx = new JUNOS::Device(hostname => "no", user => "no", access => "stubs");
&collaspe unless $jnx;
print "ok ", $testno++, "\n";

$res = $jnx->command("test fred");
$fred = $res->getElementsByTagName("fred");
print "not " unless $fred && $fred->[0][9] eq "fred";
print "ok ", $testno++, "\n";

$res = $jnx->command("test george");
$george = $res->getElementsByTagName("george");
print "not " unless $george && $george->[0][9] eq "george";
print "ok ", $testno++, "\n";

$res = $jnx->command("test jim");
$jim = $res->getElementsByTagName("jim");
print "not " unless $jim && $jim->[0][9] eq "jim";
print "ok ", $testno++, "\n";

$jnx->disconnect || print "not ";
print "ok ", $testno++, "\n";

exit 0;
