#!/usr/bin/perl

#########################################################################
#
# Module: ............... <user defined location>/eBay/API
# File: ................. BaseApi.pm
# Original Authors: ..... Jeff Nokes / Bob Bradley
# Last Modified By: ..... Jeff Nokes
# Last Modified: ........ 03/15/2007 @ 14:46
#
#########################################################################


=pod

=head1 NAME

eBay::API::BaseApi - Logging, exception handling and authentication frameworks 
for eBay::API objects.

=head1 INHERITANCE

This is the base class

=head1 DESCRIPTION

This top-level module encapsulates all the functionality for the eBay
API.  This library is really a parent class wrapper to the sub-classes of
eBay::API--mainly sessions and api call objects.

The main purpose of this framework is to provide event logging,
exception handling, and management eBay API certification information.

Users of eBay::API can use this facility to debug requests to the eBay
API and responses from the eBay API. Unless the user overrides the
default behavior, all logging will go to stderr.

=cut



# Package Declaration
# ---------------------------------------------------------------------------
package eBay::API::BaseApi;


# Required Includes
# ---------------------------------------------------------------------------
use strict;                     # Used to control variable hell.
use Exporter;                   # For Perl symbol export functionality.
use Data::Dumper;               # Used for logging support.
use eBay::Exception qw(:try);   # eBay Exceptions framework
use Params::Validate qw(:all);  # CPAN validate subroutine parameters
use XML::Tidy;                  # CPAN module to format XML

use eBay::API::XML::Release;    # Defines API release attributes
                                #  Api release number
                                #  Api release type 

# Variable Declarations
# ---------------------------------------------------------------------------
# Constants
use constant TRUE    => scalar 1;
use constant FALSE   => scalar 0;

use constant LOG_DEBUG => scalar 1;             # Pre-defined log levels
use constant LOG_INFO => scalar 2;
use constant LOG_WARN => scalar 3;
use constant LOG_ERROR => scalar 4;
use constant LOG_FATAL => scalar 5;

use constant DEFAULT_API_COMPATIBILITY_LEVEL =>
                                    eBay::API::XML::Release::RELEASE_NUMBER;
use constant DEFAULT_EBAY_API_VERSION => 
                                    eBay::API::XML::Release::RELEASE_NUMBER;
use constant DEFAULT_EBAY_SITE_ID => '0';
use constant DEFAULT_EBAY_URI => 'urn:ebay:apis:eBLBaseComponents';
use constant DEFAULT_EBAY_ERROR_LANGUAGE => 'en_US';
use constant DEFAULT_LOG_LEVEL => LOG_ERROR;
use constant DEFAULT_EBAY_API_TIMEOUT => 20;



# Global Variables
our $VERSION = $API::VERSION;    # The version of this class/module, as well as the entire pkg.
our $ERROR;                      # Most recent errors.

our @ISA = ("Exporter");   # Need to sub the Exporter class, to use the EXPORT* arrays below.

# :DEFAULT exported symbols
our @EXPORT = qw(
                   $VERSION
                   $ERROR
                );

# Script Lexical Variables
my $this_mod = 'eBay::API::BaseApi';    # Used for logging only.

my $LOG_SUB_HANDLE = undef;        # User-provided subroutine to use as a logging handler.
my $LOG_FILE_HANDLE = *STDERR;     # File handle for writing log info.
my $LOG_LEVEL = DEFAULT_LOG_LEVEL; # Current logging level for the package
my $LOG_HEADER = 0;                # Display context along with log message

my $CHECK_PARAMETERS = 1;

=head1 Subroutines

Below is a list of public methods accessed through child classes.

=cut

# Subroutine Prototypes
# -------------------------------------------------------------------------------
# Method Name                              Accessor Priviledges      Method Type
sub new($;$);                         #         Public                Class
sub _log_it(;$$);                     #         Private               Local
sub _logThis($;$$);                   #         Protected             Instance
sub logMessage($$$;);                 #         Protected             Instance
sub logXml($$$;);                     #         Protected             Instance
sub logDebug($$;);                    #         Protected             Instance
sub logInfo($$;);                     #         Protected             Instance
sub logError($$;);                    #         Protected             Instance
sub setLogHeader($$;);                #         Public                Instance
sub setLogSubHandle($$;);             #         Public                Instance
sub getLogSubHandle($;);              #         Public                Instance
sub setLogFileHandle($$;);            #         Public                Instance
sub getLogFileHandle($;);             #         Public                Instance
sub testLogEntry(;$);                 #         Public                Local
sub dumpObject($;$);                  #         Public                Instance
sub setLogLevel($$;);                 #         Public                Instance
sub getLogLevel($;);                  #         Public                Instance
sub _setError($$;);                   #         Private               Instance
sub setDevID($$;);                    #         Public                Instance
sub getDevID($;);                     #         Public                Instance
sub setAppID($$;);                    #         Public                Instance
sub getAppID($;);                     #         Public                Instance
sub setCertID($$;);                   #         Public                Instance
sub getCertID($;);                    #         Public                Instance
sub setSiteID($$;);                   #         Public                Instance
sub getSiteID($;);                    #         Public                Instance
sub setUserName($$;);                 #         Public                Instance
sub getUserName($;);                  #         Public                Instance
sub setUserPassword($$;);             #         Public                Instance
sub getUserPassword($;);              #         Public                Instance
sub setAuthToken($$;);                #         Public                Instance
sub getAuthToken($;);                 #         Public                Instance
sub setErrLang($$;);                  #         Public                Local
sub getErrLang($;);                   #         Public                Local
sub isSuccess($;);                    #         Public                Instance
sub getError($;);                     #         Public                Instance
sub setCompatibilityLevel($$;);       #         Public                Instance
sub getCompatibilityLevel($;);        #         Public                Instance
sub setVersion($$;);                  #         Public                Local
sub getVersion($;);                   #         Public                Local
sub setCompression($$;);              #         Public                Instance
sub isCompression($;);                #         Public                Instance
sub _check_arg($$;);                  #         Public                Package
sub enableParameterChecks(;$);        #         Public                Package
sub getApiReleaseNumber();            #         Public                Package
sub getApiReleaseType();              #         Public                Package
sub setCallRetry($$;);                #         Public                Instance
sub getCallRetry($;);                 #         Public                Instance
sub setTimeout($$;);                  #         Public                Instance
sub getTimeout($;);                   #         Public                Instance

# Main Script
# ---------------------------------------------------------------------------


# Subroutine Definitions
# ---------------------------------------------------------------------------

