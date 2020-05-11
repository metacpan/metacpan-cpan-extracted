package WebService::Hexonet::Connector::SocketConfig;

use 5.026_000;
use strict;
use warnings;
use utf8;

use version 0.9917; our $VERSION = version->declare('v2.5.0');


sub new {
    my $class = shift;
    return bless {
        entity     => q{},
        login      => q{},
        otp        => q{},
        pw         => q{},
        remoteaddr => q{},
        session    => q{},
        user       => q{}
    }, $class;
}


sub getPOSTData {
    my $self = shift;
    my $data = {};
    if ( length $self->{entity} ) {
        $data->{'s_entity'} = $self->{entity};
    }
    if ( length $self->{login} ) {
        $data->{'s_login'} = $self->{login};
    }
    if ( length $self->{otp} ) {
        $data->{'s_otp'} = $self->{otp};
    }
    if ( length $self->{pw} ) {
        $data->{'s_pw'} = $self->{pw};
    }
    if ( length $self->{remoteaddr} ) {
        $data->{'s_remoteaddr'} = $self->{remoteaddr};
    }
    if ( length $self->{session} ) {
        $data->{'s_session'} = $self->{session};
    }
    if ( length $self->{user} ) {
        $data->{'s_user'} = $self->{user};
    }
    return $data;
}


sub getSession {
    my $self = shift;
    return $self->{session};
}


sub getSystemEntity {
    my $self = shift;
    return $self->{entity};
}


sub setLogin {
    my ( $self, $value ) = @_;
    $self->{session} = q{};      # Empty string
    $self->{login}   = $value;
    return $self;
}


sub setOTP {
    my ( $self, $value ) = @_;
    $self->{session} = q{};      # Empty string
    $self->{otp}     = $value;
    return $self;
}


sub setPassword {
    my ( $self, $value ) = @_;
    $self->{session} = q{};      # Empty string
    $self->{pw}      = $value;
    return $self;
}


sub setRemoteAddress {
    my ( $self, $value ) = @_;
    $self->{remoteaddr} = $value;
    return $self;
}


sub setSession {
    my ( $self, $value ) = @_;
    $self->{session} = $value;
    $self->{login}   = q{};      # Empty string
    $self->{pw}      = q{};      # Empty string
    $self->{otp}     = q{};      # Empty string
    return $self;
}


sub setSystemEntity {
    my ( $self, $value ) = @_;
    $self->{entity} = $value;
    return $self;
}


sub setUser {
    my ( $self, $value ) = @_;
    $self->{user} = $value;
    return $self;
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::SocketConfig - Library to wrap API connection settings.

=head1 SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::APIClient module as described below.
To be used in the way:

    # create a new instance
    $sc = WebService::Hexonet::Connector::SocketConfig->new();

See the documented methods for deeper information.

=head1 DESCRIPTION

This library is used to wrap the API connection settings to control which API credentials / ip address etc.
is to be used within the API HTTP Communication.
It is used internally by class L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient>.

=head2 Methods

=over

=item C<new>

Returns a new L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> object.

=item C<getPOSTData>

Returns a hash covering the POST data fields. ready to use for
a HTTP request based on L<LWP::UserAgent|LWP::UserAgent>.

=item C<getSession>

Returns the session id as string.

=item C<getSystemEntity>

Returns the Backend System entity in use as string.
"54cd" represents the LIVE System.
"1234" represents the OT&E System.

=item C<setLogin( $user )>

Sets the account name to be used in API request.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setOTP( $optcode )>

Sets the otp code to be used in API request.
Required in case 2FA is activated for the account.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setPassword( $pw )>

Sets the password to be used in API request.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setRemoteAddress( $ip )>

Sets the outgoing ip address to be used in API request.
To be used in case of an active IP filter setting for the account.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setSession( $sessionid )>

Sets the session id to be used in API request.
NOTE: this is the session id we get from Backend System
when starting a session based communication.
This is not a frontend-related session id!
Setting the session resets the login, password and otp code,
as we only need the session id for further requests as long
as this session id is valid in the Backend System.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setSystemEntity( $entity )>

Sets the Backend System entity.
"54cd" represents the LIVE System.
"1234" represents the OT&E System.
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=item C<setUser( $subuser )>

Sets the specified subuser user account name.
To be used in case you want to have a data view on a specific customer.
NOTE: That view is still read and write!
Returns the current L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> instance in use for method chaining.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
