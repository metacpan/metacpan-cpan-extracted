use strict;
use warnings;
use Test::More;

use WebService::Qiita::V2;

my $client = WebService::Qiita::V2->new;

my $dummy_token = '0123456789abcdef0123456789abcdef01234567';

is $client->{token}, undef;

$client->{token} = $dummy_token;

is $client->{token}, $dummy_token;
is $client->get_authenticated_user, -1;
is_deeply $client->get_error, {
    url     => 'https://qiita.com/api/v2/authenticated_user',
    content => {
        message => 'Unauthorized',
        type    => 'unauthorized',
    },
    method  => 'GET',
    code    => 401,
};

done_testing;
