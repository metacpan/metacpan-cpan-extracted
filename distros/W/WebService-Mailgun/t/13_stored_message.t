use strict;
use warnings;
use Test::More 0.98;

# A warning from the module (an undefined host, say) fails the test.
$SIG{__WARN__} = sub { die "warning: @_" };
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# the URLs it is asked for (with the API key) and answers with an empty success.
{
    package t::Client;
    sub new { bless { urls => [] }, shift }
    sub get { push @{ $_[0]{urls} }, $_[1]; t::Response->new }

    package t::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { '{"body-plain":"Body"}' }
}

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub urls_of {
    my ($code) = @_;
    @{ $client->{urls} } = ();
    eval { $code->() };
    return ($@, [ @{ $client->{urls} } ]);
}

my $storage = 'https://storage-us-east4.api.mailgun.net/v3/domains/example.com/messages/KEY';

subtest 'a stored event' => sub {
    my ($error, $urls) = urls_of(sub {
        is_deeply $mailgun->get_message_from_event({ event => 'stored', storage => { url => $storage } }),
            { 'body-plain' => 'Body' };
    });
    is $error, '';
    my $url = URI->new($urls->[0]);
    is $url->userinfo, 'api:dummy-api-key', 'with the API key';
    $url->userinfo(undef);
    is "$url", $storage;
};

subtest 'another event with storage.url' => sub {
    my ($error, $urls) = urls_of(sub {
        $mailgun->get_message_from_event({ event => 'accepted', storage => { url => $storage } });
    });
    is $error, '';
    is scalar @$urls, 1, 'is fetched';
};

subtest 'mailgun.net and the hosts under it' => sub {
    for my $url (
        'https://api.mailgun.net/v3/domains/example.com/messages/KEY',
        'https://storage-europe-west1.api.eu.mailgun.net/v3/domains/example.com/messages/KEY',
        'https://SE.API.MAILGUN.NET/v3/domains/example.com/messages/KEY',
    ) {
        my ($error, $urls) = urls_of(sub { $mailgun->get_message_from_event({ storage => { url => $url } }) });
        is $error, '', $url;
        is scalar @$urls, 1;
    }
};

subtest 'the API key goes nowhere else' => sub {
    for my $url (
        'https://evil.example.com/v3/domains/example.com/messages/KEY',
        'https://mailgun.net.evil.example.com/messages/KEY',
        'https://evilmailgun.net/messages/KEY',
        'https://evil.example.com%2Fx.mailgun.net/messages/KEY',
        'http://storage-us-east4.api.mailgun.net/v3/domains/example.com/messages/KEY',
        '/v3/domains/example.com/messages/KEY',
        'https:foo',
    ) {
        my ($error, $urls) = urls_of(sub { $mailgun->get_message_from_event({ event => 'stored', storage => { url => $url } }) });
        like $error, qr/^get_message_from_event\(\) takes storage\.url only on https and mailgun\.net, not '/, $url;
        is_deeply $urls, [], 'nothing is requested';
    }
};

subtest 'the refused URL is shown without the API key' => sub {
    my ($error) = urls_of(sub {
        $mailgun->get_message_from_event({ storage => { url => 'https://api:secret@evil.example.com/m' } });
    });
    like $error, qr/not 'https:\/\/evil\.example\.com\/m'/;
    unlike $error, qr/secret/;
};

subtest 'the host of api_base is taken too' => sub {
    local $WebService::Mailgun::API_BASE = 'mock.example.com/v3';
    my ($error, $urls) = urls_of(sub {
        $mailgun->get_message_from_event({ storage => { url => 'https://mock.example.com/v3/domains/d/messages/K' } });
    });
    is $error, '';
    is scalar @$urls, 1;
};

subtest 'a blessed hash and a URI' => sub {
    my ($error, $urls) = urls_of(sub {
        $mailgun->get_message_from_event(bless { storage => { url => URI->new($storage) } }, 't::Event');
    });
    is $error, '';
    is scalar @$urls, 1;
};

subtest 'an event without storage.url dies' => sub {
    for my $event (
        { event => 'delivered' },
        { event => 'stored', storage => {} },
        { storage => 'x' },
        { storage => { url => ['https://x.mailgun.net/'] } },
        { storage => { url => '' } },
        undef,
    ) {
        my ($error, $urls) = urls_of(sub { $mailgun->get_message_from_event($event) });
        like $error, qr/^invalid event! this method needs an event with storage\.url/;
        is_deeply $urls, [];
    }
};

done_testing;
