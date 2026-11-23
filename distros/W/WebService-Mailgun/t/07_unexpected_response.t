use strict;
use warnings;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

# This test never reaches a real API server: the HTTP client is replaced with one that answers
# from the queue of responses it is given. Each response is [status, body].
{
    package t::Client;
    sub new { my ($class, @responses) = @_; bless { responses => [@responses], urls => [] }, $class }
    sub _next {
        my ($self, $url) = @_;
        push @{ $self->{urls} }, $url;
        my $r = shift @{ $self->{responses} } or die "no response left for $url\n";
        return t::Response->new(@$r);
    }
    sub get    { $_[0]->_next($_[1]) }
    sub delete { $_[0]->_next($_[1]) }

    package t::Response;
    sub new         { my ($class, $status, $body) = @_; bless { status => $status, body => $body }, $class }
    sub is_success  { $_[0]{status} =~ /^2/ }
    sub status_line { "$_[0]{status} Status" }
    sub content     { $_[0]{body} }
}

sub mailgun {
    my ($raise, @responses) = @_;
    my $mailgun = WebService::Mailgun->new(
        api_key    => 'dummy-api-key',
        domain     => 'example.com',
        RaiseError => $raise,
    );
    $mailgun->{_client} = t::Client->new(@responses);
    return $mailgun;
}

my $lists = 'https://api.mailgun.net/v3/lists/pages';

subtest 'a failure whose body is JSON but not an object' => sub {
    my $mailgun = mailgun(0, [400, '[1]']);
    my $res = eval { $mailgun->list('l@example.com') };
    is $@, '', 'does not die';
    ok !$res, 'returns nothing';
    is $mailgun->error, '[1]', 'error is the body';
    is $mailgun->error_status, '400 Status';
};

subtest 'a failure whose body is an object without message' => sub {
    my $mailgun = mailgun(0, [400, '{"reason":"x"}']);
    ok !$mailgun->list('l@example.com');
    is $mailgun->error, '{"reason":"x"}', 'error is the body';
};

subtest 'a failure whose message is not a string gives the body' => sub {
    my $mailgun = mailgun(0, [400, '{"message":{"code":1}}']);
    ok !$mailgun->list('l@example.com');
    is $mailgun->error, '{"message":{"code":1}}';
};

subtest 'a failure with a message still gives the message' => sub {
    my $mailgun = mailgun(0, [404, '{"message":"List not found"}']);
    ok !$mailgun->list('l@example.com');
    is $mailgun->error, 'List not found';
};

subtest 'a success whose body is not a JSON object is a failure' => sub {
    for my $body ('OK', '[1]', '"text"') {
        my $mailgun = mailgun(0, [200, $body]);
        my $res = eval { $mailgun->delete_list('l@example.com') };
        is $@, '', "'$body' does not die";
        ok !$res, 'returns nothing';
        like $mailgun->error, qr/^the response is not a JSON object/, 'error says why';
        is $mailgun->error_status, '200 Status';
    }
};

subtest 'a long body is cut short in error' => sub {
    my $mailgun = mailgun(0, [200, '<html>' . ('x' x 1000)]);
    ok !$mailgun->delete_list('l@example.com');
    is length $mailgun->error, length('the response is not a JSON object: ') + 200 + 3;
    like $mailgun->error, qr/\.\.\.\z/;
};

subtest 'a success with an empty body is a success with nothing in it' => sub {
    my $mailgun = mailgun(0, [204, '']);
    is_deeply $mailgun->delete_list('l@example.com'), {};
    is $mailgun->error, undef, 'error is not set';
};

subtest 'with RaiseError, it dies with the status line' => sub {
    my $mailgun = mailgun(1, [200, 'OK']);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $mailgun->delete_list('l@example.com') };
    like $@, qr/^200 Status/;
    like $warnings[0], qr/^the response is not a JSON object/, 'warns with the error';
};

subtest 'a page without items is a failure, with the URL of that page' => sub {
    my $mailgun = mailgun(0,
        [200, qq({"items":[{"id":"a"}],"paging":{"next":"$lists/2"}})],
        [200, '{"paging":{}}'],
    );
    my ($items, $next) = eval { $mailgun->lists() };
    is $@, '', 'does not die';
    is_deeply [ map { $_->{id} } @$items ], ['a'], 'the items fetched before it';
    is "$next", "$lists/2", 'the second value is the URL of the page, without the API key';
    is $mailgun->error, "the response has no 'items' list";
};

subtest 'a page without items dies with RaiseError' => sub {
    my $mailgun = mailgun(1, [200, '{"items":{}}']);
    local $SIG{__WARN__} = sub {};
    eval { $mailgun->lists() };
    like $@, qr/^200 Status/;
};

subtest 'a page with no paging.next is the last one, and gives its own URL' => sub {
    for my $page (
        '{"items":[{"id":"a"}]}',
        '{"items":[{"id":"a"}],"paging":{}}',
        '{"items":[{"id":"a"}],"paging":"x"}',
        '{"items":[]}',
    ) {
        my $mailgun = mailgun(0, [200, $page]);
        my ($items, $next) = eval { $mailgun->lists() };
        is $@, '', "$page does not die";
        is scalar @$items, ($page =~ /"id"/ ? 1 : 0), 'the items';
        isa_ok $next, 'URI', 'not undef: event(undef) would fetch every event again';
        is "$next", $lists, 'the URL of that page, without the API key';
        is scalar @{ $mailgun->{_client}{urls} }, 1, 'nothing more is requested';
    }
};

subtest 'a paging.next that points back stops, as a failure' => sub {
    my $mailgun = mailgun(0,
        [200, qq({"items":[{"id":"a"}],"paging":{"next":"$lists/2"}})],
        [200, qq({"items":[{"id":"b"}],"paging":{"next":"$lists"}})],
    );
    my ($items, $next) = eval { $mailgun->lists() };
    is $@, '', 'does not die';
    is_deeply [ map { $_->{id} } @$items ], [qw(a b)], 'each page once';
    is scalar @{ $mailgun->{_client}{urls} }, 2, 'no page is fetched twice';
    is $mailgun->error, "paging.next points back to $lists";
    is $mailgun->error_status, '200 Status';
    is "$next", $lists, 'without the API key';
};

subtest 'a paging.next not on the API host over https is a failure' => sub {
    for my $page_next ('/v3/lists/pages?page=2', 'http://api.mailgun.net/v3/lists/2', 'https://evil.example.com/v3/lists/2') {
        my $mailgun = mailgun(0,
            [200, qq({"items":[{"id":"a"}],"paging":{"next":"$page_next"}})],
        );
        my ($items, $next) = eval { $mailgun->lists() };
        is $@, '', "'$page_next' does not die";
        is_deeply [ map { $_->{id} } @$items ], ['a'], 'the items of the page';
        is scalar @{ $mailgun->{_client}{urls} }, 1, 'the API key goes nowhere else';
        is $mailgun->error, 'paging.next is not an https URL on api.mailgun.net';
        is "$next", $lists, 'the URL of that page';
    }
};

done_testing;
