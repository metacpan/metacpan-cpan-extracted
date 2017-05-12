package W3C::SOAP::Client;

# Created on: 2012-05-28 07:40:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use LWP::UserAgent;
use Try::Tiny;
use XML::LibXML;
use W3C::SOAP::Exception;
use W3C::SOAP::Header;
use Moose::Util::TypeConstraints qw/duck_type/;

extends 'W3C::SOAP::Base';

our $VERSION = 0.14;
our $DEBUG_REQUEST_RESPONSE = $ENV{W3C_SOAP_DEBUG_CLIENT};

has location => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has mech => (
    is        => 'rw',
    predicate => 'has_mech',
    init_arg  => 0,
);
has ua => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    builder  => '_ua',
    required => 1,
    lazy     => 1,
);
has response => (
    is      => 'rw',
    isa     => 'HTTP::Response',
    clearer => 'clear_response',
);
has log => (
    is        => 'rw',
    isa       => duck_type([qw/ debug info warn error fatal /]),
    predicate => 'has_log',
    clearer   => 'clear_log',
);
has content_type => (
    is      => 'rw',
    isa     => 'Str',
    default => 'text/xml;charset=UTF-8',
);

sub post {
    my ($self, $action, $xml) = @_;
    my $url = $self->location;

    cluck "The mech attribute has been deprecated and is replaced by ua attribute!"
        if $self->has_mech;

    $self->clear_response;
    my $response = $self->ua->post(
        $url,
        'Content-Type'     => $self->content_type,
        'SOAPAction'       => qq{"$action"},
        'Proxy-Connection' => 'Keep-Alive',
        'Accept-Encoding'  => 'gzip, deflate',
        Content            => $xml->toString,
    );
    $self->response($response);

    return $response->decoded_content;
}

{
    my $ua;
    sub _ua {
        return $ua if $ua;
        $ua = LWP::UserAgent->new;

        if ($DEBUG_REQUEST_RESPONSE) {
            $ua->add_handler("request_send",  sub { shift->dump( prefix => 'REQUEST  ', maxlength => $ENV{W3C_SOAP_DEBUG_LENGTH} || 1024 ); return });
            $ua->add_handler("response_done", sub { shift->dump( prefix => 'RESPONSE ', maxlength => $ENV{W3C_SOAP_DEBUG_LENGTH} || 1024 ); return });
        }

        return $ua;
    }
}

1;

__END__

=head1 NAME

W3C::SOAP::Client - Client to talk SOAP to a server.

=head1 VERSION

This documentation refers to W3C::SOAP::Client version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Client;

   # post a SOAP action
   my $client = W3C::SOAP::Client->new(
       location => 'http://some.where.com/',
   );

   $client->post('DO_SOMETHING', $xms_doc);

=head1 DESCRIPTION

L<W3C::SOAP::Client> is the base class for L<W3C::SOAP> clients. It provides
the base attributes that are needed for sending SOAP requests.

=head1 ATTRIBUTES

=over 4

=item location

The URL for the SOAP request

=item mech

No longer used

=item ua

A L<LWP::UserAgent> compatible object which if not supplied will be lazily
created.

=item response

The L<HTTP::Response> object of the last returned response

=item log

An logging object that proves the following methods:

 debug, info, warn, error and fatal

=item content_type

The value of the Content-Type HTTP header (defaults to text/xml;charset=UTF-8')

=back

=head1 SUBROUTINES/METHODS

=over 4

=item C<post ($action, $xml)>

Performs the SOAP POST request.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

The environment variable C<W3C_SOAP_DEBUG_CLIENT> can be used to show
request and response XML.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
