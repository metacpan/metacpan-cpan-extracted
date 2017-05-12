package XTaTIK::Model::XVars;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;
use Mojo::Pg;
use Carp;

has [qw/pg/];

my %VARS = (
    hot_products => \&_var_hot_products,
);

sub get { goto \&set } # 'set' functions as 'get' when value is undefined
sub set {
    my ( $self, $var, $value ) = @_;
    $VARS{$var} or croak "[$var] is not a valid XVar";
    return $VARS{$var}->( $self, $var, $value );
}

sub _var_hot_products {
    my ( $self, $var, $value ) = @_;
    defined $value and $value = join "\n", split ' ', $value;
    return $self->_generic($var, $value);
}

sub _generic {
    my ( $self, $var, $value ) = @_;

    if ( defined $value ) {
        return $self->pg->db->query(
            'UPDATE xvars SET value = ? WHERE name = ?',
            $value,
            $var,
        );
    }

    return $self->pg->db->query(
        'SELECT value FROM xvars WHERE name = ?',
        $var,
    )->hash->{value};
}

1;

__END__

CREATE TABLE xvars (
    name TEXT,
    value TEXT
)