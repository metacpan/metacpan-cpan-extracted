NAME

    WebService::GoogleAPI::Client - Google API Discovery and SDK

VERSION

    version 0.26

SYNOPSIS

    Access Google API Services using an OAUTH2 User Agent.

    Includes Discovery, validation, authentication and API Access.

    By default assumes gapi.json configuration in working directory with
    scoped Google project credentials and user authorization created by
    goauth.

        use WebService::GoogleAPI::Client;
        
        my $gapi_client = WebService::GoogleAPI::Client->new( debug => 1, gapi_json => 'gapi.json', user=> 'peter@pscott.com.au' );
        
        say $gapi_client->list_of_available_google_api_ids();
    
        my @gmail_endpoint_list =      $gapi_client->methods_available_for_google_api_id('gmail')
    
        if $gapi_agent->has_scope_to_access_api_endpoint( 'gmail.users.settings.sendAs.get' ) {
          say 'User has Access to GMail Method End-Point gmail.users.settings.sendAs.get';
        }

    Package includes goauth CLI Script to collect initial end-user
    authorisation to scoped services.

    Note to intrepid hackers: Any method that isn't documented is
    considered private, and subject to change in breaking ways without
    notice. (Although I'm a pretty nice guy, and probably will leave a
    warning or something).

EXAMPLES

 AUTOMATIC API REQUEST CONSTRUCTION - SEND EMAL

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

 MANUAL API REQUEST CONSTRUCTION - GET CALENDAR LIST

        ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
        my $res = $gapi_client->api_query(
          method => 'get',
          path => 'https://www.googleapis.com/calendar/users/me/calendarList',
        )->json;