=head2 new()

Object constructor for the eBay::API::XML::Session class.  This is
basically a wrapper around the CPAN LWP::Paralle module.

  my $call = eBay::API::XML::Session->new(
      site_id => 0,
      proxy   => 'https://api.ebay.com/ws/api.dll',
      dev_id  => __DEVELOPER_ID__,
      app_id  => __APPLICATION_ID__,
      cert_id => __CERT_ID__,
      user_auth_token => __AUTH_TOKEN__, 
  );
    
  or
  
  my $call = eBay::API::XML::Call::GeteBayOfficialTime->new(
      site_id => 0,
      proxy   => 'https://api.ebay.com/ws/api.dll',
      dev_id  => __DEVELOPER_ID__,
      app_id  => __APPLICATION_ID__,
      cert_id => __CERT_ID__,
      user_auth_token => __AUTH_TOKEN__, 
  );
    
  $call->execute();            
  print $call->getEBayOfficialTime();      
    
Usage:

=over 4

=item *

eBay::API::XML::Session->new({args})

=item *

eBay::API::XML::Session::new("eBay::API::XML::Request", {args} )

=back

Arguments:

=over 4

=item *

The name  of this class/package.

=item *

A hash reference containing the following possible arguments:

=over 8

=item *

B<site_id> => Scalar representing the eBay site id of the XML API
calls.  Setting the site id at the session level will provide a
default site id for all API calls bundled into a session.  The site id
for individual calls may still be overridden when the respective
request objects are instantiated.

If this value is not provided, it will attempt to use
the value in the environment variable $EBAY_API_SITE_ID;

=item *

B<dev_id> => Scalar representing the Developer ID provided to the user
by eBay.  The developer ID is unique to each licensed developer (or
company). By default this will be taken from the environment variable
$EBAY_API_DEV_ID, but it can be overridden here or via the setDevID()
class method.

=item *

B<app_id> => Scalar representing the Application ID provided to the
user by eBay.  The application ID is unique to each application
created by the developer. By default this will be taken from the
environment variable $EBAY_API_APP_ID, but it can be overridden here
or via the setAppID() class method.

=item *

B<cert_id> => Scalar representing the Certification ID provided to the
user by eBay.  The certificate ID is unique to each application
created by the developer. By default this will be taken from the
environment variable $EBAY_API_CERT_ID, but it can be overridden here
or via the setCertID() class method.

=item *

B<user_name> => Scalar representing the application level user name
for this session.  This may be overriden for each bundled call in the
session.

=item *

B<user_password> => Scalar reprsenting the application level user
password for this session.  This may be overriden for each bundled
call in the session.

=item *

B<user_auth_token> => Scalar representing the auth token for the
application level user.

=item *

B<api_ver> => Scalar representing the eBay webservices API version the
user wishes to utilize.  If this is not set here, it is taken from the
environment variable $EBAY_API_VERSION, which can be overridden via
the class method setVersion().

=item *

B<proxy> => Scalar representing the eBay transport URL needed to send
the request to.  If this is not set here, it must be set via the
setProxy() class method, prior to object instantiation.

# Deprecated
#=item *
#
#B<debug> => Boolean.  TRUE means we'll want debugging for the
#request/response.  FALSE means no debugging.

# Deprecated
#=item *
#
#B<err_lang> => Value for the error language you would like returned to
#you for any XML/webservice errors encountered.  By design, if this
#value is not provided, eBay will return en-US as the default error
#language value.  This can be set at the class level via the
#setErrLang() method, and retrieved from the getErrLang() method.  It
#can also be set for a particular instance with the instance
#getter/setter method errLang().

=item *

B<compatibility_level> => This value is defined as a default in each
release of the api.  But if you need to override the default value,
you can do this either when you instatiate your session object, or by
using the setter method setCompatibilityLevel().

=item *

B<sequential> => Boolean value to indicate if the requests should be
issued sequentially if true, and in parallel if false (default).  This
may also be set with the setter method setExecutionSequential().

=item *

B<timeout> => Scalar numerical value indicating the number of seconds to
wait on an http request before timing out.  Setting this to 0 will cause
the requests to block.  Otherwise the default is that of LWP::UserAgent.
This may also be set with the instance setter method setTimeout();

=back

=back

Returns:

=over 4

=item *

B<success>  Object reference to the eBay::API::XML::Session class.

=item *

B<failure>  undefined

=back

=cut

