BEGIN { $ENV{PERLRIG_FILE} = 't/.perlrig' }
use Test::More;
use Time::HiRes 'tv_interval';

$t0 = [gettimeofday];
$a='a'; $a.'b' for 1..100000000;
$tt1 = tv_interval ( $t0 );

$t1 = [gettimeofday];
eval 'use rig "_t_perlrig"' for 1..1;
$tt2 = tv_interval ( $t1 );

print "111=" . $tt1;
print "222=" . $tt2;
#my $tt1 = timediff $t1,$t0;
#my $tt2 = timediff $t2,$t1;
print 'RRR=' . ($tt2 / $tt1 );
ok( ($tt2 / $tt1 ) < 1 , 'under 100% time' );

done_testing;
