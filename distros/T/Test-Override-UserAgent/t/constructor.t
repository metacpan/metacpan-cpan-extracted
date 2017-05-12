#!perl -T

use lib 't/lib';

use Test::More tests => 5;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

{
	# Empty
	new_ok 'Test::Override::UserAgent' => [];
}

{
	my $conf = new_ok 'Test::Override::UserAgent' => [allow_live_requests => 1];
	ok $conf->allow_live_requests, 'allow_live_requests set through constructor hash';
}

{
	my $conf = new_ok 'Test::Override::UserAgent' => [{allow_live_requests => 1}];
	ok $conf->allow_live_requests, 'allow_live_requests set through constructor hash ref';
}
