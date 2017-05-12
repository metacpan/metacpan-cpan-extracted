use lib lib => 't/lib' => glob 'modules/*/lib';
use WebService::Qiita::Test qw(client api_endpoint);
use WebService::Qiita;
use WebService::Qiita::Client::Users;

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional;

use HTTP::Response;
use JSON qw(decode_json);
use Path::Class qw(file);


subtest post_item => sub {
    my $params = +{
        title   => 'テスト',
        body    => 'fooooooooo',
        tags    => [ {name => 'FOOBAR', versions => ['1.2', '1.3']} ],
        private => $JSON::false,
        gist    => $JSON::true,
        tweet   => $JSON::true,
    };
    my $data = file('t/data/post_item')->slurp;
    my $response = HTTP::Response->new(201);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint('/items') => $response,
    );
    my $client = client(token => 'auth');
    my $items = $client->post_item($params);

    is_deeply $items, $data_arrayref;

    Test::Mock::LWP::Conditional->reset_all;
};


subtest update_item => sub {
    my $uuid = "4f5826020e3e64b29fba";
    my $params = +{
        title   => 'テスト',
        body    => 'fooooooooo',
        tags    => [ {name => 'FOOBAR', versions => ['1.2', '1.3']} ],
        private => $JSON::false,
        gist    => $JSON::true,
        tweet   => $JSON::true,
    };
    my $data = file('t/data/update_item')->slurp;
    my $response = HTTP::Response->new(200);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/items/$uuid") => $response,
    );
    my $client = client(token => 'auth');
    my $items = $client->update_item($uuid, $params);

    is_deeply $items, $data_arrayref;

    Test::Mock::LWP::Conditional->reset_all;
};

subtest delete_item => sub {
    my $uuid = "4f5826020e3e64b29fba";
    my $response = HTTP::Response->new(204);

    my $client = client(token => 'auth');
    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/items/$uuid?token=" . $client->token) => $response,
    );
    my $items = $client->delete_item($uuid);

    is $items, "";
    Test::Mock::LWP::Conditional->reset_all;
};

subtest item => sub {
    my $uuid = "dd4fce78b1bc32b64600";
    my $data = file('t/data/item')->slurp;
    my $response = HTTP::Response->new(200);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    subtest instance_method => sub {
        my $client = client(token => 'auth');
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint("/items/$uuid?token=" . $client->token) => $response,
        );
        my $items = $client->item($uuid);

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest class_method => sub {
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint("/items/$uuid") => $response,
        );
        my $items = WebService::Qiita->item($uuid);

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };
};

subtest search_item => sub {
    my $query = 'perl';
    my $data = file('t/data/search_items')->slurp;
    my $response = HTTP::Response->new(200);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    subtest instance_method => sub {
        my $client = client(token => 'auth');
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint("/search?q=$query&token=" . $client->token) => $response,
        );
        my $items = $client->search_items($query);

        is_deeply $items, $data_arrayref;
    };

    subtest class_method => sub {
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint("/search?q=$query") => $response,
        );
        my $items = WebService::Qiita->search_items($query);

        is_deeply $items, $data_arrayref;
    };
    Test::Mock::LWP::Conditional->reset_all;
};

subtest stock_item => sub {
    my $uuid = "dd4fce78b1bc32b64600";
    my $response = HTTP::Response->new(204);

    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/items/$uuid/stock") => $response,
    );
    my $client = client(token => 'auth');
    my $items = $client->stock_item($uuid);

    is_deeply $items, "";

    Test::Mock::LWP::Conditional->reset_all;
};

subtest unstock_item => sub {
    my $uuid = "dd4fce78b1bc32b64600";
    my $response = HTTP::Response->new(204);

    my $client = client(token => 'auth');
    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/items/$uuid/unstock?token=" . $client->token) => $response,
    );
    my $items = $client->unstock_item($uuid);

    is_deeply $items, "";

    Test::Mock::LWP::Conditional->reset_all;
};

done_testing;
__END__
