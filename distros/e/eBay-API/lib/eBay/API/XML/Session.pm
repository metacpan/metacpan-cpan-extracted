#!/usr/bin/perl -s

##########################################################################
#
# Module: ............... <user defined location>/eBay/API/XML
# File: ................. Session.pm
# Original Author: ...... Bob Bradley
# Last Modified By: ..... Robert Bradley / Jeff Nokes
# Last Modified: ........ 03/06/2007 @ 16:25
#
# This class is used to control api calls made in parallel, offer some
# transactional logic when executing the calls, as well as retries.
#
##########################################################################

=head1 NAME

eBay::API::XML::Session - Cluster and submit several eBay XML API calls at once

=head1 INHERITANCE

eBay::API::XML::Session inherits from the L<eBay::API::XML::BaseXml> class

=head1 DESCRIPTION

This module collects multiple requests to the eBay XML API and submits
them sequentially or in parallel.  Session.pm uses the CPAN module, 
LWP::Parallel, to manage the parallel submission of HTTP requests to the 
eBay XML API.

=head1 SYNOPSIS

  use eBay::API::XML::Call::GeteBayOfficialTime;
  use eBay::API::XML::Call::GetUser;
  use eBay::API::XML::DataType::Enum::DetailLevelCodeType;
  use eBay::API::XML::Call::GetSearchResults;
  use eBay::API::XML::DataType::PaginationType;
  use eBay::API::XML::Session;

  # Create a session (authorization info is pulled from ENV by the constructors)
  my $session = new eBay::API::XML::Session;

  # Get official time.
  my $pCall = eBay::API::XML::Call::GeteBayOfficialTime->new();
  $session->addRequest($pCall);

  # Get user details
  my $getUserCall = eBay::API::XML::Call::GetUser->new();
  $getUserCall->setDetailLevel( [eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll] );
  $session->addRequest($getUserCall);

  # Get search results
  my $getListingsCall = new eBay::API::XML::Call::GetSearchResults;
  $getListingsCall->setQuery("new");
  my $pagination = new eBay::API::XML::DataType::PaginationType;
  $pagination->setEntriesPerPage(10);
  $getListingsCall->setPagination($pagination);
  $session->addRequest($getListingsCall);

  # session will submit the calls in parallel -- then wait til all come back
  $session->execute();

  # get results from various calls
  my $itemarray = $getListingsCall->getSearchResultItemArray()->getSearchResultItem();
  my $officialtime = $pCall->getEBayOfficialTime();
  my $pUser = $getUserCall->getUser();
  my $sEmail = $pUser->getEmail();
  my $sStatusCode = $pUser->getStatus();
  my $sSiteCode  = $pUser->getSite();


=cut




# Package Declaration
# -------------------------------------------------------------------------
package eBay::API::XML::Session;

# Required Includes
# -------------------------------------------------------------------------
use strict;
use warnings;
use Exporter;
use LWP::Parallel;   # http://search.cpan.org/~marclang/ParallelUserAgent-2.57/
                     # Support for submitting bundled requests in parallel.
use Data::Dumper;
use eBay::API::XML::BaseXml;  # parent class
use HTTP::Request;

# Global Variables
our @ISA = (
	    'Exporter', 
	    'eBay::API::XML::BaseXml',  # Parent class with logging framework
	   );

# :DEFAULT exported symbols
our @EXPORT = qw(
		);

# Subroutine Prototypes
# ----------------------------------------------------------------------------------
# Method Name                              Accessor Priviledges      Method Type

sub new($;$);
sub addRequest($$;$);                #         Public                Instance
sub clearSession($;);                #         Public                Instance
sub execute($;);                     #         Public                Instance
sub setSequentialExecution($$;);     #         Public                Instance
sub isSequentialExecution($;);       #         Public                Instance
sub _execute_sequential($;);         #         Private               Instance
sub _execute_parallel($;);           #         Private               Instance
sub _process_callback($$;);          #         Private               Instance

# Main Script
# ---------------------------------------------------------------------------
#

# Subroutine Definitions
# ---------------------------------------------------------------------------

=head1 Subroutines:



=pod

=head2 new()

Session constructor.  This constructor delegates most of the work to
the constructor for the abstract parent class, eBay::API::BaseApi.  See
perldoc eBay::API::BaseApi for more details.

Arguments:

=over 4

=item *

B<sequential>  If this is true (non-zero), then the bundled calls will
be executed sequentially.  See method setSequentialExecution() for more
details.

=back

Returns:

=over 4

=item *

