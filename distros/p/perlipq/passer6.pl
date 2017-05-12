#
# $Id: passer6.pl,v 1.2 2002/01/14 09:15:49 jmorris Exp $
#
# Example IPQueue application, simply passes packets back to
# kernel with NF_ACCEPT verdict.  This one does IPv6.
# 
# Copyright (c) 2000-2002 James Morris <jmorris@intercode.com.au>
#
# This code is GPL.
#
package passer6;
use strict;
$^W = 1;

# sys/socket.ph is really broken on my system
use constant X_PF_INET6	=>	10;


use IPTables::IPv4::IPQueue qw(:constants);

sub main
{
	my ($queue, $msg);
	
	$queue = new IPTables::IPv4::IPQueue(copy_mode => IPQ_COPY_META,
	                                     protocol => X_PF_INET6)
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

