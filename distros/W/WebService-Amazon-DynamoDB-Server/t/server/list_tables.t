use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Future;
use Future::Utils qw(fmap repeat call);

use WebService::Amazon::DynamoDB::Server;
use Test::WebService::Amazon::DynamoDB::Server;

{ # Simple list, no pagination
	my @tables = qw(first second third fourth fifth sixth);
	my $srv = ddb_server {
		add_table name => $_ for qw(first second third fourth fifth sixth);
		expect_events {
			list_tables => 5
		}
	};

	is(exception {
		cmp_deeply($srv->list_tables->get->{TableNames}, bag(@tables), "have expected tables");
	}, undef, 'no exception when listing all tables');

	is(exception {
		cmp_deeply([
			(fmap_over {
				my $last = shift;
				$srv->list_tables(
					Limit => 2,
					($last && exists $last->{LastEvaluatedTableName})
					? (ExclusiveStartTableName => $last->{LastEvaluatedTableName})
					: ()
				)->on_done(sub {
					my $data = shift;
					ok(ref $data eq 'HASH', 'had a hash');
					ok(exists $data->{TableNames}, 'have TableNames key');
					is(@{$data->{TableNames}}, 2, 'only two items in the list');
				})
			} while => sub { exists shift->{LastEvaluatedTableName} },
			  map => sub { @{shift->{TableNames}} }
			)->get
		], bag(@tables), "have expected tables when paging");
	}, undef, 'no exception when listing paginated tables');

	# We should get some sort of error with an invalid starting table
	like(exception {
		$srv->list_tables(
			ExclusiveStartTableName => 'does_not_exist'
		)->get
	}, qr/ValidationException/, 'bad starting table name raises exception');

}

done_testing;

