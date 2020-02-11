use warnings;
use strict;

use Test::Effects;

plan tests => 1;

use Term::ANSIColor 'colorstrip';
no Var::Mystic;

effects_ok {
    my $untracked;
    my $tracked;

    effects_ok { $untracked = 0 };

    effects_ok { $tracked   = 0 }
            { scalar_return => 0 };

    sub foo {
        my ($varref) = @_;
        $$varref = 'foo';
    }

    track $tracked;

    effects_ok { foo(\$untracked) };

    effects_ok { foo(\$tracked)   }
            { scalar_return => 'foo' };

    effects_ok { $untracked = 9 };
    effects_ok { $tracked   = 9 }
            { scalar_return => 9 };

    effects_ok { $untracked++ };
    effects_ok { $tracked++   }
            { scalar_return => 9 };


    effects_ok { $untracked =~ s/0/00/ };

    effects_ok { $tracked =~ s/0/00/   }
            { scalar_return => 1 };


};


done_testing();

