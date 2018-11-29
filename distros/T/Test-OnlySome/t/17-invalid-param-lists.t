#!perl
use rlib 'lib';
use DTest;
use Test::Fatal qw(dies_ok lives_ok);

# Test the import() routine.  We cannot load the module with `use` here.
# Instead, we have to use `require` and then manually call import().
# That way, the die() happens at runtime, when dies_ok() can catch it.
# Thanks to https://stackoverflow.com/a/7904653/2877364 by
# https://stackoverflow.com/users/189416/eric-strom for the explanation
# (although this file does not use any code or content from that answer).

require Test::OnlySome;

lives_ok {
    package T1;
    use Test::More;
    'Test::OnlySome'->import(qw(skip 2 6));
} 'Regular imports work (sanity check)';

dies_ok {
    package T2;
    'Test::OnlySome'->import(qw(blah));     # Unknown keyword
} 'Invalid keywords die';

dies_ok {
    package T3;
    'Test::OnlySome'->import(qw(skip blah));
        # Arg to skip doesn't look like a number
} 'Non-numeric skip arguments die';

dies_ok {
    package T4;
    'Test::OnlySome'->import(qw(skip -1));
        # Arg to skip is <1
} 'Negative skip arguments die';

dies_ok {
    package T5;
    'Test::OnlySome'->import(qw(skip 0));
        # Arg to skip is <1
} 'Skip argument of 0 dies';

done_testing();