sub new($;$) {

  # Get all arguments passed in.
  my($class, $arg_hash) = @_;

  # Validation
  eBay::API::BaseApi::_check_arg($class, Params::Validate::SCALAR);


  # Local Variables
  my $self = {};          # This object to be blessed.

  # We want to immediately bless ourselves into this __PACKAGE__ so we
  # can start setting object attributes right away, and use any
  # available instance methods.
  bless($self, $class);


  if (defined $ENV{EBAY_LOG_LEVEL} && $ENV{EBAY_LOG_LEVEL} && $ENV{EBAY_LOG_LEVEL} > 0 ) {
    $LOG_LEVEL = $ENV{EBAY_LOG_LEVEL};
  }# end if

  if (defined $::RALF and $::RALF) {
    $LOG_FILE_HANDLE = $::RALF;
  }# end if

  if ( $ENV{EBAY_API_COMPATIBILITY_LEVEL} ) {
    $self->{compatibility_level} = $ENV{EBAY_API_COMPATIBILITY_LEVEL};
  } else {
    $self->{compatibility_level} = DEFAULT_API_COMPATIBILITY_LEVEL;
  }

  if ( $ENV{EBAY_API_SITE_ID}) {
    $self->{site_id} = $ENV{EBAY_API_SITE_ID};
  } else {
    $self->{site_id} = DEFAULT_EBAY_SITE_ID;
  }

  $self->{dev_id} = $ENV{EBAY_API_DEV_ID};
  $self->{app_id} = $ENV{EBAY_API_APP_ID};
  $self->{cert_id} = $ENV{EBAY_API_CERT_ID};
  $self->{user_name} = $ENV{EBAY_API_USER_NAME};
  $self->{user_password} = $ENV{EBAY_API_USER_PASSWORD};
  $self->{user_auth_token} = $ENV{EBAY_API_USER_AUTH_TOKEN};
  $self->{proxy} = $ENV{EBAY_API_XML_TRANSPORT};

# Deprecated
#  if ($ENV{EBAY_API_XML_ERR_LANG}) {
#    $self->{err_lang} = $ENV{EBAY_API_XML_ERR_LANG};
#  } else  {
#    $self->{err_lang} = DEFAULT_EBAY_ERROR_LANGUAGE;
#  }

# Deprecated
#  if ($ENV{EBAY_API_URI} ) {
#    $self->{xml_uri} = $ENV{EBAY_API_URI};
#  } else {
#    $self->{xml_uri} = DEFAULT_EBAY_URI;
#  }

  if ($ENV{EBAY_API_VERSION} ) {
    $self->{api_ver} = $ENV{EBAY_API_VERSION};
  } else {
    $self->{api_ver} = DEFAULT_EBAY_API_VERSION;
  }

  if ($ENV{EBAY_API_TIMEOUT} ) {
    $self->{timeout} = $ENV{EBAY_API_TIMEOUT};
  } else {
    $self->{timeout} = DEFAULT_EBAY_API_TIMEOUT;
  }

  # Before we start setting local variables assuming we have an
  # $arg_hash, validate that we actaully do have one.  If we have an
  # argument but it's not a hash reference, set/log $ERROR and return
  # failure to the caller.  If we have a valid hash reference argument,
  # attempt to set the appropriate object attributes.
  if (defined($arg_hash) ) {
    eBay::API::BaseApi::_check_arg($arg_hash, Params::Validate::HASHREF);
  }# end if

  if    (defined($arg_hash)  &&  (ref($arg_hash) =~ /HASH/o))
    {
      if ($arg_hash->{site_id})         {$self->{site_id}     = $arg_hash->{site_id};}
      if ($arg_hash->{dev_id})          {$self->{dev_id}      = $arg_hash->{dev_id};}
      if ($arg_hash->{app_id})          {$self->{app_id}      = $arg_hash->{app_id};}
      if ($arg_hash->{cert_id})         {$self->{cert_id}     = $arg_hash->{cert_id};}
      #if ($arg_hash->{xml_uri})         {$self->{xml_url}     = $arg_hash->{xml_uri};}               # Deprecated
      if ($arg_hash->{user_name})       {$self->{user_name}   = $arg_hash->{user_name};}
      if ($arg_hash->{user_password})   {$self->{user_password} = $arg_hash->{user_password};}
      if ($arg_hash->{user_auth_token}) {$self->{user_auth_token} = $arg_hash->{user_auth_token};}
      if ($arg_hash->{api_ver})         {$self->{api_ver}     = $arg_hash->{api_ver};}
      #if ($arg_hash->{err_lang})        {$self->{err_lang}    = $arg_hash->{err_lang};}              # Deprecated
      if ($arg_hash->{proxy})           {$self->{proxy}       = $arg_hash->{proxy};}
      if ($arg_hash->{debug})           {$self->{debug}       = $arg_hash->{debug};}
      if ($arg_hash->{timeout})         {$self->{timeout}     = $arg_hash->{timeout};}
      if ($arg_hash->{compatibility_level}) {
         $self->{compatibility_level}  = $arg_hash->{compatibility_level};
      }# end if

    }# end if


  # Else-if we have an $arg_hash but it isn't a hash reference,
  # set/log $ERROR and return failure to the caller.
  elsif (defined($arg_hash)  &&  (ref($arg_hash) !~ /HASH/o)) {
    return(undef());
  }# end elsif

  # Else, assume the caller doesn't want to set any object attributes.
  else  {}  # end else

  # Add an error attribute to always contain the most recent error data in scalar form.
  $API::ERROR = $self->{error} = '';


  # If we've gotten this far, we have a class (we hope), return success to the caller.
  return($self);

}# end sub new()

=head2 setLogHeader()

Instance method to enable or disable additional context information
to display with log messages.  This information includes date, time,
and logging level.

Arguments:

=over 4

=item *

A reference to object of type eBay::API.

=item *

Boolean value (0 = false; non-zero = true);

=back

Returns: 

=over 4

=item *

The boolean value to be set for this attribute.

=back

=cut



sub setLogHeader($$;) {
  my $self = shift;
  my $bool = shift;
  # Validation
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
  eBay::API::BaseApi::_check_arg($bool, Params::Validate::BOOLEAN);
  $LOG_HEADER = $bool;
  return $bool;
}


# _log_it()
#
# Description:  Local method used to support logging functionality.  This sub will allow
#               for itself to be a wrapper for another sub handle if $LOG_SUB_HANDLE is
#               set.  Otherwise, it will default to printing to $LOG_FILE_HANDLE.
#
# Access:       Private
#
# Note:         If using the $LOG_SUB_HANDLE, make sure your user sub accepts an
#               argument of type scalar!
#
# Optional arguments:
#
#     A scalar or scalar reference containing the data you want to be logged.
#     A scalar containing the level at which to log.
#
# Returns:      upon success:  TRUE
#               upon failure:  undefined


  sub _log_it(;$$) {

    # Get all arguments passed in
      my($in_data, $log_level) = @_;

    # Local Variables
      my $out_data;   # Used to store the final stringified data to be logged.
      my $rv;         # Used to store a return value

    # First, determine if the $in_data provided is a scalar or a reference to a 
    # scalar, and set $out_data to always be a scalar.
      if   (ref($in_data) =~ /SCALAR/og)
           {$out_data = $$in_data;    # Dereference the scalar reference, to get the raw scalar data
           }# end if
      else {$out_data = $in_data;
           }# end else

      my $current_time = time();       # Need this for the log message
      my $delim = '|';
      my $level = '';
      if (defined $log_level) {
	if ($log_level == LOG_DEBUG) {$level='DEBUG'};
	if ($log_level == LOG_INFO) {$level='INFO'};
	if ($log_level == LOG_WARN) {$level='WARNING'};
	if ($log_level == LOG_ERROR) {$level='ERROR'};
	if ($log_level == LOG_FATAL) {$level='CRITICAL'};
      }

      # Construct context for the log message
      my $header = scalar (localtime) . $delim . # Current system date in form of MM-DD-YYYY
               $level . ": ";                                             # Logging level (debug, info, error, etc.)
      if ($LOG_HEADER){
	$out_data = $header . $out_data;
      }

    # Now print the log data.  Either pass it to the handler provided in the lexical
    # var $LOG_SUB_HANDLE or print it to the $LOG_FILE_HANDLE.
      if   ($LOG_SUB_HANDLE)
           {&$LOG_SUB_HANDLE($out_data); # Peform logging with user supplied subroutine reference.
            $rv = 1;                     # Since we don't know anything about the user supplied handler,
                                         # we'll assume success.
           }# end if
      else {$rv = print $LOG_FILE_HANDLE ($out_data);
           }# end else

    # Return success or failure to the caller.
      if   ($rv)                # Success
           {return(TRUE);
           }# end if
      else {return(undef());    # Failure
           }# end else

  }# end sub _log_it()





