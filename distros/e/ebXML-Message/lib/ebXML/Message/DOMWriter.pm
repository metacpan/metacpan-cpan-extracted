package ebXML::Message::DOMWriter;

use strict;
use XML::Xerces;

my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');

sub databuilder {
    my $msg = shift;

    #
    # build base document
    my $doc = eval{$impl->createDocument('http://schemas.xmlsoap.org/soap/envelope/', 'SOAP-ENV:Envelope',undef)};
    XML::Xerces::error($@) if $@;
    my $root = $doc->getDocumentElement();

    $root->setAttribute('xmlns:xlink',"http://www.w3c.org/1999/xlink/namespace");
    $root->setAttribute('xsi:schemaLocation',"http://schemas.xmlsoap.org/soap/envelope/ http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd");
    $root->setAttribute('xmlns:SOAP-ENC',"http://schemas.xmlsoap.org/soap/encoding/");
    $root->setAttribute('SOAP-ENV:encodingStyle',"http://schemas.xmlsoap.org/soap/encoding/");
    $root->setAttribute('xmlns:xsd',"http://www.w3.org/1999/XMLSchema");
    $root->setAttribute('xmlns:xsi',"http://www.w3.org/1999/XMLSchema-instance");

    my $soap_header = $doc->createElement ("SOAP-ENV:Header");
    $root->appendChild($soap_header);
    $soap_header->setAttribute('xmlns:eb',"http://www.ebxml.org/namespaces/messageHeader");
    $soap_header->setAttribute('xsi:schemaLocation',"http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd");

    my $soap_body = $doc->createElement ("SOAP-ENV:Body");
    $root->appendChild($soap_body);
    $soap_body->setAttribute('xmlns:eb',"http://www.ebxml.org/namespaces/messageHeader");
    $soap_body->setAttribute('xsi:schemaLocation',"http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd");


    #
    # build ebxml message header
    $soap_header->appendChild( CreateMessageHeader( $doc,$msg->From, $msg->To, $msg->CPAId,
						  $msg->ConversationId, $msg->Service,
						  $msg->Action, $msg->MessageId, $msg->Timestamp,
						  $msg->RefMessageToId, $msg->DuplicateElimination,$msg->Version ) );

    #
    # build ebxml message body
    $soap_body->appendChild( CreateMessageBody( $doc,$msg->Manifest,$msg->Version ) );

    return $doc;
}

sub getOutput {
    my $doc = shift;
    my $writer = $impl->createDOMWriter();
    if ($writer->canSetFeature('format-pretty-print',1)) {
	$writer->setFeature('format-pretty-print',1);
    }

    my $target = XML::Xerces::MemBufFormatTarget->new();
    $writer->writeNode($target,$doc);

    my $xml = $target->getRawBuffer;
}

