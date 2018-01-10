use 5.008001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use Test::Mock::Time;

BEGIN {
    $ENV{PERL_ANYEVENT_MODEL} = 'EV';
    plan skip_all => 'EV not installed' if !eval { require EV };
    plan skip_all => 'AnyEvent not installed' if !eval { require AnyEvent };
}


my $t = time;
my $w;
my ($res, $want) = (0, 0);
my $cv;

is AE::now, $t, 'AE::now';
is AE::time, $t, 'AE::time';
select undef,undef,undef,1.1;
is AE::now, $t, 'AE::now  is same after real 1.1 second delay';
is AE::time, $t, 'AE::time is same after real 1.1 second delay';
EV::sleep(-1);
is AE::now, $t, 'AE::now  is same after EV::sleep(-1)';
is AE::time, $t, 'AE::time is same after EV::sleep(-1)';
EV::sleep(0);
is AE::now, $t, 'AE::now  is same after EV::sleep(0)';
is AE::time, $t, 'AE::time is same after EV::sleep(0)';
EV::sleep(0.5);
is AE::now, $t+=0.5, 'AE::now  is increased after EV::sleep(0.5)';
is AE::time, $t, 'AE::time is increased after EV::sleep(0.5)';
EV::sleep(100);
is AE::now, $t+=100, 'AE::now  is increased after EV::sleep(100)';
is AE::time, $t, 'AE::time is increased after EV::sleep(100)';
ff(1000);
is AE::now, $t+=1000, 'AE::now  is increased after ff(1000)';
is AE::time, $t, 'AE::time is increased after ff(1000)';

$cv = AnyEvent->condvar;
$w = AE::timer 10, 0, sub { $res++; $cv->send };
$cv->recv;
is AE::now, $t+=10, 'cv->recv terminated';
is $res, $want+=1, '... by timer';

$cv = AnyEvent->condvar;
$w = AE::timer 0.5, 0, sub { $res++; $cv->send };
$cv->recv;
is AE::now, $t+=0.5, 'cv->recv terminated';
is $res, $want+=1, '... by timer';


done_testing;
