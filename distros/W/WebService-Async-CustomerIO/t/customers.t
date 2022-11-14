use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MockObject;
use Test::MockObject::Extends;

use Future;

use WebService::Async::CustomerIO;
use WebService::Async::CustomerIO::Customer;

subtest 'Creating API client' => sub {
    my @tests = ([{id => 1}, qr/^Missing required argument: api_client/], [{api_client => 1}, qr/^Missing required argument: id/],);

    for my $test_case (@tests) {
        my $err = exception { WebService::Async::CustomerIO::Customer->new(%{$test_case->[0]}) };
        like $err, $test_case->[1], "Got Expected error";
    }

    ok(
        WebService::Async::CustomerIO::Customer->new(
            id         => 1,
            api_client => 1
        ),
        'Api Client created'
    );
};

subtest 'Getters methods' => sub {
    my $time     = time;
    my $customer = WebService::Async::CustomerIO::Customer->new(
        id         => 'some_id',
        api_client => 'some_api_client',
        email      => 'user@example.com',
        created_at => $time,
        attributes => {some => 'data'},
    );

    is $customer->api,        'some_api_client',  'Get api client';
    is $customer->id,         'some_id',          'Get id';
    is $customer->email,      'user@example.com', 'Get email';
    is $customer->created_at, $time,              'created_at';
    is_deeply $customer->attributes, {some => 'data'}, 'Get attributes';
};

subtest 'Api Methods tests' => sub {
    my $time = time;
    my $api  = WebService::Async::CustomerIO->new(
        site_id   => 'some_site_id',
        api_key   => 'some_api_key',
        api_token => 'some_api_key'
    );

    $api = Test::MockObject::Extends->new($api);
    $api->mock(
        tracking_request => sub {
            my %h;
            @h{qw(method uri data)} = @_[1 .. 3];
            Future->done(\%h);
        });

    my $customer = WebService::Async::CustomerIO::Customer->new(
        api_client => $api,
        id         => 'some_id',
        email      => 'user@example.com',
        created_at => $time,
        attributes => {some => 'data'},
    );

    subtest 'upsert' => sub {
        my $response = $customer->upsert->get;
        is $response->{method}, 'PUT',               'Method is correct';
        is $response->{uri},    'customers/some_id', 'URI is correct';
        is_deeply $response->{data},
            {
            email      => 'user@example.com',
            created_at => $time,
            some       => 'data'
            },
            'Data is correct';
    };

    subtest 'set_attribute' => sub {
        my $response = $customer->set_attribute(test => 'value')->get;
        is $response->{method}, 'PUT',               'Method is correct';
        is $response->{uri},    'customers/some_id', 'URI is correct';
        is_deeply $response->{data}, {test => 'value'}, 'Data is correct';
    };

    subtest 'remove_attribute' => sub {
        my $response = $customer->remove_attribute('test')->get;
        is $response->{method}, 'PUT',               'Method is correct';
        is $response->{uri},    'customers/some_id', 'URI is correct';
        is_deeply $response->{data}, {test => ''}, 'Data is correct';
    };

    subtest 'suppress' => sub {
        my $response = $customer->suppress->get;
        is $response->{method}, 'POST',                       'Method is correct';
        is $response->{uri},    'customers/some_id/suppress', 'URI is correct';
        is_deeply $response->{data}, undef, 'Data is correct';
    };

    subtest 'unsuppress' => sub {
        my $response = $customer->unsuppress->get;
        is $response->{method}, 'POST',                         'Method is correct';
        is $response->{uri},    'customers/some_id/unsuppress', 'URI is correct';
        is_deeply $response->{data}, undef, 'Data is correct';
    };

    subtest 'upsert_device' => sub {
        my $response = $customer->upsert_device(
            device_id => 'some_device_id',
            platform  => 'ios',
            last_used => $time,
        )->get;
        is $response->{method}, 'PUT',                       'Method is correct';
        is $response->{uri},    'customers/some_id/devices', 'URI is correct';
        is_deeply $response->{data},
            {
            device => {
                id        => 'some_device_id',
                platform  => 'ios',
                last_used => $time
            }
            },
            'Data is correct';

        $response = $customer->upsert_device(
            device_id => 'some_device_id',
            platform  => 'android',
            last_used => $time,
        )->get;

        is $response->{method}, 'PUT',                       'Method is correct';
        is $response->{uri},    'customers/some_id/devices', 'URI is correct';
        is_deeply $response->{data},
            {
            device => {
                id        => 'some_device_id',
                platform  => 'android',
                last_used => $time
            }
            },
            'Data is correct';
        my $err = exception { $customer->upsert_device(platform => 'ios') };
        like $err, qr/^Missing required argument: device_id/, "Got error for missing device_id";
        $err = exception { $customer->upsert_device(device_id => 'some_id') };
        like $err, qr/^Missing required argument: platform/, "Got error for missing platform";
        $err = exception { $customer->upsert_device(device_id => 'some_id', platform => 'win') };
        like $err, qr/^Invalid value for platform: win/, "Got error for invalid platform";
    };

    subtest 'delete_device' => sub {
        my $response = $customer->delete_device('some_device_id')->get;
        is $response->{method}, 'DELETE',                                   'Method is correct';
        is $response->{uri},    'customers/some_id/devices/some_device_id', 'URI is correct';
        is_deeply $response->{data}, undef, 'Data is correct';
        my $err = exception { $customer->delete_device };
        like $err, qr/^Missing required argument: device_id/, "Got error for missing device_id";
    };

    subtest 'delete_customer' => sub {
        my $response = $customer->delete_customer()->get;
        is $response->{method}, 'DELETE',            'Method is correct';
        is $response->{uri},    'customers/some_id', 'URI is correct';
        is_deeply $response->{data}, undef, 'Data is correct';
    };

    subtest 'emit_event' => sub {
        my $response = $customer->emit_event(
            name => 'some_event',
            some => 'data'
        )->get;
        is $response->{method}, 'POST',                     'Method is correct';
        is $response->{uri},    'customers/some_id/events', 'URI is correct';
        is_deeply $response->{data},
            {
            name => 'some_event',
            some => 'data'
            },
            'Data is correct';
        my $err = exception { $customer->emit_event };
        like $err, qr/^Missing required argument: name/, "Got error for missing device_id";
    };
};

done_testing;
