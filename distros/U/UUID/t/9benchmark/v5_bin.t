use strict;
use warnings;
use Test::More;
use MyNote;
use Benchmark qw(:hireswallclock countit);

unless ( $ENV{TEST_VERBOSE} ) {
    plan skip_all => 'not verbose';
}

use_ok 'UUID', 'generate_v5';

note '';
note 'testing version 5 binary speed';

my $t = countit(1, 'generate_v5(my $x, dns => "www.example.com")');
my $cnt = $t->iters;

note 'rate = ', $cnt, ' UUID binaries per second';
note '';

ok 1, 'done';

done_testing;