# _logThis()
#
# Description:  Instance method used as a wrapper for the local subroutine _log_it().
#
# Access:       Private
#
# Arguments:    01 [R]  A refernce to an object of type eBay::API
#               02 [O]  A scalar or scalar reference containing the data you want to be logged.
#               02 [O]  A scalar containing the logging level
#
# Returns:      upon success:  same as _log_it()
#               upon failure:  same as _log_it()

  sub _logThis($;$$) {

    # Get all arguments passed in
      my($self, $in_data, $level) = @_;

    # Local Variables
      my $this_sub = '_logThis()';  # Used for logging
      my $rv;                       # Used to store a return value

    # Just call the local subroutine _log_it to perform the actual logging.
      $rv = _log_it($in_data, $level);

    # Return whaver return code came back from _log_it to the caller.
      return($rv);

  }# end sub _logThis()


=pod

=head2 logDebug()

Public convenience method to log debug messages.  This is the same as doing

  $rc = $api->logMessage(eBay::API::BaseApi::LOG_DEBUG, "This is debug message.\n");

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar data to be logged.

=back

Returns:

=over 4

=item *

True if message was logged; otherwise undef.

=back

=cut


  sub  logDebug($$;)  {
    my ($self,  $msg) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($msg, Params::Validate::SCALAR);

    return $self->logMessage(LOG_DEBUG, $msg);
  }



=pod

=head2 logInfo()

Public convenience method to log info messages.  This is the same as doing

  $rc = $api->logMessage(eBay::API::BaseApi::LOG_INFO, "This is an info message.\n");

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar data to be logged.

=back

Returns:

=over 4

=item *

True if message was logged; otherwise undef.

=back

=cut


  sub  logInfo($$;)  {
    my ($self,  $msg) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($msg, Params::Validate::SCALAR);

    return $self->logMessage(LOG_INFO, $msg);
  }



=pod

=head2 logError()

Public convenience method to log error messages.  This is the same as doing

  $rc = $api->logMessage(eBay::API::BaseApi::LOG_ERROR, "This is an error message.\n");

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar data to be logged.

=back

Returns:

=over 4

=item *

True if message was logged; otherwise undef.

=back

=cut


  sub  logError($$;)  {
    my ($self,  $msg) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($msg, Params::Validate::SCALAR);

    return $self->logMessage(LOG_ERROR, $msg);
  }




=pod

=head2 logMessage()

Description: Instance method to log application events.  This is the
main entry point for logging messages that should be filtered
depending on the setting for the logging level.  If the logging level
of the message is lower than the current default logging level, the
message will NOT be logged.

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar log level.

=item *

Scalar data to be logged.

=back

Returns:

=over 4

=item *

True if message was logged; otherwise undef.

=back

=cut




  sub logMessage($$$;) {

    my ($self, $loglevel, $msg) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($loglevel, Params::Validate::SCALAR);
    eBay::API::BaseApi::_check_arg($msg, Params::Validate::SCALAR);

    if ($loglevel >= $LOG_LEVEL) {
      return (_log_it($msg, $loglevel));
    }
    return (undef());
  }





=pod

=head2 logXml()

Description: Instance method to log application xml text.  This is
mainly a wrapper to logMessage() and takes the same arguments.  This
method assumes the message text is valid xml and will use XML::Tidy
to clean it up some before logging it.

If the xml cannot be parsed and cleaned up, it will just be logged 'as
is'.

Warning: XML::Tidy does not handle headers like

  <?xml version="1.0" encoding="utf-8" ?>

and will DELETE them from the message.

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar log level.

=item *

Scalar data to be logged.

=back

Returns:

=over 4

=item *

True if message was logged; otherwise undef.

=back

=cut




  sub logXml($$$;) {

    my ($self, $loglevel, $msg) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($loglevel, Params::Validate::SCALAR);
    eBay::API::BaseApi::_check_arg($msg, Params::Validate::SCALAR);

    if ($loglevel >= $LOG_LEVEL) {
      my $t = new XML::Tidy($msg);
      # XML::Tidy trashes things like: <?xml version="1.0" encoding="utf-8" ?> !!!
      # TODO: read up on Tidy some more and see if there is a switch to stop this
      my $tidytext;
      eval {
	$tidytext = $t->tidy()->toString();
      };
      # if tidy croaked just log the message
      if ($@) {
	return (_log_it($msg, $loglevel));
      } else {
	return (_log_it($tidytext . "\n", $loglevel));
      }
    }
    return (undef());
  }



=head2 setLogSubHandle()

Sets the class variable, $LOG_SUB_HANDLE, which allows users to
customize all of its logging features, and those of it's children.
The only required argument is a reference to a subroutine that should
be able to accept a single scalar argument.  By setting this, all
logging normally performed by this and child modules will be tasked to
the user provided handler.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Reference to a logging handler subroutine, provided by user

=back

Returns:

=over 4

=item *

B<success> The value of $LOG_SUB_HANDLE after setting with user
provided sub reference (should be the same value that was provided by
the user)

=item *

B<error> undefined

=back

=cut


  sub setLogSubHandle ($$;) {

    # Local Variables
    my $this_sub = 'setLogSubHandle';      # Used for logging

    # Get all values passed in
    my ($self, $subref) = @_;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    # Validate that we really have a subroutine reference.
    if (ref($subref) !~ /CODE/o) {
      $LOG_SUB_HANDLE = undef();
       return(undef());
     }# end if

    # If we got this far, must be a valid sub reference, set it.
    $LOG_SUB_HANDLE = $subref;

    # Return success to the caller.
      return($LOG_SUB_HANDLE);

  }# end sub setLogSubHandle()



=head2 getLogSubHandle()

Returns a reference to a subroutine handling logging messages if one
has been set by setLogSubHandle() previously.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success>  The current value of $LOG_SUB_HANDLE

=item *

B<error>    undefined, not currently possible to get this

=back

=cut




 sub getLogSubHandle ($;) {

   my $self = shift;
    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    # Return success to the caller.
      return($LOG_SUB_HANDLE);

 }# end sub getLogSubHandle()



=head2 setLogFileHandle()

