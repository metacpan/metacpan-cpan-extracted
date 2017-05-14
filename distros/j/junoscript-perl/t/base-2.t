#
# $Id: base-2.t,v 1.4 2003/03/02 11:12:13 dsw Exp $
#
# Copyright (c) 2000-2003, Juniper Networks, Inc.
# All rights reserved.
#

$testno = 1;
$testmax = 7;
print "${testno}..${testmax}\n";

use JUNOS::Device;
use JUNOS::Access::stubs;

open(DEVNULL, ">/dev/null") || die;

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
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "<xnm:error>",
	  "<message>",
	  "this is an error",
	  "</message>",
	  "</xnm:error>",
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "<configuration>",
	  "<system>",
	  "<login>",
	  "<message>",
	  "Amazing, incredible, but true!",
	  "</message>",
	  "</login>",
	  "</system>",
	  "</configuration>",
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "</rpc-reply>",

	  "<rpc-reply>",
	  "</rpc-reply>",

	  "</junoscript>"
);

&JUNOS::Access::stubs::set_read_data(@input);

$jnx = new JUNOS::Device(hostname => "no", user => "no", access => "stubs");
&collaspe unless $jnx;
print "ok ", $testno++, "\n";

$res = $jnx->open_configuration();
$err = $res->getFirstError();
print "not " if $err;
print "ok ", $testno++, "\n";

$res = $jnx->open_configuration();
$err = $res->getFirstError();
print "not " unless $err && $err->{message};
print "ok ", $testno++, "\n";

$res = $jnx->get_configuration();
print DEVNULL $res->toString || print "not ";
print "ok ", $testno++, "\n";

$res = $jnx->load_configuration(rollback => 0);
$err = $res->getFirstError();
print "not " if $err;
print "ok ", $testno++, "\n";

$jnx->close_configuration() || print "not ";
print "ok ", $testno++, "\n";

$jnx->disconnect() || print "not ";
print "ok ", $testno++, "\n";

exit 0;
