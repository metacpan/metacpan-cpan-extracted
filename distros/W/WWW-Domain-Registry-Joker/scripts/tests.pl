#!/usr/bin/perl -w

# Copyright (C) 2007 by Peter Pentchev
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.

use strict;

use Getopt::Std;

use WWW::Domain::Registry::Joker;

MAIN:
{
	my ($l, $r, $x);
	my (%opts, %h);

	getopts('d', \%opts) or
	    die("Usage: tests.pl [-d]\n\t-d\tdisplay diagnostic messages.\n");
	$r = new WWW::Domain::Registry::Joker(
	    'username' => 'your-joker-username@example.com',
	    'password' => 'somekindasecret', 'debug' => $opts{'d'},
	    'fake' => 0,
	);

	if (0) {
	%h = $r->query_domain_list('');
	print "====== query-domain-list results:\n".
	    join('', map "- domain $_ expires $h{$_}->{exp}\n", sort keys %h).
	    "======\n";
	}

	if (0) {
	print $r->do_request('contact-create', 'tld' => 'net',
	    'fname' => 'Peter', 'lname' => 'Pentchev', 'individual' => 'Y',
	    'email' => 'roam@hoster.bg',
	    'address-1' => '37 Dobri Vojnikov Street',
	    'city' => 'Sofia', 'postal-code' => '1000', 'country' => 'BG',
	    'phone' => '+359-88-883-1313')."\n";
	}

	if (0) {
	print $r->do_request('ns-create', 'Host' => 'a.ns.ringringlet.net',
	    'IP' => '77.77.142.9')."\n";
	}

	if (0) {
	print $r->do_request('domain-register', 'domain' => 'ringringlet.net',
	    'period' => 24, 'status' => 'production',
	    'owner-c' => 'CNET-673793',
	    'billing-c' => 'CNET-673793',
	    'admin-c' => 'CNET-673793',
	    'tech-c' => 'CNET-673793',
	    'ns-list' => 'a.ns.ringlet.net:b.ns.ringlet.net')."\n";
	}

	if (0) {
	print $r->do_request('domain-delete', 'domain' => 'villa-straylight.info'
	    )."\n";
	}

	if (0) {
	%h = $r->result_list();
	print "Result list:\n".join("\n", map { join ' ', 
	    @{$_}{qw/tstamp svtrid procid reqtype reqobject status cltrid/}}
	    sort { $a->{'procid'} cmp $b->{'procid'} } values %h)."\n";
	}
}
