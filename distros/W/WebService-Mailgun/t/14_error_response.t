use strict;
use warnings;
use Test::More 0.98;
use Furl::Response;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that answers
# from the queue of Furl::Response objects it is given.
{
    package t::Client;
    sub new { my ($class, @responses) = @_; bless { responses => [@responses] }, $class }
    sub get     { shift @{ $_[0]{responses} } }
    sub delete  { shift @{ $_[0]{responses} } }
    sub request { shift @{ $_[0]{responses} } }
}

sub response {
    my ($code, $message, $headers, $body) = @_;
    return Furl::Response->new(1, $code, $message, $headers, $body);
}

sub mailgun {
    my $mailgun = WebService::Mailgun->new(
        api_key => 'dummy-api-key',
        domain  => 'example.com',
    );
    $mailgun->{_client} = t::Client->new(@_);
    return $mailgun;
}

subtest 'the response of a 429, with its headers' => sub {
    my $res = response(429, 'Too Many Requests',
        [ 'X-RateLimit-Limit' => 300, 'X-RateLimit-Remaining' => 0, 'X-RateLimit-Reset' => '1700000000000' ],
        '{"message":"Too many requests"}');
    my $mailgun = mailgun($res);
    ok !$mailgun->message({ from => 'f@example.com', to => 't@example.com', text => 't' });
    is $mailgun->error_status, '429 Too Many Requests';
    is $mailgun->error, 'Too many requests';
    isa_ok $mailgun->error_response, 'Furl::Response';
    is $mailgun->error_response->code, 429;
    is $mailgun->error_response->content, '{"message":"Too many requests"}';
    is $mailgun->error_response->header('X-RateLimit-Reset'), '1700000000000';
};

subtest 'without the request, whose URL carries the API key' => sub {
    my $res = response(429, 'Too Many Requests', [], '{}');
    $res->set_request_info({ method => 'POST', url => 'https://api:secret-key@api.mailgun.net/v3/example.com/messages' },
        'headers', 'a large attachment');
    my $mailgun = mailgun($res);
    ok !$mailgun->message({ from => 'f@example.com', to => 't@example.com', text => 't' });
    my $kept = $mailgun->error_response;
    ok !exists $kept->{$_}, "no $_" for qw(request_src captured_req_headers captured_req_content);
    require Data::Dumper;
    my $dump = Data::Dumper->new([$kept])->Indent(0)->Dump;
    unlike $dump, qr/secret-key|large attachment/, 'nothing of the request is left';
    ok $res->{request_src}, 'the response given is left as it is';
};

subtest 'before any failure, there is none' => sub {
    my $mailgun = mailgun(response(200, 'OK', [], '{"list":{}}'));
    ok $mailgun->list('l@example.com');
    is $mailgun->error_response, undef;
};

subtest 'it keeps the last failure, like error' => sub {
    my $failed = response(404, 'Not Found', [], '{"message":"List not found"}');
    my $mailgun = mailgun($failed, response(200, 'OK', [], '{"list":{}}'));
    ok !$mailgun->list('l@example.com');
    ok $mailgun->list('l@example.com');
    is $mailgun->error_response->code, 404, 'a success after it does not clear it';
};

subtest 'a failure of a page' => sub {
    my $failed = response(429, 'Too Many Requests', [ 'X-RateLimit-Reset' => '1' ], '{}');
    my $mailgun = mailgun(
        response(200, 'OK', [], '{"items":[{"id":"a"}],"paging":{"next":"https://api.mailgun.net/v3/lists/pages?page=2"}}'),
        $failed,
    );
    my ($items) = $mailgun->lists();
    is scalar @$items, 1, 'the items before it';
    is $mailgun->error_response->code, 429;
    is $mailgun->error_response->header('X-RateLimit-Reset'), '1';
};

subtest 'a paging.next that points back keeps the response that pointed back' => sub {
    my $page = response(200, 'OK', [], '{"items":[{"id":"a"}],"paging":{"next":"https://api.mailgun.net/v3/lists/pages"}}');
    my $mailgun = mailgun($page);
    $mailgun->lists();
    like $mailgun->error, qr/^paging\.next points back/;
    is $mailgun->error_response->code, 200, 'the response that pointed back, a 2xx';
    is $mailgun->error_status, '200 OK';
};

done_testing;
