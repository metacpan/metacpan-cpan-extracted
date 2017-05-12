package W3C::SOAP::Base;

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

our $VERSION = 0.14;
our $DEBUG_REQUEST_RESPONSE = $ENV{W3C_SOAP_DEBUG_CLIENT};

has w3c_built_with_version => (
    is       => 'rw',
    isa      => 'version',
);

1;

__END__

=head1 NAME

W3C::SOAP::Base - Base module for build L<W3C::SOAP> modules

=head1 VERSION

This documentation refers to W3C::SOAP::Base version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Base;

   # post a SOAP action
   my $client = W3C::SOAP::Base->new(
       location => 'http://some.where.com/',
   );

   $client->post('DO_SOMETHING', $xms_doc);

=head1 DESCRIPTION

L<W3C::SOAP::Base> is the base class for L<W3C::SOAP> clients. It provides
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
