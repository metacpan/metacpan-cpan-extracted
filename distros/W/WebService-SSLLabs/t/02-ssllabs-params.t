#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'WebService::SSLLabs' ) || print "Bail out!\n";
}

my $hostName = 'ssllabs.com';
my $quotedHostName = quotemeta $hostName;

my $lab = WebService::SSLLabs->new();
my $exception;

$lab->{ua} = MockLWP->new();

foreach my $value ( 'on' ) {
	eval {
		$lab->analyze(host => $hostName, start_new => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&startNew=on$/), "startNew=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName, publish => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&publish=on$/), "publish=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName, from_cache => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&fromCache=on$/), "fromCache=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->get_endpoint_data(host => $hostName, s => '10.1.1.1', from_cache => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&s=10\.1\.1\.1&fromCache=on/), "fromCache=on is set correctly:" . MockLWP::last_url());
	eval {
		$lab->analyze(host => $hostName, ignore_mismatch => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&ignoreMismatch=on$/), "ignoreMismatch=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName, all => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&all=on$/), "all=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName$/), "maxAge, all, fromCache, fromCache and startNew are correctly not set:" . MockLWP::last_url());
}
foreach my $value ( 'done' ) {
	eval {
		$lab->analyze(host => $hostName, all => $value);
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&all=done$/), "all=done is set correctly:" . MockLWP::last_url());
}
foreach my $value ( 'off' ) {
	eval {
		$lab->analyze(host => $hostName, start_new => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&startNew=off$/), "startNew=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName, publish => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&publish=off$/), "publish=on is set correctly:" . MockLWP::last_url());

	eval {
		$lab->analyze(host => $hostName, from_cache => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&fromCache=off$/), "fromCache=off is set correctly:" . MockLWP::last_url());

	eval {
		$lab->get_endpoint_data(host => $hostName, s => '10.1.1.1', from_cache => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&s=10\.1\.1\.1&fromCache=off$/), "fromCache=off is set correctly:" . MockLWP::last_url());
	eval {
		$lab->analyze(host => $hostName, ignore_mismatch => $value );
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&ignoreMismatch=off$/), "ignoreMismatch=off is set correctly:" . MockLWP::last_url());
}

foreach my $value (0, 64, 100) {
	eval {
		$lab->analyze(host => $hostName, max_age => $value);
	} or do {
		$exception = $@;
	};
	ok(($@ and MockLWP::last_url() =~ /\?host=$quotedHostName\&maxAge=$value$/), "maxAge=$value is set correctly:" . MockLWP::last_url());
}

done_testing();

package MockLWP;

use parent 'LWP::UserAgent';

my $last_url;

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub get { 
	my ($self, $url) = @_;
	$last_url = $url;
	return HTTP::Response->new( 500 );
}

sub last_url {
	return $last_url || $@;
}
