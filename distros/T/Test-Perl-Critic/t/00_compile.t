
use strict;
use warnings;
use Test::More tests => 3;

#---------------------------------------------------------------------------

use_ok('Test::Perl::Critic');
can_ok('Test::Perl::Critic', 'critic_ok');
can_ok('Test::Perl::Critic', 'all_critic_ok');
