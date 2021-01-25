package WebService::Hexonet::Connector::Column;

use 5.030;
use strict;
use warnings;

use version 0.9917; our $VERSION = version->declare('v2.10.1');


sub new {
    my ( $class, $key, @data ) = @_;
    my $self = {};
    $self->{key} = $key;
    @{ $self->{data} } = @data;
    $self->{length} = scalar @data;
    return bless $self, $class;
}


sub getKey {
    my $self = shift;
    return $self->{key};
}


sub getData {
    my $self = shift;
    return $self->{data};
}


sub getDataByIndex {
    my $self = shift;
    my $idx  = shift;
    return $self->{data}[ $idx ]
        if $self->hasDataIndex($idx);
    return;
}


sub hasDataIndex {
    my $self = shift;
    my $idx  = shift;
    return $idx < $self->{length};
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::Column - Library to cover API response data in column-based way.

=head1 SYNOPSIS

This module is internally used by the L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> module.
To be used in the way:

    # specify the column name
    $key = "DOMAIN";

    # specify the column data as array
    @data = ('mydomain.com', 'mydomain.net');

    # create a new instance by
    $col = WebService::Hexonet::Connector::Column->new($key, @data);

=head1 DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. For simplifying data access we created this library and also the Record library
to provide an additional and more customerfriendly way to access data. Previously getHash and
getListHash were the only possibilities to access data in Response library.

=head2 Methods

=over

=item C<new( $key, @data )>

Returns a new L<WebService::Hexonet::Connector::Column|WebService::Hexonet::Connector::Column> object.
Specify the column name in $key and the column data in @data.

=item C<getKey>

Returns the column name as string.

=item C<getData>

Returns the full column data as array.

=item C<getDataByIndex( $index )>

Returns the column data of the specified index as scalar.
Returns undef if not found.

=item C<hasDataIndex( $index )>

Checks if the given index exists in the column data.
Returns boolean 0 or 1.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
