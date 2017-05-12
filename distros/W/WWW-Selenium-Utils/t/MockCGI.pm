package MockCGI;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = \%args;
    bless $self, $class;
    return $self;
}

sub param { $_[0]->{$_[1]} }

1;
