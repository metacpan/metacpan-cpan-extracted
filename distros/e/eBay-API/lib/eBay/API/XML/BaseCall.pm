#!/usr/bin/perl -w

package eBay::API::XML::BaseCall;

use strict; 
use warnings;

###############################################################################
#
# Module: ............... <user defined location>eBay/API/XML
# File: ................. BaseCall.pm
# Original Author: ...... Milenko Milanovic
# Last Modified By: ..... Robert Bradley / Jeff Nokes
# Last Modified: ........ 03/06/2007 @ 16:28
#
# Description: This is a super class for all eBay API calls. 
#
#   It contains properties common for all calls.
#   It assembles request based on properties set.
#   It submitis the HTTP request to the API server.
#   It handles call retries (if retries are enabled by a programmer).
#   It parses received HTTP response.
#   It handles both HTTP connection errors and API errors.
#
###############################################################################

=head1 NAME

eBay::API::XML::BaseCall

=head1 INHERITANCE

eBay::API::XML::BaseCall inherits from the L<eBay::API::XML::BaseCallGen> class

=cut

# Need to sub the Exporter class, to use the EXPORT* arrays below.
use Exporter;
use eBay::API::XML::BaseCallGen;   # parent class
our @ISA = ('Exporter'
	     ,'eBay::API::XML::BaseCallGen');  # Parent class 

use LWP::UserAgent;
use HTTP::Request; 
use HTTP::Headers; 
#use XML::Simple qw(:strict);
#  Do not use XML::Simple 'strict' mode because if you use it, 
#  it gets global for the
#  whole application within apache. Most often we do not use
#    forcearray and keyattr attributes in XML::Simple
#           $rhXmlSimple = XMLin ( $sRawXml
#	                  , forcearray => []
#	  	          , keyattr => [] 
#	           );
use XML::Simple;
use Data::Dumper;
use Time::HiRes qw(sleep);
use Compress::Zlib;
use XML::Tidy;

use eBay::API;
use eBay::API::XML::DataType::XMLRequesterCredentialsType;
use eBay::API::XML::DataType::ErrorType;
use eBay::API::XML::DataType::Enum::SeverityCodeType;
use eBay::API::XML::DataType::Enum::ErrorClassificationCodeType;

# Variable Declarations
# # -----------------------------------------------------------------------
# # Constants
#

use constant _TRUE_  => scalar 1;
use constant _FALSE_ => scalar 0;

use constant HTTP_ERRORCODE_PREFIX => scalar 'HTTP';                 #API001
use constant XML_PARSE_ERROR       => scalar 'XML_PARSE_ERROR';      #API004
use constant NO_RESPONSE_CONTENT    => scalar 'NO_RESPONSE_CONTENT';   # API002
use constant BAD_API_GATAWAY        => scalar 'BAD_API_GATAWAY';       # API003
use constant XML_PARSE_RESULT_EMPTY => scalar 'XML_PARSE_RESULT_EMPTY';# API005

use constant XML_OLD_TYPE_RESPONSE => scalar 'XML_OLD_TYPE_RESPONSE';

=head1 Methods

=head2 new()

See the parent constructor for detailed docs about object instantiation 

=cut

sub new($;$;) {

   my $classname = shift;
   my $arg_hash = shift;
   my $self = $classname->SUPER::new($arg_hash);

   # this allow me to introduce a "reset" method
   #  which will allow as to reuse a call instance
   $self->_init();

   return $self;
}

sub _init {

   my $self = shift;

   $self->{'pRequest'}  = undef;
   $self->{'pResponse'} = undef;

   $self->{'pHttpResponse'}      = undef;
   $self->{'isResponseValidXml'} = undef;
   $self->{'rhXmlSimple'}        = undef;
     # if externalySetRequestXml is defined
     #    then use it to submit the call
   $self->{'externalySetRequestXml'} = undef;
     # if 'hasForcedError' is set then do not execute the call
     #   just return the error set with 'forcedError' method
   $self->{'hasForcedError'} = undef;

    
   $self->_initRequest();
   $self->_initResponse();
}

=head2 reset()

Use 'reset' method in cases when you want to reuse a Call instance

=cut

sub reset {
   my $self = shift;
   $self->_init();   
}


=head2 execute()

Executes the current API call

=cut

