package  perfSONAR_PS::DataModels::PingER_Model;
 
=head1 NAME

   perfSONAR_PS::DataModels::PingER_Model - perfSONAR schemas expressed in perl for pinger MA, used to build binding perl objects collection
 
=head1 DESCRIPTION

      see perfSONAR_PS::DataModels::DataModel for details.
      this is an extension of the base schema for pinger.rnc:
      
      http://anonsvn.internet2.edu/svn/nmwg/trunk/nmwg/schema/rnc/pinger.rnc
  
   
=head1 SYNOPSIS

      ###  
      use perfSONAR_PS::DataModels::PingER_Model qw($message);
      
 
=head1 Exported variables

        $message - the hasref with whole data model description for pinger MA message
 
=cut    


use strict;
use warnings;
use version; our $VERSION  = '2.0';
use Exporter ();
use base 'Exporter';
 
our @EXPORT     = qw( );    
our @EXPORT_OK   =qw($message);
 
use   perfSONAR_PS::DataModels::Base_Model 2.0 qw($endPointPair $interfaceL3  $message   $addressL4 $endPoint 
                                                 $time $endPointL4 $addressL3 $service_subject    $service_parameter
                                                 $service_parameters  $service_datum $commonTime $parameters $parameter $endPointPairL4); 

 
##############_-----------------------------mapping SQL DB schema on XML elements, conditional 'if' added 

$addressL3->{sql} =  { metaData => {'transport'  =>   {value => 'type'},
        			   },  
		       host =>     {'ip_number'  =>   {value =>  ['value' , 'text']},
				   },
		     };
						     
$addressL4->{sql} =  { metaData => { 'ip_name_src' => {'value' =>  ['value' , 'text'], 'if' => 'type:hostname'},
        			     'ip_name_dst' => {'value' =>  ['value' , 'text'], 'if' => 'type:hostname'},
        		           },
        	       host =>     { 'ip_number'  =>  {'value' =>  ['value' , 'text'], 'if' => 'type:ipv4'},
				   },	 
        	     };

$interfaceL3->{sql} =  { metaData => { 'transport'   => {'value' => 'ipAddress'},
        	 		       'ip_name_src' => {'value' => 'ifHostName'},
		 		       'ip_name_dst' => {'value' => 'ifHostName'},
		 		     },
        	         host =>     { 'ip_number'  =>  {'value' =>  'ipAddress'},
		 		       'ip_name'    =>  {'value' => 'ifHostName'},
		 		      }
		 };

$endPointL4->{sql}= { metaData => { 'ip_name_src' => {'value' => ['address', 'interface'], if => 'role:src'},
	         		    'ip_name_dst' => {'value' => ['address', 'interface'], if => 'role:dst'},
	         		    'transport'   => {'value' => ['address', 'interface']},
                 	          },
	              host =>     { 'ip_number'   => {'value' => ['address', 'interface']},
                 		    'ip_name'     => {'value' => [ 'address' ,'interface']},
                 	           },
        	      }; 
  
$endPoint->{attrs}->{type} = 'enum:hostname';  							  
 
$endPoint->{sql} = { metaData => { 'ip_name_src' =>   { value => ['value' , 'text'], if => 'type:hostname'}, 
        	 		   'ip_name_dst' =>   { value => ['value' , 'text'], if => 'type:hostname'}, 
		 		 },
		     host =>	 { 'ip_number'  =>    { value => ['value' , 'text'], if => 'type:ipv4'}, 
		 		   'ip_name'    =>    { value => ['value' , 'text'], if => 'type:hostname'}, 
		 		 },
		    };  	      

						      
$endPointPair->{sql} =   { metaData => { 'ip_name_src' =>   { value => 'src'},  
        				 'ip_name_dst' =>   { value => 'dst'},  
		        	       },   
        	           host =>     { 'ip_number'   =>   { value => ['src', 'dst']},  
		        	         'ip_name'     =>   { value => ['src', 'dst']},					  
        	        	       },
			  };	     
					     


$service_parameter->({ attrs => { name => 'enum:consolidationFunction,resolution,count,packetInterval,packetSize,ttl,valueUnits,startTime,endTime,protocol,transport,setLimit', 
        		           value => 'scalar', xmlns => 'nmwg'}, 
		       elements => [],
		       text => 'unless:value',
		       sql => {metaData => { count => { value =>  ['value' , 'text'], if => 'name:count'},
			        	     packetInterval=> { value =>  ['value' , 'text'], if => 'name:packetInterval'},
			        	     packetSize=> { value => ['value' , 'text']  , if => 'name:packetSize'},
			        	     ttl=> { value =>   ['value' , 'text'] , if => 'name:ttl'},
			        	     protocol => { value =>   ['value' , 'text'] , if => 'name:protocol'},
			        	     transport => { value =>   ['value' , 'text'] , if => 'name:transport'},
        		        	   },
			       time     => { start =>  { value =>   ['value' , 'text'],  if => 'name:startTime'},
        		        	     end  =>   { value =>  ['value' , 'text'],  if => 'name:endTime'},
			        	     resolution  =>   { value =>  ['value' , 'text'],  if => 'name:resolution'},
			        	     cf  =>   { value =>  ['value' , 'text'],  if => 'name:consolidationFunction'},
        		        	   },
			       limit    => { setLimit => { value =>   ['value' , 'text'],  if => 'name:setLimit'},		     
			        	   },
			      }
		    });  	     

$service_datum->({ attrs => { value => 'scalar',  valueUnits => 'scalar',  seqNum => 'scalar',    numBytes => 'scalar', ttl => 'scalar',
			      name => 'enum:minRtt,maxRtt,meanRtt,medianRtt,lossPercent,clp,minIpd,maxIpd,iqrIpd,meanIpd,duplicates,outOfOrder',
			      timeType => 'scalar', timeValue => 'scalar', xmlns => 'pinger'},
		   elements => [],
        	   sql => {  'data' => {  
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
              });
		   
$service_subject->({  attrs  => {id => 'scalar', metadataIdRef => 'scalar',xmlns => 'pinger'},
		      elements => [
        			    [endPointPair =>    [$endPointPair ,  $endPointPairL4]],       			       
        			  ], 
        	  });    
 
 
 1;
