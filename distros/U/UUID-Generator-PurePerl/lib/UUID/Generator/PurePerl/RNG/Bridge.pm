package UUID::Generator::PurePerl::RNG::Bridge;

use strict;
use warnings;

use Digest;

sub gen_seed_32bit {
    my $d = Digest->new('MD5');
    $d->add(pack('I', time));
    my $r = $d->digest;
    my $x = 0;
    while (length $r > 0) {
        $x ^= unpack 'I', substr($r, 0, 4, q{});
    }
    return $x;
}

sub rand_32bit;

1;
__END__
