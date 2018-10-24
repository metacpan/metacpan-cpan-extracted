use strictures;

package WebService::GoogleAPI::Client;
$WebService::GoogleAPI::Client::VERSION = '0.13';

# ABSTRACT: Google API Services Client.


use Data::Dumper;
use Moo;
use WebService::GoogleAPI::Client::UserAgent;
use WebService::GoogleAPI::Client::Discovery;
use Carp;
use CHI;

## TODO: review class structure hierarchy and dependencies and refactor properly - currently fudging critical fixes as we go
has 'debug' => ( is => 'rw', default => 0, lazy => 1 );    ## NB - when udpated change doesn't propogate !
has 'ua' => (
  handles => [qw/access_token auth_storage  do_autorefresh get_scopes_as_array user /],
  is      => 'ro',
  default => sub { WebService::GoogleAPI::Client::UserAgent->new( debug => shift->debug ) },
  lazy    => 1,
);
has 'chi' => ( is => 'rw', default => sub { CHI->new( driver => 'File', max_key_length => 512, namespace => __PACKAGE__ ) }, lazy => 1 );
has 'discovery' => (
  handles => [
    qw/ get_method_meta discover_all extract_method_discovery_detail_from_api_spec get_api_discovery_for_api_id
      methods_available_for_google_api_id list_of_available_google_api_ids  /
  ],
  is      => 'ro',
  default => sub {
    my $self = shift;
    return WebService::GoogleAPI::Client::Discovery->new( debug => $self->debug, ua => $self->ua, chi => $self->chi );
  },
  lazy => 1,
);

## provides a way of augmenting constructor (new) without overloading it
##  see https://metacpan.org/pod/distribution/Moose/lib/Moose/Manual/Construction.pod if like me you an new to Moose


sub BUILD
{
  my ( $self, $params ) = @_;

  $self->auth_storage->setup( { type => 'jsonfile', path => $params->{ gapi_json } } ) if ( defined $params->{ gapi_json } );
  $self->user( $params->{ user } ) if ( defined $params->{ user } );

  ## how to handle chi as a parameter
  $self->discovery->chi( $self->chi );    ## is this redundant? set in default?


  ## TODO - think about consequences of user not providing auth storage or user on instantiaton

}



