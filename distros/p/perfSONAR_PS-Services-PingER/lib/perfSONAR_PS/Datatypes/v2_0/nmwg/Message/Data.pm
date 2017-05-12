package  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data  - A base class, implements  'data'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the data element.
   Object fields are:
    Scalar:     metadataIdRef, 
    Scalar:     id, 
    Object reference:   commonTime => type ARRAY,
    Object reference:   datum => type ARRAY,
    Object reference:   key => type HASH,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'data' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime;
use perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::Datum;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap metadataIdRef id commonTime datum key  );

perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         metadataIdRef   => undef, 
         id   => undef, 
         commonTime => ARRAY,
         datum => ARRAY,
         key => HASH,

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data';
Readonly::Scalar our $LOCALNAME => 'data';
            
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
       return data object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $data = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['metadataIdRef' =>  $self->metadataIdRef],
                                               ['id' =>  $self->id],
                                           ],
                         }); 
    if($self->commonTime && ref($self->commonTime) eq 'ARRAY' ) {
        foreach my $subel (@{$self->commonTime}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($data);
                $subDOM?$data->appendChild($subDOM):$logger->error("Failed to append  commonTime elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
    if(!($self->commonTime) && $self->datum && ref($self->datum) eq 'ARRAY' ) {
        foreach my $subel (@{$self->datum}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($data);
                $subDOM?$data->appendChild($subDOM):$logger->error("Failed to append  datum elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
   if(!($self->commonTime && $self->datum) && $self->key  && blessed $self->key  && $self->key->can("getDOM")) {
        my  $keyDOM = $self->key->getDOM($data);
       $keyDOM?$data->appendChild($keyDOM):$logger->error("Failed to append  key  with value: " .  $keyDOM->toString ); 
   }
    return $data;
}
  
=head2  addcommonTime()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addCommonTime {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->commonTime && ref($self->commonTime) eq 'ARRAY'?push @{$self->commonTime}, $new:$self->commonTime([$new]); 
    $logger->debug("Added new to commonTime"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->commonTime;
}

=head2  removeCommonTimeById()

     remove specific element from the array of commonTime elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeCommonTimeById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->commonTime) eq 'ARRAY' && $self->idmap->{commonTime} &&  exists $self->idmap->{commonTime}{$id}) { 
        $self->commonTime->[$self->idmap->{commonTime}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->commonTime};  
    $self->commonTime([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->commonTime)  || ref($self->commonTime) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because commonTime not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getCommonTimeByMetadataIdRef()

     get specific object from the array of commonTime elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getCommonTimeByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->commonTime) eq 'ARRAY' && $self->refidmap->{commonTime} && exists $self->refidmap->{commonTime}{$id}) {
        my $commonTime = $self->commonTime->[$self->refidmap->{commonTime}{$id}];
    return ($commonTime->can("metadataIdRef") &&   $commonTime->metadataIdRef eq  $id)?$commonTime:undef; 
    } elsif($self->commonTime && (!ref($self->commonTime) || 
                                    (ref($self->commonTime) ne 'ARRAY' &&
                                     blessed $self->commonTime && $self->commonTime->can("metadataIdRef") &&
                     $self->commonTime->metadataIdRef eq  $id)))  {
        return $self->commonTime;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getCommonTimeById()

     get specific element from the array of commonTime elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getCommonTimeById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->commonTime) eq 'ARRAY' && $self->idmap->{commonTime} &&  exists $self->idmap->{commonTime}{$id} ) {
        return $self->commonTime->[$self->idmap->{commonTime}{$id}];
    } elsif(!ref($self->commonTime) || ref($self->commonTime) ne 'ARRAY')  {
        return $self->commonTime;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
}
  
=head2  adddatum()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addDatum {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->datum && ref($self->datum) eq 'ARRAY'?push @{$self->datum}, $new:$self->datum([$new]); 
    $logger->debug("Added new to datum"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->datum;
}

=head2  removeDatumById()

     remove specific element from the array of datum elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeDatumById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->datum) eq 'ARRAY' && $self->idmap->{datum} &&  exists $self->idmap->{datum}{$id}) { 
        $self->datum->[$self->idmap->{datum}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->datum};  
    $self->datum([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->datum)  || ref($self->datum) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because datum not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getDatumByMetadataIdRef()

     get specific object from the array of datum elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getDatumByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->datum) eq 'ARRAY' && $self->refidmap->{datum} && exists $self->refidmap->{datum}{$id}) {
        my $datum = $self->datum->[$self->refidmap->{datum}{$id}];
    return ($datum->can("metadataIdRef") &&   $datum->metadataIdRef eq  $id)?$datum:undef; 
    } elsif($self->datum && (!ref($self->datum) || 
                                    (ref($self->datum) ne 'ARRAY' &&
                                     blessed $self->datum && $self->datum->can("metadataIdRef") &&
                     $self->datum->metadataIdRef eq  $id)))  {
        return $self->datum;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getDatumById()

     get specific element from the array of datum elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getDatumById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->datum) eq 'ARRAY' && $self->idmap->{datum} &&  exists $self->idmap->{datum}{$id} ) {
        return $self->datum->[$self->idmap->{datum}{$id}];
    } elsif(!ref($self->datum) || ref($self->datum) ne 'ARRAY')  {
        return $self->datum;
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
     
    foreach my $subname (qw/commonTime datum key/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering data  for subclass $subname");
            } else {
                $logger->error(" Failed for data Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    return $query;
}

=head2 merge

      merge with another data ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_data = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_data && blessed $new_data && $new_data->can("getDOM")) {
        $logger->error(" Please supply defined object of data  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_data->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_data->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  data  is not supported by data class");
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
    foreach my $field (qw/commonTime datum key/) {
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
    foreach my $field (qw/commonTime datum key/) {
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
   returns XML string  representation of the  data object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the data namespace

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
    foreach my $field (qw/commonTime datum key/) {
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
   returns data  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->metadataIdRef($dom->getAttribute('metadataIdRef')) if($dom->getAttribute('metadataIdRef'));
    $logger->debug(" Attribute metadataIdRef= ". $self->metadataIdRef) if $self->metadataIdRef; 
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 
    foreach my $childnode ($dom->childNodes) { 
        my  $getname  = $childnode->getName;
        my ($nsid, $tagname) = split $COLUMN_SEPARATOR,  $getname; 
        unless($nsid && $tagname) {   
            next;
        }
        if ($tagname eq  'commonTime' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  CommonTime : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->commonTime && ref($self->commonTime) eq 'ARRAY')?push @{$self->commonTime}, $element:$self->commonTime([$element]);; ### add another commonTime  
        }  elsif (!($self->commonTime) && $tagname eq  'datum' && $nsid eq 'pinger' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::Datum->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Datum : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->datum && ref($self->datum) eq 'ARRAY')?push @{$self->datum}, $element:$self->datum([$element]);; ### add another datum  
        }  elsif (!($self->commonTime) && $tagname eq  'datum' && $nsid eq 'nmwgr' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Datum : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->datum && ref($self->datum) eq 'ARRAY')?push @{$self->datum}, $element:$self->datum([$element]);; ### add another datum  
        }  elsif (!($self->commonTime && $self->datum) && $tagname eq  'key' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Key : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->key($element); ### add another key  
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
 
