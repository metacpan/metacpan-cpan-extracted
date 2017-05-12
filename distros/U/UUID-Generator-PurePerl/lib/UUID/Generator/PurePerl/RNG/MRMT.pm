package UUID::Generator::PurePerl::RNG::MRMT;

use strict;
use warnings;

use base qw( UUID::Generator::PurePerl::RNG::Bridge );

BEGIN {
    eval q{ use Math::Random::MT };
    if ($@) {
        *enabled = sub { 0 };
    }
    else {
        *enabled = sub { 1 };
    }
}

sub new {
    my $class = shift;
    my $seed  = shift;

    $seed = $class->gen_seed_32bit() if ! defined $seed;

    if ($class->enabled) {
        my $mt = Math::Random::MT->new($seed);
        my $self = \$mt;
        return bless $self, $class;
    }
    else {
        my $u = undef;
        my $self = \$u;
        return bless $self, $class;
    }
}

sub rand_32bit {
    my $self = shift;
    my $mt = $$self;
    return 0 if ! $mt;

    return int($mt->rand() * 65536.0 * 65536);
}

1;
__END__
