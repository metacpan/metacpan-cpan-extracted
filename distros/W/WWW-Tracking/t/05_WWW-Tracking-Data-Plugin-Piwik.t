#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 6;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'WWW::Tracking' ) or exit;
	use_ok ( 'WWW::Tracking::Data::Plugin::Piwik' ) or exit;
}

AS_PIWIK_REQUEST: {
	my %initial_data = (
		hostname            => 'metacpan.org',
		request_uri         => '/module/WWW::Tracking',
		remote_ip           => '109.72.0.72',
		user_agent          => 'Mozilla/5.0 (X11; Linux i686; rv:5.0) Gecko/20100101 Firefox/5.0 Iceweasel/5.0',
		referer             => 'http://jozef.kutej.net/?q=referer',
		visitor_id          => '202cb942ac50075c964b07152d234b70',
		timestamp           => 1315403315,
		screen_resolution   => '1024x768',
		flash_version       => '9.0',
		java_version        => '1.5',
		quicktime_version   => 7,
		realplayer_version  => 14,
		pdf_support         => 1,
		mediaplayer_version => 11,
		gears_version       => 1,
		silverlight_version => 0,
		cookie_support      => 1,
	);
	my $wt = WWW::Tracking->new(
		'tracker_account' => '5:token_auth',
		'tracker_type'    => 'piwik',
		'tracker_url'     => 'http://stats.meon.eu/piwik.php',
	)->from('hash' => \%initial_data);
	is($wt->data->as_piwik, 'http://stats.meon.eu/piwik.php?idsite=5&token_auth=token_auth&rec=1&apiv=1&rand=115935801&cip=109.72.0.72&cid=202cb942ac50075c&cdt=2011-09-07+13%3A48%3A35&fla=1&java=1&qt=1&realp=1&pdf=1&wma=1&gears=1&ag=0&h=13&m=48&s=35&res=1024x768&cookie=1&url=http%3A%2F%2Fmetacpan.org%2Fmodule%2FWWW%3A%3ATracking&urlref=http%3A%2F%2Fjozef.kutej.net%2F%3Fq%3Dreferer&action_name=%2Fmodule%2FWWW%3A%3ATracking', 'as_piwik()');
	
	eval { $wt->make_tracking_request };
	SKIP: {
		if ($@) {
			diag $@;
			skip 'tracking request failed, no network connection?', 1;
		}
		
		ok(1, 'tracking request passed');
	}
}

package WWW::Tracking::Data::Plugin::Piwik;

no warnings 'redefine';

sub _uniq_rand_id { 115935801 };

1;
