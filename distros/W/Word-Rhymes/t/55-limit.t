use warnings;
use strict;

use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

# new param default
{
    my $o = $mod->new;
    is $o->limit, 1000, "default limit ok";
}

# new param wrong type
{
    is
        eval {$mod->new(limit => 'aaa'); 1},
        undef,
        'limit param croaks if not int ok';

    like $@, qr/limit must be an integer/, "...and error is sane";
}

# new param too high
{
    is
        eval {$mod->new(limit => 1001); 1},
        undef,
        'limit param croaks if over 1000 ok';

    like $@, qr/limit must be between/, "...and error is sane";
}

# new param too low
{
    is
        eval {$mod->new(limit => 0); 1},
        undef,
        'limit param croaks if under 1 ok';

    like $@, qr/limit must be between/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->limit('aaa'); 1},
        undef,
        "limit() croaks on non int ok";

    like $@, qr/limit must be an integer/, "...and error is sane";

    is
        eval {$o->limit(0); 1},
        undef,
        "limit() croaks if param < 1 ok";

    like $@, qr/must be between/, "...and error is sane";

    is
        eval {$o->limit(1001); 1},
        undef,
        "limit() croaks if param > 1000 ok";

    like $@, qr/must be between/, "...and error is sane";

    for (1..1000) {
        is $o->limit($_), $_, "limit with $_ ok";
    }
}

# count
{
    if ($ENV{RELEASE_TESTING} || $ENV{WORD_RHYMES_INTERNET}) {

        my $o = $mod->new;

        # default
        {
            my $d = $o->fetch('zoo');

            my $count = 0;

            for my $syl (keys %$d) {
                $count += scalar @{$d->{$syl}};
            }

            is $count > 300, 1, "limit default count ok";
        }

        # limit 10
        {
            $o->limit(10);

            my $d = $o->fetch('zoo');

            my $count = 0;

            for my $syl (keys %$d) {
                $count += scalar @{$d->{$syl}};
            }

            is scalar @{ $d->{1} }, 10, "limit 10 for syl 1 values ok";
            is scalar @{ $d->{2} }, 10, "limit 10 for syl 2 values ok";
            is scalar @{ $d->{3} }, 10, "limit 10 for syl 3 values ok";
            is scalar @{ $d->{4} }, 8, "limit 10 for syl 4 values ok";
            is scalar @{ $d->{5} }, 1, "limit 10 for syl 5 values ok";

            is $count, 39, "limit set to 10 total count ok";
        }
    }
}

done_testing;