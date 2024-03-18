use strict;
use warnings;
use Test::More;
use MyNote;
use Benchmark qw(:hireswallclock countit);

unless ( $ENV{TEST_VERBOSE} ) {
    plan skip_all => 'not verbose';
}

use_ok 'UUID', 'generate_time';

note '';
note 'testing version 1 binary speed';

my $t = countit(1, 'generate_time(my $x)');
my $cnt = $t->iters;

note 'rate = ', $cnt, ' UUID binaries per second';
note '';

ok 1, 'done';

done_testing;
