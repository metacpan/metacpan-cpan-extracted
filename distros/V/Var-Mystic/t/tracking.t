use warnings;
use strict;

use Test::Effects;

plan tests => 8;

use Term::ANSIColor 'colorstrip';
use Var::Mystic;

my $untracked;
mystic $tracked;

effects_ok { $untracked = 0 };

effects_ok { $tracked   = 0 }
           { scalar_return => 0,
             stderr => sub {
                my ($output) = @_;
                is colorstrip($output),
                   '#line ' . (__LINE__-5) . "  t/tracking.t\n\$tracked = 0\n\n"
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
                my ($output) = @_;
                is colorstrip($output),
                   '#line ' . (__LINE__-10) . qq{  t/tracking.t\n\$tracked = "foo"\n\n}
             }
           };


effects_ok { $untracked++ };

effects_ok { $tracked++   }
           { scalar_return => 'foo',
             stderr => sub {
                my ($output) = @_;
                is colorstrip($output),
                   '#line ' . (__LINE__-5) . qq{  t/tracking.t\n\$tracked = "fop"\n\n}
             }
           };



effects_ok { $untracked =~ s/o/oo/ };

effects_ok { $tracked =~ s/o/oo/   }
           { scalar_return => 1,
             stderr => sub {
                my ($output) = @_;
                is colorstrip($output),
                   '#line ' . (__LINE__-5) . qq{  t/tracking.t\n\$tracked = "foop"\n\n}
             }
           };




done_testing();

