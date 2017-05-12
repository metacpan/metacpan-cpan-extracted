#
# $Id: dumper.pl,v 1.6 2002/01/14 09:15:49 jmorris Exp $
#
# Example IPQueue application, dumps packet metadata and IP
# headers. Requires Tim Potter's NetPacket module.
#
# Copyright (c) 2000-2002 James Morris <jmorris@intercode.com.au>
# This code is GPL.
#
package ipq_example;
use strict;
$^W = 1;

use IPTables::IPv4::IPQueue qw(:constants);
use NetPacket::IP;

use constant TIMEOUT => 1_000_000 * 2;		# 2 seconds

sub dump_payload
{
	my ($payload, $ip);
	
	$payload = shift;

	#
	# IP Header
	#
	$ip = NetPacket::IP->decode($payload);
	
	print<<EOT;
[ IP Header ]
Version           : $ip->{ver}
Header Length     : $ip->{hlen}
Flags             : $ip->{flags}
Frag. Offset      : $ip->{foffset}
TOS               : $ip->{tos}
Length            : $ip->{len}
ID                : $ip->{id}
TTL               : $ip->{ttl}
Protocol          : $ip->{proto}
Checksum          : $ip->{cksum}
Source IP         : $ip->{src_ip}
Destination IP    : $ip->{dest_ip}
Options           : $ip->{options}

EOT
}

sub dump_meta
{
	my $msg = shift;

	print <<EOT;
[ Metadata ]
Packet ID         : @{[ $msg->packet_id() ]}
Mark              : @{[ $msg->mark() ]}
Timestamp (sec)   : @{[ $msg->timestamp_sec() ]}
Timestamp (usec)  : @{[ $msg->timestamp_usec() ]}
Hook              : @{[ $msg->hook() ]}
In Device         : @{[ $msg->indev_name() ]}
Out Device        : @{[ $msg->outdev_name() ]}
HW Protocol       : @{[ $msg->hw_protocol() ]}
HW Type           : @{[ $msg->hw_type() ]}
HW Address Length : @{[ $msg->hw_addrlen() ]}
HW Address        : @{[ unpack('H*', $msg->hw_addr()) ]}
Data Length       : @{[ $msg->data_len() ]}
EOT
}

sub main
{
	my $queue = new IPTables::IPv4::IPQueue(copy_mode => IPQ_COPY_PACKET,
	                                        copy_range => 2048)
		or die IPTables::IPv4::IPQueue->errstr;

	while (1) {
		my $msg = $queue->get_message(TIMEOUT);
		if (!defined $msg) {
			next if IPTables::IPv4::IPQueue->errstr eq 'Timeout';
			die IPTables::IPv4::IPQueue->errstr;
		}
	
		dump_meta($msg);
		dump_payload($msg->payload()) if $msg->data_len();
		$queue->set_verdict($msg->packet_id, NF_ACCEPT);
	}
}

main();
