use strict;
use warnings;
use lib 't/lib';
use Test::More 0.98;
use URI;
use WebService::Mailgun;
use t::Form ();

# This test never reaches a real API server: the HTTP client is replaced with one that records
# each request and answers with an empty success.
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub _plain {
        my $u = URI->new($_[0]);
        $u->userinfo(undef);
        return "$u";
    }
    sub _record {
        my ($self, $method, $url) = @_;
        push @{ $self->{requests} }, { line => "$method " . _plain($url) };
        return t::Response->new;
    }
    sub get    { $_[0]->_record(GET    => $_[1]) }
    sub put    { $_[0]->_record(PUT    => $_[1]) }
    sub delete { $_[0]->_record(DELETE => $_[1]) }
    sub request {
        my ($self, $req) = @_;
        push @{ $self->{requests} }, {
            line   => $req->method . ' ' . _plain($req->uri),
            fields => [ t::Form::fields_of($req) ],
        };
        return t::Response->new;
    }

    package t::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { '{}' }
}

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub requests_of {
    my ($code) = @_;
    @{ $client->{requests} } = ();
    $code->();
    return [ @{ $client->{requests} } ];
}

sub lines_of { [ map { $_->{line} } @{ requests_of($_[0]) } ] }

*plain = \&t::Client::_plain;

subtest 'api_url() without a version is as before' => sub {
    is plain($mailgun->api_url('lists')), 'https://api.mailgun.net/v3/lists';
    is plain($mailgun->domain_api_url('messages')), 'https://api.mailgun.net/v3/example.com/messages';
    like $mailgun->api_url('lists'), qr{^https://api:dummy-api-key\@};
};

subtest 'api_url($method, $version) replaces the version' => sub {
    is plain($mailgun->api_url('domains', 'v4')), 'https://api.mailgun.net/v4/domains';
    is plain($mailgun->api_url('analytics/logs', 'v1')), 'https://api.mailgun.net/v1/analytics/logs';
    for my $region (qw(eu au)) {
        my $regional = WebService::Mailgun->new(api_key => 'k', region => $region);
        is plain($regional->api_url('domains', 'v4')), "https://api.$region.mailgun.net/v4/domains";
    }
};

subtest 'a replaced $API_BASE is followed' => sub {
    local $WebService::Mailgun::API_BASE = 'localhost.example:3000/v3';
    is plain($mailgun->api_url('domains', 'v4')), 'https://localhost.example:3000/v4/domains';

    local $WebService::Mailgun::API_BASE = 'localhost.example:3000';
    is plain($mailgun->api_url('lists')), 'https://localhost.example:3000/lists', 'v3 as before';
    ok !eval { $mailgun->api_url('domains', 'v4'); 1 }, 'a base without a version has no v4';
    like $@, qr/does not end in a version/;
};

subtest 'an unknown version dies' => sub {
    ok !eval { $mailgun->api_url('domains', '4'); 1 };
    like $@, qr/unsupported API version '4'/;
};

my $v4 = 'https://api.mailgun.net/v4';

subtest 'domains' => sub {
    is_deeply lines_of(sub { $mailgun->domains() }), ["GET $v4/domains"];
    is_deeply lines_of(sub { $mailgun->domains({ limit => 10 }) }), ["GET $v4/domains?limit=10"];
    is_deeply lines_of(sub { $mailgun->get_domain('mg.example.com') }), ["GET $v4/domains/mg.example.com"];
    is_deeply lines_of(sub { $mailgun->verify_domain('mg.example.com') }),
        ["PUT $v4/domains/mg.example.com/verify"];
    is_deeply lines_of(sub { $mailgun->delete_domain('mg.example.com') }),
        ['DELETE https://api.mailgun.net/v3/domains/mg.example.com'];

    my $requests = requests_of(sub {
        $mailgun->add_domain({ name => 'mg.example.com' });
        $mailgun->update_domain('mg.example.com' => { spam_action => 'tag' });
    });
    is $requests->[0]{line}, "POST $v4/domains";
    is_deeply $requests->[0]{fields}, [ [ name => 'mg.example.com', undef ] ];
    is $requests->[1]{line}, "PUT $v4/domains/mg.example.com";
    is_deeply $requests->[1]{fields}, [ [ spam_action => 'tag', undef ] ];
};

subtest 'validate_address($address, $query)' => sub {
    my ($line) = @{ lines_of(sub { $mailgun->validate_address('a+b@example.com', { provider_lookup => 'false' }) }) };
    my $uri = URI->new($line =~ s/^GET //r);
    is $uri->path, '/v4/address/validate';
    is_deeply { $uri->query_form }, { address => 'a+b@example.com', provider_lookup => 'false' };
};

subtest 'what is not given dies without a request' => sub {
    for my $case (
        [ 'get_domain(undef)'        => sub { $mailgun->get_domain(undef) } ],
        [ "delete_domain('')"        => sub { $mailgun->delete_domain('') } ],
        [ 'domains([])'              => sub { $mailgun->domains([]) } ],
        [ 'validate_address(undef)'  => sub { $mailgun->validate_address(undef) } ],
        [ "validate_address('a', [])" => sub { $mailgun->validate_address('a', []) } ],
    ) {
        my ($name, $code) = @$case;
        my $requests = requests_of(sub { eval { $code->(); 1 } and fail "$name did not die" });
        is_deeply $requests, [], "$name sends nothing";
    }
};

done_testing;
