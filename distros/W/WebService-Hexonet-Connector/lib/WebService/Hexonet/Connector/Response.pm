package WebService::Hexonet::Connector::Response;

use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector::Column;
use WebService::Hexonet::Connector::Record;
use parent qw(WebService::Hexonet::Connector::ResponseTemplate);
use POSIX qw(ceil floor);
use List::MoreUtils qw(first_index);
use Readonly;
Readonly my $INDEX_NOT_FOUND => -1;

use version 0.9917; our $VERSION = version->declare('v2.2.3');


sub new {
    my ( $class, $raw, $cmd ) = @_;
    my $self = WebService::Hexonet::Connector::ResponseTemplate->new($raw);
    $self = bless $self, $class;
    $self->{command}     = $cmd;
    $self->{columnkeys}  = [];
    $self->{columns}     = [];
    $self->{records}     = [];
    $self->{recordIndex} = 0;

    my $h = $self->getHash();
    if ( defined $h->{PROPERTY} ) {
        my @keys  = keys %{ $h->{PROPERTY} };
        my $count = 0;
        foreach my $key (@keys) {
            my @d = @{ $h->{PROPERTY}->{$key} };
            $self->addColumn( $key, @d );
            my $len = scalar @d;
            if ( $len > $count ) {
                $count = $len;
            }
        }
        $count--;
        for my $i ( 0 .. $count ) {
            my %d = ();
            foreach my $colkey (@keys) {
                my $col = $self->getColumn($colkey);
                if ( defined $col ) {
                    my $v = $col->getDataByIndex($i);
                    if ( defined $v ) {
                        $d{$colkey} = $v;
                    }
                }
            }
            $self->addRecord( \%d );
        }
    }
    return $self;
}


sub addColumn {
    my ( $self, $key, @data ) = @_;
    push @{ $self->{columns} }, WebService::Hexonet::Connector::Column->new( $key, @data );
    push @{ $self->{columnkeys} }, $key;
    return $self;
}


sub addRecord {
    my ( $self, $h ) = @_;
    push @{ $self->{records} }, WebService::Hexonet::Connector::Record->new($h);
    return $self;
}


sub getColumn {
    my ( $self, $key ) = @_;
    if ( $self->_hasColumn($key) ) {
        my $idx = first_index { $_ eq $key } @{ $self->{columnkeys} };
        return $self->{columns}[ $idx ];
    }
    return;
}


sub getColumnIndex {
    my ( $self, $key, $idx ) = @_;
    my $col = $self->getColumn($key);
    return $col->getDataByIndex($idx) if defined $col;
    return;
}


sub getColumnKeys {
    my $self = shift;
    return \@{ $self->{columnkeys} };
}


sub getColumns {
    my $self = shift;
    return \@{ $self->{columns} };
}


sub getCommand {
    my $self = shift;
    return $self->{command};
}


sub getCurrentPageNumber {
    my $self  = shift;
    my $first = $self->getFirstRecordIndex();
    my $limit = $self->getRecordsLimitation();
    if ( defined $first && $limit > 0 ) {
        return floor( $first / $limit ) + 1;
    }
    return $INDEX_NOT_FOUND;
}


sub getCurrentRecord {
    my $self = shift;
    return $self->{records}[ $self->{recordIndex} ]
        if $self->_hasCurrentRecord();
    return;
}


sub getFirstRecordIndex {
    my $self = shift;
    my $col  = $self->getColumn('FIRST');
    if ( defined $col ) {
        my $f = $col->getDataByIndex(0);
        if ( defined $f ) {
            return int $f;
        }
    }
    my $len = scalar @{ $self->{records} };
    return 0 if ( $len > 0 );
    return;
}


sub getLastRecordIndex {
    my $self = shift;
    my $col  = $self->getColumn('LAST');
    if ( defined $col ) {
        my $l = $col->getDataByIndex(0);
        if ( defined $l ) {
            return int $l;
        }
    }
    my $len = $self->getRecordsCount();
    if ( $len > 0 ) {
        return ( $len - 1 );
    }
    return;
}


sub getListHash {
    my $self = shift;
    my @lh   = ();
    foreach my $rec ( @{ $self->getRecords() } ) {
        push @lh, $rec->getData();
    }
    my $r = {
        LIST => \@lh,
        meta => {
            columns => $self->getColumnKeys(),
            pg      => $self->getPagination()
        }
    };
    return $r;
}


