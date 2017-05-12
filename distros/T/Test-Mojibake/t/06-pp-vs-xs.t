#!perl -T
use strict;
use warnings qw(all);

use Test::More;

## no critic (ProhibitPackageVars, ProtectPrivateSubs)

BEGIN {
    use_ok('Benchmark', 'countit');
    use_ok('Test::Mojibake');
}

unless ($Test::Mojibake::use_xs) {
    diag('No XS module detected, will fallback to PP implementation!');
    done_testing(2);
    exit;
}

our @buf;
our $err = 0;
for (qw(latin1.pl ascii.pod utf8.pl_)) { # _detect_utf8() to return qw(0 1 2)
    local $/ = undef;
    ok(open(my $fh, '<:raw', 't/good/' . $_), "opening $_ test");
    push @buf, <$fh>;
    close $fh;
}

my $time = 1.0;
my $t0 = countit($time, '&run()');
$Test::Mojibake::use_xs = 0;
my $t1 = countit($time, '&run()');

ok($err == 0, 'correct encoding matches');
ok($t0->iters > $t1->iters, 'XS faster than PP');

diag(sprintf('XS/PP speed ratio is %0.2f', $t0->iters / $t1->iters));

done_testing(7);

sub run {
    my $i = 0;
    for (@buf) {
        my $j = Test::Mojibake::_detect_utf8(\$_);
        ++$err if $i != $j;
    } continue {
        ++$i;
    }

    return;
}
