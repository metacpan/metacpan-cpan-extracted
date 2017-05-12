use lib lib => 't/lib' => glob 'modules/*/lib';
use WebService::Qiita::Test qw(client api_endpoint);
use WebService::Qiita;
use WebService::Qiita::Client::Tags;

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional qw(stub_request);

use HTTP::Response;
use JSON qw(decode_json);
use Path::Class qw(file);


subtest tag_items => sub {
    my $data = file('t/data/tag_items')->slurp;
    my $response = HTTP::Response->new(200);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    subtest instance_method => sub {
        my $client = client(token => 'auth');
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/tags/perl/items?token=' . $client->token) => $response,
        );
        my $items = $client->tag_items('perl');

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest class_method => sub {
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/tags/perl/items') => $response,
        );
        my $items = WebService::Qiita->tag_items('perl');

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };
};

subtest tags => sub {
    my $data = file('t/data/tags')->slurp;
    my $response = HTTP::Response->new(200);
    $response->content($data);

    my $data_arrayref = decode_json($data);

    subtest instance_method => sub {
        my $client = client(token => 'auth');
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/tags?token=' . $client->token) => $response,
        );
        my $items = $client->tags;

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest class_method => sub {
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/tags') => $response,
        );
        my $items = WebService::Qiita->tags;

        is_deeply $items, $data_arrayref;

        Test::Mock::LWP::Conditional->reset_all;
    };
};

done_testing;
__END__
