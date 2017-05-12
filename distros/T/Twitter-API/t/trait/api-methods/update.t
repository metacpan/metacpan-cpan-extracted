#!perl
use 5.14.1;
use warnings;
use Test::Spec;

use Twitter::API;

describe update => sub {
    my $client;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits              => 'ApiMethods',
            consumer_key        => 'key',
            consumer_secret     => 'secret',
            access_token        => 'token',
            access_token_secret => 'token-secret',
        );
        $client->stubs(send_request => sub { return });
    };

    it 'flattens media_ids' => sub {
        my $req;

        my $context = $client->update('hello world', {
            media_ids => [ 1..3 ],
        });

        is_deeply $context->args, {
            status    => 'hello world',
            media_ids => '1,2,3',
        };
    };
};

runtests;