sub execute {
  
  my $self = shift;
  
    #
    #  1. create HTTP::Request
  my $objRequest = $self->_getHttpRequestObject();

    #  
    #  2. create UserAgent
  my $objUserAgent = LWP::UserAgent->new();

  # Purposely overwrite the UserAgent property, with one identifying
  # eBay Perl SDK.
    $objUserAgent->agent(
       $objUserAgent->agent . ' / ' .
       'eBay API Perl SDK (Version: ' . $eBay::API::VERSION . ')'
    );

          # timeout in seconds
  my $timeout = $self->getTimeout();
  if ( defined $timeout ) {
     $objUserAgent->timeout($timeout);
  }

  $self->_submitHttpRequest( $objUserAgent, $objRequest );

}

sub _getHttpRequestObject {
	
  my $self = shift;
  
     # 1. what URL the call will be submitted to
  my $sApiUrl = $self->getApiUrl();
    #  
    #  2. create HTTP::Request object and fill it with all parameters
  my $objHeader = $self->_getRequestHeader();

    #  3. get XML string that will be sent to the URL
  my $requestRawXml = $self->getRequestRawXml();

    #  4. create request that will be submitted to the URL
  my $objRequest = 
        HTTP::Request->new("POST"
		           , $sApiUrl
			   , $objHeader, $requestRawXml); 

  return $objRequest;
}

=head2 getHttpRequestAsString()

Arguments: 1 [O] - isPrettyPrint - if set then XML is pretty printed

Returns: string
        Method returning a textual representation of the request
	  (request type, url, query string, header and content).

=cut

sub getHttpRequestAsString {
  my $self = shift;
  my $isPrettyPrint = shift || 0;

  my $pHttpRequest = $self->_getHttpRequestObject();

  my $str = undef;
  if ( $isPrettyPrint ) {
        $str = $self->_prettyPrintFormat( $pHttpRequest );
  } else {
        $str = $pHttpRequest->as_string();
  }
  return $str;
}

sub _submitHttpRequest($$$;) {

  my $self         = shift;
  my $objUserAgent = shift;
  my $objRequest   = shift;

  ###
  #
  #  We use this complex LOOP IN ORDER TO BE ABLE TO HANDLE RETRIES
  #
  ###

  my $maxNumberOfTries = 1;
  my $pCallRetry = $self->getCallRetry();
  if ( defined $pCallRetry ) {
     $maxNumberOfTries =  $pCallRetry->getMaximumRetries() + 1;
  }

  my $currentTry = 0;
  my $exitLoop = _FALSE_;

       #
       # If forced error is set, do not execute the call. See 'forceError' method.
       # This is used only for test purposes.
       # 
  if ( $self->hasForcedError() ) {
      $self->logMessage(eBay::API::BaseApi::LOG_DEBUG
                        ,"Error forced, request has not been sent to the API server\n");
      return;
  }

  while ( ! $exitLoop ) {   ## START retry LOOP

    #  1. send request to the URL ( API server )
    my $objHttpResponse = $objUserAgent->request($objRequest); 

    #  2.  process response
    $self->processResponse ( $objHttpResponse );

    #  3. check whether we should retry the call
           # Exit loop if
	   #    a) maxNumberOfTries has been reached 
	   #         - meaning that all tries failed
	   #    b) pCallRetry is not defined  
	   #         - meaning that call is supposed to be execute only once

    $currentTry++;			       

    if ( ($currentTry >= $maxNumberOfTries)
	 || (! $self->hasErrors() && ! $self->hasWarnings())
	 || (! defined $pCallRetry) ) {
		   
       $exitLoop = _TRUE_;
    } else {

       my $shouldRetry = $pCallRetry->shouldRetry(
	                     # ref to an array of ErrorDataType objects
			     #  check out both, errors and warnings
       			   'raErrors' => $self->getErrorsAndWarnings()
		        );

       if ( $shouldRetry ) {

	  my $pause = $pCallRetry->getDelayTime();
	  sleep $pause/1000;   ## Time::HiRes sleep  in miliseconds

	  $exitLoop = _FALSE_;

          $pCallRetry->incNumberOfRetries();
       } else {
	  $exitLoop = _TRUE_;
       }
    }
  }   ## END retry LOOP
}

