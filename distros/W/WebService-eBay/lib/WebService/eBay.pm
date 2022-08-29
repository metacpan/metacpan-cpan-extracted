use strict;
use warnings;
package WebService::eBay;

# ABSTRACT: Interface with the eBay API

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use XML::Simple;
use Data::UUID;
use DateTime;
use Encode;

=head1 NAME 

WebService::eBay 

=head1 SYNOPSIS

This package provides an interface to use the eBay Trading API.  For more information about the eBay Trading API, visit https://developer.ebay.com/devzone/xml/docs/reference/ebay/index.html

The "hello world" equivalent in the eBay API world is to send a call asking for the current eBay time.  Here's an example of how to do that with this module:

 use WebService::eBay;
 
 my $response = WebService::eBay::APICall("GeteBayOfficialTime");
 print "$response->{Timestamp}\n";

But this isn't a great example for this module because the GeteBayOfficialTime call doesn't take any parameters.  A simple one that does though is the EndItem call.  Here's how you would do that in this module:

 my $listingNumber = '142306955';
 my $callDetails   = "<ItemID>$listingNumber</ItemID>
 <EndingReason>OtherListingError</EndingReason>";
 
 if ( WebService::eBay::APICall( "EndItem", $callDetails ) ) {
 	print "\nDeleted $listingNumber from eBay\n";
 } else {
 	print("\nUnable to end listing $listingNumber\n");
 }

=head1 DESCRIPTION
 
To use the eBay Trading API you need application keys and an authorization token.  You can obtain these through your eBay developer account.  You should create a file called "tokens" in the directory containing the program using this module.  That file should look like this for the API sandbox and testing:

 APIURL https://api.sandbox.ebay.com/ws/api.dll
 SiteID 0
 DevName <Your Dev Name>
 AppName <Your App Name>
 CertName <Your Cert Name>
 AuthToken <Your Auth Token>
 Log true

and this for the Production keys.  

 APIURL https://api.ebay.com/ws/api.dll
 SiteID 100
 DevName <Your Dev Name>
 AppName <Your App Name>
 CertName <Your Cert Name>
 AuthToken <Your Auth Token>
 
The last option "Log" is intended for testing and sandbox use as it logs all communication sent and received from the API, which includes your secret keys.  To not use this option, leave the "Log" line out of the tokens file or set it to something other than 'true'.


=cut

my %config;
my $tokens;
my $name;
my $value;
open( $tokens, './tokens' ) or die "Unable to find tokens file $!";
while (<$tokens>) {
	chomp;
	( $name, $value ) = split / /;
	$config{$name} = $value;
}
close($tokens);

my $APIURL    = $config{'APIURL'}    or die "No Valid APIURL in tokens file";
my $DevName   = $config{'DevName'}   or die "No Valid DevName in tokens file";
my $AppName   = $config{'AppName'}   or die "No Valid AppName in tokens file";
my $CertName  = $config{'CertName'}  or die "No Valid CertName in tokens file";
my $AuthToken = $config{'AuthToken'} or die "No Valid AuthToken in tokens file";
my $SiteID    = $config{'SiteID'}    or die "No Valid SiteID in tokens file";

my $loggingOn = undef;
if ( $config{'Log'} eq 'true' ) {
	$loggingOn = 'true';
}

=head1 SUBROUTINES
 
=head2 APICall
 
Sends an API call and returns the results as a hash.  Optionally returns the raw XML.  If the call encounters an HTTP error sending the call, it will try again twice before giving up.  This is in accordance with the rules for the eBay API.

=head3 Parameters

=head4 CallName

The name of the API Call that you wish to make.  For a list of API calls and their parameters, visit https://developer.ebay.com/devzone/xml/docs/reference/ebay/index.html

=head4 RequestDetails

The details of the call, in XML.  You do not need to provide the RequesterCredentials or the WarningLevel, but you do have to provide the rest of the call.  This is where that goes.  The RequesterCredentials are always the same and the WarningLevel doesn't usually need to be changed.  For information on what details your call needs, visit https://developer.ebay.com/devzone/xml/docs/reference/ebay/index.html  

Some calls have no details, such as GeteBayOfficialTime.
 
=head4 Xml

