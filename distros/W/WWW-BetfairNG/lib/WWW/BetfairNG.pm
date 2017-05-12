package WWW::BetfairNG;
use strict;
use warnings;
use HTTP::Tiny;
use JSON::MaybeXS;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Carp qw /croak/;

# Define Betfair Endpoints
use constant BF_BETTING_ENDPOINT => 'https://api.betfair.com/exchange/betting/rest/v1/';
use constant BF_C_LOGIN_ENDPOINT => 'https://identitysso.betfair.com/api/certlogin/';
use constant BF_LOGIN_ENDPOINT   => 'https://identitysso.betfair.com/api/login/';
use constant BF_LOGOUT_ENDPOINT  => 'https://identitysso.betfair.com/api/logout/';
use constant BF_KPALIVE_ENDPOINT => 'https://identitysso.betfair.com/api/keepAlive/';
use constant BF_ACCOUNT_ENDPOINT => 'https://api.betfair.com/exchange/account/rest/v1.0/';
use constant BF_HRTBEAT_ENDPOINT => 'https://api.betfair.com/exchange/heartbeat/json-rpc/v1/';
use constant BF_RSTATUS_ENDPOINT => 'https://api.betfair.com/exchange/scores/json-rpc/v1/';

=head1 NAME

WWW::BetfairNG - Object-oriented Perl interface to the Betfair JSON API

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

  use WWW::BetfairNG;

  my $bf = WWW::BetfairNG->new();
  $bf->ssl_cert(<path to ssl cert file>);
  $bf->ssl_key(<path to ssl key file>);
  $bf->app_key(<application key>);

  $bf->login({username => <username>, password => <password>});
  ...
  $bf->keepAlive();
  ...
  $bf->logout();

=head1 DESCRIPTION

Betfair is an online betting exchange which allows registered users to interact with it
using a JSON-based API. This module provides an interface to that service which handles
the JSON exchange, taking and returning perl data structures (usually hashrefs). Although
there is an option to thoroughly check parameters before sending a request, and a listing
of the BETFAIR DATA TYPES is provided below, it requires a level of understanding of the
Betfair API which is best gained from their own documentation, available from
L<https://developer.betfair.com/>

To use this library, you will need a funded Betfair account and an application key. To use
the non-interactive log in, you will also need an SSL certificate and key (in seperate
files, rather than a single .pem file). Details of how to create or obtain these, and how
to register your certificate with Betfair are also available on the above website. The
interactive login does not require an SSL certificate or key and is therefore easier to
set up, but Betfair strongly recommend that unattended bots use the non-interactive
version.

=head1 METHODS

=head2 Construction and Setup

=head3 new([$parameters])

  my $bf = new WWW::BetfairNG;          OR
  my $bf = WWW::BetfairNG->new();       OR
  my $bf = WWW::BetfairNG->new({
                                ssl_cert => '<path to ssl certificate file>',
                                ssl_key  => '<path to ssl key file>',
                                app_key  => '<application key value>',
                               });

Creates a new instance of the WWW::BetfairNG class. Takes an optional hash or hash
reference of configurable attributes to set the application key and/or paths to ssl cert
and key files. (These may also be set after instantiation via the accessors described
below, but in any case the ssl cert and key need to be present for a successful
non-interactive login). The application key is required for most of the API calls, but not
for login/logout or 'getDeveloperAppKeys', so if necessary the key can be retrieved from
Betfair and then passed to the object using $bf->app_key. If logging in is not possible
for some reason, but an active session token can be obtained by other means, this may also
be passed to the new object using {session => <session token value>}; the object will then
behave as if it were logged in.

=cut

sub new {
    my $class = shift;
    # set attributes configurable at instantiation
    my $self = {
        ssl_cert  => '',
        ssl_key   => '',
        app_key   => '',
        session   => '',
    };
    # check if we were passed any configurable parameters and load them
    if (@_) {
      my $params = shift;
      unless(ref($params) eq 'HASH') {
	croak 'Parameters must be a hash ref or anonymous hash';
      }
      for my $key (keys %$params) {
	unless (exists $self->{$key}) {
	  croak "Unknown key value $key in parameter hash";
	}
	$self->{$key} = $params->{$key};
      }
    }
    # set non-configurable attributes
    $self->{error}      = 'OK',
    $self->{response}   = {};
    $self->{p_check}    = 0;
    $self->{bet_end_pt} = BF_BETTING_ENDPOINT;
    $self->{acc_end_pt} = BF_ACCOUNT_ENDPOINT;
    $self->{data_types} = {};
    # Create an HTTP::Tiny object to do all the heavy lifting
    my $client = HTTP::Tiny->new(
       timeout         => 5,
       agent           => "WWW::BetfairNG/$VERSION",
       default_headers => {'Content-Type'    => 'application/json',
			   'Accept'          => 'application/json',
			   'Accept-Encoding' => 'gzip'
			  });
    $self->{client}   = $client;
    my $obj = bless $self, $class;
    return $obj;
}

=head2 Accessors

=head3 ssl_cert([<path to ssl cert file>])

  my $cert_file = $bf->ssl_cert();
  $bf->ssl_cert('<path to ssl certificate file>');

Gets or sets the path to the file containing the client certificate required for
non-interactive login. Default is '', so this needs to be set for a sucessful login. See
Betfair documentation for details on how to create and register client SSL certificates
and keys.

=cut

sub ssl_cert {
  my $self = shift;
  if (@_){$self->{ssl_cert} = shift};
  return $self->{ssl_cert};
}

=head3 ssl_key([<path to ssl key file>])

  my $key_file = $bf->ssl_key();
  $bf->ssl_key('<path to ssl key file>');

Gets or sets the path to the file containing the client key required for
non-interactive login. Default is '', so this needs to be set for a sucessful
login. See Betfair documentation for details on how to create and register client SSL
certificates and keys.

=cut

sub ssl_key {
  my $self = shift;
  if (@_){$self->{ssl_key} = shift};
  return $self->{ssl_key};
}

=head3 app_key([<key value>])

  my $app_key = $bf->app_key();
  $bf->app_key('<application key value>');

Gets or sets the application key required for most communications with the API. This key
is not required to log in or to use 'getDeveloperAppKeys', so it may be retrieved from
Betfair and then passed to the object using this accessor. It may also be possible to
create the app keys using 'createDeveloperAppKeys', but as this call fails if keys already
exist, it was not possible to test this. See Betfair documentation for how to obtain
Application Keys using their API-NG Visualiser.

=cut

sub app_key {
  my $self = shift;
  if (@_) {
    $self->{app_key} = shift;
  }
  return $self->{app_key};
}

=head3 session()

  my $session_token = $bf->session();
  $bf->session('<session token value>');

Gets or sets the current Session Token. Contains '' if logged out. Normally this is set
automatically at login and after keepAlive, and unset at logout, but it can be set by hand
if necessary.

=cut

sub session {
  my $self = shift;
  if (@_){
    $self->{session} = shift;
  }
  return $self->{session};
}

=head3 check_parameters()

  my $check = $bf->check_parameters();
  $bf->check_parameters('<boolean>');

Gets or sets a flag telling the object whether or not it should do a detailed check on the
validity of parameters passed to the API methods. If this is set, the parameter hash will
be checked before it is sent to the API, and any errors in construction will result in the
method call immediately returning '0' and C<< $bf->error >> being set to a message
detailing the precise problem. Only the first error found will be returned, so several
iterations may be necessary to fix a badly broken parameter hash. If the flag is not set,
any parameters that are a valid hashref or anonymous hash will be passed straight to
Betfair, and errors in the construction will result in a Betfair error, which will usually
be more general (i.e. cryptic and unhelpful). As some parameter hashes can be quite
complicated, there is a performance hit incurred by turning parameter checking on. For
this reason, the default is to NOT check parameters, although you should turn it on during
development and for debugging.

=cut

sub check_parameters {
  my $self = shift;
  if (@_){
    my $current_state = $self->{p_check};
    my $flag = shift;
    $self->{p_check} = $flag ? 1 : 0;
    unless ($self->{p_check} == $current_state) {
      $self->{data_types} = $self->{p_check} ? $self->_load_data_types() : {};
    }
  }
  return $self->{p_check};
}

=head3 australian() *DEPRECATED*

  my $is_aus = $bf->australian();
  $bf->australian('<boolean>');

Betfair previously used seperate URLs for Australian racing, and this method implemented
the switching between those URLs. From 2016-09-20 the Australian exchange was integrated
into the main exchange, making this method unnecessary. From 2017-01-04 calls to the
Australian endpoints WILL NO LONGER WORK.

The method has been retained in this version for backwards compatibility, but no longer
changes the endpoints. It exists purely to avoid breaking existing third party code. If
your application uses this method, you are STRONGLY RECOMMENDED to remove any references
to it, as it will be removed in future versions.

=cut

sub australian {
  my $self = shift;
  if (@_){
    my $current_state = $self->{australian};
    my $flag = shift;
    $self->{australian} = $flag ? 1 : 0;
  }
  return $self->{australian};
}

=head3 error()

  my $err_str = $bf->error();

