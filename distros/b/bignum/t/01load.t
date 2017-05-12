#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('bignum');
    use_ok('bigint');
    use_ok('bigrat');
};

my @mods = ('bignum',
            'bigint',
            'bigrat',
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
