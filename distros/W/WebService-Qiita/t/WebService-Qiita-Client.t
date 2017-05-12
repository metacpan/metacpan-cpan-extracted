use lib lib => 't/lib' => glob 'modules/*/lib';
use WebService::Qiita::Test;
use WebService::Qiita;
use WebService::Qiita::Client;

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional;

use HTTP::Response;
use JSON;
use Path::Class qw(file);

subtest accessor => sub {
    my $client = WebService::Qiita::Client->new({
        url_name => 'y_uuki_',
        password => 'mysecret',
        token    => 'authtoken',
    });

    is $client->url_name, 'y_uuki_';
    is $client->password, 'mysecret';
    is $client->token,    'authtoken';
    isa_ok $client, 'WebService::Qiita::Client::Base';
};

subtest token => sub {
    my $response = HTTP::Response->new(200);
    my $json = JSON::encode_json(+{url_name => 'y_uuki_', token => 'yoursecrettoken'});
    $response->content($json);
    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/auth") => $response,
    );

    my $client = WebService::Qiita::Client->new({
        url_name => 'y_uuki_',
        password => 'mysecret',
    });

    is $client->url_name, 'y_uuki_';
    is $client->password, 'mysecret';
    is $client->token,    'yoursecrettoken';
};

subtest rate_limit => sub {
    my $response = HTTP::Response->new(200);
    my $data = file('t/data/rate_limit')->slurp;
    $response->content($data);
    my $data_arrayref = decode_json($data);

    Test::Mock::LWP::Conditional->stub_request(
        api_endpoint("/rate_limit") => $response,
    );

    my $limit = WebService::Qiita->rate_limit;

    is_deeply $limit, $data_arrayref;

    Test::Mock::LWP::Conditional->reset_all;
};

done_testing;
__END__
