#!/usr/bin/env perl

use strict;
use warnings;

use Clone qw(clone);
use Test::LWP::UserAgent;
use Test::More import => [qw( done_testing is is_deeply like ok subtest )];

{
  package WebService::Foo;
  use Moo;
  with 'WebService::Client';

  has '+base_url' => ( default => 'https://example.com' );

  sub get_widgets {
    my $self = shift;
    return $self->get("/widgets");
  }

  sub get_widget {
    my ($self, $id) = @_;
    return $self->get("/widgets/$id");
  }

  sub search_widgets {
    my ($self, $params) = @_;
    return $self->get("/widgets", $params);
  }

  sub create_widget {
    my ($self, $widget_data) = @_;
    return $self->post("/widgets", $widget_data);
  }
}

subtest 'GET with query params (default: php style)' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);
  is $webservice->array_query_style, 'php', 'default array_query_style is php';

  $webservice->get('/foo', { colour => 'blue' });
  my $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?colour=blue', 'simple scalar param';

  $webservice->get('/foo', { q => 'hello world' });
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?q=hello+world', 'spaces encoded as +';

  $webservice->get('/foo', { name => 'foo&bar=baz' });
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?name=foo%26bar%3Dbaz', 'special chars encoded';

  $webservice->get('/foo', { ids => [1, 2, 3] });
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?ids%5B%5D=1&ids%5B%5D=2&ids%5B%5D=3', 'array param uses php-style brackets';

  $webservice->get('/foo', {});
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo', 'empty hashref adds no query string';

  $webservice->get('/foo');
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo', 'no params adds no query string';
};

subtest 'GET with query params (rfc style)' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(
    ua                => $useragent,
    array_query_style => 'rfc',
  );

  $webservice->get('/foo', { colour => 'blue' });
  my $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?colour=blue', 'scalar param unchanged';

  $webservice->get('/foo', { ids => [1, 2, 3] });
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?ids=1&ids=2&ids=3', 'array param uses repeated keys';

  $webservice->get('/foo', { q => 'hello world' });
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?q=hello+world', 'special chars still encoded';

  $webservice->get('/foo', {});
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo', 'empty hashref still works';
};

subtest 'GET without params' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets},
    HTTP::Response->new(
      '200', 'OK', ['Content-Type' => 'application/json'], '[{"name": "widget1"}]'
    ),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  my $widgets = $webservice->get_widgets();
  ok $widgets, 'can get success';
  ok @$widgets, 'deserialized get into a list';
  is scalar @$widgets, 1, 'correct amount of values in returned list';
};

subtest 'PATCH' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets/1},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->patch('/widgets/1', { color => 'blue' });
  my $req = $useragent->last_http_request_sent;
  is $req->method, 'PATCH', 'method is PATCH';
  is $req->uri->as_string, 'https://example.com/widgets/1', 'correct URL';
  like $req->header('Content-Type'), qr{application/json}, 'Content-Type is set';
  is $req->content, '{"color":"blue"}', 'body is JSON-encoded';
};

subtest 'DELETE' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets/1},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->delete('/widgets/1');
  my $req = $useragent->last_http_request_sent;
  is $req->method, 'DELETE', 'method is DELETE';
  is $req->uri->as_string, 'https://example.com/widgets/1', 'correct URL';
  ok !$req->header('Content-Type'), 'no Content-Type header on DELETE';
};

subtest 'GET with gzipped response' => sub {
  use Compress::Zlib qw(memGzip);

  my $json_data = '{"name":"José"}';
  my $gzipped = memGzip($json_data);

  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/gzip},
    HTTP::Response->new(
      '200', 'OK',
      ['Content-Type' => 'application/json', 'Content-Encoding' => 'gzip'],
      $gzipped,
    ),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  my $result = $webservice->get('/gzip');
  ok $result, 'deserialized gzipped response';
  is $result->{name}, 'José', 'correct value from gzipped response';
};

subtest 'GET with url-like paths' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{.*},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->get('http:/evil.com/api');
  my $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.comhttp:/evil.com/api',
    'http:/... treated as relative path, appended to base_url';

  $webservice->get('https://valid.com/api');
  $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://valid.com/api',
    'https://... treated as absolute URL, base_url bypassed';
};

