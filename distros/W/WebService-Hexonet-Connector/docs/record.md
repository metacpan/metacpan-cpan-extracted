# NAME

WebService::Hexonet::Connector::Record - Library to cover API response data in row-based way.

# SYNOPSIS

This module is internally used by the [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) module.
To be used in the way:

    # specify the row data in hash notation
    $data = { DOMAIN => 'mydomain.com',  NAMESERVER0 => 'ns1.mydomain.com' };

    # create a new instance by
    $rec = WebService::Hexonet::Connector::Record->new($data);

# DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. For simplifying data access we created this library and also the Column library
to provide an additional and more customerfriendly way to access data. Previously getHash and
getListHash were the only possibilities to access data in Response library.

## Methods

- `new( $data )`

    Returns a new [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord) object.
    Specifiy the row data in hash notation as $data.

- `getData`

    Returns the whole row data as hash.

- `getDataByKey( $key )`

    Returns the row data for the specified column name as $key as scalar.
    Returns undef if not found.

- `hasData( $key )`

    Checks if the column specified by $key exists in the row data.
    Returns boolean 0 or 1.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
