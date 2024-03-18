use strict;
use warnings;
use File::Temp ();
use Benchmark qw(:hireswallclock cmpthese countit);
use UUID qw(
    generate_v1 generate_v4 generate_v6 generate_v7
    uuid1 uuid4 uuid6 uuid7
    unparse
);

my $seconds = $ARGV[0] || 1;

print "\ncomparing version speeds...\n\n";

my $r = cmpthese({
    'v1bin' => countit($seconds, 'generate_v1(my $b)'),
    'v1str' => countit($seconds, 'my $s = uuid1()'),
    'v4bin' => countit($seconds, 'generate_v4(my $b)'),
    'v4str' => countit($seconds, 'my $s = uuid4()'),
    'v6bin' => countit($seconds, 'generate_v6(my $b)'),
    'v6str' => countit($seconds, 'my $s = uuid6()'),
    'v7bin' => countit($seconds, 'generate_v7(my $b)'),
    'v7str' => countit($seconds, 'my $s = uuid7()'),
}, 'none');
    #'v1testS'  => countit($seconds, 'my $s = UUID::_v1testS()'),
    #'v1testB'  => countit($seconds, 'UUID::_v1testB(my $b)'),
    #'v4testS'  => countit($seconds, 'my $s = UUID::_v4testS()'),
    #'v4testB'  => countit($seconds, 'UUID::_v4testB(my $b)'),

#printf("%9s %11s %7s %7s %7s %7s %7s %7s %7s %7s\n", @$_) for @$r;
printf("%9s %11s %7s %7s %7s %7s %7s %7s %7s %7s\n", @$_) for @$r;

print <<'EOT';

    v1bin  ->  eval 'generate_v1(my $b)'
    v4bin  ->  eval 'generate_v4(my $b)'
    v6bin  ->  eval 'generate_v6(my $b)'
    v7bin  ->  eval 'generate_v7(my $b)'
    v1str  ->  eval 'my $s = uuid1()'
    v4str  ->  eval 'my $s = uuid4()'
    v6str  ->  eval 'my $s = uuid6()'
    v7str  ->  eval 'my $s = uuid7()'
EOT

print "\ncomparing calling styles...\n\n";

$r = cmpthese({
    'case1' => countit(2*$seconds, 'my $s = uuid1()'),
    'case2' => countit(2*$seconds, 'my $s = UUID::uuid1()'),
    'case3' => countit(2*$seconds, 'generate_v1(my $b); unparse($b, my $s)'),
    'case4' => countit(2*$seconds, 'UUID::generate_v1(my $b); UUID::unparse($b, my $s)'),
    'case5' => countit(2*$seconds, 'my($b,$s); generate_v1($b); unparse($b,$s)'),
    'case6' => countit(2*$seconds, 'my($b,$s); UUID::generate_v1($b); UUID::unparse($b,$s)'),
}, 'none');

printf("%9s %11s %6s %6s %6s %6s %6s %6s\n", @$_) for @$r;

print <<'EOT';

    case1  ->  eval 'my $s = uuid1()'
    case2  ->  eval 'my $s = UUID::uuid1()'
    case3  ->  eval 'generate_v1(my $b); unparse($b, my $s)'
    case4  ->  eval 'UUID::generate_v1(my $b); UUID::unparse($b, my $s)'
    case5  ->  eval 'my($b,$s); generate_v1($b); unparse($b,$s)'
    case6  ->  eval 'my($b,$s); UUID::generate_v1($b); UUID::unparse($b,$s)'
EOT

print "\ncomparing persist...\n\n";

my ($fh, $fname) = File::Temp::tempfile(
    'assertconfXXXXXXXX', SUFFIX => '.txt', UNLINK => 0
);
close $fh;

UUID::_persist($fname);
my $t1 = countit(2*$seconds, 'my $s = uuid1()');
UUID::_persist(undef);
my $t2 = countit(2*$seconds, 'my $s = uuid1()');
unlink $fname;

$r = cmpthese({
    'case1' => $t1,
    'case2' => $t2,
}, 'none');

printf("%9s %11s %6s %6s\n", @$_) for @$r;

print <<'EOT';

    case1  ->  persistent; eval 'my $s = uuid1()'
    case2  ->  no persist; eval 'my $s = uuid1()'

EOT

exit 0;
