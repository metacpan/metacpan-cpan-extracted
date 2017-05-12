use strict;
use warnings;

use Test::More;

use WebService::Amazon::DynamoDB::Server::Table;

# TODO Make more of these
for my $case ({
	total => 112,
	items => [
		{ attributes => [ { key => 'abc', value => 'something', type => 'S' } ] },
	],
}, {
	total => 229,
	items => [
		{ attributes => [ { key => 'abc', value => 'something', type => 'S' } ] },
		{ attributes => [ { key => 'abc', value => 'something else', type => 'S' } ] },
	],
}) {
	my $tbl = WebService::Amazon::DynamoDB::Server::Table->new(
		items => [ map WebService::Amazon::DynamoDB::Server::Item->new(%$_), @{$case->{items}} ]
	);
	is($tbl->bytes_used->get, $case->{total}, 'total bytes_used is correct (' . $case->{total} . ')') or note explain $case;
}

done_testing;