## ASSUMPTIONS:
##   - path should never include '{'..'}' characters after all interpolations
##   - extra post params as consequence of including path interpolation var values in options will not break server-side requests
##   - either query parameters are not defined for GET or the user agent will handle the options for GET as URL appendaged escaped vals?
##   - no complex parameter checking ( eg required mediaUpload in endpoint gmail.users.messages.send ) so user assumes responsiiblity
## TODO: Exceeding a rate limit will cause an HTTP 403 or HTTP 429 Too Many Requests response and your app should respond by retrying with exponential backoff. (https://developers.google.com/gmail/api/v1/reference/quota)
## TODO: follow the method spec reqeust reference to the api spec schema api_discovery_struct->{schemas}{Message};
##  THE METHOD SPEC CONTAINS
##          'request' => {
##                       '$ref' => 'Message'
##                     },
##  THE SCHEMA api_discovery_struct->{schemas}{Message} CONTAINS
##    'id' => 'Message',
##    'properties' => {
##       'raw' => {
##           {annotations}{required}[ 'gmail.users.drafts.create','gmail.users.drafts.update','gmail.users.messages.insert','gmail.users.messages.send' ]
##  so need to confirm asumption that approach is valid as follows:
##     - iterate through referenced reqerust $ref schema properties and look for matching api endpoint annotation:required entry
##       and if found then error if not defined.
## NB - uses the ua api_query to execute the server request
## NB - this is getting too long .. should split this up into managable chunk to make more readable
sub api_query
{
  my ( $self, @params_array ) = @_;

  ## TODO - find a more elgant idiom to do this - pulled this off top of head for quick imeplementation
  my $params = {};
  if ( scalar( @params_array ) == 1 && ref( $params_array[0] ) eq 'HASH' )
  {
    $params = $params_array[0];

  }
  else
  {
    $params = { @params_array };    ## what happens if not even count
  }
  carp( Dumper $params) if $self->debug > 10;

  my @teapot_errors = ();           ## used to collect pre-query validation errors - if set we return a response with 418 I'm a teapot

  ## pre-query validation if api_id parameter is included
  ## push any critical issues onto @teapot_errors
  ## include interpolation and defaults if required because user has ommitted them


  if ( defined $params->{ api_endpoint_id } )
  {

    ## $api_discovery_struct requried for service base URL
    my $api_discovery_struct = $self->discovery->get_api_discovery_for_api_id( $params->{ api_endpoint_id } );


    ## if can get discovery data for google api endpoint then continue to perform detailed checks
    my $method_discovery_struct = $self->extract_method_discovery_detail_from_api_spec( $params->{ api_endpoint_id } );
    if ( keys %{ $method_discovery_struct } > 0 )    ## method discovery struct ok
    {
      ## ensure user has required scope access
      push( @teapot_errors, "Client Credentials do not include required scope to access $params->{api_endpoint_id}" )
        unless $self->has_scope_to_access_api_endpoint( $params->{ api_endpoint_id } );
      ## set http method to default if unset
      if ( not defined $params->{ method } )
      {
        $params->{ method } = $method_discovery_struct->{ httpMethod } || carp( "API Endpoint discovered specification didn't include expected httpMethod value" );
        if ( not defined $params->{ method } )       ##
        {
          carp( 'setting to GET but this may well be incorrect' );
          $params->{ method } = 'GET';
        }
      }
      elsif ( $params->{ method } !~ /^$method_discovery_struct->{httpMethod}$/sxim )
      {
        push( @teapot_errors, "method mismatch - you requested a $params->{method} which conflicts with discovery spec requirement for $method_discovery_struct->{httpMethod}" );
      }

      warn( "API Endpoint $params->{api_endpoint_id} discovered specification didn't include expected 'parameters' keyed HASH structure" )
        unless ref( $method_discovery_struct->{ parameters } ) eq 'HASH';

      ## Set default path iff not set by user - NB - will prepend baseUrl later
      $params->{ path } = $method_discovery_struct->{ path } unless defined $params->{ path };
      push @teapot_errors, 'path is a required parameter' unless defined $params->{ path };

      foreach my $meth_param_spec ( keys %{ $method_discovery_struct->{ parameters } } )
      {
        ## set default value if is not provided within $params->{options} - nb technically not required but provides visibility of the params if examining the options when debugging
        $params->{ options }{ $meth_param_spec } = $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
          if (
          ( not defined $params->{ options }{ $meth_param_spec } )
          && ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
            && $method_discovery_struct->{ parameters }{ $meth_param_spec }{ location } eq 'query' )
          );
        ## this looks to be clobbering all options - TODO - review and stop clobbering if already defined

        carp( "checking discovery spec'd parameter - $meth_param_spec" ) if $self->debug > 10;

        #carp("$meth_param_spec  has a user option value defined") if ( defined $params->{options}{$meth_param_spec} );
        if ( $params->{ path } =~ /\{.+\}/xms )    ## there are un-interpolated variables in the path - try to fill them for this param if reqd
        {
          carp( "$params->{path} includes unfilled variables " ) if $self->debug > 10;
          carp Dumper $params if $self->debug > 10;
          ## interpolate variables into URI if available and not filled
          if ( $method_discovery_struct->{ parameters }{ $meth_param_spec }{ 'location' } eq 'path' )    ## this is a path variable
          {
            ## requires interpolations into the URI -- consider && into containing if
            if ( $params->{ path } =~ /\{$meth_param_spec\}/xg )                                         ## eg match {jobId} in 'v1/jobs/{jobId}/reports/{reportId}'
            {
              ## if provided as an option
              if ( defined $params->{ options }{ $meth_param_spec } )
              {
                carp( "DEBUG: $meth_param_spec is defined in param->{options}" ) if $self->debug > 10;
                $params->{ path } =~ s/\{$meth_param_spec\}/$params->{options}{$meth_param_spec}/xsmg;
                ## TODO - possible source of errors in future - do we need to undefine the option here?
                ## undefining it so that it doesn't break post contents
                delete $params->{ options }{ $meth_param_spec };
              }
              ## else if not provided as an option but a default value is provided in the spec
              elsif ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default } )
              {
                $params->{ path } =~ s/\{$meth_param_spec\}/$method_discovery_struct->{parameters}{$meth_param_spec}{default}/xsmg;
              }
              else    ## otherwise flag as an error - unable to interpolate
              {
                push( @teapot_errors,
                  "$params->{path} requires interpolation value for $meth_param_spec but none provided as option and no default value provided by specification" );
              }
            }
          }
        }
        elsif ( $method_discovery_struct->{ parameters }{ $meth_param_spec }{ 'location' } eq 'query' )    ## check post form variables .. assume not get?
        {
          if ( !defined $params->{ options }{ $meth_param_spec } )
          {
            $params->{ options }{ $meth_param_spec } = $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
              if ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default } );
          }

        }
      }

      ## error now if there remain uninterpolated variables in the path ?


      ## prepend base if it doesn't match expected base
      #print Dumper $method_discovery_struct;
      $api_discovery_struct->{ baseUrl } =~ s/\/$//sxmg;    ## remove trailing '/'
      $params->{ path } =~ s/^\///sxmg;                     ## remove leading '/'

      $params->{ path } = "$api_discovery_struct->{baseUrl}/$params->{path}" unless $params->{ path } =~ /^$api_discovery_struct->{baseUrl}/ixsmg;


      ## if errors - add detail available in the discovery struct for the method and service to aid debugging
      if ( @teapot_errors )
      {
        ## provide defaults for keys to method discovery that are known to be missing in small number of instances
        $api_discovery_struct->{ canonicalName }     = $api_discovery_struct->{ title } unless defined $api_discovery_struct->{ canonicalName };
        $api_discovery_struct->{ documentationLink } = '??'                             unless defined $api_discovery_struct->{ documentationLink };
        $api_discovery_struct->{ rest }              = ''                               unless defined $api_discovery_struct->{ rest };

        ## Replace all other undefined keys used in error message with ''
        foreach my $expected_key ( qw/title canonicalName ownerName  version id discoveryVersion revision description/ )
        {
          $api_discovery_struct->{ $expected_key } = '?' unless defined $api_discovery_struct->{ $expected_key };
        }

        ## something not quite right here - commenting out for review TODO: REVIEW
#push (@teapot_errors, qq{ $api_discovery_struct->{title} $api_discovery_struct->{rest} API into $api_discovery_struct->{ownerName} $api_discovery_struct->{canonicalName} $api_discovery_struct->{version} with id $method_discovery_struct->{id} as described by discovery document version $method_discovery_struct->{discoveryVersion} revision $method_discovery_struct->{revision} with documentation at $api_discovery_struct->{documentationLink} \nDescription $api_discovery_struct->{description}\n} );
      }

    }
    else    ## teapot error - cannot can get discovery data for google api endpoint
    {
      push( @teapot_errors, "Checking discovery of $params->{api_endpoint_id} method data failed - is this a valid end point" );
    }

  }


  push @teapot_errors, 'path is a required parameter' unless defined $params->{ path };

  if ( @teapot_errors > 0 )    ## carp and include in 418 response body the teapot errors
  {
    carp( join( "\n", @teapot_errors ) ) if $self->debug;
    return Mojo::Message::Response->new(
      content_type => 'text/plain',
      code         => 418,
      message      => 'Teapot Error - Reqeust blocked before submitting to server with pre-query validation errors',
      body         => join( "\n", @teapot_errors )
    );
  }
  else
  {
    #carp Dumper $params;

    return $self->ua->validated_api_query( $params );


    #return $params;
  }

}



