################################################################################
# Location: ...................... <user defined location>/eBay
# File: .......................... API.pm
#
# Description
#
# This is actually a place holder module used strictly for controlling the name-
# space of this library, as well as to provide general usage documentation.
################################################################################





# Package Declaration
# ------------------------------------------------------------------------------
  package eBay::API;





# Required Includes
# ------------------------------------------------------------------------------
  use 5.008001;          # Need to use this version of Perl, or later
  use strict;            # Needed to control variable hell
  use warnings;          # Needed to catch perl compilation warnings
  use Exporter;          # Used to provide symbol exportation





# Variable Declarations
# ------------------------------------------------------------------------------
# Constants
  # none

# Globals
  our $VERSION = '0.25';

# Lexicals
  # none





# Subroutine Prototypes
# ------------------------------------------------------------------------------
# none





# Main Script
# ------------------------------------------------------------------------------
# none





# Return TRUE to Perl
1;

__END__





# eBay Perl SDK - Getting Started Guide
# ------------------------------------------------------------------------------
=pod

=head1 NAME

eBay::API - Perl SDK for eBay Web services Interface



=head1 SYNOPSIS

# 1. GeteBayOfficialTime
     use eBay::API::XML::Call::GeteBayOfficialTime;

     my $pCall = eBay::API::XML::Call::GeteBayOfficialTime->new();
     $pCall->execute();
     my $sOfficialTime = $pCall->getEBayOfficialTime();

# 2. GetUser
     use eBay::API::XML::Call::GetUser;
     use eBay::API::XML::DataType::Enum::DetailLevelCodeType;

     my $pCall = eBay::API::XML::Call::GetUser->new();
     $pCall->setDetailLevel( [eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll] );
     $pCall->setUserID('userId');
     $pCall->execute();

     my $pUser = $pCall->getUser();
     my $sStatusCode = $pUser->getStatus();
     my $sSiteCode  = $pUser->getSite();

# 3. VerifyAddItem
     use eBay::API::XML::Call::VerifyAddItem;
     use eBay::API::XML::DataType::ItemType;
     use eBay::API::XML::DataType::CategoryType;
     use eBay::API::XML::DataType::Enum::CountryCodeType;
     use eBay::API::XML::DataType::Enum::CurrencyCodeType;
     use eBay::API::XML::DataType::Enum::ListingTypeCodeType;
     use eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;

     my $pItem = eBay::API::XML::DataType::ItemType->new();
     $pItem->setCountry(eBay::API::XML::DataType::Enum::CountryCodeType::US);
     $pItem->setCurrency(eBay::API::XML::DataType::Enum::CurrencyCodeType::USD);
     $pItem->setDescription('item description.');
     $pItem->setListingDuration(eBay::API::XML::DataType::Enum::ListingTypeCodeType::Days_1);
     $pItem->setLocation('San Jose, CA');
     $pItem->setPaymentMethods(eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription);
     $pItem->setQuantity(1);
     $pItem->getStartPrice()->setValue(1.0);
     $pItem->setTitle('item title');

     my $pCat = eBay::API::XML::DataType::CategoryType->new();
     $pCat->setCategoryID(357);
     $pItem->setPrimaryCategory($pCat);

     my $pCall = eBay::API::XML::Call::VerifyAddItem->new();

     $pCall->setItem($pItem);
     $pCall->execute();

     $sItemId = $pCall->getItemID()->getValue();


=head1 DESCRIPTION

This document describes the installation, configuration, and usage of
eBay::API module.

The eBay::API library is based on the eBay API XML schema and it does
not use SOAP to submit calls.  Other than differences in the SOAP
envelope and the way SOAP reports errors, the calls and data types
defined in eBay API XML schema and eBay API wsdl are almost exactly
the same.

You can retrieve the latest version of eBay API XML schema from:

   http://developer.ebay.com/webservices/latest/eBaySvc.xsd 

During installation that document is used to generate the library's
call and data type classes.

You can find additional documentation about eBay API XML schema
on the following URL:

   http://developer.ebay.com/DevZone/XML/docs/WebHelp/wwhelp/wwhimpl/js/html/wwhelp.htm

Each call and data type described in the above document has its Perl
module counterpart in this library. Also, each property defined for
each call and data type has a setter/getter counterpart.

This library is rich in features.  The consequence of this is some
degree of complexity.  It is hoped, the accompanying documentation
will help to ease the task of familiarizing yourself with the library.
Suggestions for improvements are always welcome.

=head1 INSTALLATION

You can install this package either by using a CPAN installer, or by
downloading the package and manually installing it by the customary
method of perl Makefile.PL, etc.

There are a number of prerequisite CPAN modules you may need to
install.  If you run perl Makefile.PL, it will tell you which modules
you need to install.  Please also reference the INSTALL document provided
with this package.

=head1 PACKAGE FEATURES

=head2 eBay XML Web Service Interface

This library provides a complete library of classes and method to utilize
every published XML API call, including getter and setter methods for all
information delivered by the individual services.

=head2 Synchronous/Asynchronous Calls

By packaging multiple calls in the provided eBay::API::XML::Session
class, it is possible to invoke multiple, different API services
either in parallel (asynchronously) or sequentially.

See eBay::API::XML::Session for more details.

=head2 Optional Exception Framework