METHODS

 new

      WebService::GoogleAPI::Client->new(
         user => 'peter@pscott.com.au', gapi_json => '/fullpath/gapi.json' );

  General parameters

    debug

      if truthy then diagnostics are send to STDERR - default false. Crank
      it up to 11 for maximal debug output

    chi

      an instance to a CHI persistent storage case object - if none
      provided FILE is used

  Login Parameters

    You can use either gapi_json, which is the file you get from using the
    bundled goauth tool, or service_account which is the json file you can
    download from
    https://console.cloud.google.com/iam-admin/serviceaccounts.

    service_account and gapi_json are mutually exclusive, and gapi_json
    takes precedence.

    If nothing is passed, then we check the GOOGLE_APPLICATION_CREDENTIALS
    env variable for the location of a service account file. This matches
    the functionality of the Google Cloud libraries from other languages
    (well, somewhat. I haven't fully implemented ADC yet - see Google's
    Docs <https://cloud.google.com/docs/authentication/production> for some
    details. PRs are welcome!)

    If that doesn't exist, then we default to gapi.json in the current
    directory.

    Be wary! This default is subject to change as more storage backends are
    implemented. A deprecation warning will be emmitted when this is likely
    to start happening.

    For more advanced usage, you can supply your own auth storage instance,
    which is a consumer of the WebService::GoogleAPI::Client::AuthStorage
    role. See the POD for that module for more information.

    user

      the email address that requests will be made for

    gapi_json

      Location of end user credentials

    service_account

      Location of service account credentials

    auth_storage

      An instance of a class consuming
      WebService::GoogleAPI::Client::AuthStorage, already set up for
      returning access tokens (barring the ua).

    If you're using a service account, user represents the user that you're
    impersonating. Make sure you have domain-wide delegation set up, or
    else this won't work.

 api_query

    query Google API with option to validate request before submitting

    handles user auth token inclusion in request headers and refreshes
    token if required and possible

    Required params: method, route

    Optional params: api_endpoint_id cb_method_discovery_modify, options

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

    If the pre-query validation fails then a 418 - I'm a Teapot error
    response is returned with the body containing the specific description
    of the errors ( Tea Leaves ;^) ).

  Dealing with inconsistencies

    NB: If you pass a 'path' parameter this takes precendence over the API
    Discovery Spec. Any parameters defined in the path of the format
    {VARNAME} will be filled in with values within the options=>{ VARNAME
    => 'value '} parameter structure. This is the simplest way of
    addressing issues where the API discovery spec is inaccurate. ( See
    dev_sheets_example.pl as at 14/11/18 for illustration ). This
    particular issue has been since solved, but you never know where else
    there are problems with the discovery spec.

    Sometimes, Google is slightly inconsistent about how to name the
    parameters. For example, error messages sent back to the user tend to
    have the param names in snake_case, whereas the discovery document
    always has them in camelCase. To address this issue, and in the DWIM
    spirit of perl, parameters may be passed in camelCase or snake_case.
    That means that

        $gapi_agent->api_query(
            api_endpoint_id => 'gmail.users.messages.list',
            options => { userId => 'foobar' });

    and

        $gapi_agent->api_query(
            api_endpoint_id => 'gmail.users.messages.list',
            options => { user_id => 'foobar' });

    will produce the same result.

    Sometimes a param expects a dynamic part and a static part. The
    endpoint jobs.projects.jobs.list, for example, has a param called
    'parent' which has a format '^projects/[^/]+$'. In cases like this, you
    can just skip out the constant part, making

      $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.list',
        options => { parent => 'sner' } );

    and

      $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.list',
        options => { parent => 'projects/sner' } );

    the same. How's that for DWIM?

    In addition, you can use different names to refer to multi-part
    parameters. For example, the endpoint jobs.projects.jobs.delete
    officially expects one parameter, 'name'. The description for the param
    tells you that you it expects it to contain 'projectsId' and 'jobsId'.
    For cases like this,

      $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.delete',
        options => {name => 'projects/sner/jobs/bler'} );

    and

      $gapi_agent->api_query( api_endpoint_id => 'jobs.projects.jobs.delete',
        options => {projectsId => 'sner', jobsId => 'bler'} );

    will produce the same result. Note that for now, in this case you can't
    pass the official param name without the constant parts. That may
    change in the future.

    To further fix discrepencies in the Discovery Specification, the
    cb_method_discovery_modify callback can be used which must accept the
    method specification as a parameter and must return a (potentially
    modified) method spec.

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

 get_api_document

    returns the cached version if avaiable in CHI otherwise retrieves
    discovery data via HTTP, stores in CHI cache and returns as a Perl data
    structure.

        my $hashref = $self->get_api_document( 'gmail' );
        my $hashref = $self->get_api_document( 'gmail:v3' );

    returns the api discovery specification structure ( cached by CHI ) for
    api id ( eg 'gmail ')

    returns the discovery data as a hashref, an empty hashref on certain
    failing conditions or croaks on critical errors.

 methods_available_for_google_api_id

    Returns a hashref keyed on the Google service API Endpoint in dotted
    format. The hashed content contains a structure representing the
    corresponding discovery specification for that method ( API Endpoint ).

        methods_available_for_google_api_id('gmail')

 get_method_details

        $my $api_detail = $gapi->discovery->get_method_details( 'gmail.users.settings' );

    returns a hashref representing the discovery specification for the
    method identified by $tree in dotted API format such as
    texttospeech.text.synthesize

    returns an empty hashref if not found

 list_api_ids

    Returns an array list of all the available API's described in the API
    Discovery Resource that is either fetched or cached in CHI locally for
    30 days.

        my $r = $agent->list_api_ids();
        print "List of API Services ( comma separated): $r\n";
    
        my @list = $agent->list_api_ids();

    To check for just one service id, use service_exists instead.

FEATURES

      * API Discovery requests cached with CHI ( Default File )

      * OAUTH app and user credentials (client_id, client_secret, scope,
      users access_token and refresh_tokens) stored in local file (default
      name = gapi.json)

      * access_token auto-refreshes when expires (if user has
      refresh_token) saving refreshed token back to json file

      * helper api_query to streamline request composition without
      preventing manual construction if preferred.

      * CLI tool (goauth) with lightweight Mojo HTTP server to simplify
      OAuth2 configuration, sccoping, authorization and obtaining access_
      and refresh_ tokens from users

AUTHORS

      * Veesh Goldman <veesh@cpan.org>

      * Peter Scott <localshop@cpan.org>

COPYRIGHT AND LICENSE

    This software is Copyright (c) 2017-2021 by Peter Scott and others.

    This is free software, licensed under:

      The Apache License, Version 2.0, January 2004