Read-only string containing the last error encountered. This is not reset by sucessful
calls, so the return value of the method needs to be checked to determine success or
failure (all methods return '0' if any error is encountered):

  unless ($ret_value = $bf->someCall($parameters) {
    $err_str = $bf->error();
    print "someCall FAILED : $err_str\n";
    <error handling code>
  }

Errors at any stage will populate this string, including connection timeouts and HTTP
errors. If the call makes it as far as the Betfair API before failing (for instance, a
lack of available funds), the decoded JSON response will be available in $bf->response and
may well contain more detailed and descriptive error messages, so this is probably the
best place to look if the high level Betfair error string returned in $bf->error() is
vague or ambiguous. (This is especially useful in cases where a number of bets are
submitted for processing, and one of them fails - this usually makes the whole call fail,
and the only way to find the culprit is to dig through the response and find the bet which
caused the problem).

=cut

sub error {
  my $self = shift;
  return $self->{error};
}

=head3 response()

  my $resp = $bf->response();

Read-only hash ref containing the last successful response from the API (for certain
values of 'successful'). If an API call succeeds completely, it will return a hash
reference containing the decoded JSON response (which will be identical to $bf->response),
so in this case, $bf->response() is pretty much redundant. If ANY error is encountered,
the return value from the API call will be '0', and in this case more details on the
specific error can often be found by examining $bf->response(). (Obviously this only works
for calls which fail after reaching the API; an HTTP 404 error, for example, will leave
the response from the previous successful API call in $bf->response).

=cut

sub response {
  my $self = shift;
  return $self->{response};
}


=head1 API CALLS

These are generally of the form '$return_value = $bf->someCall($parameters)', where
'$parameters' is a hash reference (or anonymous hash) containing one or more BETFAIR
DATA TYPES (described below), and $return_value is a hash or array reference, again
containing one or more BETFAIR DATA TYPES. Many of these data types are straightforward
lists or hashes of scalars, but some are quite complex structures. Depending on the
call, some parameters may be required (RQD) and others may be optional (OPT). If
$bf->check_parameters() is set to 'true', the parameter hash will be checked before it
is sent to the API, and any errors in construction will result in the method call
immediately returning '0' and C<< $bf->error >> being set to a message detailing the
precise problem. If $bf->check_parameters() is set to 'false' (the default), the
parameter hash is sent 'as is' to Betfair, and any problems with it's construction will
result in a Betfair error message.  Any error in a call, for whatever reason, will
result in a $return_value of '0'. In this case, $bf->error() will contain a string
describing the error and further details of the error may be found by examining
$bf->response().


=head2 Session Methods

=head3 login({username => 'username', password => 'password'})

  my $return_value = $bf->login({username => 'username', password => 'password'});

Logs in to the application using the supplied username and password. For a successful
login, 'ssl_cert' and 'ssl_key' must already be set. Returns '1' if the login succeeded,
'0' if any errors were encountered.

=cut

sub login {
  my $self = shift;
  unless (@_) {
    $self->{error} = 'Username and Password Required';
    return 0;
  }
  my $params = shift;
  unless(ref($params) eq 'HASH') {
    $self->{error} = 'Parameters must be a hash ref or anonymous hash';
    return 0;
  }
  unless ($params->{username} and $params->{password}) {
    $self->{error} = 'Username and Password Required';
    return 0;
  }
  my $cert_file = $self->ssl_cert();
  unless ($cert_file) {
    $self->{error} = 'SSL Client Certificate Required';
    return 0;
  }
  my $key_file = $self->ssl_key();
  unless ($key_file) {
    $self->{error} = 'SSL Client Key Required';
    return 0;
  }
  my $got_app_key  = $self->app_key;
  $self->app_key('login') unless $got_app_key;
  my $login_client = HTTP::Tiny->new(
     agent           => "WWW::BetfairNG/$VERSION",
     SSL_options     => {
			 'SSL_cert_file' => $self->ssl_cert,
			 'SSL_key_file'  => $self->ssl_key,
			},
     default_headers => {
                         'X-Application' => $self->app_key,
			 'Accept'        => 'application/json',
			});
  my $formdata = {username => $params->{username}, password => $params->{password}};
  my $url      = BF_C_LOGIN_ENDPOINT;
  my $response = $login_client->post_form($url, $formdata);
  $self->app_key(undef) unless $got_app_key;
  unless ($response->{success}) {
    $self->{error}  = $response->{status}.' '.$response->{reason}.' '.$response->{content};
    return 0;
  }
  $self->{response} = decode_json($response->{content});
  unless ($self->{response}->{loginStatus} eq 'SUCCESS') {
    $self->{error}  = $self->{response}->{loginStatus};
    return 0;
  }
  $self->session($self->{response}->{sessionToken});
  return 1;
}

=head3 interactiveLogin({username => 'username', password => 'password'})

  my $return_value = $bf->interactiveLogin({username => 'username',
                                            password => 'password'});

Logs in to the application using the supplied username and password. This method doesn't
use SSL certificates, so it will work without setting those up. However, Betfair STRONGLY
RECOMMEND that unattended bots use the non-interactive login ($bf->login()). Returns '1'
if the login succeeded, '0' if any errors were encountered.

=cut

sub interactiveLogin {
  my $self = shift;
  unless (@_) {
    $self->{error} = 'Username and Password Required';
    return 0;
  }
  my $params = shift;
  unless(ref($params) eq 'HASH') {
    $self->{error} = 'Parameters must be a hash ref or anonymous hash';
    return 0;
  }
  unless ($params->{username} and $params->{password}) {
    $self->{error} = 'Username and Password Required';
    return 0;
  }
  my $got_app_key  = $self->app_key;
  $self->app_key('login') unless $got_app_key;
  my $login_client = HTTP::Tiny->new(
     agent           => "WWW::BetfairNG/$VERSION",
     default_headers => {'X-Application' => $self->app_key,
			 'Accept'        => 'application/json',
			});
  my $formdata = {username => $params->{username}, password => $params->{password}};
  my $url      = BF_LOGIN_ENDPOINT;
  my $response = $login_client->post_form($url, $formdata);
  $self->app_key(undef) unless $got_app_key;
  unless ($response->{success}) {
    $self->{error}  = $response->{status}.' '.$response->{reason}.' '.$response->{content};
    return 0;
  }
  $self->{response} = decode_json($response->{content});
  unless ($self->{response}->{status} eq 'SUCCESS') {
    $self->{error}  = $self->{response}->{status};
    return 0;
  }
  $self->session($self->{response}->{token});
  return 1;
}

=head3 logout()

  my $return_value = $bf->logout();

Logs out of the application. Returns '1' if the logout succeeded,'0' if any errors were
encountered.

=cut

sub logout {
  my $self = shift;
  unless ($self->session){
    $self->{error} = 'Not logged in';
    return 0;
  }
  my $options = {
		 headers => {
			     'X-Application'    => $self->app_key,
			     'X-Authentication' => $self->session,
			     'Connection'       => 'Close'
			    }
		};
  my $url = BF_LOGOUT_ENDPOINT;
  my $response = $self->{client}->get($url, $options);
  unless ($response->{success}) {
    $self->{error}  = $response->{status}.' '.$response->{reason}.' '.$response->{content};
    return 0;
  }
  my $content = $self->_gunzip($response->{content});
  return 0 unless ($content);
  $self->{response} = decode_json($content);
  unless ($self->{response}->{status} eq 'SUCCESS') {
    $self->{error}  = $self->{response}->{status};
    return 0;
  }
  $self->session('');
  return 1;
}

=head3 keepAlive()

  my $return_value = $bf->keepAlive();

Sends a 'Keep Alive' message to the host. Without this, the session will time out after
about four hours. Unlike the SOAP interface, other API calls do NOT reset the timeout;
it has to be done explicitly with a 'keepAlive'. Returns '1' if the keepAlive succeeded,
'0' if any errors were encountered.

=cut

sub keepAlive {
  my $self = shift;
  unless ($self->session){
    $self->{error} = 'Not logged in';
    return 0;
  }
  unless ($self->app_key){
    $self->{error} = 'No application key set';
    return 0;
  }

  my $options = {headers => {'X-Application'    => $self->app_key,
			     'X-Authentication' => $self->session}};
  my $url = BF_KPALIVE_ENDPOINT;
  my $response = $self->{client}->get($url, $options);
  unless ($response->{success}) {
    $self->{error}  = $response->{status}.' '.$response->{reason}.' '.$response->{content};
    return 0;
  }
  my $content = $self->_gunzip($response->{content});
  return 0 unless ($content);
  $self->{response} = decode_json($content);
  unless ($self->{response}->{status} eq 'SUCCESS') {
    $self->{error}  = $self->{response}->{status};
    return 0;
  }
  $self->session($self->{response}->{token});
  return 1;
}

=head2 Betting Operations

The descriptions of these methods are taken directly from the Betfair documentation.  A
listing is given of parameters which can be passed to each method together with their data
type (BETFAIR DATA TYPES are described below). Required parameters are marked as RQD and
optional ones as OPT. If a parameter is marked as RQD, you need to pass it even if it
contains no data, so a MarketFilter which selects all markets would be passed as:

  filter => {}

=head3 listCompetitions($parameters)

  my $return_value = $bf->listCompetitions({filter => {}});

Returns a list of Competitions (i.e., World Cup 2013) associated with the markets selected
by the MarketFilter. Currently only Football markets have an associated competition.

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         CompetitionResult

=cut

sub listCompetitions {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listCompetitions/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listCountries($parameters)

  my $return_value = $bf->listCountries({filter => {}});

Returns a list of Countries associated with the markets selected by the MarketFilter.

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         CountryCodeResult

=cut

sub listCountries {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listCountries/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listCurrentOrders([$parameters])

  my $return_value = $bf->listCurrentOrders();

Returns a list of your current orders. Optionally you can filter and sort your current
orders using the various parameters, setting none of the parameters will return all of
your current orders, up to a maximum of 1000 bets, ordered BY_BET and sorted
EARLIEST_TO_LATEST. To retrieve more than 1000 orders, you need to make use of the
fromRecord and recordCount parameters.

Parameters

  betIds               Array of Strings    OPT
  marketIds            Array of Strings    OPT
  orderProjection      OrderProjection     OPT
  customerOrderRefs    Array of Strings    OPT
  customerStrategyRefs Array of Strings    OPT
  dateRange            TimeRange           OPT
  orderBy              OrderBy             OPT
  sortDir              SortDir             OPT
  fromRecord           Integer             OPT
  recordCount          Integer             OPT

Return Value

  currentOrders     Array of CurrentOrderSummary
  moreAvailable     Boolean

=cut

sub listCurrentOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listCurrentOrders/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listClearedOrders([$parameters])

  my $return_value = $bf->listClearedOrders({betStatus => 'SETTLED'});

Returns a list of settled bets based on the bet status, ordered by settled date.  To
retrieve more than 1000 records, you need to make use of the fromRecord and recordCount
parameters. (NOTE The default ordering is DESCENDING settled date, so most recently
settled is listed first).

Parameters

  betStatus            	 BetStatus           RQD
  eventTypeIds         	 Array of Strings    OPT
  eventIds             	 Array of Strings    OPT
  marketIds            	 Array of Strings    OPT
  runnerIds            	 Array of Strings    OPT
  betIds               	 Array of Strings    OPT
  customerOrderRefs    	 Array of Strings    OPT
  customerStrategyRefs 	 Array of Strings    OPT
  side                 	 Side                OPT
  settledDateRange     	 TimeRange           OPT
  groupBy              	 GroupBy             OPT
  includeItemDescription Boolean             OPT
  locale               	 String              OPT
  fromRecord           	 Integer             OPT
  recordCount          	 Integer             OPT

Return Value

  clearedOrders     Array of ClearedOrderSummary
  moreAvailable     Boolean

=cut

sub listClearedOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listClearedOrders/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listEvents($parameters)

  my $return_value = $bf->listEvents({filter => {}});

Returns a list of Events associated with the markets selected by the MarketFilter.

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         EventResult

=cut

sub listEvents {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listEvents/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listEventTypes($parameters)

  my $return_value = $bf->listEventTypes({filter => {}});

Returns a list of Event Types (i.e. Sports) associated with the markets selected
by the MarketFilter.

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         EventTypeResult

=cut

sub listEventTypes {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listEventTypes/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listMarketBook($parameters)

  my $return_value = $bf->listMarketBook({marketIds => [<market id>]});

Returns a list of dynamic data about markets. Dynamic data includes prices, the status of
the market, the status of selections, the traded volume, and the status of any orders you
have placed in the market. Calls to listMarketBook should be made up to a maximum of 5
times per second to a single marketId.

Parameters

  marketIds                     Array of Strings    RQD
  priceProjection               PriceProjection     OPT
  orderProjection               OrderProjection     OPT
  matchProjection               MatchProjection     OPT
  includeOverallPosition        Boolean             OPT
  partitionMatchedByStrategyRef Boolean             OPT
  customerStrategyRefs          Array of Strings    OPT
  currencyCode                  String              OPT
  locale                        String              OPT

Return Value

  Array Ref                     MarketBook

=cut

sub listMarketBook {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listMarketBook/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listRunnerBook($parameters)

  my $return_value = $bf->listRunnerBook({marketId    => <market id>,
                                          selectionId => <selection id>});

Returns a list of dynamic data about a market and a specified runner. Dynamic data
includes prices, the status of the market, the status of selections, the traded volume,
and the status of any orders you have placed in the market.  You can only pass in one
marketId and one selectionId in that market per request. If the selectionId being passed
in is not a valid one / doesn't belong in that market then the call will still work but
only the market data is returned.

Parameters

  marketId                      String              RQD
  selectionId                   Long                RQD
  handicap                      Double              OPT
  priceProjection               PriceProjection     OPT
  orderProjection               OrderProjection     OPT
  matchProjection               MatchProjection     OPT
  includeOverallPosition        Boolean             OPT
  partitionMatchedByStrategyRef Boolean             OPT
  customerStrategyRefs          Array of Strings    OPT
  currencyCode                  String              OPT
  locale                        String              OPT
  matchedSince                  Date                OPT
  betIds                        Array of Strings    OPT

Return Value

  Array Ref                     MarketBook

=cut

sub listRunnerBook {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listRunnerBook/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listMarketCatalogue($parameters)

  my $return_value = $bf->listMarketCatalogue({filter => {}, maxResults => 1});

Returns a list of information about markets that does not change (or changes very rarely).
You use listMarketCatalogue to retrieve the name of the market, the names of selections
and other information about markets.  Market Data Request Limits apply to requests made
to listMarketCatalogue.

Parameters

  filter            MarketFilter                 RQD
  marketProjection  Array of MarketProjection    OPT
  sort              MarketSort                   OPT
  maxResults        Integer                      RQD
  locale            String                       OPT

Return Value

  Array Ref         MarketCatalogue

=cut

sub listMarketCatalogue {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listMarketCatalogue/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listMarketProfitAndLoss($parameters)

  my $return_value = $bf->listMarketProfitAndLoss({marketIds => [<market id>]});

Retrieve profit and loss for a given list of markets. The values are calculated using
matched bets and optionally settled bets. Only odds (MarketBettingType = ODDS) markets
are implemented, markets of other types are silently ignored.

Parameters

  marketIds         Array of Strings    RQD
  includeSettledBets         Boolean    OPT
  includeBspBets             Boolean    OPT
  netOfCommission            Boolean    OPT

Return Value

  Array Ref         MarketProfitAndLoss

=cut

sub listMarketProfitAndLoss {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listMarketProfitAndLoss/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listMarketTypes($parameters)

  my $return_value = $bf->listMarketTypes({filter => {}});

Returns a list of market types (i.e. MATCH_ODDS, NEXT_GOAL) associated with the markets
selected by the MarketFilter. The market types are always the same, regardless of locale

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         MarketTypeResult

=cut

sub listMarketTypes {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listMarketTypes/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listTimeRanges($parameters)

  my $return_value = $bf->listTimeRanges({filter => {}, granularity => 'DAYS'});

Returns a list of time ranges in the granularity specified in the request (i.e. 3PM
to 4PM, Aug 14th to Aug 15th) associated with the markets selected by the MarketFilter.

Parameters

  filter            MarketFilter        RQD
  granularity       TimeGranularity     RQD

Return Value

  Array Ref         TimeRangeResult

=cut

sub listTimeRanges {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listTimeRanges/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listVenues($parameters)

  my $return_value = $bf->listVenues({filter => {}});

Returns a list of Venues (i.e. Cheltenham, Ascot) associated with the markets
selected by the MarketFilter. Currently, only Horse Racing markets are associated
with a Venue.

Parameters

  filter            MarketFilter        RQD
  locale            String (ISO 3166)   OPT

Return Value

  Array Ref         VenueResult

=cut

sub listVenues {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'listVenues/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 placeOrders($parameters)

  my $return_value = $bf->placeOrders({marketId    => <market id>,
	                              instructions => [{
				             selectionId => <selection id>,
				                handicap => "0",
				                    side => "BACK",
				               orderType => "LIMIT",
		         	              limitOrder => {
				       	             size  => <bet size>,
					             price => <requested price>,
				           persistenceType => "LAPSE"
                                                            }
                                                      }]
                                     });

Place new orders into market. This operation is atomic in that all orders will
be placed or none will be placed. Please note that additional bet sizing rules
apply to bets placed into the Italian Exchange.

Parameters

  marketId            String                      RQD
  instructions        Array of PlaceInstruction   RQD
  customerRef         String                      OPT
  marketVersion       MarketVersion               OPT
  customerStrategyRef String                      OPT
  async               Boolean                     OPT


Return Value

  customerRef         String
  status              ExecutionReportStatus
  errorCode           ExecutionReportErrorCode
  marketId            String
  instructionReports  Array of PlaceInstructionReport

=cut

sub placeOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'placeOrders/';
  my $result = $self->_callAPI($url, $params);
  if ($result) {
    my $status = $result->{status};
    unless ($status eq 'SUCCESS') {
      $self->{error} = $status;
      if ($result->{errorCode}) {
	$self->{error} .= " : ".$result->{errorCode};
      }
      return 0;
    }
  }
  return $result;
}

=head3 cancelOrders([$parameters])

  my $return_value = $bf->cancelOrders();

Cancel all bets OR cancel all bets on a market OR fully or partially cancel
particular orders on a market. Only LIMIT orders can be cancelled or partially
cancelled once placed. Calling this with no parameters will CANCEL ALL BETS.

Parameters

  marketId          String                      OPT
  instructions      Array of CancelInstruction  OPT
  customerRef       String                      OPT

Return Value

  customerRef       String
  status            ExecutionReportStatus
  errorCode         ExecutionReportErrorCode
  marketId          String
  instructionReports  Array of CancelInstructionReport

=cut

sub cancelOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'cancelOrders/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}


=head3 replaceOrders($parameters)

  my $return_value = $bf->replaceOrders({marketId => <market id>,
			             instructions => [{
                                               betId => <bet id>,
                                            newPrice => <new price>
                                                     }]
                                       });

This operation is logically a bulk cancel followed by a bulk place. The
cancel is completed first then the new orders are placed. The new orders
will be placed atomically in that they will all be placed or none will be
placed. In the case where the new orders cannot be placed the cancellations
will not be rolled back.

Parameters

  marketId          String                      RQD
  instructions      Array of ReplaceInstruction RQD
  customerRef       String                      OPT
  marketVersion     MarketVersion               OPT
  async             Boolean                     OPT

Return Value

  customerRef       String
  status            ExecutionReportStatus
  errorCode         ExecutionReportErrorCode
  marketId          String
  instructionReports  Array of ReplaceInstructionReport

=cut

sub replaceOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'replaceOrders/';
  my $result = $self->_callAPI($url, $params);
  if ($result) {
    my $status = $result->{status};
    unless ($status eq 'SUCCESS') {
      $self->{error} = $status;
      if ($result->{errorCode}) {
	$self->{error} .= " : ".$result->{errorCode};
      }
      return 0;
    }
  }
  return $result;
}

=head3 updateOrders($parameters)

  my $return_value = $bf->updateOrders({marketId => <market id>,
			             instructions => [{
                                               betId => <bet id>,
                                  newPersistenceType => "LAPSE"
                                                     }]
                                       });

Update non-exposure changing fields.

Parameters

  marketId          String                      RQD
  instructions      Array of UpdateInstruction  RQD
  customerRef       String                      OPT

Return Value

  customerRef       String
  status            ExecutionReportStatus
  errorCode         ExecutionReportErrorCode
  marketId          String
  instructionReports  Array of UpdateInstructionReport

=cut

sub updateOrders {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{bet_end_pt}.'updateOrders/';
  my $result = $self->_callAPI($url, $params);
  if ($result) {
    my $status = $result->{status};
    unless ($status eq 'SUCCESS') {
      $self->{error} = $status;
      if ($result->{errorCode}) {
	$self->{error} .= " : ".$result->{errorCode};
      }
      return 0;
    }
  }
  return $result;
}

=head2 Accounts Operations

As with the Betting Operations, the descriptions of these methods are taken directly from
the Betfair documentation. Once again, required parameters are denoted by RQD and optional
ones by OPT. Some parameters are described in terms of BETFAIR DATA TYPES, which are
described below.

=head3 createDeveloperAppKeys($parameters)

  my $return_value = $bf->createDeveloperAppKeys(<application name>);

Create two application keys for given user; one active and the other delayed. NOTE as this
call fails if the keys have already been created, it has NOT BEEN TESTED.

Parameters

  appName           String              RQD

Return Value

  appName           String
  appId             Long
  appVersions       Array of DeveloperAppVersion

=cut

sub createDeveloperAppKeys {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'createDeveloperAppKeys/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 getAccountDetails()

  my $return_value = $bf->getAccountDetails();

Returns the details relating [to] your account, including your discount rate and Betfair
point balance. Takes no parameters.

Return Value

  currencyCode      String
  firstName         String
  lastName          String
  localeCode        String
  region            String
  timezone          String
  discountRate      Double
  pointsBalance     Integer
  countryCode       String

=cut

sub getAccountDetails {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'getAccountDetails/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 getAccountFunds()

  my $return_value = $bf->getAccountFunds([$parameters]);

Get available to bet amount. The optional parameter 'wallet' was
previously used to access Australian funds, but since 2016-09-20
these have been included in the main (UK) wallet.

Parameters

  wallet            Wallet    OPT - DEPRECATED

Return Value

  availableToBetBalance  Double
  exposure               Double
  retainedCommission     Double
  exposureLimit          Double
  discountRate           Double
  pointsBalance          Integer

=cut

sub getAccountFunds {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'getAccountFunds/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 getDeveloperAppKeys()

  my $return_value = $bf->getDeveloperAppKeys();

Get all application keys owned by the given developer/vendor. Takes no parameters.

Return Value

  Array Ref         DeveloperApp

=cut

sub getDeveloperAppKeys {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'getDeveloperAppKeys/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 getAccountStatement([$parameters])

  my $return_value = $bf->getAccountStatement();

Get Account Statement.

Parameters

  locale            String              OPT
  fromRecord        Integer             OPT
  recordCount       Integer             OPT
  itemDateRange     TimeRange           OPT
  includeItem       IncludeItem         OPT
  wallet            Wallet              OPT

Return Value

  accountStatement  Array of StatementItem
  moreAvailable     Boolean

=cut

sub getAccountStatement {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'getAccountStatement/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 listCurrencyRates([$parameters])

  my $return_value = $bf->listCurrencyRates();

Returns a list of currency rates based on given currency.

Parameters

  fromCurrency      String              OPT

Return Value

  Array Ref         CurrencyRate

=cut

sub listCurrencyRates {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'listCurrencyRates/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head3 transferFunds($parameters) - DEPRECATED

  my $return_value = $bf->transferFunds({from   => 'UK',
                                         to     => 'AUSTRALIAN',
                                         amount => <amount> });

Transfer funds between different wallets.  With the removal of the Australian
wallet on 2016-09-20 this method is currently DEPRECATED, although it has been
retained as the introduction of alternative wallets for ringfencing funds etc.
has been mooted by Betfair on the forum.

Parameters

  from              Wallet    RQD
  to                Wallet    RQD
  amount            Double    RQD

Return Value

  transactionId     String

=cut

sub transferFunds {
  my $self = shift;
  my $params = shift || {};
  my $url = $self->{acc_end_pt}.'transferFunds/';
  my $result = $self->_callAPI($url, $params);
  return $result;
}

=head2 Navigation Data for Applications

This has only one method (navigationMenu()), which retrieves the full Betfair navigation
menu from a compressed file which is updated every five minutes.

=head3 navigationMenu()

  my $menu = $bf->navigationMenu()

Returns a huge hash containing descriptions of all Betfair markets arranged in a tree
structure. The root of the tree is a GROUP entity called 'ROOT', from which hang a
number of EVENT_TYPE entities. Each of these can have a number of GROUP or EVENT
entities as children, which in turn can have GROUP or EVENT children of their own.
EVENTs may also have individual MARKETs as children, whereas GROUPs may not. MARKETs
never have childen, and so are always leaf-nodes, but be aware that the same MARKET
may appear at the end of more than one branch of the tree. This is especially true where
RACEs are concerned; a RACE is yet another entity, which currently may only hang off the
EVENT_TYPE identified by the id '7' and the name 'Horse Racing'. A RACE may only have
MARKETs as children, and these will typically also appear elsewhere in the tree.
Takes no parameters (so it's all or nothing at all).

Return Value

  children          Array of EVENT_TYPE
  id                Integer (always '0' for ROOT)
  name              String  (always 'ROOT' for ROOT)
  type              Menu entity type (always 'GROUP' for ROOT)

Menu Entity Types

  EVENT_TYPE

  children          Array of GROUP, EVENT and/or RACE
  id                String, will be the same as EventType id
  name              String, will be the same as EventType name
  type              Menu entity type (EVENT_TYPE)


  GROUP

  children          Array of GROUP and/or EVENT
  id                String
  name              String
  type              Menu entity type (GROUP)

  EVENT

  children          Array of GROUP, EVENT and/or MARKET
  id                String, will be the same as Event id
  name              String, will be the same as Event name
  countryCode       ISO 3166 2-Character Country Code
  type              Menu entity type (EVENT)

  RACE

  children          Array of MARKET
  id                String
  name              String
  type              Menu entity type (RACE)
  startTime         Date
  countryCode       ISO 3166 2-Character Country Code
  venue             String (Course name in full)

  MARKET

  exchangeId        String (Currently always '1')
  id                String, will be the same as Market id
  marketStartTime   Date
  marketType        MarketType (e.g. 'WIN', 'PLACE')
  numberOfWinners   No. of winners (used in 'PLACE' markets)
  name              String, will be the same as Market name
  type              Menu entity type (MARKET)

=cut

sub navigationMenu {
  my $self = shift;
  my $params = {};
  # Can't use _callAPI because we need a 'get' not a 'post'
  unless ($self->session){
    $self->{error} = 'Not logged in';
    return 0;
  }
  unless ($self->app_key){
    $self->{error} = 'No application key set';
    return 0;
  }
  # Can't use default client because we need a longer timeout
  my $client = HTTP::Tiny->new(
                     timeout         => 30,
                     agent           => "WWW::BetfairNG/$VERSION",
		     verify_SSL      => 1,
                     default_headers => {'Content-Type'    => 'application/json',
			                 'Accept'          => 'application/json',
			                 'Accept-Encoding' => 'gzip'
			                }
  );
  my $url = $self->{bet_end_pt}.'en/navigation/menu.json';
  my $options = {
		 headers => {
			     'X-Authentication' => $self->session,
			     'X-Application'    => $self->app_key
			    }
		};
  my $response = $client->get($url, $options);
  unless ($response->{success}) {
    $self->{error}  = $response->{status}.' '.$response->{reason}.' '.$response->{content};
    return 0;
  }
  my $content = $self->_gunzip($response->{content});
  return 0 unless ($content);
  $self->{response} = decode_json($content);
  return $self->response;
}

=head2 Heartbeat API

This Heartbeat operation is provided to allow customers to automatically cancel their
unmatched bets in the event of their API client losing connectivity with the Betfair API.

=head3 heartbeat($parameters)

  my $return_value = $bf->heartbeat({preferredTimeoutSeconds => <timeout>});

This heartbeat operation is provided to help customers have their positions managed
automatically in the event of their API clients losing connectivity with the Betfair
API. If a heartbeat request is not received within a prescribed time period, then Betfair
will attempt to cancel all 'LIMIT' type bets for the given customer on the given
exchange. There is no guarantee that this service will result in all bets being cancelled
as there are a number of circumstances where bets are unable to be cancelled. Manual
intervention is strongly advised in the event of a loss of connectivity to ensure that
positions are correctly managed. If this service becomes unavailable for any reason, then
your heartbeat will be unregistered automatically to avoid bets being inadvertently
cancelled upon resumption of service. you should manage your position manually until the
service is resumed. Heartbeat data may also be lost in the unlikely event of nodes failing
within the cluster, which may result in your position not being managed until a subsequent
heartbeat request is received.

Parameters

  preferredTimeoutSeconds  Integer      RQD

Return Value

  actionPerformed          ActionPerformed
  actualTimeoutSeconds     Integer

=cut

sub heartbeat {
  my $self = shift;
  my $params = shift || {};
  my $url = BF_HRTBEAT_ENDPOINT;
  my $action = 'HeartbeatAPING/v1.0/heartbeat';
  my $result = $self->_callRPC($url, $action, $params);
  return $result;
}

=head2 Race Status API

The listRaceDetails operation is provided to allow customers to establish the status of a
horse or greyhound race market both prior to and after the start of the race.  This
information is available for UK and Ireland races only.

=head3 listRaceDetails($parameters)

  my $return_value = $bf->listRaceDetails();

Search for races to get their details. 'meetingIds' optionally restricts the results to
the specified meeting IDs. The unique Id for the meeting equivalent to the eventId for
that specific race as returned by listEvents. 'raceIds' optionally restricts the results
to the specified race IDs. The unique Id for the race in the format meetingid.raceTime
(hhmm). raceTime is in UTC.

Parameters

  meetingIds     Array of Strings     OPT
  raceIds        Array of Strings     OPT

Return Value

  ArrayRef       RaceDetails

=cut

sub listRaceDetails {
  my $self = shift;
  my $params = shift || {};
  my $url = BF_RSTATUS_ENDPOINT;
  my $action = 'ScoresAPING/v1.0/listRaceDetails';
  my $result = $self->_callRPC($url, $action, $params);
  return $result;
}

#===============================#
# Private Methods and Functions #
#===============================#

# Called by all API methods EXCEPT navigationMenu to do the talking to Betfair.
# =============================================================================
sub _callAPI {
  my ($self, $url, $params) = @_;
  unless ($self->session){
    $self->{error} = 'Not logged in';
    return 0;
  }
  unless ($self->app_key or ($url =~ /DeveloperAppKeys/)){
    $self->{error} = 'No application key set';
    return 0;
  }
    unless(ref($params) eq 'HASH') {
    $self->{error} = 'Parameters must be a hash ref or anonymous hash';
    return 0;
  }
  if ($self->check_parameters) {
    my $caller = [caller 1]->[3];
    $caller =~ s/^.+:://;
    return 0 unless $self->_check_parameter($caller, $params);
  }
  my $options = {
		 headers => {
			     'X-Authentication' => $self->session,
			    },
		 content => encode_json($params)
		};
  unless ($url =~ /DeveloperAppKeys/) {
    $options->{headers}{'X-Application'} = $self->app_key;
  }
  my $response = $self->{client}->post($url, $options);
  unless ($response->{success}) {
    if ($response->{status} == 400) {
      my $content = $self->_gunzip($response->{content});
      $self->{response} = decode_json($content);
      $self->{error}  = $self->{response}->{detail}->{APINGException}->{errorCode} ||
	$response->{status}.' '.$response->{reason}.' '.$response->{content};
    }
    else {
      $self->{error}  = $response->{status}.' '.$response->{reason}.' '
                       .$response->{content};
    }
    return 0;
  }
  my $content = $self->_gunzip($response->{content});
  return 0 unless ($content);
  $self->{response} = decode_json($content);
  return $self->{response};
}

# Called by Heartbeat and Race Status methods to do the talking to Betfair.
# =========================================================================#
#                                                                          #
# (Betfair generally supports both a JSON-REST and a JSON-RPC interface to #
# the API, and we use REST. However, Heartbeat and Race Status only allow  #
# RPC, so we need a function for that as well.                             #
#                                                                          #
# =========================================================================#
sub _callRPC {
  my ($self, $url, $action, $params) = @_;
  unless ($self->session){
    $self->{error} = 'Not logged in';
    return 0;
  }
  unless ($self->app_key){
    $self->{error} = 'No application key set';
    return 0;
  }
    unless(ref($params) eq 'HASH') {
    $self->{error} = 'Parameters must be a hash ref or anonymous hash';
    return 0;
  }
  if ($self->check_parameters) {
    my ($method_name) = $action =~ /\/(\w+)$/;
    return 0 unless $self->_check_parameter($method_name, $params);
  }
  my $post    = { params => $params, jsonrpc => "2.0", method => $action, id => 1};
  my $options = {
		 headers => {
			     'X-Authentication' => $self->session,
			     'X-Application'    => $self->app_key,
			    },
		 content => encode_json($post)
		};
  my $response = $self->{client}->post($url, $options);
  unless ($response->{success}) {
    if ($response->{status} == 400) {
      my $content = $self->_gunzip($response->{content});
      $self->{response} = decode_json($content);
      $self->{error}  = $self->{response}->{detail}->{APINGException}->{errorCode} ||
	$response->{status}.' '.$response->{reason}.' '.$response->{content};
    }
    else {
      $self->{error}  = $response->{status}.' '.$response->{reason}.' '
                       .$response->{content};
    }
    return 0;
  }
  my $content = $self->_gunzip($response->{content});
  return 0 unless ($content);
  $self->{response} = decode_json($content);
  if ($self->{response}->{error}) {
    $self->{error} = $self->{response}->{error}->{message};
    return 0;
  }
  if ($self->{response}->{result}) {
    return $self->{response}->{result};
  }
  else {
    $self->{error} = "Empty reply";
    return 0;
  }
}

# HTTP::Tiny doesn't have built-in decompression so we do it here
# ===============================================================
sub _gunzip {
  my $self  = shift;
  my $input = shift;
  unless ($input) {
    $self->{error} = "gunzip failed : empty input string";
    return 0;
  }
  my $output;
  my $status = gunzip(\$input => \$output);
  unless ($status) {
    $self->{error} = "gunzip failed : $GunzipError";
    return 0;
  }
  return $output;
}

# We check parameters recursively, but only when $bf->check_parameters is TRUE
# ============================================================================
sub _check_parameter {
  my $self = shift;
  my ($name, $parameter) = @_;
  unless (exists $self->{data_types}{$name}) {
    $self->{error} = "Unknown parameter '$name'";
    return 0;
  }
  my $def = $self->{data_types}{$name};
  if ($def->{type} eq 'HASH') {
    unless (ref($parameter) eq 'HASH') {
      $self->{error} = "Parameter '$name' should be a hashref";
      return 0;
    }
    my %fields  = ((map {$_ => [1, 0]} @{$def->{required}}),
                   (map {$_ => [0, 0]} @{$def->{allowed}}));
    while (my ($key, $value) = each %$parameter) {
      unless (exists $fields{$key}) {
	$self->{error} = "Invalid parameter '$key' in '$name'";
	return 0;
      }
      # Special cases - I hate putting these in, but if we are going to check
      # parameters, we ought to check them properly, even if it means spoiling
      # the abstraction of the checking subroutine. God I hate Betfair
      my $check_key = $key;
      if ($key eq 'instructions') {
	my ($prefix) = $name =~ m/^(.+)Orders$/;
	$check_key = $prefix.'Instructions';
      }
      if (($key eq 'from') or ($key eq 'to')) {
	if ($name eq 'transferFunds') {
	  $check_key = $key.'Wallet';
	}
      }
      unless ($self->_check_parameter($check_key, $value)) {
	# DON'T set error - already set recursively
	return 0;
      }
      $fields{$key}[1]++;
    }
    if (my @missing = grep {($fields{$_}[0] == 1) and ($fields{$_}[1] == 0)}
                      keys %fields){
      $self->{error}  = "The following required parameter".
        (@missing == 1 ? " is" : "s are").
	" missing from '$name' - ";
      $self->{error} .= join(", ", @missing);
      return 0;
    }
    if (my @repeated = grep {($fields{$_}[1] > 1)}
                      keys %fields){
      $self->{error}  = "The following parameter".(@repeated == 1 ? " is" : "s are").
	" repeated in '$name' - ";
      $self->{error} .= join(", ", @repeated);
      return 0;
    }
  }
  elsif ($def->{type} eq 'ARRAY') {
    unless (ref($parameter) eq 'ARRAY') {
      $self->{error} = "Parameter '$name' should be an arrayref";
      return 0;
    }
    unless (@$parameter > 0) {
      $self->{error} = "parameter '$name' can't be an empty array";
      return 0;
    }
    my $key = $def->{array_of};
    foreach my $value (@$parameter) {
      unless ($self->_check_parameter($key, $value)) {
	# DON'T set error - already set recursively
	return 0;
      }
    }
  }
  elsif ($def->{type} eq 'ENUM') {
    if (my $type = ref($parameter)) {
      $type = lc($type);
      $self->{error}  = "Parameter '$name' should be a scalar, not a reference to a";
      $self->{error} .= ($type eq 'array' ? 'n ' : ' ').$type;
      return 0;
    }
    unless (grep {$_ eq $parameter} @{$def->{allowed}}) {
      $self->{error}  = "'$parameter' is not a valid value for '$name', ";
      $self->{error} .= "valid values are - ";
      $self->{error} .= join(", ", @{$def->{allowed}});
      return 0;
    }
  }
  elsif ($def->{type} eq 'SCALAR') {
    if (my $type = ref($parameter)) {
      $type = lc($type);
      $self->{error}  = "Parameter '$name' should be a scalar, not a reference to a";
      $self->{error} .= ($type eq 'array' ? 'n ' : ' ').$type;
      return 0;
    }
    unless ($parameter =~ $def->{allowed}) {
      $self->{error}  = "'$parameter' is not a valid value for '$name' - ";
      $self->{error} .= "valid values are of the form '".$def->{example}."'";
      return 0;
    }
  }
  return 1;
}

# If $bf->check_parameters is turned ON, we load the Betfair Data Type definitions
# ================================================================================
sub _load_data_types {
  my $self = shift;

# Start with some basic data types
  my $long = {
    type     => 'SCALAR',
    allowed  => qr/^\d+$/,
    example  => '123456789'
  };
 my $double = {
    type     => 'SCALAR',
    allowed  => qr/^[\d\.]+$/,
    example  => '3.14'
  };
 my $integer = {
    type     => 'SCALAR',
    allowed  => qr/^\d+$/,
    example  => '255'
  };
 my $string = {
    type     => 'SCALAR',
    allowed  => qr/^.+$/,
    example  => 'Some Text'
  };
 my $boolean = {
    type     => 'SCALAR',
    allowed  => qr/^[01]$/,
    example  => '0 or 1'
  };
 my $date = {
    type     => 'SCALAR',
    allowed  => qr/^\d\d\d\d-\d\d-\d\d[T ]\d\d:\d\d(:\d\d)?Z?$/,
    example  => '2007-04-05T14:30Z'
  };



# main type_defs hash
  my $type_defs = {

# simple types
  version                       => $long,
  amount                        => $double,
  fromRecord                    => $integer,
  recordCount                   => $integer,
  maxResults                    => $integer,
  customerRef                   => $string,
  appName                       => $string,
  textQuery                     => $string,
  venue                         => $string,
  exchangeId                    => $string, # for now, until this feature is implemented
  marketTypeCode                => $string, # for now, until Betfair publish an Enum
  includeItemDescription        => $boolean,
  includeSettledBets            => $boolean,
  includeBspBets                => $boolean,
  netOfCommission               => $boolean,
  bspOnly                       => $boolean,
  turnInPlayEnabled             => $boolean,
  inPlayOnly                    => $boolean,
  async                         => $boolean,
  includeOverallPosition        => $boolean,
  partitionMatchedByStrategyRef => $boolean,
  from                          => $date,
  to                            => $date,
  matchedSince                  => $date,

# method names
  listCompetitions  => {
		        type     => 'HASH',
		        required => [qw/filter/],
		        allowed  => [qw/locale/],
		       },
  listCountries     => {
			type     => 'HASH',
			required => [qw/filter/],
			allowed  => [qw/locale/],
		       },
  listCurrentOrders => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/betIds marketIds orderProjection dateRange
                                        customerOrderRefs customerStrategyRefs
					orderBy sortDir fromRecord recordCount/],
		       },
  listClearedOrders => {
			type     => 'HASH',
			required => [qw/betStatus/],
			allowed  => [qw/eventTypeIds eventIds marketIds runnerIds
				        betIds side settledDateRange groupBy locale
                                        customerOrderRefs customerStrategyRefs
				        includeItemDescription fromRecord recordCount/],
		       },
  listEvents        => {
			type     => 'HASH',
			required => [qw/filter/],
			allowed  => [qw/locale/],
		       },
  listEventTypes    => {
			type     => 'HASH',
			required => [qw/filter/],
			allowed  => [qw/locale/],
		       },
  listMarketBook    => {
			type     => 'HASH',
			required => [qw/marketIds/],
			allowed  => [qw/priceProjection orderProjection matchProjection
                                        includeOverallPosition
                                        partitionMatchedByStrategyRef
                                        customerOrderRefs customerStrategyRefs
                                        currencyCode locale/],
		       },
  listRunnerBook    => {
			type     => 'HASH',
			required => [qw/marketId selectionId/],
			allowed  => [qw/priceProjection orderProjection matchProjection
                                        includeOverallPosition
                                        partitionMatchedByStrategyRef
                                        customerOrderRefs customerStrategyRefs
                                        currencyCode locale matchedSince betIds/],
		       },
  listMarketCatalogue => {
			type     => 'HASH',
			required => [qw/filter maxResults/],
			allowed  => [qw/marketProjection sort locale/],
		       },
  listMarketProfitAndLoss => {
			type     => 'HASH',
			required => [qw/marketIds/],
			allowed  => [qw/includeSettledBets includeBspBets
                                        netOfCommission/],
		       },
  listMarketTypes   => {
			type     => 'HASH',
			required => [qw/filter/],
			allowed  => [qw/locale/],
		       },
  listTimeRanges    => {
			type     => 'HASH',
			required => [qw/filter granularity/],
			allowed  => [qw//],
		       },
  listVenues        => {
			type     => 'HASH',
			required => [qw/filter/],
			allowed  => [qw/locale/],
		       },
  placeOrders       => {
			type     => 'HASH',
			required => [qw/marketId instructions/],
			allowed  => [qw/customerRef marketVersion
                                        customerOrderRef customerStrategyRef async/],
		       },
  cancelOrders      => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/marketId instructions customerRef/],
		       },
  replaceOrders     => {
			type     => 'HASH',
			required => [qw/marketId instructions/],
			allowed  => [qw/customerRef marketVersion async/],
		       },
  updateOrders      => {
			type     => 'HASH',
			required => [qw/marketId instructions/],
			allowed  => [qw/customerRef/],
		       },
  createDeveloperAppKeys => {
			type     => 'HASH',
			required => [qw/appName/],
			allowed  => [qw//],
		       },
  getAccountDetails => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw//],
		       },
  getAccountFunds   => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/wallet/],
		       },
  getDeveloperAppKeys => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw//],
		       },
  getAccountStatement => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/locale fromRecord recordCount itemDateRange
				        includeItem wallet/],
		       },
  listCurrencyRates => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/fromCurrency/],
		       },
  transferFunds     => {
			type     => 'HASH',
			required => [qw/from to amount/],
			allowed  => [qw//],
		       },

  heartbeat         => {
			type     => 'HASH',
			required => [qw/preferredTimeoutSeconds/],
			allowed  => [qw//],
		       },

  listRaceDetails   => {
			type     => 'HASH',
			required => [qw//],
			allowed  => [qw/meetingIds raceIds/],
		       },

# arrays
  betIds            => {
			type     => 'ARRAY',
                        array_of => 'betId',
		       },
  marketIds         => {
			type     => 'ARRAY',
                        array_of => 'marketId',
		       },
  eventTypeIds      => {
			type     => 'ARRAY',
                        array_of => 'eventTypeId',
		       },
  eventIds          => {
			type     => 'ARRAY',
                        array_of => 'eventId',
		       },
  runnerIds         => {
			type     => 'ARRAY',
                        array_of => 'runnerId',
		       },
  marketProjection  => {
			type     => 'ARRAY',
                        array_of => 'MarketProjection',
		       },
  placeInstructions => {
			type     => 'ARRAY',
                        array_of => 'PlaceInstruction',
		       },
  cancelInstructions => {
			type     => 'ARRAY',
                        array_of => 'CancelInstruction',
		       },
  replaceInstructions => {
			type     => 'ARRAY',
                        array_of => 'ReplaceInstruction',
		       },
  updateInstructions => {
			type     => 'ARRAY',
                        array_of => 'UpdateInstruction',
		       },
  exchangeIds       => {
			type     => 'ARRAY',
                        array_of => 'exchangeId',
		       },
  competitionIds    => {
			type     => 'ARRAY',
                        array_of => 'competitionId',
		       },
  venues            => {
			type     => 'ARRAY',
                        array_of => 'venue',
		       },
  marketBettingTypes => {
			type     => 'ARRAY',
                        array_of => 'MarketBettingType',
		       },
  marketCountries   => {
			type     => 'ARRAY',
                        array_of => 'country',
		       },
  marketTypeCodes   => {
			type     => 'ARRAY',
                        array_of => 'marketTypeCode',
		       },
  withOrders        => {
			type     => 'ARRAY',
                        array_of => 'OrderStatus',
		       },
  meetingIds        => {
			type     => 'ARRAY',
                        array_of => 'meetingId',
		       },
  raceIds           => {
			type     => 'ARRAY',
                        array_of => 'raceId',
		       },
  customerStrategyRefs => {
			type     => 'ARRAY',
                        array_of => 'customerStrategyRef',
		       },
  customerOrderRefs => {
			type     => 'ARRAY',
                        array_of => 'customerOrderRef',
		       },
  };

# Common scalars
  $type_defs->{locale}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^[A-Z]{2}$/,
	       example  => 'GB'
			  };
  $type_defs->{country} = $type_defs->{locale};
  $type_defs->{betId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{10,15}$/,
	       example  => '42676999999'
			  };
  $type_defs->{marketId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/[12]\.\d+$/,
	       example  => '1.116099999'
			  };
  $type_defs->{eventTypeId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{1,20}$/,
	       example  => '7'
			  };
  $type_defs->{eventId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{8,10}$/,
	       example  => '27292599'
			  };
  $type_defs->{runnerId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{1,10}$/,
	       example  => '6750999'
			  };
  $type_defs->{currencyCode}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^[A-Z]{3}$/,
	       example  => 'GBP'
			  };
  $type_defs->{fromCurrency} = $type_defs->{currencyCode};
  $type_defs->{competitionId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{1,10}$/,
	       example  => '409999'
			  };
  $type_defs->{preferredTimeoutSeconds}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{1,3}$/,
	       example  => '180'
			  };
  $type_defs->{meetingId} = $type_defs->{eventId};
  $type_defs->{raceId}  = {
	       type     => 'SCALAR',
	       allowed  => qr/^\d{8,10}\.(0[0-9]|1[0-9]|2[0-3])[0-5][0-9]$/,
	       example  => '27292599.1430'
			  };
  $type_defs->{customerStrategyRef} = {
	       type     => 'SCALAR',
	       allowed  => qr/^\w{1,15}$/,
	       example  => 'SVM_Place_01'
			  };
  $type_defs->{customerOrderRef} = {
	       type     => 'SCALAR',
	       allowed  => qr/^\w{1,32}$/,
	       example  => 'ORD_42251b'
			  };


# betfair data types (all the following pod is still inside the _load_data_types sub)
# each type and any sub-types are loaded into the hash following their pod entry.


=head1 BETFAIR DATA TYPES

This is an alphabetical list of all the data types defined by Betfair. It includes
enumerations, which are just sets of allowable string values. Higher level types may
contain lower level types, which can be followed down until simple scalars are
reached. Some elements of complex data types are required, while others are optional -
these are denoted by RQD and OPT respectively. Simple scalar type definitions (Long,
Double, Integer, String, Boolean, Date) have been retained for convenience. 'Date' is
a string in ISO 8601 format (e.g. '2007-04-05T14:30Z').

=head3 ActionPerformed

Enumeration

  NONE                              No action was performed since last heartbeat
  CANCELLATION_REQUEST_SUBMITTED    A request to cancel all unmatched bets was submitted
  ALL_BETS_CANCELLED                All unmatched bets were cancelled since last heartbeat
  SOME_BETS_NOT_CANCELLED           Not all unmatched bets were cancelled
  CANCELLATION_REQUEST_ERROR        There was an error requesting cancellation
  CANCELLATION_STATUS_UNKNOWN       There was no response from requesting cancellation

=head3 BetStatus

Enumeration

  SETTLED     A matched bet that was settled normally.
  VOIDED      A matched bet that was subsequently voided by Betfair.
  LAPSED      Unmatched bet that was cancelled by Betfair (for example at turn in play).
  CANCELLED   Unmatched bet that was cancelled by an explicit customer action.

=cut

  $type_defs->{BetStatus}  = {
			      type     => 'ENUM',
			      allowed  => [qw/SETTLED VOIDED LAPSED CANCELLED/],
			     };
  $type_defs->{betStatus}  = $type_defs->{BetStatus};

=head3 BetTargetType

Enumeration


  BACKERS_PROFIT The payout requested minus the size at which this LimitOrder is to be placed.
  PAYOUT         The total payout requested on a LimitOrder.

=cut

  $type_defs->{BetTargetType}  = {
				  type     => 'ENUM',
				  allowed  => [qw/BACKERS_PROFIT PAYOUT/],
				 };
  $type_defs->{betTargetType}  = $type_defs->{BetTargetType};

=head3 CancelInstruction

  betId             String              RQD
  sizeReduction     Double              OPT

=cut

  $type_defs->{CancelInstruction}  = {
     	       type     => 'HASH',
               required => [qw/betId/],
	       allowed  => [qw/sizeReduction/],
			  };
  $type_defs->{sizeReduction} = $double;

=head3 CancelInstructionReport

  status            InstructionReportStatus
  errorCode         InstructionReportErrorCode
  instruction       CancelInstruction
  sizeCancelled     Double
  cancelledDate     Date

=head3 ClearedOrderSummary

  eventTypeId       String
  eventId           String
  marketId          String
  selectionId       Long
  handicap          Double
  betId             String
  placedDate        Date
  persistenceType   PersistenceType
  orderType         OrderType
  side              Side
  itemDescription   ItemDescription
  priceRequested    Double
  settledDate       Date
  betCount          Integer
  commission        Double
  priceMatched      Double
  priceReduced      Boolean
  sizeSettled       Double
  profit            Double
  sizeCancelled     Double
  lastMatchedDate   Date
  betOutcome        String

=head3 Competition

  id                String
  name              String

=head3 CompetitionResult

  competition       Competition
  marketCount       Integer
  competitionRegion String

=head3 CountryCodeResult

  countryCode       String
  marketCount       Integer

=head3 CurrencyRate

  currencyCode      String (Three letter ISO 4217 code)
  rate              Double

=head3 CurrentOrderSummary

  betId               String
  marketId            String
  selectionId         Long
  handicap            Double
  priceSize           PriceSize
  bspLiability        Double
  side                Side
  status              OrderStatus
  persistenceType     PersistenceType
  orderType           OrderType
  placedDate          Date
  matchedDate         Date
  averagePriceMatched Double
  sizeMatched         Double
  sizeRemaining       Double
  sizeLapsed          Double
  sizeCancelled       Double
  sizeVoided          Double
  regulatorAuthCode   String
  regulatorCode       String

=head3 DeveloperApp

  appName           String
  appId             Long
  appVersions       Array of DeveloperAppVersion

=head3 DeveloperAppVersion

  owner                       String
  versionId                   Long
  version                     String
  applicationKey              String
  delayData                   Boolean
  subscriptionRequired        Boolean
  ownerManaged                Boolean
  active                      Boolean

=head3 Event

  id                String
  name              String
  countryCode       String
  timezone          String
  venue             String
  openDate          Date

=head3 EventResult

  event             Event
  marketCount       Integer

=head3 EventType

  id                String
  name              String

=head3 EventTypeResult

  eventType         EventType
  marketCount       Integer

=head3 ExBestOffersOverrides

  bestPricesDepth             Integer       OPT
  rollupModel                 RollupModel   OPT
  rollupLimit                 Integer       OPT
  rollupLiabilityThreshold    Double        OPT
  rollupLiabilityFactor       Integer       OPT

=cut

  $type_defs->{ExBestOffersOverrides}  = {
     	       type     => 'HASH',
               required => [qw//],
	       allowed  => [qw/bestPricesDepth rollupModel rollupLimit
			       rollupLiabilityThreshold rollupLiabilityFactor/],
					 };
  $type_defs->{bestPricesDepth}           = $integer;
  $type_defs->{rollupLimit}               = $integer;
  $type_defs->{rollupLiabilityThreshold}  = $double;
  $type_defs->{rollupLiabilityFactor}     = $integer;
  $type_defs->{exBestOffersOverrides}     = $type_defs->{ExBestOffersOverrides};

=head3 ExchangePrices

  availableToBack             Array of PriceSize
  availableToLay              Array of PriceSize
  tradedVolume                Array of PriceSize

=head3 ExecutionReportErrorCode

Enumeration

  ERROR_IN_MATCHER            The matcher is not healthy.
  PROCESSED_WITH_ERRORS       The order itself has been accepted, but at least one action has generated errors.
  BET_ACTION_ERROR            There is an error with an action that has caused the entire order to be rejected.
  INVALID_ACCOUNT_STATE       Order rejected due to the account's status (suspended, inactive, dup cards).
  INVALID_WALLET_STATUS       Order rejected due to the account's wallet's status.
  INSUFFICIENT_FUNDS          Account has exceeded its exposure limit or available to bet limit.
  LOSS_LIMIT_EXCEEDED         The account has exceed the self imposed loss limit.
  MARKET_SUSPENDED            Market is suspended.
  MARKET_NOT_OPEN_FOR_BETTING Market is not open for betting. It is either not yet active, suspended or closed.
  DUPLICATE_TRANSACTION       duplicate customer reference data submitted.
  INVALID_ORDER               Order cannot be accepted by the matcher due to the combination of actions.
  INVALID_MARKET_ID           Market doesn't exist.
  PERMISSION_DENIED           Business rules do not allow order to be placed.
  DUPLICATE_BETIDS            duplicate bet ids found.
  NO_ACTION_REQUIRED          Order hasn't been passed to matcher as system detected there will be no change.
  SERVICE_UNAVAILABLE         The requested service is unavailable.
  REJECTED_BY_REGULATOR       The regulator rejected the order.

=head3 ExecutionReportStatus

Enumeration

  SUCCESS               Order processed successfully.
  FAILURE               Order failed.
  PROCESSED_WITH_ERRORS The order itself has been accepted, but at least one action has generated errors.
  TIMEOUT               Order timed out.

=head3 GroupBy

Enumeration

  EVENT_TYPE A roll up on a specified event type.
  EVENT      A roll up on a specified event.
  MARKET     A roll up on a specified market.
  SIDE       An averaged roll up on the specified side of a specified selection.
  BET        The P&L, commission paid, side and regulatory information etc, about each individual bet order

=cut

  $type_defs->{GroupBy}  = {
			    type     => 'ENUM',
			    allowed  => [qw/EVENT_TYPE EVENT MARKET SIDE BET/],
			   };
  $type_defs->{groupBy}  = $type_defs->{GroupBy};

=head3 IncludeItem

Enumeration

  ALL                         Include all items.
  DEPOSITS_WITHDRAWALS        Include payments only.
  EXCHANGE                    Include exchange bets only.
  POKER_ROOM                  include poker transactions only.

=cut

  $type_defs->{IncludeItem}  = {
		    type     => 'ENUM',
		    allowed  => [qw/ALL DEPOSITS_WITHDRAWALS EXCHANGE POKER_ROOM/],
			       };
  $type_defs->{includeItem}  = $type_defs->{IncludeItem};

=head3 InstructionReportErrorCode

Enumeration

  INVALID_BET_SIZE                Bet size is invalid for your currency or your regulator.
  INVALID_RUNNER                  Runner does not exist, includes vacant traps in greyhound racing.
  BET_TAKEN_OR_LAPSED             Bet cannot be cancelled or modified as it has already been taken or has lapsed.
  BET_IN_PROGRESS                 No result was received from the matcher in a timeout configured for the system.
  RUNNER_REMOVED                  Runner has been removed from the event.
  MARKET_NOT_OPEN_FOR_BETTING     Attempt to edit a bet on a market that has closed.
  LOSS_LIMIT_EXCEEDED             The action has caused the account to exceed the self imposed loss limit.
  MARKET_NOT_OPEN_FOR_BSP_BETTING Market now closed to bsp betting. Turned in-play or has been reconciled.
  INVALID_PRICE_EDIT              Attempt to edit down a bsp limit on close lay bet, or edit up a back bet.
  INVALID_ODDS                    Odds not on price ladder - either edit or placement.
  INSUFFICIENT_FUNDS              Insufficient funds available to cover the bet action.
  INVALID_PERSISTENCE_TYPE        Invalid persistence type for this market.
  ERROR_IN_MATCHER                A problem with the matcher prevented this action completing successfully
  INVALID_BACK_LAY_COMBINATION    The order contains a back and a lay for the same runner at overlapping prices.
  ERROR_IN_ORDER                  The action failed because the parent order failed.
  INVALID_BID_TYPE                Bid type is mandatory.
  INVALID_BET_ID                  Bet for id supplied has not been found.
  CANCELLED_NOT_PLACED            Bet cancelled but replacement bet was not placed.
  RELATED_ACTION_FAILED           Action failed due to the failure of a action on which this action is dependent.
  NO_ACTION_REQUIRED              The action does not result in any state change.

=head3 InstructionReportStatus

Enumeration

  SUCCESS     Action succeeded.
  FAILURE     Action failed.
  TIMEOUT     Action Timed out.

=head3 ItemClass

Enumeration

  UNKNOWN     Statement item not mapped to a specific class.

=head3 ItemDescription

  eventTypeDesc     String
  eventDesc         String
  marketDesc        String
  marketStartTime   Date
  runnerDesc        String
  numberOfWinners   Integer
  marketType        String
  eachWayDivisor    Double

=head3 LimitOnCloseOrder

  liability         Double              REQ
  price             Double              REQ

=cut

  $type_defs->{LimitOnCloseOrder}  = {
     	       type     => 'HASH',
               required => [qw/liability price/],
	       allowed  => [qw//],
				     };
  $type_defs->{liability}  = $double;
  $type_defs->{price}      = $double;
  $type_defs->{limitOnCloseOrder}  = $type_defs->{LimitOnCloseOrder};

=head3 LimitOrder

  size              Double              REQ/OPT*
  price             Double              REQ
  persistenceType   PersistenceType     REQ
  timeInForce       TimeInForce         OPT
  minFillSize       Double              OPT
  betTargetType     BetTargetType       OPT/REQ*
  betTargetSize     Double              OPT/REQ*

  * Must specify EITHER size OR target type and target size

=cut

  $type_defs->{LimitOrder}  = {
     	       type     => 'HASH',
               required => [qw/price persistenceType/],
	       allowed  => [qw/size timeInForce minFillSize betTargetType betTargetSize/],
			      };
  $type_defs->{size}          = $double;
  $type_defs->{minFillSize}   = $double;
  $type_defs->{betTargetSize} = $double;
  $type_defs->{limitOrder}    = $type_defs->{LimitOrder};

=head3 MarketBettingType

Enumeration

  ODDS                        Odds Market.
  LINE                        Line Market.
  RANGE                       Range Market.
  ASIAN_HANDICAP_DOUBLE_LINE  Asian Handicap Market.
  ASIAN_HANDICAP_SINGLE_LINE  Asian Single Line Market.
  FIXED_ODDS                  Sportsbook Odds Market.

=cut

  $type_defs->{MarketBettingType}  = {
	       type     => 'ENUM',
	       allowed  => [qw/ODDS LINE RANGE ASIAN_HANDICAP_DOUBLE_LINE
                               ASIAN_HANDICAP_SINGLE_LINE FIXED_ODDS/],
				     };

=head3 MarketBook

  marketId              String
  isMarketDataDelayed   Boolean
  status                MarketStatus
  betDelay              Integer
  bspReconciled         Boolean
  complete              Boolean
  inplay                Boolean
  numberOfWinners       Integer
  numberOfRunners       Integer
  numberOfActiveRunners Integer
  lastMatchTime         Date
  totalMatched          Double
  totalAvailable        Double
  crossMatching         Boolean
  runnersVoidable       Boolean
  version               Long
  runners               Array of Runner

=head3 MarketCatalogue

  marketId          String
  marketName        String
  marketStartTime   Date
  description       MarketDescription
  totalMatched      Double
  runners           Array of RunnerCatalog
  eventType         EventType
  competition       Competition
  event             Event

=head3 MarketDescription

  persistenceEnabled Boolean
  bspMarket          Boolean
  marketTime         Date
  suspendTime        Date
  settleTime         Date
  bettingType        MarketBettingType
  turnInPlayEnabled  Boolean
  marketType         String
  regulator          String
  marketBaseRate     Double
  discountAllowed    Boolean
  wallet             String
  rules              String
  rulesHasDate       Boolean
  eachWayDivisor     Double
  clarifications     String

=head3 MarketFilter

  textQuery          String                       OPT
  exchangeIds        Array of String              OPT
  eventTypeIds       Array of String              OPT
  eventIds           Array of String              OPT
  competitionIds     Array of String              OPT
  marketIds          Array of String              OPT
  venues             Array of String              OPT
  bspOnly            Boolean                      OPT
  turnInPlayEnabled  Boolean                      OPT
  inPlayOnly         Boolean                      OPT
  marketBettingTypes Array of MarketBettingType   OPT
  marketCountries    Array of String              OPT
  marketTypeCodes    Array of String              OPT
  marketStartTime    TimeRange                    OPT
  withOrders         Array of OrderStatus         OPT

=cut

  $type_defs->{MarketFilter}  = {
     	       type     => 'HASH',
               required => [qw//],
	       allowed  => [qw/textQuery exchangeIds eventTypeIds eventIds
			       competitionIds marketIds venues bspOnly
			       turnInPlayEnabled inPlayOnly marketBettingTypes
			       marketCountries marketTypeCodes marketStartTime
			       withOrders/],
				};
  $type_defs->{filter}  =  $type_defs->{MarketFilter};

=head3 MarketOnCloseOrder

  liability          Double              REQ

=cut

  $type_defs->{MarketOnCloseOrder}  = {
     	       type     => 'HASH',
               required => [qw/liability/],
	       allowed  => [qw//],
				      };
  $type_defs->{marketOnCloseOrder}  = $type_defs->{MarketOnCloseOrder};

=head3 MarketProfitAndLoss

  marketId           String
  commissionApplied  Double
  profitAndLosses    Array of RunnerProfitAndLoss

=head3 MarketProjection

Enumeration

  COMPETITION        If not selected then the competition will not be returned with marketCatalogue.
  EVENT              If not selected then the event will not be returned with marketCatalogue.
  EVENT_TYPE         If not selected then the eventType will not be returned with marketCatalogue.
  MARKET_START_TIME  If not selected then the start time will not be returned with marketCatalogue.
  MARKET_DESCRIPTION If not selected then the description will not be returned with marketCatalogue.
  RUNNER_DESCRIPTION If not selected then the runners will not be returned with marketCatalogue.
  RUNNER_METADATA    If not selected then the runner metadata will not be returned with marketCatalogue.

=cut

  $type_defs->{MarketProjection}  = {
	       type     => 'ENUM',
	       allowed  => [qw/COMPETITION EVENT EVENT_TYPE MARKET_START_TIME
			       MARKET_DESCRIPTION RUNNER_DESCRIPTION RUNNER_METADATA/],
				    };

=head3 MarketSort

Enumeration

  MINIMUM_TRADED     Minimum traded volume
  MAXIMUM_TRADED     Maximum traded volume
  MINIMUM_AVAILABLE  Minimum available to match
  MAXIMUM_AVAILABLE  Maximum available to match
  FIRST_TO_START     The closest markets based on their expected start time
  LAST_TO_START      The most distant markets based on their expected start time

=cut

  $type_defs->{MarketSort}  = {
	       type     => 'ENUM',
	       allowed  => [qw/MINIMUM_TRADED MAXIMUM_TRADED MINIMUM_AVAILABLE
			       MAXIMUM_AVAILABLE FIRST_TO_START LAST_TO_START/],
			      };
  $type_defs->{sort}  = $type_defs->{MarketSort};

=head3 MarketStatus

Enumeration

  INACTIVE           Inactive Market
  OPEN               Open Market
  SUSPENDED          Suspended Market
  CLOSED             Closed Market

=cut

  $type_defs->{MarketStatus}  = {
	       type     => 'ENUM',
	       allowed  => [qw/INACTIVE OPEN SUSPENDED CLOSED/],
				};

=head3 MarketTypeResult

  marketType        String
  marketCount       Integer

=head3 MarketVersion

  version           Long                REQ

=cut

  $type_defs->{MarketVersion}  = {
				  type     => 'HASH',
				  required => [qw/version/],
				  allowed  => [qw//],
				 };
  $type_defs->{marketVersion}  = $type_defs->{MarketVersion};

=head3 Match

  betId             String
  matchId           String
  side              Side
  price             Double
  size              Double
  matchDate         Date

=head3 MatchProjection

Enumeration

  NO_ROLLUP              No rollup, return raw fragments.
  ROLLED_UP_BY_PRICE     Rollup matched amounts by distinct matched prices per side.
  ROLLED_UP_BY_AVG_PRICE Rollup matched amounts by average matched price per side.

=cut

  $type_defs->{MatchProjection}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/NO_ROLLUP ROLLED_UP_BY_PRICE ROLLED_UP_BY_AVG_PRICE/],
				   };
  $type_defs->{matchProjection}  = $type_defs->{MatchProjection};

=head3 Order

  betId             String
  orderType         OrderType
  status            OrderStatus
  persistenceType   PersistenceType
  side              Side
  price             Double
  size              Double
  bspLiability      Double
  placedDate        Date
  avgPriceMatched   Double
  sizeMatched       Double
  sizeRemaining     Double
  sizeLapsed        Double
  sizeCancelled     Double
  sizeVoided        Double

=head3 OrderBy

Enumeration

  BY_BET          Deprecated Use BY_PLACE_TIME instead. Order by placed time, then bet id.
  BY_MARKET       Order by market id, then placed time, then bet id.
  BY_MATCH_TIME   Order by time of last matched fragment (if any), then placed time, then bet id.
  BY_PLACE_TIME   Order by placed time, then bet id. This is an alias of to be deprecated BY_BET.
  BY_SETTLED_TIME Order by time of last settled fragment, last match time, placed time, bet id.
  BY_VOID_TIME    Order by time of last voided fragment, last match time, placed time, bet id.

=cut

  $type_defs->{OrderBy}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/BY_BET BY_MARKET BY_MATCH_TIME BY_PLACE_TIME
			       BY_SETTLED_TIME BY_VOID_TIME/],
			   };
  $type_defs->{orderBy} = $type_defs->{OrderBy};

=head3 OrderProjection

Enumeration

  ALL                EXECUTABLE and EXECUTION_COMPLETE orders.
  EXECUTABLE         An order that has a remaining unmatched portion.
  EXECUTION_COMPLETE An order that does not have any remaining unmatched portion.

=cut

  $type_defs->{OrderProjection}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/ALL EXECUTABLE EXECUTION_COMPLETE/],
				   };
  $type_defs->{orderProjection} = $type_defs->{OrderProjection};

=head3 OrderStatus

Enumeration

  PENDING            An asynchronous order is yet to be processed. NOT A VALID SEARCH CRITERIA.
  EXECUTION_COMPLETE An order that does not have any remaining unmatched portion.
  EXECUTABLE         An order that has a remaining unmatched portion.
  EXPIRED            Unfilled FILL_OR_KILL order. NOT A VALID SEARCH CRITERIA.

=cut

  $type_defs->{OrderStatus}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/EXECUTION_COMPLETE EXECUTABLE/],
			       };

=head3 OrderType

Enumeration

  LIMIT             A normal exchange limit order for immediate execution.
  LIMIT_ON_CLOSE    Limit order for the auction (SP).
  MARKET_ON_CLOSE   Market order for the auction (SP).

=cut

  $type_defs->{OrderType}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/LIMIT LIMIT_ON_CLOSE MARKET_ON_CLOSE/],
			     };
  $type_defs->{orderType}  = $type_defs->{OrderType};

=head3 PersistenceType

Enumeration

  LAPSE           Lapse the order when the market is turned in-play.
  PERSIST         Persist the order to in-play.
  MARKET_ON_CLOSE Put the order into the auction (SP) at turn-in-play.

=cut

  $type_defs->{PersistenceType}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/LAPSE PERSIST MARKET_ON_CLOSE/],
				   };
  $type_defs->{persistenceType}     = $type_defs->{PersistenceType};
  $type_defs->{newPersistenceType}  = $type_defs->{PersistenceType};

=head3 PlaceInstruction

  orderType          OrderType            RQD
  selectionId        Long                 RQD
  handicap           Double               OPT
  side               Side                 RQD
  limitOrder         LimitOrder           OPT/RQD \
  limitOnCloseOrder  LimitOnCloseOrder    OPT/RQD  > Depending on OrderType
  marketOnCloseOrder MarketOnCloseOrder   OPT/RQD /

=cut

  $type_defs->{PlaceInstruction}  = {
     	       type     => 'HASH',
               required => [qw/orderType selectionId side/],
	       allowed  => [qw/handicap limitOrder limitOnCloseOrder
                               marketOnCloseOrder customerOrderRef/],
				    };
  $type_defs->{selectionId}  = $type_defs->{runnerId};
  $type_defs->{handicap}     = $double;

=head3 PlaceInstructionReport

  status              InstructionReportStatus
  errorCode           InstructionReportErrorCode
  instruction         PlaceInstruction
  betId               String
  placedDate          Date
  averagePriceMatched Double
  sizeMatched         Double

=head3 PriceData

Enumeration

  SP_AVAILABLE      Amount available for the BSP auction.
  SP_TRADED         Amount traded in the BSP auction.
  EX_BEST_OFFERS    Only the best prices available for each runner, to requested price depth.
  EX_ALL_OFFERS     EX_ALL_OFFERS trumps EX_BEST_OFFERS if both settings are present.
  EX_TRADED         Amount traded on the exchange.

=cut

  $type_defs->{PriceData}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/SP_AVAILABLE SP_TRADED EX_BEST_OFFERS EX_ALL_OFFERS
			       EX_TRADED/],
			     };

