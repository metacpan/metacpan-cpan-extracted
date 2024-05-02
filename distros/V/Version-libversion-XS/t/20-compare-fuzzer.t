#!perl -T

use strict;
use warnings;

use Test::More;

use Version::libversion::XS qw(:all);


if ($ENV{SKIP_FUZZER}) {
    plan(skip_all => "Fuzzer tests skipped");
}

# Taken from libversion/tests/compare_fuzzer.c

my @version_chars = ('0', '1', 'p', 'R', 'e', '.', '-');

my @samples = ("0", "1", "a", "r", "z", "1alpha1", "1patch1");

for (my $i0 = 0; $i0 < scalar @version_chars; $i0++) {
    for (my $i1 = 0; $i1 < scalar @version_chars; $i1++) {
        for (my $i2 = 0; $i2 < scalar @version_chars; $i2++) {
            for (my $i3 = 0; $i3 < scalar @version_chars; $i3++) {
                for (my $i4 = 0; $i4 < scalar @version_chars; $i4++) {

                    my $v1 = join '', $version_chars[$i1], $version_chars[$i2], $version_chars[$i3],
                        $version_chars[$i4];

                    for (my $isample = 0; $isample < scalar @samples; $isample++) {

                        my $v2   = $samples[$isample];
                        my $res  = version_compare2($v1, $v2);
                        my $test = sprintf("%s %s %s", $v1, (($res == 0) ? '=' : ($res < 0) ? '<' : '>'), $v2);

                        ok(($res == -1 || $res == 0 || $res == 1), $test);

                    }

                }
            }
        }
    }
}

done_testing();
