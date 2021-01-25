# NAME

WebService::Hexonet::Connector::ResponseTemplate - Library that provides basic functionality
to access API response data.

# SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::Response module as described below.
To be used in the way:

    # specify the API plain-text response (this is just an example that won't fit to the command above)
    $plain = "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n";

    # create a new instance
    $r = WebService::Hexonet::Connector::ResponseTemplate->new($plain);

The difference of this library and the Response library is simply that this library

- does not provide further data access possibilities based on Column and Record library
- does not require an API command to be specified in constructor

# DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. This module manages all this: parsing data into hash format.
It provides different methods to access the data to fit your needs.
It is used as base class for [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse).
We internally use this module also in our automated tests to play with hardcoded API responses.

## Methods

- `new( $plain )`

    Returns a new [WebService::Hexonet::Connector::ResponseTemplate](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplate) instance.
    Specify the plain-text API response as $plain.

- `getCode`

    Returns the API response code as int. 

- `getDescription`

    Returns the API response description as string. 

- `getPlain`

    Returns the plain-text API response as string.

- `getQueuetime`

    Returns the Queuetime of the API response as decimal. 

- `getHash`

    Returns the API response as Hash. 

- `getRuntime`

    Returns the Runtime of the API response code as decimal. 

- `isError`

    Checks if the API response code represents an error case.
    500 <= Code <= 599
    Returns boolean 0 or 1.

- `isSuccess`

    Checks if the API response code represents a success case.
    200 <= Code <= 299
    Returns boolean 0 or 1.

- `isTmpError`

    Checks if the API response code represents a temporary error case.
    400 <= Code <= 499
    Returns boolean 0 or 1.

- `isPending`

    Checks if current operation is returned as pending.
    Returns boolean 0 or 1.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
