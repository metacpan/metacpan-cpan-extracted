package Messenger;

use strict;
use warnings;

use parent qw(Test::Class);

use Test::More;
use Test::Deep;    # (); # uncomment to stop prototype errors
use Test::Exception;

use HTTP::Request;

#use Smart::Comments;

sub prep001_messenger_available : Test(startup => 2) {
    my $self = shift;
    use_ok('WebService::Raygun::Messenger')
        or $self->FAIL_ALL('Messenger class not available.');
    use_ok('WebService::Raygun::Message')
        or $self->FAIL_ALL('Message class not available.');

}

sub t0010_raygun_http_403_response : Test(2) {
    my $self      = shift;
    my $messenger = WebService::Raygun::Messenger->new(
        api_key => '',
        message => test_message());
    my $result;
    lives_ok {
        $result = $messenger->fire_raygun();
    }
    'Called Raygun.io';
    cmp_ok($result->code, '>=', 403, 'Expect a "Bad Request" error.');
}

sub t0020_raygun_http_ok_response : Test(2) {
    my $self    = shift;
    my $api_key = $ENV{RAYGUN_API_KEY};
    if (not defined $api_key) {
        $self->SKIP_ALL('No API key for Raygun.io. No point in continuing.');
    }
    $self->{api_key} = $api_key;
    my $messenger = WebService::Raygun::Messenger->new(
        api_key => $self->{api_key},
        message => test_message());
    my $result;
    lives_ok {
        $result = $messenger->fire_raygun;
    }
    'Called Raygun.io';

    cmp_ok($result->code, '<', 400, 'Expect a "Bad Request" error.');
}

sub t0030_init_with_string_as_message : Test(1) {
    my $self = shift;

    my $messenger;
    lives_ok {
        $messenger = WebService::Raygun::Messenger->new(
            api_key => 'wMqgsBks1FfJihdrA2Aydg==',
            message => {
                user  => 'null@null.com',
                error => "string whatever",
            });
    }
    'No problem instantiating a messenger';

}

sub test_message {
    my $message = {
        user   => 'null@null.com',
        client => {
            name      => 'something',
            version   => 2,
            clientUrl => 'www.null.com'
        },
        error => {
            stack_trace => [ { line_number => 34 } ]
        },
        environment => {
            processor_count       => 2,
            cpu                   => 34,
            architecture          => 'x84',
            total_physical_memory => 3
        },
        request => HTTP::Request->new(
            POST => 'https://www.null.com',
            [ 'Content-Type' => 'text/html', ]
        ),
    };
    return $message;
}

1;

__END__