sub getNextRecord {
    my $self = shift;
    return $self->{records}[ ++$self->{recordIndex} ]
        if ( $self->_hasNextRecord() );
    return;
}


sub getNextPageNumber {
    my $self = shift;
    my $cp   = $self->getCurrentPageNumber();
    if ( $cp < 0 ) {
        return $INDEX_NOT_FOUND;
    }
    my $page  = $cp + 1;
    my $pages = $self->getNumberOfPages();
    return $page if ( $page <= $pages );
    return $pages;
}


sub getNumberOfPages {
    my $self  = shift;
    my $t     = $self->getRecordsTotalCount();
    my $limit = $self->getRecordsLimitation();
    if ( $t > 0 && $limit > 0 ) {
        return ceil( $t / $limit );
    }
    return 0;
}


sub getPagination {
    my $self = shift;
    my $r    = {
        COUNT        => $self->getRecordsCount(),
        CURRENTPAGE  => $self->getCurrentPageNumber(),
        FIRST        => $self->getFirstRecordIndex(),
        LAST         => $self->getLastRecordIndex(),
        LIMIT        => $self->getRecordsLimitation(),
        NEXTPAGE     => $self->getNextPageNumber(),
        PAGES        => $self->getNumberOfPages(),
        PREVIOUSPAGE => $self->getPreviousPageNumber(),
        TOTAL        => $self->getRecordsTotalCount()
    };
    return $r;
}


sub getPreviousPageNumber {
    my $self = shift;
    my $cp   = $self->getCurrentPageNumber();
    if ( $cp < 0 ) {
        return $INDEX_NOT_FOUND;
    }
    my $np = $cp - 1;
    return $np if ( $np > 0 );
    return $INDEX_NOT_FOUND;
}


sub getPreviousRecord {
    my $self = shift;
    return $self->{records}[ --$self->{recordIndex} ]
        if ( $self->_hasPreviousRecord() );
    return;
}


sub getRecord {
    my ( $self, $idx ) = @_;
    if ( $idx >= 0 && $self->getRecordsCount() > $idx ) {
        return $self->{records}[ $idx ];
    }
    return;
}


sub getRecords {
    my $self = shift;
    return \@{ $self->{records} };
}


sub getRecordsCount {
    my $self = shift;
    my $len  = scalar @{ $self->{records} };
    return $len;
}


sub getRecordsTotalCount {
    my $self = shift;
    my $col  = $self->getColumn('TOTAL');
    if ( defined $col ) {
        my $t = $col->getDataByIndex(0);
        if ( defined $t ) {
            return int $t;
        }
    }
    return $self->getRecordsCount();
}


sub getRecordsLimitation {
    my $self = shift;
    my $col  = $self->getColumn('LIMIT');
    if ( defined $col ) {
        my $l = $col->getDataByIndex(0);
        if ( defined $l ) {
            return int $l;
        }
    }
    return $self->getRecordsCount();
}


sub hasNextPage {
    my $self = shift;
    my $cp   = $self->getCurrentPageNumber();
    if ( $cp < 0 ) {
        return 0;
    }
    my $np = $cp + 1;
    if ( $np <= $self->getNumberOfPages() ) {
        return 1;
    }
    return 0;
}


sub hasPreviousPage {
    my $self = shift;
    my $cp   = $self->getCurrentPageNumber();
    if ( $cp < 0 ) {
        return 0;
    }
    my $pp = $cp - 1;
    if ( $pp > 0 ) {
        return 1;
    }
    return 0;
}


sub rewindRecordList {
    my $self = shift;
    $self->{recordIndex} = 0;
    return $self;
}


sub _hasColumn {
    my ( $self, $key ) = @_;
    my $idx = first_index { $_ eq $key } @{ $self->{columnkeys} };
    return ( $idx > $INDEX_NOT_FOUND );
}


sub _hasCurrentRecord {
    my $self = shift;
    my $len  = scalar @{ $self->{records} };
    return ( $len > 0 && $self->{recordIndex} >= 0 && $self->{recordIndex} < $len );
}


sub _hasNextRecord {
    my $self = shift;
    my $next = $self->{recordIndex} + 1;
    my $len  = scalar @{ $self->{records} };
    return ( $self->_hasCurrentRecord() && $next < $len );
}


