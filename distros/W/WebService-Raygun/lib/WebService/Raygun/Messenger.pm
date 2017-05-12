package WebService::Raygun::Messenger;
$WebService::Raygun::Messenger::VERSION = '0.030';
use Mouse;

#use Smart::Comments;

=head1 NAME

WebService::Raygun::Messenger - Communicate with the Raygun.io endpoint.

=head1 SYNOPSIS

  use Try::Tiny;
  use WebService::Raygun::Messenger;

    sub some_code {

        try {
            # Code that throws an exception
            # ...
        }
        catch {
            my $exception = $_;

            my $message = {
                error => $exception,        # $@ or framework exception (eg. Moose::Exception)
                request => $request_object, # i.e. HTTP::Request, Catalyst::Request, etc.

                #... other params
            };

            # initialise raygun.io messenger
            my $raygun = WebService::Raygun::Messenger->new(
                api_key => '<your raygun.io api key>',
                message => $message
            );
            # send message to raygun.io
            my $response = $raygun->fire_raygun;
            
        };
    }




=head1 DESCRIPTION

Send a request to raygun.io. 

L<WebService::Raygun::Messenger|WebService::Raygun::Messenger>, as well as most of the other classes in this package, accepts a C<HASHREF> in the constructor which is then coerced into datatypes that will eventually be sent to Raygun. It is generally not necessary to initialise any of these objects yourself. For the most part, the class hierarchy in this package maps to the API shown on the Raygun L<api docs|https://raygun.io/docs/integrations/api>.

=head1 INTERFACE

=cut

=head2 api_key

Your raygun.io API key. By default, this will be whatever is in the
C<RAYGUN_API_KEY> environment variable.

=cut

use LWP::UserAgent;
use URI;
use Mozilla::CA;
use JSON;

use WebService::Raygun::Message;

has api_key => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => sub {
        return $ENV{RAYGUN_API_KEY};
    }
);

has api_endpoint => (
    is      => 'ro',
    isa     => 'URI',
    default => sub {
        return URI->new('https://api.raygun.io/entries');
    },
);

has user_agent => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new(
            ssl_opts => { SSL_ca_file => Mozilla::CA::SSL_ca_file() } );
    },
);

=head2 message

This can be one of the following

=over 2

=item C<HASHREF>

    {
        occurred_on => '2014-06-27T03:15:10+1300',
        error       => $error_obj, # eg. Catalyst::Exception, Moose::Exception
        user        => 'test@test.com',
        environment => {
            processor_count       => 2,
            cpu                   => 34,
            architecture          => 'x84',
            total_physical_memory => 3
            ...
        },
        request => $request_object
    }



=item L<WebService::Raygun::Message|WebService::Raygun::Message> 

The C<HASHREF> with the structure above will be coerced into this type of object. See L<WebService::Raygun::Message|WebService::Raygun::Message> for a more detailed description of this object.

=back

=cut

has message => (
    is     => 'rw',
    isa    => 'RaygunMessage',
    coerce => 1,
);

=head2 fire_raygun

Send data to api.raygun.io/entries via a POST request.

=cut

sub fire_raygun {
    my $self    = shift;
    my $api_key = $self->api_key;
    my $message = $self->message;
    my $uri     = $self->api_endpoint;
    my $ua      = $self->user_agent;
    my $json    = JSON->new->allow_nonref;
    my $jsoned  = $json->pretty->encode( $message->prepare_raygun );
    ### json : $jsoned
    my $req = HTTP::Request->new( POST => $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->header( 'X-ApiKey'     => $api_key );
    $req->content($jsoned);
    ### json message : $jsoned;
    my $response = $ua->request($req);
    return $response;
}

__PACKAGE__->meta->make_immutable();

1;

=head1 SEE ALSO

=over 2

=item L<WebService::Raygun::Message|WebService::Raygun::Message>

Constructs the actual message. See this class for a better description of the fields available or required for the raygun.io API.


=back


=cut

__END__