=head3 PriceProjection

  priceData             Array of PriceData        OPT
  exBestOffersOverrides ExBestOffersOverrides     OPT
  virtualise            Boolean                   OPT
  rolloverStakes        Boolean                   OPT

=cut

  $type_defs->{PriceProjection}  = {
     	       type     => 'HASH',
               required => [qw//],
	       allowed  => [qw/priceData exBestOffersOverrides virtualise rolloverStakes/],
				   };
  $type_defs->{priceData}        = {
				    type     => 'ARRAY',
				    array_of => 'PriceData',
				   };
  $type_defs->{virtualise}       = $boolean;
  $type_defs->{rolloverStakes}   = $boolean;
  $type_defs->{priceProjection}  = $type_defs->{PriceProjection};

=head3 PriceSize

  price             Double
  size              Double

=head3 ReplaceInstruction

  betId             String              RQD
  newPrice          Double              RQD

=cut

  $type_defs->{ReplaceInstruction}  = {
     	       type     => 'HASH',
               required => [qw/betId newPrice/],
	       allowed  => [qw//],
			  };
  $type_defs->{newPrice} = $double;

=head3 RaceDetails

  meetingId         String
  raceId            String
  raceStatus        RaceStatus
  lastUpdated       Date
  responseCode      ResponseCode

=head3 RaceStatus

Enumeration

  DORMANT           There is no data available for this race
  DELAYED           The start of the race has been delayed
  PARADING          The horses are in the parade ring
  GOINGDOWN         The horses are going down to the starting post
  GOINGBEHIND       The horses are going behind the stalls
  ATTHEPOST         The horses are at the post
  UNDERORDERS       The horses are loaded into the stalls/race is about to start
  OFF               The race has started
  FINISHED          The race has finished
  FALSESTART        There has been a false start
  PHOTOGRAPH        The result of the race is subject to a photo finish
  RESULT            The result of the race has been announced
  WEIGHEDIN         The jockeys have weighed in
  RACEVOID          The race has been declared void
  ABANDONED         The meeting has been cancelled
  APPROACHING       The greyhounds are approaching the traps
  GOINGINTRAPS      The greyhounds are being put in the traps
  HARERUNNING       The hare has been started
  FINALRESULT       The result cannot be changed for betting purposes.
  NORACE            The race has been declared a no race
  RERUN             The race will be rerun

=head3 ReplaceInstructionReport

  status                  InstructionReportStatus
  errorCode               InstructionReportErrorCode
  cancelInstructionReport CancelInstructionReport
  placeInstructionReport  PlaceInstructionReport

=head3 ResponseCode

Enumeration

  OK                                  Data returned successfully
  NO_NEW_UPDATES                      No updates since the passes UpdateSequence
  NO_LIVE_DATA_AVAILABLE              Event scores are no longer available
  SERVICE_UNAVAILABLE                 Data feed for the event type is currently unavailable
  UNEXPECTED_ERROR                    An unexpected error occurred retrieving score data
  LIVE_DATA_TEMPORARILY_UNAVAILABLE   Live Data feed is temporarily unavailable

=head3 RollupModel

Enumeration

  STAKE             The volumes will be rolled up to the minimum value which is >= rollupLimit.
  PAYOUT            The volumes will be rolled up to the minimum value where the payout( price * volume ) is >= rollupLimit.
  MANAGED_LIABILITY The volumes will be rolled up to the minimum value which is >= rollupLimit, until a lay price threshold.
  NONE              No rollup will be applied.

=cut

  $type_defs->{RollupModel}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/STAKE PAYOUT MANAGED_LIABILITY NONE/],
			       };
  $type_defs->{rollupModel}  = $type_defs->{RollupModel};