By using the eBay::Exception class, it is possible to incorporate
robust exception handling into your client application, and enable all
severe run-time exceptions to be logged with the library's logging
framework.

See documentation for eBay::Exception for more details.

=head2 Optional Logging Framework

The package includes a framework supporting application logging.  Some
of the features of this logging include optional message headers,
setting severity levels for logging, logging to files, and logging to
message handlers, or subroutines.

The five supported log levels are:

	use constant LOG_DEBUG => scalar 1;
	use constant LOG_INFO  => scalar 2;
	use constant LOG_WARN  => scalar 3;
	use constant LOG_ERROR => scalar 4;
	use constant LOG_FATAL => scalar 5;

See eBay::API::BaseApi documentation for details on the methods available
for managing logging.

See EXAMPLES below for some ways to use the logging framework.

=head2 Run Time Parameter Checking

As an extra sanity check, the number and type of arguments used when
calling many methods in the API package are checked for correctness.
Exceptions will be logged and thown if the arguments are not correct.

Parameter checking is enabled by default.  You may want to disable parameter
checking in a production environment if you are worried about 
performance costs.  However, the overhead should be minimal.

To disable parameter checking use the base API instance method:

  enableParameterChecks(0)  # zero means disable

To enable parameter checking use:

  enableParameterChecks(1)

=head2 Tools

The package includes tools to auto generate all classes needed to
invoke any published eBay XML API web service, including accessing all
data components accepted and delivered by the web services.

   lib/eBay/API/XML/tools/codegen/xsd

There is also a tool to generate indexed HTML documenation for every package
included in this library, or generated by this library.

   lib/eBay/API/XML/tools/doc

=head3 Auto Generation of Call & Data type Classes

When you first install the library, you need to be connected to the
internet (unless you disable the autogeneration at module installation time).
Part of the make process involves retrieving the latest eBay XML API schema
from the published xsd file, and using that file to generate the supporting
classes for the eBay web services.

The auto generation process also produces POD documentation
for the generated classes.

It is important to realize that you can B<regenerate> these
classes at any time.

eBay is constantly releasing new features that are made available to
the API.  The code generation toolset gives you the power to
transparently keep up with these enhancements and make them directly
available to your API-enabled applications as new versions of the eBay
API become available.

Consult the README file in lib/eBay/API/XML/tools/codegen/xsd for
instructions on how to update your generated eBay XML API web services
class library.

=head3 You Must Read/Reference The eBay XML API Schema Docs

It is B<VERY> important that all developers using this SDK read
and understand the eBay datatypes and calls as described in the API
documentation itself.  The autogenerated classes here cannot be a
substitute, as there exists limitations and assumptions in this SDK
that are necessary for this SDK to be able to provide the
autogeneration tools.  That being said, developers using this SDK
cannot rely on just the eBay API documentation alone either.  Due
to the same limitations and assumptions, there may not be a 1-to-1
correlation between the Perl SDK interface and what is described
in the API documentation; I cannot stress these points enough.

=head3 Generating HTML-style Documentation

CPAN offers the POD documentation accompanying the base classes in
HTML format.  But, since the majority of the classes in this library
are generated when the modules are installed, the documentation for
the generated classes only exists in POD format.

Using the genhtmldoc.pl tool (mentioned above in the Tools section),
you can create a library of indexed HTML documentation.  Consult the README
file in lib/eBay/API/XML/tools/doc for details on how to compile and access
HTML manual pages for the generated classes from a web browser.


=head2 Error Stub Capability

An important part of any application is thoughtful error handling.
The eBay web services take up much of the burden by thoroughly
validating most of the imputs you provide with your web service
requests.  The error stub capability allows you to simulate various
API error codes likely to be return by a given web service response so
you can test the error handling logic of your applications.

See the section on the base forceError() method inherited by each web
service call class below for more details on the error stub capability.

=head1 PACKAGE OVERVIEW

=head2 Provided Classes

=head3 eBay/API.pm

This is a very generic module, that really only exists for the following
reasons:

    a)  To support the namespace of this package
    b)  To contain the overall $VERSION of this package
    c)  To contain the general documentation for this package

=head3 eBay/Exception.pm

This module provides a framework to users of the eBay::API packages to
throw, catch and handle severe runtime exceptions gracefully.

The eBay::API exceptions inherit the functionality of CPAN modules
Exceptions::Class and Error, including such informational fields as
message, error, time, package, etc.

See the documentation for eBay/Exception.pm for details on how to
enable exception handling.

=head3 eBay/API/BaseAPI.pm

This class is the base class for all classes in the API hierarchy,
especially the generated classes supporting the various eBay API calls
and data types.  The class contains the base class constructor, and
supporting frameworks for logging, internal exception handling and
management of ebay certification (AuthNAuth) information.  All classes
in the eBay::API::XML class path extend from the BaseAPI.

In the future, any new extension to this package for supporting
different API protocols (such as SOAP) should "extend" itself from
this class.

=head3 eBay/API/XML/BaseXML.pm

BaseXML class extends BaseAPI class and at this moment it contains
just one property: ApiUrl.  This property is used to set URL to be
used for calls against the XML version of the eBay web services API.

=head3 eBay/API/XML/BaseCallGen.pm

BaseCallGen class extends BaseXML class and it is a parent class for
BaseCall class.  It contains request and response properties that are
common for all calls.

This class is generated when the libary is installed and built on your
computer, or when the generated classes are rebuilt.

