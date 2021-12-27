#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Tripletail qw(/dev/null);

# TL::MemorySentinel by design doesn't throw errors but instead dumps
# them to log. We want to inspect them here.
undef &Tripletail::log; # Suppress the "redefined" warning.
*Tripletail::log = sub {
    my $this = shift;
    diag(join(' ', @_));
};

my $mems;
lives_ok {
    $mems = $TL->getMemorySentinel();
} 'TL::getMemorySentinel()';

# getMemorySize() may return 0 if the platform isn't supported. But at
# least it must not die.
lives_and {
    my $size = $mems->getMemorySize;
    diag "Memory usage: $size KiB";
    like $size, qr/^[0-9]+$/;
} 'getMemorySize() returns something sane';

lives_ok {
    $mems->setPermissibleSize(foo => 10 * 1024);
    $mems->setPermissibleSize(bar => 20 * 1024);
} 'setPermissibleSize()';

lives_and {
    my $total = $mems->getTotalPermissibleSize();
    ok($total >= 30 * 1024);
} 'getTotalPermissibleSize()';
