use strict;
use warnings;

use Test2::V0 -target => 'WebService::Pixela';

use JSON;
use WebService::Pixela;

subtest 'create_instance_success' => sub {
    ok (my $obj = $CLASS->new(username => 'test', token => 'testtoken'),
        q{ create_instance_success(input username and token) });
    isa_ok( $obj, [$CLASS],"create instance at WebService::Pixela");
};

subtest 'use_methods' => sub {
    can_ok($CLASS,qw/username token base_url decode user graph pixel webhook _agent/);
};

subtest 'method by each instance' => sub {
    my $obj = $CLASS->new(username => 'test', token => 'testtoken');
    isa_ok( $obj->user,    [qw/WebService::Pixela::User/], "create instance at WebService::Pixela");
    isa_ok( $obj->graph,   [qw/WebService::Pixela::Graph/],"create instance at WebService::Pixela");
    isa_ok( $obj->pixel,   [qw/WebService::Pixela::Pixel/],"create instance at WebService::Pixela");
    isa_ok( $obj->webhook, [qw/WebService::Pixela::Webhook/],"create instance at WebService::Pixela");
    isa_ok( $obj->_agent,  [qw/HTTP::Tiny/],"_agent is HTTP::Tiny instance");
};

subtest 'Whether the entered value is properly set' => sub {
    my %params = ( username => 'test', token => 'testtoken', base_url => 'http://example.com' , decode => 0);
    my $obj = $CLASS->new(username => $params{username}, token => $params{token}, base_url => $params{base_url}, decode => $params{decode});
    for my $key (keys %params){
        is ( [$obj->$key, $obj->{$key}], [($params{$key}) x 2], "$key is properly set.");
    }
};

subtest 'Test of new method call without argument' => sub {
    like( dies { $CLASS->new(); }, qr/require username/, "Not intput username" );
    like( warning { $CLASS->new(username => 'test'); }, qr/not input token/, "No input token");
    is($CLASS->new(username => 'test', token => 'testtoken')->base_url, 'https://pixe.la/', "base_url is pixe.la url");
    is($CLASS->new(username => 'test', token => 'testtoken')->decode , '1', "decode json mode");
};

subtest '_decode_or_simple_return_from_json' => sub {
    my $json_mock = encode_json({test => 'example'});
    my $obj = $CLASS->new(username => 'test', token => 'testtoken');

    is($obj->_decode_or_simple_return_from_json($json_mock), decode_json($json_mock), 'default decode_json');
    $obj->decode(0);
    is($obj->_decode_or_simple_return_from_json($json_mock), $json_mock, 'return simple json');
};

subtest '_request tests' => sub {
    my $http_mock = mock 'HTTP::Tiny' => (
        override => [request => 
            sub {
                shift @_;
                return ({content => ['HTTP::Tiny',@_]});
            }],
    );

    my $json_mock = mock $CLASS => (
        override => [ _decode_or_simple_return_from_json =>
            sub {
                my ($self,$array_ref) = @_;
                return (@$array_ref);
            }],
    );

    my $obj = $CLASS->new(username => 'test', token => 'testtoken');
    is [$obj->_request('POST','testpath',encode_json({test => 'example'}))], ['HTTP::Tiny', 'POST','https://pixe.la/v1/testpath',encode_json({test => 'example'})];
};


subtest 'query_request test' => sub {
    my $mock = mock 'HTTP::Tiny'  => (
        override => [ request =>
            sub {
                shift @_;
                return {content => [@_]};
            }],
    );
    my $obj = $CLASS->new(username => 'test', token => 'testtoken');
    my $path  = 'testpath/path';
    my $query = { test => 'example'};
    my $url   = 'https://pixe.la/v1/testpath/path?test=example';

    is $obj->query_request('GET',$path,$query), ['GET',$url];
};

my $request_test_mock_sub = sub { shift @_; return @_};

subtest 'request test' => sub {
    my $mock = mock $CLASS => (
        override => [ _request => $request_test_mock_sub],
    );
    my $obj = $CLASS->new(username => 'test', token => 'testtoken');
    is [$obj->request('POST','testpath',{test => 'example'})], ['POST','testpath',{ content => encode_json({test => 'example'})}];
};

subtest 'request_with_xuser_in_header  test' => sub {
    my $mock = mock $CLASS => (
        override => [ _request => $request_test_mock_sub],
    );
    my $obj = $CLASS->new(username => 'test', token => 'testtoken');
    is [$obj->request_with_xuser_in_header('POST','testpath',{test => 'example'})], ['POST','testpath',{ headers => {'X-USER-TOKEN' => "testtoken"} , content => encode_json({test => 'example'})}];
};

done_testing;
