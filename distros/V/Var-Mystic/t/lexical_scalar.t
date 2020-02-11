use warnings;
use strict;

use Test::Effects;

plan tests => 1;

use Term::ANSIColor 'colorstrip';
use Var::Mystic;

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

    {
        track here $tracked;

        effects_ok { foo(\$untracked) };

        effects_ok { foo(\$tracked)   };

        effects_ok { $untracked = 9 };
        effects_ok { $tracked   = 9 }
                { scalar_return => 9,
                    stderr => sub {
                        my ($output) = colorstrip(shift);
                        like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                        like $output, qr/\n\$tracked = 9\n\n/;
                    }
                };
    }

    effects_ok { $untracked++ };
    effects_ok { $tracked++   };


    effects_ok { $untracked =~ s/0/00/ };

    track here $tracked;

    effects_ok { $tracked =~ s/0/00/   }
            { scalar_return => 1,
                stderr => sub {
                    my ($output) = colorstrip(shift);
                    like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                    like $output, qr/\n\$tracked = 100\n\n/;
                }
            };


};


done_testing();


