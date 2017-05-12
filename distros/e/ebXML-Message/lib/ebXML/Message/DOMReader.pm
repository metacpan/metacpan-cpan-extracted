package ebXML::Message::DOMReader;

use strict;

use XML::Xerces;
use XML::Xerces::BagOfTricks qw(:all);
use ebXML::Message;

use Data::Dumper;

sub new {
    my ($class,$doc,%options) = @_;

    my $root=$doc->getFirstChild;

    my %root_attr = $root->getAttributes();

    # get namespace prefixes from SOAP-ENV:Envelope
    warn "getting prefixes \n";
    my ($ebns,$soapns,$xlinkns);
    foreach my $key (keys %root_attr) {
	warn "key : $key \n";
	if ($key =~ /xmlns:(.*soap.*)/i) { warn " found possible soap prefix $1 : $root_attr{$key} ";
					   my $ns = $1; $soapns = $ns if ($root_attr{$key} =~ /envelope/i);}
	if ($key =~ /xmlns:(.*eb.*)/i) { warn " found eb prefix "; $ebns = $1;}
	if ($key =~ /xmlns:(.*xl.*)/i) { warn " found xlink prefix "; $xlinkns = $1; } 
    }

    my $rootname = $root->getTagName();
    unless ($rootname eq "$soapns:Envelope")
    { warn "'$rootname' isn't '$soapns:Envelope'\n"}

    # get namespace prefixes from SOAP-ENV:Header
    my ($soapheader) = $root->getElementsByTagName("$soapns:Header");
    my %soapheader_attr = $soapheader->getAttributes();
    foreach my $key (keys %soapheader_attr) {
	warn "key : $key \n";
	if ($key =~ /xmlns:(.*soap.*)/i) { warn " found possible soap prefix $1 : $root_attr{$key} ";
					   my $ns = $1; $soapns ||= $ns if ($root_attr{$key} =~ /envelope/i);}
	if ($key =~ /xmlns:(.*eb.*)/i) { warn " found eb prefix "; $ebns ||= $1;}
	if ($key =~ /xmlns:(.*xl.*)/i) { warn " found xlink prefix "; $xlinkns ||= $1; } 
    }

    # FIXME / REFACTORME
    # NB it is probably worth pre-parsing through the nodes and building a simple data
    # structure rather than a series of calls through DOM

    # if we don't have the ebXML namespace / prefix
    # get first child from soapheader - added to support Hermes MSH
    unless ($ebns) {
	foreach my $child ( $soapheader->getChildNodes() ) {
	    if ($child->getNodeName =~ /MessageHeader/) {
		$ebns = $child->getPrefix();
		$root_attr{"xmlns:$ebns"} = $soapheader_attr{"xmlns:$ebns"} = $child->getNamespaceURI;
		last;
	    }
	}
    }

    my ($ebheader) = $soapheader->getElementsByTagName("$ebns:MessageHeader");
    my ($soapbody) = $root->getElementsByTagName("$soapns:Body");
    my %header_attr = $ebheader->getAttributes();

    my $message = ebXML::Message->new(
				      'Version' => $header_attr{"$ebns:version"},
				      'CPAId' => getTextContents($ebheader->getElementsByTagName("$ebns:CPAId")),
				      'Action' => getTextContents($ebheader->getElementsByTagName("$ebns:Action")),
				      'Namespace' => $root_attr{"xmlns:$ebns"} || $soapheader_attr{"xmlns:$ebns"},
				      'MessageId' => 'response-00001',
				      'RefMessageToId' => getTextContents($ebheader->getElementsByTagName("$ebns:RefMessageToId")) || '0',
				      'ConversationId' => getTextContents($ebheader->getElementsByTagName("$ebns:ConversationId")) || '0',
				      'Service' => ebXML::Message::Service->new( VALUE =>getTextContents($ebheader->getElementsByTagName("$ebns:Service"))),
				      'To' => ebXML::Message::ToFrom->new,
				      'From' => ebXML::Message::ToFrom->new
				      );


    # process manifest if we have one
    my ($ebmanifest) = $soapbody->getElementsByTagName("$ebns:Manifest");
    if (ref $ebmanifest) {
	$message->Manifest( ebXML::Message::Manifest->new (id=>'Manifest',Version=>$header_attr{"$ebns:version"}));
	if ( scalar $ebmanifest->getElementsByTagName("$ebns:Reference") ) {
	    warn " have references \n";
	    foreach my $ebreference ($ebmanifest->getElementsByTagName("$ebns:Reference")) {
		warn "handling reference\n";
	    }
	} else {
	    warn " don't have references \n";
	}
    }

    # process to / from
    my ($ebto) = $ebheader->getElementsByTagName("$ebns:To");
    foreach my $party ( $ebto->getElementsByTagName("$ebns:PartyId") ) {
	# FIXME : get PartyId, Type from party attributes
	$message->To->Partys->insert(ebXML::Message::Party->new(PartyId=>'0001', VALUE=>getTextContents($party), Type=>'type2'));
    }
    foreach my $role ( $ebto->getElementsByTagName("$ebns:Role") ) {
	$message->To->Roles->insert(ebXML::Message::Role->new(VALUE=>getTextContents($role)));
    }

    my ($ebfrom) = $ebheader->getElementsByTagName("$ebns:From");
    foreach my $party ( $ebto->getElementsByTagName("$ebns:PartyId") ) {
	# FIXME : get PartyId, Type from party attributes
	$message->From->Partys->insert(ebXML::Message::Party->new(PartyId=>'0001', VALUE=>getTextContents($party), Type=>'type2'));
    }
    foreach my $role ( $ebto->getElementsByTagName("$ebns:Role") ) {
	$message->From->Roles->insert(ebXML::Message::Role->new(VALUE=>getTextContents($role)));
    }

    return $message;
}


1;
