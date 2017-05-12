package  perfSONAR_PS::Datatypes::v2_0::nmwg::Message;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmwg::Message  - A base class, implements  'message'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the message element.
   Object fields are:
    Scalar:     type, 
    Scalar:     id, 
    Object reference:   parameters => type ARRAY,
    Object reference:   metadata => type ARRAY,
    Object reference:   data => type ARRAY,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'message' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmwg::Message;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key::Parameters;
use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap type id parameters metadata data  );

perfSONAR_PS::Datatypes::v2_0::nmwg::Message->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmwg::Message->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         type   => undef, 
         id   => undef, 
         parameters => ARRAY,
         metadata => ARRAY,
         data => ARRAY,

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmwg::Message';
Readonly::Scalar our $LOCALNAME => 'message';
            
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( $CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( $LOCALNAME, 'nmwg');
    
    if($param) {
        if(blessed $param && $param->can('getName')  && ($param->getName =~ m/$LOCALNAME$/xm) ) {
            return  $self->fromDOM($param);  
          
        } elsif(ref($param) ne 'HASH')   {
            $logger->error("ONLY hash ref accepted as param " . $param ); 
            return;
        }
    if($param->{xml}) {
         my $parser = XML::LibXML->new();
             my $dom;
             eval {
                  my $doc = $parser->parse_string( $param->{xml});
          $dom = $doc->getDocumentElement;
             };
             if($EVAL_ERROR) {
                 $logger->error(" Failed to parse XML :" . $param->{xml} . " \n ERROR: \n" . $EVAL_ERROR);
                return;
             }
             return  $self->fromDOM( $dom );  
    } 
        $logger->debug("Parsing parameters: " . (join " : ", keys %{$param}));
     
        no strict 'refs';
        foreach my $param_key (keys %{$param}) {
            $self->$param_key( $param->{$param_key} ) if $self->can($param_key);
        }  
        use strict;     
   
       $logger->debug("Done ");     
    }  
    return $self;
}

 
sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY  if $self->can("SUPER::DESTROY");
    return;
}
 
=head2   getDOM ($) 
      
       accept parent DOM
       return message object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $message = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['type' =>  $self->type],
                                               ['id' =>  $self->id],
                                           ],
                         }); 
    if($self->parameters && ref($self->parameters) eq 'ARRAY' ) {
        foreach my $subel (@{$self->parameters}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($message);
                $subDOM?$message->appendChild($subDOM):$logger->error("Failed to append  parameters elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
    if($self->metadata && ref($self->metadata) eq 'ARRAY' ) {
        foreach my $subel (@{$self->metadata}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($message);
                $subDOM?$message->appendChild($subDOM):$logger->error("Failed to append  metadata elements  with value: " .  $subDOM->toString ); 
            }
         }
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
  
=head2  addparameters()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addParameters {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->parameters && ref($self->parameters) eq 'ARRAY'?push @{$self->parameters}, $new:$self->parameters([$new]); 
    $logger->debug("Added new to parameters"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->parameters;
}

=head2  removeParametersById()

     remove specific element from the array of parameters elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeParametersById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->parameters) eq 'ARRAY' && $self->idmap->{parameters} &&  exists $self->idmap->{parameters}{$id}) { 
        $self->parameters->[$self->idmap->{parameters}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->parameters};  
    $self->parameters([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->parameters)  || ref($self->parameters) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because parameters not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getParametersByMetadataIdRef()

     get specific object from the array of parameters elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getParametersByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->parameters) eq 'ARRAY' && $self->refidmap->{parameters} && exists $self->refidmap->{parameters}{$id}) {
        my $parameters = $self->parameters->[$self->refidmap->{parameters}{$id}];
    return ($parameters->can("metadataIdRef") &&   $parameters->metadataIdRef eq  $id)?$parameters:undef; 
    } elsif($self->parameters && (!ref($self->parameters) || 
                                    (ref($self->parameters) ne 'ARRAY' &&
                                     blessed $self->parameters && $self->parameters->can("metadataIdRef") &&
                     $self->parameters->metadataIdRef eq  $id)))  {
        return $self->parameters;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getParametersById()

     get specific element from the array of parameters elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getParametersById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->parameters) eq 'ARRAY' && $self->idmap->{parameters} &&  exists $self->idmap->{parameters}{$id} ) {
        return $self->parameters->[$self->idmap->{parameters}{$id}];
    } elsif(!ref($self->parameters) || ref($self->parameters) ne 'ARRAY')  {
        return $self->parameters;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
}
  
=head2  addmetadata()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addMetadata {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->metadata && ref($self->metadata) eq 'ARRAY'?push @{$self->metadata}, $new:$self->metadata([$new]); 
    $logger->debug("Added new to metadata"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->metadata;
}

=head2  removeMetadataById()

     remove specific element from the array of metadata elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeMetadataById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->metadata) eq 'ARRAY' && $self->idmap->{metadata} &&  exists $self->idmap->{metadata}{$id}) { 
        $self->metadata->[$self->idmap->{metadata}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->metadata};  
    $self->metadata([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->metadata)  || ref($self->metadata) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because metadata not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getMetadataByMetadataIdRef()

     get specific object from the array of metadata elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getMetadataByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->metadata) eq 'ARRAY' && $self->refidmap->{metadata} && exists $self->refidmap->{metadata}{$id}) {
        my $metadata = $self->metadata->[$self->refidmap->{metadata}{$id}];
    return ($metadata->can("metadataIdRef") &&   $metadata->metadataIdRef eq  $id)?$metadata:undef; 
    } elsif($self->metadata && (!ref($self->metadata) || 
                                    (ref($self->metadata) ne 'ARRAY' &&
                                     blessed $self->metadata && $self->metadata->can("metadataIdRef") &&
                     $self->metadata->metadataIdRef eq  $id)))  {
        return $self->metadata;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getMetadataById()

     get specific element from the array of metadata elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getMetadataById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->metadata) eq 'ARRAY' && $self->idmap->{metadata} &&  exists $self->idmap->{metadata}{$id} ) {
        return $self->metadata->[$self->idmap->{metadata}{$id}];
    } elsif(!ref($self->metadata) || ref($self->metadata) ne 'ARRAY')  {
        return $self->metadata;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
}
  
