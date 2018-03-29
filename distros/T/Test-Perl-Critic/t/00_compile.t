
use strict;
use warnings;
use Test::More tests => 3;

#---------------------------------------------------------------------------

use_ok('Test::Perl::Critic');
can_ok('Test::Perl::Critic', 'critic_ok');
can_ok('Test::Perl::Critic', 'all_critic_ok');

diag( "Testing Test::Perl::Critic $Test::Perl::Critic::VERSION with Perl::Critic $Perl::Critic::VERSION and PPI $PPI::VERSION, under Perl $], $^X" );
