use strict;
use warnings;
use Test::More;
use MyNote;
use Benchmark qw(:hireswallclock countit);

unless ( $ENV{TEST_VERBOSE} ) {
    plan skip_all => 'not verbose';
}

use_ok 'UUID', 'uuid3';

note '';
note 'testing version 3 string speed';

my $t = countit(1, 'uuid3(dns => "www.example.com")');
my $cnt = $t->iters;

note 'rate = ', $cnt, ' UUID strings per second';
note '';

ok 1, 'done';

done_testing;
