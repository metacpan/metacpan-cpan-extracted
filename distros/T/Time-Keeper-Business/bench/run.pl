#!perl
use strict;
use warnings;

# Runs every benchmark from the dist's top and says how many marks were missed.
my @scripts = sort glob('bench/[0-9][0-9]-*.pl');
my ($fail, @lines) = (0);
for my $s (@scripts) {
    my $out = `"$^X" -Mblib $s 2>&1`;
    $fail++ if $?;
    print $out;
    push @lines, grep { /^(PASS|FAIL|SKIP)/ } split /\n/, $out;
}
my $f = grep { /^FAIL/ } @lines;
printf "\n%d marks, %d missed\n", scalar(grep { /^(PASS|FAIL)/ } @lines), $f;
exit($fail ? 1 : 0);
