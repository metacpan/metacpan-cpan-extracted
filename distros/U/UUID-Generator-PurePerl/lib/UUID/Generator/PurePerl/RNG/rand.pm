package UUID::Generator::PurePerl::RNG::rand;

use strict;
use warnings;

use base qw( UUID::Generator::PurePerl::RNG::Bridge );

sub enabled { 1 }

sub new {
    my $class = shift;
    my $seed  = shift;
    $seed = time if ! defined $seed;

    my $me = q{};
    my $self = \$me;

    srand $seed;

    return bless $self, $class;
}

sub rand_32bit {
    my $v1 = int(rand(65536)) % 65536;
    my $v2 = int(rand(65536)) % 65536;
    return ($v1 << 16) | $v2;
}

1;
__END__
