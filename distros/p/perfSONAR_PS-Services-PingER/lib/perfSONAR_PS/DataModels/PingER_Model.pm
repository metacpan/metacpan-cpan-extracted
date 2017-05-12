package  perfSONAR_PS::DataModels::PingER_Model;
 
=head1 NAME

   perfSONAR_PS::DataModels::PingER_Model - perfSONAR schemas expressed in perl for pinger MA, used to build binding perl objects collection
 
=head1 DESCRIPTION

      see perfSONAR_PS::DataModels::DataModel for details. this is the perl way to extend something
  
   
=head1 SYNOPSIS

      ###  
      use perfSONAR_PS::DataModels::PingER_Model qw($message);
     
      
      ### thats it, next step is to build API by utilizing buildAPi from APIBuilder.pm package
      
      buildAPI('message', $message,  '', '' );
      
=cut 

=head1 Exported variables

        $message - the hasref with whole data model description for pinger MA message
 
=cut    
use strict;
use warnings;
use Data::Dumper;
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
        
      
        @EXPORT_OK   =qw($message);
}
use   version;  
our @EXPORT_OK;

 
use   perfSONAR_PS::DataModels::DataModel   2.0 qw($endPointPair $interfaceL3  $message $metadata $data $addressL4 $endPoint $key
          $time $endPointL4 $addressL3 $service_subject $select_subj $select_params  
	   $service_parameters $resultDatum $commonTime $parameters $parameter $endPointPairL4); 

   
  ##############_-----------------------------mapping SQL on current schema ( the hardest part ), conditional 'if' added 
  
    $addressL3->{sql} =  {metaData => {'transport'  =>   {value => 'type'},
                                                      },  
					   host =>    {'ip_number'  =>   {value =>  ['value' , 'text']},
					              },
			 };
							
   $addressL4->{sql} =  {metaData => {'ip_name_src' => {'value' =>  ['value' , 'text'], 'if' => 'type:hostname'},
                                                        'ip_name_dst' => {'value' =>  ['value' , 'text'], 'if' => 'type:hostname'},
                                                      },
                                           host =>    {'ip_number'  =>  {'value' =>  ['value' , 'text'], 'if' => 'type:ipv4'},
					              },    
                        };
  
   $interfaceL3->{sql} =  {metaData => {'transport' =>   {'value' => 'ipAddress'},
                                                           'ip_name_src' => {'value' => 'ifHostName'},
							   'ip_name_dst' => {'value' => 'ifHostName'},
							  },
                                              host =>     {'ip_number'  =>  {'value' =>  'ipAddress'},
					                   'ip_name'    =>  {'value' => 'ifHostName'},
					                  }
		    };
 
   $endPointL4->{sql}= {metaData => {'ip_name_src' => {'value' => ['address', 'interface'], if => 'role:src'},
                                                            'ip_name_dst' => {'value' => ['address', 'interface'], if => 'role:dst'},
                                                            'transport'   => {'value' => ['address', 'interface']},
					                   },
                                               host =>     {'ip_number' =>   {'value' => ['address', 'interface']},
					                    'ip_name'   =>   {'value' => [ 'address' ,'interface']},
							   },
			}; 
    
    $endPoint->{attrs}->{type} = 'enum:hostname'; 							     
    
    $endPoint->{sql} = {metaData => {'ip_name_src' =>   { value => ['value' , 'text'], if => 'type:hostname'}, 
    							  'ip_name_dst' =>   { value => ['value' , 'text'], if => 'type:hostname'}, 
						         },
					     host =>     {'ip_number'  =>    { value => ['value' , 'text'], if => 'type:ipv4'}, 
					                  'ip_name'    =>    { value => ['value' , 'text'], if => 'type:hostname'}, 
							 },
		       }; 		 
  
 							 
    $endPointPair->{sql} =   {metaData => { 'ip_name_src' =>   { value => 'src'},  
                                            'ip_name_dst' =>   { value => 'dst'},  
						                },   
                                                    host =>     { 'ip_number' =>    { value => ['src', 'dst']},  
						                  'ip_name'    =>    { value => ['src', 'dst']},                                     
                                                                },
			     }; 	
						
   
   
   
   $parameter->{'attrs'} = {name => 'enum:count,packetInterval,packetSize,ttl,valueUnits,startTime,endTime,protocol,transport,setLimit', 
                            value => 'scalar', xmlns => 'nmwg'};
                  
   $parameter->{sql} =            {metaData => {count => { value =>  ['value' , 'text'], if => 'name:count'},
			                        packetInterval=> { value =>  ['value' , 'text'], if => 'name:packetInterval'},
				                packetSize=> { value => ['value' , 'text']  , if => 'name:packetSize'},
				                ttl=> { value =>   ['value' , 'text'] , if => 'name:ttl'},
				                protocol => { value =>   ['value' , 'text'] , if => 'name:protocol'},
				                transport => { value =>   ['value' , 'text'] , if => 'name:transport'},
                                                },
			           time     => {start =>  { value =>   ['value' , 'text'],  if => 'name:startTime'},
                                                end  =>   { value =>  ['value' , 'text'],  if => 'name:endTime'},
                                               },
			           limit    => {setLimit => { value =>   ['value' , 'text'],  if => 'name:setLimit'},			  
				                },
		                   }; 		  

    ########## next lines are commented because we selecting time from stupid parameters ( instead of proper time elements )
   ########
   # %{$time}  =   ( %{$time},  sql => { 'data' => { start => { value =>  'value' },
    #                                                           duration =>  { value =>  'duration'},
    #                                                           end =>   { value =>  'value'},
    #                                                           
	#						     },
	#						     
    #
     #                                             }); 	
  #  %{$commonTime} =   ( %{$commonTime }, sql => { 'data' => { start => { value => ['value','start']},
   #                                                            duration =>  { value =>  'duration' },
  #                                                             end =>   { value =>  'end'},
  #                                                             
  #							     },
 #							     
 #   
 #                                                 }); 	

   my $pingerDatum    =  {'attrs'  => {value => 'scalar',  valueUnits => 'scalar',  seqNum => 'scalar',    numBytes => 'scalar', ttl => 'scalar',
                                       name => 'enum:minRtt,maxRtt,meanRtt,medianRtt,lossPercent,clp,minIpd,maxIpd,iqrIpd,meanIpd,duplicates,outOfOrder',
                                       timeType => 'scalar', timeValue => 'scalar', xmlns => 'pinger'},
                          elements => [],
			  sql => {     'data' => {  
			                          minRtt  => { value =>  ['value' , 'text'], if => 'name:minRtt'},
			                          maxRtt  => { value => ['value' , 'text'], if => 'name:maxRtt'},
						  meanRtt => { value => ['value' , 'text'], if => 'name:meanRtt'},
						  medianRtt => { value => ['value' , 'text'], if => 'name:medianRtt'},
						  lossPercent   => { value => ['value' , 'text'], if => 'name:lossPercent'}, 
						  minIpd  => { value => ['value' , 'text'], if => 'name:minIpd'},  
						  maxIpd   => { value => ['value' , 'text'], if => 'name:maxIpd'}, 
						  iqrIpd   => { value => ['value' , 'text'], if => 'name:iqrIpd'}, 
						  meanIpd  => { value => ['value' , 'text'], if => 'name:meanIpd'}, 
						  clp =>  { value => ['value' , 'text'], if => 'name:clp'},
						  duplicates =>  { value => ['value' , 'text'], if => 'name:duplicates'},
						  outOfOrder =>  { value => ['value' , 'text'], if => 'name:outOfOrder'},
						  numBytes => { value =>  'numBytes'},
						  seqNums   => { value =>  'seqNum'},
						  ttl       => { value =>  'ttl'},
						  rtts =>    { value => 'value' },						
					      },
					      					             
				     },
			            
	                 };  
  
   push @{$commonTime->{elements}}, [datum => [$pingerDatum]]; 
 
    $service_parameters =  {'attrs'  => {id => 'scalar',   xmlns => 'pinger'},
                    elements => [
		               [parameter => [$parameter]], 
			      
			      ], 
	         }; 
    $service_subject= { 'attrs'   => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'pinger'},
                        elements => [
			                [endPointPair =>    [$endPointPair ,  $endPointPairL4]],
					 
				    ], 
	             };    
   $data = {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'nmwg'},
 	       elements => [
 			    [commonTime  => [$commonTime]], 
			    [datum  => [[$pingerDatum], [$resultDatum]], 'unless:commonTime'],
 			    [key       =>   $key, 'unless:commonTime,datum'],    
 			   ],
 			    
 	      }; 
 
   $metadata = {'attrs'  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'nmwg'},
 	       elements => [
 			    [subject    =>  [$service_subject, $select_subj]],
			    [parameters =>  [$select_params, $service_parameters]],
			    [eventType  =>  'text'], 
 			    [key        =>  $key], 
			  ], 
 	      }; 

  $message  = {  'attrs'  => {id => 'scalar', type => 'scalar', xmlns => 'nmwg'}, 
                  elements => [ 
		                [parameters =>  [$service_parameters]],
		                [metadata =>    [$metadata]], 
			        [data	   =>   [$data]]
			      ], 
	         }; 
   ### die  " Message definition: " . Dumper  $metadata;
   
 1;
