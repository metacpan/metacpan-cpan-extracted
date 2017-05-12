package  perfSONAR_PS::DataModels::PingER_Topology;
 
=head1 NAME

   perfSONAR_PS::DataModels::Network_Topology - perfSONAR network topology schema  expressed in perl
 
=head1 DESCRIPTION

   
    'nmrtopo' extension  of the perfSONAR_PS RelaxNG Compact schema for  the perfSONAR
    services metadata  
    see:  
    
    http://anonsvn.internet2.edu/svn/nmwg/trunk/nmwg/schema/rnc/topo/nmtopo_base.rnc
  
   
   
=head1 SYNOPSIS

      ###  
      use  perfSONAR_PS::DataModels::Network_Topology qw($nmtopo);

       
      
    
       
=cut 

=head1 Exported Variables
 
     $pingertopo  $port   $node $domain

=cut



use strict;
use warnings;
use version;our $VERSION  = '2.0';

 
our @EXPORT    = qw( );   
our @EXPORT_OK = qw($nmtopo $addressL2 $port_l2 $port_l3 $node $domain);
 
our ($pingertopo, $port_l2, $port_l3,$parameters, $addressL2, $parameter, $location, $contact ,$basename, $node,$domain, $textnode_nmtb);  

use   perfSONAR_PS::DataModels::Base_Model  2.0 qw($addressL3);
 
           

$addressL2 = { attrs  => {value => 'scalar', type  => 'scalar',  xmlns => 'nmtl2'},
	       elements => [ ],
	       text => 'unless:value',

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
$relation =  { attrs => {xmlns => 'nmtb', type => 'scalar'},
	       elements => [
			     [domainIdRef => 'text'],
        		     [nodeIdRef => 'text'],
			     [portIdRef => 'text'],
			     [linkIdRef => 'text'],
			     [pathIdRef  => 'text'],
			     [netwrokIdRef  => 'text'],
			     [serviceIdRef  => 'text'],
			     [groupIdRef => 'text'],
			     [idRef  => 'text'],
			  ],
	     };     
$port_l3 = { attrs  => {id => 'scalar', xmlns => 'nmtl3'},
            elements => [
        		  [  address=>  $addressL3 ], 
			  [  name  =>   'text'],  
			  [  description  =>   'text'],         		   
        	      ], 
           }; 
$port_l2 = { attrs  => {id => 'scalar', xmlns => 'nmtl2'},
            elements => [
        		[ ipAddress=>  $addressL2 ],       		   
        	      ], 
           }; 
 
$contact =  { attrs => {xmlns => 'nmtb', priority => 'scalar'},
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
		 
$node =  { attrs  => { id => 'scalar', idRef => 'scalar', xmlns => 'nmtb'}, 
	   elements => [ 
        		 [name =>  $basename],
        		 [hostName =>  $textnode_nmtb],
			 [relation =>  $relation],
        		 [description =>  $textnode_nmtb ],
			 [comments =>  $textnode_nmtb], 
        		 [location => $location ],
        		 [contact =>  $contact], 
        		 [parameters =>  $parameters], 
        		 [port => $port],
        	       ], 
        };
 
$domain = { attrs  => {id => 'scalar', xmlns => 'nmtb'}, 
            elements => [ 
        		  [node => [$node]], 
        	        ], 
          };
	  
$nmtopo = { attrs  => {xmlns => 'nmtopo'}, 
		elements => [ 
        		      [domain => [$domain]], 
        		    ], 
              }; 
 
1;
 
  
