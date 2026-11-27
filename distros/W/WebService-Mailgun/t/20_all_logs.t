use strict;
use warnings;
use JSON;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# each request and answers with the [status, body] pairs in @main::responses, in turn.
our @responses;
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub post {
        my ($self, $url, $headers, $content) = @_;
        my $u = URI->new($url);
        $u->userinfo(undef);
        push @{ $self->{requests} }, { line => "POST $u", body => JSON::decode_json($content) };
        my ($status, $body) = @{ shift(@main::responses) // [ '200 OK', '{"items":[]}' ] };
        return t::Response->new($status, $body);
    }

    package t::Response;
    sub new         { bless { status => $_[1], content => $_[2] }, $_[0] }
    sub is_success  { $_[0]{status} =~ /^2/ }
    sub status_line { $_[0]{status} }
    sub content     { $_[0]{content} }
}

my $mailgun = WebService::Mailgun->new(api_key => 'dummy-api-key');
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub run_all_logs {
    my ($body, @answers) = @_;
    @{ $client->{requests} } = ();
    local @responses = @answers;
    my @r = $mailgun->all_logs($body);
    return \@r, [ @{ $client->{requests} } ];
}

sub page {
    my ($ids, $next) = @_;
    return [ '200 OK', encode_json({
        items => [ map { +{ id => $_ } } @$ids ],
        pagination => { defined $next ? (next => $next) : (), first => 'f' },
    }) ];
}

subtest 'follows pagination.next until a page has none' => sub {
    my $body = { start => 'Thu, 26 Nov 2026 00:00:00 +0000', pagination => { limit => 2, sort => 'timestamp:asc' } };
    my ($r, $requests) = run_all_logs($body, page([1, 2], 'tok1'), page([3, 4], 'tok2'), page([5]));
    is_deeply $r, [ [ map { +{ id => $_ } } 1 .. 5 ], undef ];
    is_deeply [ map { $_->{line} } @$requests ], [ ('POST https://api.mailgun.net/v1/analytics/logs') x 3 ];
    is_deeply [ map { $_->{body}{pagination}{token} } @$requests ], [ undef, 'tok1', 'tok2' ];
    is_deeply [ map { $_->{body}{start} } @$requests ], [ ($body->{start}) x 3 ], 'the rest of the body on every page';
    is_deeply $body->{pagination}, { limit => 2, sort => 'timestamp:asc' }, 'the body given is not changed';
};

subtest 'an empty page is the end, even with a new token' => sub {
    my ($r, $requests) = run_all_logs({}, page([1], 'tok1'), page([], 'tok2'), page([9]));
    is scalar @$requests, 2, 'tok2 is not followed';
    is_deeply $r, [ [ { id => 1 } ], undef ];
};

subtest 'no logs' => sub {
    my ($r, $requests) = run_all_logs(undef, [ '200 OK', '{"items":[],"pagination":{}}' ]);
    is_deeply $r, [ [], undef ];
    is_deeply $requests->[0]{body}, { pagination => {} };
};

subtest 'a failure on the first page gives a pagination, not undef' => sub {
    my ($r) = run_all_logs({ pagination => { limit => 2 } }, [ '400 Bad Request', '{"message":"start is before the retention"}' ]);
    is_deeply $r, [ [], { limit => 2 } ];
    is $mailgun->error, 'start is before the retention';
    is $mailgun->error_status, '400 Bad Request';
};

subtest 'a failure on a later page gives the items so far and its pagination' => sub {
    my ($r, $requests) = run_all_logs({ pagination => { limit => 2 } },
        page([1, 2], 'tok1'), [ '429 Too Many Requests', '{"message":"slow down"}' ]);
    is_deeply $r, [ [ { id => 1 }, { id => 2 } ], { limit => 2, token => 'tok1' } ];
    is $mailgun->error_status, '429 Too Many Requests';

    # passed back, it takes up from the page that failed
    ($r, $requests) = run_all_logs({ pagination => $r->[1] }, page([3]));
    is $requests->[0]{body}{pagination}{token}, 'tok1';
    is_deeply $r, [ [ { id => 3 } ], undef ];
};

subtest 'a token that comes again stops as a failure' => sub {
    my ($r, $requests) = run_all_logs({}, page([1], 'tok1'), page([2], 'tok2'), page([3], 'tok1'));
    is scalar @$requests, 3, 'tok1 is not sent twice';
    is_deeply $r, [ [ map { +{ id => $_ } } 1 .. 3 ], { token => 'tok1' } ];
    like $mailgun->error, qr/points back/;
};

subtest 'a page without items is a failure' => sub {
    my ($r) = run_all_logs({}, page([1], 'tok1'), [ '200 OK', '{"pagination":{}}' ]);
    is_deeply $r, [ [ { id => 1 } ], { token => 'tok1' } ];
    like $mailgun->error, qr/no 'items'/;
};

subtest 'RaiseError dies' => sub {
    my $raise = WebService::Mailgun->new(api_key => 'dummy-api-key', RaiseError => 1);
    $raise->{_client} = $client;
    local @responses = ([ '400 Bad Request', '{"message":"bad"}' ]);
    local $SIG{__WARN__} = sub {};
    ok !eval { $raise->all_logs({}); 1 };
};

subtest 'what is not a hash reference dies without a request' => sub {
    for my $case ([ 'a list' => [] ], [ 'pagination as a list' => { pagination => [] } ]) {
        @{ $client->{requests} } = ();
        ok !eval { $mailgun->all_logs($case->[1]); 1 }, "$case->[0] dies";
        is_deeply $client->{requests}, [], "$case->[0] sends nothing";
    }
};

done_testing;
