package WebService::Raygun::Message;
$WebService::Raygun::Message::VERSION = '0.030';
# VERSION

use Mouse;
use Try::Tiny;
use Carp 'croak';

=head1 NAME

WebService::Raygun::Message - A message to be sent to raygun.io

=head1 SYNOPSIS

  use WebService::Raygun::Message;
  my $message = WebService::Raygun::Message->new(
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

  # test stuff

=head1 DESCRIPTION

You generally should not need to create instances of this class

=head1 DESCRIPTION

This module assembles a request for raygun.io.


=head1 INTERFACE

=cut

use DateTime;
use DateTime::Format::Strptime;
use POSIX ();

use WebService::Raygun::Message::Error;
use WebService::Raygun::Message::Environment;
use WebService::Raygun::Message::Request;
use WebService::Raygun::Message::User;

use Mouse::Util::TypeConstraints;

subtype 'RaygunMessage' => as 'Object' => where {
    $_->isa('WebService::Raygun::Message');
};

coerce 'RaygunMessage' => from 'HashRef' => via {
    return WebService::Raygun::Message->new( %{$_} );
};

subtype 'OccurredOnDateTime' => as 'Object' => where {
    $_->isa('DateTime');
};

coerce 'OccurredOnDateTime' => from 'Str' => via {
    my $parser = DateTime::Format::Strptime->new(
        pattern   => '%FT%T%z',
        time_zone => 'UTC',
        on_error  => sub {
            confess
              'Expect time in the following format: yyyy-mm-ddTHH:MM:SS+HHMM';
        }
    );
    return $parser->parse_datetime($_);
};

no Mouse::Util::TypeConstraints;

=head2 occurred_on

Time the error occurred. This can be either:

=over 2

=item  L<DateTime|DateTime> object

=item C<string>

Should have format C<YYYY-mm-ddTHH:MM:SSz>.


=back

Must be a valid datetime with timezone offset, eg 2014-06-30T04:30:30+100. Defaults to current time.

=cut

has occurred_on => (
    is      => 'rw',
    isa     => 'OccurredOnDateTime',
    coerce  => 1,
    default => sub {
        return DateTime->now( time_zone => 'UTC' );
    },
);

=head2 error

The error. Can be one of the following:

=over 2

=item C<string>

This could be the output of something like L<croak|Carp/croak> or C<die>.

=item An exception object

See L<WebService::Raygun::Message::Error|WebService::Raygun::Message::Error> for a list of supported exception types.


=item L<WebService::Raygun::Message::Error|WebService::Raygun::Message::Error> 

If possible, the other data types are converted to an instance of this class.

=back

=cut

has error => (
    is       => 'rw',
    isa      => 'MessageError',
    coerce   => 1,
    default => sub {
        my $exception;
        try {
            croak "Default error message. If you are seeing this,"
            ."it means the developer has not passed in an error object.";
        }
        catch { 
            $exception = $_; 
        };
        return $exception;
    },
);

=head2 user

Accepts any one of the following:


=over 2

=item C<string>

A string containing an email (eg. C<test@test.com>).

=item C<integer>

=item C<HASHREF>

Key/values should be a subset of the following:

        {
            identifier   => "someidentifier",
            email        => 'test@test.com',
            is_anonymous => 1|0|undef,
            full_name    => 'Firstname Lastname',
            first_name   => 'Firstname',
            uuid         => '783491e1-d4a9-46bc-9fde-9b1dd9ef6c6e'
        }

All the fields are optional, however if C<uuid> is not supplied, one will be generated automatically. 


=back

These will all be coerced into an object of type L<WebService::Raygun::Message::User|WebService::Raygun::Message::User>.

=cut

has user => (
    is      => 'rw',
    isa     => 'RaygunUser',
    coerce  => 1,
    default => sub {
        return {};
    }
);

=head2 request

A I<request> object.  See L<WebService::Raygun::Message::Request|WebService::Raygun::Message::Request> for a list of supported types.


=cut

has request => (
    is      => 'rw',
    isa     => 'Request',
    coerce  => 1,
    default => sub { return {}; },
);

=head2 environment


See L<WebService::Raygun::Message::Environment|WebService::Raygun::Message::Environment>.


=cut

has environment => (
    is      => 'rw',
    isa     => 'Environment',
    coerce  => 1,
    default => sub {
        return {};
    }
);

=head2 user_custom_data

Some data from the user.

=cut

has user_custom_data => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {};
    },
);

=head2 tags


=cut

has tags => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        return [];
    },
);

=head2 grouping_key 

=cut

has grouping_key => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=head2 version


=cut

has version => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return '0.1';
    },
);

=head2 machine_name


=cut

has machine_name => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return (POSIX::uname)[1];
    },
);

=head2 response_status_code

Default is 200.

=cut

has response_status_code => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        return 200;
    },
);

=head2 client


=cut

sub client {
    my $self = shift;

    return {
        name      => 'WebService::Raygun',
        version   => $self->VERSION,
        clientUrl => 'https://metacpan.org/pod/WebService::Raygun'
    };
}

=head2 prepare_raygun

Converts a Perl hash to JSON.

=cut

sub prepare_raygun {
    my $self      = shift;
    my $formatter = DateTime::Format::Strptime->new(
        pattern   => '%FT%TZ',
        time_zone => 'UTC',
    );
    my $occurred_on = $formatter->format_datetime( $self->occurred_on );
    my $data        = {
        occurredOn => $occurred_on,
        details    => {
            groupingKey    => $self->grouping_key,
            userCustomData => $self->user_custom_data,
            machineName    => $self->machine_name,
            error          => $self->error->prepare_raygun,
            version        => $self->version,
            client         => $self->client,
            request        => $self->request->prepare_raygun,
            environment    => $self->environment->prepare_raygun,
            tags           => $self->tags,
            user           => $self->user->prepare_raygun,
            response       => {
                statusCode => $self->response_status_code,
            }
        }
    };
    return $data;
}

=head1 DEPENDENCIES

=cut

=head1 SEE ALSO

=over 2

=item L<WebService::Raygun::Message::Request|WebService::Raygun::Message::Request>


=item L<WebService::Raygun::Message::Environment|WebService::Raygun::Message::Environment>

=item L<WebService::Raygun::Message::Error|WebService::Raygun::Message::Error>


=item L<WebService::Raygun::Message::Error::StackTrace|WebService::Raygun::Message::Error::StackTrace>



=back


=cut

__PACKAGE__->meta->make_immutable();

1;

__END__