Pass any value here for true (pass "undef" for false) and the sub will return the raw XML from the API response, instead of the hash.

=head4 FailOnWarning

Pass any value here for true (pass "undef" for false) and the sub will return false ("fail") if the API call returns a warning.  The default is to return the hash (which contains the warning) if the API call returns a warning.

=cut

sub APICall {
	my $CallName = shift;
	my $RequestDetails;
	$RequestDetails = shift
	  or $RequestDetails = ' ';
	my $Xml = shift
	  ; # Set to true to get function to return the raw XML instead of a hash, generally for debugging.  Default is off.
	my $FailOnWarning = shift
	  ; # Set to true if you want the function to return false if the API call returns a warning.  The default is to return true if the API call returns a warning.
	my $objUserAgent = LWP::UserAgent->new( timeout => 15 );
	my $Header       = HTTP::Headers->new;
	my ( $ErrorResponse, @Errors, $Error, $Response );

	$CallName =~ s/\s+/ /g;    #Remove consecutive spaces
	$CallName =~ s/ $//gi;     #Remove the last space
	$CallName =~ s/^ //gi;     #Remove the first space

	my $Request = "<?xml version=\"1.0\" encoding=\"utf-8\"?> 
<$CallName" . "Request xmlns=\"urn:ebay:apis:eBLBaseComponents\"> 
  <RequesterCredentials> 
    <eBayAuthToken>$AuthToken</eBayAuthToken> 
  </RequesterCredentials>
  <WarningLevel>High</WarningLevel>
  $RequestDetails
</$CallName" . "Request>";

	my $apiLog;
	if ($loggingOn) {
		open( $apiLog, ">>apiLog" ) or die $!;
		binmode( $apiLog, ":utf8" );
		print $apiLog FormateBayDate() . "\n\n$Request\n\n";
	}

	$Header->push_header( 'X-EBAY-API-COMPATIBILITY-LEVEL' => '897' );
	$Header->push_header(
		'X-EBAY-API-SESSION-CERTIFICATE' => "$DevName$AppName$CertName" );
	$Header->push_header( 'X-EBAY-API-DEV-NAME'  => $DevName );
	$Header->push_header( 'X-EBAY-API-APP-NAME'  => $AppName );
	$Header->push_header( 'X-EBAY-API-CERT-NAME' => $CertName );
	$Header->push_header( 'X-EBAY-API-SITEID'    => "$SiteID" );
	$Header->push_header( 'Content-Type'         => 'text/xml; charset=utf-8' );
	$Header->push_header( 'X-EBAY-API-CALL_NAME' => "$CallName" );

	my $objRequest = HTTP::Request->new( "POST", $APIURL, $Header );
	$objRequest->content_type("text/plain; charset='utf8'");
	$objRequest->content( Encode::encode_utf8($Request) );
	my $objResponse = $objUserAgent->request($objRequest) or return undef;

	if ( $objResponse->is_error ) {
		warn "HTTP request error: "
		  . $objResponse->error_as_HTML
		  . " on API Call $CallName. Trying again...";
		sleep 2;
		$objResponse = $objUserAgent->request($objRequest);
		if ( $objResponse->is_error ) {
			warn ("HTTP request error again... Trying one more time...");
			sleep 2;
			$objResponse = $objUserAgent->request($objRequest);
			if ( $objResponse->is_error ) {
				die
				  "Unable to resolve the HTTP request error.  API call FAILED.";
				return undef;
			}
		}
	}

	if ($Xml) { return $objResponse->{_content} }
	if ($loggingOn) {
		print $apiLog $objResponse->{_content}
		  . "\n**************************************************************************\n\n";
		close $apiLog;
	}

	my $xml = new XML::Simple;
	$Response = $xml->XMLin( $objResponse->content );

	if ( $Response->{Ack} ) {
		if ( $Response->{Ack} =~ /success/i ) {
			return $Response;
		} else {    # We have an error!!
			$ErrorResponse =
			  $xml->XMLin( $objResponse->content, ForceArray => 1 );
			@Errors = @{ $ErrorResponse->{Errors} };
			my $ErrorLine = "*** API Call $CallName returned " . scalar @Errors;
			if ( $Response->{Ack} =~ /warning/i ) {
				$ErrorLine .= " warning(s): ";
				foreach $Error (@Errors) {
					$ErrorLine .= "Warning: " . $Error->{LongMessage}->[0];
				}
				print($ErrorLine);
				return $Response unless ($FailOnWarning);
			} elsif ( $Response->{Ack} =~ /PartialFailure/i ) {
				$ErrorLine .= " Partial Failures but did not fail.  ";
				foreach $Error (@Errors) {
					$ErrorLine .= "Error: " . $Error->{LongMessage}->[0];
				}
				print $ErrorLine;
				return $Response;
			} elsif ( $Response->{Ack} =~ /failure/i ) {
				$ErrorLine .= " error(s) and FAILED: *** ";
				foreach $Error (@Errors) {
					$ErrorLine .= " || Error: " . $Error->{LongMessage}->[0];
				}
				print($ErrorLine);
			} else {
				$ErrorLine .=
" errors with an undefined error response and FAILED.  Error XML follows. \n\n$objResponse->{_content}\n\n";
				print($ErrorLine);
			}
		}
	} else {
		print
"API Call \"$CallName\" did not return a result status and has FAILED.";
	}

	# Arrival at this line consitutes an error!
	#    print "\n$Request\n\n$objResponse->{_content}\n\n";
	return undef;
}

