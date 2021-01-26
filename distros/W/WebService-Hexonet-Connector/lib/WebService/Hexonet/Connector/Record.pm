package WebService::Hexonet::Connector::Record;

use 5.030;
use strict;
use warnings;

use version 0.9917; our $VERSION = version->declare('v2.10.2');


sub new {
    my ( $class, $data ) = @_;
    return bless { data => $data }, $class;
}


sub getData {
    my $self = shift;
    return $self->{data};
}


sub getDataByKey {
    my $self = shift;
    my $key  = shift;
    return $self->{data}->{$key}
        if $self->hasData($key);
    return;
}


sub hasData {
    my $self = shift;
    my $key  = shift;
    return defined $self->{data}->{$key};
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::Record - Library to cover API response data in row-based way.

=head1 SYNOPSIS

This module is internally used by the L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> module.
To be used in the way:

    # specify the row data in hash notation
    $data = { DOMAIN => 'mydomain.com',  NAMESERVER0 => 'ns1.mydomain.com' };

    # create a new instance by
    $rec = WebService::Hexonet::Connector::Record->new($data);

=head1 DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful
data structure. For simplifying data access we created this library and also the Column library
to provide an additional and more customerfriendly way to access data. Previously getHash and
getListHash were the only possibilities to access data in Response library.


=head2 Methods

=over

=item C<new( $data )>

Returns a new L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record> object.
Specifiy the row data in hash notation as $data.

=item C<getData>

Returns the whole row data as hash.

=item C<getDataByKey( $key )>

Returns the row data for the specified column name as $key as scalar.
Returns undef if not found.

=item C<hasData( $key )>

Checks if the column specified by $key exists in the row data.
Returns boolean 0 or 1.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
