use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Future;
use Future::Utils qw(fmap repeat call);

use WebService::Amazon::DynamoDB::Server;
use Test::WebService::Amazon::DynamoDB::Server;

{
	my $srv = ddb_server {
		expect_events {
			create_table => 9
		};
	};

	like(exception {
		$srv->create_table->get
	}, qr/ValidationException/, 'exception when creating without AttributeDefinitions');

	like(exception {
		$srv->create_table(
			AttributeDefinitions => [],
		)->get
	}, qr/ValidationException/, 'exception when creating without KeySchema');

	like(exception {
		$srv->create_table(
			AttributeDefinitions => [],
			KeySchema => [],
		)->get
	}, qr/ValidationException/, 'exception when creating with empty KeySchema');

	like(exception {
		$srv->create_table(
			AttributeDefinitions => [],
			KeySchema => [ {
				AttributeName => 'id',
				KeyType => 'HASH'
			} ],
		)->get
	}, qr/ValidationException/, 'exception when creating with KeySchema referring to missing attribute');

	like(exception {
		$srv->create_table(
			AttributeDefinitions => [ {
				AttributeName => 'id',
				AttributeType => 'S',
			} ],
			KeySchema => [ {
				AttributeName => 'id',
				KeyType => 'BAD'
			} ],
		)->get
	}, qr/ValidationException.*KeyType.*HASH/, 'exception when creating with invalid key type');

	like(exception {
		$srv->create_table(
			AttributeDefinitions => [ {
				AttributeName => 'id',
				AttributeType => 'S',
			} ],
			KeySchema => [ {
				AttributeName => 'id',
				KeyType => 'HASH'
			} ],
		)->get
	}, qr/ValidationException/, 'exception when creating without ProvisionedThroughput');

	my %args = (
		AttributeDefinitions => [ {
			AttributeName => 'id',
			AttributeType => 'S',
		} ],
		KeySchema => [ {
			AttributeName => 'id',
			KeyType => 'HASH'
		} ],
	);

	$args{ProvisionedThroughput} = {
		ReadCapacityUnits => "5",
		WriteCapacityUnits => "5",
	};
	like(exception {
		$srv->create_table(
			%args,
		)->get
	}, qr/ValidationException/, 'exception when creating without TableName');

	$args{TableName} = 'test_table';
	is(exception {
		my ($create) = $srv->create_table(
			%args,
		)->get;
		isa_ok($create, 'HASH');
		ok(exists $create->{TableDescription}, 'have TableDescription') or note explain $create;
		cmp_deeply([ keys %$create ], bag('TableDescription'), 'no other keys');
		my $spec = $create->{TableDescription};
		cmp_deeply($spec->{$_}, $args{$_}, "$_ matches") for sort keys %args;
		is($spec->{ItemCount}, 0, 'zero item count');
		is($spec->{TableSizeBytes}, 0, 'zero size');
		is($spec->{TableStatus}, 'CREATING', 'starts as CREATING status');
		cmp_ok(abs(Time::Moment->from_string($spec->{CreationDateTime})->epoch - time), '<=', 10, 'creation time is about right');
	}, undef, 'no exception when creating with all required parameters');

	ok($srv->have_table('test_table'), 'table is now found');

	like(exception {
		$srv->create_table(
			%args,
		)->get;
	}, qr/ResourceInUseException/, 'exception when creating duplicate table');
}

done_testing;

