use strict;
use warnings;

use Test2::V0 -target => 'WebService::Pixela::Webhook';

use JSON;
use WebService::Pixela;

my $username = 'testuser';
my $token    = 'thisistoken';

subtest 'use_methods' => sub {
    can_ok($CLASS,qw/new client create get invoke delete hash/);
};

subtest 'new_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    ok( my $obj = $CLASS->new($pixela), 'create instance');
    isa_ok($obj->{client}, [qw/WebService::Pixela/], 'client is WebService::Pixela');
};

subtest 'client_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    isa_ok($pixela->webhook->client,[qw/WebService::Pixela/], 'cient is WebService::Pixela');
};

subtest 'hash_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    isa_ok($pixela->webhook->hash('test_hash'),[qw/WebService::Pixela::Webhook/], 'return $self');
    is($pixela->webhook->hash(),'test_hash', 'return hash_value');
};

subtest 'croak_create_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    like( dies {$pixela->webhook->create()}, qr/require graph_id/, 'require graph_id');
    like( dies {$pixela->webhook->create(graph_id => 'test')}, qr/require type/, 'require type');
    like( dies {$pixela->webhook->create(graph_id => 'test', type => 'invalid')}, qr/invalid type/, 'invalid type');
};

subtest 'create_method_use_decode' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return {
                    isSuccess   => 1,
                    webhookHash => [@_],
                };
            }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    my %args = (
        type => 'Increment',
    );

    $pixela->graph->id('mock_id');
    create_method_true_test_helper($pixela,%args);

    $pixela = WebService::Pixela->new(username => $username, token => $token);
    $args{graph_id} = 'mock_id';
    create_method_true_test_helper($pixela,%args);
};

sub create_method_true_test_helper {
    my ($pixela,%args) = @_;

    is($pixela->webhook->hash(),undef,'not set hash');

    my $path = "users/$username/webhooks";
    my $mock_hash = ['POST',$path,{type => 'increment', graphID => 'mock_id'}];

    is($pixela->webhook->create(%args),
        { isSuccess   => 1,
          webhookHash => $mock_hash,
        },
        'create_method'
    );

    is($pixela->webhook->hash(),$mock_hash,'setting hash response');
}

subtest 'create_method_not_decode' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return encode_json({
                    isSuccess   => 1,
                    webhookHash => [@_],
                });
            }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    $pixela->decode(0);

    my %args = (
        type     => 'Increment',
        graph_id => 'mock_id',
    );

    my $path = "users/$username/webhooks";
    my $mock_hash = ['POST',$path,{type => 'increment', graphID => 'mock_id'}];

    my $mock_json = encode_json({ isSuccess   => 1,webhookHash => $mock_hash});

    is( decode_json($pixela->webhook->create(%args) ),
            {
                isSuccess   => 1,
                webhookHash => $mock_hash,
            },
        'create_method'
    );

    is($pixela->webhook->hash(),$mock_hash,'setting hash response');
};

subtest 'get_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return {
                    isSuccess => 1,
                    webhooks  => [@_],
                };
            }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    my $path      = "users/$username/webhooks/";
    my $mock_hash = ['GET',$path];

    is($pixela->webhook->get(),$mock_hash,'get methods use decode');

    $pixela->decode(0);

    $mock_hash = { isSuccess => 1, webhooks => ['GET',$path]};

    is($pixela->webhook->get(),$mock_hash,'get methods unde decode');
};

subtest 'invoke_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_content_length_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    like( dies {$pixela->webhook->delete()}, qr/require webhookHash/, 'require webhookHash');

    my $hash_mock = 'hash_mock';
    my $path      = "users/$username/webhooks/$hash_mock";
    my $mock_hash = ['POST',$path,0];

    is($pixela->webhook->invoke($hash_mock),$mock_hash,'invoke methods use arg hash');

    $pixela->webhook->hash($hash_mock);

    is($pixela->webhook->invoke(),$mock_hash,'invoke methods not use arg hash');
};

subtest 'delete_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    like( dies {$pixela->webhook->delete()}, qr/require webhookHash/, 'require webhookHash');

    my $hash_mock = 'hash_mock';
    my $path      = "users/$username/webhooks/$hash_mock";
    my $mock_hash = ['DELETE',$path];

    is($pixela->webhook->delete($hash_mock),$mock_hash,'delete methods use arg hash');

    $pixela->webhook->hash($hash_mock);

    is($pixela->webhook->delete(),$mock_hash,'delete methods not use arg hash');
};

done_testing;
