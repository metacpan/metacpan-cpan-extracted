#!/usr/bin/perl

##########################################################################
#
# Module: ............... <user defined location>/eBay/API/XML
# File: ................. CallRetry.pm
# Original Author: ...... Milenko Milanovic 
#                          (based on CallRetry.java written by Weijun Li)
# Last Modified By: ..... Robert Bradley / Jeff Nokes
# Last Modified: ........ 03/06/2007 @ 16:26
#
##########################################################################


=pod

=head1 eBay::API::XML::CallRetry

Specifies retry parameters for an API call.

=head1 DESCRIPTION

This module is used to specify call retry parameters for an API call.

=cut


# Package Declaration
# --------------------------------------------------------------------------
package eBay::API::XML::CallRetry;


# Required Includes
# --------------------------------------------------------------------------
use strict;                   # Used to control variable hell.
use warnings;

use Exporter;                 # For Perl symbol export functionality.
use Data::Dumper;

# Variable Declarations
# --------------------------------------------------------------------------

# Global Variables
our @ISA = ("Exporter");

use HTTP::Status;

use eBay::API::XML::BaseCall;

#
# graGenericTriggerErrorCodes are production trigger error codes
#
my $graGenericTriggerErrorCodes  = [
       '10007' # "Internal error to the application."
      ,'931'   # "Validation of the authentication token in API request failed."
	       
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_INTERNAL_SERVER_ERROR  #  (500)
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_BAD_GATEWAY            #  (502) 'Proxy Error'
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_REQUEST_TIMEOUT        #  (408)
    			   ];

#
# graTestTriggerErrorCodes are used only for test purposes.
# DO NOT USE THEM IN PRODUCTION
#
my $graTestTriggerErrorCodes  = [
       '10007' # "Internal error to the application."
      ,'931'   # "Validation of the authentication token in API request failed."
      ,'521'   # Test of Call-Retry: "The specified time window is invalid."
      ,'124'   # Test of Call-Retry: "Developer name invalid."

      ,'21926' # Test of Call-Retry: 
               #     "The version 415 in the HTTP header 
	       #        X-EBAY-API-COMPATIBILITY-LEVEL does not match 
	       #        the version 445 in the request.  The HTTP header 
	       #        version will be used."
	       
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_INTERNAL_SERVER_ERROR  #  (500)
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_BAD_GATEWAY            #  (502) 'Proxy Error'
      ,eBay::API::XML::BaseCall::HTTP_ERRORCODE_PREFIX
                           . RC_REQUEST_TIMEOUT        #  (408)
    			   ];


=head1 Subroutines

=cut


# Subroutine Prototypes
# --------------------------------------------------------------------------------
# Method Name                              Accessor Privileges      Method Type

sub new($;);                         #         Public                Instance
sub setMaximumRetries($$;);          #         Public                Instance
sub getMaximumRetries($;);           #         Public                Instance
sub setDelayTime($$;);               #         Public                Instance
sub getDelayTime($;);                #         Public                Instance
sub setTriggerErrorCodes($$;);       #         Public                Instance
sub getTriggerErrorCodes($;);        #         Public                Instance
sub incNumberOfRetries($;);          #         Public                Instance
sub getNumberOfRetries($;);          #         Public                Instance
sub shouldRetry($$;);                #         Public                Instance
sub createGenericCallRetry();        #         Public                Static
sub createTestCallRetry();           #         Public                Static


# Main Script
# --------------------------------------------------------------------------------


# Subroutine Definitions
# --------------------------------------------------------------------------------


=head2 new()

Object constructor for the eBay::CallRetry class.

Arguments:


=over 4

=item *

    no arguments

=back

=cut

  sub new($;) {

    my $classname = shift;
    my $self = {};
    bless($self, $classname);

    $self->{'maximumRetries'} = 0;
    $self->{'delayTime'}      = 0;
    $self->{'raTriggerErrorCodes'} = [];

    $self->{'numberOfRetries'} = 0;  # how many retries was executed

    return $self;
  }