Sets a custom log file handle, which will allow users of this module
to customize all of its logging features, and those of it's children.
The log file handle argument is a typeglob (or reference to a
typeglob; e.g. \*STDOUT) of a file handle that the user wishes all
error/app logging be sent to, instead of the default STDERR.  By
setting this, all logging normally performed by this and child modules
will be sent to the user provided file handle.

Arguments:

=over 4

=item *

Reference to object of type eBay::API.

=item *

Typeglob (or reference to a typeglob) of a user specific file handle

=back

Returns:

=over 4

=item *

B<success> The value of $LOG_FILE_HANDLE after setting with user
provided file handle.  (It should be the same value that was provided
by the user.)

=item *

B<error>    undefined

=back

=cut


  sub setLogFileHandle ($$;) {

    # Local Variables
    my $this_sub = 'setLogFileHandle';      # Used for logging

    # Get all values passed in
    my ($self, $fh) = @_;

    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($fh, Params::Validate::GLOB | Params::Validate::GLOBREF);

    # If we got this far, must be a valid file handle, set it.
    $LOG_FILE_HANDLE = $fh;

    # Return success to the caller.
    return($LOG_FILE_HANDLE);

  }# end sub setLogFileHandle()



=head2 getLogFileHandle()

Returns the current log file handle.  If this had not been previously
set by the user of the module, it should return STDERR.

Arguments:    none

Returns:

=over 4

=item *

B<success>  The current value of $LOG_FILE_HANDLE

=item *

B<error>    undefined, not currently possible to get this

=back

=cut



  sub getLogFileHandle ($;) {

    my $self = shift;

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    # Return success to the caller.
    return($LOG_FILE_HANDLE);

  }# end sub getLogFileHandle()



=head2 testLogEntry()

Testing any user-specific overrides to default log output file or logging handler
subroutine.

Arguments:

=over 4

=item *

Reference to object of type eBay::API.

=item *

Scalar representing some test data to log.

=back

Returns:

=over 4

=item *

B<success>  TRUE

=item *

B<error>    undefined

=back

=cut



  sub testLogEntry (;$) {

    # Local Variables
      my $this_sub = 'testLogEntry';      # Used for logging
      my $rv;                             # Used for storing return codes

    # Get any values passed in.
      my($self, $test_data) = @_;

    # Attempt to print the test data using the internal class method _log_it().
      chomp($test_data);
      $rv = _log_it($this_mod . '::' . 
		    $this_sub . ': Test Log Entry = ' . $test_data . "\n");

    # Return success/failure to the caller.
      if   ($rv)
           {return(TRUE);
           }# end if
      else {return(undef());
           }# end else

  }# end sub testLogEntry()



=head2 dumpObject()

Instance method use mostly for debugging.  It will dump the entire
structure of an object.  If an object is supplied as an argument,
that object will be dumped; otherwise the instance of the class
calling this method will be dumped in its entirety.

By design, the dump will use the protected logging method _logThis(),
so whatever settings the user has to override the default logging,
that where it will go, hopefully ...

You need to have log level DEBUG set for this to actually log
anything.

Arguments:

=over 4

=item *

Object reference of type eBay::API::* or lower.

=item *

Optional object or hash reference.

=back

Returns:

=over 4

=item *

B<success> Whatever _logThis() returns. (Note: It will however dump
the entire structure of the object at this point in time.)

=item *

B<error>    Whatever _logThis() returns.

=back

=cut



  sub dumpObject($;$) {

    # Get all values passed in.
      my($self, $object) = @_;

    # Local Variables
      my $this_sub = 'dumpObject()';    # Used for logging.
      my $rv;                           # Stores a return value.

#     Set the indentation for Data::Dumper.

#     Description taken from Data::Dumper:

#       Controls the style of indentation. It can be set to 0, 1, 2 or
#       3. Style 0 spews output without any newlines, indentation, or
#       spaces between list items. It is the most compact format
#       possible that can still be called valid perl. Style 1 outputs a
#       readable form with newlines but no fancy indentation (each
#       level in the structure is simply indented by a fixed amount of
#       whitespace).  Style 2 (the default) outputs a very readable
#       form which takes into account the length of hash keys (so the
#       hash value lines up). Style 3 is like style 2, but also
#       annotates the elements of arrays with their index (but the
#       comment is on its own line, so array output consumes twice the
#       number of lines). Style 2 is the default.


        $Data::Dumper::Indent = 1;

# Since 5.8.1 Dumper randomizes the order of hash keys for security
# reasons.  We don't want that if we need to diff output results from
# different versions of the software for unit test purposes.  So
# turn key sorting back on.

        $Data::Dumper::Sortkeys = 1;

    # Dump the entire object
      if (defined $object) {
	$rv = $self->_logThis($this_mod . '::' . $this_sub . "\n" .
			      'Dump of current object of type \'' . ref($object) . "'\n" .
			      "--------------------------------------------------------------------------------\n" .
			      Dumper($object) . "\n", eBay::API::BaseApi::LOG_DEBUG
			     );
      } else {
	$rv = $self->_logThis($this_mod . '::' . $this_sub . "\n" .
			      'Dump of current object of type \'' . ref($self) . "'\n" .
			      "--------------------------------------------------------------------------------\n" .
			      Dumper($self) . "\n",eBay::API::BaseApi::LOG_DEBUG
			     );
      }

    # Return success to the caller.
      return($rv);

  }# end sub dumpObject()






=head2 setLogLevel()

Setter method for setting the logging level of eBay::API and all child
classes.  Log levels may be set with any of the following constants.

=over 4

=item *

B<eBay::API::BaseApi::LOG_DEBUG> Full debugging information is logged, along
with all log messages of higher levels.

=item *

B<eBay::API::BaseApi::LOG_INFO> Informational and all higher logging level
messages are logged.

=item *

B<eBay::API::BaseApi::LOG_WARN> Warnings and all higher logging level messages
are logged.

=item *

B<eBay::API::BaseApi::LOG_ERROR> Errors and all higher logging level messages
are logged.

=item *

B<eBay::API::BaseApi::LOG_FATAL> Only errors which causes immediate termination
of the current transaction are logged.

=back

Arguments:

=over 4

=item *

Reference to object of type eBay::API.

=item  *

Scalar constant logging level.

=back

Returns:

=over 4

=item  *

B<success>:  The logging level requested.

=item  *

B<error>: Undef if an invalid logging level is requested.  In this
case the logging level is left unchanged from the current logging
level.

=back

