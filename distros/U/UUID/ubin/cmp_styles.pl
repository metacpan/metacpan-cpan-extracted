
# seconds per test
my $seconds = $ARGV[0] || 2;

#------------------------------------------------------------------------------
use blib;
use strict;
use warnings;
use Benchmark qw(:hireswallclock cmpthese countit);
use UUID qw(
    generate_v1 generate_v3 generate_v4 generate_v5 generate_v6 generate_v7
    uuid1 uuid3 uuid4 uuid5 uuid6 uuid7
    unparse
);

print "\ncomparing calling styles...\n\n";

my $r = cmpthese({
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

exit 0;
