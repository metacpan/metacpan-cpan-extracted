use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Word::Rhymes;

use constant {
    SORT_BY_SCORE_DESC  => 0x00, # Default
    SORT_BY_SCORE_ASC   => 0x01,
    SORT_BY_ALPHA_DESC  => 0x02,
    SORT_BY_ALPHA_ASC   => 0x03,
};

my $mod = 'Word::Rhymes';
my $f = 't/data/zoo.data';
my $w = 'zoo';

#
# sort_by
#

# param
{
    # score_desc (default)
    {
        my $o = $mod->new(file => $f);
        my $d = $o->fetch($w)->{1};

        is $o->sort_by, SORT_BY_SCORE_DESC, "score_desc is the default ok";
        is $d->[0]{score}, 18213, "param: first sorted in score desc ok";
        is $d->[-1]{score}, 1, "param: last sorted in score desc ok";
    }

    # score_asc
    {
        my $o = $mod->new(file => $f, sort_by => 'score_asc');
        my $d = $o->fetch($w)->{1};

        is $o->sort_by, SORT_BY_SCORE_ASC, "score_asc set via param ok";
        is $d->[0]{score}, 1, "param: score_asc ok";
        is $d->[-1]{score}, 18213, "param: score asc ok";
    }

    # alpha_desc
    {
        my $o = $mod->new(file => $f, sort_by => 'alpha_desc');
        my $d = $o->fetch($w)->{1};

        is $o->sort_by, SORT_BY_ALPHA_DESC, "alpha_desc set via param ok";
        is $d->[0]{word}, 'zooplasty', "param: first sorted in alpha_desc ok";
        is $d->[-1]{word}, 'beu', "param: last sorted in alpha_desc ok";
    }

    # score_asc
    {
        my $o = $mod->new(file => $f, sort_by => 'alpha_asc');
        my $d = $o->fetch($w)->{1};

        is $o->sort_by, SORT_BY_ALPHA_ASC, "alpha_asc set via param ok";
        is $d->[0]{word}, 'beu', "param: score_asc ok";
        is $d->[-1]{word}, 'zooplasty', "param: score asc ok";
    }
}

# method
{
    my $o = $mod->new(file => $f);
    my $d;

    is eval { $o->sort_by('blah'); 1 }, undef, "bad param croaks ok";

    $o->sort_by('score_asc');

    is $o->sort_by, SORT_BY_SCORE_ASC, "alpha_asc set via method ok";
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{score}, 1, "method: score_asc ok";
    is $d->[-1]{score}, 18213, "method: score asc ok";

    $o->sort_by('alpha_desc');

    is $o->sort_by, SORT_BY_ALPHA_DESC, "alpha_desc set via method ok";
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{word}, 'zooplasty', "method: first sorted in alpha_desc ok";
    is $d->[-1]{word}, 'beu', "method: last sorted in alpha_desc ok";

    $o->sort_by('alpha_asc');

    is $o->sort_by, SORT_BY_ALPHA_ASC, "alpha_asc set via method ok";
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{word}, 'beu', "method: first sorted in alpha_asc ok";
    is $d->[-1]{word}, 'zooplasty', "method: last sorted in alpha_asc ok";
}

done_testing;
