#!perl

use 5.010;
use warnings;

use Test::More;    # last test to print

my $unicorn       = qx'which unicorn 2>/dev/null';
my $unicorn_rails = qx'which unicorn_rails 2>/dev/null';

SKIP: {
    skip 'unicorn seems not to be installed. run `gem install unicorn` or fix your $PATH', 1
        unless ( $unicorn && $unicorn_rails );

    ok $unicorn,       "unicorn is in your \$PATH ($unicorn)";
    ok $unicorn_rails, "unicorn is in your \$PATH ($unicorn_rails)";
}

done_testing;
