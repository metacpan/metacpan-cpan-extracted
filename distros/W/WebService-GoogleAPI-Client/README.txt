NAME

    WebService::GoogleAPI::Client - API WebService OAUTH2 Client Agent to
    streamline access to GOOGLE API End-Point Services using Discovery Data

VERSION

    version 0.18

SYNOPSIS

    Access Google API Services Version 1 using an OAUTH2 User Agent

    assumes gapi.json configuration in working directory with scoped Google
    project redentials and user authorization created by _goauth_

        use WebService::GoogleAPI::Client;
        
        my $gapi_client = WebService::GoogleAPI::Client->new( debug => 1, gapi_json => 'gapi.json', user=> 'peter@pscott.com.au' );
        
        say $gapi_client->list_of_available_google_api_ids();
    
        my @gmail_endpoint_list =      $gapi_client->methods_available_for_google_api_id('gmail')
    
        if $gapi_agent->has_scope_to_access_api_endpoint( 'gmail.users.settings.sendAs.get' ) {
          say 'User has Access to GMail Method End-Point gmail.users.settings.sendAs.get';
        }

    Internal User Agent provided be property
    WebService::GoogleAPI::Client::UserAgent dervied from Mojo::UserAgent

    Package includes go_auth CLI Script to collect initial end-user
    authorisation to scoped services

EXAMPLES

 AUTOMATIC API REQUEST CONSTRUCTION - SEND EMAL

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

 MANUAL API REQUEST CONSTRUCTION - GET CALENDAR LIST

        ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
        my $res = $gapi_client->api_query(
          method => 'get',
          path => 'https://www.googleapis.com/calendar/users/me/calendarList',
        )->json;

METHODS

 new

      WebService::GoogleAPI::Client->new( user => 'peter@pscott.com.au', gapi_json => '/fullpath/gapi.json' );

  PARAMETERS

   user :: the email address that identifies key of credentials in the
   config file

   gapi_json :: Location of the configuration credentials - default
   gapi.json

   debug :: if '1' then diagnostics are send to STDERR - default false

   chi :: an instance to a CHI persistent storage case object - if none
   provided FILE is used

 api_query

    query Google API with option to validate request before submitting

    handles user auth token inclusion in request headers and refreshes
    token if required and possible

    Required params: method, route

    Optional params: api_endpoint_id

    $self->access_token must be valid

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
      #print pp $r;
    
    
      NB: including the version in the API Endpoint Spec is not supported .. yet? eg gmail:v1.users.messages.list .. will always use the latest stable version
    
    
      if the pre-query validation fails then a 418 - I'm a Teapot error response is returned with the 
      body containing the specific description of the errors ( Tea Leaves ;^) ).   

    Returns Mojo::Message::Response object

 has_scope_to_access_api_endpoint

    Given an API Endpoint such as 'gmail.users.settings.sendAs.get' returns
    1 iff user has scope to access

        say 'User has Access'  if $gapi_agent->has_scope_to_access_api_endpoint( 'gmail.users.settings.sendAs.get' );

    Returns 0 if scope to access is not available to the user.

    warns and returns 0 on error ( eg user or config not specified etc )

METHODS DELEGATED TO WebService::GoogleAPI::Client::Discovery

 discover_all

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

 get_api_discovery_for_api_id

    returns the cached version if avaiable in CHI otherwise retrieves
    discovery data via HTTP, stores in CHI cache and returns as a Perl data
    structure.

        my $hashref = $self->get_api_discovery_for_api_id( 'gmail' );
        my $hashref = $self->get_api_discovery_for_api_id( 'gmail:v3' );

    returns the api discovery specification structure ( cached by CHI ) for
    api id ( eg 'gmail ')

    returns the discovery data as a hashref, an empty hashref on certain
    failing conditions or croaks on critical errors.

 methods_available_for_google_api_id

    Returns a hashref keyed on the Google service API Endpoint in dotted
    format. The hashed content contains a structure representing the
    corresponding discovery specification for that method ( API Endpoint ).

        methods_available_for_google_api_id('gmail')

 extract_method_discovery_detail_from_api_spec

        $my $api_detail = $gapi->discovery->extract_method_discovery_detail_from_api_spec( 'gmail.users.settings' );

    returns a hashref representing the discovery specification for the
    method identified by $tree in dotted API format such as
    texttospeech.text.synthesize

    returns an empty hashref if not found

 list_of_available_google_api_ids

    Returns an array list of all the available API's described in the API
    Discovery Resource that is either fetched or cached in CHI locally for
    30 days.

        my $r = $agent->list_of_available_google_api_ids();
        print "List of API Services ( comma separated): $r\n";
    
        my @list = $agent->list_of_available_google_api_ids();

FEATURES

      * API Discovery requests cached with CHI ( Default File )

      * OAUTH app and user credentials (client_id, client_secret, scope,
      users access_token and refresh_tokens) stored in local file (default
      name = gapi.json)

      * access_token auto-refreshes when expires (if user has
      refresh_token) saving refreshed token back to json file

      * helper api_query to streamline request composition without
      preventing manual construction if preferred.

      * CLI tool (goauth) with lightweight HTTP server to simplify OAuth2
      configuration, sccoping, authorization and obtaining access_ and
      refresh_ tokens from users

AUTHOR

    Peter Scott <localshop@cpan.org>

COPYRIGHT AND LICENSE

    This software is Copyright (c) 2017-2018 by Peter Scott and others.

    This is free software, licensed under:

      The Apache License, Version 2.0, January 2004

