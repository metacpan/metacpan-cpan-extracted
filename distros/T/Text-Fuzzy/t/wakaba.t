use Test::More;
use warnings;
use strict;
use utf8;
use Text::Fuzzy;
binmode STDOUT, ":utf8";

my @words = ('ワカタ', 'ワカバ', 'ワカ');
my $tf = Text::Fuzzy->new ('ワカb');
my @nearest = $tf->nearest (\@words);
is (scalar @nearest, 3);
done_testing ();
