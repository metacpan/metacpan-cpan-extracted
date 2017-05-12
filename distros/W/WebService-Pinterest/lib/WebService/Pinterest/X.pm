
package WebService::Pinterest::Spec::X;
$WebService::Pinterest::Spec::X::VERSION = '0.1';
use overload '""' => \&as_string;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    bless shift(), $class;
}

sub throw {
    die shift->new(shift);
}

# key
# value
# message

sub as_string {
    my $self = shift;
    return sprintf $self->{message}, $self->{key}, $self->{value};
}

1;

