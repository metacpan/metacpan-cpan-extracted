package Zenoss::Response;
use strict;
use JSON qw{};

use Moose;
with 'Zenoss::Error';

#**************************************************************************
# Public Attributes
#**************************************************************************
# HTTP::Response from Zenoss::Router
has handler => (
    isa         => 'HTTP::Response',
    is          => 'ro',
    handles     => {
        # Proxy methods to HTTP::Response
        json                    => 'decoded_content',
        raw_response            => 'as_string',
        http_code               => 'code',
        http_code_description   => 'message',
        http_status             => 'status_line',
        is_success              => 'is_success',
        is_error                => 'is_error',
        error_as_HTML           => 'error_as_HTML',        
        header                  => 'header',
        request_time            => 'current_age',
    },
    required    => 1,
);

# Perl reference format of the JSON return data
has decoded => (
    is          => 'ro',
    isa         => 'Ref',
    builder     => '_build_decoded',
    lazy        => 1,
    init_arg    => undef,
);

# Transaction ID that was received from the Zenoss server
has received_tid => (
    is          => 'ro',
    isa         => 'Num',
    builder     => '_build_received_tid',
    writer      => '_set_received_tid',
    lazy        => 1,
    init_arg    => undef,
);

# Transaction ID that was sent to the Zenoss server
# This is passed from Zenoss::Router
has sent_tid => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
);

#**************************************************************************
# Private Attributes
#**************************************************************************
# Method that send the API call off
has '_caller' => (
    is	        => 'ro',
    isa	        => 'Str',
    required    => 1,
);

#**************************************************************************
# Private Methods
#**************************************************************************
#======================================================================
# _build_decoded
#======================================================================
sub _build_decoded {
    my $self = shift;

    my $json_decoder = JSON->new->allow_nonref;
    my $json_decoded = $json_decoder->decode($self->json);

    # Set the received_tid if we have it
    if (exists($json_decoded->{'tid'})) {
        $self->_set_received_tid($json_decoded->{'tid'});
    }

    # Return result set
    if (exists($json_decoded->{'result'})) {
        # result structure should be there, so return this
        return $json_decoded->{'result'};
    } else {
        # if not return what we have
        return $json_decoded;
    }
} # END _build_decoded

#======================================================================
# _build_received_tid
#======================================================================
sub _build_received_tid {
    my $self = shift;

    # just call _build_decoded - it does the same thing
    # its easier to just convert the JSON to a hash and pull it out
    # of the data structure
    $self->_build_decoded;
} # END _build_received_tid

#======================================================================
# _validate_api_method_exists
#
# This method will determine if the API allowed the method to be
# executed on the Zenoss server
#======================================================================
sub _validate_api_method_exists {
    my $self = shift;

    # Check to see if we have a 500 HTTP ERROR
    if ($self->http_code() == 500) {
        # Check to see if Zenoss reported the API call unavailable
        if ($self->raw_response() =~ m/is not the name of a method on/) {
            my $caller = $self->_caller();
            $self->_croak("[$caller] is not an available API call with your version of Zenoss. Upgrade your Zenoss to a later version!");
        }
    }

    # All good, return the response object
    return $self;
} # END _validate_api_method_exists

#**************************************************************************
# Package end
#**************************************************************************
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

Zenoss::Response - Handles responses from Zenoss::Router

=head1 SYNOPSIS

    use Zenoss;
    use Data::Dumper;
    
    # Create a Zenoss object
    my $api = Zenoss->connect(
        {
            username    => 'admin',
            password    => 'zenoss',
            url         => 'http://zenossinstance:8080',
        }
    );
    
    # Issue a request to get all devices from Zenoss
    my $response = $api->device_getDevices();
    
    # $response is now an instance of Zenoss::Response
    # now we can do things like
    print $response->json();
    print $response->http_code();
    
    # get the response in reference form
    my $reference = $response->decoded();
    print Dumper $reference;

=head1 DESCRIPTION

This module is NOT instantiated directly.  When the Zenoss API issues a response
to a request initiated by Zenoss::Router, a Zenoss::Response instance is created.
To call methods from this module create an instance of L<Zenoss> and issue a request
to the Zenoss API.

Please review the SYNOPSIS for examples.

=head1 ATTRIBUTES

Attributes can be retrieved by calling $obj->attribute.

=head2 sent_tid

This attribute is set upon the creation of Zenoss::Response by Zenoss::Router.  Each
request issued to the Zenoss API is coded with a transaction ID (tid).  This can be compared
with the received_tid to ensure that the proper response was received for what was requested.

=head2 received_tid

This attribute is set by extracting the transaction ID (tid) from the response Zenoss sends.  This
can be compared with the sent_tid to ensure that the proper response was received for what was requested.

=head1 METHODS

=head2 $obj->json()

Returns the response, from the Zenoss API request, in JSON format.

=head2 $obj->decoded()

Returns the result response, from the Zenoss API request, in a PERL reference.

=head2 $obj->raw_response()

Returns a textual representation of the response.

=head2 $obj->http_code()

Returns a 3 digit number that encodes the overall outcome of a HTTP response.

For example 200, for OK.

=head2 $obj->http_code_description()

Returns a short human readable single line string that explains the response code.

For example, OK.

=head2 $obj->http_status()

Returns the string "<http_code> <http_code_description>". If the http_code_description
attribute is not set then the official name of <code> (see HTTP::Status) is substituted.

=head2 $obj->is_success()

Returns true if the http response was successful.  Note this does not mean the API request
was successful or not.

See HTTP::Status for the meaning of these.

=head2 $obj->is_error()

Returns true if the http response had an error.  Note this does not mean the API request
was successful or not.

See HTTP::Status for the meaning of these.

=head2 $obj->error_as_HTML()

Returns a string containing a complete HTML document indicating what error occurred.
This method should only be called when $obj->is_error is TRUE.

=head2 $obj->header()

This is used to get header values and it is inherited from HTTP::Headers via HTTP::Message.

=head2 $obj->request_time()

Calculates the "current age" of the response as specified by RFC 2616 section 13.2.3.
The age of a response is the time since it was sent by the origin server. The returned value
is a number representing the age in seconds.

=head2 $obj->received_tid()

Returns the transaction id (tid) that was returned by Zenoss.

=head2 $obj->sent_tid()

Returns the transaction id (tid) that was sent to Zenoss

=head1 SEE ALSO

=over

=item *

L<Zenoss>

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