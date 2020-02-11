use warnings;
use strict;

use Test::Effects;

plan tests => 1;

use Term::ANSIColor 'colorstrip';
use Var::Mystic;

effects_ok {
          my @untracked;
    track my @tracked;

    effects_ok { @untracked = 0..2 };

    effects_ok { @tracked   = 0..2 }
               { list_return => [0..2],
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                       like $output, qr/\n\@tracked = \[0, 1, 2\]\n\n/;
                   }
               };

    sub foo {
        my ($varref) = @_;
        @$varref = 'foo';
    }

    effects_ok { foo(\@untracked) };

    effects_ok { foo(\@tracked)   }
               { list_return => ['foo'],
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 9)}/;
                       like $output, qr/\n\@tracked = \["foo"\]\n\n/;
                   }
               };


    effects_ok { @untracked[0,1] = (0,1) };
    effects_ok { @tracked[0,1]   = (0,1) }
               { list_return => [0,1],
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                       like $output, qr/\n\@tracked = \[0, 1\]\n\n/;
                   }
               };

    effects_ok { $untracked[0] = -1 };

    effects_ok { $tracked[0] =  -1 }
               { list_return => [-1] };


    effects_ok { $#untracked = 2 };

    effects_ok { $#tracked   = 2 }
               { scalar_return => 2,
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                       like $output, qr/\n\@tracked = \[-1, 1, undef\]\n\n/;
                   }
               };

};


done_testing();

