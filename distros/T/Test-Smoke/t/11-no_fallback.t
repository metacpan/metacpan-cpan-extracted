#! perl -w
use strict;

use Test::More 'no_plan';

use Config;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions;

{
    my ($base, @tree, @inc);
    BEGIN {
        @inc = @INC;
        $base = catdir('t', 'fallback');
        @tree = ($base);
        push @tree, catdir($base, $Config{archname}, 'auto');
        push @tree, catdir($base, $Config{archname});
        push @tree, catdir($base, $Config{version});
        push @tree, catdir($base, $Config{version}, $Config{archname});
        mkpath($_) for @tree;
    }
    use fallback 't/fallback';

    no fallback 't/fallback';
    # We only need to test that the elements of @tree are no longer in @INC
    my @seen;
    for my $dir (@tree) {
        push @seen, $dir if grep $_ eq $dir, @INC;
    }
    is(scalar @seen, 0, "No fallback directories left behind");

    rmtree($base);
}
#done_testing();

