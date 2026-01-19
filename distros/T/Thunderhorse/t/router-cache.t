use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests Router cache functionality
################################################################################

package PlainCache {
	use Mooish::Base -standard;

	has field '_cache' => (
		isa => HashRef,
		default => sub { {} },
	);

	sub get ($self, $key)
	{
		return $self->_cache->{$key};
	}

	sub set ($self, $key, $value)
	{
		$self->_cache->{$key} = $value;
	}

	sub clear ($self)
	{
		$self->_cache->%* = ();
	}
}

package SpecializedCache {
	use Mooish::Base -standard;

	extends 'PlainCache';
	with 'Thunderhorse::Router::SpecializedCache';
}

package TestApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/hello' => {
				to => sub ($self, $ctx) {
					return 'hello world';
				}
			}
		);

		$router->add(
			'/goodbye' => {
				to => sub ($self, $ctx) {
					return 'goodbye world';
				}
			}
		);
	}
}

subtest 'should work with plain cache' => sub {
	my $cache = PlainCache->new;
	my $app = TestApp->new;
	$app->router->set_cache($cache);

	subtest 'should cache route matches' => sub {
		# First request - should populate cache
		http $app, GET '/hello';
		http_status_is 200;
		http_header_is 'Content-Type', 'text/html; charset=utf-8';
		http_text_is 'hello world';

		# Verify cache was populated
		my $cached = $cache->get('SUPER::match;http.get;/hello');
		ok $cached, 'cache was populated';
		ok scalar($cached->@*), 'cache contains matches';

		# Second request - should use cache
		http $app, GET '/hello';
		http_status_is 200;
		http_text_is 'hello world';
	};

	subtest 'should cache different routes separately' => sub {
		http $app, GET '/goodbye';
		http_status_is 200;
		http_text_is 'goodbye world';

		# Verify both routes are cached
		my $hello_cached = $cache->get('SUPER::match;http.get;/hello');
		my $goodbye_cached = $cache->get('SUPER::match;http.get;/goodbye');

		ok $hello_cached, 'hello route still cached';
		ok $goodbye_cached, 'goodbye route cached';
	};

	subtest 'should clear cache' => sub {
		$cache->clear;

		# Verify cache is empty
		my $cached = $cache->get('SUPER::match;http.get;/hello');
		is $cached, undef, 'cache was cleared';

		# Should work after clearing
		http $app, GET '/hello';
		http_status_is 200;
		http_text_is 'hello world';
	};

	subtest 'should cache flat_match results' => sub {
		$cache->clear;

		# Call flat_match directly on the router
		my @matches = $app->router->flat_match('/hello', 'http.get');
		ok scalar(@matches), 'flat_match returned matches';

		# Verify cache was populated
		my $cached = $cache->get('SUPER::flat_match;http.get;/hello');
		ok $cached, 'flat_match cache was populated';
		ok scalar($cached->@*), 'cache contains matches';

		# Second call - should use cache
		my @matches2 = $app->router->flat_match('/hello', 'http.get');
		is scalar(@matches2), scalar(@matches), 'flat_match returned same number of matches';
	};
};

subtest 'should work with specialized cache' => sub {
	my $cache = SpecializedCache->new;
	my $app = TestApp->new;
	$app->router->set_cache($cache);

	subtest 'should cache route matches with specialized cache' => sub {
		# First request - should populate cache
		http $app, GET '/hello';
		http_status_is 200;
		http_header_is 'Content-Type', 'text/html; charset=utf-8';
		http_text_is 'hello world';

		# Verify cache was populated with serialized data
		my $cached = $cache->get('SUPER::match;http.get;/hello');
		ok $cached, 'cache was populated';
		ok scalar($cached->@*), 'cache contains matches';

		# Verify location is stored as name, not object
		is $cache->_cache->{'SUPER::match;http.get;/hello'}->[0][0]{location},
			'1_any_/hello',
			'location stored as name in cache';

		# Verify location returned as an object
		isa_ok $cached->[0][0]{location}, 'Thunderhorse::Router::Location';

		# Second request - should use cache and reconstruct objects
		http $app, GET '/hello';
		http_status_is 200;
		http_text_is 'hello world';
	};

	subtest 'should cache different routes separately with specialized cache' => sub {
		http $app, GET '/goodbye';
		http_status_is 200;
		http_text_is 'goodbye world';

		# Verify both routes are cached
		my $hello_cached = $cache->get('SUPER::match;http.get;/hello');
		my $goodbye_cached = $cache->get('SUPER::match;http.get;/goodbye');

		ok $hello_cached, 'hello route still cached';
		ok $goodbye_cached, 'goodbye route cached';
	};

	subtest 'should clear specialized cache' => sub {
		$cache->clear;

		# Verify cache is empty
		my $cached = $cache->get('SUPER::match;http.get;/hello');
		is $cached, undef, 'cache was cleared';

		# Should work after clearing
		http $app, GET '/hello';
		http_status_is 200;
		http_text_is 'hello world';
	};

	subtest 'should cache flat_match results with specialized cache' => sub {
		$cache->clear;

		# Call flat_match directly on the router
		my @matches = $app->router->flat_match('/hello', 'http.get');
		ok scalar(@matches), 'flat_match returned matches';

		# Verify cache was populated with serialized data
		my $cached = $cache->get('SUPER::flat_match;http.get;/hello');
		ok $cached, 'flat_match cache was populated';
		ok scalar($cached->@*), 'cache contains matches';

		# Verify location is stored as name, not object
		is $cache->_cache->{'SUPER::flat_match;http.get;/hello'}->[0]{location},
			'1_any_/hello',
			'location stored as name in cache';

		# Verify location returned as an object
		isa_ok $cached->[0]{location}, 'Thunderhorse::Router::Location';

		# Second call - should use cache and reconstruct objects
		my @matches2 = $app->router->flat_match('/hello', 'http.get');
		is $matches[0]->location->name, $matches2[0]->location->name, 'matched again ok';
	};
};

done_testing;

