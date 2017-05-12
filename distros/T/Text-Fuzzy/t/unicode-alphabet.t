use warnings;
use strict;
use utf8;
use Test::More;
binmode STDOUT, ":utf8";
use Text::Fuzzy;
my $agogo = 'アルベルトアインシュタイン';
my @words = qw/
ヒトアンシン
リヒテンシュタイン
ヒトアンシン
アイウエオカキクケコバビブベボハヒフヘホ
/;
my $tf = Text::Fuzzy->new ($agogo);
my $is = $tf->nearest (\@words);
cmp_ok ($is, '>=', 0, "Found in array");
is ($words[$is], 'リヒテンシュタイン', "Found best match");
is ($tf->last_distance, 7, "Found correct distance");
done_testing ();