B<success> A reference to a blessed Session object.

=item *

B<error> Undefined if an exception was encountered during construction
of the session object.  In that case, consult the log file for more
details.

=back


=cut



sub new($;$) {
  my $class = shift;
  my $arg_hash = shift;

  # validate that first arguments is blessed object
  eBay::API::BaseApi::_check_arg($class, Params::Validate::SCALAR);

  # more validations are done in the parent classes
  my $self = $class->SUPER::new($arg_hash);

  if (defined $self) {
    $self->clearSession();
    if    (defined($arg_hash)) {
      # validate that the arguements are a reference to a hash
      eBay::API::BaseApi::_check_arg($arg_hash, Params::Validate::HASHREF);
      if ($arg_hash->{sequential}) {
	$self->{sequential} = $arg_hash->{sequential};
      }
    }
  }
  return $self;
}



=head2 addRequest()

Instance method to add an eBay::API::XML::Call to the request bundle.

Arguments:

=over 4

=item *

Object reference of type eBay::API::XML::Session

=item *

Reference to an eBay::API::XML::Call to be issued to the eBay XML API.

=item *

Optional reference to a callback subroutine to be called when the
http request returns.  Note.  This subroutine will be called whether
the return is a success, a failure, or a timeout.

Argument going to the callback subroutine is the call object it is
associated with.

=back

Returns: None

=cut

sub addRequest($$;$) {
  my ($self, $apicall, $callback) = @_;

  # validate that first two arguments are blessed objects
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
  eBay::API::BaseApi::_check_arg($apicall, Params::Validate::OBJECT);

  unshift (@{$self->{requestqueue}}, $apicall);
  if (defined $callback) {
    eBay::API::BaseApi::_check_arg($callback, Params::Validate::CODEREF);
    $self->{callbacks}{$apicall} = $callback;
  }
}



=pod

=head2 clearSession()

Reset an eBay::API::XML::Session object so it may be re-used.

This involves the following:

=over 4

=item *

Remove all bundled eBay::API::XML::Request objects.

=item *

Clear error information if present.

=back

Arguments:

=over 4

=item *

Object reference of type eBay::API::XML::Session

=back

Returns:

=over 4

=item *

B<success> Object reference to the eBay::API::XML::Session.

=item *

B<failure> undefined

=back

=cut


sub clearSession($;) {
  my $self = shift;

  # validate that first arguments is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

  # iniitialize Session member variables to sane values
  $self->_setError('');
  $self->{requestqueue} = ();
  $self->{sequential}  = 0;
  $self->{callbacks} = {};
  return $self;
}




=head2 execute()

Instance method used for executing the actual XML API request bundle.
This method really does most of the work.  It will attempt to perform
all necessary validations, as well as create and send the bundle of
XML requests.

This method will block until all issued requests have responses, or
until the timeout.  After the responses come back from the API, they
are populated back into the call objects registered with the session
so they can be accessed from the client application.

execute() also returns the eBay::API::XML::Response objects in an array.  
This array may have responses for all, some, or none of the issued 
requests, depending on the success or failure of each request.

If the client application wants to use the request objects in the returned
array, it should match up each response in the array with the
corresponding request.  This can best be done by using and tracking a
unique message id for each request.

If an incomplete set of responses are returned, an appropriate error
will be set and available to the getError() method.

Arguments:

=over 4

=item *

Object reference of type eBay::API::XML::Session

=back

Returns:

=over 4

=item *

B<success> Reference to array of api call objects submittted to the eBay
API.  The calls may, or may not have executed successfully; it is up to
the user to check error status of the session and possibly individual calls.

=item *

B<failure> undefined

=back

=cut



sub execute($;) {

  # Get all values passed in.
  my $self = shift;

  # validate that first argument is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

  if ($self->isSequentialExecution()) {
    return $self->_execute_sequential();
  } else {
    return $self->_execute_parallel();
  }
}



# _execute_parallel()

#  Use LWP::Parallel to do parallel processing of the bundled calls.

