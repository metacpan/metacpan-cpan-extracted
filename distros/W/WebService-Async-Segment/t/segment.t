use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::MockObject;
use Test::Warnings;
use Time::Moment;

use WebService::Async::Segment;
use JSON::MaybeUTF8 qw(decode_json_utf8);
use IO::Async::Loop;

my $base_uri = 'http://dummy/';

my $call_uri;
my $call_req;
my %call_http_args;
my $mock_http     = Test::MockModule->new('Net::Async::HTTP');
my $mock_response = '{\n "success":1 \n }';
my $code;

$mock_http->mock(
    'POST' => sub {
        (undef, $call_uri, $call_req, %call_http_args) = @_;

        return $mock_response if $mock_response->isa('Future');

        my $response = $mock_response;
        $code = 200;

        unless ($call_uri =~ /(identify|track)$/) {
            $response = '404 Not Found';
            $code     = 404;
        }

        my $res = Test::MockObject->new();
        $res->mock(content => sub { $response });
        $res->mock(code    => sub { $code });
        Future->done($res);
    });

my $segment = WebService::Async::Segment->new(
    write_key => 'test_token',
    base_uri  => $base_uri
);
my $loop = IO::Async::Loop->new;
$loop->add($segment);

subtest 'call validation' => sub {
    my $result = $segment->method_call()->block_until_ready;
    ok $result->is_failed(), 'Expected failure with no method';
    my @failure = $result->failure;
    is_deeply [@failure[0 .. 2]], ['ValidationError', 'segment', 'Method name is missing'], "Correct error message for call without ID";

    $result = $segment->method_call('invalid_call', user_id => 'Test User')->block_until_ready;
    ok $result->is_failed(), 'Invalid request will fail';
    @failure = $result->failure;
    is_deeply [@failure[0 .. 2]], ['RequestFailed', 'segment', '404 Not Found'], 'Expected error detail for invalid uri';

    $result = $segment->method_call('identify')->block_until_ready;
    ok $result->is_failed(), 'Expected failure without id';
    @failure = $result->failure;
    is_deeply [@failure[0 .. 2]], ['ValidationError', 'segment', 'Both user_id and anonymous_id are missing'],
        "Correct error message for call without ID";

    $result = $segment->method_call('identify', user_id => 'Test User');
    ok $result, 'Result is OK with user_id';

    $mock_response = Future->fail('Dummy Failure', 'http POST', 'Just for test');
    $result        = $segment->method_call('identify', user_id => 'Test User')->block_until_ready;
    ok $result->is_failed(), 'Expected failure when POST fails';
    @failure = $result->failure;
    is_deeply [@failure[0 .. 2]], ['Dummy Failure', 'http POST', 'Just for test'], "Correct error details for POST failure";

    $mock_response = '{\n "success":1 \n }';

    $result = $segment->method_call('identify', anonymous_id => 'Test anonymous_id');
    ok $result, 'Result is OK with anonymous_id';
};

subtest 'args validation' => sub {
    my $epoch  = time();
    my $result = $segment->method_call('track', user_id => 'Test User2');

    is $call_uri, $base_uri . 'track', 'Uri is correct';
    my $json_req = decode_json_utf8($call_req);

    is_deeply $json_req->{context}->{library},
        {
        name    => 'WebService::Async::Segment',
        version => $WebService::Async::Segment::VERSION,
        },
        'Context library is valid';
    is $json_req->{userId}, 'Test User2', 'Json args are correct';
    ok $json_req->{sentAt}, 'SentAt is set by API wrapper';
    my $sent_time = Time::Moment->from_string($json_req->{sentAt});

    ok $sent_time->is_after(Time::Moment->from_epoch($epoch - 1)),  'SentAt is not too early';
    ok $sent_time->is_before(Time::Moment->from_epoch($epoch + 1)), 'SentAt is not too late';

    is_deeply \%call_http_args,
        {
        user         => $segment->{write_key},
        pass         => '',
        content_type => 'application/json'
        },
        'HTTP header is correct';

};

subtest 'snake_case to camelCase' => sub {
    my $epoch = time();

    my %args = (
        user_id      => 'user1',
        anonymous_id => 'anonymous2',
        sent_at      => Time::Moment->now_utc->to_string(),
        custom_field => 'custom3'
    );
    my %context = (
        user_agent     => 'Mozila',
        group_id       => '1234',
        custom_context => 'custom4'
    );
    my %device = (
        advertising_id      => '111111',
        ad_tracking_enabled => 1,
        custom_device       => 'custom5'
    );

    my %traits = (
        first_name   => 'Ali',
        last_name    => 'XYX',
        created_at   => '2000-01-02',
        custom_trait => 'value1',
        address      => {
            postal_code => '54-56-77',
        },
    );

    my $result = $segment->method_call(
        'track', %args,
        traits  => {%traits},
        context => {%context, device => {%device}});

    my $json_req = decode_json_utf8($call_req);

    is_deeply $json_req->{context}->{library},
        {
        name    => 'WebService::Async::Segment',
        version => $WebService::Async::Segment::VERSION,
        },
        'Context library is valid';

    for my $snake (qw(user_id anonymous_id sent_at)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $json_req->{$snake}, undef, "snake_case field $snake is removed";
        is($json_req->{$camel}, $args{$snake}, "snake_case arg $snake is converted to camelCase $camel");
    }
    is $json_req->{custom_field}, $args{custom_field}, "Custom filed is kept in snake_case";
    is $json_req->{customField},  undef,               'Custom filed is not converted to camelCase';

    for my $snake (qw(user_agent group_id)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $json_req->{context}->{$snake}, undef,            "snake_case context field $snake is removed";
        is $json_req->{context}->{$camel}, $context{$snake}, "snake_case context filed $snake is converted to camelCase $camel";
    }
    is $json_req->{context}->{custom_context}, $context{custom_context}, "Custom context filed is kept in snake_case";
    is $json_req->{context}->{customContext},  undef,                    'Custom context filed is not converted to camelCase';

    for my $snake (qw(advertising_id ad_racking_enabled)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $json_req->{context}->{device}->{$snake}, undef,           "snake_case device field $snake is removed";
        is $json_req->{context}->{device}->{$camel}, $device{$snake}, "snake_case device filed $snake is converted to camelCase $camel";
    }
    is $json_req->{context}->{device}->{custom_device}, $device{custom_device}, "Custom device filed is kept in snake_case";
    is $json_req->{context}->{device}->{customDevice},  undef,                  'Custom device filed is not converted to camelCase';

    for my $snake (qw(first_name last_name created_at)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $json_req->{traits}->{$snake}, undef,           "snake_case trait $snake is removed";
        is $json_req->{traits}->{$camel}, $traits{$snake}, "snake_case trait $snake is converted to camelCase $camel";
    }
    is $json_req->{traits}->{address}->{postal_code}, undef, "snake_case trait address->postal_code is removed";
    is $json_req->{traits}->{address}->{postalCode}, $traits{address}->{postal_code},
        "snake_case trait address->postal_code is converted to camelCase address->postalCode";
    is $json_req->{traits}->{custom_trait}, $traits{custom_trait}, "Custom trait is kept in snake_case";
    is $json_req->{traits}->{customTrait},  undef,                 'Custom trait is not converted to camelCase';
};

done_testing();

$mock_http->unmock_all;
