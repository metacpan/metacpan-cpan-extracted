# NAME

WebService::Hexonet::Connector::SocketConfig - Library to wrap API connection settings.

# SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::APIClient module as described below.
To be used in the way:

    # create a new instance
    $sc = WebService::Hexonet::Connector::SocketConfig->new();

See the documented methods for deeper information.

# DESCRIPTION

This library is used to wrap the API connection settings to control which API credentials / ip address etc.
is to be used within the API HTTP Communication.
It is used internally by class [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient).

## Methods

- `new`

    Returns a new [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) object.

- `getPOSTData`

    Returns a hash covering the POST data fields. ready to use for
    a HTTP request based on [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent).

- `getSession`

    Returns the session id as string.

- `getSystemEntity`

    Returns the Backend System entity in use as string.
    "54cd" represents the LIVE System.
    "1234" represents the OT&E System.

- `setLogin( $user )`

    Sets the account name to be used in API request.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setOTP( $optcode )`

    Sets the otp code to be used in API request.
    Required in case 2FA is activated for the account.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setPassword( $pw )`

    Sets the password to be used in API request.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setRemoteAddress( $ip )`

    Sets the outgoing ip address to be used in API request.
    To be used in case of an active IP filter setting for the account.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setSession( $sessionid )`

    Sets the session id to be used in API request.
    NOTE: this is the session id we get from Backend System
    when starting a session based communication.
    This is not a frontend-related session id!
    Setting the session resets the login, password and otp code,
    as we only need the session id for further requests as long
    as this session id is valid in the Backend System.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setSystemEntity( $entity )`

    Sets the Backend System entity.
    "54cd" represents the LIVE System.
    "1234" represents the OT&E System.
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

- `setUser( $subuser )`

    Sets the specified subuser user account name.
    To be used in case you want to have a data view on a specific customer.
    NOTE: That view is still read and write!
    Returns the current [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) instance in use for method chaining.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
