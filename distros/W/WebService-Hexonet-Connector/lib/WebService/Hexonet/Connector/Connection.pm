package WebService::Hexonet::Connector::Connection;

use strict;
use warnings;
use WebService::Hexonet::Connector::Response;
use WebService::Hexonet::Connector::Util;
use LWP::UserAgent;

our $VERSION = '1.05';

sub new {
    my $class = shift;
    my $self  = shift;
    foreach my $key (%$self) {
        my $value = $self->{$key};
        delete $self->{$key};
        $self->{ lc $key } = $value;
    }
    return bless $self, $class;
}

sub call {
    my $self    = shift;
    my $command = shift;
    my $config  = shift;
    return WebService::Hexonet::Connector::Response->new(
        $self->call_raw( $command, $config ) );
}

sub call_raw {
    my $self    = shift;
    my $command = shift;
    my $config  = shift;

    $config = {} if !defined $config;
    $config = { User => $config } if ( defined $config ) && ( !ref $config );

    #TODO check above line if we still need it; $config should always be defined
    #because of the line before, so that at least the if branch can be reviewed

    return $self->call_raw_http( $command, $config );
}

sub call_raw_http {
    my $self    = shift;
    my $command = shift;
    my $config  = shift;

    my $ua = $self->_get_useragent();

    my $url  = $self->{url};
    my $post = {
        s_command => (
            scalar WebService::Hexonet::Connector::Util::command_encode(
                $command)
        )
    };
    $post->{s_entity} = $self->{entity}   if exists $self->{entity};
    $post->{s_login}  = $self->{login}    if exists $self->{login};
    $post->{s_pw}     = $self->{password} if exists $self->{password};
    $post->{s_user}   = $self->{user}     if exists $self->{user};
    $post->{s_login} = $self->{login} . "!" . $self->{role}
      if ( exists $self->{login} ) && ( exists $self->{role} );

    if ( exists $config->{user} ) {
        if ( exists $post->{s_user} ) {
            $post->{s_user} .= " " . $config->{user};
        }
        else {
            $post->{s_user} = $config->{user};
        }
    }

    my $response = $self->{_useragent}->post( $url, $post );
    return $response->content();

}

sub _get_useragent {
    my $self = shift;
    return $self->{_useragent} if exists $self->{_useragent};
    $self->{_useragent} = new LWP::UserAgent(
        agent      => "Hexonet-perl/$WebService::Hexonet::Connector::VERSION",
        keep_alive => 4
    );
    return $self->{_useragent};
}

1;

__END__

=head1 NAME

WebService::Hexonet::Connector::Connection - package to provide API client functionality.

=head1 DESCRIPTION

This package provides any API client functionality that you need to communicate with the
insanely fast L<HEXONET Backend API|https://www.hexonet.net/>. A short hand method to
instantiate the API client is provided as WebService::Hexonet::Connector::connect and its usage is
described in that appropriate file.

The API client library itself cares about requesting provided commands to the Backend API
by using the given configuration data (credentials, backend system url and entity) and to
return the Backend API response accordingly.

=head1 METHODS WebService::Hexonet::Connector::Connection

=over 4

=item C<new(config)>

Create an new API client instance with the given configuration data.
Supported configuration data keys are:
- login - your uid
- password - your password
- url - Backend API url to use; in general https://coreapi.1api.de/api/call.cgi
- entity - Backend system entity; use "54cd" for LIVE system and "1234" for OT&E system
- user - to have a view into subuser account data
- role - in case you want to login with a role user account that is directly under the given uid

=item C<call(command, config)>

Make a curl API call and returns the response as a response object

=item C<call_raw(command,config)>

Make a curl API call and returns the response as a string

=item C<call_raw_http(command, config)>

Make a curl API call over HTTP(S) and returns the response as a string

=back

=head1 AUTHOR

Hexonet GmbH

L<https://www.hexonet.net>

=head1 LICENSE

MIT

=cut
