use strict;
use warnings;
use utf8;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# the method, the URL and the form it is asked for, and answers with the body in $content.
our $content = '{}';
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub _record {
        my ($self, $method, $url, $form) = @_;
        my $u = URI->new($url);
        $u->userinfo(undef);
        push @{ $self->{requests} }, [ "$method $u", $form ];
        return t::Response->new;
    }
    sub get    { $_[0]->_record(GET    => $_[1]) }
    sub post   { $_[0]->_record(POST   => $_[1], $_[3]) }
    sub put    { $_[0]->_record(PUT    => $_[1], $_[3]) }
    sub delete { $_[0]->_record(DELETE => $_[1]) }

    package t::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { $main::content }
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

my $base = 'https://api.mailgun.net/v3/domains/example.com/webhooks';

subtest 'domain_webhooks()' => sub {
    local $content = '{"webhooks":{"clicked":{"urls":["https://example.com/c"]}}}';
    my $webhooks;
    is_deeply requests_of(sub { $webhooks = $mailgun->domain_webhooks() }), [ ["GET $base", undef] ];
    is_deeply $webhooks, { clicked => { urls => ['https://example.com/c'] } };
};

subtest 'domain_webhook($type)' => sub {
    local $content = '{"webhook":{"urls":["https://example.com/c"]}}';
    my $webhook;
    is_deeply requests_of(sub { $webhook = $mailgun->domain_webhook('clicked') }),
        [ ["GET $base/clicked", undef] ];
    is_deeply $webhook, { urls => ['https://example.com/c'] };
};

subtest 'add_domain_webhook($type, $url)' => sub {
    is_deeply requests_of(sub { $mailgun->add_domain_webhook(clicked => 'https://example.com/c') }),
        [ ["POST $base", [ id => 'clicked', url => 'https://example.com/c' ]] ];
};

subtest 'add_domain_webhook($type, \@urls) sends url once for each' => sub {
    is_deeply requests_of(sub {
        $mailgun->add_domain_webhook(opened => ['https://example.com/a', 'https://example.com/b']);
    }), [ ["POST $base", [ id => 'opened', url => 'https://example.com/a', url => 'https://example.com/b' ]] ];
};

subtest 'update_domain_webhook($type, \@urls)' => sub {
    is_deeply requests_of(sub { $mailgun->update_domain_webhook(clicked => ['https://example.com/n']) }),
        [ ["PUT $base/clicked", [ url => 'https://example.com/n' ]] ];
};

subtest 'delete_domain_webhook($type)' => sub {
    is_deeply requests_of(sub { $mailgun->delete_domain_webhook('clicked') }),
        [ ["DELETE $base/clicked", undef] ];
};

subtest 'a URI goes out as its string' => sub {
    is_deeply requests_of(sub { $mailgun->add_domain_webhook(clicked => URI->new('https://example.com/c')) }),
        [ ["POST $base", [ id => 'clicked', url => 'https://example.com/c' ]] ];
};

subtest 'a response without the webhooks is a failure' => sub {
    local $content = '{"items":[]}';
    my ($webhooks, $webhook);
    requests_of(sub { $webhooks = $mailgun->domain_webhooks() });
    is $webhooks, undef;
    is $mailgun->error, "the response has no 'webhooks'";
    requests_of(sub { $webhook = $mailgun->domain_webhook('clicked') });
    is $webhook, undef;
    is $mailgun->error, "the response has no 'webhook'";

    local $mailgun->{RaiseError} = 1;
    local $SIG{__WARN__} = sub {};
    ok !eval { $mailgun->domain_webhooks(); 1 }, 'dies with RaiseError';
};

subtest 'a decoded URL goes out as UTF-8' => sub {
    my $requests = requests_of(sub { $mailgun->update_domain_webhook(clicked => 'https://example.com/ü') });
    is $requests->[0][1][1], "https://example.com/\xC3\xBC";
};

subtest 'the type goes into the path percent-encoded' => sub {
    is_deeply requests_of(sub { $mailgun->delete_domain_webhook('a/b?c') }),
        [ ["DELETE $base/a%2Fb%3Fc", undef] ];
};

subtest 'a missing type or URL dies without a request' => sub {
    for my $case (
        [ 'domain_webhook(undef)'             => sub { $mailgun->domain_webhook(undef) } ],
        [ "delete_domain_webhook('')"         => sub { $mailgun->delete_domain_webhook('') } ],
        [ 'add_domain_webhook(undef, $url)'   => sub { $mailgun->add_domain_webhook(undef, 'https://example.com/') } ],
        [ 'add_domain_webhook($type)'         => sub { $mailgun->add_domain_webhook('clicked') } ],
        [ 'add_domain_webhook($type, [])'     => sub { $mailgun->add_domain_webhook(clicked => []) } ],
        [ "update_domain_webhook(\$type, '')" => sub { $mailgun->update_domain_webhook(clicked => '') } ],
        [ 'update_domain_webhook($type, {})'  => sub { $mailgun->update_domain_webhook(clicked => {}) } ],
    ) {
        my ($name, $code) = @$case;
        my $requests = requests_of(sub { eval { $code->(); 1 } and fail "$name did not die" });
        is_deeply $requests, [], "$name sends nothing";
    }
};

subtest 'a domain is required' => sub {
    my $no_domain = WebService::Mailgun->new(api_key => 'dummy-api-key');
    $no_domain->{_client} = $client;
    my $requests = requests_of(sub { eval { $no_domain->domain_webhooks(); 1 } and fail 'did not die' });
    is_deeply $requests, [];
};

done_testing;
