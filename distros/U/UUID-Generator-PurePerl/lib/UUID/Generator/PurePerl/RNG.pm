package UUID::Generator::PurePerl::RNG;

use strict;
use warnings;

my $singleton;
sub singleton {
    my $class = shift;

    if (! defined $singleton) {
        $singleton = $class->new(@_);
    }

    return $singleton;
}

sub new {
    shift;  # class

    my @classes = qw(
        UUID::Generator::PurePerl::RNG::MRMT
        UUID::Generator::PurePerl::RNG::MRMTPP
        UUID::Generator::PurePerl::RNG::rand
    );

    foreach my $class (@classes) {
        next if ! eval qq{ require $class };

        next if ! $class->enabled;

        return $class->new();
    }

    return;
}

1;
__END__
