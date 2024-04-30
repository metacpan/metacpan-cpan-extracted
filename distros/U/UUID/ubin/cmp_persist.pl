use strict;
use warnings;
use File::Temp ();
use Benchmark qw(:hireswallclock cmpthese countit);
use UUID qw(
    generate_v1 generate_v3 generate_v4 generate_v5 generate_v6 generate_v7
    uuid1 uuid3 uuid4 uuid5 uuid6 uuid7
    unparse
);

my $seconds = $ARGV[0] || 1;

print "\ncomparing persist...\n\n";

my ($fh, $fname) = File::Temp::tempfile(
    'assertconfXXXXXXXX', SUFFIX => '.txt', UNLINK => 0
);
close $fh;

UUID::_persist(undef);
my $t1 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_persist($fname);
my $t2 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.0000001);
my $t3 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.000001);
my $t4 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.00001);
my $t5 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.0001);
my $t6 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.001);
my $t7 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.01);
my $t8 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_defer(0.1);
my $t9 = countit(2*$seconds, 'my $s = uuid1()');
unlink $fname;

my $r = cmpthese({
    'case1' => $t1,
    'case2' => $t2,
    'case3' => $t3,
    'case4' => $t4,
    'case5' => $t5,
    'case6' => $t6,
    'case7' => $t7,
    'case8' => $t8,
    'case9' => $t9,
}, 'none');

printf("%9s %11s %6s %6s %6s %6s %6s %6s %6s %6s %6s\n", @$_) for @$r;

print <<'EOT';

    case1  ->  no persist; eval 'my $s = uuid1()'
    case2  ->  persistent; eval 'my $s = uuid1()' # undeferred
    case3  ->  persistent; eval 'my $s = uuid1()' # deferred 100ns
    case4  ->  persistent; eval 'my $s = uuid1()' # deferred 1us
    case5  ->  persistent; eval 'my $s = uuid1()' # deferred 10us
    case6  ->  persistent; eval 'my $s = uuid1()' # deferred 100us
    case7  ->  persistent; eval 'my $s = uuid1()' # deferred 1ms
    case8  ->  persistent; eval 'my $s = uuid1()' # deferred 10ms
    case9  ->  persistent; eval 'my $s = uuid1()' # deferred 100ms
EOT

exit 0;
