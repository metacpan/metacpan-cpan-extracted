package MyConstraint;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub check { 1 }

1;
