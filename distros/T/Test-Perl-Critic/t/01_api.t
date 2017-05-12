
use strict;
use warnings;
use Test::More tests => 4;
use Test::Perl::Critic;
use English qw(-no_match_vars);

#---------------------------------------------------------------------------
# Export tests

can_ok('main', 'critic_ok');
can_ok('main', 'all_critic_ok');

#---------------------------------------------------------------------------
# Test exception for missing files

eval{ critic_ok('foobar') };
ok( defined $EVAL_ERROR );

#---------------------------------------------------------------------------
# Test exception for null file

eval{ critic_ok() };
ok( defined $EVAL_ERROR );