sub _hasPreviousRecord {
    my $self = shift;
    return ( $self->{recordIndex} > 0 && $self->_hasCurrentRecord() );
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::Response - Library to provide accessibility to API response data.

=head1 SYNOPSIS

This module is internally used by the L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient> module.
To be used in the way:

    # specify the used API command (used for the request that responsed with $plain)
    $command = {
	    COMMAND => 'StatusAccount'
    };
  
    # specify the API plain-text response (this is just an example that won't fit to the command above)
    $plain = "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n";
  
    # create a new instance by
    $r = WebService::Hexonet::Connector::Response->new($plain, $command);

=head1 DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. This module manages all this: parsing data into hash format, into columns and records.
It provides different methods to access the data to fit your needs.

=head2 Methods

=over

=item C<new( $plain, $command )>

Returns a new L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> object.
Specify the plain-text API response by $plain.
Specify the used command by $command.

=item C<addColumn( $key, @data )>

Add a new column.
Specify the column name by $key.
Specify the column data by @data.
Returns the current L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> instance in use for method chaining.

=item C<addRecord( $hash )>

Add a new record.
Specify the row data in hash notation by $hash.
Where the hash key represents the column name.
Where the hash value represents the row value for that column.
Returns the current L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> instance in use for method chaining.

=item C<getColumn( $key )>

Get a column for the specified column name $key.
Returns an instance of L<WebService::Hexonet::Connector::Column|WebService::Hexonet::Connector::Column>.

=item C<getColumnIndex( $key, $index )> {

Get Data of the specified column $key for the given column index $index.
Returns a scalar.

=item C<getColumnKeys>

Get a list of available column names. NOTE: columns may differ in their data size.
Returns an array.

=item C<getCommand>

Get the command used within the request that resulted in this api response.
This is in general the command you provided in the constructor.
Returns a hash.

=item C<getCurrentPageNumber>

Returns the current page number we are in with this API response as int.
Returns -1 if not found.

=item C<getCurrentRecord>

Returns the current record of the iteration. It internally uses recordIndex as iterator index.
Returns an instance of L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record>.
Returns undef if not found.

=item C<getFirstRecordIndex>

Returns the first record index of this api response as int.
Returns undef if not found.

=item C<getLastRecordIndex>

Returns the last record index of this api response as int.
Returns undef if not found.

=item C<getListHash>

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

=item C<getNextRecord>

Returns the next record of the current iteration.
Returns an instance of L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record>.
Returns undef if not found.

=item C<getNextPageNumber>

Returns the number of the next api response page for the current request as int.
Returns -1 if not found.

=item C<getNumberOfPages>

Returns the total number of response pages in our API for the current request as int.

=item C<getPagination>

Returns paginator data of the current response / request.
Returns a hash.

=item C<getPreviousPageNumber>

Returns the number of the previous api response page for the current request as int.
Returns -1 if not found.

=item C<getPreviousRecord>

Returns the previous record of the current iteration.
Returns undef if not found otherwise an instance of L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record>.

=item C<getRecord( $index )>

Returns the record of the specified record index $index.
Returns undef if not found otherwise an instance of L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record>.

=item C<getRecords>

Returns a list of available records.
Returns an array of instances of L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record>.

=item C<getRecordsCount>

Returns the amount of returned records for the current request as int.

=item C<getRecordsTotalCount>

Returns the total amount of available records for the current request as int.

=item C<getRecordsLimitation>

Returns the limitation of the current request as int. LIMIT = ...
NOTE: Our system comes with a default limitation if you do not specify
a limitation in list commands to avoid data load in our systems.
This limitation is then returned in column "LIMIT" at index 0.

=item C<hasNextPage>

Checks if a next response page exists for the current query.
Returns boolean 0 or 1.

=item C<hasPreviousPage>

Checks if a previous response page exists for the current query.
Returns boolean 0 or 1.

=item C<rewindRecordList>

Resets the current iteration to index 0.

=item C<_hasColumn( $key )>

Private method. Checks if a column specified by $key exists.
Returns boolean 0 or 1.
	
=item C<_hasCurrentRecord>

Private method. Checks if the current record exists in the iteration.
Returns boolean 0 or 1.

=item C<_hasNextRecord>

Private method. Checks if the next record exists in the iteration.
Returns boolean 0 or 1.

=item C<_hasPreviousRecord>

Private method. Checks if the previous record exists in the iteration.
Returns boolean 0 or 1.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
