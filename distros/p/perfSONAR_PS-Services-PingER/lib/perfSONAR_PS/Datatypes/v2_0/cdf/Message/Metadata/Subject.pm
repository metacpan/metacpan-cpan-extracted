package  perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject;
{
##use lib qw(/home/netadmin/LHCOPN/perfSONAR-PS/branches/pinger/perfSONAR-PS-PingER-1.0/lib/perfSONAR_PS);
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject  - A base class, implements  'subject'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the subject element.
   Object fields are:
    Scalar:     metadataIdRef, 
    Scalar:     id, 
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'subject' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject;
	      
	      my $el =  perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject->new($DOM_Obj);
 
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
use Class::Accessor;
use Class::Fields;
use base qw(Class::Accessor Class::Fields);
use fields qw(nsmap idmap refidmap metadataIdRef id   );

perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject->mk_accessors(perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         metadataIdRef   => undef, 
         id   => undef, 

=cut

use constant  CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::cdf::Message::Metadata::Subject';
use constant  LOCALNAME => 'subject';
 	       
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( LOCALNAME, 'cdf');
    
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
       return subject object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( CLASSPATH ); 
    my $subject = getElement({name =>   LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( LOCALNAME )],
                             attributes => [

                                               ['metadataIdRef' =>  $self->metadataIdRef],
                                               ['id' =>  $self->id],
                                           ],
        	             }); 
    return $subject;
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
     
    return $query;
}

=head2 merge

      merge with another subject ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_subject = shift;
    my $logger  = get_logger( CLASSPATH );  
    unless($new_subject && blessed $new_subject && $new_subject->can("getDOM")) {
        $logger->error(" Please supply defined object of subject  ");
        return undef;
    } 
    foreach my $member ($new_subject->show_fields) {
        if($self->can($member)) {
	     my $mergeList = $self->{$member};
	     $mergeList = [ $self->{$member} ]  unless(ref($mergeList) eq 'ARRAY');
	     foreach my $mem (@{ $mergeList }) {
	         if(blessed $mem && $mem->can("merge")) {
	             $mem->merge($new_subject->{$member}); ## recursively merge it
                 } else {
                     $mem = $new_subject->{$member};
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
    return undef;
}
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my $self = shift;
    my %map = (); 
    my $logger  = get_logger( CLASSPATH );
    return undef;
}
=head2  asString()

   shortcut to get DOM and convert into the XML string
   returns XML string  representation of the  subject object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString();
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the subject namespace

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
    return     $nsids;
}
=head2  fromDOM ($)
   
   accepts parent XML DOM   element   tree as parameter 
   returns subject  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( CLASSPATH ); 
    my $dom = shift;
     
    $self->metadataIdRef($dom->getAttribute('metadataIdRef')) if($dom->getAttribute('metadataIdRef'));
    $logger->debug(" Attribute metadataIdRef= ". $self->metadataIdRef) if $self->metadataIdRef; 
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 

 return $self;
}

1; 
}

__END__

=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007, maxim@fnal.gov

=cut 
 
