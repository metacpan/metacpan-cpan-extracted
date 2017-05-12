use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Devel::CodeObserver';
use t::Util;
use File::Spec;
use Test::Base::Less;
use File::Path;
use File::Basename;
use File::Temp;

for my $xt (glob('t/cases/*.xt')) {
    (my $expected = $xt) =~ s/\.xt\z/.expected/;
    (my $required = $xt) =~ s/\.xt\z/.required/;

    if (-f $required) {
        eval slurp($required);
        if ($@) {
            diag "Skipped: $xt";
            next;
        }
    }

    my $got = run_test($xt);
    is($got, slurp_utf8($expected));
}

pass 'done all tests';

done_testing;

