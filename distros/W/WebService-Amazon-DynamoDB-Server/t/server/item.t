use strict;
use warnings;

use utf8;

use Test::More;

use WebService::Amazon::DynamoDB::Server::Item;

use Encode;
use List::Util qw(sum);

# TODO Make more of these
for my $case (
	{ attributes => [ { key => 'abc', value => 'something', type => 'S' } ], total => 12 },
	{ attributes => [ { key => 'abc', value => '0', type => 'S' } ], total => 4 },
	{ attributes => [ { key => 'abc', value => '0', type => 'N' } ], total => 4 },
	{ attributes => [ { key => 'abc', value => '0', type => 'B' } ], total => 4 },
	# all list/map types have +3 to LEN
	{ attributes => [ { key => 'abc', value => [qw(abc def)], type => 'SS' } ], total => 12 },
	{ attributes => [ { key => 'abc', value => [qw(abc def something)], type => 'SS' } ], total => 21 },
	# boolean / null are 1
	{ attributes => [ { key => 'abc', value => 1, type => 'BOOL' } ], total => 4 },
	{ attributes => [ { key => 'abc', value => 1, type => 'NULL' } ], total => 4 },
	{ attributes => [
		{ key => 'abc',     value => 'dd', type => 'S' },
		{ key => 'def',     value => 'ee', type => 'S' },
		{ key => 'another', value => 'ff', type => 'S' },
		{ key => 'thing',   value => 'gg', type => 'S' },
	], total => 26 },
	{ attributes => [
		{ key => 'abc',     value => 'dd', type => 'S' },
		{ key => 'def',     value => 'ee', type => 'S' },
		{ key => 'ænöther', value => 'ff', type => 'S' },
		{ key => 'thing',   value => 'gg', type => 'S' },
	], total => 28 },
	{ attributes => [
		{ key => 'abc',     value => {
			one => { key => 'one', type => 'S', value => 'test' },
			two => { key => 'two', type => 'N', value => '123' },
			three => { key => 'three', type => 'BOOL', value => 0 },
		}, type => 'M' }
	], total => 25 },
) {
	my $item = new_ok('WebService::Amazon::DynamoDB::Server::Item', [
		attributes => $case->{attributes},
	]);
	is(
		$item->bytes_used->get,
		$case->{total},
		'correct size in bytes (' . $case->{total} . ')'
	) or note explain $case;
}

done_testing;

