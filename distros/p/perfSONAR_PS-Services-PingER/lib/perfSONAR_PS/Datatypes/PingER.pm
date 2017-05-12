use perfSONAR_PS::DB::SQL::PingER;

package perfSONAR_PS::Datatypes::PingER;
{
=head1 NAME

 perfSONAR_PS::Datatypes::PingER  -  this is a pinger message  handler object


=head1 DESCRIPTION

   it inherits everything from perfSONAR_PS::Datatypes::Message and only implements  request handlers with pinger specifics 
    
=head1 SYNOPSIS
             
  
	     use perfSONAR_PS::Datatypes::PingER ;
	   
	     
	     my ($DOM) = $requestMessage->getElementsByTag('message');
	    
	     my $message = new perfSONAR_PS::Datatypes::PingER($DOM);
             $message = new perfSONAR_PS::Datatypes::PingER({id => '2345', 
	                                                     type = 'SetupdataResponse',
							     metadata => {'id1' =>   <obj>},
							     data=> {'id1' => <obj>}}); 
	 
	    #######   add data element, namespaces will be added from this object to Message object namespace declaration
             $message->addPartById('id1', 'data', new perfSONAR_PS::Datatypes::PingER::data({id=> 'id1', metadataIdRef => 'metaid1' }));
        
	    ########add metadata element, namespaces will be added from this object to Message object namespace declaration
	     $message->addPartById('id1', 'metadata',  new perfSONAR_PS::Datatypes::PingER::metadata({id=> 'id1' });
	     
	     my $dom = $message->getDOM(); # get as DOM 
	     print $message->asString();  # print the whole message
	     
	     
=head1   METHODS

=cut


use strict;
use warnings;
use English qw( -no_match_vars);
use Log::Log4perl qw(get_logger); 
use POSIX qw(strftime);
use Data::Dumper;
use Scalar::Util qw(blessed);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message; 
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime;

use perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum;

use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Parameters;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters;

use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject; 
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum;

use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Subject;

use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter;
use perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair::Dst;
use perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair::Src;
use perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair;

use perfSONAR_PS::Datatypes::NSMap;
use perfSONAR_PS::Datatypes::EventTypes;
 
 
use base qw(perfSONAR_PS::Datatypes::Message);
 
use constant  CLASSPATH =>  'perfSONAR_PS::Datatypes::PingER';
use constant  LOCALNAME => 'message'; 

#
#   internal limit for the number of the data/metadata in the response message
#
our $_sizeLimit = '1000000'; 

 
 
=head2 handle 

   dispatch method. accepts type of request,response object and MA config hashref as parameters, returns fully built response object,
   sets query size limit  

=cut

sub handle {
    my $self = shift;
    my $type = shift;
    my $response = shift; 
    my $maconfig = shift;
    my $logger  = get_logger( CLASSPATH );
    no strict 'refs';  
    if($self->can($type)) {
        $_sizeLimit = $maconfig->{query_size_limit} if $maconfig && ref($maconfig) eq 'HASH' && $maconfig->{query_size_limit};
        $logger->debug(" Size limit set to:  $_sizeLimit ");       
        return $type->($self, $response);
    } else {
       $logger->error(" Handler for $type Not supported");
       return undef;
    }
    use strict;
}


=head2   MetadataKeyRequest

      method for MetadataKey request,  works per event ( single pre-merged md  and data pair)
      returns filled response message object 

  ###############################  From Jason's SNMP MA code ################################### 
  # MA MetadataKeyRequest Steps
  # ---------------------
  # Is there a key?
  #   Y: do queries against key 
  #      return key as md AND d
  #   N: Is there a chain?
  #     Y: Is there a key
  #       Y: do queries against key, add in select stuff to key, return key as md AND d
  #       N: do md/d queries against md return results with altered key
  #     N: do md/d queries against md return results
  #--------------------------
 
=cut

sub  MetadataKeyRequest {
    my $self = shift;
    my $response = shift;
    my $logger  = get_logger( CLASSPATH );   
    $logger->debug("MetadataKeyRequest  ...");
 
    unless($response && blessed  $response &&   $response->can("getDOM")) {
        $logger->error(" Please supply  metadata  object and not the:" . ref($response));
        return  " System error, API incomplete";
    }
    ##my $message_params = perfSONAR_PS::Datatypes::v2_0::select::Message::Parameters->new();
    ##my $message_limit = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Parameters::Parameter->new({name => 'sizeLimit', value =>  $_sizeLimit});
    ##$message_params->addParameter($message_limit);
    ##$response->addParameters($message_params);
    #### setting status URI for response 
    $self->eventTypes->status->operation('metadatakey');
    $logger->error(" Please supply  array of metadata and not: " . $self->metadata ) unless $self->metadata && ref($self->metadata) eq 'ARRAY';
    my $data  =   $self->data->[0];
    my $requestmd =  $self->metadata->[0];
    my  $objects  = undef;### iterator returned by backend query
    if($requestmd->key  &&  $requestmd->key->id) {
        $logger->debug(" Found Key =" . $requestmd->key->id);	  
        $objects  = $self->DBO->getMeta([ metaID=> {eq =>  $requestmd->key->id}], 1);
	     
    }  elsif(($requestmd->subject) ||  ($requestmd->parameters)) { 
        my  $query = {query_metaData => []};
        $query =  $self->buildQuery('eq', $requestmd );
	$query =  {query_metaData => []} unless $query;
	$logger->debug(" Will query = " . Dumper $query);	 	
	$objects  =   $self->DBO->getMeta(  $query->{query_metaData},  _mdSetLimit($query->{query_limit}) );
	 
	if($EVAL_ERROR) {
	    $logger->logdie("PingER backend  Query failed: " . $EVAL_ERROR);
	}
    }  else {
	$logger->warn("Malformed request or missing key or parameters, md=" . $requestmd->id);   
	$response->addResultResponse({ md => $requestmd, message => 'Malformed request or missing key or parameters',  eventType => $self->eventTypes->status->failure});	
        return;     
    }
     
    if($objects &&   ref($objects) eq 'HASH' &&  %{$objects}) {
	foreach my  $metaid (keys %{$objects}) {
	    $logger->debug( "Found metaID " .  $metaid  );
	    my $md =   $self->_ressurectMd({ md_row =>  $objects->{$metaid}  });  
	    my $md_id = $response->addIDMetadata($md, $self->eventTypes->tools->pinger);
            $logger->debug(" MD created: \n " .  $md->asString);
	    my $key =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key->new({id => $metaid });
	    $logger->debug(" KEY  created: \n " .  $key->asString );
	    my $data  = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({ id => "data" . $response->dataID, metadataIdRef => "meta$md_id" , key => $key  });
	    $logger->debug(" DATA created: \n " .  $data->asString);
	    $response->addData($data); ## 
	    $logger->debug(" DATA added");
	    $response->add_dataID;
	}    
    } else {           
        $response->addResultResponse({ md =>  $requestmd, message => ' no metadata found ', eventType => $self->eventTypes->status->failure});
    }
    
    return  0;
}


=head2   SetupDataRequest

   SetupData request,    works per event ( single pre-merged md  and data pair)
      returns filled response message object 
      returns filled response  
  ###############################  From Jason's SNMP MA code ################################### 
  # MA SetupdataRequest Steps
  # ---------------------
  # Is there a key?
  #   Y: key in db?
  #     Y: Original MD in db?
  #       Y: add it, extract data
  #       N: use sent md, extract data
  #     N: error out
  #   N: Is it a select?
  #     Y: Is there a matching MD?
  #       Y: Is there a key in the matching md?
  #         Y: Original MD in db?
  #           Y: add it, extract data
  #           N: use sent md, extract data
  #         N: extract md (for correct md), extract data
  #       N: Error out
  #     N: extract md, extract data
  #----------------------------------
  #     Updated from Jason e-mail, 11/27/07
  #
  #   Is there a key?
  #     Y: key in db?
  #         Y: chain metadata      
  #            extract data
  #         N: error out
  #     N: Is it a select?
  #         Y: Is there a matching MD?
  #             Y: Is there a key in the matching md?
  #                  Y: key in db?
  #                      Y: chain metadata 
  #                         extract data
  #                      N: error out
  #                 N:  chain metadata
  #                     extract data     
  #             N: Error out
  #        N: chain metadata
  #           extract data 
  #
  # 
  
=cut

sub  SetupDataRequest  {
    my $self = shift;
    my $response = shift;
    
    my $logger  = get_logger( CLASSPATH ); 
    $logger->debug("SetupdataKeyRequest  ..."); 
 
    unless($response && blessed  $response &&   $response->can("getDOM")) {
        $logger->error(" Please supply defined object of metadata and not:" . ref($response));
        return "System error,  API incomplete";
    }
    ##my $message_params = perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters->new();
    ##my $message_limit  = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter->new({name => 'sizeLimit', value =>  $_sizeLimit});
    ##$message_params->addParameter($message_limit);
    ##$response->addParameters($message_params);
    #### setting status URI for response
    $self->eventTypes->status->operation('setupdata'); 
    ####  
    ### hashref to hold relation between metaID DB key and meta id 
    my $metaids = {}; 
    ###  hashref to contain time selects metadata which will be 
    ###  chained to the response metadata with pinger key (to re-use time range selects from request)
    my  $time_selects = {}; 
    $logger->debug(" Whole message : " . $self->asString);
    ### single data only ( per event ) set filters array as well
    my  $data  = $self->data->[0];
    my $requestmd =  $self->metadata->[0];
    my @filters = $self->filters?@{$self->filters}:();
     
    unless(  $requestmd  ) {
         $logger->error("Orphaned data   - no  metadata found for metadataRefid:" . $data->metadataIdRef );
         return; 
    } else {
         $logger->debug("Found metadata in request id=" .  $requestmd->id . " metadata=" . $requestmd->asString );
    }
    ### objects hashref  returned by backend query with metaID as key
    my  $objects_hashref  = {};
	# if there is a Key, then get data arrayref
     if($requestmd->key  && $requestmd->key->id) {      
	    if($self->_retriveDataByKey({md => $requestmd , datas => $objects_hashref,  timeselects => $time_selects, metaids => $metaids, response => $response})) {
	        $response->addResultResponse({md => $requestmd, message => 'no  matching data found',  eventType => $self->eventTypes->status->failure});		   
	        return $response;
	    }
     }   elsif($requestmd->subject | $requestmd->parameters) {
	        my $query = {}; 
	        my  $md_objects = undef;
	        eval {
		     foreach my $supplied_md ( $requestmd, @filters)  {
	                %{$query} =  (%{$query} , %{$self->buildQuery('eq',  $supplied_md)});		    
		     }  
		     $logger->debug(" Will query = " . Dumper $query);
	             unless($query && $query->{query_metaData} &&  ref($query->{query_metaData}) eq 'ARRAY' && scalar @{$query->{query_metaData}} >= 1) {
	                $logger->warn(" Nothing to query about for md=" . $requestmd->id);
		        $response->addResultResponse({ md => $requestmd, message => 'Nothing to query about(no key or parameters supplied)',  eventType => $self->eventTypes->status->failure});	
                        return $response;
	            }
                    $md_objects  = $self->DBO->getMeta($query->{query_metaData}, _mdSetLimit($query->{query_limit}) );
	        };
	        if($EVAL_ERROR) {
	            $logger->fatal("PingER backend  Query failed: " . $EVAL_ERROR);
		    die " System error, store failed";
	        }
	        my $timequery =  $self->processTime({timehash => $query->{time}});
	      
		  if($md_objects &&  (ref($md_objects) eq 'HASH') &&   %{$md_objects}) { 
	            foreach my $metaid  (sort { $a <=> $b} keys %{$md_objects}) {   
		        my $md =  $self->_ressurectMd( { md_row =>  $md_objects->{$metaid}});
		        if($self->_retriveDataByKey({key =>  $metaid,   timequery => $timequery, timeselects => $time_selects,
			                             metaids => $metaids, datas => $objects_hashref, response => $response}) ){
			    $response->addResultResponse({md => $md, message => 'no  matching data found',  eventType => $self->eventTypes->status->failure});		   
	                    return $response;
	                }
		    }		     
	        } else {
	            $response->addResultResponse({md => $requestmd, message => 'no metadata found',  eventType => $self->eventTypes->status->failure});		   
	        }  
            } else {
	        $response->addResultResponse({md =>$requestmd,  message => 'no key and no select in metadata  submitted',  eventType => $self->eventTypes->status->failure});    
	    }   
    
        if($objects_hashref && ref($objects_hashref) eq 'HASH') {
	    ############################################################   here add all those found data elements
           
            foreach my $metaid (keys %{$objects_hashref}) {     
	        if(%{$objects_hashref->{$metaid}}) { 
	            my $data  = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({id => "data". $response->dataID, metadataIdRef => "meta" . $metaids->{$metaid}});
	            foreach my $data_metaid (sort { $a <=> $b} keys %{$objects_hashref->{$metaid}}) {   
 	                foreach my  $timev (sort { $a <=> $b} keys %{$objects_hashref->{$metaid}->{$data_metaid}}) {   	         
                          $logger->debug(" What is data row :" .  Data::Dumper::Dumper $objects_hashref->{$metaid}->{$data_metaid}->{ $timev });
		          my $ctime = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new({ type => 'unix', value => $timev});
		       
		          foreach my $entry (qw/minRtt maxRtt medianRtt meanRtt clp iqrIpd lostPercent  maxIpd minIpd meanIpd duplicates outOfOrder/) {
		              next  unless  $objects_hashref->{$metaid}->{$data_metaid}->{ $timev }->{$entry};
		              my $value =  $objects_hashref->{$metaid}->{$data_metaid}->{ $timev }->{$entry};
		              my $datum = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new({name => $entry , value  =>  $value});
		              $ctime->addDatum($datum); 
	                  } 
		          $data->addCommonTime($ctime);
		        }
	            }
	            $response->addData($data); ## 
	            $response->add_dataID; 
	        } 
            } 
        }  
      
   
   return  $response;

}
#  auxiliary private function
#  check if setLimit was requested in the query
#  if not then set default 
#
sub _mdSetLimit {
    my $query = shift; 
    if($query  && ref($query) eq 'ARRAY' 
		       && $query->[0] &&  ref($query->[0]) eq 'HASH' 
		       && $query->[0]->{setLimit} && ref($query->[0]->{setLimit}) eq 'HASH'  
		       && $query->[0]->{setLimit}->{eq} && $query->[0]->{setLimit}->{eq} >= 1) {		    
       return   $query->[0]->{setLimit}->{eq};
    }
    return $_sizeLimit;
}
 
#
#  auxiliary private function
#  
#  accepting SQL row or metaID and will create md element for response and return it as object
#
#
sub _ressurectMd {
    my ($self, $params)  = @_; 
    my $logger  = get_logger( CLASSPATH ); 
    unless($params && ref($params) eq 'HASH' &&    ($params->{md_row} ||  $params->{metaID})) {
        $logger->error("Parameters missed:  md_row or metaID  are  required parameters");
        return ' Parameters missed:  md_row , timequery are required parameters';
    } 
    my $md = undef;
    
    if($params->{metaID}) {
        eval{
	    ($params->{metaID}, $params->{md_row})  = each %{$self->DBO->getMeta( [ 'metaID' , {'eq' => $params->{metaID}}], 1 )};
        };
	if($EVAL_ERROR)  {
	  $logger->logdie(" Fatal error while calling Rose::DB object query". $EVAL_ERROR);
	}
    } 
  
    my $metaid =  $params->{metaID};
    $md  = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new(); 
    my $key =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Key->new({id => "meta$metaid" });
   
    my $subject = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject->new({ id => "subj$metaid",
  		      endPointPair => perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair->new({		      
  		                          src => perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair::Src->new({ value =>  $params->{md_row}->{ip_name_src}, type => 'hostname'}),
     				          dst => perfSONAR_PS::Datatypes::v2_0::nmwgt::Message::Metadata::Subject::EndPointPair::Dst->new({ value =>  $params->{md_row}->{ip_name_dst}, type => 'hostname'})
     				      }) 
     		  });		  
     
    my $pinger_params =   perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Parameters->new({ id => "params$metaid" });
    my $param_arrref = []; 
    no strict 'refs';
      
    foreach my $pparam (qw/count packetSize ttl transport packetInterval protocol/) { 
        if($params->{md_row}->{$pparam}) {
  	   push @{$param_arrref} , perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter->new({name =>  $pparam , value => $params->{md_row}->{$pparam}});
        }
    }
    use strict;
    $md->subject($subject); 
    if($param_arrref && @{$param_arrref}) {
        $pinger_params->parameter($param_arrref);
        $md->parameters($pinger_params);
    }
    $md->key($key); 
    return $md;   
}
#  auxiliary private  function
#
#  _createTimeSelect
#
#  creates time range select metadata and store it for reuse in timeselects hashref
#
sub _createTimeSelect {
    my ($self, $params) = @_; 
    my $logger  = get_logger( CLASSPATH ); 
    unless($params->{timequery} && (ref($params->{timequery}) eq 'HASH') && $params->{response} && $params->{timeselects} ) {
        $logger->error("Parameters missed:    timequery,  response and timeselects are  required parameters");
        return ' Parameters missed:  timequery,  response and timeselects are required parameters';
    } 
    my $id = $params->{timequery}->{eq}?"eq=".$params->{timequery}->{eq}:"lt=".$params->{timequery}->{lt}."_gt=".$params->{timequery}->{gt};
   
    return $params->{timeselects}{$id}{md} if($params->{timeselects}{$id} &&  $params->{timeselects}{$id}{md});
    my $selects = [];
    if($params->{timequery}->{eq}) {
        push @{$selects} , perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter->new({name => 'timeStamp', value =>  $params->{timequery}->{eq}});
    } elsif($params->{timequery}->{gt} && $params->{timequery}->{lt}) {
        push @{$selects} , perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter->new({name => 'startTime', value =>  $params->{timequery}->{gt}});
        push @{$selects} , perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Parameters::Parameter->new({name => 'endTime', value =>  $params->{timequery}->{lt}});
    }  
    if($selects  && @{$selects}) {
        my $md =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new();
	$md->subject(perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Subject->new({id => "subj" .  $params->{response}->mdID}));
	
        my $param_selects = perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters->new({ id => "params".$params->{response}->mdID,   parameter => $selects});
  	$md->parameters($param_selects); 
	$logger->debug("--------- Created New time select: ". $md->asString);
        $params->{timeselects}{$id}{md} = $params->{response}->addIDMetadata($md,  $self->eventTypes->ops->select);  
	return   $params->{timeselects}{$id}{md}; 
    } 
    return undef;
}


#
#  auxiliary private  function
#
#  this one will find time range from md, find proper list of data tables and will query data tables by metaID key
#  parameters - hashref to { md => $metadata_obj, datas => $iterators_attayref, key => $metaKey, timequery => $timequery_hashref, tables => $tables_hashref, response => response}
#  return 0 if everything OK, result will be added as data objects arrayref to the {datas} arrayref
#  return 1 if something is wrong
#
sub _retriveDataByKey {
    my ( $self, $params)  = @_; 
    my $logger  = get_logger( CLASSPATH );  
    unless($params && ref($params) eq 'HASH' && ($params->{key} || ($params->{md} && blessed $params->{md}))  && 
           $params->{response} && blessed $params->{response} && $params->{metaids} && $params->{datas} && $params->{timeselects}) {
        $logger->error("Parameters missed:  md,response,iterators,metaids,timeselects are required parameters");
        return -1;
    } 
    my $keyid = $params->{key}?$params->{key}:($params->{md} && blessed $params->{md})?$params->{md}->key->id:$logger->(" md or key MUST be provided");
    return ' Key parameter  missed ' unless $keyid;
    $params->{timequery}= $self->processTime( { element => $params->{md} } ) unless  $params->{timequery};
        
    unless( $params->{timequery} && ref($params->{timequery} ) eq 'HASH') {
        $logger->error("No time range in the query found");
        $params->{response}->addResultResponse({ md =>  $params->{md}, message =>  'No time range in the query found' ,  eventType => $self->eventTypes->status->failure});	
        return -1;
    } 
 
    my @timestamp_conditions = map { ('timestamp' => { $_ => $params->{timequery}->{$_} } )} keys %{$params->{timequery}};     
    my  $iterator_local =  $self->DBO->getData( [ metaID => {eq =>  $keyid},  @timestamp_conditions], undef, $_sizeLimit);
    if(%{$iterator_local}) {
        $params->{datas}->{$keyid} = $iterator_local;
        my $idref = $self->_createTimeSelect( $params );
	$logger->debug(" Created Time Select ..... ......id=$idref");	 
	my $pinger_md = $self->_ressurectMd({metaID =>  $keyid});
	$pinger_md->metadataIdRef($idref) if $idref; 
	$params->{metaids}->{$keyid} =   $params->{response}->addIDMetadata($pinger_md,  $self->eventTypes->tools->pinger); 
        return 0;
    } 
    return -1;
    
}
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)   2007-2008

=cut
}

1;
