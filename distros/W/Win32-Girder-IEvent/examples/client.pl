#!/usr/bin/perl -w

use strict;
use Win32::Girder::IEvent::Client;

my $gc = Win32::Girder::IEvent::Client->new( PeerHost => "workpc" )
	|| die "New failed";

$gc->send(@ARGV)
	|| die "Send failed";

$gc->close();