subtest 'invalid headers are rejected' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{.*},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  eval { $webservice->get('/foo', {}, headers => 0) };
  ok $@, 'headers => 0 croaks';
  like $@, qr/headers param must be a hashref/, 'correct error message';

  eval { $webservice->get('/foo', {}, headers => '') };
  ok $@, 'headers => "" croaks';
  like $@, qr/headers param must be a hashref/, 'correct error message for empty string';
};

subtest 'methods do not mutate caller arguments' => sub {
  my $ua = Test::LWP::UserAgent->new;
  $ua->map_response(
    qr{.*},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $svc = WebService::Foo->new(ua => $ua);

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);
    my $params = { colour => 'blue', ids => [1, 2], nested => { a => 1 } };
    my $params_copy = clone($params);

    $svc->get('/foo', $params, %args);

    ok(!$ua->last_http_request_sent->header('Content-Type'), 'get: no Content-Type header');
    is_deeply \%args, $args_copy, 'get: %args unchanged';
    is_deeply $params, $params_copy, 'get: $params unchanged';
  }

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);
    my $data = { name => 'test', tags => ['x', 'y'] };
    my $data_copy = clone($data);

    $svc->post('/foo', $data, %args);

    is_deeply \%args, $args_copy, 'post: %args unchanged';
    is_deeply $data, $data_copy, 'post: $data unchanged';
  }

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);
    my $data = { name => 'test', tags => ['x', 'y'] };
    my $data_copy = clone($data);

    $svc->put('/foo', $data, %args);

    is_deeply \%args, $args_copy, 'put: %args unchanged';
    is_deeply $data, $data_copy, 'put: $data unchanged';
  }

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);
    my $data = { name => 'test', tags => ['x', 'y'] };
    my $data_copy = clone($data);

    $svc->patch('/foo', $data, %args);

    is_deeply \%args, $args_copy, 'patch: %args unchanged';
    is_deeply $data, $data_copy, 'patch: $data unchanged';
  }

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);

    $svc->delete('/foo', %args);

    is_deeply \%args, $args_copy, 'delete: %args unchanged';
  }
};

subtest 'HEAD' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets/1},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], ''),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->head('/widgets/1');
  my $req = $useragent->last_http_request_sent;
  is $req->method, 'HEAD', 'method is HEAD';
  is $req->uri->as_string, 'https://example.com/widgets/1', 'correct URL';
  ok !$req->header('Content-Type'), 'no Content-Type header on HEAD';
};

subtest 'HEAD with query params' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], ''),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->head('/foo', { colour => 'blue' });
  my $url = $useragent->last_http_request_sent->uri;
  is "$url", 'https://example.com/foo?colour=blue', 'HEAD with query params';
};

subtest 'OPTIONS' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->options('/widgets');
  my $req = $useragent->last_http_request_sent;
  is $req->method, 'OPTIONS', 'method is OPTIONS';
  is $req->uri->as_string, 'https://example.com/widgets', 'correct URL';
  like $req->header('Content-Type'), qr/form-urlencoded/, 'Content-Type set by HTTP::Request::Common';
};

subtest 'OPTIONS with body' => sub {
  my $useragent = Test::LWP::UserAgent->new;
  $useragent->map_response(
    qr{example.com/widgets},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $webservice = WebService::Foo->new(ua => $useragent);

  $webservice->options('/widgets', { color => 'blue' });
  my $req = $useragent->last_http_request_sent;
  is $req->method, 'OPTIONS', 'method is OPTIONS';
  is $req->uri->as_string, 'https://example.com/widgets', 'correct URL';
  like $req->header('Content-Type'), qr{application/json}, 'Content-Type is set';
  is $req->content, '{"color":"blue"}', 'body is JSON-encoded';
};

subtest 'HEAD and options do not mutate caller arguments' => sub {
  my $ua = Test::LWP::UserAgent->new;
  $ua->map_response(
    qr{.*},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{}'),
  );

  my $svc = WebService::Foo->new(ua => $ua);

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);
    my $params = { colour => 'blue', ids => [1, 2] };
    my $params_copy = clone($params);

    $svc->head('/foo', $params, %args);

    is_deeply \%args, $args_copy, 'head: %args unchanged';
    is_deeply $params, $params_copy, 'head: $params unchanged';
  }

  {
    my %args = (headers => { 'X-Custom' => 'val' });
    my $args_copy = clone(\%args);

    $svc->options('/foo', {}, %args);

    is_deeply \%args, $args_copy, 'options: %args unchanged';
  }
};

done_testing();