=head2  adddata()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addData {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->data && ref($self->data) eq 'ARRAY'?push @{$self->data}, $new:$self->data([$new]); 
    $logger->debug("Added new to data"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->data;
}

=head2  removeDataById()

     remove specific element from the array of data elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeDataById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->data) eq 'ARRAY' && $self->idmap->{data} &&  exists $self->idmap->{data}{$id}) { 
        $self->data->[$self->idmap->{data}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->data};  
    $self->data([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->data)  || ref($self->data) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because data not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getDataByMetadataIdRef()

     get specific object from the array of data elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getDataByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->data) eq 'ARRAY' && $self->refidmap->{data} && exists $self->refidmap->{data}{$id}) {
        my $data = $self->data->[$self->refidmap->{data}{$id}];
    return ($data->can("metadataIdRef") &&   $data->metadataIdRef eq  $id)?$data:undef; 
    } elsif($self->data && (!ref($self->data) || 
                                    (ref($self->data) ne 'ARRAY' &&
                                     blessed $self->data && $self->data->can("metadataIdRef") &&
                     $self->data->metadataIdRef eq  $id)))  {
        return $self->data;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getDataById()

     get specific element from the array of data elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getDataById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->data) eq 'ARRAY' && $self->idmap->{data} &&  exists $self->idmap->{data}{$id} ) {
        return $self->data->[$self->idmap->{data}{$id}];
    } elsif(!ref($self->data) || ref($self->data) ne 'ARRAY')  {
        return $self->data;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
}

=head2  querySQL ()

      depending on config  it will return some hash ref  to the initialized fields
    for example querySQL ()
    accepts one optional prameter - query hashref
    will return:
    { ip_name_src =>  'hepnrc1.hep.net' },}
    
=cut

