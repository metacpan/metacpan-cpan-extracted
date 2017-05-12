package XTaTIK::Model::Users;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;
use Digest;
use MIME::Base64;
use Data::Entropy::Algorithms qw/rand_bits/;

has [qw/pg/];

my @VALID_ROLES = sort qw/
    users
    products
/;

sub check {
    my ( $self, $login, $pass ) = @_;

    my $user = $self->get( $login );

    unless ( $user ) {
        # we don't want a possible attacker to know whether or not they
        # got the login right, just by seeing the page returns fast
        __hash(rand);
        return;
    }

    my ( $hash ) = __hash( $pass, $user->{salt} );
    return $user if $hash eq $user->{pass};
    return;
}

sub valid_roles {
    return @VALID_ROLES;
}

sub add {
    my $self = shift;
    my %values = __prepare_values( @_ );
    @values{qw/pass salt/} = __hash($values{pass});

    $self->pg->db->query(
        'INSERT INTO users (login, pass, salt, name, email, phone, roles)
            VALUES (?, ?, ?, ?, ?, ?, ?)',
        map $values{$_}, qw/login  pass  salt  name  email  phone  roles/,
    );

    return 1;
}

sub update {
    my $self = shift;
    my $id   = shift;
    my %values = __prepare_values( @_ );

    $self->pg->db->query(
        'UPDATE users SET
            login = ?, name = ?, email = ?, phone = ?, roles = ?
                WHERE id = ?',
        @values{qw/login  name  email  phone  roles/},
        $id,
    );
}

sub delete {
    my ( $self, $login ) = @_;
    $self->pg->db->query( 'DELETE FROM users WHERE login = ?', $login );
}

sub get {
    my ( $self, $login ) = @_;

    my $user = $self->pg->db->query(
        'SELECT * FROM users WHERE login = ?',
        lc($login) =~ s/^\s+|\s+$//gr,
    )->hash or return;

    $_ = +{ map +( $_ => 1 ), split /,/ } for $user->{roles};

    return $user;
}

sub get_all {
    my $self = shift;
    return $self->pg->db->query(
        'SELECT * FROM users ORDER BY login',
    )->hashes;
}

sub __hash {
    my ( $pass, $salt ) = @_;
    $salt = defined $salt ? decode_base64( $salt) : rand_bits 8*16;
    my $hash = Digest->new("Bcrypt")->cost(15)->salt( $salt )
    ->add( $pass )->hexdigest;
    return ( $hash, encode_base64 $salt, '' );
}

sub __prepare_values {
    my %values = @_;

    $_ //= '' for values %values;
    $values{roles} =~ s/^\s+|\s+$//g;
    $values{roles} =~ s/\s*,\s*/,/g;
    $values{login} = lc($values{login}) =~ s/^\s+|\s+$//gr;

    return %values;
}

1;

__END__

CREATE TABLE users (
    id      SERIAL PRIMARY KEY,
    login   TEXT,
    name    TEXT,
    email   TEXT,
    phone   TEXT,
    roles   TEXT
);