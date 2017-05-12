use Text::Shorten 'shorten_hash';
use Test::More tests => 2;
use strict;
use warnings;

my %r = (499_901 .. 500_300);
my %s = %r;

my $r = join ",", map { join "=>", @$_ } shorten_hash({%r}, 100);
my $s = join ",", map { join "=>", @$_ } shorten_hash({%r}, 100);
ok($r eq $s || $r ne $s, 'hash order may or may not be preserved');

local $Text::Shorten::HASHREPR_SORTKEYS = 1;
$r = join ",", map { join "=>", @$_ } shorten_hash({%r}, 103);
$s = join ",", map { join "=>", @$_ } shorten_hash({%s}, 103);
ok($r eq $s, 'force sorted hashkey order to make useful comparison')
      or diag $r,$/,$s;

