package  perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = 0.09;
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node  - A base class, implements  'node'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the node element.
   Object fields are:
    Scalar:     metadataIdRef, 
    Scalar:     id, 
    Object reference:   name => type HASH,
    Object reference:   hostName => type HASH,
    Object reference:   description => type HASH,
    Object reference:   location => type HASH,
    Object reference:   contact => type HASH,
    Object reference:   parameters => type HASH,
    Object reference:   port => type HASH,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'node' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Name;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::HostName;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Description;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Location;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Contact;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Topology::Domain::Node::Parameters;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap metadataIdRef id name hostName description location contact parameters port  );

perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node->mk_accessors(perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         metadataIdRef   => undef, 
         id   => undef, 
         name => HASH,
         hostName => HASH,
         description => HASH,
         location => HASH,
         contact => HASH,
         parameters => HASH,
         port => HASH,

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node';
Readonly::Scalar our $LOCALNAME => 'node';
            
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( $CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( $LOCALNAME, 'pingertopo');
    
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
       return node object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $node = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['metadataIdRef' =>  $self->metadataIdRef],
                                               ['id' =>  $self->id],
                                           ],
                         }); 
   if($self->name  && blessed $self->name  && $self->name->can("getDOM")) {
        my  $nameDOM = $self->name->getDOM($node);
       $nameDOM?$node->appendChild($nameDOM):$logger->error("Failed to append  name  with value: " .  $nameDOM->toString ); 
   }
   if($self->hostName  && blessed $self->hostName  && $self->hostName->can("getDOM")) {
        my  $hostNameDOM = $self->hostName->getDOM($node);
       $hostNameDOM?$node->appendChild($hostNameDOM):$logger->error("Failed to append  hostName  with value: " .  $hostNameDOM->toString ); 
   }
   if($self->description  && blessed $self->description  && $self->description->can("getDOM")) {
        my  $descriptionDOM = $self->description->getDOM($node);
       $descriptionDOM?$node->appendChild($descriptionDOM):$logger->error("Failed to append  description  with value: " .  $descriptionDOM->toString ); 
   }
   if($self->location  && blessed $self->location  && $self->location->can("getDOM")) {
        my  $locationDOM = $self->location->getDOM($node);
       $locationDOM?$node->appendChild($locationDOM):$logger->error("Failed to append  location  with value: " .  $locationDOM->toString ); 
   }
   if($self->contact  && blessed $self->contact  && $self->contact->can("getDOM")) {
        my  $contactDOM = $self->contact->getDOM($node);
       $contactDOM?$node->appendChild($contactDOM):$logger->error("Failed to append  contact  with value: " .  $contactDOM->toString ); 
   }
   if($self->parameters  && blessed $self->parameters  && $self->parameters->can("getDOM")) {
        my  $parametersDOM = $self->parameters->getDOM($node);
       $parametersDOM?$node->appendChild($parametersDOM):$logger->error("Failed to append  parameters  with value: " .  $parametersDOM->toString ); 
   }
   if($self->port  && blessed $self->port  && $self->port->can("getDOM")) {
        my  $portDOM = $self->port->getDOM($node);
       $portDOM?$node->appendChild($portDOM):$logger->error("Failed to append  port  with value: " .  $portDOM->toString ); 
   }
    return $node;
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
     
    foreach my $subname (qw/name hostName description location contact parameters port/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering node  for subclass $subname");
            } else {
                $logger->error(" Failed for node Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    return $query;
}

=head2 merge

      merge with another node ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_node = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_node && blessed $new_node && $new_node->can("getDOM")) {
        $logger->error(" Please supply defined object of node  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_node->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_node->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  node  is not supported by node class");
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
    foreach my $field (qw/name hostName description location contact parameters port/) {
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
    foreach my $field (qw/name hostName description location contact parameters port/) {
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
   returns XML string  representation of the  node object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the node namespace

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
    foreach my $field (qw/name hostName description location contact parameters port/) {
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
   returns node  object

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
        if ($tagname eq  'name' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Name->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Name : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->name($element); ### add another name  
        }  elsif ($tagname eq  'hostName' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::HostName->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  HostName : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->hostName($element); ### add another hostName  
        }  elsif ($tagname eq  'description' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Description->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Description : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->description($element); ### add another description  
        }  elsif ($tagname eq  'location' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Location->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Location : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->location($element); ### add another location  
        }  elsif ($tagname eq  'contact' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Node::Contact->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Contact : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->contact($element); ### add another contact  
        }  elsif ($tagname eq  'parameters' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Topology::Domain::Node::Parameters->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Parameters : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->parameters($element); ### add another parameters  
        }  elsif ($tagname eq  'port' && $nsid eq 'nmtl3' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Port : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->port($element); ### add another port  
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
 
