package  perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = qv('v2.0');
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum  - A base class, implements  'datum'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the datum element.
   Object fields are:
    Scalar:     timeType, 
    Scalar:     ttl, 
    Scalar:     numBytes, 
    Scalar:     value, 
    Scalar:     name, 
    Scalar:     valueUnits, 
    Scalar:     timeValue, 
    Scalar:     seqNum, 
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'datum' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new($DOM_Obj);
 
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
use fields qw(nsmap idmap refidmap timeType ttl numBytes value name valueUnits timeValue seqNum   );

perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->mk_accessors(perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         timeType   => undef, 
         ttl   => undef, 
         numBytes   => undef, 
         value   => undef, 
         name   => undef, 
         valueUnits   => undef, 
         timeValue   => undef, 
         seqNum   => undef, 

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum';
Readonly::Scalar our $LOCALNAME => 'datum';
            
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( $CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( $LOCALNAME, 'pinger');
    
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
       return datum object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $datum = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['timeType' =>  $self->timeType],
                                               ['ttl' =>  $self->ttl],
                                               ['numBytes' =>  $self->numBytes],
                                               ['value' =>  $self->value],
                                     ['name' =>  (($self->name    =~ m/(minRtt|maxRtt|meanRtt|medianRtt|lossPercent|clp|minIpd|maxIpd|iqrIpd|meanIpd|duplicates|outOfOrder)$/)?$self->name:undef)],
                                               ['valueUnits' =>  $self->valueUnits],
                                               ['timeValue' =>  $self->timeValue],
                                               ['seqNum' =>  $self->seqNum],
                                           ],
                         }); 
    return $datum;
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
     
    my %defined_table = (  'data' => [  'minRtt',   'ttl',   'numBytes',   'outOfOrder',   'maxRtt',   'rtts',   'clp',   'medianRtt',   'meanRtt',   'duplicates',   'maxIpd',   'meanIpd',   'minIpd',   'seqNums',   'lossPercent',   'iqrIpd',  ],  );
    $query->{data}{numBytes}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{numBytes}) || ref($query->{data}{numBytes});
    $query->{data}{ttl}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{ttl}) || ref($query->{data}{ttl});
    $query->{data}{minRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{minRtt}) || ref($query->{data}{minRtt});
    $query->{data}{maxRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{maxRtt}) || ref($query->{data}{maxRtt});
    $query->{data}{outOfOrder}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{outOfOrder}) || ref($query->{data}{outOfOrder});
    $query->{data}{medianRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{medianRtt}) || ref($query->{data}{medianRtt});
    $query->{data}{clp}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{clp}) || ref($query->{data}{clp});
    $query->{data}{meanRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{meanRtt}) || ref($query->{data}{meanRtt});
    $query->{data}{duplicates}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{duplicates}) || ref($query->{data}{duplicates});
    $query->{data}{maxIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{maxIpd}) || ref($query->{data}{maxIpd});
    $query->{data}{minIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{minIpd}) || ref($query->{data}{minIpd});
    $query->{data}{meanIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{meanIpd}) || ref($query->{data}{meanIpd});
    $query->{data}{iqrIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{iqrIpd}) || ref($query->{data}{iqrIpd});
    $query->{data}{lossPercent}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{lossPercent}) || ref($query->{data}{lossPercent});
    $query->{data}{minRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{minRtt}) || ref($query->{data}{minRtt});
    $query->{data}{maxRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{maxRtt}) || ref($query->{data}{maxRtt});
    $query->{data}{outOfOrder}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{outOfOrder}) || ref($query->{data}{outOfOrder});
    $query->{data}{rtts}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{rtts}) || ref($query->{data}{rtts});
    $query->{data}{medianRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{medianRtt}) || ref($query->{data}{medianRtt});
    $query->{data}{clp}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{clp}) || ref($query->{data}{clp});
    $query->{data}{meanRtt}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{meanRtt}) || ref($query->{data}{meanRtt});
    $query->{data}{maxIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{maxIpd}) || ref($query->{data}{maxIpd});
    $query->{data}{duplicates}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{duplicates}) || ref($query->{data}{duplicates});
    $query->{data}{minIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{minIpd}) || ref($query->{data}{minIpd});
    $query->{data}{meanIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{meanIpd}) || ref($query->{data}{meanIpd});
    $query->{data}{iqrIpd}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{iqrIpd}) || ref($query->{data}{iqrIpd});
    $query->{data}{lossPercent}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{lossPercent}) || ref($query->{data}{lossPercent});
    $query->{data}{seqNums}= [ 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ] if!(defined $query->{data}{seqNums}) || ref($query->{data}{seqNums});
    eval { 
        foreach my $table  ( keys %defined_table) {  
            foreach my $entry (@{$defined_table{$table}}) {  
                if(ref($query->{$table}{$entry}) eq 'ARRAY') {
                    foreach my $classes (@{$query->{$table}{$entry}}) {  
                        if($classes && $classes eq 'perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum' ) { 
                            if    ($self->ttl && ( (  ($entry eq 'ttl')) )) {
                                $query->{$table}{$entry} =  $self->ttl;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->ttl);
                                last;  
                            }
                            elsif ($self->numBytes && ( (  ($entry eq 'numBytes')) )) {
                                $query->{$table}{$entry} =  $self->numBytes;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->numBytes);
                                last;  
                            }
                            elsif ($self->value && ( (  ( ($self->name eq 'minRtt')  && $entry eq 'minRtt') or  ( ($self->name eq 'maxRtt')  && $entry eq 'maxRtt') or  ( ($self->name eq 'outOfOrder')  && $entry eq 'outOfOrder') or  ($entry eq 'rtts') or  ( ($self->name eq 'medianRtt')  && $entry eq 'medianRtt') or  ( ($self->name eq 'clp')  && $entry eq 'clp') or  ( ($self->name eq 'meanRtt')  && $entry eq 'meanRtt') or  ( ($self->name eq 'maxIpd')  && $entry eq 'maxIpd') or  ( ($self->name eq 'duplicates')  && $entry eq 'duplicates') or  ( ($self->name eq 'minIpd')  && $entry eq 'minIpd') or  ( ($self->name eq 'meanIpd')  && $entry eq 'meanIpd') or  ( ($self->name eq 'iqrIpd')  && $entry eq 'iqrIpd') or  ( ($self->name eq 'lossPercent')  && $entry eq 'lossPercent')) )) {
                                $query->{$table}{$entry} =  $self->value;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->value);
                                last;  
                            }
                            elsif ($self->seqNum && ( (  ($entry eq 'seqNums')) )) {
                                $query->{$table}{$entry} =  $self->seqNum;
                                $logger->debug(" Got value for SQL query $table.$entry: " . $self->seqNum);
                                last;  
                            }
                            elsif ($self->text && ( (  ( ($self->name eq 'minRtt')  && $entry eq 'minRtt') or  ( ($self->name eq 'maxRtt')  && $entry eq 'maxRtt') or  ( ($self->name eq 'outOfOrder')  && $entry eq 'outOfOrder') or  ( ($self->name eq 'medianRtt')  && $entry eq 'medianRtt') or  ( ($self->name eq 'clp')  && $entry eq 'clp') or  ( ($self->name eq 'meanRtt')  && $entry eq 'meanRtt') or  ( ($self->name eq 'duplicates')  && $entry eq 'duplicates') or  ( ($self->name eq 'maxIpd')  && $entry eq 'maxIpd') or  ( ($self->name eq 'minIpd')  && $entry eq 'minIpd') or  ( ($self->name eq 'meanIpd')  && $entry eq 'meanIpd') or  ( ($self->name eq 'iqrIpd')  && $entry eq 'iqrIpd') or  ( ($self->name eq 'lossPercent')  && $entry eq 'lossPercent')) )) {
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

      merge with another datum ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_datum = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_datum && blessed $new_datum && $new_datum->can("getDOM")) {
        $logger->error(" Please supply defined object of datum  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_datum->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_datum->{$member_name};
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
        $logger->error(" This field $member_name,  found in supplied  datum  is not supported by datum class");
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
   returns XML string  representation of the  datum object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the datum namespace

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
   returns datum  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->timeType($dom->getAttribute('timeType')) if($dom->getAttribute('timeType'));
    $logger->debug(" Attribute timeType= ". $self->timeType) if $self->timeType; 
    $self->ttl($dom->getAttribute('ttl')) if($dom->getAttribute('ttl'));
    $logger->debug(" Attribute ttl= ". $self->ttl) if $self->ttl; 
    $self->numBytes($dom->getAttribute('numBytes')) if($dom->getAttribute('numBytes'));
    $logger->debug(" Attribute numBytes= ". $self->numBytes) if $self->numBytes; 
    $self->value($dom->getAttribute('value')) if($dom->getAttribute('value'));
    $logger->debug(" Attribute value= ". $self->value) if $self->value; 
    $self->name($dom->getAttribute('name')) if($dom->getAttribute('name') && ($dom->getAttribute('name')   =~ m/(minRtt|maxRtt|meanRtt|medianRtt|lossPercent|clp|minIpd|maxIpd|iqrIpd|meanIpd|duplicates|outOfOrder)$/));
    $logger->debug(" Attribute name= ". $self->name) if $self->name; 
    $self->valueUnits($dom->getAttribute('valueUnits')) if($dom->getAttribute('valueUnits'));
    $logger->debug(" Attribute valueUnits= ". $self->valueUnits) if $self->valueUnits; 
    $self->timeValue($dom->getAttribute('timeValue')) if($dom->getAttribute('timeValue'));
    $logger->debug(" Attribute timeValue= ". $self->timeValue) if $self->timeValue; 
    $self->seqNum($dom->getAttribute('seqNum')) if($dom->getAttribute('seqNum'));
    $logger->debug(" Attribute seqNum= ". $self->seqNum) if $self->seqNum; 

 return $self;
}

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim@fnal.gov

=cut 

1;
 
