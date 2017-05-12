package XTaTIK::Model::Quote;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;
use XTaTIK::Model::Products;
use Mojo::Pg;
use JSON::Meth;

use experimental 'postderef';

my @ACCESSORS = qw/contents created_on
    address1  address2  city  email  lname  name  phone  province  zip/;

has [qw/pg/, @ACCESSORS ];

sub accessors {
    return @ACCESSORS;
}

sub new_quote {
    my $self = shift;
    # my $id   = shift;

    # $self->pg->db->query(
    #     'INSERT INTO quotes (id, created_on) VALUES (?, ?)',
    #     $id,
    #     time(),
    # );
    return $self;
}

sub save {
    my $self = shift;

    # $self->pg->db->query(
    #     'UPDATE quotes SET contents = ?, address1 = ?, address2 = ?,
    #             city = ?, email = ?, lname = ?, name = ?, phone = ?,
    #             province = ?, zip = ?
    #         WHERE id = ?',
    #     $self->contents->$j,
    #     map $self->$_, qw/address1  address2  city  email  lname  name
    #         phone  province  zip  id/,
    # );

    return $self;
}

1;
__END__