sub _getRequestHeader {
  
  my $self = shift;
  my $sCallName = $self->getApiCallName();
  if ( ! defined $sCallName ) {
    print "\nAPI call not set!!!\n";
    print "'GetApiCallName' method must be implemented in " 
    					. ref($self) . ".pm!\n\n";
    return;
  }
	
  # common call properties
  my $sSiteId   = $self->getSiteID();

  my $sClLevel  = $self->getCompatibilityLevel();
  my $sDevName  = $self->getDevID();
  my $sAppName  = $self->getAppID();
  my $sCertName = $self->getCertID();


    # 
    #  set header values
  my $objHeader = HTTP::Headers->new(); 

  $objHeader->push_header('X-EBAY-API-COMPATIBILITY-LEVEL' => $sClLevel); 
  $objHeader->push_header('X-EBAY-API-SESSION-CERTIFICATE' =>
  					"$sDevName;$sAppName;$sCertName"); 
  $objHeader->push_header('X-EBAY-API-DEV-NAME' => $sDevName); 
  $objHeader->push_header('X-EBAY-API-APP-NAME' => $sAppName); 
  $objHeader->push_header('X-EBAY-API-CERT-NAME' => $sCertName); 
  $objHeader->push_header('X-EBAY-API-CALL-NAME' => $sCallName); 
  $objHeader->push_header('X-EBAY-API-SITEID' => $sSiteId); 
  $objHeader->push_header('Content-Type' => 'text/xml'); 
  if ($self->isCompression()) {
    $objHeader->push_header('Accept-Encoding' => 'gzip'); 
  }
  
  return $objHeader;
}

sub _setRequestDataType {
  my $self = shift;
  $self->{'pRequest'} = shift;
}

=head2 getRequestDataType()

Returns the RequestDataType object, 

=cut

sub getRequestDataType {
  my $self = shift;
  return $self->{'pRequest'};
}

sub _setResponseDataType {
  my $self = shift;
  $self->{'pResponse'} = shift;
}

=head2 getResponseDataType()

Returnst the ResponseDataType object
=cut

sub getResponseDataType {
  my $self = shift;
  return $self->{'pResponse'};
}

sub _setHttpResponseObject {
  my $self = shift;
  $self->{'pHttpResponse'} = shift;
}

sub _getHttpResponseObject {
  my $self = shift;
  return $self->{'pHttpResponse'};
}

=head2 isHttpRequestSubmitted()

Tells to a programmer whether a request has been submitted or not.
This method is mainly used in Session in sequential mode.

=cut

sub isHttpRequestSubmitted {
  my $self = shift;
  my $objHttpResponse = $self->_getHttpResponseObject();
  if ( defined $objHttpResponse ) {
    return 1;
  }
  return 0;
}

=head2 getHttpResponseAsString()

Method returning a textual representation of the response

  Arguments: 1 [O] - isPrettyPrint - if set then XML is pretty printed
  Returns: string

=cut

sub getHttpResponseAsString {

  my $self = shift;
  my $isPrettyPrint = shift || 0;

  my $objHttpResponse = $self->_getHttpResponseObject();

  my $str = undef;
  if ( defined $objHttpResponse ) {
      if ( $isPrettyPrint ) {
            $str = $self->_prettyPrintFormat( $objHttpResponse );
      } else {
            $str = $objHttpResponse->as_string();
      }
  } else {
     $str = "HttpResponseAsString is not available since the API call " . 
                      "has not been executed yet!";
     if ($self->hasForcedError()) {
         $str .= "\nError forced, request has not been sent to the API server.";
     }
  }
  return $str;
}

=head2 getResponseRawXml()

Method returning the raw XML reponse

=cut

sub getResponseRawXml {
  my $self = shift;
  my $pHttpResponse = $self->_getHttpResponseObject();
  
  my $str = '';
  if ( defined $pHttpResponse ) {
     $str = $pHttpResponse->content();
     my $contentEncoding = $pHttpResponse->content_encoding;
     if ( defined $contentEncoding && $contentEncoding =~ /gzip/i) {
       $str = Compress::Zlib::memGunzip($str);
     }
  }
  return $str;
}

sub _setXmlSimpleDataStructure {
  my $self = shift;
  $self->{'rhXmlSimple'} = shift;
}

=head2 getXmlSimpleDataStructure()

Returns XML::Simple data structure for a given path.
Path is defined as a reference to an array of node names, starting with 
the top level node and ending with lowest level node.

Path IS NOT an XPATH string!!!!

Path examples for VerifyAddItem call:
  
  @path = ( 'Fees','Fee' );   # Returns fees as an XML::Simple data structure
  @path = ( 'Errors' );       # Returns Response errors as an XML::Simple 
                              #    data structure
  @path = ( 'Errors-xxxx' );  # Will not find anything

Notice that root node is not being specified. The reason for that is that 
we XML::Simple is configured not to put root node into its data structure
(that is a default behaviour for XML::Simple).

If path is not submitted return the whole XML::Simple data structure

=cut

