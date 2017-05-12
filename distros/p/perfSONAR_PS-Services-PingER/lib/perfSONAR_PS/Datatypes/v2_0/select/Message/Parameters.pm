package  perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters;
{
##use lib qw(/home/netadmin/LHCOPN/perfSONAR-PS/branches/pinger/perfSONAR-PS-PingER-1.0/lib/perfSONAR_PS);
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters  - A base class, implements  'parameters'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the parameters element.
   Object fields are:
    Scalar:     id, 
    Object reference:   parameter => type ARRAY,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'parameters' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters;
	      
	      my $el =  perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters->new($DOM_Obj);
 
=head1   METHODS

=cut
 
use strict;
use warnings;
use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Parameters::Parameter;
use Class::Accessor;
use Class::Fields;
use base qw(Class::Accessor Class::Fields);
use fields qw(nsmap idmap refidmap id parameter  );

perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters->mk_accessors(perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         id   => undef, 
         parameter => ARRAY,

=cut

use constant  CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters';
use constant  LOCALNAME => 'parameters';
 	       
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( LOCALNAME, 'select');
    
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
    return $self;
}

#
#  no shortcuts !
#
sub AUTOLOAD {}  

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY  if $self->can("SUPER::DESTROY");
}
 
=head2   getDOM ($) 
      
       accept parent DOM
       return parameters object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( CLASSPATH ); 
    my $parameters = getElement({name =>   LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( LOCALNAME )],
                             attributes => [

                                               ['id' =>  $self->id],
                                           ],
        	             }); 
    if($self->parameter && ref($self->parameter) eq 'ARRAY' ) {
        foreach my $subel (@{$self->parameter}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($parameters);
                $subDOM?$parameters->appendChild($subDOM):$logger->error("Failed to append  parameter elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
    return $parameters;
}
  
=head2  addparameter()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addParameter {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( CLASSPATH ); 
   
    $self->parameter && ref($self->parameter) eq 'ARRAY'?push @{$self->parameter}, $new:$self->parameter([$new]); 
    $logger->debug("Added new to parameter"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->parameter;
}

=head2  removeParameterById()

     remove specific element from the array of parameter elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     
=cut

sub removeParameterById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( CLASSPATH ); 
    if(ref($self->parameter) eq 'ARRAY' && $self->idmap->{parameter} ) { 
        $self->parameter->[$self->idmap->{parameter}{$id}] = undef; 
	my @tmp =  grep { defined $_ } @{$self->parameter};  
	$self->parameter([@tmp]);
	$self->buildRefIdMap; ## rebuild ref index map  
	$self->buildIdMap; ## rebuild index map 
	
    } elsif(!ref($self->parameter)  || ref($self->parameter) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because parameter not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id"); 
        return undef;
    } 
}   
=head2  getParameterByMetadataIdRef()

     get specific object from the array of parameter elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getParameterByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( CLASSPATH ); 
    if(ref($self->parameter) eq 'ARRAY' && $self->refidmap->{parameter}) {
        my $parameter = $self->parameter->[$self->refidmap->{parameter}{$id}];
	return ($parameter->can("metadataIdRef") &&   $parameter->metadataIdRef eq  $id)?$parameter:undef; 
    } elsif($self->parameter && (!ref($self->parameter) || 
                                    (ref($self->parameter) ne 'ARRAY' &&
	                                 blessed $self->parameter && $self->parameter->can("metadataIdRef") &&
					 $self->parameter->metadataIdRef eq  $id)))  {
        return $self->parameter;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getParameterById()

     get specific element from the array of parameter elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getParameterById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( CLASSPATH ); 
    if(ref($self->parameter) eq 'ARRAY') {
        return $self->parameter->[$self->idmap->{parameter}{$id}];
    } elsif(!ref($self->parameter) || ref($self->parameter) ne 'ARRAY')  {
        return $self->parameter;
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
    my $logger  = get_logger( CLASSPATH );
     
  foreach my $subname (qw/parameter/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
          my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
	  foreach my $el  (@array) {
	     if(blessed  $el  &&  $el->can("querySQL"))  {
		  $el->querySQL($query);		 
		   $logger->debug("Quering parameters  for subclass $subname");
	     } else {
	        $logger->error(" Failed for parameters Unblessed member or querySQL is not implemented by subclass $subname");
	     }
	  }  
       }
    }	
    return $query;
}

=head2 merge

      merge with another parameters ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_parameters = shift;
    my $logger  = get_logger( CLASSPATH );  
    unless($new_parameters && blessed $new_parameters && $new_parameters->can("getDOM")) {
        $logger->error(" Please supply defined object of parameters  ");
        return undef;
    } 
    foreach my $member ($new_parameters->show_fields) {
        if($self->can($member)) {
	     my $mergeList = $self->{$member};
	     $mergeList = [ $self->{$member} ]  unless(ref($mergeList) eq 'ARRAY');
	     foreach my $mem (@{ $mergeList }) {
	         if(blessed $mem && $mem->can("merge")) {
	             $mem->merge($new_parameters->{$member}); ## recursively merge it
                 } else {
                     $mem = $new_parameters->{$member};
	         }
	     }
	} else {
	    $logger->error(" This field $member,  found in supplied  metadata is not supported by MetaData class");
	    return undef;
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
    my %map = (); 
    my $logger  = get_logger( CLASSPATH );
    foreach my $field (qw/parameter/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        my $i = 0;
        foreach my $el ( @array)  {
            if($el && blessed $el && $el->can("id") &&  $el->id)  { 
                $map{$field}{$el->id} = $i;   
            }
            $i++;
        }
    }
    return $self->idmap(\%map);
}
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my $self = shift;
    my %map = (); 
    my $logger  = get_logger( CLASSPATH );
    foreach my $field (qw/parameter/) {
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
   returns XML string  representation of the  parameters object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString();
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the parameters namespace

=cut

sub registerNamespaces {
    my $self = shift;
    my $logger  = get_logger( CLASSPATH );
    my $nsids = shift;
    my $local_nss = {reverse %{$self->nsmap->mapname}};
    unless($nsids) {
        $nsids =  $local_nss;
    }  else {
        %{$nsids} = ( %{$local_nss},  %{$nsids});
    }
    foreach my $field (qw/parameter/) {
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
   returns parameters  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( CLASSPATH ); 
    my $dom = shift;
     
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 
    foreach my $childnode ($dom->childNodes) { 
        my  $getname  = $childnode->getName;
        my ($nsid, $tagname) = split ':',  $getname ; 
        unless($nsid && $tagname) {   
            next;
        }
        if ($tagname eq  'parameter' && $nsid eq 'nmwg' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Parameters::Parameter->new($childnode) 
           };
           unless(!$@ && $element  && blessed $element) {
               $logger->error(" Failed to load and add  Parameter : " . $dom->toString . " error: " . $@);
               return undef;
           }
           ($self->parameter && ref($self->parameter) eq 'ARRAY')?push @{$self->parameter}, $element:$self->parameter([$element]);; ### add another parameter  
        }      ###  $dom->removeChild($childnode); ##remove processed element from the current DOM so subclass can deal with remaining elements
    }
  $self->buildIdMap;
 $self->buildRefIdMap;
 $self->registerNamespaces;
  
 return $self;
}

1; 
}

__END__

=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007, maxim@fnal.gov

=cut 
 
