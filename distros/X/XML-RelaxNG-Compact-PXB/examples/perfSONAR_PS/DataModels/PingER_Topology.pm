package  perfSONAR_PS::DataModels::PingER_Topology;
 
=head1 NAME

   perfSONAR_PS::DataModels::PingER_Topology - perfSONAR pinger topology schema  expressed in perl
 
=head1 DESCRIPTION

   
    'pingertopo' extension  of the perfSONAR_PS RelaxNG Compact schema for  the perfSONAR
    services metadata  
    see:  
    
    http://anonsvn.internet2.edu/svn/nmwg/trunk/nmwg/schema/rnc/pinger-landmarks.rnc
  
   
   
=head1 SYNOPSIS

      ###  
      use  perfSONAR_PS::DataModels::PingER_Topology qw($pingertopo);

       
      
    
       
=cut 

=head1 Exported Variables
 
     $pingertopo  $port   $node $domain

=cut



use strict;
use warnings;
use version;our $VERSION  = '2.0';

 
our @EXPORT    = qw( );   
our @EXPORT_OK = qw($pingertopo  $port   $node $domain);
 
our ($pingertopo, $port,$parameters, $parameter, $location, $contact ,$basename,  $node ,$domain , $textnode_nmtb);  

use   perfSONAR_PS::DataModels::Base_Model  2.0 qw($addressL3);
 
$port = { attrs  => {id => 'scalar', xmlns => 'nmtl3'},
          elements => [
        		[ ipAddress=>  $addressL3 ],       		   
        	      ], 
        }; 
            
$parameter  =  { attrs  => { name => 'enum:count,packetInterval,packetSize,ttl,measurementPeriod,measurementOffset',  
                             value => 'scalar', xmlns => 'nmwg'},
		 elements => [],
        	 text => 'unless:value',
               };  
	           
$parameters = { attrs  => {id => 'scalar', xmlns => 'nmwg'},
                elements => [
        		      [ parameter =>  [$parameter] ],			  
        		    ], 
              }; 
            
$basename =   { attrs  => {type => 'scalar', xmlns => 'nmtb'}, 
		elements => [], 
        	text => 'scalar',
              };
	      
$location =  { attrs => {xmlns => 'nmtb'},
	       elements => [
			     [continent => 'text'],
        		     [country => 'text'],
			     [zipcode   => 'text'],
			     [state	=> 'text'],
			     [institution   => 'text'],
			     [city   => 'text'],
			     [streetAddress  => 'text'],
			     [floor	=> 'text'],
			     [room   => 'text'],
			     [cage   => 'text'],
			     [rack  => 'text'], 
			     [shelf  => 'text'], 
			     [latitude => 'text'], 
			     [longitude   => 'text'],
			  ],
	     };

$contact =  { attrs => {xmlns => 'nmtb'},
	      elements => [
			    [email => 'text'],
        		    [phoneNumber => 'text'],
			    [administrator => 'text'],
			    [institution   => 'text'],
                          ],
            };  
	    
$textnode_nmtb = { attrs  => {xmlns => 'nmtb'}, 
		   elements => [], 
        	   text => 'scalar',
                 };
		 
$node =  { attrs  => { id => 'scalar', metadataIdRef => 'scalar', xmlns => 'pingertopo'}, 
	   elements => [ 
        		 [name =>  $basename],
        		 [hostName =>  $textnode_nmtb],
        		 [description =>  $textnode_nmtb ],
        		 [location => $location ],
        		 [contact =>  $contact], 
        		 [parameters =>  $parameters], 
        		 [port => $port],
        	       ], 
        };
 
$domain = { attrs  => {id => 'scalar', xmlns => 'pingertopo'}, 
            elements => [ 
        		  [comments =>  $textnode_nmtb], 
        		  [node => [$node]], 
        	        ], 
          };
	  
$pingertopo = { attrs  => {xmlns => 'pingertopo'}, 
		elements => [ 
        		      [domain => [$domain]], 
        		    ], 
              }; 
 
1;
 
  
