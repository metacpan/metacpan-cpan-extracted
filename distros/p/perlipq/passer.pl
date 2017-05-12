#
# $Id: passer.pl,v 1.4 2002/01/14 09:15:49 jmorris Exp $
#
# Example IPQueue application, simply passes packets back to
# kernel with NF_ACCEPT verdict.
# 
# Copyright (c) 2000-2002 James Morris <jmorris@intercode.com.au>
#
# This code is GPL.
#
package passer;
use strict;
$^W = 1;

use IPTables::IPv4::IPQueue qw(:constants);

sub main
{
	my ($queue, $msg);
	
	$queue = new IPTables::IPv4::IPQueue(copy_mode => IPQ_COPY_META)
		or die IPTables::IPv4::IPQueue->errstr;

	while (1) {
	
		$msg = $queue->get_message()
			or die IPTables::IPv4::IPQueue->errstr;
		
		print "Issuing verdict on packet " . $msg->packet_id() . "\n";
		
		$queue->set_verdict($msg->packet_id(), NF_ACCEPT) > 0
			or die IPTables::IPv4::IPQueue->errstr;
	}
}

main();

