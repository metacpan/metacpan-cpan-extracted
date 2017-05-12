use Text::Shorten 'shorten_hash';
use Test::More tests => 28;
use strict;
use warnings;


for my $maxlen (100, 90, 80, 70, 60, 50, 40, 30, 20) {
    my @r = shorten_hash { 1001 .. 1200 }, $maxlen;
    my $r = join ",", map { join "=>", @$_ } @r;
    # print length($r), ":$r\n";
    ok(length($r) <= $maxlen)
	or diag("length($r) is ", length($r), " expected <= $maxlen ... $r");

    my @s = shorten_hash { 1..200 }, $maxlen, undef, undef, '61', '153';
    my $s = join ",", map { join "=>", @$_ } @s;
    ok(length($s) <= $maxlen)
	or diag("length($s) is ", length($s), " expected <= $maxlen ... $s");
    ok($s =~ /61=>62/ && $s =~ /153=>154/,
       "short hash includes key elements")
	or diag $s;


}

my @r = shorten_hash { 1001 .. 1200 }, 10;
my $r = join ",", map { join "=>", @$_ } @r;
ok(length($r) > 10 && length($r) < 20)
  or diag("length($r) is ", length($r), " expected betweem 10 and 20 ... $r");