=head2 setMaximumRetries()

Set maximum number of retries if the failure continues to happen. If 0 then 
there are no retries.

=cut

  sub setMaximumRetries($$;) {
    my $self = shift;
    $self->{'maximumRetries'} = shift;
  }


=head2 getMaximumRetries()

Returns maximum number of retries if the failure continues to happen. If 0 then 
there are no retries.

=cut


  sub getMaximumRetries($;) {
    my $self = shift;
    return $self->{'maximumRetries'};
  }


=head2 setDelayTime()

Set delay time (in ms) for between each retry-API-call. 
If ms equals 0, then retry immediately.

=cut

  sub setDelayTime($$;) {
    my $self = shift;
    $self->{'delayTime'} = shift;
  }


=head2 getDelayTime()

Returns delay time (in ms) for between each retry-API-call. 
If ms equals 0, then retry immediately.

=cut


  sub getDelayTime($;) {
    my $self = shift;
    return $self->{'delayTime'};
  }

=head2 setTriggerErrorCodes()

Sets list of API error codes that trigger retry

=cut

  sub setTriggerErrorCodes($$;) {
    my $self = shift;
    $self->{'raTriggerErrorCodes'} = shift;
  }

=head2 getTriggerErrorCodes()

Returns list of API error codes that trigger retry

=cut

  sub getTriggerApiErrorCodes($;) {
    my $self = shift;
    return $self->{'raTriggerErrorCodes'};
  }

=head2 incNumberOfRetries()

increment number of retries (keep counter)

=cut

  sub incNumberOfRetries($;) {
    my $self = shift;
    my $value = $self->{'numberOfRetries'};
    $value++;
    $self->{'numberOfRetries'} = $value;
  }


=head2 getNumberOfRetries()

Return current number of retries left.

=cut



  sub getNumberOfRetries($;) {
    my $self = shift;
    return $self->{'numberOfRetries'};
  }


=head2 shouldRetry()

Determines if the Call-Retry should be granted for the given errors.

=cut

  sub shouldRetry($$;) {
    my $self = shift;
    
    # rlb avoid "Odd number of elements in hash assignment" warnings
    # when there are no errors or warnings.
    if (scalar @_ <= 1) {
      return 0;
    }

    my %args = @_;

    my $raErrors  = $args{'raErrors'};

    if ( defined $raErrors ) {
	    
       my $sErrorCode = undef;
       
         # create a hash with trigger codes, It is easier to lookup 
	 #  call errors in a hash table than in an array

       my $raTriggerErrorCodes = $self->getTriggerApiErrorCodes();
       my %hTriggerErrorCodes = ();
       foreach $sErrorCode ( @$raTriggerErrorCodes) {
	     $hTriggerErrorCodes{$sErrorCode} = undef;
       }

       foreach my $pError (@$raErrors) {	      
	
          $sErrorCode = $pError->getErrorCode();

          if ( exists( $hTriggerErrorCodes{$sErrorCode} ) ) {
    	     return 1;
          }
       }
    }

    return 0;
  }

=head2 createGenericCallRetry()

Create most common call retry rule.
This is a static method

=cut

  sub createGenericCallRetry() {
	  
    my $pCallRetry = API::CallRetry->new();

    $pCallRetry->setMaximumRetries(2); # try 2 more retries 
    $pCallRetry->setDelayTime(300);    # 300 ms

    $pCallRetry->setTriggerErrorCodes( $graGenericTriggerErrorCodes );

    return $pCallRetry;
  }

=head2 createTestCallRetry()

Create Call retry rules used in TESTS only 
This is a static method.

=cut

  sub createTestCallRetry() {

    my $pCallRetry = eBay::CallRetry->new();

    $pCallRetry->setMaximumRetries(2); # try 2 more retries 
    $pCallRetry->setDelayTime(300);    # 300 ms

    $pCallRetry->setTriggerErrorCodes( $graTestTriggerErrorCodes );

    return $pCallRetry;
  }
  
1;
