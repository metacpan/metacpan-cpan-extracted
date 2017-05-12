use strict;
use warnings;
use Text::KyTea;
use Test::More;

my $kytea = Text::KyTea->new(
    model  => './model/test.mod',
    tagmax => 1,
);

tagmax_test( $kytea->parse("コーパスの文です。") );
tagmax_test( $kytea->parse("もうひとつの文です。") );
is($kytea->pron("コーパスの文です。"), 'こーぱすのぶんです。');

done_testing;


sub tagmax_test
{
    my $results = shift;

    for my $result (@{$results})
    {
        my $pos_tag = $result->{tags}[0];
        is(scalar @{$pos_tag}, 1);

        my $pron_tag = $result->{tags}[1];
        is(scalar @{$pron_tag}, 1);
    }
}
