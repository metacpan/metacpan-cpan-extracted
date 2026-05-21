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
use UUID 'uuid3';

note '';
note 'testing version 3 string speed';

my $t = countit(1, 'uuid3(dns => "www.example.com")');
my $cnt = $t->iters;

note 'rate = ', int_commify($cnt, 1), ' UUID strings per second';
note '';

ok 1, 'done';

done_testing;