=head2 GeteBayTime

Returns eBay official time.  Not local time.  

=head3 Parameters

=cut

sub GeteBayTime {
	my $Response = APICall("GeteBayOfficialTime") or return undef;

	my $Time  = $Response->{Timestamp};
	my $Today = substr( $Time, 0, 10 );
	$Time =~ s/(t|z)/ /ig;
	$Time =~ s/(^\s+)|(\s+$)//g;
	return $Time;
}

=head2 FormateBayDate

Returns the current date formatted for use in eBay API calls.  Optionally will return a date offset from the current time, such as one hour from now or one day ago.

=head3 Parameters

=head4 Offset

Number of seconds to offset the current time.  Example: FormateBayDate(3600) returns the time one hour from now.  This function is usually called as FormateBayDate(86400) to obtain the next day's date.

=cut

sub FormateBayDate {
	my $Offset = shift;
	$Offset = 0 unless ($Offset);

	my (
		$Second, $Minute,  $Hour,      $Day, $Month,
		$Year,   $WeekDay, $DayOfYear, $IsDST
	) = localtime( time + $Offset );
	$Year  = $Year + 1900;
	$Month = $Month + 1;

	$Day    = sprintf( "%02s", $Day );
	$Month  = sprintf( "%02s", $Month );
	$Hour   = sprintf( "%02s", $Hour );
	$Minute = sprintf( "%02s", $Minute );
	$Second = sprintf( "%02s", $Second );
	return
		$Year . "-"
	  . $Month . "-"
	  . $Day . " "
	  . $Hour . ":"
	  . $Minute . ":"
	  . $Second;
}

=head2 XMLClean

Strips a string of characters recognized by XML code

=head3 Parameters

=head4 Line

The string of characters you want to process.

=cut

sub XMLClean {
	my $Line = shift;
	$Line =~ s/ < / &lt; /gi;
	$Line =~ s/ > / &gt; /gi;
	$Line =~ s/ & / &amp; /gi;
	$Line =~ s/\'/&apos;/gi;
	$Line =~ s/\"/&quot;/gi;
	return $Line;
}

=head2 GetUUID

Returns a UUID formatted for eBay standards

=head3 Parameters

none

=cut

sub GetUUID {    # Returns a UUID formated for eBay standards
	my $Ug   = new Data::UUID;
	my $Uuid = $Ug->create();
	my $Guid = $Ug->to_string($Uuid);

	$Guid =~ s/-//gi;
	$Guid =~ s/{|}//gi;

	return $Guid;
}

=head2 ebayTimeToSqlTimestamp

Converts an ebay time to a string properly formatted for insertion as an SQL timestamp.

=head3 Parameters

=head4 time

The time you want to convert

=cut

sub ebayTimeToSqlTimestamp {
	my $time = shift;
	$time =~ s/[T|Z]/ /gi;    # Remove "T and Z"
	$time =~ s/\..*$//gi;     # remove the first dot and everything after it
	return $time;
}

return 1;

