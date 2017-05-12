#!/usr/bin/perl -w
#
use strict;
use warnings;

###############################################################################
#
# Module: ............... <user defined location>eBay/API/XML
# File: ................. testBaseCall_Errors.pl
# Original Author: ...... Milenko Milanovic
# Last Modified By: ..... Milenko Milanovic
# Last Modified: ........ 03/03/2006 @ 11:32
#
# Description: Unit test class that tests HTTP connection errors 
#              as well as cases when API returns some strange responses.
#              We covered all 6 errors whose constants are specified at
#              the begining of BaseCall class:
#
#                       HTTP_ERRORCODE_PREFIX
#                       XML_PARSE_ERROR
#                       NO_RESPONSE_CONTENT
#                       BAD_API_GATAWAY
#                       XML_PARSE_RESULT_EMPTY
#                       XML_OLD_TYPE_RESPONSE
#
# Note: We do not submit any calls to API servers. 
#       We just set raw XML responses and HTTP response codes to simulate 
#       error condition that has to be trapped by the API call.
#       
###############################################################################

use Test::More 'no_plan';
use HTTP::Response;
use HTTP::Status;
use Data::Dumper;

use eBay::API::XML::Call::GetAllBidders;
use eBay::API::XML::BaseCall;

my $sRawResponseContent;
my $sExpectedErrorCode;
my $sHttpStatusCode;

 #
 #  START TESTS
 #
 
 # 1. HTTP connection error
$sHttpStatusCode = HTTP::Status::RC_INTERNAL_SERVER_ERROR;
$sRawResponseContent = '';
$sExpectedErrorCode = eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                             . $sHttpStatusCode;
ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode
        ,$sHttpStatusCode),  $sExpectedErrorCode );


 # 2. XML parse error
$sRawResponseContent = <<'XML_PARSE_ERROR';
<?xml version="1.0" encoding="UTF-8"?>
<force
XML_PARSE_ERROR
$sExpectedErrorCode = eBay::API::XML::BaseCall::XML_PARSE_ERROR;

ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode ),  $sExpectedErrorCode );


 # 4. no response in content
$sRawResponseContent = '';
$sExpectedErrorCode = eBay::API::XML::BaseCall::NO_RESPONSE_CONTENT;

ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode ),  $sExpectedErrorCode );



 # 5. BAD_API_GATAWAY
$sRawResponseContent = <<'BAD_API_GATAWAY';
<!DOCTYPE
BAD_API_GATAWAY
$sExpectedErrorCode = eBay::API::XML::BaseCall::BAD_API_GATAWAY;

ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode ),  $sExpectedErrorCode );


 # 6. XML_PARSE_RESULT_EMPTY
$sRawResponseContent = <<'XML_PARSE_RESULT_EMPTY';
<?xml version="1.0" encoding="UTF-8"?>
<root>
<!-- there is nothing useful in this document -->
</root>
XML_PARSE_RESULT_EMPTY
$sExpectedErrorCode = eBay::API::XML::BaseCall::XML_PARSE_RESULT_EMPTY;

ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode ),  $sExpectedErrorCode );


 # 2. XML_OLD_TYPE_RESPONSE

$sRawResponseContent = createResponseForOldTypeResponseError();
$sExpectedErrorCode = eBay::API::XML::BaseCall::XML_OLD_TYPE_RESPONSE; 
ok ( testError ( 
         $sRawResponseContent
	,$sExpectedErrorCode ),  $sExpectedErrorCode );


 #
 #  END TESTS
 #
 
=head2 testError()

=cut 

sub testError {

    my $sRawResponseContent = shift; 
    my $sExpectedErrorCode  = shift;
    my $sHttpStatusCode    = shift || HTTP::Status::RC_OK;

	  #
	  # We just need any Call class to test API000-API005 errors
	  #

    my $pCall = eBay::API::XML::Call::GetAllBidders->new();

    my $objHttpResponse = HTTP::Response->new();
    $objHttpResponse->code( $sHttpStatusCode );
    $objHttpResponse->content( $sRawResponseContent );

    $pCall->processResponse( $objHttpResponse );

    my $raErrors = $pCall->getErrorsAndWarnings();

    #print Dumper( $raErrors );

    if ( defined $raErrors && (scalar @$raErrors) == 1 ) {

       my $pError = $raErrors->[0];
       my $sErrorCode = $pError->getErrorCode();
       if ( $sErrorCode eq $sExpectedErrorCode ) {
          return 1;	       
       }
    }

    return 0;
}

=head2 testOldTypeResponseError()

I used this test just to get response for XML_OLD_TYPE_RESPONSE error.
At this moment this test is not being executed when the whole test script is 
being run.

=cut

sub testOldTypeResponseError {
   	
   my $sExpectedErrorCode = shift;

   my $pCall = eBay::API::XML::Call::GetAllBidders->new();
     # Submit an empty request string
     # That is the case when API returns XML_OLD_TYPE_RESPONSE  error
   $pCall->setRequestRawXml('');

   $pCall->execute();

   my $sResponseRawXml = $pCall->getResponseRawXml();

   print Dumper( $sResponseRawXml );

   my $raErrors = $pCall->getErrorsAndWarnings();

   if ( defined $raErrors && (scalar @$raErrors) == 1 ) {

       my $pError = $raErrors->[0];
       my $sErrorCode = $pError->getErrorCode();
       if ( $sErrorCode eq $sExpectedErrorCode ) {
          return 1;	       
       }
   }

   return 0;   
}

=head2 createResponseForOldTypeResponseError()

We need a very specific raw XML response in order to test if 
XML_OLD_TYPE_RESPONSE error is being properly trapped within BaseCall class.

=cut 

sub createResponseForOldTypeResponseError {

   my $str = <<'OLD_RES';
<?xml version="1.0" encoding="UTF-8"?>
<eBay>
	<EBayTime>2006-03-03 19:20:07</EBayTime>
	<CallStatus>
		<Status>Failure</Status>
	</CallStatus>
	<Errors>
		<Error>
			<Code>10012</Code>
			<SeverityCode>1</SeverityCode>
			<Severity>SeriousError</Severity>
			<Line>0</Line>
			<Column>0</Column>
			<ErrorClass>RequestError</ErrorClass>
			<ShortMessage><![CDATA[Invalid value for header "X-EBAY-API-DETAIL-LEVEL".]]></ShortMessage>
		</Error>
		<Error>
			<Code>5</Code>
			<SeverityCode>1</SeverityCode>
			<Severity>SeriousError</Severity>
			<Line>0</Line>
			<Column>0</Column>
			<ErrorClass>RequestError</ErrorClass>
			<ShortMessage><![CDATA[XML Parse error.]]></ShortMessage>
		</Error>
	</Errors>
</eBay>
OLD_RES
	
   return $str;
}