=cut



  sub setLogLevel($$;) {


    # Get all values passed in.
    my ($self, $level) = @_;

    # Validate the arguments.
    # Sub prototype deals with case of missing required argument

    # Validate the arguments
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($level, Params::Validate::SCALAR);

    $LOG_LEVEL = $level;

    # Return success to the caller
    return($LOG_LEVEL);

  }# end sub setLogLevel()



=head2 getLogLevel()

Get the current logging level.  See setLoglevel() for details on the
logging levels supported.

Arguments:    none

Returns:

=over 4

=item *

B<success>:  The current logging level.

=item *

B<error>:    undefined

=back

=cut



  sub getLogLevel($;) {

    # Local Variables
    #my $this_sub = 'getDebug';    # Used for logging

    my $self = shift;

    # validate that first argument is blessed object
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    # Return success to the caller
    return($LOG_LEVEL);

  }# end sub getLogLevel()

=head2 setDevID()

Sets the dev id for api certification. This variable is set to default
to the value of $ENV{EBAY_API_DEV_ID}. You can override this either
when constructing a session object or by using this method after
construction of the session.

Arguments:

=over 4

=item *

Reference to object of type eBay::API::XML::Session.

=item *

Scalar representing the eBay Developer ID of the eBay API request.

=back

Returns:

=over 4

=item *

B<success>  The value of the dev id.

=item *

B<error>    undefined

=back

=cut



  sub setDevID($$;) {

    # Local Variables
    #my $this_sub = 'setDevID';

    # Get all values passed in.
    my($self, $devid) = @_;

    # Some validation of the existence of the argument is done implicitly via the sub prototype.
    # validate the arguments for existence and data type
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($devid, Params::Validate::SCALAR);


    $self->{dev_id} = $devid;

    # Return success to the caller.
    return($devid);

  }# end sub setDevID()



=head2 getDevID()

Gets the current dev id setting.

Arguments:

=over 4

=item *

Reference to a session object.

=back

Returns:

=over 4

=item *

B<success>  The value of the dev id.

=item *

B<error>    undefined

=back

=cut



  sub getDevID($;) {

    # Local Variables
    #my $this_sub = 'getDevID';

    my $self = shift;

    # validate the arguments for existence and data type
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


    # Return success to the caller.
    return($self->{dev_id});

  }# end sub getDevID()



=head2 setAppID()

Sets the app id for ebay certification.  This value defaults to
$ENV{EBAY_API_APP_ID}, and is overridden either by calling this method
or if it is specified when constructing a session object.

Arguments:

=over 4

=item *

Reference to a session object.

=item *

Scalar representing the eBay Application ID of the eBay API request.

=back

Returns:

=over 4

=item *

B<success>  The value of new app id.

=item *

B<error>    undefined

=back

=cut




  sub setAppID($$;) {

    # Local Variables
    #my $this_sub = 'setAppID';

    # Get all values passed in.
    my($self, $appid) = @_;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($appid, Params::Validate::SCALAR);

    # Set the proxy
    $self->{app_id} = $appid;

    # Return success to the caller.
    return($appid);

  }# end sub setAppID()



=head2 getAppID()

Get the current app id for the session.

Arguments:

=over 4

=item *

Reference to a session object.

=back

Returns:

=over 4

=item *

B<success>  The value of the app id.

=item *

B<error>    undefined

=back

=cut



  sub getAppID($;) {

    # Local Variables
    #my $this_sub = 'getAppID';

    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


    # Return success to the caller.
    return($self->{app_id});

  }# end sub getAppID()



=head2 setCertID()

Sets the cert id for the session.  This overrides any default in
$ENV{EBAY_API_CERT_ID}, or any value specified when the session was
originally constructed.

Arguments:

=over 4

=item *

Reference to a session object.

=item *

Scalar representing the eBay Certification ID of the eBay API request.

=back

Returns:

=over 4

=item *

B<success> The cert id just set.

=item *

B<error>    undefined

=back

=cut




  sub setCertID($$;) {

    # Local Variables
    #my $this_sub = 'setCertID';

    # Get all values passed in.
    my($self, $certid) = @_;
    # Validation of the existence of the argument is done implicitly via the sub prototype.

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($certid, Params::Validate::SCALAR);


    # Set the proxy
    $self->{cert_id} = $certid;

    # Return success to the caller.
    return($certid);

  }# end sub setCertID()



=head2 getCertID()

Gets current cert id.

Arguments:

=over 4

=item *

Reference to session object.

=back

Returns:

=over 4

=item *

B<success>  The value of the cert id.

=item *

B<error>    undefined

=back

=cut



  sub getCertID($;) {

    # Local Variables
    #my $this_sub = 'getCertID';

    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


    # Return success to the caller.
      return($self->{cert_id});

  }# end sub getCertID()




=head2 setSiteID()

Instance method to set the site id for the current session.  This will override
any global setting of the site id that was set at the package level by the
environment variable $ENV{EBAY_API_SITE_ID}, or when a Session object is
first constructed.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Scalar site id.

=back

Returns:

=over 4

=item *

B<success> Site id given as argument.

=item *

B<error> undefined

=back


=cut




  sub setSiteID ($$;) {
    my ($self, $site_id) = @_;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($site_id, Params::Validate::SCALAR);


    $self->{site_id} = $site_id;
    return $site_id;
  }




=head2 getSiteID()

Returns the current site id for the current session.  Note that this may
be different than the global site id for the package.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success> Site id given for the current session.

=item *

B<error> undefined

=back


=cut



  sub getSiteID ($;) {
    my $self = shift;
    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    return $self->{site_id};
  }



=head2 setUserName()

Instance method to set the application user name for the current
session.  This will override any global setting of the user name that
was set at the package level by the environment variable
$ENV{EBAY_API_USER_NAME}, or when a Session object is first
constructed.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Scalar user name.

=back

Returns:

=over 4

=item *

B<success> User name given as argument.

=item *

B<error> undefined

=back


=cut




  sub setUserName ($$;) {
    my ($self, $user_name) = @_;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    $self->{user_name} = $user_name;
    return $user_name;
  }

=head2 getUserName()

Returns the current application user name for the current session.
Note that this may be different than the global user name for the
package.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success> User name given for the current session.

=item *

B<error> undefined

=back


=cut



  sub getUserName ($;) {
    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    return $self->{user_name};
  }


#########



=head2 setUserPassword()

Instance method to set the application user password for the current
session.  This will override any global setting of the user password that
was set at the package level by the environment variable
$ENV{EBAY_API_USER_PASSWORD}, or when an API object is first
constructed.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Scalar user password.

=back

Returns:

=over 4

=item *

B<success> User password given as argument.