=head3 eBay/API/XML/BaseCall.pm

BaseCall class extends BaseCallGen class and it is being extended by
all API calls.  BaseCall class is responsible for submitting an API
request as well as processing the received response. It really
contains major logic for handling all API calls.

=head3 eBay/API/XML/BaseDataType.pm

This class is the most parent class of the DataType class
hierachy. All DataType classes extend this class. It contains methods
that serialize a DataType object into an XML document as well as
methods that deserialize an XML document into a DataType object. Its
internals should not be a concern for a user of this library.

=head3 eBay/API/XML/CallRetry.pm

This class is used internally by the the Session and BaseCall classes
to implement repeated calls to a web service in case of failure due to
timeouts, etc.

There are some shared methods available to calls and sessions that
allow you to tune the retry logic of your application:

   setTimeout() allows you specify how many seconds your application 
                should wait for a response.

   setCallRetry() allows you to specify how many times your application 
                should retry in case of a timeout before giving up.

For example, an application may want to wait a bit longer when
seeking results on a search query then it would to add a new auction
item.

See the eBay::API::BaseApi for more information on these and other
general directives you can adjust.

=head3 eBay/API/XML/Session.pm

This class collects multiple requests to the eBay XML API and submits
them sequentially or in parallel. When used in sequential mode it offers
some support for transactional integrity, minus the concept of a rollback.
For more details, including code examples see the documentation for
eBay/API/XML/Session.pm.

=head2 Generated Classes

The generated classes are placed in the following directory structure:

    lib/eBay/API/XML/Call                     Call base classes
    ib/eBay/API/XML/Call/AddItem (etc)        Call request and response classes
    lib/eBay/API/XML/DataType                 Complex data types (Item, User, etc.)
    lib/eBay/API/XML/DataType/Enum            Enumerated codes, types, etc.

See discussion below for more details on the generated classes and how
to use them.

=head1 SETTING eBay CREDENTIALS

There are a set of arguments that have to be set for each call.
Those arguments are:

    a) eBay API application credentials:  Dev ID, App ID, Cert ID
    b) API Transport - URL against calls are being executed.
    c) API Version and API compatibility level
    d) User credentials
       1. User Token
       2. UserName and UserPassword
       It is enough to set either user token or username and user password. If you set 
       both "User Token" and UserName/UserPassword than "User Token" is used.

There are two ways to set these arguments: 

     a) using ENV variables
     b) using provided setters

=head2 Via ENV variables

    The following ENV variables can be set so that you do not have to specify 
    credentials, proxy url, site id with each call:

    # eBay API application credentials
      $ENV{'EBAY_API_APP_ID'}='appid'
      $ENV{'EBAY_API_CERT_ID'}='certid'
      $ENV{'EBAY_API_DEV_ID'}='devid'

    # eBay User credentials
      $ENV{'EBAY_API_USER_AUTH_TOKEN'}='token';
      $ENV{'EBAY_API_USER_NAME'}='username';
      $ENV{'EBAY_API_USER_PASSWORD'}='password';

       Be aware that eBay User Credentials ENV variables are used for each call
       unless they are explicitly overwritten by appropriate call setters. So these
       credentials should be used only for anonymous calls while for non-anonymous 
       calls you should use credentials of a specific user on whose behalf you are
       submitting the call.

       Also, be aware that most API calls require the use of an auth token vice
       that of a userid/password.  Check the latest API documentation for further
       details.

    # eBay API URL
    # getApiUrl and setApiUrl
      $ENV{'EBAY_API_XML_TRANSPORT'} = 'https://api.sandbox.ebay.com/ws/api.dll';
      $ENV{'EBAY_API_URI'} = 'urn:ebay:apis:eBLBaseComponents'

    # site id
      $ENV{'EBAY_API_SITE_ID'}=0
    # additional call parameters
      $ENV{'EBAY_API_VERSION'}=461
      $ENV{'EBAY_API_COMPATIBILITY_LEVEL'}=461
      $ENV{'EBAY_API_XML_ERR_LANG'}='en_US'


=head2 Via provided setters

    # 1. Instantiate the API call object.
      my $pCall = eBay::API::XML::Call::GetUser->new();

    # 2.  set credentials, api URL, version (parameters common for all calls)

    # 2.1 set transport
      $pCall->setApiUrl('https://api.ebay.com');
      (For example, see official eBay API documentation for proper transport.)


    # 2.2 set application credentials
      $pCall->setDevID('devId');
      $pCall->setAppID('appId');
      $pCall->setCertID('certId');

    # 2.3 set user credentials
      $pCall->setAuthToken('token');
    #   or
      $pCall->setUserName('username');
      $pCall->setUserPassword('password');

    # 2.4 set siteId
    # You can find more about siteIDs in 
    # eBay::API::XML::DataType::Enum::SiteCodeType
      $pCall->setSiteID(0);  # US

    # 2.4 additional common arguments
      $pCall->setVersion(461);
      $pCall->setCompatibilityLevel($pCall->getVersion());
      $pCall->setErrLang('en_US');

    # 3. set arguments specific to current call and execute the call
      $pCall->setDetailLevel( [eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll] );
      $pCall->getUserID->setValue('userId');

    # 4. Execute the API call.
      $pCall->execute();

=head1 EXAMPLES

=head2 Authentication

See above.