sub  querySQL {
    my $self = shift;
    my $query = shift; ### undef at first and then will be hash ref
    my $logger  = get_logger( $CLASSPATH );
     
    foreach my $subname (qw/parameters metadata data/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering message  for subclass $subname");
            } else {
                $logger->error(" Failed for message Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    return $query;
}

=head2 merge

      merge with another message ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_message = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_message && blessed $new_message && $new_message->can("getDOM")) {
        $logger->error(" Please supply defined object of message  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_message->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_message->{$member_name};
        ###  check if both objects are defined
        if($current_member && $new_member) {
            ### if  one of them array then just add another one
            if(blessed $current_member && blessed $new_member  && $current_member->can("merge") 
               && ( $current_member->nsmap->mapname($member_name) 
                eq  $new_member->nsmap->mapname($member_name) ) ) {
               $current_member->merge($new_member);
            $self->{$member_name} =  $current_member;
            $logger->debug("  Merged $member_name , got" . $current_member->asString);
            ### if its array then just push
            } elsif(ref($current_member) eq 'ARRAY'){
                 
           $self->{$member_name}=[$current_member, $new_member];
              
            $logger->debug("  Pushed extra to $member_name ");
            }  
        ## thats it, dont merge if new member is just a scalar
        } elsif( $new_member) {
           $self->{$member_name} = $new_member;
        }   
    } else {
        $logger->error(" This field $member_name,  found in supplied  message  is not supported by message class");
        return;
        }
    }
    return $self;
} 
 
=head2  buildIdMap()

    if any of subelements has id then get a map of it in form of
    hashref to { element}{id} = index in array and store in the idmap field

=cut

sub  buildIdMap {
    my $self = shift;
    my $map = (); 
    my $logger  = get_logger( $CLASSPATH );
    foreach my $field (qw/parameters metadata data/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        my $i = 0;
        foreach my $el ( @array)  {
            if($el && blessed $el && $el->can("id") &&  $el->id)  { 
                $map->{$field}{$el->id} = $i;   
            }
            $i++;
        }
    }
    return $self->idmap($map);
}
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my $self = shift;
    my %map = (); 
    my $logger  = get_logger( $CLASSPATH );
    foreach my $field (qw/parameters metadata data/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        my $i = 0;
        foreach my $el ( @array)  {
            if($el && blessed $el  && $el->can("metadataIdRef") &&  $el->metadataIdRef )  { 
                $map{$field}{$el->metadataIdRef} = $i;   
            }
            $i++;
        }
    }
    return $self->refidmap(\%map);
}
=head2  asString()

   shortcut to get DOM and convert into the XML string
   returns XML string  representation of the  message object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the message namespace

=cut

sub registerNamespaces {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH );
    my $nsids = shift;
    my $local_nss = {reverse %{$self->nsmap->mapname}};
    unless($nsids) {
        $nsids =  $local_nss;
    }  else {
        %{$nsids} = ( %{$local_nss},  %{$nsids});
    }
    foreach my $field (qw/parameters metadata data/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        foreach my $el ( @array)  {
            if(blessed $el &&   $el->can("registerNamespaces") )  { 
                my $fromNSmap =  $el->registerNamespaces($nsids); 
                my %ns_idmap =   %{$fromNSmap};  
                foreach my $ns ( keys %ns_idmap)  {
                      $nsids->{$ns}++
                }
            }
        }
    }
    return     $nsids;
}
=head2  fromDOM ($)
   
   accepts parent XML DOM   element   tree as parameter 
   returns message  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->type($dom->getAttribute('type')) if($dom->getAttribute('type'));
    $logger->debug(" Attribute type= ". $self->type) if $self->type; 
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 
    foreach my $childnode ($dom->childNodes) { 
        my  $getname  = $childnode->getName;
        my ($nsid, $tagname) = split $COLUMN_SEPARATOR,  $getname; 
        unless($nsid && $tagname) {   
            next;
        }
        if ($tagname eq  'parameters' && $nsid eq 'pinger' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Parameters : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->parameters && ref($self->parameters) eq 'ARRAY')?push @{$self->parameters}, $element:$self->parameters([$element]);; ### add another parameters  
        }  elsif ($tagname eq  'metadata' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Metadata : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->metadata && ref($self->metadata) eq 'ARRAY')?push @{$self->metadata}, $element:$self->metadata([$element]);; ### add another metadata  
        }  elsif ($tagname eq  'data' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Data : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->data && ref($self->data) eq 'ARRAY')?push @{$self->data}, $element:$self->data([$element]);; ### add another data  
        }      ###  $dom->removeChild($childnode); ##remove processed element from the current DOM so subclass can deal with remaining elements
    }
  $self->buildIdMap;
 $self->buildRefIdMap;
 $self->registerNamespaces;
  
 return $self;
}

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim@fnal.gov

=cut 

1;
 