=head3 Runner

  selectionId       Long
  handicap          Double
  status            RunnerStatus
  adjustmentFactor  Double
  lastPriceTraded   Double
  totalMatched      Double
  removalDate       Date
  sp                StartingPrices
  ex                ExchangePrices
  orders            Array of Order
  matches           Array of Match

=head3 RunnerCatalog

  selectionId       Long
  runnerName        String
  handicap          Double
  sortPriority      Integer
  metadata          Hash of Metadata


=head3 RunnerProfitAndLoss

  selectionId       Long
  ifWin             Double
  ifLose            Double

=head3 RunnerStatus

Enumeration

  ACTIVE            Active in a live market.
  WINNER            Winner in a settled market.
  LOSER             Loser in a settled market.
  PLACED            The runner was placed, applies to EACH_WAY marketTypes only.
  REMOVED_VACANT    Vacant (e.g. Trap in a dog race).
  REMOVED           Removed from the market.
  HIDDEN            Hidden from the market.

=cut

  $type_defs->{RunnerStatus}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/ACTIVE WINNER LOSER PLACED REMOVED_VACANT REMOVED HIDDEN/],
				};

=head3 Side

Enumeration

  BACK  To bet on the selection to win.
  LAY   To bet on the selection to lose.

=cut

  $type_defs->{Side}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/BACK LAY/],
			};
  $type_defs->{side}  = $type_defs->{Side};