sub getXmlSimpleDataStructure {
  my $self   = shift;
  my $raPath = shift;

  my $rhXmlSimple = $self->{'rhXmlSimple'};
  if ( ! defined $raPath ) {
     return $rhXmlSimple;
  }

  my $rhNode = $rhXmlSimple;
  foreach my $key (@$raPath) {
    $rhNode = $rhNode->{$key};	  
    if ( ! defined $rhNode ) {
       last;
    }
  }

  return $rhNode;
}

# _setResponseValidXml()
# Sets whether a response is a valid XML document or not.

sub _setResponseValidXml {
  my $self = shift;
  $self->{'isResponseValidXml'} = shift;
}

=head2 isResponseValidXml()

Access: public
Returns: true (1) if a response is a valid XML document or not.
         false (0) if a response is NOT a valid XML document or not.
Note: 
  It allows us to differentiate cases the following cases:
    a) Response is a valid XML with API errors
    b) Response is not a valid XML document at all 
         or HTTP connection failed.
  Most likely it should not be used a lot.

=cut 

sub isResponseValidXml {
  my $self = shift;
  
  my $value = $self->{'isResponseValidXml'};
  if ( defined $value && $value == 1 ) {
    return _TRUE_;
  }
  return _FALSE_;
}

sub _addError {
  my $self = shift;
  my $pError = shift;
   
  my $pResponse = $self->getResponseDataType();
  my $raErrors = $pResponse->getErrors();

  if ( ! defined $raErrors ) {
    $raErrors = [];
  }
  push @$raErrors, $pError;
  $pResponse->setErrors( $raErrors );
}

=head2 hasErrors()

If an API call return errors (API, HTTP connection or XML parsing errors)
the application should stop normal processing and return a "system error"
message to an application user. The only things that it makes sense to read 
from ResponseDataType objects are: errors and rawResponse (which in this case 
might not even be a valid XML document).

=cut

sub hasErrors {
  my $self = shift;
  return $self->_hasErrorsForSeverityCode(
	  eBay::API::XML::DataType::Enum::SeverityCodeType::Error);
}

=head2 hasWarnings()

Return true if the API has errors.

=cut

sub hasWarnings {
  my $self = shift;
  return $self->_hasErrorsForSeverityCode(
          eBay::API::XML::DataType::Enum::SeverityCodeType::Warning);
}

=head2 getErrors()

