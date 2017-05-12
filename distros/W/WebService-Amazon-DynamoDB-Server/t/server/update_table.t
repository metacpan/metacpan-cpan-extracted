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
			update_table => 3
		}
	};
	ok($srv->have_table('test'), 'have starting table');

	like(exception {
		$srv->update_table(
			TableName => 'test'
		)->get;
	}, qr/ResourceInUseException/, 'exception when table is not yet active');

	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'mark table as active');

	is(exception {
		my $details = $srv->describe_table(TableName => 'test')->get->{Table};
		is($details->{ProvisionedThroughput}{ReadCapacityUnits}, 5, 'start off with 5 read units');
		is($details->{ProvisionedThroughput}{WriteCapacityUnits}, 5, 'start off with 5 write units');
	}, undef, 'no exception on ->describe_table');

	is(exception {
		$srv->update_table(
			TableName => 'test',
			ProvisionedThroughput => {
				ReadCapacityUnits => "7",
				WriteCapacityUnits => "3",
			}
		)->get;
	}, undef, 'no exception on valid update');

	is(exception {
		is($srv->table_status(test =>)->get, 'UPDATING', 'table is now updating');
	}, undef, 'no exception when reading table status');
	like(exception {
		$srv->update_table(
			TableName => 'test',
			ProvisionedThroughput => {
				ReadCapacityUnits => "2",
				WriteCapacityUnits => "9",
			}
		)->get;
	}, qr/ResourceInUseException/, 'exception when table is updating');

	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'no exception when marking table ACTIVE again');

	is(exception {
		my $details = $srv->describe_table(TableName => 'test')->get->{Table};
		is($details->{ProvisionedThroughput}{ReadCapacityUnits}, 7, 'now have 7 read units');
		is($details->{ProvisionedThroughput}{WriteCapacityUnits}, 3, 'now have 3 write units');
	}, undef, 'no exception on ->describe_table');
}

done_testing;

