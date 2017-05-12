package  perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface  - A base class, implements  'interface'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the interface element.
   Object fields are:
    Scalar:     id, 
    Scalar:     interfaceIdRef, 
    Object reference:   ipAddress => type HASH,
    Object reference:   netmask => type ,
    Object reference:   ifName => type ,
    Object reference:   ifDescription => type ,
    Object reference:   ifAddress => type HASH,
    Object reference:   ifHostName => type ,
    Object reference:   ifIndex => type ,
    Object reference:   type => type ,
    Object reference:   capacity => type ,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'interface' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IfAddress;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap id interfaceIdRef ipAddress ifAddress netmask ifName ifDescription ifHostName ifIndex type capacity  text );

perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         id   => undef, 
         interfaceIdRef   => undef, 
         ipAddress => HASH,
         ifAddress => HASH,
text => 'text'

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface';
Readonly::Scalar our $LOCALNAME => 'interface';
            
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( $CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( $LOCALNAME, 'nmtl3');
    
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
       return interface object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $interface = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['id' =>  $self->id],
                                               ['interfaceIdRef' =>  $self->interfaceIdRef],
                                           ],
                                      'text' => (!($self->ipAddress)?$self->text:undef),
                         }); 
   if($self->ipAddress  && blessed $self->ipAddress  && $self->ipAddress->can("getDOM")) {
        my  $ipAddressDOM = $self->ipAddress->getDOM($interface);
       $ipAddressDOM?$interface->appendChild($ipAddressDOM):$logger->error("Failed to append  ipAddress  with value: " .  $ipAddressDOM->toString ); 
   }
   if($self->ifAddress  && blessed $self->ifAddress  && $self->ifAddress->can("getDOM")) {
        my  $ifAddressDOM = $self->ifAddress->getDOM($interface);
       $ifAddressDOM?$interface->appendChild($ifAddressDOM):$logger->error("Failed to append  ifAddress  with value: " .  $ifAddressDOM->toString ); 
   }
   foreach my $textnode (qw/netmask ifName ifDescription ifHostName ifIndex type capacity /) {
       if($self->{$textnode}) { 
            my  $domtext  =  getElement({name =>   $textnode, parent => $interface , ns => [$self->nsmap->mapname($LOCALNAME)],
                                          text => $self->{$textnode},
                                 });
            $domtext?$interface->appendChild($domtext):$logger->error("Failed to append new text element $textnode  to  interface   ");
        } 
   } 
    return $interface;
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
     
    my %defined_table = (  'metaData' => [  'transport',   'ip_name_src',   'ip_name_dst',  ],   'host' => [  'ip_name',   'ip_number',  ],  );
    $query->{metaData}{transport}= [    'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress',    ];
    $query->{host}{ip_number}= [    'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress',    ];
    $query->{metaData}{ip_name_src}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface' ] if!(defined $query->{metaData}{ip_name_src}) || ref($query->{metaData}{ip_name_src});
    $query->{metaData}{ip_name_dst}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface' ] if!(defined $query->{metaData}{ip_name_dst}) || ref($query->{metaData}{ip_name_dst});
    $query->{host}{ip_name}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface' ] if!(defined $query->{host}{ip_name}) || ref($query->{host}{ip_name});
    foreach my $subname (qw/ipAddress ifAddress/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering interface  for subclass $subname");
            } else {
                $logger->error(" Failed for interface Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    eval { 
        foreach my $table  ( keys %defined_table) {  
            foreach my $entry (@{$defined_table{$table}}) {  
                if(ref($query->{$table}{$entry}) eq 'ARRAY') {
                    foreach my $classes (@{$query->{$table}{$entry}}) {  
                        if($classes && $classes eq 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface' ) { 
                         }
                     }
                 }
             }
        }
    }; 
    if ($EVAL_ERROR) { $logger->logcroak(" SQL query building is failed  here " . $EVAL_ERROR)};
    return $query;
}

=head2 merge

      merge with another interface ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_interface = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_interface && blessed $new_interface && $new_interface->can("getDOM")) {
        $logger->error(" Please supply defined object of interface  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_interface->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_interface->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  interface  is not supported by interface class");
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
    foreach my $field (qw/ipAddress ifAddress/) {
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
    foreach my $field (qw/ipAddress ifAddress/) {
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
   returns XML string  representation of the  interface object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the interface namespace

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
    foreach my $field (qw/ipAddress ifAddress/) {
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
   returns interface  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 
    $self->interfaceIdRef($dom->getAttribute('interfaceIdRef')) if($dom->getAttribute('interfaceIdRef'));
    $logger->debug(" Attribute interfaceIdRef= ". $self->interfaceIdRef) if $self->interfaceIdRef; 
    $self->text($dom->textContent) if(!($self->ipAddress) && $dom->textContent);
    foreach my $childnode ($dom->childNodes) { 
        my  $getname  = $childnode->getName;
        my ($nsid, $tagname) = split $COLUMN_SEPARATOR,  $getname; 
        unless($nsid && $tagname) {   
            next;
        }
        if ($tagname eq  'ipAddress' && $nsid eq 'nmtl3' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  IpAddress : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->ipAddress($element); ### add another ipAddress  
        }  elsif ($tagname eq  'ifAddress' && $nsid eq 'nmtl3' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IfAddress->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  IfAddress : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->ifAddress($element); ### add another ifAddress  
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
 
