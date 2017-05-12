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
			describe_table => 4
		};
	};
	ok($srv->have_table('test'), 'have starting table');

	like(exception {
		$srv->describe_table(
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with no table name');
	like(exception {
		$srv->describe_table(
			TableName => 'missing'
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with non-existing table');
	like(exception {
		$srv->describe_table(
			TableName => 'test'
		)->get;
	}, qr/ResourceInUseException/, 'exception with table that is still being created');
	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'mark table as active');
	is(exception {
		$srv->describe_table(
			TableName => 'test'
		)->get;
	}, undef, 'no exception on valid table');
}

done_testing;

