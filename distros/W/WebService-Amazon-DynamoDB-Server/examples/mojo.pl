#!/usr/bin/env perl 
use strict;
use warnings;
use WebService::Amazon::DynamoDB;
use curry;

my $ddb = WebService::Amazon::DynamoDB->new(
	implementation => 'WebService::Amazon::DynamoDB::MojoUA',
	version        => '20120810',
	access_key     => 'access_key',
	secret_key     => 'secret_key',
	host           => 'localhost',
	port           => 8000,
);

# First we create a table with a single hash-indexed field:
# my $table_name = 'existing_table';
my $table_name = join '_', 'test', $$, time;
my $f = $ddb->create_table(
	table => $table_name,
	fields => [
		name => 'S',
	],
	primary => [
		name => 'HASH',
	],
	secondary => [ ],
)->then(sub {
	# Table creation is an async process, so we may not be ready to use
	# it just yet - wait => 1 on the create_table will defer completion
	# until the table is ready, or we can do this step manually:
	$ddb->wait_for_table(table => $table_name)
})->then(sub {
	# Once we've created the table, it should show up in the list of available
	# tables, so let's test that. We may have lots of tables in place, so we
	# can control how many each request returns by using the 'limit' option.
	my @pending;
	push @pending, $ddb->each_table(sub {
		my $tbl = shift;
		warn "Had table: [$tbl]\n";
#		push @pending, $ddb->delete_table(name => $name);
	}, limit => 5);
	Future->needs_all(@pending)
})->then(sub {
	# Write a single value to our new table.
	$ddb->put_item(
		table => $table_name,
		fields => {
			name => 'some test name here',
			age => 123,
		},
	);
})->then(sub {
	# Read the value back from our table - we only expect a single value but
	# we'll use the batch API for variety
	$ddb->batch_get_item(
		sub {
			my $tbl = shift;
			my $data = shift;
			warn "Batch get: $tbl had " . join(',', %$data) . "\n";
		},
		items => {
			$table_name => {
				keys => [
					name => 'some test name here',
				],
				fields => [qw(name age)],
			}
		},
	)
})->then(sub {
	# Clean up after ourselves by removing the table
	$ddb->delete_table(table => $table_name)
})->on_done(sub { warn "finished\n"})
->on_fail(sub { die "@_" });

