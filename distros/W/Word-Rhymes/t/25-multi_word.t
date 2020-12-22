use warnings;
use strict;

use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# multi_word
#

# new param default
{
    my $o = $mod->new;
    is $o->multi_word, 0, "default multi_word ok";
}

# new param set
{
    my $o = $mod->new(multi_word => 1);
    is $o->multi_word, 1, 'multi_word param set ok';
}

# method
{
    my $o = $mod->new;

    is
        $o->multi_word(1),
        1,
        "multi_word() set ok";
}

# counts
{
    # no multi_word (default)
    {
        my $data = $mod->new(file => 't/data/zoo.data')->fetch('zoo');

        my $c;

        for my $syl (keys %$data) {
            $c += scalar @{ $data->{$syl} };
        }

        is $c, 383, "without multi_word, word count ok";
    }

    # multi_word
    {
        my $data = $mod->new(file => 't/data/zoo.data', multi_word => 1)->fetch('zoo');

        my $c;

        for my $syl (keys %$data) {
            $c += scalar @{ $data->{$syl} };
        }

        is $c, 699, "with multi_word, word count ok";
    }
}

done_testing;