sub CreateMessageHeader {
    my ($doc, $from, $to, $cpa_id, $conversation_id, $service,
	$action, $message_id, $timestamp, $refto, $dup, $version) = @_;
    my $message_header = $doc->createElement ("eb:MessageHeader");

    # <eb:MessageHeader xmlns:eb="http://www.ebxml.org/namespaces/messageHeader" SOAP-ENV:mustUnderstand="1" eb:version="2" eb:id="..">

    $message_header->setAttribute('xmlns:eb',"http://www.ebxml.org/namespaces/messageHeader");
    $message_header->setAttribute('SOAP-ENV:mustUnderstand',"1");
    $message_header->setAttribute('eb:version',$version);
    $message_header->setAttribute('eb:id',"..");

    # <eb:From><eb:PartyId>uri:example.com</eb:PartyId><eb:Role>http://path.to/roles/foo</eb:Role></eb:From>
    my $ebfrom = $doc->createElement('eb:From');
    $message_header->appendChild ($ebfrom);
    foreach my $partyid ( $from->Partys ) {
	my $ebpartyid = $doc->createElement('eb:PartyId');
	my $value = $doc->createTextNode($partyid->VALUE);
	$ebpartyid->appendChild($value);
	$ebpartyid->setAttribute('eb:Type',$partyid->Type);
	$ebfrom->appendChild ($ebpartyid);
    }
    foreach my $role ( $from->Roles ) {
	my $ebrole = $doc->createElement('eb:Role');
	my $value = $doc->createTextNode($role->VALUE);
	$ebrole->appendChild($value);
	$ebfrom->appendChild ($ebrole);
    }

    # <eb:To><eb:PartyId>uri:example.com/bar</eb:PartyId><eb:Role>http://path.to/roles/bar</eb:Role></eb:To>
    my $ebto = $doc->createElement('eb:To');
    $message_header->appendChild ($ebto);
    foreach my $partyid ( $to->Partys ) {
	my $ebpartyid = $doc->createElement('eb:PartyId');
	my $value = $doc->createTextNode($partyid->VALUE);
	$ebpartyid->appendChild($value);
	$ebpartyid->setAttribute('eb:Type',$partyid->Type);
	$ebto->appendChild ($ebpartyid);
    }
    foreach my $role ( $to->Roles ) {
	my $ebrole = $doc->createElement('eb:Role');
	my $value = $doc->createTextNode($role->VALUE);
	$ebrole->appendChild($value);
	$ebto->appendChild ($ebrole);
    }

    # <eb:CPAId>http://www.oasis-open.org/cpa/123456</eb:CPAId>
    my $ebcpaid = $doc->createElement('eb:CPAId');
    $message_header->appendChild ($ebcpaid);
    $ebcpaid->appendChild($doc->createTextNode($cpa_id));

    # <eb:Service eb:type="myservicetypes">QuoteToCollect</eb:Service>
    my $ebservice = $doc->createElement('eb:Service');
    $ebservice->appendChild($doc->createTextNode($service->VALUE));
    $ebservice->setAttribute('eb:Type',$service->Type);
    $message_header->appendChild($ebservice);

    # <eb:Action>NewPurchaseOrder</eb:Action>
    my $ebaction = $doc->createElement('eb:Action');
    $ebaction->appendChild($doc->createTextNode($action));
    $message_header->appendChild($ebaction);

    # <eb:MessageData>
    #   <eb:MessageId>UUID-2</eb:MessageId>
    #   <eb:Timestamp>2000-07-25T12:19:05</eb:Timestamp>
    #   <eb:RefToMessageID>UUID-1</eb:RefToMessageID>
    my $ebmessagedata = $doc->createElement('eb:MessageData');
    $message_header->appendChild($ebmessagedata);
    my $ebmessageid = $doc->createElement('eb:MessageId');
    $ebmessageid->appendChild($doc->createTextNode($message_id));
    $ebmessagedata->appendChild($ebmessageid);
    my $ebtimestamp = $doc->createElement('eb:Timestamp');
    $ebtimestamp->appendChild($doc->createTextNode($timestamp));
    $ebmessagedata->appendChild($ebtimestamp);
    if ($refto) {
	my $ebreftomessage = $doc->createElement('eb:RefToMessageID');
	$ebreftomessage->appendChild($doc->createTextNode($refto));
	$ebmessagedata->appendChild($ebreftomessage);
    }

    # <eb:DuplicateElimination xsi:null="1"/>
#    my $ebduplicate = $doc->createElement('eb:DuplicateElimination');
#    $message_header->appendChild($ebduplicate);
    # TBD : handle Duplicate Elimination

    return $message_header;
}

sub CreateMessageBody {
    my ($doc,$version) = @_;
    my $message_body = $doc->createElement ("eb:Manifest");
    $message_body->setAttribute('xmlns:eb',"http://www.ebxml.org/namespaces/messageHeader");
    $message_body->setAttribute('SOAP-ENV:mustUnderstand',"1");
    $message_body->setAttribute('eb:version',$version);
    $message_body->setAttribute('eb:id',"Manifest");

    # TBD - Manifest and References
    # FIXME - need to handle Manifest and References

    return $message_body;
}

1;
