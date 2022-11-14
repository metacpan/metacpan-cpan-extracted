use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::MockObject;
use Test::Warnings;
use Test::Fatal;
use IO::Async::Loop;
use JSON::MaybeUTF8 qw(decode_json_utf8);

use WebService::Async::Segment;
use WebService::Async::Segment::Customer;

my $base_uri = 'http://dummy/';

my $call_uri;
my $call_req;
my %call_http_args;
my $mock_http     = Test::MockModule->new('Net::Async::HTTP');
my $mock_response = '{"success":1}';
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
    write_key => 'DummyKey',
    base_uri  => $base_uri
);
my $loop = IO::Async::Loop->new;
$loop->add($segment);

my $customer_info = {
    user_id => '123456',
    traits  => {
        email => 'test@ghost.test',
        name  => 'Test Ghost',
    },
    anonymous_id => '987654',
    ivalid_xyz   => 'Invalid value'
};

like exception { WebService::Async::Segment::Customer->new() }, qr/Missing required arg api_client/,
    'Cannot create an onject without a segment api client';
like exception { WebService::Async::Segment::Customer->new(api_client => 'invalid value') }, qr/Invalid api_client value/,
    'Cannot create an onject with invalid api_client value';
my $customer = WebService::Async::Segment::Customer->new(api_client => $segment);
ok $customer, 'Created an object with setting the required argument';

$customer = $segment->new_customer(%$customer_info);

is($customer->$_, $customer_info->{$_}, "$_ is properly set by Customer constructor") for (qw(user_id anonymous_id));
is_deeply $customer->traits, $customer_info->{traits}, "traits are properly set by Customer constructor";
cmp_ok $customer->traits, '!=', $customer_info->{traits}, 'traits are deeply copied';

is $customer->{ivalid_xyz}, undef, 'Invalid args are filtered';

subtest 'Identify API call' => sub {
    $call_uri = $call_req = undef;
    undef %call_http_args;

    my $customer = $segment->new_customer();

    is($customer->$_, undef, "$_ is expectedly undefined after constructor is called") for (qw(user_id traits anonymous_id));

    my $result = $customer->identify()->block_until_ready;
    ok $result->is_failed, 'Request is failed';
    my @failure = $result->failure();
    is_deeply [@failure[0 .. 2]], ['ValidationError', 'segment', 'Both user_id and anonymous_id are missing'], 'Expectedly failed with no ID';

    $result = $customer->identify(anonymous_id => 1234)->get;

    ok $result, 'Successful identify call with anonymous_id';
    is $customer->anonymous_id, 1234,  'Object anonymous_id changed by calling identify';
    is $customer->user_id,      undef, 'Obect user_id is expectedly empty yet';
    test_call(
        'identify',
        {
            anonymousId => 1234,
            traits      => $customer->traits
        });

    delete $customer->{anonymous_id};
    $result = $customer->identify(user_id => 4321)->get;
    ok $result, 'Successful identify with user_id';
    is $customer->user_id,      4321,  'Object user_id changed by calling identify';
    is $customer->anonymous_id, undef, 'Object anonymous_id is still empty';
    test_call(
        'identify',
        {
            traits => $customer->traits,
            userId => 4321
        });

    my $call_args = {
        anonymous_id => 11112222,
        user_id      => 999990000,
        traits       => {
            email        => 'mail@test.com',
            custom_trait => 'custom value'
        },
        custom => {
            custom_arg1 => 'custom_value',
            custom_arg2 => 'custom_arg2'
        },
        context => {
            ip             => '1.2.3.4',
            custom_context => 'custom_xyz',
        }};

    $result = $customer->identify(%$call_args)->get;
    ok $result, 'successful call with full arg set';
    is $customer->$_, $call_args->{$_}, "Object $_ changed by calling identify" for (qw(user_id anonymous_id));
    is_deeply $customer->traits, $call_args->{traits}, "traits are properly set by Customer constructor";
    cmp_ok $customer->traits, '!=', $call_args->{traits}, 'traits are deeply copied';
    test_call(
        'identify',
        {
            traits      => $customer->traits,
            userId      => 999990000,
            anonymousId => 11112222,
            %{$call_args->{custom}}
        },
        $call_args->{context});

};

