package WebService::Mattermost;

use Moo;
use Types::Standard qw(Bool Int Object Str);

use WebService::Mattermost::V4::API;

our $VERSION = 0.006;

with 'WebService::Mattermost::Role::Logger';

################################################################################

has [ qw(base_url username password) ] => (is => 'ro', isa => Str, required => 1);

has api_version                => (is => 'ro', isa => Int,  default => 4);
has [ qw(authenticate debug) ] => (is => 'rw', isa => Bool, default => 0);
has [ qw(auth_token user_id) ] => (is => 'rw', isa => Str,  default => '');

has api => (is => 'ro', isa => Object, lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    unless ($self->auth_token) {
        $self->_try_authentication();
    }

    return 1;
}

################################################################################

sub _try_authentication {
    my $self = shift;

    if ($self->authenticate && $self->username && $self->password) {
        # Log into Mattermost at runtime. The entire API requires an auth token
        # which is sent back from the login method.
        my $ret = $self->api->users->login($self->username, $self->password);

        if ($ret->is_success) {
            $self->auth_token($ret->headers->header('Token'));
            $self->user_id($ret->content->{id});
            $self->_set_resource_auth_token();
        } else {
            $self->logger->fatal($ret->message);
        }
    } elsif ($self->authenticate && !($self->username && $self->password)) {
        $self->logger->logdie('"username" and "password" are required attributes for authentication');
    } elsif ($self->auth_token) {
        $self->_set_resource_auth_token();
    }

    return 1;
}

sub _set_resource_auth_token {
    my $self  = shift;

    # Set the auth token against every available resource class after a
    # successful login to the Mattermost server
    foreach my $resource (@{$self->api->resources}) {
        $resource->auth_token($self->auth_token);
    }

    return 1;
}

################################################################################

sub _build_api {
    my $self = shift;

    my $args = {
        base_url   => $self->base_url,
        auth_token => $self->auth_token,
        debug      => $self->debug,
    };

    my $ver = 'WebService::Mattermost::V4::API';

    # Later, if $self->api_version == 5 ...

    return $ver->new($args);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost - a SDK for interacting with Mattermost.

=head1 DESCRIPTION

WebService::Mattermost provides websocket and REST API integrations for Mattermost,
and supercedes C<Net::Mattermost::Bot>, replacing all functionality.

=head2 SYNOPSIS

See C<WebService::Mattermost::V4::API> for all available API integrations.

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        # Required
        base_url => 'https://my.mattermost.server.com/api/v4/',

        # Optional
        authenticate => 1,            # Trigger a "login" to the Mattermost server
        debug        => 1,            # Debug via Mojo::Log
        username     => 'MyUsername', # Login credentials for the server
        password     => 'MyPassword',
    });

    # Example REST API calls
    my $emojis = $mm->api->emoji->custom;
    my $user   = $mm->api->users->search_by_email('someone@somewhere.com');

Where appropriate, a response object or list of objects may be returned. You can
access these via (using the custom emoji search above as an example):

    # First item only
    my $item = $emojis->item;

    # All items
    my $items = $emoji->items;

=head2 METHODS

This class has no public methods.

=head2 ATTRIBUTES

=over 4

=item C<base_url>

The base URL of your Mattermost server. Should contain the C</api/v4/> section.

=item C<username>

An optional username for logging into Mattermost.

=item C<password>

An optional password for logging into Mattermost.

=item C<authenticate>

If this value is true, an authentication attempt will be made against your
Mattermost server.

=item C<auth_token>

Set after a successful login and used for authentication for the successive API
calls.

=item C<api>

A containing class for the available resources for API version 4.

=back

=head1 SEE ALSO

=over 4

=item L<Bug tracker and source|https://git.netsplit.uk/mike/WebService-Mattermost>

=item L<https://api.mattermost.com/>

Plain Mattermost API documentation.

=item C<WebService::Mattermost::V4::API>

Containing object for resources for version 4 of the Mattermost REST API.
Accessible from this class via the C<api> attribute.

=item C<Net::Mattermost::Bot>

Deprecated original library.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

