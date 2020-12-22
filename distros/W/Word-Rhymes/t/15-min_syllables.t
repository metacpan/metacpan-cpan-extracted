use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# min_syllables
#

# new param default
{
    my $o = $mod->new;
    is $o->min_syllables, 1, "default min_syllables ok";
}

# new param wrong type
{
    is
        eval {$mod->new(min_syllables => 'aaa'); 1},
        undef,
        'min_syllables param croaks if not int ok';

    like $@, qr/min_syllables must be an integer/, "...and error is sane";
}

# new param too high
{
    is
        eval {$mod->new(min_syllables => 101); 1},
        undef,
        'min_syllables param croaks if over 100 ok';

    like $@, qr/min_syllables must be between/, "...and error is sane";
}

# new param too low
{
    is
        eval {$mod->new(min_syllables => 0); 1},
        undef,
        'min_syllables param croaks if under 1 ok';

    like $@, qr/min_syllables must be between/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->min_syllables('aaa'); 1},
        undef,
        "min_syllables() croaks on non int ok";

    like $@, qr/min_syllables must be an integer/, "...and error is sane";

    is
        eval {$o->min_syllables(0); 1},
        undef,
        "min_syllables() croaks if param < 1 ok";

    like $@, qr/must be between/, "...and error is sane";

    is
        eval {$o->min_syllables(101); 1},
        undef,
        "min_syllables() croaks if param > 100 ok";

    like $@, qr/must be between/, "...and error is sane";

    for (1..100) {
        is $o->min_syllables($_), $_, "min_syllables with $_ ok";
    }
}

# data
{
    my $o = $mod->new(file => 't/data/zoo.data');

    is keys %{ $o->fetch('zoo') }, 5, "default min_syllables ok";

    $o->min_syllables(4);
    is keys %{ $o->fetch('zoo') }, 2, "min_syllables set to '4' ok";

    $o->min_syllables(3);
    is keys %{ $o->fetch('zoo') }, 3, "min_syllables set to '3' ok";

    $o->min_syllables(2);
    is keys %{ $o->fetch('zoo') }, 4, "min_syllables set to '2' ok";

    $o->min_syllables(1);
    is keys %{ $o->fetch('zoo') }, 5, "min_syllables set to '1' ok";
}

done_testing;