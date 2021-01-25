# NAME

WebService::Hexonet::Connector - Connector library for the insanely fast [HEXONET Backend API](https://www.hexonet.net/).

# SYNOPSIS

        ###############################
        # How to use this Library?
        ###############################

        # Install our module by
        cpan WebService::Hexonet::Connector
        # or
        cpanm WebService::Hexonet::Connector
        # NOTE: We suggest to use cpanm (App::cpanminus) for several reasons.

Check the Example provided at [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient).

# DESCRIPTION

This module is used as namespace.

# AVAILABLE SUBMODULES

We've split our functionality into submodules to give this module a better structure.

- [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) - API Client functionality.
- [WebService::Hexonet::Connector::Column](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AColumn) - API Response Data handling as "Column".
- [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord) - API Response Data handling as "Record".
- [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) - API Response functionality.
- [WebService::Hexonet::Connector::ResponseParser](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseParser) - API Response Parser functionality.
- [WebService::Hexonet::Connector::ResponseTemplate](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplate) - API Response Template functionality.
- [WebService::Hexonet::Connector::ResponseTemplateManager](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplateManager) - API Response Template Manager functionality.
- [WebService::Hexonet::Connector::SocketConfig](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ASocketConfig) - API Communication Configuration functionality.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