=head2 Specific Web Service Requests

See synopsis above.

=head2 Application logging

The follow example shows how to use the logging framework in your
applications to log application events either to a file or to a 
message handler.

	use eBay::API::XML::Call::GeteBayOfficialTime;
	use strict;

	# Construct a call class

	my $pCall = eBay::API::XML::Call::GeteBayOfficialTime->new();

	# Initialize the logging facility.
	# These settings are package level and shared by all other subsequently
	# constructed classes that inherit from eBay::API.

	open (LOGGER, ">/tmp/ebay.log");         # Log to a file (or pipe, etc.)
	$pCall->setLogLevel($pCall->LOG_DEBUG);  # set the log level
	$pCall->setLogFileHandle(\*LOGGER);
	$pCall->setLogHeader(1);                 # Add time, log level to messages

	# Get the official time.
	$pCall->execute();

	# Log some information

	$pCall->logDebug($pCall->getEBayOfficialTime() . "\n");  # log data
	$pCall->dumpObject();  # Log Dumper of entire call; good for debugging
	$pCall->logXml($pCall->LOG_DEBUG, $pCall->getResponseRawXml());

	# You can also log to a subroutine / message handler
	# rather than a file.

	$pCall->setLogSubHandle(\&myLogHandler);
	$pCall->logInfo("Just log to standard out.");

	sub myLogHandler () {
	  my $msg = shift;
	  # just print to STDOUT
	  print $msg . "\n";
	}



=head2 Exception Handling

See eBay::Exception documentation for examples of how to enable
exception handling with try/catch statements.

=head2 Session Management

See eBay::API::XML::Session documentation for examples of how to
create and submit a bundle of web service requests either in parallel
or sequentially.




=head1 CALL CONSTRUCTOR

=head2 new()

Object constructor for all classes extending eBay::API::XML::BaseCall
(basically for all API calls).

Usage:

    eBay::API::XML::Session->new({args})
    eBay::API::XML::Call::GeteBayOfficialTime->new({args})
    eBay::API::XML::Call::GetUser->new({args})
    ....

Arguments:

=over 4

=item *

A hash reference containing the following possible arguments:

=over 8

=item *

B<site_id> => Scalar representing the eBay site id of the XML API
calls.  Setting the site id at the session level will provide a
default site id for all API calls bundled into a session.  The site id
for individual calls may still be overridden when the respective
request objects are instantiated, via the setSiteID() method.

If this value is not provided, it will attempt to use
the value in the environment variable EBAY_API_SITE_ID;

=item *

B<dev_id> => Scalar representing the Developer ID provided to the user
by eBay.  The developer ID is unique to each licensed developer (or
company). By default this will be taken from the environment variable
EBAY_API_DEV_ID, but it can be overridden here or via the setDevID()
instance method.

=item *

B<app_id> => Scalar representing the Application ID provided to the
user by eBay.  The application ID is unique to each application
created by the developer. By default this will be taken from the
environment variable EBAY_API_APP_ID, but it can be overridden here
or via the setAppID() instance method.

=item *

B<cert_id> => Scalar representing the Certification ID provided to the
user by eBay.  The certificate ID is unique to each application
created by the developer. By default this will be taken from the
environment variable EBAY_API_CERT_ID, but it can be overridden here
or via the setCertID() instance method.

=item *

B<user_name> => Scalar representing the application level user name
for this session.  This can be set via the environment variable
EBAY_API_USER_NAME, or may be overridden for each bundled call in the
session via the setUserName() instance method.

=item *

B<user_password> => Scalar reprsenting the application level user
password for this session.  This can be set via the environment variable
EBAY_API_USER_PASSWORD, or may be overridden for each bundled call
in the session via the setUserPassword() instance method.

=item *

B<user_auth_token> => Scalar representing the auth token for the
application level user for this session.  This may be set via the environment
variable EBAY_API_USER_AUTH_TOKEN, or overridden for each bundled call via
the setAuthToken() instance method.

=item *

B<api_ver> => Scalar representing the eBay webservices API version the
user wishes to utilize.  If this is not set here, it is taken from the
environment variable EBAY_API_VERSION, which can be overridden via
the instance method setVersion().

=item *

B<proxy> => Scalar representing the eBay transport URL needed to send
the request to.  If this is not set here, it must be set via the
environment variable EBAY_API_XML_TRANSPORT, or the setApiUrl() instance
method.

=item *

B<detail_level> => Value for the default detail level of the eBay XML API
requests invoked.  If not set here, it can be set with the instance
getter/setter methods getDetailLevel() and setDetailLevel().  When
bundling requests, this is the default detail level for all requests.
The detail level may be overridden for a specific request when it is
constructed.

=item *

B<compatibility_level> => This value is defined as a default in each
release of the API schema, and is taken by default via the autogenerated
class constant eBay::API::XML::Release::RELEASE_NUMBER.  But, if you need
to override the default value, you can do this either when you instatiate
your session object, or by using the instance setter method
setCompatibilityLevel(), or globally via the environment variable
EBAY_API_COMPATIBILITY_LEVEL.

=item *

B<sequential> => Boolean value to indicate if the requests should be
issued sequentially if true, and in parallel if false (default).  This
may also be set with the instance setter method setExecutionSequential().

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

B<success>  Object reference to an API call.

=item *

B<failure>  undefined

=back

B<Note>:

