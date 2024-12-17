use Test::More;

use WebService::Chroma;
=pod
my $chroma = WebService::Chroma->new();

my $version = $chroma->version();

diag explain $version;

#my $reset = $chroma->reset();

#diag explain $reset;

my $heartbeat = $chroma->heartbeat();

diag explain $heartbeat;

my $pre_flight = $chroma->pre_flight_checks();

diag explain $pre_flight;

my $auth_identity = $chroma->auth_identity();

diag explain $auth_identity;

my $tenant = $chroma->get_tenant(
	name => 'testing-tenant'
);

my $db = $tenant->get_database(
	name => 'testing-db'
);

#$db->create_collection(
#	name => 'my-collection'
#);

diag explain $db->get_collections();

my $collection = $db->get_collection(name => 'my-collection');

diag explain $collection;

$collection->delete(
	ids => [ "1", "2" ],
);

diag explain $collection->add(
	embeddings => [
		[1.1, 2.3, 3.2],
		[2.1, 3.3, 4.2],
	],
	documents => [
		'a blue scarf, a red hat, a wolly jumper, black gloves',
		'a pink scarf, a blue hat, a wolly jumper, green gloves'
	],
	ids => [
		"1",
		"2"
	]
);

diag explain $collection->get(
	ids => [
		"1"
	]
);

diag explain $collection->query(
  "query_embeddings"=> [
	[2.1, 3.3, 4.2],
  ],
  "n_results"=> 1,
  "include"=> [
    "metadatas",
    "documents",
    "distances"
  ]
);

=cut

ok(1);

done_testing();
