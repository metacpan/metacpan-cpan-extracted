use strict;
use warnings;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that records
# the method and the URL it is asked for, and answers every request with an empty success.
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub _record {
        my ($self, $method, $url) = @_;
        my $u = URI->new($url);
        $u->userinfo(undef);
        push @{ $self->{requests} }, "$method $u";
        return t::Response->new;
    }
    sub get    { $_[0]->_record(GET    => $_[1]) }
    sub post   { $_[0]->_record(POST   => $_[1]) }
    sub put    { $_[0]->_record(PUT    => $_[1]) }
    sub delete { $_[0]->_record(DELETE => $_[1]) }

    package t::Response;
    sub new        { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content    { '{"items":[],"list":{},"member":{}}' }
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

my $v3 = 'https://api.mailgun.net/v3';

subtest 'an address that worked before goes out as it is' => sub {
    is_deeply requests_of(sub { $mailgun->list('dev+news@example.com') }),
        ["GET $v3/lists/dev+news\@example.com"];
    is_deeply requests_of(sub { $mailgun->list_member('list@example.com', "o'brien\@example.com") }),
        ["GET $v3/lists/list\@example.com/members/o'brien\@example.com"];
};

subtest 'characters that would change the URL are percent-encoded' => sub {
    my %encoded = (
        'a?b@example.com' => 'a%3Fb@example.com',
        'a#b@example.com' => 'a%23b@example.com',
        'a/b@example.com' => 'a%2Fb@example.com',
        'a%b@example.com' => 'a%25b@example.com',
        'a b@example.com' => 'a%20b@example.com',
    );
    for my $address (sort keys %encoded) {
        is_deeply requests_of(sub { $mailgun->list($address) }),
            ["GET $v3/lists/$encoded{$address}"], "'$address'";
    }
};

subtest 'a decoded string is sent as UTF-8' => sub {
    my $address = "\x{e9}t\x{e9}\@example.com";
    utf8::upgrade($address);
    is_deeply requests_of(sub { $mailgun->list($address) }),
        ["GET $v3/lists/%C3%A9t%C3%A9\@example.com"];
};

subtest 'a string of UTF-8 bytes is not encoded twice' => sub {
    is_deeply requests_of(sub { $mailgun->list("\xc3\xa9t\xc3\xa9\@example.com") }),
        ["GET $v3/lists/%C3%A9t%C3%A9\@example.com"];
};

subtest 'a percent-encoded address is taken as it is, not decoded' => sub {
    is_deeply requests_of(sub { $mailgun->list('a%3Fb@example.com') }),
        ["GET $v3/lists/a%253Fb\@example.com"];
};

subtest 'an undefined or empty address dies before any request' => sub {
    for my $call (
        [ 'list(undef)'                       => sub { $mailgun->list(undef) } ],
        [ "list('')"                          => sub { $mailgun->list('') } ],
        [ 'delete_list_member($list, undef)'  => sub { $mailgun->delete_list_member('l@example.com', undef) } ],
        [ 'delete_template(undef)'            => sub { $mailgun->delete_template(undef) } ],
    ) {
        my ($name, $code) = @$call;
        my $requests = requests_of(sub { eval { $code->() } });
        like $@, qr/^an address or a name is required/, "$name dies";
        is_deeply $requests, [], 'nothing is requested';
    }
};

subtest 'every method that takes an address or a name' => sub {
    my $list   = 'a?b@example.com';
    my $member = 'c#d@example.com';
    my $l = 'a%3Fb@example.com';
    my $m = 'c%23d@example.com';
    is_deeply requests_of(sub {
        $mailgun->list($list);
        $mailgun->update_list($list, {});
        $mailgun->delete_list($list);
        $mailgun->list_members($list);
        $mailgun->add_list_member($list, {});
        $mailgun->add_list_members($list, {});
        $mailgun->list_member($list, $member);
        $mailgun->update_list_member($list, $member, {});
        $mailgun->delete_list_member($list, $member);
        $mailgun->delete_template('a/b');
    }), [
        "GET $v3/lists/$l",
        "PUT $v3/lists/$l",
        "DELETE $v3/lists/$l",
        "GET $v3/lists/$l/members/pages",
        "POST $v3/lists/$l/members",
        "POST $v3/lists/$l/members.json",
        "GET $v3/lists/$l/members/$m",
        "PUT $v3/lists/$l/members/$m",
        "DELETE $v3/lists/$l/members/$m",
        "DELETE $v3/example.com/templates/a%2Fb",
    ];
};

done_testing;
