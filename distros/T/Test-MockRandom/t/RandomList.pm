package RandomList;

sub new {
    my ( $class, @items ) = @_;
    return bless( \@items, $class );
}

sub random {
    my ($self) = @_;
    return @$self ? $self->[ rand(@$self) ] : undef;
}

1;