=head3 SortDir

Enumeration

  EARLIEST_TO_LATEST          Order from earliest value to latest.
  LATEST_TO_EARLIEST          Order from latest value to earliest.

=cut

  $type_defs->{SortDir}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/EARLIEST_TO_LATEST LATEST_TO_EARLIEST/],
			   };
  $type_defs->{sortDir} = $type_defs->{SortDir};

=head3 StartingPrices

  nearPrice                   Double
  farPrice                    Double
  backStakeTaken              Array of PriceSize
  layLiabilityTaken           Array of PriceSize
  actualSP                    Double

=head3 StatementItem

  refId             String
  itemDate          Date
  amount            Double
  balance           Double
  itemClass         ItemClass
  itemClassData     Hash of ItemClassData
  legacyData        StatementLegacyData

=head3 StatementLegacyData

  avgPrice                    Double
  betSize                     Double
  betType                     String
  betCategoryType             String
  commissionRate              String
  eventId                     Long
  eventTypeId                 Long
  fullMarketName              String
  grossBetAmount              Double
  marketName                  String
  marketType                  String
  placedDate                  Date
  selectionId                 Long
  selectionName               String
  startDate                   Date
  transactionType             String
  transactionId               Long
  winLose                     String

=head3 TimeGranularity

Enumeration

  DAYS              Days.
  HOURS             Hours.
  MINUTES           Minutes.

