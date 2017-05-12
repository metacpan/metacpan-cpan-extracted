package M2_T;
use Test::Usage;

example('a1', sub {ok(warn, 'Exp_a1', 'Got_a1')});
example('a2', sub {ok(die,  'Exp_a2', 'Got_a2')});

