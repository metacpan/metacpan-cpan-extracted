package # hide from PAUSE
    TN0;

sub new {
    my $class = shift;
    my %attrs = @_;
    $attrs{parent} //= undef;
    $attrs{children} //= [];
    bless \%attrs, $class;
}

sub parent {
    my $self = shift;
    if (@_) {
        $self->{parent} = $_[0];
    }
    $self->{parent};
}

sub children {
    my $self = shift;

    if (@_) {
        if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
            $self->{children} = $_[0];
        } else {
            $self->{children} = \@_;
        }
    }

    # we deliberately do this for testing, to make sure that the node methods
    # can work with both children returning arrayref or list
    if (rand() < 0.5) {
        return $self->{children};
    } else {
        return @{ $self->{children} };
    }
}

1;