=cut

  $type_defs->{TimeGranularity}  = {
     	       type     => 'ENUM',
	       allowed  => [qw/DAYS HOURS MINUTES/],
				   };
  $type_defs->{granularity}  = $type_defs->{TimeGranularity};

=head3 TimeInForce

Enumeration

  FILL_OR_KILL Execute the transaction immediately  or not at all.

=cut

  $type_defs->{TimeInForce}  = {
				type     => 'ENUM',
				allowed  => [qw/FILL_OR_KILL/],
			       };
  $type_defs->{timeInForce}  = $type_defs->{TimeInForce};

=head3 TimeRange

  from              Date      OPT
  to                Date      OPT

=cut

  $type_defs->{TimeRange}  = {
     	       type     => 'HASH',
               required => [qw//],
	       allowed  => [qw/from to/],
			     };
  $type_defs->{dateRange}        = $type_defs->{TimeRange};
  $type_defs->{settledDateRange} = $type_defs->{TimeRange};
  $type_defs->{itemDateRange}    = $type_defs->{TimeRange};
  $type_defs->{marketStartTime}  = $type_defs->{TimeRange};

=head3 TimeRangeResult

  timeRange         TimeRange
  marketCount       Integer

=head3 UpdateInstruction

  betId              String             RQD
  newPersistenceType PersistenceType    RQD

=cut

  $type_defs->{UpdateInstruction}  = {
     	       type     => 'HASH',
	       required => [qw/betId newPersistenceType/],
	       allowed  => [qw//],
				     };

=head3 UpdateInstructionReport

  status            InstructionReportStatus
  errorCode         InstructionReportErrorCode
  instruction       UpdateInstruction

=head3 Wallet

Enumeration

  UK                UK Exchange wallet.
  AUSTRALIAN        Australian Exchange wallet. DEPRECATED

=cut

  $type_defs->{Wallet}  = {
			   type     => 'ENUM',
			   allowed  => [qw/UK AUSTRALIAN/],
			  };
  $type_defs->{wallet}      = $type_defs->{Wallet};
  $type_defs->{fromWallet}  = $type_defs->{Wallet};
  $type_defs->{toWallet}    = $type_defs->{Wallet};

# A Dirty Hack datatype, because 'instructions' is ambiguous, and could refer
# to place-, cancel-, replace- or updateOrders methods. God I hate Betfair.
  $type_defs->{Instruction}  = {
     	       type     => 'HASH',
	       required => [qw//],
	       allowed  => [qw/orderType selectionId side handicap limitOrder
                               limitOnCloseOrder marketOnCloseOrder betId sizeReduction
                               newPrice newPersistenceType/],
			       };



  return $type_defs;
}


1;

=head1 THREADS

Because the betfair object maintains a persistent encrypted connection to the Betfair
servers, it should NOT be considered 100% thread-safe. In particular, using the same $bf
object to make API calls across different threads will usually result in disaster.
In practice, there are at least two ways to solve this problem and use WWW::BetfairNG
safely in threaded applications:-

=head2 'Postbox' Thread

If simultaneous or overlapping calls to betfair are not required, one solution is to make
all calls from a single, dedicated thread. This thread can wait on a queue created by
Thread::Queue for requests from other threads, and return the result to them, again
via a queue. Only one $bf object is required in this scenario, which may be created by
the 'postbox' thread itself or, less robustly, by the parent thread before the 'postbox'
is spawned. In the latter case, no other thread (including the parent) should use the $bf
object once the 'postbox' has started using it.

=head2 Multiple Objects

If you need to make simultaneous or overlapping calls to betfair, you can create a new $bf
object in each thread that makes betfair calls. As betfair sessions are identified by a
simple scalar session token, a single login will create a session which CAN be safely
shared across threads:-

  use WWW::BetfairNG;
  use threads;
  use threads::shared;

  my $parent_bf = WWW::BetfairNG->new({
                                       ssl_cert => '<path to ssl certificate file>',
                                       ssl_key  => '<path to ssl key file>',
                                       app_key  => '<application key value>',
                                       });
  $parent_bf->login({username => <username>, password => <password>})
    or die;
  my $session :shared = $parent_bf->session();

  my $child = threads->create(sub {
    # Create a new bf object in the child - no need for ssl cert and key
    my $child_bf = WWW::BetfairNG->new({app_key  => '<application key value>'});
    # Assign the shared session token - $child_bf will then be logged in
    $child_bf->session($session);

        # Make any required API calls in the child using $child_bf
  });

  # Freely make API calls using $parent_bf

  $child->join;
  $parent_bf->logout; # Logs out any children using the same session token
  exit 0;

In particular, keepAlive calls only need to be made in one thread to affect all threads
using the same session token, and logging out in any thread will log out all threads
using the same session token.

=head1 SEE ALSO

The Betfair Developer's Website L<https://developer.betfair.com/>
In particular, the Exchange API Documentation and the Forum.

=head1 AUTHOR

Myrddin Wyllt, E<lt>myrddinwyllt@tiscali.co.ukE<gt>

=head1 ACKNOWLEDGEMENTS

Main inspiration for this was David Farrell's WWW::betfair module,
which was written for the v6 SOAP interface. Thanks also to Carl
O'Rourke for suggestions on clarifying error messages, Colin
Magee for the suggestion to extend the timeout period for the
navigationMenu call and David Halstead for spotting a bug in the
selectionId parameter check.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Myrddin Wyllt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
