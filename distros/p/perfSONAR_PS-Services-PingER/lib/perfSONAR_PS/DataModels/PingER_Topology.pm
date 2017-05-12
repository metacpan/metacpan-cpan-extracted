package  perfSONAR_PS::DataModels::PingER_Topology;
 
=head1 NAME

   - perfSONAR schemas expressed in perl, used to build binding perl objects collection
 
=head1 DESCRIPTION

   perlish expression of the perfSONAR_PS RelaxNG Compact schema of the PingER Topology
   
   
   
=head1 SYNOPSIS

      ###  
      use  DataModel qw($pingertopo);

      ##  export all structures and adjust any:
      ##
      ## for exzample for pinger 
    
      push @{$pingertopo->{elements}},  [endPointPair =>  [$endPointPair,  $endPointPairL4]];
  
      $pingertopo->{attrs}->{xmlns}  = 'pinger';
      
   
       
      ####
      
      ### thats it, next step is to build API
       
=cut 

=head1 Exported Variables
 
$pingertopo $port $pingerTest $basename $hostName $node $domain 

=cut



 use strict;
 use warnings;
 
  
BEGIN {
 use Exporter ();
 our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
        use version; our $VERSION =    qv('2.0'); 
        # set the version for version checking
        #$VERSION     = 2.0;
        # if using RCS/CVS, this may be preferred
        #$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
        %EXPORT_TAGS = ();
        @ISA         = qw(Exporter);
        @EXPORT     = qw( );
        
      
        @EXPORT_OK   =qw($pingertopo $port $parameters $location $contact $parameter $basename   $node $domain);
}
use version;
our @EXPORT_OK ;
our ($pingertopo, $port,$parameters, $parameter,$location, $contact ,$basename,  $node ,$domain , $textnode_nmtb );  
use   perfSONAR_PS::DataModels::DataModel   2.0 qw($addressL3);
 
  $port = {'attrs'  => {id => 'scalar', xmlns => 'nmtl3'},
 	       elements => [
 			      [ipAddress=>  $addressL3],
			     
			  ], 
 	      }; 
	      
   $parameter	=  {'attrs'  => {name => 'enum:count,packetInterval,packetSize,ttl,measurementPeriod,measurementOffset',  value => 'scalar', xmlns => 'nmwg'},
                     elements => [],
			      text => 'unless:value',
	         };      
  $parameters = {'attrs'  => {id => 'scalar',   xmlns => 'nmwg'},
 	       elements => [
 			      [parameter =>  [$parameter]],			    
			  ], 
 	      }; 
	      
  $basename = 	{  'attrs'  => {type => 'scalar',   xmlns => 'nmtb'}, 
                   elements => [], 
		   text => 'scalar',
	       };
  $location =  { 'attrs' => {xmlns => 'nmtb'},
                  elements => [
                         [continent => 'text'],
			 [country => 'text'],
                         [zipcode   => 'text'],
                         [state   => 'text'],
                         [institution   => 'text'],
                         [city   => 'text'],
                         [streetAddress  => 'text'],
                         [floor   => 'text'],
                         [room   => 'text'],
                         [cage   => 'text'],
                         [rack  => 'text'], 
                         [shelf  => 'text'], 
                         [latitude => 'text'], 
                         [longitude   => 'text'],
                              ],
               };
  
  $contact =  { 'attrs' => {xmlns => 'nmtb'},
                  elements => [
                         [email => 'text'],
			 [phoneNumber => 'text'],
                         [administrator   => 'text'],
                         [institution   => 'text'],
                        
                              ],
               };   
  $textnode_nmtb = {  'attrs'  => {xmlns => 'nmtb'}, 
                   elements => [], 
		   text => 'scalar',
	       };
  $node =  {  'attrs'  => { id => 'scalar', metadataIdRef => 'scalar', xmlns => 'pingertopo'}, 
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
   
  $domain =    {  'attrs'  => {id => 'scalar', xmlns => 'pingertopo'}, 
                  elements => [ 
		                 [ comments =>  $textnode_nmtb ], 
				 [ node => [$node]], 
			        
			      ], 
	       };
  $pingertopo = {  'attrs'  => {xmlns => 'pingertopo'}, 
                  elements => [ 
		                 [ domain => [$domain]], 
			        
			      ], 
	         }; 
 
1;
 
  
