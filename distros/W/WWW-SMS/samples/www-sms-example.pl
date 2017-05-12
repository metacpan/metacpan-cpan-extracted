#!/usr/bin/perl

#
# Copyright (c) 2001 Giulio Motta. All rights reserved.
# http://www-sms.sourceforge.net/
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use WWW::SMS;

my $sms = WWW::SMS->new('39', '333', '1234567', 'This is a test.');

for ( $sms->gateways(sorted => 'reliability') ) {
	print "Trying $_...\n";
	if ( $sms->send($_) ) {
		last;
	} else {
		print $WWW::SMS::Error;
	}
}
