# NAME

WebService::Hexonet::Connector::Column - Library to cover API response data in column-based way.

# SYNOPSIS

This module is internally used by the [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) module.
To be used in the way:

    # specify the column name
    $key = "DOMAIN";

    # specify the column data as array
    @data = ('mydomain.com', 'mydomain.net');

    # create a new instance by
    $col = WebService::Hexonet::Connector::Column->new($key, @data);

# DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. For simplifying data access we created this library and also the Record library
to provide an additional and more customerfriendly way to access data. Previously getHash and
getListHash were the only possibilities to access data in Response library.

## Methods

- `new( $key, @data )`

    Returns a new [WebService::Hexonet::Connector::Column](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AColumn) object.
    Specify the column name in $key and the column data in @data.

- `getKey`

    Returns the column name as string.

- `getData`

    Returns the full column data as array.

- `getDataByIndex( $index )`

    Returns the column data of the specified index as scalar.
    Returns undef if not found.

- `hasDataIndex( $index )`

    Checks if the given index exists in the column data.
    Returns boolean 0 or 1.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
