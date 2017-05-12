use lib lib => 't/lib' => glob 'modules/*/lib';
use WebService::Qiita::Test;
use WebService::Qiita::Client::Base;

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional;
use JSON qw(encode_json);

subtest accessor => sub {
    my $client = WebService::Qiita::Client::Base->new({
        url_name => 'y_uuki_',
        password => 'mysecret',
        token    => 'authtoken',
    });

    is $client->url_name, 'y_uuki_';
    is $client->password, 'mysecret';
    is $client->token,    'authtoken';
};

subtest agent => sub {
    my $client = WebService::Qiita::Client::Base->new;
    my $agent = $client->agent;

    isa_ok $agent, 'LWP::UserAgent';
};

subtest request => sub {
    my $client = WebService::Qiita::Client::Base->new;

    subtest normal => sub {
        my $response = HTTP::Response->new(200);
        my $data_hashref = +{test => 'てすと'};
        $response->content(encode_json $data_hashref);

        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/hoge') => $response,
        );
        my $content = $client->_request('GET', '/hoge');

        is_deeply $content, $data_hashref;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest invalid_http_method => sub {
        like exception { $client->_request('INVALID', '/hoge'); }, qr(invalid http);
    };

    subtest defined_error => sub {
        my $response = HTTP::Response->new(400);
        my $data_hashref = +{error => 'えらー'};
        $response->content(encode_json $data_hashref);
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/hoge') => $response,
        );

        like exception { $client->_request('GET', '/hoge'); }, qr(えらー);
    };

    subtest undefined_error => sub {
        my $response = HTTP::Response->new(500);
        $response->content('');
        Test::Mock::LWP::Conditional->stub_request(
            api_endpoint('/hoge') => $response,
        );

        like exception { $client->_request('GET', '/hoge'); }, qr(GET .+ 500);
    };
};

done_testing;
__END__
