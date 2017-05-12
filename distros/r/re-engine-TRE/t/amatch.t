use strict;
use utf8;
use warnings qw(all);

no if ($] >= 5.017010), warnings => q(experimental);

use Test::More tests => 8;

open(my $fh, q(<), q(t/words));
my @words = <$fh>;
close $fh;
chomp @words;

ok(
    $#words == 28,
    q(dictionary complete),
);

{
    use re::engine::TRE max_cost => 1;
    ok(
        [qw[
            appeal
            dispel
            erlangen
            hyperbola
            merlin
            parlance
            pearl
            perk
            superappeal
            superlative
        ]] ~~ [ grep /perl/, @words ],
        q(case-sensitive, within cost=1),
    );
};

{
    use re::engine::TRE max_cost => 1;
    ok(
        [qw[
            appeal
            dispel
            erlangen
            hyperbola
            merlin
            parlance
            Pearl
            pearl
            perk
            superappeal
            superlative
        ]] ~~ [ grep /perl/i, @words ],
        q(case-insensitive, within cost=1),
    );
};

{
    use re::engine::TRE (
        cost_ins    => -1,
        max_cost    => 1,
    );
    ok(
        [qw[
            appeal
            dispel
            erlangen
            hyperbola
            merlin
            parlance
            perk
            superappeal
            superlative
        ]] ~~ [ grep /perl/, @words ],
        q(no insertions),
    );
};

{
    use re::engine::TRE (
        cost_del    => -1,
        max_cost    => 1,
    );
    ok(
        [qw[
            appeal
            hyperbola
            merlin
            parlance
            pearl
            perk
            superappeal
            superlative
        ]] ~~ [ grep /perl/, @words ],
        q(no deletions),
    );
};

{
    use re::engine::TRE (
        cost_subst  => -1,
        max_cost    => 1,
    );
    ok(
        [qw[
            dispel
            erlangen
            hyperbola
            merlin
            pearl
            perk
            superappeal
            superlative
        ]] ~~ [ grep /perl/, @words ],
        q(no substitutions),
    );
};

{
    use re::engine::TRE max_cost => 2;
    ok(
        [qw[
            aberrant
            accelerate
            appeal
            dispel
            erlangen
            felicity
            gibberish
            hyperbola
            iterate
            legerdemain
            merlin
            mermaid
            oatmeal
            park
            parlance
            Pearl
            pearl
            perk
            petal
            superappeal
            superlative
            supple
            twirl
            zealous
        ]] ~~ [ grep /perl/, @words ],
        q(case-sensitive, within cost=2),
    );
};

{
    use re::engine::TRE max_cost => 2;
    my $haystack = 'xyz' x 10 . 'abc0defghijabc1defghij' . 'zyx' x 10;
    my $needle = 'abcdefghij' x 2;
    ok(
        $haystack =~ /$needle/,
        q(long pattern),
    );
};
