use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use Test::Requires { 'Devel::CodeObserver' => '0.10' };
use t::Util;
use Text::Diff;

for my $file (sort <eg/*.t>) {
    for my $reporter (qw(Spec TAP)) {
        for my $power (qw(0 1)) {
            note "$file $reporter";
            local $ENV{KANTAN_REPORTER} = $reporter;
            local $ENV{KANTAN_NOOBSERVER} = $power ? 0 : 1;
            (my $outfile = $file) =~ s/\.t\z/-${reporter}-${power}.out/;
            my $expected = slurp_utf8($outfile);

            my $out = run_test($file);
            $out =~ s/\A\n*//;
            $expected =~ s/\A\n*//;

            ok($out eq $expected, $outfile) or diag(diff(\$out, \$expected));
        }
    }
}

done_testing;
