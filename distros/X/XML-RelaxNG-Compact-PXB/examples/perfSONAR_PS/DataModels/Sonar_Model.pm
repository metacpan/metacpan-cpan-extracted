package  perfSONAR_PS::DataModels::Sonar_Model;
 
=head1 NAME

  perfSONAR_PS::DataModels::Sonar_Model - perfSONAR schemas expressed in perl,
                                          used to build binding perl objects collection
 
=head1 DESCRIPTION

  'sonar' extension  of the perfSONAR_PS RelaxNG Compact schema for  the perfSONAR services metadata ( perfsonar NS) 
   see: http://anonsvn.internet2.edu/svn/nmwg/trunk/nmwg/schema/rnc/sonar.rnc
   
   
=head1 SYNOPSIS

      ###  
      use   perfSONAR_PS::DataModels::Sonar_Model qw($message);

    
       
      ####
      
      ### thats it, next step is to build API
       
 
=head1 Exported Variables
 
  $message

=cut
 
use strict;
use warnings;
use version; our $VERSION  = '2.0';

use Exporter ();
use base 'Exporter';
our @EXPORT     = qw();   
our @EXPORT_OK  = qw($message);
use  perfSONAR_PS::DataModels::Base_Model  2.0 qw($endPointPair $interfaceL3    $endPointL4   $service_parameter
                                                 $service_subject $parameter $service_parameters $metadata $data 
                                                 $message   $service_datum $event_datum    $endPointPairL4);  

 

our ($service_element); 
  
$service_datum->($event_datum); 
   
$service_parameters->({ attrs  => {id => 'scalar',   xmlns => 'psservice'},
    		        elements => [
    				      [parameter =>    $service_parameter->()],		   
    			            ], 
    		     }); 
		     
$service_element = { attrs  => {id => 'scalar',   xmlns => 'psservice'},
    	             elements => [
    			           [ serviceName   =>  'text'],
			           [ accessPoint   =>  'text'],
			           [ serviceType   =>  'text'],
			           [ serviceDescription   =>  'text'],	 
    			], 
	   
	            };

$service_subject->({ attrs  => { id => 'scalar',   xmlns => 'psservice'}, 
		     elements => [   
    				  [service =>  $service_element], 	  
			         ],
    		     text => 'unless:service',	      
		});

foreach my $subj (qw/xpath sql xquery/) {
    $service_subject->({ attrs  => {id => 'scalar', xmlns => $subj},
			 elements => [],
    			 text => 'scalar',	      
    		       });
    $service_parameters->({ attrs  => {id => 'scalar', xmlns => $subj },
			    elements => [
    					  [parameter =>  [$parameter]],				
    				        ],			   
    			 });    		       
}
   
    	  
$service_subject->({ attrs    => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'perfsonar'},
		     elements => [
    				   [interface =>   $interfaceL3], 
    				   [endPointPair =>    [$endPointPair ,  $endPointPairL4], 'unless:interface'],
    				   [service => $service_element],    				 				     
    			         ], 
    	          });  


1;
 
  
