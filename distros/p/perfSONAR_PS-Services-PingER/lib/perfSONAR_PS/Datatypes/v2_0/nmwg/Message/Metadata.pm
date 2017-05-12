package  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata  - A base class, implements  'metadata'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the metadata element.
   Object fields are:
    Scalar:     metadataIdRef, 
    Scalar:     id, 
    Object reference:   subject => type ARRAY,
    Object reference:   parameters => type ARRAY,
    Object reference:   eventType => type ,
    Object reference:   key => type HASH,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'metadata' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Subject;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters;
use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap metadataIdRef id subject parameters key eventType );

perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         metadataIdRef   => undef, 
         id   => undef, 
         subject => ARRAY,
         parameters => ARRAY,
         key => HASH,

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata';
Readonly::Scalar our $LOCALNAME => 'metadata';
            
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
       return metadata object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $metadata = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['metadataIdRef' =>  $self->metadataIdRef],
                                               ['id' =>  $self->id],
                                           ],
                         }); 
   if($self->subject  && blessed $self->subject  && $self->subject->can("getDOM")) {
        my  $subjectDOM = $self->subject->getDOM($metadata);
       $subjectDOM?$metadata->appendChild($subjectDOM):$logger->error("Failed to append  subject  with value: " .  $subjectDOM->toString ); 
   }
   if($self->parameters  && blessed $self->parameters  && $self->parameters->can("getDOM")) {
        my  $parametersDOM = $self->parameters->getDOM($metadata);
       $parametersDOM?$metadata->appendChild($parametersDOM):$logger->error("Failed to append  parameters  with value: " .  $parametersDOM->toString ); 
   }
   if($self->key  && blessed $self->key  && $self->key->can("getDOM")) {
        my  $keyDOM = $self->key->getDOM($metadata);
       $keyDOM?$metadata->appendChild($keyDOM):$logger->error("Failed to append  key  with value: " .  $keyDOM->toString ); 
   }
   foreach my $textnode (qw/eventType /) {
       if($self->{$textnode}) { 
            my  $domtext  =  getElement({name =>   $textnode, parent => $metadata , ns => [$self->nsmap->mapname($LOCALNAME)],
                                          text => $self->{$textnode},
                                 });
            $domtext?$metadata->appendChild($domtext):$logger->error("Failed to append new text element $textnode  to  metadata   ");
        } 
   } 
    return $metadata;
}
  
=head2  addsubject()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addSubject {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->subject && ref($self->subject) eq 'ARRAY'?push @{$self->subject}, $new:$self->subject([$new]); 
    $logger->debug("Added new to subject"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->subject;
}

=head2  removeSubjectById()

     remove specific element from the array of subject elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeSubjectById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->subject) eq 'ARRAY' && $self->idmap->{subject} &&  exists $self->idmap->{subject}{$id}) { 
        $self->subject->[$self->idmap->{subject}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->subject};  
    $self->subject([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->subject)  || ref($self->subject) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because subject not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getSubjectByMetadataIdRef()

     get specific object from the array of subject elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getSubjectByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->subject) eq 'ARRAY' && $self->refidmap->{subject} && exists $self->refidmap->{subject}{$id}) {
        my $subject = $self->subject->[$self->refidmap->{subject}{$id}];
    return ($subject->can("metadataIdRef") &&   $subject->metadataIdRef eq  $id)?$subject:undef; 
    } elsif($self->subject && (!ref($self->subject) || 
                                    (ref($self->subject) ne 'ARRAY' &&
                                     blessed $self->subject && $self->subject->can("metadataIdRef") &&
                     $self->subject->metadataIdRef eq  $id)))  {
        return $self->subject;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getSubjectById()

     get specific element from the array of subject elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getSubjectById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->subject) eq 'ARRAY' && $self->idmap->{subject} &&  exists $self->idmap->{subject}{$id} ) {
        return $self->subject->[$self->idmap->{subject}{$id}];
    } elsif(!ref($self->subject) || ref($self->subject) ne 'ARRAY')  {
        return $self->subject;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
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
     
    foreach my $subname (qw/subject parameters key/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering metadata  for subclass $subname");
            } else {
                $logger->error(" Failed for metadata Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    return $query;
}

=head2 merge

      merge with another metadata ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_metadata = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_metadata && blessed $new_metadata && $new_metadata->can("getDOM")) {
        $logger->error(" Please supply defined object of metadata  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_metadata->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_metadata->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  metadata  is not supported by metadata class");
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
    foreach my $field (qw/subject parameters key/) {
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
    foreach my $field (qw/subject parameters key/) {
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
   returns XML string  representation of the  metadata object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the metadata namespace

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
    foreach my $field (qw/subject parameters key/) {
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
   returns metadata  object

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
        if ($tagname eq  'subject' && $nsid eq 'pinger' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Subject : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->subject($element); ### add another subject  
        }  elsif ($tagname eq  'subject' && $nsid eq 'select' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Subject->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Subject : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->subject($element); ### add another subject  
        }  elsif ($tagname eq  'parameters' && $nsid eq 'select' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Parameters : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->parameters($element); ### add another parameters  
        }  elsif ($tagname eq  'parameters' && $nsid eq 'pinger' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Parameters : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->parameters($element); ### add another parameters  
        }  elsif ($tagname eq  'key' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Key : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->key($element); ### add another key  
        }  elsif ($childnode->textContent && $self->can("$tagname")) { 
           $self->{$tagname} =  $childnode->textContent; ## text node 
        }       ###  $dom->removeChild($childnode); ##remove processed element from the current DOM so subclass can deal with remaining elements
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
 
