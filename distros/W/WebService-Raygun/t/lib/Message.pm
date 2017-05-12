package Message;

use strict;
use warnings;

use parent qw(Test::Class);

use Test::More;
use Test::Deep;    # (); # uncomment to stop prototype errors
use Test::Exception;

use HTTP::Request;

#use Smart::Comments;

sub prep001_message_available : Test(startup => 1) {
    my $self = shift;
    use_ok('WebService::Raygun::Message')
      or $self->FAIL_ALL("Message class not available.");
}

sub t0010_validate_raygun_occurred_on : Test(3) {
    my $self = shift;
    my $message;
    lives_ok {
        $message =
          WebService::Raygun::Message->new(
            occurred_on => '2014-06-27T03:15:10+1300', );
    }
    'Instantiated Message object.';
    my $occurred_on = $message->occurred_on;
    isa_ok( $occurred_on, 'DateTime', 'Occurred on argument' );

    throws_ok {
        $message =
          WebService::Raygun::Message->new(
            occurred_on => '2014-06-27T03:15:10+200', );
    }
    qr{yyyy-mm-ddTHH:MM:SS\+HH},
      'Timestamp in incorrect format throws an error.';
}

sub t0020_validate_error_field : Test(4) {
    my $self = shift;
    my $message;
    lives_ok {
        $message = WebService::Raygun::Message->new(
            error => {
                stack_trace => [ { line_number => 34 } ]
            }
        );
    }
    'Instantiated Message object.';
    my $error = $message->error;
    isa_ok(
        $error,
        'WebService::Raygun::Message::Error',
        'Error is an error type'
    );
    isa_ok(
        $error->stack_trace->[0],
        'WebService::Raygun::Message::Error::StackTrace',
        'Stack trace is the correct type.'
    );
    throws_ok {
        WebService::Raygun::Message->new(
            error => {
                stackTrace => [ {} ]
            }
        );
    }
    qr{one\sstack\strace}, 'Error thrown as expected.';
}

sub t0021_catch_moose_exception : Test(2) {
    my $self = shift;
    eval {
        package Test::Moose;
        use Moose;
        extends;
    };
    if ( my $exception = $@ ) {
        my $message;
        lives_ok {
            $message = WebService::Raygun::Message->new( error => $exception );
        }
        'Initialised class using Moose exception.';
        isa_ok(
            $message->error,
            'WebService::Raygun::Message::Error',
            'Created an error object.'
        );
    }
}

sub t0022_catch_mouse_exception : Test(2) {
    my $self = shift;
    eval {
        package Test::Mouse;
        use Mouse;
        has something => (
            is       => 'rw',
            isa      => 'StupidData',
            required => 1,
            default  => sub {
                return 1;
            },
        );

        my $test = Test::Mouse->new;
    };
    if ( my $exception = $@ ) {
        my $error_type = ref $exception;

        ### mouse error : $error_type
        my $message;
        lives_ok {
            $message = WebService::Raygun::Message->new( error => $exception );
        }
        'Initialised class using ordinary exception.';
        isa_ok(
            $message->error,
            'WebService::Raygun::Message::Error',
            'Created an error object.'
        );
    }
}

sub t0030_validate_environment : Test(3) {
    my $self    = shift;
    my $message = WebService::Raygun::Message->new();
    lives_ok {
        $message->environment(
            {
                processor_count       => 2,
                cpu                   => 34,
                architecture          => 'x84',
                total_physical_memory => 3
            }
        );
    }
    'Set some environment fields';
    my $environment = $message->environment;
    isa_ok(
        $environment,
        'WebService::Raygun::Message::Environment',
        'HashRef intantiated correct environment'
    );
    my $api_data = $environment->prepare_raygun;
    cmp_deeply(
        $api_data,
        superhashof(
            {
                processorCount      => 2,
                cpu                 => 34,
                architecture        => 'x84',
                totalPhysicalMemory => 3
            }
        ),
        'Received expected data for API'
    );
}

sub t0040_validate_request : Test(2) {
    my $self    = shift;
    my $request = HTTP::Request->new(
        POST => 'https://www.null.com',
        [ 'Content-Type' => 'text/html', ]
    );
    my $message;
    lives_ok {
        $message = WebService::Raygun::Message->new( request => $request );
    }
    'Set the request field';
    $request = $message->request;
    isa_ok(
        $request,
        'WebService::Raygun::Message::Request',
        'Request attribute is expected type'
    );

    my $data = $request->prepare_raygun;
    ### data : $data
}

sub t0050_generate_entire_message : Test(1) {
    my $self    = shift;
    my $message = WebService::Raygun::Message->new(
        user => 'test@mail.com',
        client => {
            name      => 'something',
            version   => 2,
            clientUrl => 'www.null.com'
        },
        occurred_on => '2014-06-27T03:15:10+1300',
        error       => {
            stack_trace => [ { line_number => 34 } ]
        },
        environment => {
            processor_count       => 2,
            cpu                   => 34,
            architecture          => 'x84',
            total_physical_memory => 3
        },
        request => HTTP::Request->new(
            GET => 'https://www.null.com?q=Search&time=today&lang=english',
            [ 'Content-Type' => 'text/html', ]
        ),
    );

    my $ready_for_raygun = $message->prepare_raygun;
    ### result : $ready_for_raygun
    cmp_deeply(
        $ready_for_raygun,
        superhashof( {} ),
        'We got something at least'
    );

}

sub t0060_error_with_string_only : Test(1) {
    my $self = shift;
    my $message;
    lives_ok {
        $message = WebService::Raygun::Message->new(
            occurred_on => '2014-06-27T03:15:10+1300',
            error       => "This is my error!",
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
        );

    }
    'Instantiated a message with string for error.';


}

sub t0070_error_with_array_strings : Test(1) {
    my $self = shift;
    my $message;
    lives_ok {
        $message = WebService::Raygun::Message->new(
            user => 12345,
            occurred_on => '2014-06-27T03:15:10+1300',
            error       => ["This is my error!", "Another error!"],
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
        );

    }
    'Instantiated a message with an array of strings for error.';


}

1;

__END__
