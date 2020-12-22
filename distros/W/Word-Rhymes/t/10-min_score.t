use warnings;
use strict;

use Test::More;
use JSON;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# min_score
#

# new param default
{
    my $o = $mod->new;
    is $o->min_score, 0, "default min_score ok";
}

# new param wrong type
{
    is
        eval {$mod->new(min_score => 'aaa'); 1},
        undef,
        'min_score param croaks if not int ok';

    like $@, qr/min_score must be an integer/, "...and error is sane";
}

# new param too high
{
    is
        eval {$mod->new(min_score => 1000001); 1},
        undef,
        'min_score param croaks if over 1,000,000 ok';

    like $@, qr/min_score must be between/, "...and error is sane";
}

# new param too low
{
    is
        eval {$mod->new(min_score => -1); 1},
        undef,
        'min_score param croaks if under 0 ok';

    like $@, qr/min_score must be between/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->min_score('aaa'); 1},
        undef,
        "min_score() croaks on non int ok";

    like $@, qr/min_score must be an integer/, "...and error is sane";

    is
        eval {$o->min_score(-1); 1},
        undef,
        "min_score() croaks if param < 0 ok";

    like $@, qr/must be between/, "...and error is sane";

    is
        eval {$o->min_score(1000001); 1},
        undef,
        "min_score() croaks if param > 1,000,000 ok";

    like $@, qr/must be between/, "...and error is sane";

    for (1..500, 10000..11000, 999900..1000000) {
        is $o->min_score($_), $_, "min_score with $_ ok";
    }
}

# check data
{
    my $j;
    {
        local $/;
        open my $fh, '<', 't/data/zoo.data' or die $!;
        $j = <$fh>;
    }

    my $p = decode_json $j;

    is scalar @$p, 803, "number of original matches ok";

    my $o = $mod->new(file => 't/data/zoo.data');

    is get_count($o), 383, "default min_score count ok";

    $o->min_score(100);
    is get_count($o), 278, "min_score 100 count ok";

    $o->min_score(500);
    is get_count($o), 147, "min_score 500 count ok";

    $o->min_score(1000);
    is get_count($o), 73, "min_score 1000 count ok";

    $o->min_score(2000);
    is get_count($o), 21, "min_score 2000 count ok";

    $o->min_score(3000);
    is get_count($o), 11, "min_score 3000 count ok";

    $o->min_score(5000);
    is get_count($o), 4, "min_score 5000 count ok";

    $o->min_score(10000);
    is get_count($o), 1, "min_score 10000 count ok";
}

sub get_count {
    my ($o) = @_;

    my $data = $o->fetch('zoo');

    my $count = 0;

    for my $syl (keys %$data) {
        $count += scalar @{ $data->{$syl} };
    }

    return $count;
}

done_testing;