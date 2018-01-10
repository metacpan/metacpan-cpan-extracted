use 5.008001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use Test::Mock::Time;

BEGIN {
    plan skip_all => 'EV not installed' if !eval { require EV };
}


my $t = time;
my $w;
my ($res, $want) = (0, 0);

is EV::now, $t, 'EV::now';
is EV::time, $t, 'EV::time';
select undef,undef,undef,1.1;
is EV::now, $t, 'EV::now  is same after real 1.1 second delay';
is EV::time, $t, 'EV::time is same after real 1.1 second delay';
EV::sleep(-1);
is EV::now, $t, 'EV::now  is same after EV::sleep(-1)';
is EV::time, $t, 'EV::time is same after EV::sleep(-1)';
EV::sleep(0);
is EV::now, $t, 'EV::now  is same after EV::sleep(0)';
is EV::time, $t, 'EV::time is same after EV::sleep(0)';
EV::sleep(0.5);
is EV::now, $t+=0.5, 'EV::now  is increased after EV::sleep(0.5)';
is EV::time, $t, 'EV::time is increased after EV::sleep(0.5)';
EV::sleep(100);
is EV::now, $t+=100, 'EV::now  is increased after EV::sleep(100)';
is EV::time, $t, 'EV::time is increased after EV::sleep(100)';
ff(1000);
is EV::now, $t+=1000, 'EV::now  is increased after ff(1000)';
is EV::time, $t, 'EV::time is increased after ff(1000)';

$w = EV::timer 10, 0, sub { $res++; EV::break };
EV::run;
is EV::now, $t+=10, 'EV::run terminated';
is $res, $want+=1, '... by timer';

$w = EV::timer 0.5, 0, sub { $res++ };
EV::run(EV::RUN_ONCE);
is EV::now, $t+=0.5, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=1, '... by timer';

EV::run(EV::RUN_ONCE);
is EV::now, $t, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want, '... because there are no watchers';

EV::run;
is EV::now, $t, 'EV::run terminated';
is $res, $want, '... because there are no watchers';

$w = EV::timer_ns 0.5, 0.5, sub { $res++ };

EV::run(EV::RUN_ONCE);
is EV::now, $t, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want, '... because there are no active watchers';

EV::run;
is EV::now, $t, 'EV::run terminated';
is $res, $want, '... because there are no active watchers';

my $w2 = EV::timer 10, 10, sub { $res+=10 };
EV::run(EV::RUN_ONCE);
is EV::now, $t+=10, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=10, '... by active timer';

$w2->stop;
EV::run(EV::RUN_ONCE);
is EV::now, $t, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want, '... because there are no active watchers';

$w->again;
EV::run(EV::RUN_ONCE);
is EV::now, $t+=0.5, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=1, '... by another active timer';

$w->stop;
$w2->start;
EV::run(EV::RUN_ONCE);
is EV::now, $t+=9.5, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=10, '... by another one active timer';

ok !$w->is_active, 'first timer is inactive';
ok $w2->is_active, 'second timer is active';

undef $w;
undef $w2;
EV::run;
is EV::now, $t, 'EV::run terminated';
is $res, $want, '... because there are no watchers';

$w = EV::periodic EV::now+0.3, 0, undef, sub { $res+=3 };
EV::run(EV::RUN_ONCE);
is EV::now, $t+=0.3, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=3, '... by absolute periodic';

$w2 = EV::periodic 0, 3600, undef, sub { $res+=3600 };
EV::run(EV::RUN_ONCE);
is EV::now, $t=int($t)+3600-$t%3600, 'EV::run(EV::RUN_ONCE) terminated';
is $res, $want+=3600, '... by interval periodic';


done_testing;
