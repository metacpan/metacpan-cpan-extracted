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

print "\ncomparing version speeds...\n\n";

my $r = cmpthese({
    'v1bin' => countit($seconds, 'generate_v1(my $b)'),
    'v1str' => countit($seconds, 'my $s = uuid1()'),
    'v3bin' => countit($seconds, 'generate_v3(my $b, dns => q(www.example.com))'),
    'v3str' => countit($seconds, 'my $s = uuid3(dns => q(www.example.com))'),
    'v4bin' => countit($seconds, 'generate_v4(my $b)'),
    'v4str' => countit($seconds, 'my $s = uuid4()'),
    'v5bin' => countit($seconds, 'generate_v5(my $b, dns => q(www.example.com))'),
    'v5str' => countit($seconds, 'my $s = uuid5(dns => q(www.example.com))'),
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
printf("%9s %11s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s\n", @$_) for @$r;

print <<'EOT';

    v1bin  ->  eval 'generate_v1(my $b)'
    v3bin  ->  eval 'generate_v3(my $b, dns => q(www.example.com))'
    v4bin  ->  eval 'generate_v4(my $b)'
    v5bin  ->  eval 'generate_v5(my $b, dns => q(www.example.com))'
    v6bin  ->  eval 'generate_v6(my $b)'
    v7bin  ->  eval 'generate_v7(my $b)'
    v1str  ->  eval 'my $s = uuid1()'
    v3str  ->  eval 'my $s = uuid3(dns => q(www.example.com))'
    v4str  ->  eval 'my $s = uuid4()'
    v5str  ->  eval 'my $s = uuid5(dns => q(www.example.com))'
    v6str  ->  eval 'my $s = uuid6()'
    v7str  ->  eval 'my $s = uuid7()'
EOT

exit 0;