=item *

B<error> undefined

=back


=cut




  sub setUserPassword ($$;) {
    my ($self, $user_password) = @_;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($user_password, Params::Validate::SCALAR);

    $self->{user_password} = $user_password;
    return $user_password;
  }

=head2 getUserPassword()

Returns the current application user password for the current session.
Note that this may be different than the global user password for the
package.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success> User password given for the current session.

=item *

B<error> undefined

=back


=cut



  sub getUserPassword ($;) {
    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    return $self->{user_password};
  }



# Deprecated
#=pod
#
#=head2 setErrLang()
#
#Local setter method for setting the class attribute $EBAY_ERR_LANG.
#This variable is set to default to the value of
#$ENV{EBAY_API_XML_ERR_LANG}.  If you want to override the value, make
#sure to use this method before object instantiation.
#
#Arguments:
#
#=over 4
#
#=item *
#
#Scalar representing the desired locale representation of the error
#language you would like to have returned to you from XML responses.
#
#=back
#
#Returns:
#
#=over 4
#
#=item *
#
#B<success> The value of $EBAY_ERR_LANG (should be the same value that
#was provided by the user)
#
#=item *
#
#B<error>    undefined
#
#=back
#
#=cut
#
#
#
#
#  sub setErrLang($$;) {
#
#    # Get all values passed in.
#    my($self, $errlang) = @_;
#
#    # Validation of the existence of the argument is done implicitly via the sub prototype.
#    # Validation 
#    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
#    eBay::API::BaseApi::_check_arg($errlang, Params::Validate::SCALAR);
#
#    # Set the api error language
#    $self->{err_lang} = $errlang;
#
#    # Return success to the caller.
#      return($errlang);
#
#  }# end sub setErrLang()




# Deprecated
#=pod
#
#=head2 getErrLang()
#
#Local getter method for getting the current value of $EBAY_ERR_LANG.
#
#Arguments:    none
#
#Returns:
#
#=over 4
#
#=item *
#
#B<success>  The value of $EBAY_ERR_LANG
#
#=item *
#
#B<error>    undefined
#
#=back
#
#=cut
#
#
#
#  sub getErrLang($;) {
#
#    my $self = shift;
#
#    # Validation 
#    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
#
#    # Return success to the caller.
#    return($self->{err_lang});
#
#  }# end sub getErrLang()









