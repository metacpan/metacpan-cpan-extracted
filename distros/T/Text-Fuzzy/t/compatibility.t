use warnings;
use strict;
use Test::More tests => 2;
use Text::Fuzzy;
use utf8;
SKIP: {
    eval {
	require Text::Levenshtein::Damerau::XS;
    };
    if ($@) {
	skip "Text::Levenshtein::Damerau not installed", 2;
    }
    compare ('ハルベルト', 'バババブアルベルト');
    compare ('アルベルトアインシュタイン', 'リヒテンシュタイン');
}
exit;

sub compare
{
    my ($left, $right) = @_;
    my $tld = Text::Levenshtein::Damerau::XS::xs_edistance ($left, $right);
    my $tf = Text::Fuzzy->new ($left);
    my $d = $tf->distance ($right);
    is ($tld, $d, "Same values with tld and tf");
}