sub _execute_parallel($;) {
  my $self = shift;

  # validate that first argument is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);


  # Set up for retries.
  # If the user has registered a retry object with retry requirements for the 
  # session, then use those requirements.  Otherwise, default to only 1 try (that
  # is to say, no retries.  The retry object has two main things: 1) the number
  # of times to retry, and 2) the types of errors that qualify for retry.
  # See perldoc eBay::API::XML::CallRetry for more details on the retry object.
  my @calls = @{$self->{requestqueue}};  # egg basket; take calls out and put back in to retry
  my $moreretries = 1;
  my $retryobj = $self->getCallRetry();
  if ( defined $retryobj ) {
     $moreretries =  $retryobj->getMaximumRetries();
  }

  # BEGIN RETRY LOOP

  # Loop through the current egg basket
  while ($moreretries && @calls) {

    $moreretries--;
    my %requests;
    my $parallel_agent = new LWP::Parallel::UserAgent;

    # Register the requests.  In the case of retries, we
    # only register those requests that were unsuccessful
    # in the previous try.
    while (my $apicall = pop(@calls)) {
      my $httprequest = $apicall->_getHttpRequestObject();
      $requests{$httprequest} = $apicall;
      $parallel_agent->register($httprequest);
    }

    # submit parallel and wait
    my $entries = $parallel_agent->wait($self->getTimeout());

    # Process the responses.
    while ( my ($key, $entry) = each %$entries) {
      my $httpresponse = $entry->{response};
      my $apicall = $requests{$key};
      # The base call does most of the work here.
      $apicall->processResponse($httpresponse);
      # test for errors and possibly retry
      if ($moreretries && defined $retryobj &&
	  $retryobj->shouldRetry(
				 'raErrors' => $apicall->getErrorsAndWarnings()
				)) {
	unshift(@calls, $apicall);
      }
    }

  }

  # END RETRY LOOP

  # Process the callbacks and any errors
  foreach (@{$self->{requestqueue}}) {
    $self->_process_callback($_);
    if ($_->hasErrors()) {
      my ($error) = @{$_->getErrors()};
      $self->_setError($error->getShortMessage);
    }
  }

  # Return the api call bundle

  return $self->{requestqueue};
}

#_execute_sequential

#Private instance method to execute the bundled calls in the
#sequence in which they were added to the bundle.

sub _execute_sequential($;) {
  my $self = shift;

  # validate that first arguments is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

  # Calls were unshifted on to the request queue array
  # in the order in which they were added to the session.
  # Now pop them off; and execute the calls in the same
  # sequence.
  my @calls = @{$self->{requestqueue}};
  while (my $call = pop(@calls)) {
    $call->execute();
    $self->_process_callback($call);
    if ($call->hasErrors()){
      my ($error) = @{$call->getErrors()};
      $self->_setError($error->getShortMessage);
      last;
    }
  }
  return $self->{requestqueue};
}

# _process_callback()

# Private method.  Check if a call was registered with a callback.
# If so, then call the callback.


sub _process_callback($$;) {
  my $self = shift;
  my $call = shift;

  # validate that first two arguments are blessed objects
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);
  eBay::API::BaseApi::_check_arg($call, Params::Validate::OBJECT);


  # If this call has a callback associated with it, then call
  # the callback.
  if (exists($self->{callbacks}{$call})) {
    my $callback = $self->{callbacks}{$call};
    &$callback($call);
  }
}


=head2 isSequentialExecution()

Returns current state of the session with regard to whether session
calls should be executed in sequence as an ordered transaction rather
than in parallel.


Arguments:

=over 4

=item *

Object reference of type eBay::API::XML::Session.

=back


Returns:

=over 4

=item *

B<zero - true> Session is set to issue calls in parallel.

=item *

B<non-zero - true> Session will issue calls sequentially.

=back

=cut


sub isSequentialExecution($;) {
  my $self = shift;

  # validate that first argument is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

  return $self->{sequential};
}


=head2 setSequentialExecution()

Instance method to prepare the session to execute the API requests
bundled in the session in the sequence in which they were added to the
session. The only difference between this and the normal execution
state is that the execute() method will execute each api call
asynchronously rather than in parallel.  If an error is encountered,
none of the calls after the error was encountered will be sent to the
eBay API.  This behavior, in effect, offers a kind application-level
transaction integrity, although there is no concept of 'rollback' in
the sense of backing out the effects of calls executed prior to the
error was encountered.

See the description of the execute() subroutine for more details.

Arguments:

=over 4

=item *

Object reference of type eBay::API::XML::Session.

=item *

Boolean.  True will set execution mode to sequential.  False
will set execution mode to parallel.

=back

Returns:

=over 4

=item *

B<success> Value set for execution mode.

=item *

B<failure> undefined

=back

=cut


sub setSequentialExecution($$;) {
  my ($self, $bool) = @_;

  # validate that first argument is blessed object
  eBay::API::BaseApi::_check_arg($self, Params::Validate::OBJECT);

  $self->{sequential} = $bool;
  return $bool;
}




# Return TRUE to perl
1;
