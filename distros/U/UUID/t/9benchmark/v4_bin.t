use strict;
use warnings;

BEGIN {
    unless ( $ENV{TEST_VERBOSE} ) {
        print "1..0 # SKIP not verbose\n";
        exit 0;
    }
}

use MyTest;
use MyTmpTimer;
use Benchmark qw(:hireswallclock countit);
use UUID 'generate_random';

note '';
note 'testing version 4 binary speed';

my $t = countit(1, 'generate_random(my $x)');
my $cnt = $t->iters;

note 'rate = ', int_commify($cnt, 1), ' UUID binaries per second';
note '';

ok 1, 'done';

done_testing;
