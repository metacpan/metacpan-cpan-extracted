package ebXML::Message;

=head1 NAME

ebXML::Message - encapsulate an ebMS message

=head1 SYNOPSIS

  use ebXML::Message;

  # create new message

  my $message = ebXML::Message->new
      (
        'CPAId'        => 'http://www.you.org/cpa/123456',
        'Action'       => 'NewPurchaseOrder',
        'MessageId'    => 12,
        'RefMessageToId' => 11,
        'Service'      => ebXML::Message::Service->new
                              (
                                VALUE => 'QuoteToCollect',
                                Type => 'myservicetypes',
                              ),
      );

   # write SOAP XML using DOM

   use XML::Xerses;

   # DOM Document
   my $target = XML::Xerces::StdOutFormatTarget->new();
   $writer->writeNode($target,$message->getOutput('DOM-Doc');

   # DOM generated / munged XML
   print OUT $message->getOutput('DOM-XML');


   # use message with SOAP::Lite to call webservice

   use SOAP::Lite;

   # SOAP::Data::Builder object
   my $result = SOAP::Lite->uri('http://uri.to/WebService')
                          ->proxy('http://uri.to/soap.cgi')
                          ->parts($message->getMIMEParts)
                          ->call($message->getOutput('SOAP-Data'))
                          ->result;

   # SOAP::Data::Builder generated / munged XML
   print OUT $message->getOutput('SOAP-XML');



=head1 DESCRIPTION

An ebXML message encapsulates all the details of an ebMS message.

ebXML is a mechanism for ensuring reliable delivery of XML-based
messages via a transport mechanism such as SOAP.  For more details on
ebXML, see http://www.ebxml.org/

Large portions of this manual page are copied directly from the ebMS
2.0 specification.

=cut

use base qw(Class::Tangram);

our $VERSION = 0.03;

=head1 PROPERTIES

An ebMS message contains the following properties (case sensitive):

=over

=item B<From> and B<To>

The REQUIRED B<From> property identifies the Party that originated the
message. The REQUIRED B<To> property identifies the Party that is the
intended recipient of the message. Both B<To> and B<From> can contain
logical identifiers, such as a DUNS number, or identifiers that also
imply a physical location such as an eMail address.

The B<From> and the B<To> properties are references to
B<ebXML::Message::Party> objects.  These objects have:

=over

=item a list of B<PartyId>s

which occurs one or more times.

The B<PartyId> property has a B<type> and content that is a string
value. The B<type> indicates the domain of names to which the string
in the content of the B<PartyId> element belongs. The value of the
B<type> MUST be mutually agreed and understood by each of the
Parties. It is RECOMMENDED that the value of the B<type> be a URI. It
is further recommended that these values be taken from the EDIRA (ISO
6523), EDIFACT ISO 9735 or ANSI ASC X12 I05 registries.

If the B<PartyId> B<type> is B<undef>, the content of the B<PartyId>
element MUST be a URI [RFC2396], otherwise the I<Receiving MSH> SHOULD
report an error (see section 11) with B<errorCode> set to
B<Inconsistent> and B<severity> set to B<Error>. It is strongly
RECOMMENDED that the content of each B<PartyID> be a URI.

C<ebXML::Message::Party->get_PartyIds()> returns a list of B<type>
=E<gt> B<value> pairs.  C<ebXML::Message::Party->set_PartyIds()>
accepts the same input.

=item a list of B<Role>s

which occurs zero or one times

The B<Role> property identifies the authorized role
(fromAuthorizedRole or toAuthorizedRole) of the Party I<sending> (when
present as a child of the B<From> element) and/or I<receiving> (when
present as a child of the B<To> element) the message. The value of
each element of the B<Role> is a non-empty string, which is specified
in the CPA.

=back

If either the B<From> or B<To> properties contain multiple B<PartyId>
elements, all members of the list MUST identify the same organisation.
Unless a single B<type> value refers to multiple identification
systems, a B<type> attribute value must not appear more than once in a
single list of B<PartyId> elements.

Note: This mechanism is particularly useful when transport of a
message between the parties may involve multiple intermediaries (see
Sections 8.5.4, Multi-hop TraceHeader Sample and 10.3, ebXML Reliable
Messaging Protocol).  More generally, the From Party should provide
identification in all domains it knows in support of intermediaries
and destinations that may give preference to particular identification
systems.

The B<From> and B<To> elements contain zero or one B<Role> child
element that, if present, SHALL immediately follow the last B<PartyId>
child element.

The following fragment demonstrates usage of the B<From> and B<To>
elements.

    <eb:From>
      <eb:PartyId eb:type="urn:duns">123456789</eb:PartyId>
      <eb:PartyId eb:type="SCAC">RDWY</PartyId>
    </eb:From>
    <eb:To>
      <eb:PartyId>mailto:president.brown@california.uber.alles</eb:PartyId>
    </eb:To>

This is set in a B<ebXML::Message> object via the following Perl
fragment:

   $message->set_From
       ( [ PartyIds => [ 'urn:duns' => "123456789",
                         'SCAC' => "RDWY",          ],
           Roles    => [ "X-Originator" ],
         ] );

   $message->set_To
       ( [ PartyIds => [ undef => 'mailto:president.brown@california.uber.alles' ],
           Roles    => [ "X-Recipient" ],
         ] );


=item B<CPAId>

The REQUIRED B<CPAId> property is a string that identifies the
parameters governing the exchange of messages between the parties.
The recipient of a message MUST be able to resolve the B<CPAId> to an
individual set of parameters, taking into account the sender of the
message.

The value of a B<CPAId> property MUST be unique within a namespace
that is mutually agreed by the two parties.  This could be a
concatenation of the B<From> and B<To> PartyId values, a URI that is
prefixed with the Internet domain name of one of the parties, or a
namespace offered and managed by some other naming or registry
service.  It is RECOMMENDED that the B<CPAId> be a URI.

The B<CPAId> MAY reference an instance of a CPA as defined in the
ebXML Collaboration Protocol Profile and Agreement Specification
[ebCPP].  An example of the CPAId element follows:

    <eb:CPAId>http://example.com/cpas/ourcpawithyou.xml</eb:CPAId>

This is set with the Perl fragment:

    $message->set_CPAId("http://example.com/cpas/ourcpawithyou.xml");

If the parties are operating under a CPA, then the reliable messaging
parameters are determined by the appropriate elements from that CPA,
as identified by the B<CPAId> property.  If a receiver determines that
a message is in conflict with the CPA, the appropriate handling of
this conflict is undefined by this specification. Therefore, senders
SHOULD NOT generate such messages unless they have prior knowledge of
the receiver's capability to deal with this conflict.

If a receiver chooses to generate an error as a result of a detected
inconsistency, then it MUST report it with an B<errorCode> of
B<Inconsistent> and a severity of B<Error>. If it chooses to generate
an error because the B<CPAId> is not recognized, then it MUST report
it with an B<errorCode> of B<NotRecognized> and a severity of
B<Error>.
=item B<ConversationId>

The REQUIRED B<ConversationId> property is a string identifying the
set of related messages that make up a conversation between two
Parties. It MUST be unique within the context of the specified
B<CPAId>.  The I<Party> initiating a conversation determines the value
of the B<ConversationId> property that SHALL be reflected in all
messages pertaining to that conversation.

The B<ConversationId> enables the recipient of a message to identify
the instance of an application or process that generated or handled
earlier messages within a conversation. It remains constant for all
messages within a conversation.

The value used for a B<ConversationId> is implementation dependent.
An example of the B<ConversationId> element follows:

  <eb:ConversationId>20001209-133003-28572</eb:ConversationId>

As set by:

  $message->set_ConversationId("20001209-133003-28572");

Note: Implementations are free to choose how they will identify and
store conversational state related to a specific conversation.
Implementations SHOULD provide a facility for mapping between their
identification scheme and a B<ConversationId> generated by another
implementation.

=item B<Service>

The REQUIRED B<Service> property identifies the service that acts on
the message and it is specified by the designer of the service. The
designer of the service may be:

=over

=item *

a standards organization, or

=item *

an individual or enterprise

=back

Note: In the context of an ebXML business process model, an action
equates to the lowest possible role based activity in the Business
Process [ebBPSS] (requesting or responding role) and a service is a
set of related actions for an authorized role within a party.

An example of the B<Service> element follows:

  <eb:Service>urn:services:SupplierOrderProcessing</eb:Service>

Set with:

  $message->set_service("urn:services:SupplierOrderProcessing");


Note: URIs in the B<Service> element that start with the namespace
C<urn:oasis:names:tc:ebxml-msg:service> are reserved for use by this
specification.

The B<Service> element has a single B<type> attribute.

If the B<type> attribute is present, it indicates the parties sending
and receiving the message know, by some other means, how to interpret
the content of the B<Service> element.  The two parties MAY use the
value of the type attribute to assist in the interpretation.

If the B<type> attribute is not present, the content of the B<Service>
element MUST be a URI [RFC2396].  If it is not a URI then report an
error with B<errorCode> of B<Inconsistent> and B<severity> of
B<Error>.

=item B<Action>

The REQUIRED B<Action> element identifies a process within a
B<Service> that processes the Message.  B<Action> SHALL be unique
within the B<Service> in which it is defined.  The value of the
B<Action> element is specified by the designer of the service.  An
example of the B<Action> element follows:

  <eb:Action>NewOrder</eb:Action>

If the value of either the B<Service> or B<Action> element are
unrecognized by the I<Receiving MSH>, then it MUST report the error
with an B<errorCode> of B<NotRecognized> and a B<severity> of
B<Error>.

=item B<MessageData>

The REQUIRED MessageData element provides a means of uniquely identifying an ebXML Message. It
contains the following:
· MessageId element
· Timestamp element
· RefToMessageId element
· TimeToLive element
The following fragment demonstrates the structure of the MessageData element:

  <eb:MessageData>
      <eb:MessageId>20001209-133003-28572@example.com</eb:MessageId>
      <eb:Timestamp>2001-02-15T11:12:12</eb:Timestamp>
      <eb:RefToMessageId>20001209-133003-28571@example.com</eb:RefToMessageId>
  </eb:MessageData>

=item B<MessageId>

The REQUIRED element MessageId is a globally unique identifier for each message conforming to
MessageId [RFC2822].
Note: In the Message-Id and Content-Id MIME headers, values are always surrounded by angle brackets.  However
references in mid: or cid: scheme URI's and the MessageId and RefToMessageId elements MUST NOT include
these delimiters.

=item B<Timestamp>

The REQUIRED Timestamp is a value representing the time that the
message header was created conforming to a dateTime [XMLSchema] and
MUST be expressed as UTC.  Indicating UTC in the Timestamp element by
including the `Z' identifier is optional.

=item B<RefToMessageId>

The RefToMessageId element has a cardinality of zero or one. When
present, it MUST contain the MessageId value of an earlier ebXML
Message to which this message relates. If there is no earlier related
message, the element MUST NOT be present.

For Error messages, the RefToMessageId element is REQUIRED and its
value MUST be the MessageId value of the message in error (as defined
in section 4.2).

=item B<TimeToLive>

If the TimeToLive element is present, it MUST be used to indicate the
time, expressed as UTC, by which a message should be delivered to the
To Party MSH.  It MUST conform to an XML Schema dateTime.  In this
context, the TimeToLive has expired if the time of the internal clock,
adjusted for UTC, of the Receiving MSH is greater than the value of
TimeToLive for the message.

If the To Party's MSH receives a message where TimeToLive has expired,
it SHALL send a message to the From Party MSH, reporting that the
TimeToLive of the message has expired.  This message SHALL be
comprised of an ErrorList containing an error with the errorCode
attribute set to TimeToLiveExpired and the severity attribute set to
Error.

=item B<DuplicateElimination>

The DuplicateElimination element, if present, identifies a request by
the sender for the receiving MSH to check for duplicate messages (see
section 6.4.1 for more details).  Valid values for
DuplicateElimination:

* The Ace of spades

Gambling is for fools, but thats the way I like it baby, I don't want
to live for ever.. and don't forget the joker!

=over

=item DuplicateElimination present

duplicate messages SHOULD be eliminated.

=item DuplicateElimination not present

this results in a delivery behavior of Best-Effort.  The
DuplicateElimination element MUST NOT be present if the CPA has
duplicateElimination set to never (see section 6.4.1 and section 6.6
for more details).

=back

=item B<Description>

The Description element may be present zero or more times.  Its
purpose is to provide a human readable description of the purpose or
intent of the message.  The language of the description is defined by
a required xml:lang attribute.  The xml:lang attribute MUST comply
with the rules for identifying anguages specified in XML [XML].  Each
occurrence SHOULD have a different value for xml:lang.

An example of a Description element follows.

    <eb:Description xml:lang="en-GB">Purchase Order for
 One night in bangkok </eb:Description>

=item B<Version>

The ebMS Version.  This module supports version 2.0, so that is the
default value of this property.

The REQUIRED version attribute indicates the version of the ebXML
Message Service Header Specification to which the ebXML SOAP Header
extensions conform.  Its purpose is to provide future versioning
capabilities.  For conformance to this specification, all of the
version attributes on any SOAP extension elements defined in this
specification MUST have a value of "2.0".  An ebXML message MAY
contain SOAP header extension elements that have a value other than
"2.0".  An implementation conforming to this specification that
receives a message with ebXML SOAP extensions qualified with a version
other than "2.0" MAY process the message if it recognizes the version
identified and is capable of processing it.  It MUST respond with an
error (details TBD) if it does not recognize the identified version.

The version attribute MUST be namespace qualified for the ebXML SOAP
Envelope extensions namespace defined above.

Use of multiple versions of ebXML SOAP extensions elements within the
same ebXML SOAP document, while supported, should only be used in
extreme cases where it becomes necessary to semantically change an
element, which cannot wait for the next ebXML Message Service
Specification version release.

=item B<Manifest>

The Manifest element MAY be present as a child of the SOAP Body
element.  The Manifest element is a composite element consisting of
one or more Reference elements.  Each Reference element identifies
payload data associated with the message, whether included as part of
the message as payload document(s) contained in a Payload Container,
or remote resources accessible via a URL.  It is RECOMMENDED that no
payload data be present in the SOAP Body.  The purpose of the Manifest
is:

=over

=item *

to make it easier to directly extract a particular payload associated
with this ebXML Message,

=item *

to allow an application to determine whether it can process the
payload without having to parse it.

=back

The Manifest element is comprised of the following:

=over

=item

=item *

an id attribute

=item *

a version attribute

=item *

one or more Reference elements

=back
=item B<Reference>

The Reference element is a composite element consisting of the
following subordinate elements:

=over

=item *

zero or more Schema elements ­information about the schema(s) that
define the instance document identified in the parent Reference
element

=item *

zero or more Description elements ­a textual description of the
payload object referenced by the parent

=back

The Reference element itself is a simple link [XLINK]. It should be
noted that the use of XLINK in this context is chosen solely for the
purpose of providing a concise vocabulary for describing an
association.  Use of an XLINK processor or engine is NOT REQUIRED, but
may prove useful in certain implementations.

The Reference element has the following attribute content in addition
to the element content described above:

=over
=item *

id ­an XML ID for the Reference element,

=item *

xlink:type ­this attribute defines the element as being an XLINK
simple link. It has a fixed value of 'simple',

=item *

xlink:href ­this REQUIRED attribute has a value that is the URI of
the payload object referenced. It SHALL conform to the XLINK [XLINK]
specification criteria for a simple link.

=item *

xlink:role ­this attribute identifies some resource that describes
the payload object or its purpose. If present, then it SHALL have a
value that is a valid URI in accordance with the [XLINK]
specification,

=item *

Any other namespace-qualified attribute MAY be present. A Receiving
MSH MAY choose to ignore any foreign namespace attributes other than
those defined above.

=back

The designer of the business process or information exchange using
ebXML Messaging decides what payload data is referenced by the
Manifest and the values to be used for xlink:role.

=item B<Schema>

If the item being referenced has schema(s) of some kind that describe
it (e.g. an XML Schema, DTD and/or a database schema), then the Schema
element SHOULD be present as a child of the Reference element. It
provides a means of identifying the schema and its version defining
the payload object identified by the parent Reference element. The
Schema element contains the following attributes:

=over

=item location

the REQUIRED URI of the schema

=item version

a version identifier of the schema

=back

=back

=head2 B<Manifest Validation>

If an xlink:href attribute contains a URI that is a content id (URI
scheme "cid") then a MIME part with that content-id MUST be present in
the corresponding Payload Container of the message. If it is not, then
the error SHALL be reported to the From Party with an errorCode of
MimeProblem and a severity of Error.

If an xlink:href attribute contains a URI, not a content id (URI
scheme "cid"), and the URI cannot be resolved, it is an implementation
decision whether to report the error.  If the error is to be reported,
it SHALL be reported to the From Party with an errorCode of
MimeProblem and a severity of Error.  Note: If a payload exists, which
is not referenced by the Manifest, that payload SHOULD be discarded.

=cut

use strict 'vars', 'subs';

our $fields = {
	       string => {
			  'Version' => { init_default => "2.0", },
			  'CPAId' => { required => 1 },
			  'Action' => undef,
			  'Namespace' =>  { init_default => 'http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd',  },
			  'MessageId' => undef,
			  'RefMessageToId' => undef,
			  'Timestamp' =>  { init_default => \&generateTimestamp },
			  'ConversationId' => { required => 1 },
			 },
	       ref => {
		       'From' => { class => "ebXML::Message::ToFrom", },
		       'To' => { class => "ebXML::Message::ToFrom" },
		       'Service' => { class => "ebXML::Message::Service" },
		       'Manifest' => { class => "ebXML::Message::Manifest" },
		       'DuplicateElimination' => { class => "ebXML::Message::DuplicateElimination" },
		      },
	      };

BEGIN {
    # FIXME - should this go into Class::Tangram ?
    my %setters = ( From => "Message::Party",
                    To   => "Message::Party",
                    Service => "ebXML::Message::Service" );

    while ( my ($attrib, $class) = each %setters ) {
        my $class = "Message::Party";
        my $setter = "set_$attrib";
        *{$setter} = sub {
            my $self = shift;
            my $val  = shift;
            if (ref $val eq "ARRAY") {
                $val = $class->new(@$val)
            };
            return eval '$self->SUPER::'."$setter".'($val, @_);'
        }
    }
}

=head1 METHODS

Each object property has a B<$message-E<gt>get_X> and
B<$message-E<gt>set_X> method, which get and set the value,
respectively.  You can also use the simple B<$message-E<gt>X> as a
getter.

Additionally, the following methods may be called on B<ebXML::Message>
objects:

=over

=item B<$message-E<gt>getMIMEParts>

  returns a list of MIME::Entity objects built using the addPayload method

  no arguments

=cut

sub getMIMEParts {
    my $self = shift;
    my @parts = ();
    if ($self->haveMIMEParts) {
	@parts = values %{$self->{_sekrit}{MIME}{parts}};
	warn "returning mimeparts\n";
    } else {
	warn "we have no MIMEParts!\n";
    }
    return @parts;
}

=item B<$message-E<gt>haveMIMEParts>

  returns the count of MIME parts currently in the payload

  I love you honeybunny..  I love you too pumpkin.. Everybody be cool this is a robbery!

=cut

sub haveMIMEParts {
    my $self = shift;
    my $count = $self->{_sekrit}{MIME}{partcount} || 0;
    return $count;
}

=item B<$message-E<gt>getMIMEPart>

  returns a MIME::Entity object built using the addPayload method
  based on the name given as the first and only argument

=cut

sub getMIMEPart {
    my ($self,$name) = @_;
    my $part = $self->{_sekrit}{MIME}{parts}{$name};
    return $part;
}

=item B<$message-E<gt>addPayload>

Adds a payload to the message - takes either a set of options and a MIME::Entity object or string or filename

An Entity ( a MIME::Entity object ) or data (a scalar holding the mime payload content) or a path/filename
to an existing and accessable file (that will make up the mime payload) are required.

Also required are SchemaLocation, and Role (these relate to the ebXML rather than MIME itself)

optional arguments are description, Name, filename (required unless full path provided), path 
(required unless filename provided and includes full path), version (of Schema), content-id


$name = $message->addPayload(name=>'Foo',data=>$data, 'content-id'=>'payload-d',filename=>$filename,
                       Description => 'Purchase Order for 100,000 widgets',
		       SchemaLocation=> 'http://regrep.org/gci/purchaseOrder/po.xsd',
		       Role => 'http://regrep.org/gci/purchaseOrder', Name=>'PurchaseOrder',
		     );

or a MIME::Entity object

$name = $message->addpayload ( Entity => $entity, Description => 'Purchase Order for 100,000 widgets',
		       SchemaLocation=> 'http://regrep.org/gci/purchaseOrder/po.xsd',
		       Role => 'http://regrep.org/gci/purchaseOrder', Name=>'PurchaseOrder',
		     );

=cut

sub addPayload {
    my ($self, %options) = @_;
    my $name;
    $options{Entity} ||= $options{entity};
    $options{Description} ||= 'Not Applicable';
    $options{SchemaLocation} ||= 'default.xsd';
    $options{SchemaVersion} ||= '1';
    if ($options{Entity}) {
	$options{'content-id'} ||= $options{Entity}->head->mime_attr("content-id") || generate_content_id(%options);
	$name = $options{Entity}->head->mime_attr("content-id") || generate_content_id(%options) ;
    } else {
	my $id = generate_content_id(%options);
	$name = $options{name} || $options{Name} || generate_content_id(%options);
	my %arguments = (Disposition => "attachment", Type => "text/xml",);
	$options{filename} ||= $options{Filename} || '$name.tmp';
	$options{path} ||= $options{Path} || "/tmp/$options{filename}";
	$options{data} ||= $options{Data};
	unless ( -f $options{path} ) {
	    open (TMP,">$options{path}") or die "can't create tmp file for MIME part ( $options{path} ) : $!\n";
	    print TMP $options{data};
	    close TMP;
	    push(@{$self->{sekrit}{tmp_files}},$options{path} );
	}

	$options{'content-id'} = $id;

	my $mime_part = MIME::Entity->build ( Path        => $options{path},
					      Filename    => $options{filename},
					      Id          => $options{'content-id'});
	$options{Entity} = $mime_part;
    }
    $self->{_sekrit}{MIME}{parts}{$name} = $options{Entity};
    $self->{_sekrit}{MIME}{partcount}++;

    $self->Manifest->References_insert
	( ebXML::Message::Reference->new(
					 Description => ebXML::Message::Description->new(VALUE => $options{Description},
											 , xml_lang=> 'en-GB',),
					 Schema      => ebXML::Message::Schema->new(Version => $options{SchemaVersion},
										    Location => $options{SchemaLocation}, ),
					 id          => $options{'content-id'},
					 xlink_href  => "cid:$options{'content-id'}",
					 xlink_role  => $options{Role},
					), );

    return $name;
}

=item B<$message-E<gt>removePayload>

removes a named payload from from the message, returns 1 or 0 depending
if present or not

=cut

sub removePayload {
    my ($self, $name) = @_;
    my $success = 0;
    if ($self->{_sekrit}{MIME}{parts}{name}) {
	delete $self->{_sekrit}{MIME}{parts}{name};
	$success++;
    }
    return $success;
}

=item B<$message-E<gt>getOutput>

    returns one of : Xerces DOM Document object, SOAP::Data::Builder object,
    XML (generated via Xerces / DOM), XML (generated by SOAP::Data::Builder)
    depending on mode

    accepts one argument : mode which can be any of 'dom-xml','dom-doc',
    'soap-xml','soap-data'

=cut

sub getOutput {
    my ($self,$mode) = @_;
    my $output;

 MODE: {
	if (lc($mode) eq 'dom-xml') {
	    use ebXML::Message::DOMWriter;
	    $output = ebXML::Message::DOMWriter::getOutput(ebXML::Message::DOMWriter::databuilder($self));
	    last;
	}
	if (lc($mode) eq 'dom-doc') {
	    use ebXML::Message::DOMWriter;
	    $output = ebXML::Message::DOMWriter::databuilder($self);
	    last;
	}
	if (lc($mode) eq 'soap-data') {
	    use ebXML::Message::SOAPWriter;
	    $output = ebXML::Message::SOAPWriter::databuilder($self);
	    last;
	}
	if (lc($mode) eq 'soap-xml') {
	    use ebXML::Message::SOAPWriter;
	    $output = ebXML::Message::SOAPWriter::getOutput(ebXML::Message::SOAPWriter::databuilder($self));
	    last;
	}
	warn " no such mode : $mode ! \n";
    } # end of MODE

    return $output;
}

=back

=cut

sub DESTEROY {
    warn "DESTEROY called\n";
    my $self = shift;
    if (ref $self->{sekrit}{tmp_files}) {
	foreach my $file ( @{$self->{sekrit}{tmp_files}} ) {
	    warn "removing temp file $file \n";
	    unlink $file or warn "ERROR : unable to remove temp file ($file) : $!\n";
	}
    } else {
	warn "no temporary files to clean up\n";
    }
}

#########################################################################

sub generate_content_id {
    my ($self,%options) = @_;
    my $date = time;
    my $content_id;
    foreach my $option ( keys %options ) {
    OPTION: {
	    if (lc $option eq 'content-id') {
		$content_id = $options{$option};
		last;
	    }
	    if (lc $option eq 'name') {
		$content_id = "$options{$option}-$date";
		last;
	    }
	    if (lc $option eq 'filename') {
		$content_id = "$options{$option}-$date";
		last;
	    }
	    if (lc $option eq 'path') {
		($content_id) = reverse (split(/[\/\\]/,$options{$option}));
		$content_id .= "-$date";
		last;
	    }
	} # end of OPTION
    }
    return $content_id;
}

sub generateTimestamp {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = (localtime);
    my $timestamp = sprintf("%4d-%02d-%02dT%02s:%02s:%02d",$year+1900, $mon+1, $mday, $hour, $min, $sec);
    # 2000-07-25T12:19:05
    warn "timestamp : $timestamp\n";
    if ($self) { $self->Timestamp($timestamp) unless ($self->Timestamp); }
    return $timestamp;
}

sub requiresAction {
    my ($self,$value) = @_;
    if ($value) { $self->{_sekrit}{requiresAction} = $value; }
    my $yesno =  $self->{_sekrit}{requiresAction} || 0;
    return $yesno;
}

#########################################################################
# internal / private methods
#########################################################################

sub new_from_DOMDocument {
    my ($self,$doc) = @_;
    use ebXML::Message::DOMReader;
    my $class = ebXML::Message::DOMReader->new($doc);
    return $class;
}

#########################################################################
# Subclasses for ebXML::Message
#########################################################################

# ebXML::Message::Party
package ebXML::Message::Party;
use base qw(Class::Tangram);
our $fields = { string => [ qw(PartyId Type VALUE) ] };

#
# ebXML::Message::Manifest
package ebXML::Message::Manifest;
use base qw(Class::Tangram);
our $fields = { string => [ qw(id Version ) ], set => { References => { class => "ebXML::Message::Reference"} },};

#
# ebXML::Message::Description
package ebXML::Message::Description;
use base qw(Class::Tangram);
our $fields = {  string => [ qw(VALUE xml_lang) ] };

#
# ebXML::Message::Schema
package ebXML::Message::Schema;
use base qw(Class::Tangram);
our $fields = { string => [qw(Version Location)] };

#
# ebXML::Message::DuplicateElimination
package ebXML::Message::DuplicateElimination;
use base qw(Class::Tangram);
our $fields = { string => [qw(VALUE foo bar)]  };

#
# ebXML::Message::ToFrom
package ebXML::Message::ToFrom;
use base qw(Class::Tangram);
our $fields = { set => { Roles => { class => "ebXML::Message::Role" }, Partys => { class => "ebXML::Message::Party" } } };
#
# ebXML::Message::Role
package ebXML::Message::Role;
use base qw(Class::Tangram);
our $fields = { string => [ qw(VALUE)] };

###################################################################

=head1 EXAMPLES

=over

=item MessageHeader

The following fragment demonstrates the structure of the MessageHeader
element within the SOAP Header:

 <eb:MessageHeader eb:id="..." eb:version="2.0"
                   SOAP:mustUnderstand="1">
   <eb:From>
    <eb:PartyId>uri:example.com</eb:PartyId>
    <eb:Role>http://rosettanet.org/roles/Buyer</eb:Role>
  </eb:From>
   <eb:To>
       <eb:PartyId eb:type="someType">QRS543</eb:PartyId>
    <eb:Role>http://rosettanet.org/roles/Seller</eb:Role>
   </eb:To>
   <eb:CPAId>http://www.oasis-open.org/cpa/123456</eb:CPAId>
   <eb:ConversationId>987654321</eb:ConversationId>
   <eb:Service eb:type="myservicetypes">QuoteToCollect</eb:Service>
   <eb:Action>NewPurchaseOrder</eb:Action>
   <eb:MessageData>
     <eb:MessageId>UUID-2</eb:MessageId>
     <eb:Timestamp>2000-07-25T12:19:05</eb:Timestamp>
     <eb:RefToMessageId>UUID-1</eb:RefToMessageId>
   </eb:MessageData>
   <eb:DuplicateElimination/>
 </eb:MessageHeader>

=item B<Manifest>

The following fragment demonstrates a typical Manifest for a single payload MIME body part:

  <eb:Manifest eb:id="Manifest" eb:version="2.0">
      <eb:Reference eb:id="pay01"
        xlink:href="cid:payload-1"
        xlink:role="http://regrep.org/gci/purchaseOrder">
        <eb:Schema eb:location="http://regrep.org/gci/purchaseOrder/po.xsd"
                   eb:version="2.0"/>
        <eb:Description xml:lang="en-US">Purchase Order for
             100,000 widgets</eb:Description>
     </eb:Reference>
  </eb:Manifest>

=back


=cut

###################################################################
###################################################################

1;
