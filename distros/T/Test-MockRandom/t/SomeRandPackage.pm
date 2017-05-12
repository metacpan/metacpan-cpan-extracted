package SomeRandPackage;

sub new {
    my $class = shift;
    return bless( {}, ref($class) || $class );
}

sub rand(;$) {
    my $rnd = CORE::rand;
    return $rnd;
}

1;
