use warnings;
use strict;

use Test::Effects;

plan tests => 1;

use Term::ANSIColor 'colorstrip';
use Var::Mystic;

effects_ok {
          my $untracked;
    track my $tracked;

    effects_ok { $untracked = 0 };

    effects_ok { $tracked   = 0 }
            { scalar_return => 0,
                stderr => sub {
                    my ($output) = colorstrip(shift);
                    like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                    like $output, qr/\n\$tracked = 0\n\n/;
                }
            };

    sub foo {
        my ($varref) = @_;
        $$varref = 'foo';
    }

    effects_ok { foo(\$untracked) };

    effects_ok { foo(\$tracked)   }
            { scalar_return => 'foo',
                stderr => sub {
                    my ($output) = colorstrip(shift);
                    like $output, qr/\A\#line ${\(__LINE__ - 9)}/;
                    like $output, qr/\n\$tracked = "foo"\n\n/;
                }
            };


    effects_ok { $untracked = 9 };
    effects_ok { $tracked   = 9 }
            { scalar_return => 9,
                stderr => sub {
                    my ($output) = colorstrip(shift);
                    like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                    like $output, qr/\n\$tracked = 9\n\n/;
                }
            };

    effects_ok { $untracked++ };
    effects_ok { $tracked++   }
            { scalar_return => 9,
                stderr => sub {
                    my ($output) = colorstrip(shift);
                    like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                    like $output, qr/\n\$tracked = 10\n\n/;
                }
            };



    effects_ok { $untracked =~ s/0/00/ };

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