Even though the constructor has a lot of arguments, in general you probably 
don't need to use them. If you set ENV variables you really do not have to
provide any arguments to a constructor.



=head1 CALL's EXECUTE method

=over

=item $pCall->execute()

Executes the call. Serialiaze XML request, sends request, receives response
and deserializes received XML response. This method does not return any values.
In order to access retrieved values use call's getter properties.

=back 



=head1 PROPERTIES COMMON FOR ALL CALLS

=head2 Info properties 

=over

=item $pCall->getEBayOfficialTime

Returns eBay official time at time of call execution

=item $pCall->getApiCallName()

Returns call's name

=back 

=head2 Request header properties

The following properties are used to get/set request header properties

=over 

=item $pCall->getDevID()

=item $pCall->setDevID( $dev_id )

Get/set the dev id for api certification. This variable is set to default
to the value of $ENV{EBAY_API_DEV_ID}. You can override this either
when constructing a call object or by using this method after the
construction of the call.

=item $pCall->getAppID()

=item $pCall->setAppID( $app_id )

Get/set the app id for the call.  This overrides any default in
$ENV{EBAY_API_APP_ID}. You can override this either
when constructing a call object or by using this method after the
construction of the call.

=item $pCall->getCertID()

=item $pCall->setCertID( $cert_id )

Get/set the cert id for the call.  This overrides any default in
$ENV{EBAY_API_CERT_ID}. You can override this either
when constructing a call object or by using this method after the
construction of the call.

=item $pCall->getSiteID()

=item $pCall->setSiteID( $site_id )

Get/set the siteId for the call.  This overrides any default in
$ENV{EBAY_API_SITE_ID}. You can override this either
when constructing a call object or by using this method after the
construction of the call. For site id mapping please see 
eBay::API::XML::DataType::Enum::SiteCodeType. 

=item $pCall->getCompatibilityLevel()

=item $pCall->setCompatibilityLevel( $compatibilityLevel )

Get/set the compatibility level of the request payload schema for the call.  
This overrides any default in $ENV{EBAY_API_COMPATIBILITY_LEVEL}. You can 
override this either when constructing a call object or by using this method 
after the construction of the call. 

=item $pCall->getVersion()

=item $pCall->setVersion( $version )

B<This property is not used since the library is based on XML API, but
it is included in case we create a libary based on SOAP.>

If you are using the SOAP API, this field is required in the body of the request.
Specify the version of the schema your application is using.

If you are using the XML API, this field has no effect. Instead,
specify the version in the CompatibilityLevel HTTP header.  (eBay only
uses the value in this HTTP header when processing XML API requests.
If you specify Version in the body of an XML API request and it is
different from the value in the HTTP header, eBay returns an
informational warning that the value in the HTTP header was used
instead.)

The version you specify for a call has two effects:

    1) It directly indicates the version of the code lists and other 
	data that eBay should use to process your request.

    2) It indirectly indicates the API compatibility level of the data and 
	functionality you are using.

See the eBay Web Services guide for information about schema versions,
code lists, and compatibility levels.

=back 

=head2 User credential properties

=over 

=item $pCall->getUserName()

=item $pCall->setUserName( $username )

Get/set the username for the call.  This overrides any default in
$ENV{EBAY_API_USER_NAME}. You can override this either
when constructing a call object or by using this method after the
construction of the call. 


=item $pCall->getUserPassword()

=item $pCall->setUserPassword( $userPassword )

Get/set the user password for the call.  This overrides any default in
$ENV{EBAY_API_USER_PASSWORD}. You can override this either
when constructing a call object or by using this method after the
construction of the call. 


=item $pCall->getAuthToken()

=item $pCall->setAuthToken( $userAuthToken )

Get/set the user authentication token for the call.  This overrides any 
default in $ENV{EBAY_API_USER_AUTH_TOKEN}. You can override this either
when constructing a call object or by using this method after the
construction of the call. You should use either authentication token or 
username, password. If both, token and username/password are set then
token is used and username/password are ignored by the SDK.

=back

=head2 SDK's properties

=over 

=item $pCall->getApiReleaseNumber()

Returns eBay's API XML Schema version on which the SDK is based

=back

=head2 Helper properties

=over

=item $pCall->isCompression()

=item $pCall->setCompression( $isCompression )

Enables/disables compression in the HTTP header.  This tells the API server
whether the client application can accept gzipped content or not. If
this property is set then the API server returns compressed XML response.
Do not set this unless you have CPAN module Compress::Zlib.  This is
potentially useful for possibly large API responses such as
GetCategories, etc.


=item $pCall->getHttpRequestAsString($isXmlPrettyPrint)

=item $pCall->getHttpRequestAsString()

This method returns a textual representation of the request
(request type, url, query string, header and content).
If argument isXmlPrettyPrint is set to 1 then the request's XML is pretty printed

=item $pCall->getHttpResponseAsString()

