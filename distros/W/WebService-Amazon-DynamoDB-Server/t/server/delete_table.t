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
			delete_table => 4,
		}
	};
	ok($srv->have_table('test'), 'have starting table');

	like(exception {
		$srv->delete_table(
			TableName => 'test'
		)->get;
	}, qr/ResourceInUseException/, 'exception when table is not yet active');

	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'mark table as active');

	is(exception {
		$srv->delete_table(
			TableName => 'test'
		)->get;
	}, undef, 'no exception when table is active');

	is(exception {
		is($srv->table_status(test =>)->get, 'DELETING', 'table is now deleting');
	}, undef, 'no exception when reading table status');

	is(exception {
		$srv->delete_table(
			TableName => 'test'
		)->get;
	}, undef, 'no exception when table is deleting');

	is(exception {
		$srv->drop_table(TableName => 'test')->get
	}, undef, 'drop the table');

	like(exception {
		$srv->describe_table(
			TableName => 'test'
		)->get;
	}, qr/ResourceNotFoundException/, 'exception on describe after purging table');
	like(exception {
		$srv->delete_table(
			TableName => 'test'
		)->get;
	}, qr/ResourceNotFoundException/, 'exception on delete after purging table');
}

done_testing;

