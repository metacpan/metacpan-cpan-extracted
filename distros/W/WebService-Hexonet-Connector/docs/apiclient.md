# NAME

WebService::Hexonet::Connector::APIClient - Library to communicate with the insanely fast [HEXONET Backend API](https://www.hexonet.net).

# SYNOPSIS

This module helps to integrate the communication with the HEXONET Backend System.
To be used in the way:

    use 5.030;
    use strict;
    use warnings;
    use WebService::Hexonet::Connector;

    # Create a connection with the URL, entity, login and password
    # Use " 1234 " as entity for the OT&E, and " 54 cd " for productive use
    # Don't have a Hexonet Account yet? Get one here: www.hexonet.net/sign-up

    # create a new instance
    my $cl = WebService::Hexonet::Connector::APIClient->new();

    # set credentials
    $cl->setCredentials('test.user', 'test.passw0rd');

    # or instead set role credentials
    # $cl->setRoleCredentials('test.user', 'testrole', 'test.passw0rd');

    # set your outgoing ip address (to be used in case ip filter settings is active)
    $cl->setRemoteIPAdress('1.2.3.4');

    # specify the HEXONET Backend System to use
    # LIVE System
    $cl->useLIVESystem();
    # or OT&E System
    $cl->useOTESystem();

    # ---------------------------
    # SESSION-based communication
    # ---------------------------
    $r = $cl->login();
    # or if 2FA is active, provide your otp code by
    # $cl->login(" 12345678 ");
    if ($r->isSuccess()) {
        # use saveSession for your needs
        # to apply the API session to your frontend session.
        # For later reuse (no need to specify credentials and otp code)
        # within every request to your frontend server,
        # rebuild the session by using reuseSession method accordingly.
        # No need to provide credentials, no need to select a system,
        # nor to provide a otp code further on.

        $r = $cl->request({ COMMAND: 'StatusAccount' });
        # further logic, further commands

        # perform logout, you may check the result as shown with the login method
        $cl->logout();
    }

    # -------------------------
    # SESSIONless communication
    # -------------------------
    $r = $cl->request({ COMMAND: 'StatusAccount' });


        # -------------------------------------
        # Working with returned Response object
        # -------------------------------------
        # Display the result in the format you want
        my $res;
        $res = $r->getListHash());
        $res = $r->getHash();
        $res = $r->getPlain();

        # Get the response code and the response description
        my $code = $r->getCode();
        my $description = $r->getDescription();

        print "$code$description ";

        # There are further useful methods that help to access data
        # like getColumnIndex, getColumn, getRecord, etc.
        # Check the method documentation below.

See the documented methods for deeper information.

# DESCRIPTION

This library is used to provide all functionality to be able to communicate with the HEXONET Backend System.

## Methods

- `new`

    Returns a new [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance.

- `enableDebugMode`

    Activates the debug mode. Details of the API communication are put to STDOUT.
    Like API command, POST data, API plain-text response.
    Debug mode is inactive by default.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `disableDebugMode`

    Deactivates the debug mode. Debug mode is inactive by default.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `getPOSTData( $command, $secured )`

    Get POST data fields ready to use for HTTP communication based on LWP::UserAgent.
    Specify the API command for the request by $command.
    Specify if password data has to be replaced with asterix to secure it for output purposes by $secured. Optional.
    This method is internally used by the request method.
    Returns a hash.

- `getProxy`

    Returns the configured Proxy URL to use for API communication as string.

- `getReferer`

    Returns the configured HTTP Header \`Referer\` value to use for API communication as string.

- `getSession`

    Returns the API session in use as string.

- `getURL`

    Returns the url in use pointing to the Backend System to communicate with, as string.

- `getUserAgent`

    Returns the user-agent string.

- `getVersion`

    Returns the SDK version currently in use as string.

- `saveSession( $sessionhash )`

    Save the current API session data into a given session hash object.
    This might help you to add the backend system session into your frontend session.
    Use reuseSession method to set a new instance of this module to that session.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `reuseSession( $sessionhash )`

    Reuse API session data that got previously saved into the given session hash object
    by method saveSession.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setURL( $url )`

    Set a different backend system url to be used for communication.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setOTP( $otpcode )`

    Set your otp code. To be used in case of active 2FA.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setProxy( $proxy )`

    Set the Proxy URL to use for API communication.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setReferer( $referer )`

    Set the HTTP Header \`Referer\` value to use for API communication.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setSession( $sessionid )`

    Set the API session id to use. Automatically handled after successful session login
    based on method login or loginExtended.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setRemoteIPAddress( $ip )`

    Set the outgoing ip address to be used in API communication.
    Use this in case of an active IP filter setting for your account.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setCredentials( $user, $pw )`

    Set the credentials to use in API communication.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setRoleCredentials( $user, $role, $pw)`

    Set the role user credentials to use in API communication.
    NOTE: the role user specified by $role has to be directly assigned to the
    specified account specified by $user.
    The specified password $pw belongs to the role user, not to the account.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `setUserAgent( $str, $rv, $modules )`

    Set a custom user agent header. This is useful for tools that use our SDK.
    Specify the client label in $str and the revision number in $rv.
    Specify further libraries in use by array $modules. This is optional. Entry Format: "modulename/version".
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining .

- `login( $otpcode )`

    Perform a session login. Entry point for the session-based communication.
    You may specify your OTP code by $otpcode.
    Returns an instance of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `loginExtended( $params, $otpcode )`

    Perform a session login. Entry point for the session-based communication.
    You may specify your OTP code by $otpcode.
    Specify additional command parameter for API command " StartSession " in
    Hash $params.
    Possible parameters can be found in the [API Documentation for StartSession](https://github.com/hexonet/hexonet-api-documentation/blob/master/API/USER/SESSION/STARTSESSION.md).
    Returns an instance of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `logout`

    Perfom a session logout. This destroys the API session.
    Returns an instance of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `request( $command )`

    Requests the given API Command $command to the Backend System.
    Returns an instance of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `requestNextResponsePage( $lastresponse )`

    Requests the next response page for the provided api response $lastresponse.
    Returns an instance of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `requestAllResponsePages( $command )`

    Requests all response pages for the specified command.
    NOTE: this might take some time. Requests are not made in parallel!
    Returns an array of instances of [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).

- `setUserView( $subuser )`

    Activate read/write Data View on the specified subuser account.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `resetUserView`

    Reset the data view activated by setUserView.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `useDefaultConnectionSetup`

    Use the Default Setup to connect to our backend systems. This is the default!
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `useHighPerformanceConnectionSetup`

    Use the High Performance Connection Setup to connect to our backend systems. This is not the default! Read README.md for Details.
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `useLIVESystem`

    Use the LIVE Backend System as communication endpoint.
    Usage may lead to costs. BUT - are system is a prepaid system.
    As long as you don't have charged your account, you cannot order.
    This is the default!
    Returns the current [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) instance in use for method chaining.

- `_flattenCommand( $cmd )`

    Private method. Converts all keys of the given hash into upper case letters and flattens parameters using nested arrays to string parameters.
    Returns the new command.

- `_autoIDNConvert( $cmd )`

    Private method. Converts all affected parameter values to punycode as our API only works with punycode domain names, not with IDN.
    Returns the new command.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
