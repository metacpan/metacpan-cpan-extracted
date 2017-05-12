package MyUAConfigDefaults;

use Test::Override::UserAgent for => 'configuration';

# Disallow live requests
allow_live(0);

# localhost overrides
override_for host => 'localhost', sub {
	# Just path
	override_request path => '/', sub {
		return [200, ['Content-Type' => 'text/plain'], ['override']];
	};

	# GET overrides
	override_for method => 'GET', sub {
		override_request path => '/only.get', sub {
			return [200, ['Content-Type' => 'text/plain'], ['override']];
		};
	};

	override_request path => '/all.methods', sub {
		return [200, ['Content-Type' => 'text/plain'], ['override']];
	};

	# Reoverride host
	override_for host => 'someplace', sub {
		override_request path => '/other', sub {
			return [200, ['Content-Type' => 'text/plain'], ['override']];
		};
	};
};

1;
