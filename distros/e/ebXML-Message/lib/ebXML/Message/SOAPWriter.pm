package ebXML::Message::SOAPWriter;

use SOAP::Data::Builder;

use SOAP::Lite;

sub databuilder {
    my $message = shift;

    my $soap_data_dom = SOAP::Data::Builder->new();

    #
    # MessageHeader
    $soap_data_dom->add_elem(name => 'eb:MessageHeader', header=>1, attributes=>{"eb:id"=>"..", "eb:version"=>$message->Version(),
										 "SOAP-ENV:mustUnderstand"=>"1",
										 'xmlns:eb'=>$message->Namespace()} );
    # From
    $soap_data_dom->add_elem(name=>'eb:From', parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    foreach my $partyid ( $message->From->Partys ) {
	my $elem = $soap_data_dom->add_elem(name=>'eb:PartyId', parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:From'),
					    value=>$partyid->VALUE,);
	$elem->set_attribute($type,$partyid->Type) if ($partyid->Type);
    }
    foreach my $role ( $message->From->Roles ) {
    	$soap_data_dom->add_elem(name=>'eb:Role', parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:From'),
				 value=>$role->VALUE,);
    }
    # To
    $soap_data_dom->add_elem(name=>'eb:To', parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    foreach my $partyid ( $message->To->Partys ) {
	my $elem = $soap_data_dom->add_elem(name=>'eb:PartyId', parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:To'),
					    value=>$partyid->VALUE,);
	$elem->set_attribute($type,$partyid->Type) if ($partyid->Type);

    }
    foreach my $role ( $message->To->Roles ) {
    	$soap_data_dom->add_elem(name=>'eb:Role', parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:To'),
				 value=>$role->VALUE);
    }
    # CPAId
    $soap_data_dom->add_elem(name=>'eb:CPAId', value=>$message->CPAId,
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    # ConversationId
    $soap_data_dom->add_elem(name=>'eb:ConversationId', value=>$message->ConversationId,
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    # Service
    my $service = $soap_data_dom->add_elem(name=>'eb:Service', value=>$message->Service->VALUE,
					   parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    $service->set_attribute($type,$message->Service->Type) if ($message->Service->Type);
    # Action
    $soap_data_dom->add_elem(name=>'eb:Action', value=>$message->Action,
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    # MessageData
    $soap_data_dom->add_elem(name=>'eb:MessageData',
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader'));
    # MessageId
    $soap_data_dom->add_elem(name=>'eb:MessageId', value=>$message->MessageId ,
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:MessageData'));
    # TimeStamp
    $soap_data_dom->add_elem(name=>'eb:Timestamp', value=>$message->Timestamp ,
			     parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:MessageData'));
    # RefToMessageID
    if ($message->RefMessageToId) {
	$soap_data_dom->add_elem(name=>'eb:RefToMessageID', value=>$message->RefMessageToId ,
				 parent=>$soap_data_dom->get_elem('eb:MessageHeader/eb:MessageData'));
    }

    # DuplicateElimination TBD
    # FIXME
#    $soap_data_dom->add_elem(name=>'eb:DuplicateElimination',
#			     parent=>$soap_data_dom->get_elem('eb:MessageHeader'));

    if ($message->Manifest) {
	#
	## Manifest TBD
	$soap_data_dom->add_elem(name => 'eb:Manifest', attributes => {'eb:id'=>'Manifest', 'eb:version'=>$message->Version,
								       'xmlns:eb'=>$message->Namespace, 'SOAP-ENV:mustUnderstand'=>'1'},
				 isMethod=>1);

	foreach my $reference ( $message->Manifest->References ) {
	    $soap_data_dom->add_elem(name=>'eb:Reference', attributes=> {
									 'eb:id'=>$reference->id,'xlink:href'=>$reference->xlink_href,
									 'xlink:role'=>$reference->xlink_role,
									},
				     parent=>$soap_data_dom->get_elem('eb:Manifest'));
	    $soap_data_dom->add_elem(name=>'eb:Description',
				     parent=>$soap_data_dom->get_elem('eb:Manifest/eb:Reference'),
				     attributes=>{'xml:lang'=>$reference->Description->xml_lang,},
				     value=>$reference->Description->VALUE);
	    $soap_data_dom->add_elem(name=>'eb:Schema',
				     parent=>$soap_data_dom->get_elem('eb:Manifest/eb:Reference'),
				     attributes=>{'eb:version'=>$reference->Schema->Version,
						  'eb:location'=>$reference->Schema->Location});
	}
    }
    return $soap_data_dom;
}

sub getOutput {
    my $builder = shift;
    my $output;

    return $output;
}


sub mungeSOAP {
    my $builder = shift;
    my $output;

    return $output;
}

1;
