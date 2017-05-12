package  perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = 0.09;
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress  - A base class, implements  'ipAddress'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the ipAddress element.
   Object fields are:
    Scalar:     value, 
    Scalar:     type, 
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'ipAddress' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap value type    text );

perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         value   => undef, 
         type   => undef, 
text => 'text'

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress';
Readonly::Scalar our $LOCALNAME => 'ipAddress';
            
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
       return ipAddress object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $ipAddress = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['value' =>  $self->value],
                                               ['type' =>  $self->type],
                                           ],
                                      'text' => (!($self->value)?$self->text:undef),
                         }); 
    return $ipAddress;
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
     
    my %defined_table = (  'metaData' => [  'transport',  ],   'host' => [  'ip_number',  ],  );
    $query->{host}{ip_number}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress' ] if!(defined $query->{host}{ip_number}) || ref($query->{host}{ip_number});
    $query->{host}{ip_number}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress' ] if!(defined $query->{host}{ip_number}) || ref($query->{host}{ip_number});
    $query->{metaData}{transport}= [ 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress' ] if!(defined $query->{metaData}{transport}) || ref($query->{metaData}{transport});
    eval { 
        foreach my $table  ( keys %defined_table) {  
            foreach my $entry (@{$defined_table{$table}}) {  
                if(ref($query->{$table}{$entry}) eq 'ARRAY') {
                    foreach my $classes (@{$query->{$table}{$entry}}) {  
                        if($classes && $classes eq 'perfSONAR_PS::Datatypes::v2_0::nmtl3::Topology::Domain::Node::Port::IpAddress' ) { 
                            if    ($self->value && ( (  ($entry eq 'ip_number')) )) {
                                $query->{$table}{$entry} =  $self->value;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->value);
                                last;  
                            }
                            elsif ($self->type && ( (  ($entry eq 'transport')) )) {
                                $query->{$table}{$entry} =  $self->type;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->type);
                                last;  
                            }
                            elsif ($self->text && ( (  ($entry eq 'ip_number')) )) {
                                $query->{$table}{$entry} =  $self->text;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->text);
                                last;  
                            }
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

      merge with another ipAddress ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_ipAddress = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_ipAddress && blessed $new_ipAddress && $new_ipAddress->can("getDOM")) {
        $logger->error(" Please supply defined object of ipAddress  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_ipAddress->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_ipAddress->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  ipAddress  is not supported by ipAddress class");
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
    return;
}
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my $self = shift;
    my %map = (); 
    my $logger  = get_logger( $CLASSPATH );
    return;
}
=head2  asString()

   shortcut to get DOM and convert into the XML string
   returns XML string  representation of the  ipAddress object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the ipAddress namespace

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
    return     $nsids;
}
=head2  fromDOM ($)
   
   accepts parent XML DOM   element   tree as parameter 
   returns ipAddress  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->value($dom->getAttribute('value')) if($dom->getAttribute('value'));
    $logger->debug(" Attribute value= ". $self->value) if $self->value; 
    $self->type($dom->getAttribute('type')) if($dom->getAttribute('type'));
    $logger->debug(" Attribute type= ". $self->type) if $self->type; 
    $self->text($dom->textContent) if(!($self->value) && $dom->textContent);

 return $self;
}

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim@fnal.gov

=cut 

1;
 
