#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'WWW::Tracking::Data' ) or exit;
}

AS_HASH_FROM_HASH: {
	my %initial_data = (
		hostname           => 'example.com',
		request_uri        => '/path',
		remote_ip          => '1.2.3.4',
		user_agent         => 'SomeWebBrowser',
		referer            => 'http://search/?q=example',
		browser_language   => 'de-AT',
		timestamp          => 1314712280,
		java_version       => '1.5',
		encoding           => 'UTF-8',
		screen_color_depth => '24',
		screen_resolution  => '1024x768',
		flash_version      => '9.0',
		visitor_id         => '202cb962ac59075b964b07152d234b70',
	);
	my $tracking_data = WWW::Tracking::Data->new(%initial_data);
	
	eq_or_diff($tracking_data->as_hash, \%initial_data, 'as_hash()');
	eq_or_diff(WWW::Tracking::Data->new->from_hash(\%initial_data), $tracking_data, 'from_hash()');
}
