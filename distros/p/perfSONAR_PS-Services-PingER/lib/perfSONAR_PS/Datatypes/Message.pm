package perfSONAR_PS::Datatypes::Message;
{
=head1 NAME

 perfSONAR_PS::Datatypes::Message  -  this is a message handler object


=head1 DESCRIPTION

  
  
    new will return undef in case of wrong parameters ( will return Error object in the future )
   it accepts only one parameter -  reference, thats it
   the reference might be of type:
   hashref to the hash  with named parameters which can be used to initialize this object
      or
   DOM object 
     or 
   hashref with single key { xml => <xmlString>}, where xmlString ,must be valid Message xml element  or document

   it extends: 
     
    use perfSONAR_PS::Datatypes::v2_0::nmwg::Message; 
   
   Namespaces will be added dynamically from the underlying data and metadata
   
  
=head1 SYNOPSIS
             
  
	     use perfSONAR_PS::Datatypes::Message ;
	   
	     
	     my ($DOM) = $requestMessage->getElementsByTag('message');
	    
	     my $message = new perfSONAR_PS::Datatypes::Message($DOM);
             $message = new perfSONAR_PS::Datatypes::Message({id => '2345', 
	                                                     type = 'SetupdataResponse',
							     metadata => {'id1' =>   <obj>},
							     data=> {'id1' => <obj>}}); 
	 
	    #######   add data element, namespaces will be added from this object to Message object namespace declaration
             $message->addPartById('id1', 'data', new perfSONAR_PS::Datatypes::Message::data({id=> 'id1', metadataIdRef => 'metaid1' }));
        
	    ########add metadata element, namespaces will be added from this object to Message object namespace declaration
	     $message->addPartById('id1', 'metadata',  new perfSONAR_PS::Datatypes::Message::metadata({id=> 'id1' });
	     
	     my $dom = $message->getDOM(); # get as DOM 
	     print $message->asString();  # print the whole message
	     
	     
=head1   METHODS

=cut


use strict;
use warnings;
use Log::Log4perl qw(get_logger); 
use Clone::Fast qw(clone);
use XML::LibXML;
 
use Scalar::Util qw(blessed);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message; 
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
use perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum;

use perfSONAR_PS::Datatypes::Element qw(getElement);
 
use perfSONAR_PS::Datatypes::NSMap;
use perfSONAR_PS::Datatypes::EventTypes;
use base qw(perfSONAR_PS::Datatypes::v2_0::nmwg::Message);   
use fields qw( eventTypes mdID dataID filters DBO);
use constant  CLASSPATH =>  'perfSONAR_PS::Datatypes::Message';
use constant  LOCALNAME => 'message';
  
=head2 new( )
   
      creates message object, accepts parameter in form of:
      
      DOM with nmwg:message element tree or hashref to the list of
        type => <string>, id => <string> , namespace => {}, metadata => {}, ...,   data   => { }  ,
 	 
     or DOM object or hashref with single key { xml => <xmlString>}
    it extends:
     use perfSONAR_PS::Datatypes::v2_0::nmwg::Message 
     All parameters will be passed first to superclass
  
=cut

sub new { 
    my $that = shift;
    my $param = shift;
    my $logger  = get_logger( CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->eventTypes(perfSONAR_PS::Datatypes::EventTypes->new()); 
 
    $self->mdID(1);
    $self->dataID(1);
   
    
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( LOCALNAME, 'nmwg');
    if($param) {
        if(blessed $param && $param->can('getName')  && ($param->getName =~ m/(${\LOCALNAME})$/x) ) {
            return  $self->fromDOM($param);  
	      
        } elsif(ref($param) ne 'HASH')   {
            $logger->error("ONLY hash ref accepted as param " . $param ); 
            return undef;
        }
	if($param->{xml}) {
	     my $parser = XML::LibXML->new();
             my $dom;
             eval {
                  my $doc = $parser->parse_string( $param->{xml});
		  $dom = $doc->getDocumentElement;
             };
             if($@) {
                 $logger->error(" Failed to parse XML :" . $param->{xml} . " \n ERROR: \n" . $@);
                 return undef;
             }
             return  $self->fromDOM( $dom );  
	} 
        $logger->debug("Parsing parameters: " . (join " : ", keys %{$param}));
     
        no strict 'refs';
        map { $self->$_ ( $param->{$_} ) if $self->can($_)} keys %{$param}; ###  
        use strict;     
   
        $logger->debug("Done ");     
    }  
    return   $self ;
}
 
=head2 filters 

    add another filter object ( md ) or return array of filters

=cut


sub addFilter {
    my $self = shift;
    my $arg = shift;
    if($arg) {
        return push @{$self->{filters}},  $arg;
    } else {
        return $self->{filters}; 
    }
} 

=head2 filters 

    set filters array or return it

=cut


sub filters {
    my $self = shift;
    my $arg = shift;
    if($arg) {
        return  $self->{filters} = $arg;
    } else {
        return $self->{filters}; 
    }
} 

=head2 eventTypes

    set or return eventType 

=cut



sub eventTypes {
    my $self = shift;
    my $arg = shift;
    if($arg) {
        return $self->{eventTypes} = $arg;
    } else {
        return $self->{eventTypes}; 
    }
} 

=head2 DBO

    set or return DB object

=cut



sub DBO {
    my $self = shift;
    my $arg = shift;
    if($arg) {
        return $self->{DBO} = $arg;
    } else {
        return $self->{DBO}; 
    }
} 

=head2  mdID

   set id number for metadata element
   if no argument supplied then just return the current one

=cut

sub  mdID {
    my $self = shift;
    my $arg = shift;
    if($arg) {
        return $self->{mdID} = $arg
    } else {
        return $self->{mdID} 
    }
}
=head2 add_mdID

   increment id number for metadata element

=cut

sub add_mdID {
    my $self = shift;
    $self->{mdID}++; 
    return $self->{mdID}
}

=head2 add_dataID

   increment id number for  data element

=cut

sub  add_dataID {
    my $self = shift;
    $self->{dataID}++; 
    return $self->{dataID}
} 

=head2  dataID

   set id number for  data element
   if no argument supplied then just return the current one

=cut 

sub  dataID {
 my $self = shift;
   my $arg = shift;
   if($arg) {
       return $self->{dataID} = $arg
   } else {
       return $self->{dataID} 
   }

} 
 

=head2 getDom()

   accepts parent DOM object as argument
   returns newly created DOM with all namespaces acquired from underlying elements
   
=cut

sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( CLASSPATH ); 
    my $message_ns = $self->registerNamespaces(); 
     
    my @nss = map { $_  if($_ && $_  ne 'nmwg')}  keys %{$message_ns};
    push(@nss, 'nmwg');   
    $logger->debug(" NSMap ::" . (join " : " ,  @nss ));  
   
 
    my $message = getElement({name =>   LOCALNAME, parent => $parent , ns =>  [@nss],
                              attributes => [

                                                 ['type' =>  $self->type],
                                                 ['id' =>  $self->id],
                                            ],
        	                 }); 
    # $message->setNamespace(   "http://ggf.org/ns/nmwg/base/2.0/", 'nmwg', 1);   
    eval {
    if($self->metadata && ref($self->metadata) eq 'ARRAY' ) {
        foreach my $subel (@{$self->metadata}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($message);
		 
                 $subDOM?$message->appendChild($subDOM):$logger->error("Failed to append  metadata elements $subel with value: " .  $subDOM->toString ); 
            }
         }
    }
    };
    if($@) {
         $logger->debug("................... Metadata doomed " . $@);
    }
    
    if($self->data && ref($self->data) eq 'ARRAY' ) {
        foreach my $subel (@{$self->data}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($message);
                 $subDOM?$message->appendChild($subDOM):$logger->error("Failed to append  data elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
    
    return $message;
}  

=head2 getChain

      accept current metadata and chain this metadata with every reffered metadata,
      clone it, merge it with chained metadata and return new metadata
       eventType must be the same or eventTypes->ops->select
=cut
 
sub getChain {
    my $self = shift;
    my $currentmd = shift;
    my $logger  = get_logger( CLASSPATH ); 
    ## clone this metadata
    my $newmd = clone( $currentmd );
    my $idref = $newmd->metadataIdRef;
    ##check if its refered and eventType is the same
    ##if($newmd->key &&   $newmd->key->id) {
    ##    ## stop chaining since we found a key
    ##    return $newmd;
    ##} 
    if($idref) {
        my $checkmd =   $self->getMetadataById($idref);
        if(($newmd->eventType  eq    $checkmd->eventType) || ($checkmd->eventType eq $self->eventTypes->ops->select)) {
            # recursion
            my  $newInChain = $self->getChain($checkmd);
            # merge according to implementation ( without filtering )
	    $newmd->merge($newInChain);      
        } else {
	    $logger->error(" Reffered wrong eventType in the chain: " . $checkmd->eventType->asString );
	}
    }  
    return $newmd;  
}
 
 

=head2  addIDMetadata 
     
     
     add supplied  metadata, set id and set supplied eventtype
     arguments: $md,   $eventType 
     md id will be set as  "meta$someid"
     then metaId counter will be increased
     returns:  set metadata id
     
=cut

sub addIDMetadata {
    my ($self, $md, $event) = @_; 
    my $logger  = get_logger( CLASSPATH );
    my $current_mdid =  $self->mdID;
    $md->id("meta" . $self->mdID);
    $md->eventType( $event  );
    $self->addMetadata($md);# send back original request
    $self->add_mdID;
    return  $current_mdid;
}

=head2  addResultData

     add  data with result datum only to the   message
     arguments: hashref with keys - {metadataIdRef => $metaidkey, message =>  $message, eventType => $eventType})
      
     returns:  set data id

=cut


sub addResultData  {
    my ($self, $params)    = @_;
    my $logger  = get_logger( CLASSPATH ); 
    unless($params && ref($params) eq 'HASH' && $params->{metadataID} ) {
       $logger->error("Parameters missed:  addResultData Usage:: addResultData(\$params) where \$params is hashref");
      return undef;
    }  
     
    $params->{message} = ' no message ' unless $params->{message};
     my $current_id =  $self->dataID;
    my $data  =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({ id => "data" . $self->dataID, metadataIdRef => "meta" . $params->{metadataID}, 
	                     datum =>  [perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum->new({text =>  $params->{message}})] });
    $self->addData($data);
    $self->add_dataID;
    return  $current_id;  
}

=head2  addResultResponse

     add md with eventype and data with result datum, where contents of the datum is some message
     arguments: hashref - {md => $md, message =>  $message, eventType => $eventType})
     if $md is not supplied then new will be created and 
     returns: $self

=cut


sub addResultResponse( ) {
    my ($self, $params)    = @_;
    my $logger  = get_logger( CLASSPATH ); 
    unless($params && ref($params) eq 'HASH' && $params->{eventType} ) {
       $logger->error("Parameters missed:  addResultResponse Usage:: addResultResponse(\$params) where \$params is hashref");
      return undef;
    }  
    unless($params->{md} && blessed $params->{md}) {
       $params->{md}  = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new();
       $logger->debug(" New md was generated ");
    }
    $params->{message} = ' no message ' unless $params->{message};
    my $md_id = $self->addIDMetadata(  $params->{md},    $params->{eventType}); 
    $self->addResultData({ message =>  $params->{message},    metadataID  => $md_id}); 
    return $self;
}
 


=head2   MetadataKeyRequest

      this is abstract handler method for MetadataKey request, accepts response Message object 
      returns filled response message object  or error message
 
=cut

sub  MetadataKeyRequest {
   my $self = shift;
   my $response = shift;
   my $logger  = get_logger( CLASSPATH );   
   $logger->debug("MetadataKeyRequest  ...");
   $logger->error("MetadataKeyRequest  handler  Not   implemented by the service ");
   return  "MetadataKeyRequest  handler  Not   implemented by the service ";
}


=head2   SetupDataRequest

     this is abstract handler method forSetupData request,  accepts response Message object 
     returns filled response message object  or error message 

=cut

sub  SetupDataRequest  {
    my $self = shift;
    my $response = shift;
    my $logger  = get_logger( CLASSPATH ); 
    $logger->debug("SetupDataRequest  ...");
    $logger->error(" SetupDataRequest handler  Not   implemented by the service ");
    return  "SetupDataRequest handler  Not   implemented by the service";
}


=head2   MeasurementArchiveStoreRequest

    this is abstract method for MeasurementArchiveStore request, must be implemented by the tool
    returns filled response message object  or error message 
    
=cut

sub  MeasurementArchiveStoreRequest {
    my $self = shift;
    my $response = shift;
    my $logger  = get_logger( CLASSPATH );   
    $logger->error(" MeasurementArchiveStoreRequest   handler Not   implemented by the service ");
    return  " MeasurementArchiveStoreRequest   handler Not   implemented by the service ";
   
}
 
  
=head2 buildQuery
 
   build query for sql specific operation: ['lt', 'gt','eq','ge','le','ne'] 
   arguments: operation and  element object to run querySQL on
   returns: hashref to the found parameters and query as arrayref of form [  entryname1 => {'operator' => 'value1'},   entryname2 => {'operator' => 'value2'}, .... ]
   the whole structure will look as:
      {  'query_<tablename>' => [ <query> ], '<tablename>' => { sql_entry1 => value1, sql_entry2 => value2, ...} }
      

=cut

sub  buildQuery{
    my $self = shift;
    my $oper = shift;
    my $element = shift;
    my $logger  = get_logger( CLASSPATH ); 
    $logger->debug("  Quering...  ");
     
    my $queryhash  =  {};
    $element->querySQL($queryhash);
    $logger->debug("  Done  ");
  
    foreach my $table  (keys %{$queryhash}) {
        foreach my $entry (keys %{$queryhash->{$table}}) {
            push @{$queryhash->{"query_$table"}},  ($entry => { $oper =>  $queryhash->{$table}{$entry}} )  if  $queryhash->{$table}{$entry} && !ref($queryhash->{$table}{$entry});
        }
    }
    return   $queryhash;
}

 
=head2  processTime
    
    finds set time range from  any  element in the Message objects tree which is able to contain nmtm parameter with 
    startTime/endTime selects or timestamp
    returns:  hashref suitable for SQL query in form of - { gt => <unix epoch time>, lt => <unix epoch time>} or { eq => <unix epoch time>}
    $timequery->{eq|gt|lt} = unix_time
    arguments: hashref - {element => <element object with time inside>, timehash => <timehash in form of  {'start' => <>, 'end' =>'', duration => ''}>}
    
=cut

sub  processTime {
   my $self = shift;
   my $params = shift; 
   my $logger  = get_logger( CLASSPATH ); 
   unless($params && ref($params) eq 'HASH' && 
            (($params->{timehash} && ref($params->{timehash}) eq 'HASH') ||
            ($params->{element} && blessed $params->{element} && $params->{element}->can("querySQL"))) )  {
       $logger->error("Parameters missed: element or timequery  ");
       return 1;
   } 
    
   my $One_DAY_inSec = 86400;
   $params->{element}->querySQL($params->{timehash}) unless   $params->{timehash};
  
   require Data::Dumper;
   $logger->debug("  -------> Timestamp=  " . Data::Dumper::Dumper  $params->{timehash}); 
   
   my %timequery =  (gt =>  time() -  $One_DAY_inSec, lt =>  time());
   
   $timequery{gt} = $params->{timehash}->{'start'} if   $params->{timehash}->{'start'} && !ref($params->{timehash}->{'start'}) ;
   if($params->{timehash}->{'duration'} &&   !ref( $params->{timehash}->{'duration'})) {  
       $timequery{lt} =  $timequery{gt}  + $params->{timehash}->{'duration'}; 
   } elsif($params->{timehash}->{'end'} && !ref($params->{timehash}->{'end'})) {
       $timequery{lt} =  $params->{timehash}->{'end'};
   } else {
       my $tmp =  $timequery{gt};
       %timequery = (eq  => $timequery{gt});
   }
   unless( $timequery{eq} || $timequery{gt}) {
       $logger->error(" Failed to get time values,possible missed start time or timestamp from the data element commonTime  ");
       return undef;
   }
   $logger->debug("  -------> Processed Timestamp=  " . Data::Dumper::Dumper %timequery); 
   return \%timequery;
}



=head1 AUTHORS

   Maxim Grigoriev (FNAL)   2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Internet2
Copyright (C) 2007 by Fermitools, Fermilab

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
 


=cut
}

1;
