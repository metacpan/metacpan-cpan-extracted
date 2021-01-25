# NAME

WebService::Hexonet::Connector::Logger - Library to cover API request and response data output / logging.

# SYNOPSIS

This module is internally used by the [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) module.
To be used in the way:

    # create a new instance by
    $logger = WebService::Hexonet::Connector::Logger->new();

    # Log API Request / Response Data
    # * specify request data in $data in string format
    # * specify an instance of WebService::Hexonet::Connector::Response in $r.    
    # * specify an error message as string in $error (optional parameter)
    $logger->log( $data, $r, $error );
    #  vs.
    $logger->log( $data, $r );    

# DESCRIPTION

HEXONET Backend API communication will be printed to STDOUT/STDERR by default.
This mechanism can be overwritten by a CustomLogger implementation.
Use method setCustomLogger of WebService::Hexonet::Connector::APIClient for this.
Important is that a custom implementation provides method \`log\` and supports all the arguments explained.

## Methods

- `new`

    Returns a new [WebService::Hexonet::Connector::Logger](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ALogger) object.

- `log($post, $r, $error)`

    Log API Request / Response Data
    Specify request data in $data in string format
    Specify an instance of WebService::Hexonet::Connector::Response in $r.
    Specify an error message as string in $error. Optional. Thought for forwarding HTTP errors.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
