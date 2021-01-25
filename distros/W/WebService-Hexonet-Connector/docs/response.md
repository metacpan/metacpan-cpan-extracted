# NAME

WebService::Hexonet::Connector::Response - Library to provide accessibility to API response data.

# SYNOPSIS

This module is internally used by the [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) module.
To be used in the way:

    # specify the used API command (used for the request that responsed with $plain)
    $command = {
            COMMAND => 'StatusAccount'
    };
    # Optionally specify replacements for place holders in static response templates e.g. {CONNECTION_URL}
    # see ResponseTemplateManager. This makes of course sense and is handled internally by APIClient automatically.
    # When using Repsonse class in unit tests, you could leave this probably out.
    $ph = {
        CONNECTION_URL => 'https://api.ispapi.net/api/call.cgi'
    };

    # specify the API plain-text response (this is just an example that won't fit to the command above)
    $plain = "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n";

    # create a new instance by
    $r = WebService::Hexonet::Connector::Response->new($plain, $command, $ph);

# DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. This module manages all this: parsing data into hash format, into columns and records.
It provides different methods to access the data to fit your needs.

## Methods

- `new( $plain, $command, $ph )`

    Returns a new [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) object.
    Specify the plain-text API response by $plain.
    Specify the used command by $command.
    Specify the hash covering all place holder variable's replacement values by $ph. Optional.

- `addColumn( $key, @data )`

    Add a new column.
    Specify the column name by $key.
    Specify the column data by @data.
    Returns the current [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) instance in use for method chaining.

- `addRecord( $hash )`

    Add a new record.
    Specify the row data in hash notation by $hash.
    Where the hash key represents the column name.
    Where the hash value represents the row value for that column.
    Returns the current [WebService::Hexonet::Connector::Response](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponse) instance in use for method chaining.

- `getColumn( $key )`

    Get a column for the specified column name $key.
    Returns an instance of [WebService::Hexonet::Connector::Column](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AColumn).

- `getColumnIndex( $key, $index )` {

    Get Data of the specified column $key for the given column index $index.
    Returns a scalar.

- `getColumnKeys`

    Get a list of available column names. NOTE: columns may differ in their data size.
    Returns an array.

- `getCommand`

    Get the command used within the request that resulted in this api response.
    This is in general the command you provided in the constructor.
    Returns a hash.

- `getCommandPlain`

    Get the command in plain text that you used within the API request of this response.
    This is in general the command you provided in the constructor.
    Returns a string.

- `getCurrentPageNumber`

    Returns the current page number we are in with this API response as int.
    Returns -1 if not found.

- `getCurrentRecord`

    Returns the current record of the iteration. It internally uses recordIndex as iterator index.
    Returns an instance of [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord).
    Returns undef if not found.

- `getFirstRecordIndex`

    Returns the first record index of this api response as int.
    Returns undef if not found.

- `getLastRecordIndex`

    Returns the last record index of this api response as int.
    Returns undef if not found.

- `getListHash`

    Returns this api response in a List-Hash format.
    You will find the row data under hash key "LIST".
    You will find meta data under hash key "meta".
    Under "meta" data you will again find a hash, where
    hash key "columns" provides you a list of available
    column names and "pg" provides you useful paginator
    data.
    This method is thought to be used if you need
    something that helps you realizing tables with or 
    without a pager.
    Returns a Hash.

- `getNextRecord`

    Returns the next record of the current iteration.
    Returns an instance of [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord).
    Returns undef if not found.

- `getNextPageNumber`

    Returns the number of the next api response page for the current request as int.
    Returns -1 if not found.

- `getNumberOfPages`

    Returns the total number of response pages in our API for the current request as int.

- `getPagination`

    Returns paginator data of the current response / request.
    Returns a hash.

- `getPreviousPageNumber`

    Returns the number of the previous api response page for the current request as int.
    Returns -1 if not found.

- `getPreviousRecord`

    Returns the previous record of the current iteration.
    Returns undef if not found otherwise an instance of [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord).

- `getRecord( $index )`

    Returns the record of the specified record index $index.
    Returns undef if not found otherwise an instance of [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord).

- `getRecords`

    Returns a list of available records.
    Returns an array of instances of [WebService::Hexonet::Connector::Record](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3ARecord).

- `getRecordsCount`

    Returns the amount of returned records for the current request as int.

- `getRecordsTotalCount`

    Returns the total amount of available records for the current request as int.

- `getRecordsLimitation`

    Returns the limitation of the current request as int. LIMIT = ...
    NOTE: Our system comes with a default limitation if you do not specify
    a limitation in list commands to avoid data load in our systems.
    This limitation is then returned in column "LIMIT" at index 0.

- `hasNextPage`

    Checks if a next response page exists for the current query.
    Returns boolean 0 or 1.

- `hasPreviousPage`

    Checks if a previous response page exists for the current query.
    Returns boolean 0 or 1.

- `rewindRecordList`

    Resets the current iteration to index 0.

- `_hasColumn( $key )`

    Private method. Checks if a column specified by $key exists.
    Returns boolean 0 or 1.

- `_hasCurrentRecord`

    Private method. Checks if the current record exists in the iteration.
    Returns boolean 0 or 1.

- `_hasNextRecord`

    Private method. Checks if the next record exists in the iteration.
    Returns boolean 0 or 1.

- `_hasPreviousRecord`

    Private method. Checks if the previous record exists in the iteration.
    Returns boolean 0 or 1.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
