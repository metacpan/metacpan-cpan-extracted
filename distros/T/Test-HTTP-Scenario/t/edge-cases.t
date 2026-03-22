use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Strict;
use Test::Vars;
use Test::Deep;
use Test::Returns;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::HTTP::Scenario;

BEGIN {
	require File::Path;
	File::Path::make_path('t/fixtures');
}

#----------------------------------------------------------------------#
# Local mock adapter for edge-case testing
#----------------------------------------------------------------------#

{
	package Local::Adapter::Edge;
	use strict;
	use warnings;

	sub new {
		my ($class) = @_;
		return bless {
			scenario	   => undef,
			normalized_req => undef,
			normalized_res => undef,
			installed	  => 0,
			uninstalled	=> 0,
		}, $class;
	}

	sub set_scenario {
		my ($self, $sc) = @_;
		$self->{scenario} = $sc;
		require Scalar::Util;
		Scalar::Util::weaken($self->{scenario});
		return;
	}

	sub install   { $_[0]->{installed}++ }
	sub uninstall { $_[0]->{uninstalled}++ }

	sub normalize_request {
		my ($self, $req) = @_;
		return $self->{normalized_req} // $req;
	}

	sub normalize_response {
		my ($self, $res) = @_;
		return $self->{normalized_res} // $res;
	}

	sub build_response {
		my ($self, $hash) = @_;
		return $hash->{body};
	}
}

#----------------------------------------------------------------------#
# Redirect-like behaviour
#----------------------------------------------------------------------#

subtest 'redirect-like response is recorded and replayed' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'redirect',
		file	=> 't/fixtures/redirect.yaml',
		mode	=> 'record',
		adapter => $adapter,
	);

	my $real_called = 0;

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://x/' };
	$adapter->{normalized_res} = {
		status  => 302,
		reason  => 'Found',
		headers => { Location => 'http://x/next' },
		body	=> '',
	};

	$sc->handle_request({}, sub { $real_called++; return 'IGNORED' });

	is $real_called, 1, 'real request executed in record mode';

	cmp_deeply(
		$sc->{interactions}[0]{response},
		superhashof({ status => 302 }),
		'redirect stored correctly'
	);

	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'redirect',
		file	=> 't/fixtures/redirect.yaml',
		mode	=> 'replay',
		adapter => Local::Adapter::Edge->new,
	);

	$sc2->{interactions} = $sc->{interactions};
	$sc2->{adapter}->{normalized_req} = { method => 'GET', uri => 'http://x/' };

	my $res = $sc2->handle_request({}, sub { die 'should not call real' });

	is $res, '', 'redirect body replayed';
};

#----------------------------------------------------------------------#
# Binary body handling
#----------------------------------------------------------------------#

subtest 'binary body is preserved' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $binary = "\x00\xFF\x10\x80";

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'binary',
		file	=> 't/fixtures/binary.yaml',
		mode	=> 'record',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://bin/' };
	$adapter->{normalized_res} = {
		status  => 200,
		reason  => 'OK',
		headers => {},
		body	=> $binary,
	};

	$sc->handle_request({}, sub { return 'IGNORED' });

	cmp_deeply(
		$sc->{interactions}[0]{response}{body},
		$binary,
		'binary body stored'
	);

	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'binary',
		file	=> 't/fixtures/binary.yaml',
		mode	=> 'replay',
		adapter => Local::Adapter::Edge->new,
	);

	$sc2->{interactions} = $sc->{interactions};
	$sc2->{adapter}->{normalized_req} = { method => 'GET', uri => 'http://bin/' };

	my $res = $sc2->handle_request({}, sub { die 'no real call' });

	is $res, $binary, 'binary body replayed';
};

#----------------------------------------------------------------------#
# Multiple identical requests
#----------------------------------------------------------------------#

subtest 'multiple identical requests return first match' => sub {

	unlink 't/fixtures/multi.yaml' if -e 't/fixtures/multi.yaml';

	my $adapter = Local::Adapter::Edge->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'multi',
		file	=> 't/fixtures/multi.yaml',
		mode	=> 'replay',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://x/' };

	$sc->{interactions} = [
		{ request => { method => 'GET', uri => 'http://x/' }, response => { body => 'FIRST' } },
		{ request => { method => 'GET', uri => 'http://x/' }, response => { body => 'SECOND' } },
	];

	my $res = $sc->handle_request(
		{ method => 'GET', uri => 'http://x/' },
		sub { die 'no real call' }
	);

	is $res, 'FIRST', 'first matching interaction returned';
};


#----------------------------------------------------------------------#
# Missing fields in fixture
#----------------------------------------------------------------------#

subtest 'missing fields in fixture do not crash replay' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'missing',
		file	=> 't/fixtures/missing.yaml',
		mode	=> 'replay',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://x/' };

	$sc->{interactions} = [
		{ request => { method => 'GET', uri => 'http://x/' }, response => {} },
	];

	my $res = $sc->handle_request({}, sub { die 'no real call' });

	is $res, undef, 'empty response hash produces undef body';
};

#----------------------------------------------------------------------#
# Unexpected status codes
#----------------------------------------------------------------------#

subtest 'unexpected status codes are preserved' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'status',
		file	=> 't/fixtures/status.yaml',
		mode	=> 'record',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'POST', uri => 'http://x/' };
	$adapter->{normalized_res} = {
		status  => 418,
		reason  => 'I am a teapot',
		headers => {},
		body	=> 'short and stout',
	};

	$sc->handle_request({}, sub { return 'IGNORED' });

	cmp_deeply(
		$sc->{interactions}[0]{response}{status},
		418,
		'status code preserved'
	);
};

#----------------------------------------------------------------------#
# Chunked-like bodies (simulated)
#----------------------------------------------------------------------#

subtest 'chunked-like body is stored as-is' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $chunked = "4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n";

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'chunked',
		file	=> 't/fixtures/chunked.yaml',
		mode	=> 'record',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://chunk/' };
	$adapter->{normalized_res} = {
		status  => 200,
		reason  => 'OK',
		headers => {},
		body	=> $chunked,
	};

	$sc->handle_request({}, sub { return 'IGNORED' });

	cmp_deeply(
		$sc->{interactions}[0]{response}{body},
		$chunked,
		'chunked-like body stored'
	);
};

#----------------------------------------------------------------------#
# Replay mismatch behaviour
#----------------------------------------------------------------------#

subtest 'replay mismatch croaks' => sub {

	my $adapter = Local::Adapter::Edge->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'mismatch',
		file	=> 't/fixtures/mismatch.yaml',
		mode	=> 'replay',
		adapter => $adapter,
	);

	$adapter->{normalized_req} = { method => 'GET', uri => 'http://wrong/' };

	$sc->{interactions} = [
		{ request => { method => 'GET', uri => 'http://right/' }, response => { body => 'ok' } },
	];

	dies_ok {
		$sc->handle_request({}, sub { die 'should not call real' });
	} 'croaks on mismatch';
};

done_testing();