subtest 'Track API call' => sub {
    $call_uri = $call_req = undef;
    undef %call_http_args;

    my $customer = $segment->new_customer(traits => $customer_info->{traits});

    is($customer->{$_}, undef, "$_ is properly set by Customer constructor") for (qw(user_id anonymous_id));
    is_deeply $customer->{traits}, $customer_info->{traits}, "traits are properly set by Customer constructor";
    my $args = {};

    my $result = $customer->track(%$args)->block_until_ready;
    ok $result->is_failed, 'Request is failed';
    is_deeply [$result->failure], ['ValidationError', 'segment', 'Missing required argument "event"'], 'Expectedly failed with no event';

    my $event = 'Test Event';
    $args->{event} = $event;
    $result = $customer->track(%$args)->block_until_ready;
    ok $result->is_failed, 'Request is failed';
    is $result->failure, 'ValidationError', 'Expectedly failed because there was no ID';

    $customer->{anonymous_id} = 1234;
    $result = $customer->track(%$args, anonymous_id => 1)->get;
    ok $result, 'Successful track call with anonymous_id';
    test_call(
        'track',
        {
            event       => $event,
            anonymousId => 1234
        });

    delete $customer->{anonymous_id};
    $customer->{user_id} = 1234;
    $result = $customer->track(%$args)->get;
    ok $result, 'Successful track call with user_id';
    test_call(
        'track',
        {
            event  => $event,
            userId => 1234
        });

    delete $args->{anonymous_id};
    delete $args->{anonymous_id};

    my $properties = {
        property1 => 1,
        property2 => 2,
    };
    $args = {
        event        => $event,
        properties   => $properties,
        anonymous_id => 11112222,
        user_id      => 999990000,
        traits       => {
            email        => 'mail@test.com',
            custom_trait => 'custom value'
        },
        custom => {
            custom_arg1 => 'custom_value',
            custom_arg2 => 'custom_arg2'
        },
        context => {
            ip             => '1.2.3.4',
            custom_context => 'custom_xyz',
        }};

    $result = $customer->track(%$args)->get;
    ok $result, 'successful call with full arg set';
    cmp_ok $customer->$_ // '', 'ne', $args->{$_}, "Object $_ is not changed by calling track" for (qw(user_id anonymous_id));
    is_deeply $customer->traits, $customer_info->{traits}, 'Customer traits are not changes by calling track';
    test_call(
        'track',
        {
            event       => $event,
            properties  => $properties,
            traits      => undef,
            anonymousId => undef,
            userId      => 1234,
            %{$args->{custom}}
        },
        $args->{context});

};

subtest 'snake_case and camelCase' => sub {
    $call_uri = $call_req = undef;
    undef %call_http_args;

    my $customer_info = {
        userId       => 12345,
        anonymousId  => 54321,
        custom_filed => 'custom value'
    };
    my $customer = $segment->new_customer(%$customer_info);

    for my $snake (qw(user_id anonymous_id)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $customer->{$camel}, undef, "camelCase field $camel is removed";
        is($customer->{$snake}, $customer_info->{$camel}, "camelCase arg $camel is converted to snake_case $snake");
    }

    my $result = $customer->identify()->get;
    ok $result, 'Successful identify call';
    test_call(
        'identify',
        {
            userId       => 12345,
            anonymousId  => 54321,
            custom_filed => undef,
        });

    my $new_info = {
        userId       => 11111,
        anonymousId  => 22222,
        custom_filed => 'custom value',
    };
    $result = $customer->identify(%$new_info)->get;
    ok $result, 'Successful identify call with args';
    test_call(
        'identify',
        {
            userId       => 11111,
            anonymousId  => 22222,
            custom_filed => undef,
        });

    for my $snake (qw(user_id anonymous_id)) {
        my $camel = $snake;
        $camel =~ s/(_([a-z]))/uc($2)/ge;
        is $customer->{$camel}, undef, "camelCase field $camel is removed";
        is($customer->{$snake}, $new_info->{$camel}, "camelCase arg $camel is applied to customer's snake_case $snake");
    }
};

sub test_call {
    my ($method, $args, $context) = @_;
    is $call_uri, $base_uri . $method, "Correct uri for $method call";
    is_deeply \%call_http_args,
        {
        user         => $segment->{write_key},
        pass         => '',
        content_type => 'application/json'
        },
        'HTTP header is correct';

    my $json_req = decode_json_utf8($call_req);

    is_deeply $json_req->{context}->{library},
        {
        name    => 'WebService::Async::Segment',
        version => $WebService::Async::Segment::VERSION
        },
        'Context library is correct';

    my $sent_time = Time::Moment->from_string($json_req->{sentAt});
    ok $sent_time->is_after(Time::Moment->from_epoch(time - 2)),  'SentAt is not too early';
    ok $sent_time->is_before(Time::Moment->from_epoch(time + 1)), 'SentAt is not too late';

    for (keys %$context) {
        ref($context->{$_})
            ? is_deeply $context->{$_}, $json_req->{context}->{$_}, "Context $_ is sent correctly"
            : is $context->{$_}, $json_req->{context}->{$_}, "Context $_ is sent correctly";
    }
    for my $key (keys %$args) {
        ref($args->{$key})
            ? is_deeply($json_req->{$key}, $args->{$key}, "Value of arg $key is correct")
            : is($json_req->{$key}, $args->{$key}, "Value of arg $key is correct");
    }
}

done_testing();