# _setError()
#
# Description: 
#
# Private instance setter method for setting the latest
# error message encountered during an eBay API call.
#
# Access:  private
#
# Arguments:    Reference to an object of type eBay::API
#
# Returns:   Error message being set

  sub _setError($$;) {

    # Local Variables
    my $this_sub = '_setError';      # Used for logging

    # Get values passed in
    my($obj, $error) = @_;

    # Validate arguments
    # Argument existence enforced from sub prototype.

    # Validation
    eBay::API::BaseApi::_check_arg($obj, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($error, Params::Validate::SCALAR);

    # Set the error
    $ERROR = $obj->{error} = $error;

    # Return success to the caller.
    return($ERROR);

  }# end sub _setError()



=head2 getError()

Instance getter method for retrieving the generic error for currrent
state of the session.  Consult the other information such as the logs,
or the status of other api objects such as api call objects for more
detailed error information.  If all requests have completed
successfully, there will be no error information.  If any of the
requests have had an error, then there will some message to this
effect.

Arguments:

=over 4

=item  *

Reference to an object of type eBay::API.

=back

Returns:

=over 4

=item  *

B<success>: Last error encountered during while executing an eBay::API
call.  undef if no errors were encountered.

Note: An empty error value can return this as well, which in this case
would be success.

=back

=cut

  sub getError($;) {

    # Get values passed in
    my($obj) = @_;

    # Validation
    eBay::API::BaseApi::_check_arg($obj, Params::Validate::OBJECT);

    # If we pass validation, return success to the caller.
    return( $obj->{error} || undef() );

  }# end sub getError()





=head2 isSuccess()

Indicates B<general> status of the eBay::API object (usually a
session, or an API call itself).  Call this after execute() to see if
errors were encountered.

Arguments: none

Returns:

=over 4

=item *

B<success> Boolean true if all reponses for the request(s) were returned
without problems by the eBay API.

=item *

B<failure> Boolean false if there was either a general problem with
getting response(s) back from the eBay API, or if there was a failure on
one or more of the bundled request.  Consult the error status of each
response for more information.

=back

=cut


  sub isSuccess($;) {
    my $obj = shift;

    # Validation
    eBay::API::BaseApi::_check_arg($obj, Params::Validate::OBJECT);

    return (defined $obj->{error} && $obj->{error}) ? 1 : 0;
  }




=head2 setAuthToken()

Instance method to set the application user auth token for the current
session.  This will override any global setting of the user auth token that
was set at the package level by the environment variable
$ENV{EBAY_API_AUTH_TOKEN}, or when an API object is first
constructed.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Scalar user auth token.

=back

Returns:

=over 4

=item *

B<success> User auth token given as argument.

=item *

B<error> undefined

=back


=cut




  sub setAuthToken ($$;) {
    my ($self, $user_auth_token) = @_;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


    $self->{user_auth_token} = $user_auth_token;
    return $user_auth_token;
  }



=head2 getAuthToken()

Returns the current application user auth token for the current session.
Note that this may be different than the global user auth token for the
package.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success> User auth token given for the current session.

=item *

B<error> undefined

=back


=cut



  sub getAuthToken ($;) {
    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


    return $self->{user_auth_token};
  }





=head2 setCompatibilityLevel()

Instance method to set the XML API compatibility level for the current
session.  This will override any global default setting at the package
level.

Note that the compatibility level is defaulted with each release of
the API.  However you can override that default with the environment
variable, $ENV{EBAY_API_COMPATIBILITY_LEVEL}, when you construct a
session object, or by using this setter method.


Arguments:

=over 4

=item *

Object reference of type eBay::API.

=item *

Scalar compatibility level.

=back

Returns:

=over 4

=item *

B<success> Compatibility level given as argument.

=item *

B<error> undefined

=back


=cut




  sub setCompatibilityLevel ($$;) {
    my ($self, $level) = @_;

    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($level, Params::Validate::SCALAR);

    $self->{compatibility_level} = $level;
    return $level;
  }

=head2 getCompatibilityLevel()

Returns the XML API compatibility level for the current session.  Note that this may
be different than the global default for the package.

Arguments:

=over 4

=item *

Object reference of type eBay::API.

=back

Returns:

=over 4

=item *

B<success> Compatibility level for the current session.

=item *

B<error> undefined

=back


=cut



  sub getCompatibilityLevel ($;) {
    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    return $self->{compatibility_level};
  }




=head2 setVersion()

Instance method to set the api version to something other than the default value, or the
value specified when an eBay::API object was instantiated.

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=item *

Scalar representing the version of the the eBay webservices API you
wish to use.

=back

Returns:

=over 4

=item *

B<success> The value of API version (should be the same value
that was provided by the user)

=item *

B<error>    undefined

=back

=cut



  sub setVersion($$;) {

    # Get all values passed in.
    my($self, $apiver) = @_;

    # Validation of the existence of the argument is done implicitly via the sub prototype.
    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($apiver, Params::Validate::SCALAR);

    # Set the proxy
    $self->{api_ver} = $apiver;

    # Return success to the caller.
    return($apiver);

  }# end sub setVersion()



=head2 getVersion()

Instance getter method for getting the current ebay api version level
to be used.

Arguments:

=over 4

=item *

Reference to an object of type eBay::API.

=back

Returns:

=over 4

=item *

B<success>  The value of the current ebay api version to be used.

=item *

B<error>    undefined

=back

=cut

  sub getVersion($;) {

    my $self = shift;

    # Validation 
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    # Return success to the caller.
    return $self->{api_ver};

  }# end sub getVersion()




=head2 setCompression()

Enables/disables compression in the HTTP header.  This tells the API
whether the client application can accept gzipped content or not.
Do not set this unless you have CPAN module Compress::Zlib.

Arguments:

=over 4

=item *

A reference to object of type eBay::API.

=item *

Boolean value (0 = false; non-zero = true);

=back

Returns: 

=over 4

=item *

The boolean value to be set for this attribute.

=back

=cut




  sub setCompression($$;) {
    my $self = shift;
    my $bool = shift;

    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    eBay::API::BaseApi::_check_arg($bool, Params::Validate::BOOLEAN);

    $self->{compression} = $bool;
    return $bool;
  }


=head2 isCompression()

Indicates if gzip compression has been requested from the API.

Arguments: 

=over 4

=item *

A reference to an object of type eBay::API.

=back

Returns: 

=over 4

=item *

True if compression is enabled; false if it is not

=back

=cut



  sub isCompression($;) {
    my $self = shift;

    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

    return $self->{compression};
  }

=pod

=head2 setTimeout()

Call this instance method to set the number of seconds a session or a call should wait
for the eBay XML API web services to respond to a request.  This parameter
controls the behavior of the call retry logic.

Arguments:

=over 4


=item *

The name  of this class/package.

=item *

(Required) A scalar integer value indicating the number of seconds to
wait for a web service request to return with a response.

=back

Returns:

=over 4

=item *

Undefined.

=back

=cut


  sub setTimeout($$;) {
    my $self = shift;
    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    $self->{'timeout'} = shift;
  }


=pod

=head2 getTimeout()

Call this instance method to get the number of seconds a session or a call should wait
for the eBay XML API web services to respond to a request.  This parameter
controls the behavior of the call retry logic.

Arguments:

=over 4


=item *

The name  of this class/package.

=back

Returns:

=over 4

=item *

The number of seconds the call or session should currently wait for a response
from a web service.

=back

=cut


  sub getTimeout($;) {
    my $self = shift;
    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    return $self->{'timeout'};
  }


=pod

=head2 setCallRetry()

Call this instance method to set the number of times a session or a call should
retry an eBay XML API web service before giving up.  This parameter
controls the behavior of the call retry logic.

Arguments:

=over 4


=item *

The name  of this class/package.

=item *

(Required) A reference to an object of type eBay::API::XML::CallRetry.  This
object contains parameters controlling how to retry a call if there is an
error, including number of times to retry, delay in milliseconds between retries,
a list of errors that will permit a retry.  See CallRetry documentation
for more details.

=back

Returns:

=over 4

=item *

Undefined.

=back

=cut


  sub setCallRetry($$;) {
    my $self = shift;
    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    $self->{'callRetry'} = shift;
  }


=pod

=head2 getCallRetry()

Call this instance method to get any eBay::API::XML::CallRetry object
that has previously been set to control retry behavior.

Arguments:

=over 4


=item *

The name  of this class/package.

=back

Returns:

=over 4

=item *

The number of times the call or session should currently retry for a response
from a web service.

=back

=cut


  sub getCallRetry($;) {
    my $self = shift;
    # Validation
    eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
    return $self->{'callRetry'};
  }


=pod

=head2 getApiReleaseNumber()

Modifier: static
Access:   public
Note:     Returns the SDK's release number

=cut

sub getApiReleaseNumber() {
   return eBay::API::XML::Release::RELEASE_NUMBER;
}

# _check_arg()

#  Protected package method to validate arguments to subroutines.  Uses
#  CPAN module Params::Validate.  Will throw exceptions if parameters
#  are not correct.

#  Returns false if the parameter check occurred and it failed; otherwise
#  returns true.

sub _check_arg ($$;) {
  if ($CHECK_PARAMETERS) {
    my $argvalue = shift;
    my $argtype = shift;
    my @args;
    push(@args, $argvalue);
    eval {
      validate_pos(@args, { type => $argtype });
    };
    if ($@) {
      my ($package, $filename, $line) = caller;
      $argvalue = (defined $argvalue) ? $argvalue : 'null';
      ebay_throw eBay::API::UsageException(error => 'Invalid argument type: ' . $argvalue,
					   package  => $package,
					   file  => $filename,
					   line => $line);
      return 0;
    }
  }
  return 1;
}


=pod

=head2 enableParameterChecks()

Public package method to enable run-time validation of arguments to
subroutines in the eBay::API package.  Checking is enabled by default,
but you may want to disable checking in production to reduce overhead.
Having checking enabled is probably most useful during development of
your application.

This method is both a getter and a setter.

Usage:


  if (eBay::API::BaseApi::enableParameterChecks()) {
    eBay::API::BaseApi::enableParameterChecks(0);
  }

Arguments:

=over 4

=item *

(Optional) A scalar boolean value to enable (non-zero) or disable (0)
run-time parameter checking in the eBay::API package.

=back

Returns:

=over 4

=item *

True if checking is enabled; false if it is not.

=back

=cut

sub enableParameterChecks(;$) {
  my $bool = shift;
  if (defined $bool) {
    $CHECK_PARAMETERS = $bool;
  }
  return $CHECK_PARAMETERS;
}

1;
