#!perl -T

use Test::More;

unless($ENV{BILLOMAT_ID} && $ENV{BILLOMAT_KEY}) {
	plan( skip_all =>
		"Set BILLOMAT_ID and BILLOMAT_KEY to run live tests"
	);
} else {
	plan( tests => 10 );
}

use WWW::Billomat;

my $billomat = WWW::Billomat->new(
	billomat_id => $ENV{BILLOMAT_ID},
	api_key => $ENV{BILLOMAT_KEY},
);
isa_ok($billomat, 'WWW::Billomat', 'WWW::Billomat object instantiated');

my $client = $billomat->create_client(
	WWW::Billomat::Client->new(
		name => "WWW::Billomat test $$",
		first_name => 'Arthur',
		last_name => 'Dent',
	)
);
ok(defined($client), 'client created successfully');
isa_ok($client, 'WWW::Billomat::Client', 'client isa WWW::Billomat::Client');
is($client->name, "WWW::Billomat test $$",
	'client name is what we expect'
);

$client->first_name('Zaphod');
$client->last_name('Beeblebrox');
ok($billomat->edit_client($client), 'client modified successfully');

my @clients = $billomat->get_clients( name => "WWW::Billomat test $$" );
is(@clients, 1, 'client found');
is($clients[0]->id, $client->id, 'id is the same');
is($clients[0]->first_name(), 'Zaphod', 'first_name has been modified');
 
ok( $billomat->delete_client($client), 'client deleted successfully');

my @empty = $billomat->get_clients( name => "WWW::Billomat test $$" );

is(@empty, 0, 'client really deleted');
