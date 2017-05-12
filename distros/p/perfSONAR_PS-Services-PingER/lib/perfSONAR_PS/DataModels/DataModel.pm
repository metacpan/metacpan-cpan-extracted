package  perfSONAR_PS::DataModels::DataModel;
 
=head1 NAME

  DataModel - perfSONAR schemas expressed in perl, used to build binding perl objects collection
 
=head1 DESCRIPTION

   perlish expression of the perfSONAR_PS RelaxNG Compact schemas
   
   every element expressed as:
   
   $subelement_defintion = {};...
  
   $parameter	=  {'attrs'  => {name => 'enum:param,default',  value => 'scalar', xmlns =>  'nmwg' },
                  elements => [[subelement1 => $subelement_defintion, 'unless:value'],
			      text => 'scalar',
	         }; 
   Where 'attrs' referrs to the hash of attributes with xmlns for the   namespace id ( from perfSONAR_PS::Datatypes::Namespace )
   elements referrs to the array of elements, defined already and text stays for the text content of the element
   there is some conditional logic allowed. In elements the third memebr is an optionla condition with syntax: '<if|unless>:<name1,name2,...>'
   where <name1,name2...> might be list of any predefined  attribute keys or element names. 
      In attributes hash and in text content definition this condition should be used
   in place  of 'scalar'. Another validation condition is supported: 'enum:<comma separated list of enunms>'. Its useful for enumerated
   type of attributes ( not supported for elements). For multiple choice element definition use array ref:
   [subelement1 => [$subelement_defintion1,$subelement_defintion2]]
   
=head1 SYNOPSIS

      ###  
      use  DataModel qw($subject $endPointPair $parameter $parameters $commonTime $endPointPairL4);

      ##  export all structures and adjust any:
      ##
      ## for exzample for pinger 
    
      push @{$subject->{elements}},  [endPointPair =>  [$endPointPair,  $endPointPairL4]];
  
      $subject->{attrs}->{xmlns}  = 'pinger';
      my $pingerDatum1    =  {'attrs'  => {value => 'scalar', valueUnits => 'scalar', seqNum => 'scalar', 
                                     numBytes => 'scalar', ttl => 'scalar', timeType => 'scalar', timeValue => 'scalar',
				    xmlns => 'pinger'},
                   elements => [],	          
	        };  
     my $pingerDatum2    =  {'attrs'  => {value => 'scalar',  valueUnits => 'scalar',   
                                       name => 'enum:minRtt,maxRtt,meanRtt,medianRtt,lossPercent,clp,minIpd,maxIpd,iqrIpd,meanIpd',
                                       timeType => 'scalar', timeValue => 'scalar', xmlns => 'pinger'},
                   elements => [],	          
	        };  
  %{$parameter} = ('attrs'  => {name => 'enum:count,interval,packetSize,ttl,valueUnits',  value => 'scalar', xmlns => 'nmwg'},
                  elements => [],
			      text => 'unless:value',
	         ); 		  
  
   push @{$commonTime->{elements}}, [datum => [$pingerDatum1, $pingerDatum2 ]]; 
 
   push @{$data->{elements}}, [datum => [$pingerDatum1, $pingerDatum2, $resultDatum]];
   $parameters->{attrs}->{xmlns}= 'pinger';
       
      ####
      
      ### thats it, next step is to build API
       
=cut 

=head1 Exportedvariables
 
$message $metadata $data  $key $endPointPairL4  $datum $commonTime\
	              $endPointPairL3 $interfaceL3 $addressL4 $addressL3 $endPointPair $resultDatum  $endPointL4  $subject $time $parameters $parameter

=cut



 use strict;
 use warnings;
 
  
BEGIN {
 use Exporter ();
 our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
        use version; our $VERSION =   qv('2.0');
        # set the version for version checking
        #$VERSION     = 2.0;
        # if using RCS/CVS, this may be preferred
        #$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
        %EXPORT_TAGS = ();
        @ISA         = qw(Exporter);
        @EXPORT     = qw( );
        
      
        @EXPORT_OK   =qw($message $metadata $datum $data   $resultDatum   $key $endPointPairL4  $endPointL4 $commonTime 
	              $endPointPairL3 $interfaceL3 $addressL4 $addressL3 $endPointPair $key  $time   $parameter $parameters
		      $endPoint $service_parameters $select_params $select_subj $service_subject);
}
our @EXPORT_OK ;
our ($message, $metadata, $data,  $key, $endPointPairL4 , $resultDatum,  $commonTime, $datum, $endPointL4,  
	              $endPointPairL3, $interfaceL3, $addressL4, $addressL3, $endPointPair,   $subject, $time, $parameters, $parameter,
		      $service_parameters, $service_subject,  
		      $select_params, $average_params, $mean_params, $median_params, $max_params, $min_params, $cdf_params, $histogram_params,		      
		      $select_subj, $average_subj, $mean_subj, $median_subj, $max_subj, $min_subj, $cdf_subj, $histogram_subj,
		      
		      $endPoint );  
 
   $subject =  {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'nmwg'},
                 elements => [] , 
	         }; 
		 
		 
   $parameter	=  {'attrs'  => {name => 'scalar',  value => 'scalar', xmlns => 'nmwg'},
                     elements => [],
			      text => 'unless:value',
	         }; 		 
   $parameters =  {'attrs'  => {id => 'scalar',   xmlns => 'nmwg'},
                    elements => [
		               [parameter => [$parameter]], 
			      
			      ], 
	         }; 	
  $service_parameters =  {}; 	
  $service_subject =  {}; 		 
   no strict 'refs';
   foreach my $filters (qw/select average mean median max min cdf histogram/) {
        ${"$filters\_params"} = {'attrs'  => {id => 'scalar',   xmlns =>  $filters },
                                 elements => [
		                               [parameter  => [$parameter]], 			      
			                     ], 
	                       };
      		
    }
   
   
   foreach my $filters (qw/select average mean median max min cdf histogram/) {
        ${"$filters\_subj"} = {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',  xmlns =>  $filters },
                               elements => [], 
	                      };
       	
   }
   use strict;			
   
   $key = {'attrs'  => {id => 'scalar',   xmlns => 'nmwg'},
                  elements => [
		               [parameters => [$parameters]], 			      
			      ], 
	        };
		
  
   $datum = 	 {'attrs'  => {xmlns => 'nmwg'},
                   elements => [],
                  };  
   $resultDatum = 	 {'attrs'  => {type => 'scalar', xmlns => 'nmwgr'},
                   elements => [],
		   text => 'scalar',
                  };  
		  
   $time = 	{'attrs'  => {type => 'scalar', value => 'scalar', duration => 'scalar', inclusive => 'scalar', xmlns => 'nmtm'},
                  elements => [], 
	         }; 
   $addressL4 = {'attrs'  => {value => 'scalar', type  => 'scalar',  xmlns => 'nmtl4'},
                  elements => [], 
                  text => 'unless:value',
   
   }; 
   
   $addressL3 = {'attrs'  => {value => 'scalar', type  => 'scalar',  xmlns => 'nmtl3'},
                  elements => [], 
                  text => 'unless:value',
   
   };	
   						 
  $interfaceL3  = {'attrs'  => {id => 'scalar', interfaceIdRef => 'scalar',   xmlns => 'nmtl3'},
                  elements => [
		               [ipAddress => $addressL3],
			       [netmask =>  'text'],
			       [ifName =>  'text'],
			       [ifDescription =>  'text'],
			       [ifAddress =>  $addressL3 ],
			       [ifHostName =>  'text'],
			       [ifIndex =>  'text'],
			       [type  =>  'text'],
			       [capacity  =>  'text'],
			      ], 
                  text => 'unless:ipAddress',
   
   };
   $endPointL4 =    {  'attrs'  => { port => 'scalar', protocol => 'scalar', role => 'enum:src,dst',   xmlns => 'nmtl4'},
                        elements => [
		                      [address =>  $addressL4], 
			              [interface =>  $interfaceL3 , 'unless:address'], 
			            ], 
                   };
    
   $endPointPairL4 = {  'attrs'  => { xmlns => 'nmtl4'},
                       elements => [
		                 [endPoint  => [$endPointL4]], 
			        ], 
  }; 
  $endPoint = {  'attrs'  => {value => 'scalar', type => 'scalar', port => 'scalar',  xmlns => 'nmwgt'},
                                                   elements => [], 
						   text => 'unless:value',
                                                 }; 
  	 	
  $endPointPair	= { 'attrs'  => { xmlns => 'nmwgt'},
                    elements => [
		                 [src  =>   $endPoint ], 
			         [dst  =>   $endPoint ], 
				 	 
			      ], 
			      
  
  };	 	
  $commonTime = {'attrs'  => {type => 'scalar', value => 'scalar', duration => 'scalar', inclusive => 'scalar', xmlns => 'nmwg'},
                  elements => [
		               ['start' =>  $time , 'unless:value'], 
			       ['end'  =>   $time , 'if:value,start'], 
			        ],
			      
	         }; 
 		 
  $data = {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'nmwg'},
 	       elements => [
 			    [commonTime  => [$commonTime]], 
			   
 			    [key       =>  $key, 'unless:commonTime,datum'],    
 			   ],
 			    
 	      }; 
  
  $metadata = {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'nmwg'},
 	       elements => [
 			    [subject    =>  [$subject, $service_subject, $select_subj, $average_subj, $mean_subj, $median_subj, $max_subj, $min_subj, $cdf_subj, $histogram_subj]],
			    [parameters =>  [$parameters,  $select_params, $average_params, $mean_params, $median_params, $max_params, $min_params, $cdf_params, $histogram_params]],
 			    [eventType  =>  'text'], 
 			    [key        =>  $key], 
			  ], 
 	      }; 

  $message  = {  'attrs'  => {id => 'scalar', type => 'scalar', xmlns => 'nmwg'}, 
                  elements => [ 
		                [parameters =>  [$service_parameters, $parameters, $select_params, $average_params, $mean_params, $median_params, $max_params, $min_params, $cdf_params, $histogram_params ]],
		                [metadata => [$metadata]], 
			        [data	   => [$data]]
			      ], 
	         }; 
 
1;
 
  
