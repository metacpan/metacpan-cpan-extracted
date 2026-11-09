use strict;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# the URLs it is asked for and answers from %pages (any other URL gets an empty page).
my $base = 'https://api.mailgun.net/v3/example.com/events';
my %pages = (
    "$base?event=stored" => {
        items  => [ { id => 'a' }, { id => 'b' } ],
        paging => { next => "$base/page-2", previous => "$base/page-0" },
    },
    "$base/page-2" => {
        items  => [],
        paging => { next => "$base/page-3", previous => "$base/page-1" },
    },
    "$base?event=failing" => {
        items  => [ { id => 'c' } ],
        paging => { next => "$base/fails" },
    },
    "$base/fails" => { status => 500 },
);

{
    package t::Client;
    sub new { bless { urls => [] }, shift }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{urls} }, $url;
        my $u = URI->new($url);
        $u->userinfo(undef);
        return t::Response->new($pages{"$u"}
            || { items => [], paging => { next => "$u/next", previous => "$u/previous" } });
    }

    package t::Response;
    use JSON;
    sub new         { my ($class, $page) = @_; bless { page => $page }, $class }
    sub is_success  { !$_[0]{page}{status} }
    sub status_line { "$_[0]{page}{status} Internal Server Error" }
    sub content     { $_[0]{page}{status} ? '{"message":"failed"}' : encode_json $_[0]{page} }
}

sub with_key {
    my $u = URI->new(shift);
    $u->userinfo('api:dummy-api-key');
    return "$u";
}

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);
my $client = t::Client->new;
$mailgun->{_client} = $client;

my ($events, $next) = $mailgun->event({ event => 'stored' });

is_deeply [ map { $_->{id} } @$events ], [qw(a b)], 'the events of every page';
is_deeply $client->{urls}, [ with_key("$base?event=stored"), with_key("$base/page-2") ],
    'paging.next is followed until a page has no items';
isa_ok $next, 'URI';
is "$next", with_key("$base/page-3"),
    'the second value is paging.next of the empty page, with the API key';

subtest 'event($next) fetches the URL it is given' => sub {
    @{ $client->{urls} } = ();
    $next->userinfo(undef);
    $mailgun->event($next);
    is $client->{urls}[0], with_key("$base/page-3");
    is "$next", "$base/page-3", 'the URI passed in is left as it is';
};

subtest 'when a page fails, the second value is the URL of that page' => sub {
    my ($events, $retry) = $mailgun->event({ event => 'failing' });
    is_deeply [ map { $_->{id} } @$events ], ['c'], 'the events fetched before it';
    is "$retry", with_key("$base/fails");
    is $mailgun->error, 'failed', 'error is set';
};

subtest 'a URL given as a string gets the API key' => sub {
    @{ $client->{urls} } = ();
    $mailgun->event("$base/page-3");
    is $client->{urls}[0], with_key("$base/page-3");
};

subtest 'the API key goes only to the API host over https' => sub {
    for my $url (
        'https://evil.example.com/v3/example.com/events/page-3',
        'http://api.mailgun.net/v3/example.com/events/page-3',
        'events/page-3',
        '',
    ) {
        @{ $client->{urls} } = ();
        eval { $mailgun->event($url) };
        like $@, qr/^event\(\) takes a query hash reference or an https URL on api\.mailgun\.net/,
            "'$url' is refused";
        is scalar @{ $client->{urls} }, 0, 'nothing is requested';
    }
};

done_testing;