Returns: a reference to an array of errors (it can retu
This method overrides BaseCallGen::getErrors method, while _getResponseErrors is basically 
the same method that exists in BaseCallGen

=cut

sub getErrors {
  my $self = shift;
  return $self->_getErrorsForSeverityCode(
	  eBay::API::XML::DataType::Enum::SeverityCodeType::Error);
}

=head2 getWarnings()

Return a reference to an array of warnings

=cut

sub getWarnings {
  my $self = shift;
  return $self->_getErrorsForSeverityCode(
	  eBay::API::XML::DataType::Enum::SeverityCodeType::Warning);
}

# _hasErrorsForSeverityCode()
sub _hasErrorsForSeverityCode {

  my $self = shift;	
  my $severityCode = shift;
  
  my $raErrors = $self->_getResponseErrors();
  
  my $hasErrors = 0;
  if ( defined $raErrors ) {
    foreach my $pError (@$raErrors) {

      my @keys = keys ( %$pError );
      if ( (scalar @keys) == 0 ) {
         $hasErrors = 1;
         last;
      } 

      if ( $pError->getSeverityCode() eq $severityCode ) {
         $hasErrors = 1;
         last;
      }
    }
  }
  return $hasErrors;
}

# _getErrorsForSeverityCode()
sub _getErrorsForSeverityCode {

  my $self = shift;	
  my $severityCode = shift;
  
  my $raErrors = $self->_getResponseErrors();
  
  my @aErrors = ();
  if ( defined $raErrors ) {
    foreach my $pError (@$raErrors) {
      if ( $pError->getSeverityCode() eq $severityCode ) {
    	 push @aErrors, $pError;
      }
    }
  }
  return wantarray ? @aErrors : \@aErrors;
}

=head2 getErrorsAndWarnings() 

Returns: reference to an array

Array contains all errors returned by API call, regardless of SeverityCode
Includes both SeverityCodes: 'Error' and 'Warning'

=cut

sub getErrorsAndWarnings() {
  my $self = shift;
  return $self->_getResponseErrors();
}

=head2 hasError() 

Arguments: [0] [R] - errorCode

Returns:    1 - if an error with the given error code is found
            0 - if no error with the given error code is returned

  my $boolean = $self->hasError( '304' );
  
=cut

sub hasError {
	
   my $self = shift;
   my $sErrorCode = shift;

   my $yes = 0;
   my $raErrors = $self->getErrorsAndWarnings();
   foreach my $pError ( @$raErrors ) {
       if ( $sErrorCode eq $pError->getErrorCode() ) {
          $yes = 1;
	  last;	  
       }	       
   }   

   return $yes;
}

###############################################################################
# Response getters(only): output values  
###############################################################################

# _getResponsErrors()
#      
# type: 'ns:ErrorType'
#    setter expects: array or reference to an array 
#    getter returns: reference to an array  
#                     of 'ns:ErrorType'
#
sub _getResponseErrors {
  my $self = shift;
  return $self->getResponseDataType()->getErrors();
}


=head2 getEBayOfficialTime()

Returns the officaial eBay time.

  2008-07-03T23:46:36.234Z
  
=cut

#      
# type: 'xs:dateTime'
#
#
sub getEBayOfficialTime {
  my $self = shift;
  return $self->getResponseDataType()->getTimestamp();
}

###############################################################################
# Methods
###############################################################################

# _prettyPrintFormat()
#
# Arguments: 1 [R] pHttpR - either an HTTP::Request or HTTP:Response object
# Description: Formats HTTP::Request/HTTP::Response as a string.
#            Includes: header and content.
#            XML content is pretty printed.

sub _prettyPrintFormat {

    my $self = shift;
    my $pHttpR = shift;     # either HTTP::Request or HTTP::Response object

    my $sContent    = $pHttpR->content();
    my $sEverything = $pHttpR->as_string();

    my $str = '';
    my $pTidy = XML::Tidy->new('xml' => $sContent);
    my $tidyStrContent = '';
    eval {
        $pTidy->tidy();
        $tidyStrContent = $pTidy->toString();
    };
    my $ndx = index($sEverything, '<?xml');
    my $sHeader = '';
    if ( $ndx >= 0) {
        $sHeader = substr($sEverything, 0, $ndx);
    }
    $str = $sHeader . $tidyStrContent;
    return $str;
}

=head2 setRequestRawXml()
  
Method for setting some raw xml content to be used for the request.

  my $call = new eBay::API::XML::Call::FetchToken(
      site_id => 0,
      proxy   => __API_URL__,
      dev_id  => __DEVELOPER_ID__,
      app_id  => __APPLICATION_ID__,
      cert_id => __CERT_ID__,
      user_auth_token => __AUTH_TOKEN__, 
  );
  
  $call->setRequestRawXml('<?xml version="1.0" encoding="UTF-8"?>
      <FetchTokenRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      <SecretID>
        R2n6MQr@LDMAABeDFY8.1025449191.1198127665.563330
      </SecretID>
      <RequesterCredentials><Username>__USERNAME__</Username>
      </RequesterCredentials>
      </FetchTokenRequest>'
  );

  $call->execute();
  print $call->getResponseRawXml();
  
=cut

sub setRequestRawXml {
   my $self = shift;
   $self->{'externalySetRequestXml'} = shift;
}

=head2 getRequestRawXml()

Method returning the raw XML request content

=cut

sub getRequestRawXml {
 
  my $self = shift;

     # 
     # externaly set Request Xml should be used only for testing purposes
     # 
  my $sExternalySetRequestXml = $self->{'externalySetRequestXml'};
  if ( defined $sExternalySetRequestXml ) {
    return $sExternalySetRequestXml;
  }
  
     # Assemble Request Xml
  my $pRequest = $self->getRequestDataType();

      # 1. START set credentials 
  my $pRequesterCredentials = 
        eBay::API::XML::DataType::XMLRequesterCredentialsType->new();


 # We should always be submitting either token or (username, password) pair, NEVER BOTH
 # The default (username, password) values should be used for anonymous calls only!
  my $sAuthToken = $self->getAuthToken();
  if ( defined $sAuthToken && $sAuthToken ne '' ) {
	 $pRequesterCredentials->setEBayAuthToken($sAuthToken);
  } else {
   	 $pRequesterCredentials->setUsername($self->getUserName());
   	 $pRequesterCredentials->setPassword($self->getUserPassword());
  }	  

  $pRequest->setRequesterCredentials($pRequesterCredentials);
  
      # 1. END set credentials 

  my $sCallName = $self->getApiCallName() . 'Request';
  my $strXml    = $self->{'pRequest'}->serialize($sCallName);

  return $strXml;
}

# _initRequest()
sub _initRequest {  

  my $self = shift;

  my $sRequestDataFullPackage = $self->getRequestDataTypeFullPackage();
  if ( ! defined $sRequestDataFullPackage ) {
    # Errors like this one should be cought during the development.
    print "requestDataTypeFullPackage not set!!!\n";
    print "'getRequestDataTypeFullPackage' method must be implemented in " 
    					. ref($self) . ".pm!\n\n";
    return;
  }
   my $pRequest = $sRequestDataFullPackage->new();

   $self->_setRequestDataType($pRequest);
}

# _initResponse()
sub _initResponse {  

  my $self = shift;

  my $sResponseDataFullPackage = $self->getResponseDataTypeFullPackage();
  if ( ! defined $sResponseDataFullPackage ) {
    # Errors like this one should be cought during the development.
    print "responseDataTypeFullPackage not set!!!\n";
    print "'getResponseDataTypeFullPackage' method must be implemented in " 
    					. ref($self) . ".pm!\n\n";
    return;
  }
   my $pResponse = $sResponseDataFullPackage->new();

   $self->_setResponseDataType($pResponse);
}

=head2 forceError()

This method is used to force a given error when a call is being executed.
If the forced error is set, then that error is being returned by the call
without executing the call (sending request to the API Server and receiving 
the response.

This method is used for test purposes when a programmer wants to test
how the application handles an API error.

Arguments: This method uses named argument calling style that looks like this:
            
  $self->forceError ( sErrorCode => '1025', sShortMsg => 'Test API error', ... );

       Required arguments
           1 - sErrorCode - API error code
           2 - sShortMsg  - short error message
           3 - sLongMsg   - long error message
       Optional arguments
           4 - sSeverityCode - severity code
                 default severity code:
                     eBay::API::XML::DataType::Enum::SeverityCodeType::Error
           5 - sErrorClassificationCode - error classification code
                 default error classification code
                     eBay::API::XML::DataType::Enum::ErrorClassificationCodeType::SystemError

Example:
  
  $call->forceError (
    'sErrorCode' => '1025'
    ,'sShortMsg' => 'Test error short message'
    ,'sLongMsg' => 'Test error long message'
  );

=cut 

sub forceError {
   my $self = shift;
   my %args = @_;

   my $sErrorCode = $args{'sErrorCode'};
   my $sShortMsg  = $args{'sShortMsg'};
   my $sLongMsg   = $args{'sLongMsg'};
   my $sSeverityError = 
        $args{'sSeverityCode'} 
                || eBay::API::XML::DataType::Enum::SeverityCodeType::Error;
   my $sErrorClassificationCode = 
        $args{'sErrorClassificationCode'} 
                || eBay::API::XML::DataType::Enum::ErrorClassificationCodeType::SystemError;

   my $pError = eBay::API::XML::DataType::ErrorType->new();
   $pError->setShortMessage ( $sShortMsg );
   $pError->setErrorParameters ( [] );
   $pError->setErrorCode( $sErrorCode );
   $pError->setSeverityCode( $sSeverityError );
   $pError->setLongMessage ( $sLongMsg );
   $pError->setErrorClassification ( $sErrorClassificationCode );

   $self->_addError( $pError );
        # signal that we want to force an error.
   $self->{'hasForcedError'} = 1;
}

sub hasForcedError {
    my $self = shift;
    return $self->{'hasForcedError'};
}

=head2 processResponse()

Method resonsible for process the http response when it arrives.

=cut

sub processResponse {
   my $self = shift;
   my $objHttpResponse = shift;

   # 1. retrieve response content
   #    if gziped - unzip it
   my $contentEncoding = $objHttpResponse->content_encoding;
   my $sRawXml= $objHttpResponse->content();
   if (defined $contentEncoding && $contentEncoding =~ /gzip/i) {
       $sRawXml = Compress::Zlib::memGunzip ( $sRawXml );
   }

   $self->_setHttpResponseObject( $objHttpResponse );

   #print $sRawXml;

   my $pResponse = $self->getResponseDataType();

   my $isHttpError = $objHttpResponse->is_error;

       # 3. process response
       
   if (! $isHttpError ) {    # 3.1. process HTTP response when when we 
	                     #      DO NOT HAVE HTTP connection errors

      my $ok = 1;			     
      $ok = $self->_handleNoResponseContent ( \$sRawXml );
      if ( ! $ok ) {
         $self->_setResponseValidXml( _FALSE_);
         return;	      
      }

      $ok = $self->_handleApiBadGataway ( \$sRawXml );
      if ( ! $ok ) {
         $self->_setResponseValidXml( _FALSE_);
         return;	      
      }

      my $rhXmlSimple;

          # I.1. parse the raw response
      eval {
           $rhXmlSimple = XMLin ( $sRawXml
	                  , forcearray => []
	  	          , keyattr => [] 
	           );
      };

      if ( $@ ) {     # I.2. OOPS, parsing failed - response is not 
	              #                            a valid XML document
          $self->_setResponseValidXml( _FALSE_);

	  #print Dumper($sRawXml);
	  my $longMsg   = "error [$@] while parsing response xml [$sRawXml]";
	  my $shortMsg  = $!;
	  my $errorCode = XML_PARSE_ERROR;

          $self->_addHTTP_XMLParse_Error (
                        'shortMsg'  => $shortMsg
                        ,'longMsg'   => $longMsg
                        ,'errorCode' => $errorCode
   					 );
      } else {        # I.3. raw response is a valid XML document, 
	              #      deserialize it to the response

          $self->_setResponseValidXml( _TRUE_);

	  $ok = $self->_handleResposeParsedButStructureEmpty (
	                                     \$sRawXml, $rhXmlSimple );
	  if ( ! $ok ) {
	     return;	      
	  }

          $self->_setResponseValidXml( _TRUE_);

	  $self->_setXmlSimpleDataStructure( $rhXmlSimple );

             #print Dumper $rhXmlSimple;
          $pResponse->deserialize('rhXmlSimple' => $rhXmlSimple );
             #print Dumper $pResponse;

	  #            I.3.1 OLD TYPE XML RESPONSE
	  #   see method description
          #

	  $self->_handleIfItIsOldStyle();
      }
   } else {                  # 3.2. process HTTP response when we HAVE 
	                     #      HTTP connection errors
         # since this was a connectin error, raw response cannot be 
	 # a valid XML document
      $self->_setResponseValidXml( _FALSE_);

      #print $objHttpResponse->error_as_HTML; 
      #print Dumper( $objHttpResponse);

      my $shortMsg = $objHttpResponse->status_line();
      my $longMsg  = $shortMsg;
      my $errorCode = HTTP_ERRORCODE_PREFIX . $objHttpResponse->code();

      $self->_addHTTP_XMLParse_Error (
                        'shortMsg'  => $shortMsg
                        ,'longMsg'   => $longMsg
                        ,'errorCode' => $errorCode
   				 );
   } 
}

# _handleNoResponseContent()
sub _handleNoResponseContent {

   my $self     = shift;
   my $rsRawXml = shift;

   my $sRawXml = $$rsRawXml;

   my $ok = 1;
   if ( ! $sRawXml ) {

      my $longMsg   = 'No response content !';
      my $shortMsg  = $longMsg;
      my $errorCode = NO_RESPONSE_CONTENT;
      $self->_addHTTP_XMLParse_Error (
                  'shortMsg'  => $shortMsg
                  ,'longMsg'   => $longMsg
                  ,'errorCode' => $errorCode
		 );
      $ok = 0;		 
   }
   return $ok;
}

# _handleApiBadGataway()
sub _handleApiBadGataway {

   my $self     = shift;
   my $rsRawXml = shift;

   my $sRawXml = $$rsRawXml;

      #  'Bad Gataway' ERROR
      #    Check for error HTML response from the gateway.
      #    If it begins with DOCTYPE or it begins with an html block

   my $isBadApiGateway = 0;
   if ( $sRawXml =~ m{^\s*<!DOCTYPE} or $sRawXml =~ m{^\s+<HTML}i ) {   
      $isBadApiGateway = 1
   }

   my $ok = 1;
   if ( $isBadApiGateway ) {

	  my $longMsg   = "Bad API gateway, [$sRawXml] !";
	  my $shortMsg  = 'Bad API gateway';
	  my $errorCode = BAD_API_GATAWAY;
          $self->_addHTTP_XMLParse_Error (
                        'shortMsg'  => $shortMsg
                        ,'longMsg'   => $longMsg
                        ,'errorCode' => $errorCode
   					 );
       $ok = 0;
   }
   return $ok;
}

# _handleResposeParsedButStructureEmpty()
sub _handleResposeParsedButStructureEmpty {

   my $self        = shift;
   my $rsRawXml    = shift;
   my $rhXmlSimple = shift;

   my $sRawXml = $$rsRawXml;

      # xml contains no useful data ( everything is comment??
      #                               try that as a test case )

   my $ok = 1;
   my $isEmpty =  (! $rhXmlSimple)
                  || (! ref($rhXmlSimple));
   if ( ! $isEmpty ) {		  
	    
      if ( ref($rhXmlSimple) eq 'HASH' ) {
         my @keys = keys %$rhXmlSimple;
         if ( (scalar @keys) == 0 ) {
            $isEmpty = 1;
         }      
      }	   
   }

   if ( $isEmpty ) {

	  my $longMsg   = "no data from response xml [$sRawXml]";
	  my $shortMsg  = 'no data from response xml';
	  my $errorCode = XML_PARSE_RESULT_EMPTY;
          $self->_addHTTP_XMLParse_Error (
                        'shortMsg'  => $shortMsg
                        ,'longMsg'   => $longMsg
                        ,'errorCode' => $errorCode
   					 );
       $ok = 0;
   }
   
   return $ok;
}

# _addHTTP_XMLParse_Error()
sub _addHTTP_XMLParse_Error {
   my $self = shift;
   my %args = @_;

   my $shortMsg  = $args{'shortMsg'};
   my $longMsg   = $args{'longMsg'};
   my $errorCode = $args{'errorCode'};

   my $pError = eBay::API::XML::DataType::ErrorType->new();
   _populateHTTP_XMLParse_Error(
                       'pError'    => $pError
                      ,'shortMsg'  => $shortMsg
                      ,'longMsg'   => $longMsg
                      ,'errorCode' => $errorCode
	   		);
   $self->_addError( $pError );			     
}

# _populateHTTP_XMLParse_Error()
sub _populateHTTP_XMLParse_Error {

   my %args = @_;

   my $pError    = $args{'pError'};
   my $shortMsg  = $args{'shortMsg'};
   my $longMsg   = $args{'longMsg'};
   my $errorCode = $args{'errorCode'};

   $pError->setShortMessage ( $shortMsg );
   $pError->setErrorParameters ( [] );
   $pError->setErrorCode( $errorCode );
   $pError->setSeverityCode( 
      eBay::API::XML::DataType::Enum::SeverityCodeType::Error
                           );
   $pError->setLongMessage ( $longMsg );
   $pError->setErrorClassification ( 
      eBay::API::XML::DataType::Enum::ErrorClassificationCodeType::SystemError
			     );
}

# _handleIfItIsOldStyle()
sub _handleIfItIsOldStyle {

   my $self = shift;

	  #            I.3.1 OLD TYPE XML RESPONSE
	  #  If an empty XML string is submitted, then an old type
	  #   XML response is returned. Such response returns errors 
	  #   which are in the old format. Those errors do not make any
	  #   sense anyways so just replace them with a new one which really
	  #   says what has happend.
	  #
   my $ok = 1;	  
   my $raErrors = $self->_getResponseErrors();
   if ( defined $raErrors ) {

      foreach my $pError (@$raErrors) {

         my @keys = keys ( %$pError );
	    # If we have errors but such errors do not have keys
	    # that means that an old style response is returned.
            #  Add a new error message
         if ( (scalar @keys) == 0 ) {

            my $shortMsg = 'old type XML response';
            my $longMsg = <<"OLD_TYPE";

Old type response, most likely:
a) an empty string sent as a request
b) a very incomplete XML string sent as a request
Please check both, raw request string and raw response!!
OLD_TYPE
            my $errorCode = XML_OLD_TYPE_RESPONSE;

            _populateHTTP_XMLParse_Error(
                       'pError'    => $pError
                      ,'shortMsg'  => $shortMsg
                      ,'longMsg'   => $longMsg
                      ,'errorCode' => $errorCode
	   		);
         }

	 $ok = 0;
	    # Just check out the first error message
	    # If first error message is not an old style error message
	    # then none is.
         last;
      }
   }

   return $ok;
}

=head1 ABSTRACT METHODS 

Methods that HAVE TO BE IMPLEMENTED IN each specific API CALL

=head2 getApiCallName()

An abstract method - it has to be implemented in a class extending BaseCall class

=cut

sub getApiCallName {
   return undef;
}

=head2 getRequestDataTypeFullPackage()

An abstract method - it has to be implemented in a class extending BaseCall class

=cut

sub getRequestDataTypeFullPackage {
  return undef; 
}

=head2 getResponseDataTypeFullPackage()

An abstract method - it has to be implemented in a class extending BaseCall class

=cut

sub getResponseDataTypeFullPackage {
  return undef; 
}

1;
