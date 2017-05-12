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
			put_item => 6
		};
	};
	ok($srv->have_table('test'), 'have starting table');

	like(exception {
		$srv->put_item(
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with no table');
	like(exception {
		$srv->put_item(
			TableName => 'missing'
		)->get;
	}, qr/ResourceNotFoundException/, 'exception with missing table');
	like(exception {
		$srv->put_item(
			TableName => 'test',
		)->get;
	}, qr/ResourceInUseException/, 'exception when table is not ACTIVE');

	is(exception {
		$srv->table_status(test => 'ACTIVE')->get
	}, undef, 'mark table as active');

	like(exception {
		$srv->put_item(
			TableName => 'test',
			Item => {
			}
		)->get;
	}, qr/ValidationException/, 'exception when primary key is missing');

	is(exception {
		my $data = $srv->put_item(
			TableName => 'test',
			Item => {
				id => { S => "1" }
			}
		)->get;
		isa_ok($data, 'HASH');
		cmp_deeply($data, { }, 'nothing returned');
	}, undef, 'no exception when primary key is provided');

	is(exception {
		my $details = $srv->describe_table(
			TableName => 'test'
		)->get->{Table};
		is($details->{ItemCount}, 1, 'have an item');
		cmp_ok($details->{TableSizeBytes}, '>', 0, 'table size is nonzero');
	}, undef, 'describe table');
	is(exception {
		my $data = $srv->put_item(
			TableName => 'test',
			Item => {
				id => { S => "1" }
			},
			ReturnValues => 'ALL_OLD',
		)->get;
		isa_ok($data, 'HASH');
		cmp_deeply($data, { Attributes => { } }, 'had attributes in response');
	}, undef, 'no exception on put');
	is(exception {
		my $details = $srv->describe_table(
			TableName => 'test'
		)->get->{Table};
		is($details->{ItemCount}, 1, 'still have one item');
		cmp_ok($details->{TableSizeBytes}, '>', 0, 'table size is nonzero');
	}, undef, 'describe table');
}

done_testing;

