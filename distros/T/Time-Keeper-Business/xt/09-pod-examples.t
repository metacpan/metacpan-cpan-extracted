#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();

# Author test: the SYNOPSIS runs, its comments are the answers it gives,
# and the eg/ scripts run.

use Time::Keeper;
use Time::Keeper::Business;

my $pm = "$FindBin::Bin/../lib/Time/Keeper/Business.pm";
open my $fh, '<', $pm or die "$pm: $!";
my $pod = do { local $/; <$fh> };
my ($syn) = $pod =~ /^=head1 SYNOPSIS\n\n(.*?)^=head1/ms;
ok($syn, 'the SYNOPSIS is there');
my @lines = split /\n/, $syn;
my $code = join "\n", map { (my $l = $_) =~ s/^    //; $l } @lines;
my @checks;
for my $l (split /\n/, $code) {
    next unless $l =~ /^(\S.*?;)\s+#\s+(.+)$/;
    my ($stmt, $want) = ($1, $2);
    next if $want =~ /^\(/;
    push @checks, [ $stmt, $want ];
}
my @results;
my $harness = $code . "\n" . join("\n", map { "push \@results, [ q{$_->[0]}, scalar do { $_->[0] } ];" } @checks) . "\n1;";
ok(eval $harness, 'the SYNOPSIS runs') or diag $@;
my %got = map { $_->[0] => $_->[1] } @results;
for my $c (@checks) {
    my ($stmt, $want) = @$c;
    my $got = $got{$stmt};
    $got = "$got" if ref $got;
    if ($want =~ /^(\d{4}-\d\d-\d\dT\d\d:\d\d)/) { is(substr($got, 0, 16), $1, "$stmt gives $1") }
    elsif ($want =~ /^(\d{4}-\d\d-\d\d)/) { is(substr($got, 0, 10), $1, "$stmt gives $1") }
    else { is($got, $want, "$stmt gives $want") }
}

for my $eg (qw(uk us-federal target2 japan sweden)) {
    my $out = `"$^X" -Mblib "$FindBin::Bin/../eg/$eg.pl" 2027 2>&1`;
    is($?, 0, "eg/$eg.pl runs");
    like($out, qr/the ten business days after 2027-12-20:\n(?:  \d{4}-\d\d-\d\d  \w+\n){10}/, "  and prints ten business days");
}

done_testing;
