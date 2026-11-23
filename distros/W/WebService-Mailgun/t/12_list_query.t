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
        push @{ $self->{urls} }, $u;
        return t::Response->new;
    }

    package t::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { '{"items":[]}' }
}

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub first_url_of {
    my ($code) = @_;
    @{ $client->{urls} } = ();
    $code->();
    return $client->{urls}[0];
}

my $v3 = 'https://api.mailgun.net/v3';

subtest 'lists() without a query, as before' => sub {
    is first_url_of(sub { $mailgun->lists() }), "$v3/lists/pages";
};

subtest 'lists($query)' => sub {
    my $url = first_url_of(sub { $mailgun->lists({ limit => 100 }) });
    is $url->path, '/v3/lists/pages';
    is_deeply { $url->query_form }, { limit => 100 };
};

subtest 'list_members() without a query, as before' => sub {
    is first_url_of(sub { $mailgun->list_members('l@example.com') }),
        "$v3/lists/l\@example.com/members/pages";
};

subtest 'list_members($address, $query)' => sub {
    my $url = first_url_of(sub { $mailgun->list_members('l@example.com', { subscribed => 'no', limit => 50 }) });
    is $url->path, '/v3/lists/l@example.com/members/pages';
    is_deeply { $url->query_form }, { subscribed => 'no', limit => 50 };
};

subtest 'the query goes on the later pages too' => sub {
    my $pages = "$v3/lists/l\@example.com/members/pages";
    my @answers = (
        # paging.next without subscribed, with its own limit
        qq({"items":[{"address":"a"}],"paging":{"next":"$pages?page=next&address=a&limit=100"}}),
        qq({"items":[{"address":"b"}],"paging":{"next":"$pages?page=next&address=b&limit=100"}}),
        '{"items":[]}',
    );
    no warnings 'redefine';
    local *t::Response::new     = sub { bless { content => shift @answers }, shift };
    local *t::Response::content = sub { $_[0]{content} };
    @{ $client->{urls} } = ();
    my ($members, $next) = $mailgun->list_members('l@example.com', { subscribed => 'no', limit => 50 });
    is scalar @{ $client->{urls} }, 3, 'every page';
    for my $url (@{ $client->{urls} }[1, 2]) {
        my %q = $url->query_form;
        is $q{subscribed}, 'no', "subscribed is put back on $url";
        is $q{limit}, 100, 'a key paging.next has is left as it is';
        is $q{page}, 'next', 'and the keys of paging.next are kept';
    }
    my %q = $next->query_form;
    is $q{subscribed}, 'no', 'on the second value too';
};

subtest 'a blessed hash is a query too' => sub {
    my $url = first_url_of(sub { $mailgun->lists(bless { limit => 10 }, 't::Query') });
    is_deeply { $url->query_form }, { limit => 10 };
};

subtest 'a query that is not a hash reference dies before any request' => sub {
    for my $call (
        [ lists        => sub { $mailgun->lists('limit=100') } ],
        [ list_members => sub { $mailgun->list_members('l@example.com', [ limit => 100 ]) } ],
    ) {
        my ($name, $code) = @$call;
        @{ $client->{urls} } = ();
        eval { $code->() };
        like $@, qr/^\Q$name\E\(\) takes a query hash reference/, $name;
        is_deeply $client->{urls}, [], 'nothing is requested';
    }
};

done_testing;
