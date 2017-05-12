package SomePackage;

sub new {
    my $class = shift;
    return bless( {}, ref($class) || $class );
}

sub next_random {
    my $rnd = rand;
    return $rnd;
}

1;
