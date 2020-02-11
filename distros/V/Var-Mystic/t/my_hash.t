use warnings;
use strict;

use Test::Effects;

plan tests => 1;

use Term::ANSIColor 'colorstrip';
use Var::Mystic;

effects_ok {
          my %untracked;
    track my %tracked;

    effects_ok { %untracked = (a=>1, b=>2) };

    effects_ok { %tracked   = (a=>1, b=>2) }
               { list_return => [a=>1, b=>2],
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                       like $output, qr/\n\%tracked = \{(?:\s*a => 1,?|\s*b => 2,?)+\s*\}\n\n/;
                   }
               };

    sub foo {
        my ($varref) = @_;
        $varref->{f} = 'foo';
    }

    effects_ok { foo(\%untracked) };

    effects_ok { foo(\%tracked)   }
               { scalar_return => 'foo',
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 9)}/;
                       like $output, qr/\n\%tracked = \{(?:\s*a => 1,?|\s*b => 2,?|\s*f => "foo")+\s*\}\n\n/;
                   }
               };



    effects_ok { %untracked = () };

    effects_ok { %tracked   = () }
               { list_return => [],
                   stderr => sub {
                       my ($output) = colorstrip(shift);
                       like $output, qr/\A\#line ${\(__LINE__ - 4)}/;
                       like $output, qr/\n\%tracked = \{\}\n\n/;
                   }
               };

};


done_testing();


