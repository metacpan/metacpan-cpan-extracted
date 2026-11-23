use strict;
use warnings;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# the URLs it is asked for and answers with an empty page.
{
    package t::Client;
    sub new { bless { urls => [] }, shift }
    sub get {
        my ($self, $url) = @_;
        my $u = URI->new($url);
        $u->userinfo(undef);
        push @{ $self->{urls} }, "$u";
        return t::Response->new;
    }

    package t::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { '{"items":[],"list":{}}' }
}

sub mailgun {
    my ($region) = @_;
    my $mailgun = WebService::Mailgun->new(
        api_key => 'dummy-api-key',
        domain  => 'example.com',
        (defined $region ? (region => $region) : ()),
    );
    $mailgun->{_client} = t::Client->new;
    return $mailgun;
}

for my $case (
    [ undef, 'api.mailgun.net' ],
    [ 'us',  'api.mailgun.net' ],
    [ 'eu',  'api.eu.mailgun.net' ],
    [ 'EU',  'api.eu.mailgun.net' ],
    [ 'au',  'api.au.mailgun.net' ],
    [ 'AU',  'api.au.mailgun.net' ],
) {
    my ($region, $host) = @$case;
    subtest 'region ' . ($region // 'not given') => sub {
        my $mailgun = mailgun($region);
        $mailgun->list('l@example.com');
        $mailgun->event({ event => 'stored' });
        $mailgun->event("https://$host/v3/example.com/events/next");
        is_deeply $mailgun->{_client}{urls}, [
            "https://$host/v3/lists/l\@example.com",
            "https://$host/v3/example.com/events?event=stored",
            "https://$host/v3/example.com/events/next",
        ];
    };
}

subtest 'event() takes a URL only on the host of its region' => sub {
    my $mailgun = mailgun('au');
    eval { $mailgun->event('https://api.mailgun.net/v3/example.com/events/next') };
    like $@, qr/https URL on api\.au\.mailgun\.net/;
};

subtest 'an unknown region dies' => sub {
    my $mailgun = mailgun('ap');
    eval { $mailgun->list('l@example.com') };
    like $@, qr/^unsupported region 'ap'/;
    is_deeply $mailgun->{_client}{urls}, [], 'nothing is requested';
};

done_testing;
