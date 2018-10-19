NAME

    WebService::GoogleAPI::Client - Google API Services Client.

VERSION

    version 0.11

SYNOPSIS

    Access Google API Services Version 1 using an OAUTH2 User Agent

        ## use goauth CLI helper to create the OATH credentials file ( see perldoc goauth )
    
        use WebService::GoogleAPI::Client;
        use Data::Dumper;
    
        my $gapi = WebService::GoogleAPI::Client->new(debug => 0); # my $gapi = WebService::GoogleAPI::Client->new(access_token => '');
        my $user = 'peter@pscott.com.au'; # full gmail or G-Suite email
    
        $gapi->auth_storage->setup({type => 'jsonfile', path => './gapi.json' }); # by default
    
        $gapi->user($user);       ## allows to select user configuration by google auth'd email address
        $gapi->do_autorefresh(1); ## refresh auth token with refresh token if auth session has expired

 OAUTH CREDENTIALS FILE TO ACCESS SERVCICES

    TODO

 BUILD

    WebService::GoogleAPI::Client->new( user => 'useremail@sdf.com',
    gapi_json => '/fullpath/gapi.json' );

 api_query

    query Google API with option to validate request before submitting

    handles user auth token inclusion in request headers and refreshes
    token if required and possible

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

    Returns Mojo::Message::Response object

 has_scope_to_access_api_endpoint

    Given an API Endpoint such as 'gmail.users.settings.sendAs.get' returns
    1 iff user has scope to access

    Returns 0 if scope to access is not available to the user.

    warns and returns 0 on error ( eg user or config not specified etc )

 methods_available_for_google_api_id

    Returns a hashref keyed on the Google service API Endpoint in dotted
    format. The hashed content contains a structure representing the
    corresponding discovery specification for that method ( API Endpoint )

        methods_available_for_google_api_id('gmail.users.settings.delegates.get')

    TODO: consider ? refactor to allow parameters either as a single api id
    such as 'gmail' as well as the currently accepted hash keyed on the api
    and version

    DELEGATED FROM WebService::GoogleAPI::Client::Discovery

    SEE ALSO: The following methods are delegated through to
    Client::Discovery - see perldoc WebService::Client::Discovery for
    detils

      get_method_meta 
      discover_all 
      extract_method_discovery_detail_from_api_spec 
      get_api_discovery_for_api_id

 list_of_available_google_api_ids

    Returns an array list of all the available API's described in the API
    Discovery Resource that is either fetched or cached in CHI locally for
    30 days.

    WHen called in a scalar context returns the list as a comma joined
    string.

    DELEGATED FROM WebService::GoogleAPI::Client::Discovery

FUNCTIONAL CLASS PROPERTIES

 ua

    Is a WebService::GoogleAPI::Client::UserAgent

  DELEGATE METHOD

METHODS DELEGATED TO PROPERTY CLASS INSTANCES

 access_token ua handles: access_token auth_storage do_autorefresh
 get_scopes_as_array user

    discovery handles: discover_all
    extract_method_discovery_detail_from_api_spec
    get_api_discovery_for_api_id get_method_meta

KEY FEATURES

    Aim is to streamline endpoint access without forcing an additional
    opinionated abstraction layer that imposes unecessary congnitive load.
    Users of the module should be able to access all Google Services and
    either use helper features or fully construct requests in a way that is
    as portable to alternative approaches as possible.

    API Discovery with local caching using CHI File

    OAUTH app credentials (client_id, client_secret, scope, users
    access_token and refresh_tokens) stored in local file (default name =
    gapi.json)

    access_token refreshes when expires (if user has refresh_token) saving
    refreshed token back to json file

    helper api_query to streamline request composition without preventing
    manual construction if preferred.

    CLI tool (goauth) with lightweight http server to simplify OAuth2
    configuration, sccoping, authorization and obtaining access_ and
    refresh_ tokensn from users

 TODO:

    Refactor AuthStorage and Credentials modules - include capability to
    handle service accounts credentials which are not currently supported.
    See https://gist.github.com/gsainio/6322375

    standardise terminology in documentation and code

    include POD for delegated methods

    basic CLI to query API Discovery data ( Potentially with OPEN/Swagger
    Output option ) potenitlaly evolving to something similar to gcloud

SEE ALSO

      * "/cloud.google.com/apis/docs/cloud-client-libraries" in Google
      Cloud Client Libraries https:

      * "/www.blog.google/products/google-cloud/" in Google Cloud Blog
      https:

      * Moo::Google - The original code base later forked into
      WebService::Google::Client by Steve Dondley. Some shadows of the
      original design remain

      * "/github.com/APIs-guru/google-discovery-to-swagger" in Google
      Swagger API https:

      * OAuth2::Client::Google - Perl 6 OAuth2 Client

AUTHOR

    Peter Scott <localshop@cpan.org>

COPYRIGHT AND LICENSE

    This software is Copyright (c) 2017-2018 by Peter Scott and others.

    This is free software, licensed under:

      The Apache License, Version 2.0, January 2004

