use strict;
use warnings;

use Test::More;

use HTTP::Tiny;
use Test::Mock::HTTP::Tiny;

is_deeply(Test::Mock::HTTP::Tiny->mocked_data, [],
	'There is no mocked data initially');

my $mocked_data = [
	{
		url      => 'http://test1',
        method   => 'GET',
        args     => { },
        response => {
        	content => 'test1',
        },
	},
	{
		url      => 'http://test2',
        method   => 'GET',
        args     => { },
        response => {
        	content => 'test2',
        },
	},
	{
		url      => 'http://test3',
        method   => 'GET',
        args     => { },
        response => {
        	content => 'test3',
        },
	}
];

Test::Mock::HTTP::Tiny->set_mocked_data($mocked_data);

is_deeply(Test::Mock::HTTP::Tiny->mocked_data, $mocked_data,
	'Mocked data matches what was set');

my $response = HTTP::Tiny->new->request($mocked_data->[0]{method},
	$mocked_data->[0]{url});

is_deeply($response, $mocked_data->[0]{response},
	'The expected response is returned');

splice(@$mocked_data, 0, 1);
is_deeply(Test::Mock::HTTP::Tiny->mocked_data, $mocked_data,
	'The first item has been removed from mocked data');

my $mock_item = {
	url      => 'http://test4',
    method   => 'GET',
    args     => { },
    response => {
    	content => 'test4',
    },
};

Test::Mock::HTTP::Tiny->append_mocked_data($mock_item);

push @$mocked_data, $mock_item;
is_deeply(Test::Mock::HTTP::Tiny->mocked_data, $mocked_data,
	'A new item has been added to mocked data');

Test::Mock::HTTP::Tiny->clear_mocked_data;

is_deeply(Test::Mock::HTTP::Tiny->mocked_data, [],
	'Mocked data is empty after clearing');

done_testing;