########################################################
sub has_scope_to_access_api_endpoint
{
  my ( $self, $api_ep ) = @_;
  return 0 unless defined $api_ep;
  return 0 if $api_ep eq '';
  my $method_spec = $self->extract_method_discovery_detail_from_api_spec( $api_ep );

  if ( keys( %$method_spec ) > 0 )    ## empty hash indicates failure
  {
    my $configured_scopes = $self->ua->get_scopes_as_array();    ## get user scopes arrayref
    ## create a hashindex to facilitate quick lookups
    my %configured_scopes_hash = map { s/\/$//xr, 1 } @$configured_scopes;    ## NB r switch as per https://www.perlmonks.org/?node_id=613280 to filter out any trailing '/'
    my $granted                = 0;                                           ## assume permission not granted until we find a matching scope
    my $required_scope_count   = 0
      ; ## if the final count of scope constraints = 0 then we will assume permission is granted - this has proven necessary for the experimental Google My Business because scopes are not defined in the current discovery data as at 14/10/18
    foreach my $method_scope ( map {s/\/$//xr} @{ $method_spec->{ scopes } } )
    {
      $required_scope_count++;
      $granted = 1 if defined $configured_scopes_hash{ $method_scope };
      last if $granted;
    }
    $granted = 1 if ( $required_scope_count == 0 );
    return $granted;
  }
  else
  {
    return 0;    ## cannot get method spec - warnings should have already been issued - returning - to indicate access denied
  }

}
########################################################




#=head2 MANUAL API REQUEST CONSTRUCTION
#    ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
#    my $res = $gapi_client->api_query(
#      method => 'get',
#      path => 'https://www.googleapis.com/calendar/users/me/calendarList',
#    )->json;
#

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client - Google API Services Client.

=head1 VERSION

version 0.13

=head1 SYNOPSIS

Access Google API Services Version 1 using an OAUTH2 User Agent

    use WebService::GoogleAPI::Client;

    ## assumes gapi.json configuration in working directory with scoped project and user authorization
    
    my $gapi_client = WebService::GoogleAPI::Client->new( debug => 1, gapi_json => 'gapi.json', user=> 'peter@pscott.com.au' );

=head2 AUTOMATIC API REQUEST CONSTRUCTION  - SEND EMAL

    ## using dotted API Endpoint id to invoke helper validation and default value interpolations etc to send email to self
    use Email::Simple;    ## RFC2822 formatted messages
    use MIME::Base64;
    my $my_email_address = 'peter@shotgundriver.com'


    my $raw_email_payload = encode_base64( Email::Simple->create( header => [To => $my_email_address, 
                                                                             From => $my_email_address, 
                                                                             Subject =>"Test email from '$my_email_address' ",], 
                                                                             body => "This is the body of email to '$my_email_address'", 
                                                                )->as_string 
                                        );

    $gapi_client->api_query( 
                            api_endpoint_id => 'gmail.users.messages.send',
                            options    => { raw => $raw_email_payload },
                        );

=head2 MANUAL API REQUEST CONSTRUCTION - GET CALENDAR LIST

    ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
    my $res = $gapi_client->api_query(
      method => 'get',
      path => 'https://www.googleapis.com/calendar/users/me/calendarList',
    )->json;

=head2 C<new>

WebService::GoogleAPI::Client->new( user => 'useremail@sdf.com', gapi_json => '/fullpath/gapi.json' );

=head2 C<api_query>

query Google API with option to validate request before submitting

handles user auth token inclusion in request headers and refreshes token if required and possible

Required params: method, route

Optional params: api_endpoint_id 

$self->access_token must be valid

Examples of usage:

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
      options    => { raw => encode_base64( 
                                            Email::Simple->create( header => [To => $user, From => $user, Subject =>"Test email from $user",], 
                                                                    body   => "This is the body of email from $user to $user", )->as_string 
                                          ), 
                    },
  )->to_string; ##

  print  $gapi_agent->api_query(
            api_endpoint_id => 'gmail.users.messages.list', ## auto sets method to GET, path to 'https://www.googleapis.com/calendar'
          )->to_string;
  #print Dumper $r;


  NB: including the version in the API Endpoint Spec is not supported .. yet? eg gmail:v1.users.messages.list .. will always use the latest stable version


  if the pre-query validation fails then a 418 - I'm a Teapot error response is returned with the 
  body containing the specific description of the errors ( Tea Leaves ;^) ).   

Returns L<Mojo::Message::Response> object

=head2 C<has_scope_to_access_api_endpoint>

Given an API Endpoint such as 'gmail.users.settings.sendAs.get' returns 1 iff user has scope to access

Returns 0 if scope to access is not available to the user.

warns and returns 0 on error ( eg user or config not specified etc )

=head2 C<methods_available_for_google_api_id>

Returns a hashref keyed on the Google service API Endpoint in dotted format.
The hashed content contains a structure
representing the corresponding discovery specification for that method ( API Endpoint )

    methods_available_for_google_api_id('gmail.users.settings.delegates.get')

TODO: consider ? refactor to allow parameters either as a single api id such as 'gmail' 
      as well as the currently accepted  hash keyed on the api and version

DELEGATED FROM WebService::GoogleAPI::Client::Discovery

SEE ALSO:  
  The following methods are delegated through to Client::Discovery - see perldoc WebService::Client::Discovery for detils

  get_method_meta 
  discover_all 
  extract_method_discovery_detail_from_api_spec 
  get_api_discovery_for_api_id

=head2 C<list_of_available_google_api_ids>

Returns an array list of all the available API's described in the API Discovery Resource
that is either fetched or cached in CHI locally for 30 days.

WHen called in a scalar context returns the list as a comma joined string.

DELEGATED FROM WebService::GoogleAPI::Client::Discovery

=head1 FEATURES

=over 1

=item API Discovery with local caching using CHI File

=item OAUTH app credentials (client_id, client_secret, scope, users access_token and refresh_tokens) stored in local file (default name =  gapi.json)

=item access_token refreshes when expires (if user has refresh_token) saving refreshed token back to json file

=item helper api_query to streamline request composition without preventing manual construction if preferred.

=item CLI tool (I<goauth>) with lightweight http server to simplify OAuth2 configuration, sccoping, authorization and obtaining access_ and refresh_ tokensn from users

=back

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
