# NAME

WebService::Hexonet::Connector::ResponseParser - Library that provides functionality to parse
plain-text API response data into Hash format and to serialize it back to plain-text format
if necessary.

# SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::Response module.
To be used in the way:

    # specify the API plain-text response (this is just an example that won't fit to the command above)
    $plain = "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n";

    # parse a plain-text response into hash
    $hash = WebService::Hexonet::Connector::ResponseParser::parse($plain);

    # serialize that hash format back to plain-text
    $plain = WebService::Hexonet::Connector::ResponseParser::serialize($hash);

# DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful data structure.
Within automated tests we also need the reverse way to serialize a parsed response back to plain-text.
This module cares about exactly all that.

## Methods

- `parse( $plain )`

    Returns the parsed API response as Hash.
    Specifiy the plain-text API response as $plain.

- `serialize( $hash )`

    Returns the serialized API response as string. 
    Specifiy the hash notation of the API response as $hash.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
