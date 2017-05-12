package W3C::SOAP;

# Created on: 2012-06-29 07:52:54
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use English qw/ -no_match_vars /;
use W3C::SOAP::XSD::Parser qw/load_xsd/;
use W3C::SOAP::WSDL::Parser qw/load_wsdl/;

Moose::Exporter->setup_import_methods(
    as_is => [qw/load_wsdl load_xsd/],
);

our $VERSION = 0.14;

1;

__END__

=head1 NAME

W3C::SOAP - Static and dynamic SOAP client generator from WSDL & XSD files

=head1 VERSION

This documentation refers to W3C::SOAP version 0.14.

=head1 SYNOPSIS

   # Dynamically created clients
   use W3C::SOAP qw/load_wsdl/;

   # load some wsdl file
   my $wsdl = load_wsdl("http://example.com/eg.wsdl");

   # call a method exported by the WSDL
   $wsdl->some_method( HASH | HASH_REF );

   # A real world example
   my $wsdl = load_wsdl('http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl');
   my $res = $wsdl->resolve_ip( ip_address => '59.106.161.11', license_key => 0 );
   printf "lat: %.4f\n", $res->resolve_ipresult->latitude;

   # load some xsd file
   my $xsd = load_xsd("http://example.com/eg.xsd");

   # create a new object of of the XSD
   my $obj = $xsd->new( HASH | HASH_REF );

   # Statically created clients
   # on the command line build Client module (and included XSD modules)
   # see wsdl-parser --help for more details
   $ wsdl-parser -b ResolveIP ResolveIP 'http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl'

   # back in perl

   # the default directory modules are created into
   use lib 'lib';
   # load the ResolveIP client module
   use ResolveIP;
   # Create a client object
   my $client = ResolveIP->new();
   # call the WS
   my $res = $client->resolve_ip( ip_address => '59.106.161.11', license_key => 0 );
   # show the results
   printf "lat: %.4f\n", $res->resolve_ipresult->latitude;

=head1 DESCRIPTION

A perly SOAP client library. To see more details on how to generate a WSDL client
see L<W3C::SOAP::WSDL::Parser>, and for generating Moose objects from XSD files
see L<W3C::SOAP::XSD::Parser>.

=head2 Gotchas

Java style camel case names are converted to the more legible Perl style underscore
separated names for everything that doesn't end up being a Perl package or Moose
type. Eg in the Synopsis the operation defined in the IP 2 GEO WSDL is defined as
ResolveIP this is translated to the perly name resolve_ip.

=head2 Debugging

When something goes wrong there are two ways to see what XML is being sent and
received.

=over 4

=item 1

The C<$W3C_SOAP_DEBUG_CLIENT> environment variable will cause the all request
and response HTTP bodies to be dumped to STDOUT. The length of the content is
limited to 1024 by default but this can be changed with the
C<$W3C_SOAP_DEBUG_LENGTH> environment variable.

=item 2

Supplying a log object. When a client is instantiated you can supply it a log
object or after creation supply the C<log> method with a log object, the only
restriction is that it implements C<debug, info, warn, error and fatal>
methods. L<Log::Log4perl> and C<Catalyst::Log> are known working examples.

  eg
    my $client = ResolveIP->new(log => $log);
  or
    $client->log($log);

=back

Both methods can be used together.

=head1 SUBROUTINES/METHODS

=over 4

=item C<load_wsdl ($wsdl_location)>

Loads a WSDL file, parses is and generates dynamic Moose objects that represent
the WSDL file and any XML Schema xsd content that it refers to.

See L<W3C::SOAP::WSDL::Parser> for more details.

=item C<load_xsd ($xsd_location)>

Loads an XML Schema (.xsd) file, parses is and generates dynamic Moose objects
that representing that schema and any other included/imported XML Schema
content that it refers to.

See L<W3C::SOAP::XSD::Parser> for more details.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item C<$W3C_SOAP_DEBUG_CLIENT>

If this environment variable is a true value it will turn on printing request
and response HTTP messages bodies to STDOUT.

=item C<$W3C_SOAP_DEBUG_LENGTH>

Alter the amount of data shown by C<$W3C_SOAP_DEBUG_CLIENT> which defaults to
1024.

=back

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

Perl 5.18 see below.

=head1 BUGS AND LIMITATIONS

Currently the WSDL handling doesn't deal with more than one input or output
on an operation or inputs/outputs that aren't specified by an XMLSchema. A;so
operation fault objects aren't yet handled.

Currently there is an issue with Perl 5.18 (probably caused by L<Moose> affecting
L<XML::LibXML> usage)

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 ALSO SEE

L<wsdl-parser>, L<W3C::SOAP::Client>, L<XML::LibXML>, L<Moose>, L<MooseX::Types::XMLSchema>

Inspired by L<SOAP::WSDL> & L<SOAP::Lite>

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW 2077 Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
