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
use UUID 'generate_v5';

note '';
note 'testing version 5 binary speed';

my $t = countit(1, 'generate_v5(my $x, dns => "www.example.com")');
my $cnt = $t->iters;

note 'rate = ', int_commify($cnt, 1), ' UUID binaries per second';
note '';

ok 1, 'done';

done_testing;
