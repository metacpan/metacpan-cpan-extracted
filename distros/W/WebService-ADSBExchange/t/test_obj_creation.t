use WebService::ADSBExchange;
use Test2::V0;

ok(
	lives {
		WebService::ADSBExchange->new( key => 'test_key' );
	},
	"Sending string for key successful"
) or note($@);

ok(
	lives {
		my $bad = WebService::ADSBExchange->new(
			key     => 'test_key',
			api_url => 'nowhere.google.com'
		);
		$bad->aircraft_by_callsign('twine31');
	},
	"Bad API url does not die"
) or note($@);

like(
	dies {
		WebService::ADSBExchange->new();
	},
	qr/You did not specify your API key/,
	"Dies on no key as expected",
);

done_testing;
