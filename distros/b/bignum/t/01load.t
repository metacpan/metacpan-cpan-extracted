# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('bigint');
    use_ok('bigfloat');
    use_ok('bigrat');
    use_ok('bignum');
};

# Main modules for various distributions.

my @mods = ('bignum',
            'Math::BigInt',
            'Math::BigRat',
            'Math::BigInt::Lite',
            );

diag("");
diag("Testing with Perl $], $^X");
diag("");
diag(sprintf("%12s %s\n", 'Version', 'Module'));
diag(sprintf("%12s %s\n", '-------', '------'));
for my $mod (@mods) {
    eval "require $mod";
    my $ver = $@ ? '-' : $mod -> VERSION();
    diag(sprintf("%12s %s\n", $ver, $mod));
}
diag("");
