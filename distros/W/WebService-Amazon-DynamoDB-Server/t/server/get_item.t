use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Future;

use WebService::Amazon::DynamoDB::Server;
use Test::WebService::Amazon::DynamoDB::Server;

{
	my $srv = ddb_server {
		shift->create_table(
			TableName => 'test',
			AttributeDefinitions => [ {
				AttributeName => 'id',
				AttributeType => 'S',
			} ],
			KeySchema => [ {
				AttributeName => 'id',
				KeyType => 'HASH'
			} ],
			ProvisionedThroughput => {
				ReadCapacityUnits => "5",
				WriteCapacityUnits => "5",
			}
		);
		expect_events {
			get_item => 4
		};
	};
	ok($srv->have_table('test'), 'have starting table');

	like(exception {
		$srv->get_item(
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with no table');
	like(exception {
		$srv->get_item(
			TableName => 'missing'
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with missing table');
	like(exception {
		$srv->get_item(
			TableName => 'test',
		)->get;
	}, qr/ResourceInUseException/, 'exception when table is not ACTIVE');

	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'mark table as active');

	like(exception {
		$srv->get_item(
			TableName => 'test',
			Item => {
			}
		)->get;
	}, qr/ValidationException/, 'exception when primary key is missing');
}

done_testing;

