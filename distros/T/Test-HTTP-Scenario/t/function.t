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

use_ok('Test::HTTP::Scenario') or BAIL_OUT('Cannot load core module');

BEGIN {
	require File::Path;
	File::Path::make_path('t/fixtures');
}

#----------------------------------------------------------------------#
# Constructor behaviour
#----------------------------------------------------------------------#

subtest 'constructor basic structure' => sub {

	new_ok(
		'Test::HTTP::Scenario' => [
			name	=> 'basic',
			file	=> 't/fixtures/basic.yaml',
			mode	=> 'record',
			adapter => 'LWP',
		],
		'constructor returns object',
	);

};

#----------------------------------------------------------------------#
# Adapter selection
#----------------------------------------------------------------------#

subtest '_build_adapter maps names correctly' => sub {

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'adapter_test',
		file	=> 't/fixtures/adapter.yaml',
		mode	=> 'record',
		adapter => 'LWP',
	);

	isa_ok($sc->{adapter}, 'Test::HTTP::Scenario::Adapter::LWP');

};

#----------------------------------------------------------------------#
# Serializer selection
#----------------------------------------------------------------------#

subtest '_build_serializer maps names correctly' => sub {

	my $sc = Test::HTTP::Scenario->new(
		name	   => 'serializer_test',
		file	   => 't/fixtures/serializer.yaml',
		mode	   => 'record',
		adapter	=> 'LWP',
		serializer => 'YAML',
	);

	isa_ok($sc->{serializer}, 'Test::HTTP::Scenario::Serializer::YAML');

};

#----------------------------------------------------------------------#
# Pure helper behaviour (white-box)
#----------------------------------------------------------------------#

{
	package Local::MockAdapter1;
	use strict;
	use warnings;
	sub new { bless {}, shift }
	sub normalize_request { return { method => 'GET', uri => 'http://x/' } }
}

subtest '_find_match returns undef when no interactions exist' => sub {

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'empty',
		file	=> 't/fixtures/empty.yaml',
		mode	=> 'record',
		adapter => 'LWP',
	);

	$sc->{adapter} = Local::MockAdapter1->new;

	ok(!defined($sc->_find_match({})), '_find_match returns undef when no interactions exist');
};

{
	package Local::MockAdapter2;
	use strict;
	use warnings;
	sub new { bless {}, shift }
	sub normalize_request {
		return { method => 'GET', uri => 'http://example.com/b' };
	}
}

subtest '_find_match returns first matching interaction' => sub {

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'match',
		file	=> 't/fixtures/match.yaml',
		mode	=> 'record',
		adapter => 'LWP',
	);

	$sc->{interactions} = [
		{
			request  => { method => 'GET', uri => 'http://example.com/a' },
			response => { status => 200 },
		},
		{
			request  => { method => 'GET', uri => 'http://example.com/b' },
			response => { status => 200 },
		},
	];

	$sc->{adapter} = Local::MockAdapter2->new;

	my $match = $sc->_find_match({});

	cmp_deeply(
		$match->{request},
		superhashof({ uri => 'http://example.com/b' }),
		'correct interaction matched'
	);

};

#----------------------------------------------------------------------#
# Serializer round-trip (pure)
#----------------------------------------------------------------------#

subtest 'YAML serializer round-trip' => sub {

	use_ok('Test::HTTP::Scenario::Serializer::YAML');

	my $ser = Test::HTTP::Scenario::Serializer::YAML->new;

	my $data = {
		name => 'roundtrip',
		interactions => [
			{
				request  => { method => 'GET', uri => 'http://x/' },
				response => { status => 200, body => 'ok' },
			},
		],
	};

	my $yaml = $ser->encode_scenario($data);
	ok($yaml, 'YAML encoded');

	my $decoded = $ser->decode_scenario($yaml);

	cmp_deeply($decoded, $data, 'YAML round-trip preserved structure');

};

done_testing;

