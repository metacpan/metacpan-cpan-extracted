#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 6;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'WWW::Tracking' ) or exit;
}

ISA_CAN: {
	my $wt = WWW::Tracking->new;
	isa_ok($wt, 'WWW::Tracking');
	can_ok($wt, 'tracker_account');
	can_ok($wt, 'data');
	can_ok($wt, 'from');
}

FROM: {
	my %initial_data = (
		hostname           => 'example.com',
		request_uri        => '/path',
		remote_ip          => '1.2.3.4',
		user_agent         => 'SomeWebBrowser',
	);
	my $wt = WWW::Tracking->new->from('hash' => \%initial_data);
	is(length($wt->data->visitor_id), 32, 'from() autogenerate new visitor_id')
}
