# ex:ts=4:sw=4:sts=4:et
package Transmission::AttributeRole;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::AttributeRole - For Torrent and Client

=head1 DESCRIPTION

This role is used by L<Transmission::Client> and L<Transmission::Torrent>.
It requires the consuming class to provide the method C<read_all()>.

=cut

use Moose::Role;

=head1 ATTRIBUTES

=head2 client

 $obj = $self->client;

Returns a L<Transmission::Client> object.

=cut

has client => (
    is => 'ro',
    isa => 'Object',
    handles => { client_error => 'error' },
);

=head2 lazy_write

 $bool = $self->lazy_write;
 $self->lazy_write($bool);

Will prevent writeable attributes from sending a request to Transmission.
L</write_all()> can then later be used to sync data.

=cut

has lazy_write => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

=head2 eager_read

 $bool = $self->eager_read;

Setting this attribute in constructor forces L</read_all()> to be called.
This will again populate all (or most) attributes right after the object is
constructed (if Transmission answers the request).

=cut

has eager_read => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    trigger => sub { $_[0]->read_all if($_[1]) },
);

# this method name exists to prove a point - not to be readable...
sub _convert {
    if(ref $_[1] eq 'HASH') {
        for my $camel (keys %{ $_[1] }) {
            my $key = $_[2]->($camel);

            if(ref $_[1]->{$camel} eq 'HASH') {
                __PACKAGE__->_convert($_[1]->{$camel}, $_[2]);
            }

            $_[1]->{$key} = delete $_[1]->{$camel};
        }
    }
    else {
        return $_[2]->($_[1]);
    }
}

sub _camel2Normal {
    $_[0]->_convert( $_[1], sub {
        local $_ = $_[0];
        tr/-/_/;
        s/([A-Z]+)/{ "_" .lc($1) }/ge;
        return $_;
    } );
}
sub _normal2Camel {
    $_[0]->_convert( $_[1], sub {
        local $_ = $_[0];
        tr/_/-/;
        s/_(\w)/{ uc($1) }/ge; # wild guess...
        return $_;
    } );
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
