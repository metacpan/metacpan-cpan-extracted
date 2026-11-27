use strict;
use warnings;
use utf8;
use JSON;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# each request and answers with an empty success.
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub _record {
        my ($self, $method, $url, $headers, $content) = @_;
        my $u = URI->new($url);
        $u->userinfo(undef);
        push @{ $self->{requests} }, {
            line => "$method $u",
            ($headers && @$headers ? (headers => { @$headers }) : ()),
            (defined $content ? (body => JSON::decode_json($content)) : ()),
        };
        return t::Response->new;
    }
    sub get    { $_[0]->_record(GET    => @_[1 .. 3]) }
    sub post   { $_[0]->_record(POST   => @_[1 .. 3]) }
    sub put    { $_[0]->_record(PUT    => @_[1 .. 3]) }
    sub delete { $_[0]->_record(DELETE => @_[1 .. 3]) }

    # The status line of the answers, '200 OK' unless a test sets it.
    package t::Response;
    our $status = '200 OK';
    sub new         { bless {}, shift }
    sub is_success  { $status =~ /^2/ }
    sub status_line { $status }
    sub content     { is_success() ? '{"items":[]}' : '{"message":"Invalid duration"}' }
}

my $mailgun = WebService::Mailgun->new(api_key => 'dummy-api-key');
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub request_of {
    my ($code) = @_;
    @{ $client->{requests} } = ();
    $code->();
    is scalar @{ $client->{requests} }, 1, 'one request';
    return $client->{requests}[0];
}

my $v1 = 'https://api.mailgun.net/v1/analytics';

for my $case (
    [ logs          => 'logs' ],
    [ metrics       => 'metrics' ],
    [ usage_metrics => 'usage/metrics' ],
    [ tags          => 'tags' ],
) {
    my ($method, $path) = @$case;
    subtest "$method(\$body) sends the body as JSON" => sub {
        my $body = { duration => '1d', pagination => { limit => 10, token => 'ü' } };
        my $req = request_of(sub { $mailgun->$method($body) });
        is $req->{line}, "POST $v1/$path";
        is $req->{headers}{'Content-Type'}, 'application/json';
        is_deeply $req->{body}, $body;

        $req = request_of(sub { $mailgun->$method() });
        is_deeply $req->{body}, {}, 'without a body, an empty object';
    };
}

subtest 'update_tag() and delete_tag() send the tag in the body' => sub {
    my $req = request_of(sub { $mailgun->update_tag(news => 'The newsletter') });
    is $req->{line}, "PUT $v1/tags";
    is_deeply $req->{body}, { tag => 'news', description => 'The newsletter' };

    $req = request_of(sub { $mailgun->delete_tag('news') });
    is $req->{line}, "DELETE $v1/tags";
    is_deeply $req->{body}, { tag => 'news' };
};

subtest 'tag_limits()' => sub {
    my $req = request_of(sub { $mailgun->tag_limits() });
    is $req->{line}, "GET $v1/tags/limits";
};

subtest 'the region is followed' => sub {
    my $eu = WebService::Mailgun->new(api_key => 'k', region => 'eu');
    $eu->{_client} = $client;
    my $req = request_of(sub { $eu->logs() });
    is $req->{line}, 'POST https://api.eu.mailgun.net/v1/analytics/logs';
};

subtest 'a blessed hash goes out as a plain one' => sub {
    my $body = bless { duration => '1d' }, 'Some::Hash';
    my $req = request_of(sub { $mailgun->logs($body) });
    is_deeply $req->{body}, { duration => '1d' };
};

subtest 'a failure is told as for the other methods' => sub {
    local $t::Response::status = '400 Bad Request';
    my $res;
    request_of(sub { $res = $mailgun->logs({ duration => 'x' }) });
    is $res, undef;
    is $mailgun->error, 'Invalid duration';
    is $mailgun->error_status, '400 Bad Request';

    local $mailgun->{RaiseError} = 1;
    local $SIG{__WARN__} = sub {};
    ok !eval { $mailgun->metrics({}); 1 }, 'dies with RaiseError';
};

subtest 'what is not given dies without a request' => sub {
    for my $case (
        [ 'logs([])'          => sub { $mailgun->logs([]) } ],
        [ "metrics('x')"      => sub { $mailgun->metrics('x') } ],
        [ 'update_tag(undef)' => sub { $mailgun->update_tag(undef, 'x') } ],
        [ "update_tag('news')" => sub { $mailgun->update_tag('news') } ],
        [ "delete_tag('')"    => sub { $mailgun->delete_tag('') } ],
    ) {
        my ($name, $code) = @$case;
        @{ $client->{requests} } = ();
        eval { $code->(); 1 } and fail "$name did not die";
        is_deeply $client->{requests}, [], "$name sends nothing";
    }
};

done_testing;
