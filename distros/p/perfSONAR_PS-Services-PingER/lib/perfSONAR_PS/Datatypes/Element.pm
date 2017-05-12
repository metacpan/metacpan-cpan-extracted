package  perfSONAR_PS::Datatypes::Element;
use strict;
use warnings;
use version;our $VERSION = 0.09;
use base 'Exporter';
=head1 NAME

 perfSONAR_PS::Datatypes::Element -  static class for element manipulations

=head1 DESCRIPTION
   
      see each call description for details

=cut

our @EXPORT_OK   = qw(&getElement);

use Readonly;
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::Element';
use perfSONAR_PS::Datatypes::Namespace;
use XML::LibXML;
###use Log::Log4perl qw(get_logger);  ## to slow
use Data::Dumper;
 
=head2    getElement ()

    create   element from some data struct and return it as DOM
     accepts 1 parameter - hashref to named parameters
     where  'name' =>  name of the element
     'ns' => [ namespace id1, namespace id2 ...] array ref
     'parent' => parent DOM if provided ( element will be created in context of the parent),
     'attributes' =>  arrayhref to the array of attributes pairs 
    (where to get i-th attribute one has to  $attr->[i]->[0] for  name  and  $attr->[i]->[1]  for value) 
     and last one is 'text' => <CDATA>
    creates  new   element, returns this element
    
=cut 

sub  getElement {   
        my $param = shift;
	###my $logger  = get_logger( $CLASSPATH );
	my $data = undef;
	unless($param && ref($param) eq 'HASH' &&  $param->{name}) {
	   ###$logger->error(" Need single hashref parameter as { name => '',  parent => DOM_obj, attributes => [], text => ''}");
	   return;
	}
	my $name = $param->{name};    
	my $attrs =  $param->{attributes};
	my $text =  $param->{text};
 	my $nss =   $param->{ns};
	
	      
	if($param->{parent} && ref($param->{parent}) && $param->{parent}->isa('XML::LibXML::Document')) {
	    $data =  $param->{parent}->createElement($name);
	    ###$logger->debug(" Added new element to parent ::: " . $data->toString);
	} else {
	    $data =  XML::LibXML::Element->new($name);
	    ###$logger->debug(" Created new element ::: " . $data->toString);	
	}
	if($nss)  {
	    foreach my $ns (@{$nss}) { 
	       next unless $ns;
	       my $nsid =  perfSONAR_PS::Datatypes::Namespace::getNsByKey(  $ns  );
	       ###$logger->error(" Attempted to create element with unsupported namespace id: ". $ns ) unless $nsid && !ref($nsid);
	       $data->setNamespace(  $nsid ,   $ns, 1);  
	    }
	}### else {
	   ### $logger->error(" Attempted to create element without namespace ");
	   ### 
	###}
	if (($attrs &&  ref($attrs) eq 'ARRAY') || $text) {
	    if($attrs && ref($attrs) eq 'ARRAY') {
	       foreach my $attr  (@{$attrs}) {
		 if ($attr->[0] && $attr->[1] ) {
		    unless(ref($attr->[1]) )   {
		       $data->setAttribute($attr->[0], $attr->[1]); 
		    } ###else {
	               ###$logger->warn(" Attempted to create ".$attr->[0]." with this: ".$attr->[1]." dump:" . Dumper  $attr->[1]);
	            ###} 
	          }
	       }
	    }
	    if($text)  {
	       unless(ref($text)) {
	          my $text_el = XML::LibXML::Text->new( $text  );
		  $data->appendChild( $text_el );
	       } ###else {
	        ### $logger->warn(" Attempted to create text with this: $text dump:" . Dumper $text);
	       ###} 
	    }
	} ###else {
	    ###$logger->warn(" Attempted to create empty element with name $name, failed to do so, will return undef ");
	###}
	  
	return $data;       
}


=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007, maxim@fnal.gov

=cut

1;
