
package XML::SRS;
BEGIN {
  $XML::SRS::VERSION = '0.09';
}

BEGIN { our $PROTOCOL_VERSION = "5.0" }
use XML::SRS::Version;

use Moose::Role;
use XML::SRS::Types;
use XML::SRS::Node;

use PRANG::Graph;
BEGIN { with 'PRANG::Graph', 'XML::SRS::Node'; }

# packet types
use XML::SRS::Request;
use XML::SRS::Response;

# data types
use XML::SRS::Time;
use XML::SRS::Date;
use XML::SRS::TimeStamp;
use XML::SRS::Contact;
use XML::SRS::Contact::Filter;
use XML::SRS::Contact::Address::Filter;
use XML::SRS::Audit;

# ---
# plug-ins:

# Query types:
use XML::SRS::Whois;
use XML::SRS::ACL::Query;
use XML::SRS::Registrar::Query;
use XML::SRS::Registrar::Update;
use XML::SRS::Domain::Create;
use XML::SRS::Domain::Update;
use XML::SRS::Domain::Query;
use XML::SRS::Domain::Transferred;
use XML::SRS::UDAIValid::Query;
use XML::SRS::Handle::Create;
use XML::SRS::Handle::Update;
use XML::SRS::Handle::Query;
use XML::SRS::Message;
use XML::SRS::Message::Ack::Response;
use XML::SRS::GetMessages;
use XML::SRS::AckMessage;

# ActionResponse types:
use XML::SRS::Error;
use XML::SRS::ACL;
use XML::SRS::Domain;
use XML::SRS::Handle;
use XML::SRS::Registrar;
use XML::SRS::UDAIValid;

1;

__END__

=head1 NAME

XML::SRS - Shared Registry System XML Protocol

=head1 SYNOPSIS

 # Construct a request
 my $create = XML::SRS::Domain::Create->new(
          action_id => "kaihoro.co.nz-create-".time(),
          domain_name => "kaihoro.co.nz",
          term => 12,
          delegate => 1,
          contact_registrant => {
               name => "Lord Crumb",
               email => 'kaihoro.takeaways@gmail.com',
               address => {
                    address1 => "57 Mount Pleasant St",
                    address2 => "Burbia",
                    city => "Kaihoro",
                    region => "Nelson",
                    cc => "NZ",
               },
               phone => {
                    cc => "64",
                    ndc => "4",
                    subscriber => "499 2267",
               },
          },
          nameservers => [qw( ns1.registrar.net.nz ns2.registrar.net.nz )],
         );

  my $request = XML::SRS::Request->new(
      registrar_id => 555,
      requests => [$create],
  );

  my $xml_request = $request->to_xml;
  
  # $xml_request is now an XML string containing a request that can be sent to 
  # the SRS
  
  # $xml_response is an XML string recieved from the SRS
  my $response = XML::SRS::Response->parse($xml_response);
  
  # Calling 'results' gives us an array reference with the results for 
  #  each of the requests we sent. 
  my $results = $response->results;
  
  # Assuming the first result was a domain create, check to see if it was
  #  successful
  my $result = $results->[0]; # $result is a XML::SRS::Result
  
  my $domain = $result->response;
  
  # Print the domain's status
  print $domain->status;

=head1 DESCRIPTION

This module is an implementation of the XML protocol used by the .nz
registry. It allows XML requests (and responses) to be constructed via
an OO interface. Additionally, it allows SRS XML documents to be parsed,
returning a set of objects.

Note, this documentation does not attempt to describe the SRS protocol
itself. Please see the NZRS website (L<http://nzrs.net.nz>) for more
information on the protocol.

Validation is performed on both XML emitting and parsing. This should be
less stringent than the SRS itself, so although XML::SRS may generate
requests that the SRS will reject as invalid, you can be sure it won't
reject input the SRS would accept.

The parsing and emitting of XML is handled by L<PRANG>.

Some more information on how to create and parse XML documents follows.
We assume that you're using XML::SRS from a client's point-of-view, i.e.
you're interested in creating requests and parsing responses. Therefore,
we don't discuss parsing requests and creating responses, even though
XML:SRS has these capabilities.

=head2 Constructing requests

A request consists of multiple 'actions' or 'transactions', such as
Whois, DomainCreate, etc. Each action has its own class in the XML::SRS
namespace. These should be instantiated (see each individual class for
information on the parameters for the constructor), and passed to the
'requests' parameter of a XML::SRS::Request object. The example in
the synopsis illustrates the construction of a DomainCreate request.

You can then call the to_xml() method on the constructed object
to retrieve the xml. Note, to_xml() can be called on any level of
object if you require an XML fragment.

=head2 Parsing responses

A response can be parsed by simply calling the 'parse' method (or a
related method - see below) on the XML::SRS package. Again, the
synopsis of this module demostrates this.

The resulting object will be an L<XML::SRS::Response> instance. See the
documentation for that module for methods to retrieve the data in the
response.

=head1 METHODS

This module uses the L<PRANG::Graph> role, and so the parse methods
(i.e. parse(), parse_file() and parse_fh()) are available. See that
module's documentation for more information.

Note, as XML::SRS itself cannot be instantiated, you cannot call the
to_xml() method from PRANG::Graph on it. However, each of the XML::SRS
classes have this method available if you're interested in constucting
XML documents. In particular, XML::SRS::Request can be used to 
construct an entire SRS request.

=head1 COMPOSED OF

L<PRANG::Graph>, L<XML::SRS::Node>

=head1 BACKGROUND

The SRS protocol was developed in 2002, using what were considered stable XML
standard methods at the time, such as SGML DTD. This compares to the now 
de-facto standard, EPP (RFC3730, friends and updates), which was developed 
using XML Schema and XML Namespaces.  As such, the SRS protocol as a stable
standard far pre-dates EPP, which took a further 2 years to reach 1.0 status.

=head1 GLOBALS

There is currently a C<$XML::SRS::PROTOCOL_VERSION> variable which
includes the version of the SRS protocol parsed by the module.
Currently, the ability to parse more than one version at a time is not
supported, so in the event of registry protocol version changes, you
will need to upgrade the version of L<XML::SRS> in lock-step for any
new functionality.  This global is not exported.

=head1 SOURCE, SUBMISSIONS, SUPPORT

Source code is available from Catalyst:

  git://git.catalyst.net.nz/XML-SRS.git

And Github:

  git://github.com/catalyst/XML-SRS.git

Please see the file F<SubmittingPatches> for information on preferred
submission formats.

Suggested avenues for support:

=over

=item *

The DNRS forum on SourceForge -
L<http://sourceforge.net/projects/dnrs/forums>

=item *

Contact the author and ask either politely or commercially for help.

=item *

Log a ticket on L<http://rt.cpan.org/>

=back

=head1 SEE ALSO

L<PRANG>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009-2011, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