This method returns a textual representation of the response
(header info as well as response body. If argument isXmlPrettyPrint is set to 1
then the response's XML is pretty printed.
NOTE:  It is recommended not to use this feature in production, only during
development and/or testing.  The CPAN module used to help with the pretty-ness
of the XML is B<VERY sloooooooooooooow>.

=item $pCall->getRequestRawXml()

This method returns a textual representation of the requests' body

=item $pCall->getResponseRawXml()

This method returns a textual representation of the response's body

=item $pCall->isHttpRequestSubmitted()

Tells to a programmer whether a request has been submitted or not.
This method is mainly used in Session in sequential mode.

=item $pCall->getXmlSimpleDataStructure()

The library internally uses XML::Simple for XML parsing.
This method returns XML::Simple data structure for a given path.
Path is defined as a reference to an array of node names, starting with 
the top level node and ending with lowest level node.

Path IS NOT an XPATH string!!!!

Path examples for VerifyAddItem call:

    @path = ( 'Fees','Fee' );   # Returns fees as an XML::Simple data structure
    @path = ( 'Errors' );       # Returns Response errors as an XML::Simple data structure
    @path = ( 'Errors-xxxx' );  # Returns nothing because 'Errors-xxxx' node does not exist.

Notice that root node is not being specified. The reason for that is that 
XML::Simple is configured not to put root node into its data structure
(that is a default behaviour for XML::Simple).

If path is not submitted return the whole XML::Simple data structure.

=item $pCall->forceError()

This method is used to force a given error when a call is being executed.
If the forced error is set, then that error is being returned by the call
without executing the call (sending request to the API Server and receiving 
the response).

This method is used for test purposes when a programmer wants to test
how the application handles an API error.

Arguments: This method uses named argument calling style that looks like this:

    $pCall->forceError ( sErrorCode => '1025', sShortMsg => 'Test API error', ... );

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

      $pCall->forceError (
                    'sErrorCode' => '1025'
                    ,'sShortMsg' => 'Test error short message'
                    ,'sLongMsg' => 'Test error long message'
                        );

=back

=head2 Common request (input) properties


=over 

=item $pCall->getRequestDataType()

Each call has a call specific RequestDataType property which defines set of request 
properties specific for that call. This method gives you access to those properties. 
The request properties listed below are basically shortcuts for the following syntax:

    $pCall->getDetailLevel() <=> $pCall->getRequestDataType()->getDetailLevel();

To get list of properties available for a specific call, please read POD documentation 
for that call.

=item $pCall->setDetailLevel( @aDetailLevels )

=item @aDetailLevels = $pCall->getDetailLevel()

Detail levels are instructions that define standard subsets of data to
return for particular data components (e.g., each Item, Transaction,
or User) within the response payload.  For example, a particular
detail level might cause the response to include buyer-related data in
every result (e.g., for every Item), but no seller-related data.
Specifying a detail level is like using a predefined attribute list in
the SELECT clause of an SQL query. Use the DetailLevel element to
specify the required detail level that the client application needs
pertaining to the data components that are applicable for the request.
The DetailLevelCodeType defines the global list of available detail
levels for all request types. Most request types support certain
detail levels or none at all.  If you pass a detail level that exists
in the schema but that isn't valid for a particular request, eBay will
ignore it and your request will still be processed (currently).  For each
request type, see the eBay Web Services guide to determine which detail
levels are applicable and which elements are returned for each applicable
detail level.

B<Notice that you can set multiple DetailLevels for a given call>. In
cases when you have to submit multiple detail levels you have to
provide either an array or a reference to an array with a list of
valid detail levels.  getDetailLevel always returns either an array or
a reference to an array (depending on calling context) even if you
have used a scalar value to set detail level.

DetailLevel code must be one of
eBay::API::XML::DataType::Enum::DetailLevelCodeType enum values.

=item $pCall->setErrorHandling( $ErrorHandlingCodeType )

=item $pCall->getErrorHandling( )

Error tolerance level for the call. For calls that support Item
Specifics, this is a preference that controls how eBay handles listing
requests when invalid attribute data is passed in. See Attribute Error
Handling in the eBay Web Services guide for details about this field
in listing requests.

ErrorHandling code must be one of
eBay::API::XML::DataType::Enum::ErrorHandlingCodeType enum values.

=item $pCall->setErrorLanguage($error_lang)

=item $pCall->getErrorLanguage()

Use ErrorLanguage to return error strings for the call in a different
language from the language commonly associated with the site that the
requesting user is registered with.  Specify the standard RFC 3066
language identification tag (e.g., en_US).

See http://www.ietf.org/rfc/rfc3066.txt.

    ID    country
    ----- -----
    de_AT Austria
    de_CH Switzerland
    de_DE Germany 
    en_AU Australia
    en_CA Canada
    en_GB United Kingdom
    en_US United States
    es_ES Spain
    fr_BE Belgium (French)
    fr_FR France
    it_IT Italy
    nl_BE Belgium (Dutch)
    nl_NL Netherlands
    zh_TW Taiwan
    zh_CN China
    en_IN India
    en_IE Ireland
    zh_HK Hong Kong


=item $pCall->getInvocationID()->setValue($invocation_id)

=item $pCall->getInvocationID()->getValue()

A unique identifer for a particular call. If the same InvocationID is
passed in after it has been passed in once on a call that succeeded
for a particular application and user, then an error will be
returned. The identifier can only contain digits from 0-9 and letters
from A-F. The identifier must be 32 characters long.  For example,
1FB02B2-9D27-3acb-ABA2-9D539C374228.

This is one of DataTypes explained in L</IDIOSYNCRASIES>.

You can also set a value using the following snippet:

     my $pUUIDType = eBay::API::XML::UUIDType->new();
     $pUUIDType->setValue( $invokation_id );
     $pCall->setInvocationID ($pUUIDType )

This is possible because the argument that setInvocationID expects is an
object of eBay::API::XML::UUIDType even though that class at this
moment has only one property ('value').

=item $pCall->setMessageID( $message )

=item $pCall->getMessageID()

In most cases, all calls support a MessageID element in the request
and a CorrelationID element in the response.

If you pass a message ID in a request, we will return the same value
in CorrelationID in the response. You can use this for tracking that a
response is returned for every request and to match particular
responses to particular requests.

If you do not pass MessageID in the request, CorrelationID is not
returned.  Note that some calls are designed to retrieve large sets of
meta-data that only change once a day or less often. To improve
performance, these calls return cached responses when you request all
available data (with no filters). In these cases, the correlation ID
is not applicable. However, if you specify an input filter to reduce
the amount data returned, you can use MessageID and CorrelationID for
these meta-data calls.

These are the meta-data calls that can return cached responses:

	GetCategories 
	GetAttributesCS 
	GetCategory2CS 
	GetAttributesXsl 
	GetProductFinder 
	GetProductFinderXsl 
	and GetProductSearchPage

=item $pCall->setWarningLevel( $WarningLevelCodeType )

=item $pCall->getWarningLevel()

Controls whether or not to return warnings when the application passes
unrecognized elements in a request.
(This does not control warnings related to unrecognized
values within elements.)

WarningLevelCodeType is one of eBay::API::XML::DataType::Enum::WarningLevelCodeType
enum values.

=back

=head2 Common response (output) properties

=over 

=item $pCall->getResponseDataType()

Each call has a specific ResponseDataType property which defines set of response 
properties specific for that call. This method gives you access to those properties. 
The response properties listed below are basically shortcuts for the following syntax:

    $pCall->getAck() <=> $pCall->getResponseDataType()->getAck();

To get list of properties available for a specific call, please read POD documentation 
for that call.

The following properties are used to get response properties common for all calls

=item $pCall->getAck()

A token representing the application-level acknowledgement code that indicates
the response status (e.g., success). The AckCodeType list specifies
the possible values for Ack.

AckCodeType is one of eBay::API::XML::DataType::Enum::AckCodeType
enum values.

=item $pCall->getBuild()

This refers to the specific software build that eBay used when processing the request
and generating the response. This includes the version number plus additional
information. eBay Developer Support may request the build information
when helping you resolve technical issues.

=item $pCall->getCorrelationID()

In most cases, all calls support a MessageID element in the request
and a CorrelationID element in the response.

If you pass a message ID in a request, the API service will return the
same value in CorrelationID in the response. You can use this for tracking
that a response is returned for every request and to match particular
responses to particular requests.

If you do not pass MessageID in the request, CorrelationID is not
returned.  Note that some calls are designed to retrieve large sets of
meta-data that only change once a day or less often. To improve
performance, these calls return cached responses when you request all
available data (with no filters). In these cases, the correlation ID
is not applicable. However, if you specify an input filter to reduce
the amount data returned, you can use MessageID and CorrelationID for
these meta-data calls.

These are the calls that can return cached responses:

	GetCategories 
	GetAttributesCS 
	GetCategory2CS 
	GetAttributesXsl 
	GetProductFinder 
	GetProductFinderXsl
	GetProductSearchPage.

=item $pCall->getDuplicateInvocationDetails()

Information that explains a failure due to a duplicate InvocationID being
passed in.

=item $pCall->getEIASToken()

Unique Identifier of Recipient user ID of the notification. Only returned by
Platform Notifications (not for regular API call responses).

=item $pCall->getHardExpirationWarning()

Expiration date of the user's authentication token. Only returned
within the 7-day period prior to a token's expiration.

To ensure that user authentication tokens are secure and to help avoid
a user's token being compromised, tokens have a limited life span. A
token is only valid for a period of time (set by eBay). After this
amount of time has passed, the token expires and must be replaced with
a new token.

=item $pCall->getMessage()

Supplemental information from eBay, if applicable. May elaborate on
errors or provide useful hints for the seller.

This data can accompany the call's normal data result set or a result
set that contains only errors.

The string can return HTML, including TABLE, IMG, and HREF elements.
In this case, an HTML-based application should be able to include the
HTML as-is in the HTML page that displays the results.

A non-HTML application would need to parse the HTML and convert the
table elements and image references into UI elements particular to the
programming language used.  Because this data is returned as a string,
the HTML markup elements are escaped with character entity references

	(e.g.,&lt;table&gt;&lt;tr&gt;...).

See the appendices in the eBay Web Services guide for general
information about string data types.

=item $pCall->getNotificationEventName()

Event name of the notification. Only returned by Platform Notifications.

=item $pCall->getNotificationSignature()

A Base64-encoded MD5 hash that allows the recepient of a Platform
Notification to verify this is a valid Platform Notification sent by
eBay.

=item $pCall->getRecipientUserID()

Recipient user ID of the notification. Only returned by Platform Notifications.

=back

=head2 Errors related methods

=over 

=item $pCall->hasErrors

Returns true (1) if an API call returns errors (API, HTTP connection or
XML parsing errors).  (ErrorSeverityCode =
eBay::API::XML::DataType::Enum::SeverityCodeType::Error) In this case
the application should stop normal processing and return a "system
error" message to an application user. The only things that it makes
sense to read from ResponseDataType objects are: errors and
rawResponse (which in this case might not even be a valid XML
document).

=item $pCall->hasWarnings

Returns true (1) if an API call returns warnings (ErrorSeverityCode =
eBay::API::XML::DataType::Enum::SeverityCodeType::Warning) Usually
warnings can be ignored.

=item $pCall->getErrors

Returns a list of errors.  Depending on context it can return either a
reference to an array or an array of errors.  Type of elements in the
array is eBay::API::XML::DataType::ErrorType.

=item $pCall->getWarnings

Returns a list of warnings.  Depending on context it can return either
a reference to an array or an array of errors.  Type of elements in
the array is eBay::API::XML::DataType::ErrorType.

=item $pCall->getErrorsAndWarnings

Returns a list of both errors and warnings.  Depending on context it
can return either a reference to an array or an array of errors.  Type
of elements in the array is eBay::API::XML::DataType::ErrorType.

=item $pCall->hasError( $sErrorCode )

Returns true (1) if API call returned an error with the given errorCode

=back

=head1 DataTypes

Each data type defined in API Schema document has a corresponding
DataType perl module.  These modules can be found in
eBay::API::XML::DataType namespace.  Here are a few examples of such
DataType modules:

    AmountType.pm
    ItemType.pm
    ItemIDType.pm
    UserType.pm
    UserIDType.pm
    OfferType.pm

=head1 Enums

eBay's API often uses list of codes for various calls. Examples of
such lists are: CountryCodeType and CurrencyCodeType. Such code lists
are defined in appropriate Perl modules.  These code list (ENUM)
modules can be found in eBay::API::XML::DataType::Enum namespace.
Here are a few examples of such code lists (ENUMS):

    CountryCodeType.pm
    CurrencyCodeType.pm

=head1 EXPORT

None by default.

=head1 IDIOSYNCRASIES

=head2 ENUM constants in Perl

   Since Perl does not support an ENUM datatype the way C, C++, Java, etc. does,
   the autogenerated ENUM datatypes have all of their ENUM constants defined as
   Perl constants.

      i.e.  use constant foo => 'BAR';

   Some of the eBay ENUM datatypes may have the actual ENUM constant as a number,
   or a string that begins with a number.  Because of that, we cannot allow the
   following for obvious reasons:

      use constant 1 => '1';

   So, we have added logic to the autogeneration process that will automatically
   append a 'N' to the beginning of any ENUM constant that begins with a number.
   The above example will now look like the following:

      use constant N1 => '1';

   Again, it is up to the developer to make sure they have read the eBay API
   schema documentation thoroughly, for all datatypes used.  It is the only way
   that you will be aware that you will have to refer to the ENUM constant
   as N1 vice 1, etc.


=head2 Request (input) and response (output) properties - setters and getters

   There are two sets of request and response properties:

        1. properties common for all calls
        2. properties specific for a given call

   1. Properties common for all calls (found in BaseCallGen.pm class)
       1.1. Request properties
            Request properties have both: getters and setters
                Examples: 
                        $value = $pCall->getErrorLanguage();
                        $pCall->setErrorLanguage( $value );
       1.2. Response propertise
            Response properties have only getters
                Examples: 
                        $value = $pCall->getAck();

   2. Properties specific for a given call
       2.1. Request properties - only setters are directly available
              This means that the following syntax must be used to retrieve request property
                my $value = $pCall->getRequestDataType()->getProperty() 
              At the same time, the same property is set using the following syntax:
                $pCall->setProperty() 
       2.2. Response propertise - only getters are directly available
              To retrieve a response property use the follwing syntax:
                my $value = $pCall->getProperty() 

=head2 Classes with only one or two properties

Example of such classes are: 

        UserIDType, ItemIDType - one property: 'value' 
        AmountType - two properties: 'value', 'currencyID'

Most likely the way properties for these classes are being set and
retrieved is unusual.

     get value: use

                    my $username = $pGetItem->getUser()->getUserID()->getValue();

                instead of

                    my $pUserID  = $pGetItem->getUser()->getUserID(); 

                because getUserID() returns an object.

     set value: use

                    $pGetItem->getUser()->getUserID()->setValue('username');

                instead of

                    $pGetItem->getUser()->setUserID($pUserID);

                because setUserID() expects an object of type UserIDType rather
                then a scalar value (username).

This approach is probably clearer for AmountType class because
AmountType has two properties: value and currencyID.





=head1 TODO

=head2 Possibly support SOAP and REST interfaces.

    The current version only supports the eBay API XML interface.  However, the 
    structure of the package was defined to accommodate future support for any
    interface/protocol as well.

=head2 Support auto-generation of classes for XML schema interface using WSDL vice XSD.

    At the moment all the classes supporting specific API calls are generated from the
    most recently published xsd schema file at eBay.  Generating the classes from the
    most recently published wsdl schema has been deferred until support for the eBay
    SOAP interface is provided.






=head1 SEE ALSO

http://developer.ebay.com
https://ebay-perl-api-sdk.codebase.ebay.com





=head1 AUTHORS

in alphabetical order:

=item *

Robert Bradley

=item *

Mike Evans

=item *

Milenko Milanovic

=item *

Jeff Nokes

=item *

perl@ebay.com





=head1 COPYRIGHT AND LICENSE

Reference information in README file, provided with this module distribution.


=cut
