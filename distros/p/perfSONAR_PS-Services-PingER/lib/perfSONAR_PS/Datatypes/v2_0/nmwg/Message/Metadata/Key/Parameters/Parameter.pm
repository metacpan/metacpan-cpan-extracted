package  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter  - A base class, implements  'parameter'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the parameter element.
   Object fields are:
    Scalar:     value, 
    Scalar:     name, 
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'parameter' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter->new($DOM_Obj);
 
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
use fields qw(nsmap idmap refidmap value name    text );

perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter->mk_accessors(perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         value   => undef, 
         name   => undef, 
text => 'text'

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter';
Readonly::Scalar our $LOCALNAME => 'parameter';
            
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
       return parameter object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $parameter = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['value' =>  $self->value],
                                     ['name' =>  (($self->name    =~ m/(count|packetInterval|packetSize|ttl|valueUnits|startTime|endTime|protocol|transport|setLimit)$/)?$self->name:undef)],
                                           ],
                                      'text' => (!($self->value)?$self->text:undef),
                         }); 
    return $parameter;
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
     
    my %defined_table = (  'time' => [  'end',   'start',  ],   'metaData' => [  'protocol',   'transport',   'count',   'packetSize',   'ttl',   'packetInterval',  ],   'limit' => [  'setLimit',  ],  );
    $query->{metaData}{protocol}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{protocol}) || ref($query->{metaData}{protocol});
    $query->{metaData}{count}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{count}) || ref($query->{metaData}{count});
    $query->{metaData}{transport}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{transport}) || ref($query->{metaData}{transport});
    $query->{metaData}{packetSize}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{packetSize}) || ref($query->{metaData}{packetSize});
    $query->{metaData}{ttl}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{ttl}) || ref($query->{metaData}{ttl});
    $query->{metaData}{packetInterval}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{packetInterval}) || ref($query->{metaData}{packetInterval});
    $query->{time}{start}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{time}{start}) || ref($query->{time}{start});
    $query->{time}{end}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{time}{end}) || ref($query->{time}{end});
    $query->{limit}{setLimit}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{limit}{setLimit}) || ref($query->{limit}{setLimit});
    $query->{metaData}{protocol}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{protocol}) || ref($query->{metaData}{protocol});
    $query->{metaData}{count}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{count}) || ref($query->{metaData}{count});
    $query->{metaData}{transport}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{transport}) || ref($query->{metaData}{transport});
    $query->{metaData}{packetSize}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{packetSize}) || ref($query->{metaData}{packetSize});
    $query->{metaData}{ttl}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{ttl}) || ref($query->{metaData}{ttl});
    $query->{metaData}{packetInterval}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{metaData}{packetInterval}) || ref($query->{metaData}{packetInterval});
    $query->{time}{start}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{time}{start}) || ref($query->{time}{start});
    $query->{time}{end}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{time}{end}) || ref($query->{time}{end});
    $query->{limit}{setLimit}= [ 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ] if!(defined $query->{limit}{setLimit}) || ref($query->{limit}{setLimit});
    eval { 
        foreach my $table  ( keys %defined_table) {  
            foreach my $entry (@{$defined_table{$table}}) {  
                if(ref($query->{$table}{$entry}) eq 'ARRAY') {
                    foreach my $classes (@{$query->{$table}{$entry}}) {  
                        if($classes && $classes eq 'perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key::Parameters::Parameter' ) { 
                            if    ($self->value && ( (  ( ($self->name eq 'protocol')  && $entry eq 'protocol') or  ( ($self->name eq 'count')  && $entry eq 'count') or  ( ($self->name eq 'transport')  && $entry eq 'transport') or  ( ($self->name eq 'packetSize')  && $entry eq 'packetSize') or  ( ($self->name eq 'ttl')  && $entry eq 'ttl') or  ( ($self->name eq 'packetInterval')  && $entry eq 'packetInterval')) || (  ( ($self->name eq 'startTime')  && $entry eq 'start') or  ( ($self->name eq 'endTime')  && $entry eq 'end')) || (  ( ($self->name eq 'setLimit')  && $entry eq 'setLimit')) )) {
                                $query->{$table}{$entry} =  $self->value;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->value);
                                last;  
                            }
                            elsif ($self->text && ( (  ( ($self->name eq 'protocol')  && $entry eq 'protocol') or  ( ($self->name eq 'count')  && $entry eq 'count') or  ( ($self->name eq 'transport')  && $entry eq 'transport') or  ( ($self->name eq 'packetSize')  && $entry eq 'packetSize') or  ( ($self->name eq 'ttl')  && $entry eq 'ttl') or  ( ($self->name eq 'packetInterval')  && $entry eq 'packetInterval')) || (  ( ($self->name eq 'startTime')  && $entry eq 'start') or  ( ($self->name eq 'endTime')  && $entry eq 'end')) || (  ( ($self->name eq 'setLimit')  && $entry eq 'setLimit')) )) {
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

      merge with another parameter ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_parameter = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_parameter && blessed $new_parameter && $new_parameter->can("getDOM")) {
        $logger->error(" Please supply defined object of parameter  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_parameter->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_parameter->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  parameter  is not supported by parameter class");
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
   returns XML string  representation of the  parameter object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the parameter namespace

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
   returns parameter  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->value($dom->getAttribute('value')) if($dom->getAttribute('value'));
    $logger->debug(" Attribute value= ". $self->value) if $self->value; 
    $self->name($dom->getAttribute('name')) if($dom->getAttribute('name') && ($dom->getAttribute('name')   =~ m/(count|packetInterval|packetSize|ttl|valueUnits|startTime|endTime|protocol|transport|setLimit)$/));
    $logger->debug(" Attribute name= ". $self->name) if $self->name; 
    $self->text($dom->textContent) if(!($self->value) && $dom->textContent);

 return $self;
}

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim@fnal.gov

=cut 

1;
 
