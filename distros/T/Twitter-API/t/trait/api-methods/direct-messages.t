#!perl
use 5.14.1;
use warnings;
use Test::Spec;

use Twitter::API;

describe direct_messages => sub {
    my $client;
    my $is_stub_test;
    my $new_message_id;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits              => 'ApiMethods',
            consumer_key        => 'key',
            consumer_secret     => 'secret',
            access_token        => 'token',
            access_token_secret => 'token-secret',
        );
        if ($client->consumer_key eq 'key') {
            $client->stubs(send_request => sub { return });
            $is_stub_test = 1;
        }
    };

    it 'new_direct_messages_event' => sub {
        my $user_id_str = $client->verify_credentials()->{id_str};
        my $context = $client->new_direct_messages_event('test message ' . time, $user_id_str);
        if ($is_stub_test) {
            ok $context->http_request->method eq 'POST' && $context->http_request->uri =~ m'/direct_messages/events/new\.json$' && $context->http_request->content;
            $new_message_id = 'dummy';
        } else {
            ok(exists $context->{event});
            $new_message_id = $context->{event}->{id};
        }
    };
    it 'direct_messages_events' => sub {
        my $context = $client->direct_messages_events();
        if ($is_stub_test) {
            ok $context->http_request->method eq 'GET' && $context->http_request->uri =~ m'/direct_messages/events/list\.json$';
        } else {
            ok(exists $context->{events} && @{ $context->{events} } > 0);
        }
    };
    it 'show_direct_messages_event' => sub {
        my $context = $client->show_direct_messages_event($new_message_id);
        if ($is_stub_test) {
            ok $context->http_request->method eq 'GET' && $context->http_request->uri =~ m'/direct_messages/events/show\.json\?id=dummy$';
        } else {
            ok(exists $context->{event});
        }
    };
    it 'destroy_direct_messages_event' => sub {
        my $context = $client->destroy_direct_messages_event($new_message_id);
        if ($is_stub_test) {
            ok $context->http_request->method eq 'DELETE' && $context->http_request->uri =~ m'/direct_messages/events/destroy\.json\?id=dummy$';
        } else {
            ok($context eq '');
        }
    };
};

runtests;
