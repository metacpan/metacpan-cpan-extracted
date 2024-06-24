
# seconds per test
my $seconds = $ARGV[0] || 2;

#------------------------------------------------------------------------------
use blib;
use strict;
use warnings;
use File::Temp ();
use Benchmark qw(:hireswallclock cmpthese countit);
use UUID qw(
    generate_v1 generate_v3 generate_v4 generate_v5 generate_v6 generate_v7
    uuid1 uuid3 uuid4 uuid5 uuid6 uuid7
    unparse
);

use vars qw($tmpdir $fname);

BEGIN {
    $tmpdir = File::Temp->newdir(CLEANUP => 0);
    $fname  = File::Temp::tempnam($tmpdir, 'UUID.test.');
}

END {
    unlink $fname  if defined $fname;
    rmdir  $tmpdir if defined $tmpdir;
}

# call END block on ^C
$SIG{INT} = sub { exit 0 };

print "\ncomparing persist...\n\n";

UUID::_persist(undef);
my $t0 = countit($seconds, 'my $s = uuid1()');
UUID::_persist($fname);
my $t1 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.0000001);
my $t2 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.000001);
my $t3 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.00001);
my $t4 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.0001);
my $t5 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.001);
my $t6 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.01);
my $t7 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(0.1);
my $t8 = countit($seconds, 'my $s = uuid1()');
UUID::_defer(1.0);
my $t9 = countit($seconds, 'my $s = uuid1()');

my $r = cmpthese({
    'case0' => $t0,
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

printf("%9s %11s %6s %6s %6s %6s %6s %6s %6s %6s %6s %6s\n", @$_) for @$r;

print <<'EOT';

    case0  ->  no persist; eval 'my $s = uuid1()'
    case1  ->  persistent; eval 'my $s = uuid1()' # undeferred
    case2  ->  persistent; eval 'my $s = uuid1()' # deferred 100ns
    case3  ->  persistent; eval 'my $s = uuid1()' # deferred 1us
    case4  ->  persistent; eval 'my $s = uuid1()' # deferred 10us
    case5  ->  persistent; eval 'my $s = uuid1()' # deferred 100us
    case6  ->  persistent; eval 'my $s = uuid1()' # deferred 1ms
    case7  ->  persistent; eval 'my $s = uuid1()' # deferred 10ms
    case8  ->  persistent; eval 'my $s = uuid1()' # deferred 100ms
    case9  ->  persistent; eval 'my $s = uuid1()' # deferred 1ms
EOT

exit 0;
