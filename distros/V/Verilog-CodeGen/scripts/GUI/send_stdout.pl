#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

#This script very simply sends everything it receives on STDIN to TCP port $port on the localhost.

use strict;
use IO::Socket;

my $port=2507;
my $new_sock;
my $buff;

my $sock = new IO::Socket::INET (
PeerAddr => 'localhost',
				 PeerPort => $port,
				 Proto => 'tcp',
				 );
die "Socket could not be created: $!" unless $sock; 
while (<STDIN>) {
my $line=$_;
print $sock $line;
#print "SENT:$line\n";
$sock->flush();
}
close ($sock);



