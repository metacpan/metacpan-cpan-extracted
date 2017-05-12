package Zenoss::Connector;
use strict;
use IO::Socket::INET;

use Moose;
with 'Zenoss::Error';

#**************************************************************************
# Constants
#**************************************************************************
our $URL_REGEX;     *URL_REGEX = 
    \qr {
        \b
        # Protocol
        (https?)://
        
        # URL
        ([-A-Z0-9.]+)
        
        # Port
        (?::|)(\d+)?
}ix;

#**************************************************************************
# Attributes
#**************************************************************************
has 'username' => (
    is	        => 'ro',
    isa	        => 'Str',
    required    => 1,
);

has 'password' => (
    is	        => 'ro',
    isa	        => 'Str',
    required    => 1,
);

has 'url' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    trigger     => \&_check_url,
);

has 'timeout' => (
    is          => 'ro',
    isa         => 'Int',
    default     => '120',
);

has 'endpoint' => (
    is          => 'ro',
    isa         => 'Str',
    writer      => '_set_endpoint',
    init_arg    => undef,
);

#**************************************************************************
# _check_url
#**************************************************************************
sub _check_url {
    my $self = shift;
    my $url = $self->url;
    my $timeout = $self->timeout;
    
    my $matched_protocol;
    my $matched_host;
    my $matched_port;
    my $actual_port;
    
    # Parse the URL to check correctness
    if ($url =~ m/$URL_REGEX/) {
        $matched_protocol = $1;
        $matched_host = $2;
        $matched_port = $3;
        
        # Check if we found a host
        if (!defined($matched_host)) {
            $self->_croak("Unable to determine host from URL [$url]");
        }
        
        # Store the port or default to 80
        if ((defined($matched_protocol) && $matched_protocol eq 'https') && !defined($matched_port)) {
            $actual_port = 443;
        } elsif ((defined($matched_protocol) && $matched_protocol eq 'http') && !defined($matched_port)) {
            $actual_port = 80;
        } elsif (defined($matched_port)) {
            $actual_port = $matched_port;
        } else {
            $self->_croak("Unable to determine the appropriate port from URL [$url]");
        }
    } else {
        $self->_croak("Unable to parse URL [$url]");
    }
    
    # Test connection
    my $success = eval { 
        my $socket = IO::Socket::INET->new(
            PeerAddr    => $matched_host,
            PeerPort    => $actual_port,
            Timeout     => $timeout,
            Proto       => 'tcp',
        )
    };
    
    # If successful set the endpoint
    if (!$success) {
        $self->_croak("Unable to establish connection to host [$matched_host] using port [$actual_port]");
    } else {
        if (defined($matched_port)) {
            $self->_set_endpoint(sprintf("%s://%s:%s\@%s:%s", $matched_protocol, $self->username, $self->password, $matched_host, $matched_port));
        } else {
            $self->_set_endpoint(sprintf("%s://%s:%s\@%s", $matched_protocol, $self->username, $self->password, $matched_host));
        }
    }    
} # END _check_url

#**************************************************************************
# Package end
#**************************************************************************
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__


=head1 NAME

Zenoss::Connector - Module responsible for establishing a connection to the Zenoss API

=head1 SYNOPSIS

    use Zenoss::Connector;
    use Zenoss::Router;
    
    # Create a connection object
    my $connection = Zenoss::Connector->new(
        {
            username    => 'admin',
            password    => 'zenoss',
            url         => 'http://zenossinstance:8080',
        }
    );
    
    # Pass the connection to the router
    my $api = Zenoss::Router->new(
        {
            connector => $connection,
        }
    );
    
    # Call some API methods
    my $response = $api->device_getDevices();
    
    # Print the JSON return
    print $response->json;

=head1 DESCRIPTION

This module creates a connection to the Zenoss API, and tests the connectivity.  Once a 
L<Zenoss::Connector> object has been established, it can be passed to L<Zenoss::Router>
to process Zenoss API calls.

While this module can be used directly, it is recommended that L<Zenoss> facilitates the
connection to the L<Zenoss::Router>.

A croak will occur in the event a connection cannot be established.

=head1 ATTRIBUTES

Attributes can be set on object creation, see SYNOPSIS, or by calling $obj->attribute('value').

Attributes can be retrieved by calling $obj->attribute.

=head2 username

The username to log in with at the Zenos instance

=head2 password

The password to log in with at the Zenos instance

=head2 url

The url to be used in establishing a connection to the Zenoss instance.  Note,
that ports in the http(s) url are not required unless they're non-stanard.  For
example the url can be set to:

http://zenossinstance

https://zenossinstance

Without having to specify :80 or :443.  However, non-standard ports must be specified!
Zenoss by default uses :8080, so this must be specified on the url if your instance
uses this.

IE

http://zenossinstance:8080

=head2 timeout

The timeout value for processing transactions.  Note, if you process a large request, IE
getting all historical events, its prudent to set this value to something higher than the
default of 120 seconds.

=head2 endpoint

This attribute cannot be set.  However, once the object is created this attribute can be
accessed to provide the full url, with credentials, to the Zenoss instance.  For example,

http://admin:zenoss@zenossinstance:8080

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=item *

L<Zenoss::Response>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut