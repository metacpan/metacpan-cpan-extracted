use strictures;
use 5.14.0;

package WebService::GoogleAPI::Client;

our $VERSION = '0.24';    # VERSION

use Data::Dump qw/pp/;
use Moo;
use WebService::GoogleAPI::Client::UserAgent;
use WebService::GoogleAPI::Client::Discovery;
use WebService::GoogleAPI::Client::AuthStorage::GapiJSON;
use WebService::GoogleAPI::Client::AuthStorage::ServiceAccount;
use Carp;
use CHI;
use Mojo::Util;

#TODO- batch requests. The only thing necessary is to send  a
#multipart request as I wrote in that e-mail.
#
#TODO- implement auth for service accounts.
#
#TODO- allow using promises instead of just calling. Also allow
#      for full access to the tx instead of assuming it's always
#      returning the res. Perhaps mix in something that delegates the
#      json method to the res?

# ABSTRACT: Google API Discovery and SDK

#   FROM MCE POD -- <p><img src="https://img.shields.io/cpan/v/WebService-GoogleAPI-Client.png" width="664" height="446" alt="Bank Queuing Model" /></p>


has 'debug' => (is => 'rw', default => 0, lazy => 1);
has 'ua'    => (
  handles => [qw/do_autorefresh auth_storage get_access_token scopes user/],
  is      => 'ro',
  default =>
    sub { WebService::GoogleAPI::Client::UserAgent->new(debug => shift->debug) }
  ,
  lazy => 1,
);

sub get_scopes_as_array {
  carp 'get_scopes_as_array has deprecated in favor of the shorter "scopes"';
  return $_[0]->scopes;
}

has 'chi' => (
  is      => 'rw',
  default => sub {
    CHI->new(driver => 'File', max_key_length => 512, namespace => __PACKAGE__);
  },
  lazy => 1
);

has 'discovery' => (
  handles => [
    qw/  discover_all
      get_method_details
      get_api_document service_exists
      methods_available_for_google_api_id list_api_ids  /
  ],
  is      => 'ro',
  default => sub {
    my $self = shift;
    return WebService::GoogleAPI::Client::Discovery->new(
      debug => $self->debug,
      ua    => $self->ua,
      chi   => $self->chi
    );
  },
  lazy => 1,
);

## provides a way of augmenting constructor (new) without overloading it
##  see https://metacpan.org/pod/distribution/Moose/lib/Moose/Manual/Construction.pod if like me you an new to Moose


#NOTE- in terms of implementing google's ADC
# (see https://cloud.google.com/docs/authentication/production and also
#  https://github.com/googleapis/python-cloud-core/blob/master/google/cloud/client.py)
# I looked into it and based on that, it seems that every environment has different reqs,
#  so it's a maintenance liability
sub BUILD {
  my ($self, $params) = @_;

  my ($storage, $file);
  if ($params->{auth_storage}) {
    $storage = $params->{auth_storage};
  } elsif ($file = $params->{gapi_json}) {
    $storage =
      WebService::GoogleAPI::Client::AuthStorage::GapiJSON->new(path => $file);
  } elsif ($file = $params->{service_account}) {
    $storage = WebService::GoogleAPI::Client::AuthStorage::ServiceAccount->new(
      path   => $file,
      scopes => $params->{scopes}
    );
  } elsif ($file = $ENV{GOOGLE_APPLICATION_CREDENTIALS}) {
    $storage = WebService::GoogleAPI::Client::AuthStorage::ServiceAccount->new(
      path   => $file,
      scopes => $params->{scopes}
    );
  }
  $self->auth_storage($storage) if $storage;

  $self->user($params->{user}) if (defined $params->{user});
}


## ASSUMPTIONS:
##   - no complex parameter checking ( eg required mediaUpload in endpoint gmail.users.messages.send ) so user assumes responsiiblity
## TODO: Exceeding a rate limit will cause an HTTP 403 or HTTP 429 Too Many Requests response and your app should respond by retrying with exponential backoff. (https://developers.google.com/gmail/api/v1/reference/quota)
##  follows the method spec reqeust reference to the api spec schema api_discovery_struct->{schemas}{Message};
##  THE METHOD SPEC CONTAINS
##          'request' => {
##                       '$ref' => 'Message'
##                     },
##  THE SCHEMA api_discovery_struct->{schemas}{Message} CONTAINS
##    'id' => 'Message',
##    'properties' => {
##       'raw' => {
##           {annotations}{required}[ 'gmail.users.drafts.create','gmail.users.drafts.update','gmail.users.messages.insert','gmail.users.messages.send' ]

## NB - uses the ua api_query to execute the server request
##################################################
sub api_query {
  my ($self, @params_array) = @_;

  ## TODO - find a more elgant idiom to do this - pulled this off top of head for quick imeplementation
  my $params = {};
  if (scalar(@params_array) == 1 && ref($params_array[0]) eq 'HASH') {
    $params = $params_array[0];
  } else {
    $params = {@params_array};    ## what happens if not even count
  }
  carp(pp $params) if $self->debug > 10;

  croak "Missing neccessary scopes to access $params->{api_endpoint_id}"
    unless $self->has_scope_to_access_api_endpoint($params->{api_endpoint_id});

  ## used to collect pre-query validation errors - if set we return a response
  #  with 418 I'm a teapot
  my @teapot_errors = ();
  ## pre-query validation if api_id parameter is included
  @teapot_errors = $self->_process_params($params)
    if (defined $params->{api_endpoint_id});

  ## either as param or from discovery
  if (not defined $params->{path}) {
    push @teapot_errors, 'path is a required parameter';
    $params->{path} = '';
  }
  push @teapot_errors,
    "Path '$params->{path}' includes unfilled variable after processing"
    if ($params->{path} =~ /\{.+\}/xms);
  ## carp and include in 418 TEAPOT ERROR - response body with @teapot errors
  if (@teapot_errors > 0) {
    carp(join("\n", @teapot_errors)) if $self->debug;
    return Mojo::Message::Response->new(
      content_type => 'text/plain',
      code         => 418,
      message      =>
'Teapot Error - Reqeust blocked before submitting to server with pre-query validation errors',
      body => join("\n", @teapot_errors)
    );
  } else {
    ## query looks good - send to user agent to execute
    return $self->ua->validated_api_query($params);
  }
}
##################################################

##################################################
## _ensure_api_spec_has_defined_fields is really only used to allow carping without undef warnings if needed
sub _ensure_api_spec_has_defined_fields {
  my ($self, $api_discovery_struct) = @_;
  ## Ensure API Discovery has expected fields defined
  foreach my $expected_key (
    qw/path title ownerName version id discoveryVersion
    revision description documentationLink rest/
  ) {
    $api_discovery_struct->{$expected_key} = ''
      unless defined $api_discovery_struct->{$expected_key};
  }
  $api_discovery_struct->{canonicalName} = $api_discovery_struct->{title}
    unless defined $api_discovery_struct->{canonicalName};
  return $api_discovery_struct;
}
##################################################

##################################################
sub _process_params_for_api_endpoint_and_return_errors {
  warn
'_process_params_for_api_endpoint_and_return_errors has been deprecated. Please use _process_params';
  _process_params(@_);
}

sub _process_params {
  ## nb - api_endpoint is a param - param key values are modified through this sub
  my ($self, $params) = @_;

  croak('this should never happen - this method is internal only!')
    unless defined $params->{api_endpoint_id};

  ## $api_discovery_struct requried for service base URL
  my $api_discovery_struct = $self->_ensure_api_spec_has_defined_fields(
    $self->discovery->get_api_document($params->{api_endpoint_id}));
  ## remove trailing '/' from baseUrl
  $api_discovery_struct->{baseUrl} =~ s/\/$//sxmg;

  ## if can get discovery data for google api endpoint then continue to perform
  #  detailed checks
  my $method_discovery_struct =
    $self->get_method_details($params->{api_endpoint_id});

  #save away original path so we can know if it's fiddled with
  #later
  $method_discovery_struct->{origPath} = $method_discovery_struct->{path};

  ## allow optional user callback pre-processing of method_discovery_struct
  $method_discovery_struct =
    &{ $params->{cb_method_discovery_modify} }($method_discovery_struct)
    if (defined $params->{cb_method_discovery_modify}
    && ref($params->{cb_method_discovery_modify}) eq 'CODE');

  my @teapot_errors = ();    ## errors are pushed into this as encountered
  $params->{method} = $method_discovery_struct->{httpMethod} || 'GET'
    if (not defined $params->{method});
  push(@teapot_errors,
"method mismatch - you requested a $params->{method} which conflicts with discovery spec requirement for $method_discovery_struct->{httpMethod}"
  ) if ($params->{method} !~ /^$method_discovery_struct->{httpMethod}$/sxim);

  ## Set default path iff not set by user - NB - will prepend baseUrl later
  $params->{path} = $method_discovery_struct->{path} unless $params->{path};
  push @teapot_errors, 'path is a required parameter' unless $params->{path};

  push @teapot_errors,
    $self->_interpolate_path_parameters_append_query_params_and_return_errors(
    $params, $method_discovery_struct);

  $params->{path} =~ s/^\///sxmg;    ## remove leading '/'  from path
  $params->{path} = "$api_discovery_struct->{baseUrl}/$params->{path}"
    unless $params->{path} =~
    /^$api_discovery_struct->{baseUrl}/ixsmg;    ## prepend baseUrl if required

  ## if errors - add detail available in the discovery struct for the method and service to aid debugging
  push @teapot_errors,
qq{ $api_discovery_struct->{title} $api_discovery_struct->{rest} API into $api_discovery_struct->{ownerName} $api_discovery_struct->{canonicalName} $api_discovery_struct->{version} with id $method_discovery_struct->{id} as described by discovery document version $api_discovery_struct->{discoveryVersion} revision $api_discovery_struct->{revision} with documentation at $api_discovery_struct->{documentationLink} \nDescription: $method_discovery_struct->{description}\n}
    if @teapot_errors;

  return @teapot_errors;
}
##################################################

#small subs to convert between these_types to theseTypes of params
#TODO- should probs move this into a Util module
sub camel { shift if @_ > 1; $_[0] =~ s/ _(\w) /\u$1/grx }
sub snake { shift if @_ > 1; $_[0] =~ s/([[:upper:]])/_\l$1/grx }

##################################################
sub _interpolate_path_parameters_append_query_params_and_return_errors {
  my ($self, $params, $discovery_struct) = @_;
  my @teapot_errors = ();

  my @get_query_params = ();

  #create a hash of whatever the expected params may be
  my %path_params;
  my $param_regex = qr/\{ \+? ([^\}]+) \}/x;
  if ($params->{path} ne $discovery_struct->{origPath}) {

    #check if the path was given as a custom path. If it is, just
    #interpolate things directly, and assume the user is responsible
    %path_params = map { $_ => 'custom' } ($params->{path} =~ /$param_regex/xg);
  } else {

    #label which param names are from the normal path and from the
    #flat path
    %path_params =
      map { $_ => 'plain' } ($discovery_struct->{path} =~ /$param_regex/xg);
    if ($discovery_struct->{flatPath}) {
      %path_params = (
        %path_params,
        map { $_ => 'flat' } ($discovery_struct->{flatPath} =~ /$param_regex/xg)
      );
    }
  }


  #switch the path we're dealing with to the flat path if any of
  #the parameters match the flat path
  $params->{path} = $discovery_struct->{flatPath}
    if grep { $_ eq 'flat' }
    map { $path_params{ camel $_} || () } keys %{ $params->{options} };


  #loop through params given, placing them in the path or query,
  #or leaving them for the request body
  for my $param_name (keys %{ $params->{options} }) {

    #first check if it needs to be interpolated into the path
    if ($path_params{$param_name} || $path_params{ camel $param_name}) {

      #pull out the value from the hash, and remove the key
      my $param_value = delete $params->{options}{$param_name};

      #Camelize the param name if not passed in customly, allowing
      #the user to pass in camelCase or snake_case param names.
      #This implictly allows for a non camelCased param to be left
      #alone in a custom param.
      $param_name = camel $param_name if $path_params{ camel $param_name};

      #first deal with any param that doesn't have a plus, b/c
      #those just get interpolated
      $params->{path} =~ s/\{$param_name\}/$param_value/;

      #if there's a plus in the path spec, we need more work
      if ($params->{path} =~ /\{ \+ $param_name \}/x) {
        my $pattern = $discovery_struct->{parameters}{$param_name}{pattern};

        #if the given param matches google's pattern for the
        #param, just interpolate it straight
        if ($param_value =~ /$pattern/) {
          $params->{path} =~ s/\{\+$param_name\}/$param_value/;
        } else {

          #N.B. perhaps support passing an arrayref or csv for those
          #params such as jobs.projects.jobs.delete which have two
          #dynamic parts. But for now, unnecessary

          #remove the regexy parts of the pattern to interpolate it
          #into the path, assuming the user has provided just the
          #dynamic portion of the param.
          $pattern =~ s/^\^ | \$$//gx;
          my $placeholder = qr/ \[ \^ \/ \] \+ /x;
          $params->{path} =~ s/\{\+$param_name\}/$pattern/x;
          $params->{path} =~ s/$placeholder/$param_value/x;
          push @teapot_errors, "Not enough parameters given for {+$param_name}."
            if $params->{path} =~ /$placeholder/;
        }
      }

      #skip to the next run, so I don't need an else clause later
      next;    #I don't like nested if-elses
    }

    #if it's not in the list of params, then it goes in the
    #request body, and our work here is done
    next unless $discovery_struct->{parameters}{$param_name};

    #it must be a GET type query param, so push the name and value
    #on our param stack and take it off of the options list
    push @get_query_params, $param_name, delete $params->{options}{$param_name};
  }

  #if there are any query params...
  if (@get_query_params) {

    #interpolate and escape the get query params built up in our
    #former for loop
    $params->{path} .= ($params->{path} =~ /\?/) ? '&' : '?';
    $params->{path} .= Mojo::Parameters->new(@get_query_params);
  }

  #interpolate default value for path params if not given. Needed
  #for things like the gmail API, where userID is 'me' by default
  for my $param_name ($params->{path} =~ /$param_regex/g) {
    my $param_value = $discovery_struct->{parameters}{$param_name}{default};
    $params->{path} =~ s/\{$param_name\}/$param_value/ if $param_value;
  }
  push @teapot_errors, "Missing a parameter for {$_}."
    for $params->{path} =~ /$param_regex/g;

  #print pp $params;
  #exit;
  return @teapot_errors;
}
##################################################


sub has_scope_to_access_api_endpoint {
  my ($self, $api_ep) = @_;
  my $method_spec = $self->get_method_details($api_ep);

  if (keys %$method_spec) {
    my $configured_scopes = $self->scopes;    ## get user scopes arrayref
    ## create a hashindex to facilitate quick lookups
    my %configured_scopes_hash = map { (s/\/$//xr, 1) } @$configured_scopes;
    ## NB r switch as per https://www.perlmonks.org/?node_id=613280 to filter
    #out any trailing '/'
    my $granted = 0;
    ## assume permission not granted until we find a matching scope
    my $required_scope_count = 0;
    ## if the final count of scope constraints = 0 then we will assume permission is granted - this has proven necessary for the experimental Google My Business because scopes are not defined in the current discovery data as at 14/10/18
    for my $method_scope (map { s/\/$//xr } @{ $method_spec->{scopes} }) {
      $required_scope_count++;
      $granted = 1 if defined $configured_scopes_hash{$method_scope};
      last         if $granted;
    }
    $granted = 1 if $required_scope_count == 0;
    return $granted;
  } else {
    return 0;
  }

}


#TODO: Consider rename to return_fetched_google_v1_apis_discovery_structure
#
#TODO - handle auth required error and resubmit request with OAUTH headers if response indicates
#       access requires auth ( when exceed free access limits )


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client - Google API Discovery and SDK

=head1 VERSION

version 0.24

=head1 SYNOPSIS

Access Google API Services using an OAUTH2 User Agent.

Includes Discovery, validation, authentication and API Access.

By default assumes gapi.json configuration in working directory with scoped Google project 
credentials and user authorization created by L<goauth>.

    use WebService::GoogleAPI::Client;
    
    my $gapi_client = WebService::GoogleAPI::Client->new( debug => 1, gapi_json => 'gapi.json', user=> 'peter@pscott.com.au' );
    
    say $gapi_client->list_of_available_google_api_ids();

    my @gmail_endpoint_list =      $gapi_client->methods_available_for_google_api_id('gmail')

    if $gapi_agent->has_scope_to_access_api_endpoint( 'gmail.users.settings.sendAs.get' ) {
      say 'User has Access to GMail Method End-Point gmail.users.settings.sendAs.get';
    }

Package includes L<goauth> CLI Script to collect initial end-user authorisation
to scoped services.

Note to intrepid hackers: Any method that isn't documented is considered
private, and subject to change in breaking ways without notice. (Although I'm a
pretty nice guy, and probably will leave a warning or something).

=begin html <a href="https://travis-ci.org/pscott-au//WebService-GoogleAPI-Client"><img alt="Build Status" src="https://api.travis-ci.org/pscott-au/WebService-GoogleAPI-Client.png?branch=master" /></a>
<a href="https://metacpan.org/pod/WebService::GoogleAPI::Client"><img alt="CPAN version" src="https://img.shields.io/cpan/v/WebService-GoogleAPI-Client.png" /></a>

=end html

=head1 EXAMPLES

=head2 AUTOMATIC API REQUEST CONSTRUCTION  - SEND EMAL

    ## using dotted API Endpoint id to invoke helper validation and default value interpolations etc to send email to self
    use Email::Simple;    ## RFC2822 formatted messages
    use MIME::Base64;
    my $my_email_address = 'peter@shotgundriver.com'

    my $raw_email_payload = encode_base64(
      Email::Simple->create(
        header => [
          To      => $my_email_address,
          From    => $my_email_address,
          Subject => "Test email from '$my_email_address' ",
        ],
        body => "This is the body of email to '$my_email_address'",
      )->as_string
    );

    $gapi_client->api_query(
      api_endpoint_id => 'gmail.users.messages.send',
      options         => { raw => $raw_email_payload },
    );

=head2 MANUAL API REQUEST CONSTRUCTION - GET CALENDAR LIST

    ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
    my $res = $gapi_client->api_query(
      method => 'get',
      path => 'https://www.googleapis.com/calendar/users/me/calendarList',
    )->json;

=head1 METHODS

=head2 C<new>

  WebService::GoogleAPI::Client->new(
     user => 'peter@pscott.com.au', gapi_json => '/fullpath/gapi.json' );

=head3 B<General parameters>

=over 4

=item debug

if truthy then diagnostics are send to STDERR - default false. Crank it up to 11
for maximal debug output

=item chi

an instance to a CHI persistent storage case object - if none provided FILE is used

=back

=head3 B<Login Parameters>

You can use either gapi_json, which is the file you get from using the bundled
goauth tool, or service_account which is the json file you can download from
https://console.cloud.google.com/iam-admin/serviceaccounts.

service_account and gapi_json are mutually exclusive, and gapi_json takes precedence.

If nothing is passed, then we check the GOOGLE_APPLICATION_CREDENTIALS env
variable for the location of a service account file. This matches the
functionality of the Google Cloud libraries from other languages (well,
somewhat. I haven't fully implemented ADC yet - see
L<Google's Docs|https://cloud.google.com/docs/authentication/production> for some details. PRs
are welcome!)

If that doesn't exist, then we default to F<gapi.json> in the current directory.

B<Be wary!> This default is subject to change as more storage backends are implemented.
A deprecation warning will be emmitted when this is likely to start happening.

For more advanced usage, you can supply your own auth storage instance, which is
a consumer of the L<WebService::GoogleAPI::Client::AuthStorage> role. See the
POD for that module for more information.

=over 4

=item user

the email address that requests will be made for

=item gapi_json

Location of end user credentials

=item service_account

Location of service account credentials

=item auth_storage

An instance of a class consuming L<WebService::GoogleAPI::Client::AuthStorage>, already
set up for returning access tokens (barring the ua).

=back

If you're using a service account, user represents the user that you're
impersonating. Make sure you have domain-wide delegation set up, or else this
won't work.

=head2 C<api_query>

query Google API with option to validate request before submitting

handles user auth token inclusion in request headers and refreshes token if required and possible

Required params: method, route

Optional params: api_endpoint_id  cb_method_discovery_modify, options

$self->get_access_token must return a valid token

  $gapi->api_query({
      method => 'get',
      path => 'https://www.googleapis.com/calendar/users/me/calendarList',
    });

  $gapi->api_query({
      method => 'post',
      path => 'https://www.googleapis.com/calendar/v3/calendars/'.$calendar_id.'/events',
      options => { key => value }
  }

  ## if provide the Google API Endpoint to inform pre-query validation
  say $gapi_agent->api_query(
      api_endpoint_id => 'gmail.users.messages.send',
      options    => 
          { raw => encode_base64( Email::Simple->create( 
                       header => [To => $user, From => $user, 
                                  Subject =>"Test email from $user",], 
		       body   => "This is the body of email from $user to $user", 
                   )->as_string ), 
          },
      )->to_string; ##

  print  $gapi_agent->api_query(
            api_endpoint_id => 'gmail.users.messages.list', 
            ## auto sets method to GET, and the path to 
	    ## 'https://www.googleapis.com/gmail/v1/users/me/messages'
          )->to_string;

If the pre-query validation fails then a 418 - I'm a Teapot error response is 
returned with the body containing the specific description of the 
errors ( Tea Leaves ;^) ).   

=head3 B<Dealing with inconsistencies>

NB: If you pass a 'path' parameter this takes precendence over the
API Discovery Spec.  Any parameters defined in the path of the
format {VARNAME} will be filled in with values within the
options=>{ VARNAME => 'value '} parameter structure. This is the
simplest way of addressing issues where the API discovery spec is
inaccurate. ( See dev_sheets_example.pl as at 14/11/18 for
illustration ). This particular issue has been since solved, but
you never know where else there are problems with the discovery spec.

Sometimes, Google is slightly inconsistent about how to name the parameters. For example,
error messages sent back to the user tend to have the param names in snake_case, whereas
the discovery document always has them in camelCase. To address this issue, and in
the DWIM spirit of perl, parameters may be passed in camelCase or snake_case. That
means that 

    $gapi_agent->api_query(
        api_endpoint_id => 'gmail.users.messages.list',
        options => { userId => 'foobar' });

and

    $gapi_agent->api_query(
        api_endpoint_id => 'gmail.users.messages.list',
        options => { user_id => 'foobar' });

will produce the same result.

Sometimes a param expects a dynamic part and a static part. The endpoint
jobs.projects.jobs.list, for example, has a param called 'parent' which has a 
format '^projects/[^/]+$'. In cases like this, you can just skip out the constant 
part, making

  $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.list',
    options => { parent => 'sner' } );

and

  $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.list',
    options => { parent => 'projects/sner' } );

the same. How's that for DWIM?

In addition, you can use different names to refer to multi-part
parameters. For example, the endpoint jobs.projects.jobs.delete officially
expects one parameter, 'name'. The description for the param tells you
that you it expects it to contain 'projectsId' and 'jobsId'. For cases like this,

  $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.delete',
    options => {name => 'projects/sner/jobs/bler'} );

and

  $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.delete',
    options => {projectsId => 'sner', jobsId => 'bler'} );

will produce the same result. Note that for now, in this case you can't pass
the official param name without the constant parts. That may change in the
future.

To further fix discrepencies in the Discovery Specification, the
cb_method_discovery_modify callback can be used which must accept
the method specification as a parameter and must return a
(potentially modified) method spec.

eg.

    my $r = $gapi_client->api_query(  
                api_endpoint_id => "sheets:v4.spreadsheets.values.update",  
                options => { 
		   spreadsheetId => '1111111111111111111',
                   valueInputOption => 'RAW',
                   range => 'Sheet1!A1:A2',
                   'values' => [[99],[98]]
                },
                cb_method_discovery_modify => sub { 
                   my  $meth_spec  = shift; 
                   $meth_spec->{parameters}{valueInputOption}{location} = 'path';
                   $meth_spec->{path} .= "?valueInputOption={valueInputOption}";
                   return $meth_spec;
                 }
            );

Again, this specific issue has been fixed.

Returns L<Mojo::Message::Response> object

=head2 C<has_scope_to_access_api_endpoint>

Given an API Endpoint such as 'gmail.users.settings.sendAs.get' returns 1 iff user has scope to access

    say 'User has Access'  if $gapi_agent->has_scope_to_access_api_endpoint( 'gmail.users.settings.sendAs.get' );

Returns 0 if scope to access is not available to the user.

warns and returns 0 on error ( eg user or config not specified etc )

=head1 METHODS DELEGATED TO WebService::GoogleAPI::Client::Discovery

=head2 C<discover_all>

  Return details about all Available Google APIs as provided by Google or in CHI Cache

  On Success: Returns HASHREF containing items key => list of hashes describing each API
  On Failure: Warns and returns empty hashref

    my $client = WebService::GoogleAPI::Client->new; ## has discovery member WebService::GoogleAPI::Client::Discovery

    $d = $client->discover_all();
    $d = $client->discover_all(1); ## NB if include a parameter that evaluates to true such as '1' then the cache is flushed with a new version

    ## OR
    $d = $client->discovery-> discover_all();
    $d = WebService::GoogleAPI::Client::Discovery->discover_all();

    print Dumper $d;

      $VAR1 = {
                'items' => [
                            {
                              'preferred' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                              'id' => 'abusiveexperiencereport:v1',
                              'icons' => {
                                            'x32' => 'https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png',
                                            'x16' => 'https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png'
                                          },
                              'version' => 'v1',
                              'documentationLink' => 'https://developers.google.com/abusive-experience-report/',
                              'kind' => 'discovery#directoryItem',
                              'discoveryRestUrl' => 'https://abusiveexperiencereport.googleapis.com/$discovery/rest?version=v1',
                              'title' => 'Abusive Experience Report API',
                              'name' => 'abusiveexperiencereport',
                              'description' => 'Views Abusive Experience Report data, and gets a list of sites that have a significant number of abusive experiences.'
                            }, ...

    ## NB because the structure isn't indexed on the api name it can be convenient to post-process it
    ## 
    
    my $new_hash = {};
    foreach my $api ( @{ %{$client->discover_all()}{items} } )
    {
        # convert JSON::PP::Boolean to true|false strings
        $api->{preferred}  = "$api->{preferred}" if defined $api->{preferred};
        $api->{preferred}  = $api->{preferred} eq '0' ? 'false' : 'true';

        $new_hash->{ $api->{name} } = $api;
    }
    print dump $new_hash->{gmail};

=head2 C<get_api_document>

returns the cached version if avaiable in CHI otherwise retrieves discovery data via HTTP, stores in CHI cache and returns as
a Perl data structure.

    my $hashref = $self->get_api_document( 'gmail' );
    my $hashref = $self->get_api_document( 'gmail:v3' );

returns the api discovery specification structure ( cached by CHI ) for api id ( eg 'gmail ')

returns the discovery data as a hashref, an empty hashref on certain failing conditions or croaks on critical errors.

=head2 C<methods_available_for_google_api_id>

Returns a hashref keyed on the Google service API Endpoint in dotted format.
The hashed content contains a structure  representing the corresponding 
discovery specification for that method ( API Endpoint ).

    methods_available_for_google_api_id('gmail')

=head2 C<get_method_details>

    $my $api_detail = $gapi->discovery->get_method_details( 'gmail.users.settings' );

returns a hashref representing the discovery specification for the method identified by $tree in dotted API format such as texttospeech.text.synthesize

returns an empty hashref if not found

=head2 C<list_api_ids>

Returns an array list of all the available API's described in the API Discovery Resource
that is either fetched or cached in CHI locally for 30 days.

    my $r = $agent->list_api_ids();
    print "List of API Services ( comma separated): $r\n";

    my @list = $agent->list_api_ids();

To check for just one service id, use C<service_exists> instead.

=head1 FEATURES

=over 1

=item * API Discovery requests cached with CHI ( Default File )

=item * OAUTH app and user credentials (client_id, client_secret, scope, users access_token and refresh_tokens) stored in local file (default name =  gapi.json)

=item * access_token auto-refreshes when expires (if user has refresh_token) saving refreshed token back to json file

=item * helper api_query to streamline request composition without preventing manual construction if preferred.

=item * CLI tool (I<goauth>) with lightweight Mojo HTTP server to simplify OAuth2 configuration, sccoping, authorization and obtaining access_ and refresh_ tokens from users

=back

=head1 AUTHORS

=over 4

=item *

Veesh Goldman <veesh@cpan.org>

=item *

Peter Scott <localshop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
