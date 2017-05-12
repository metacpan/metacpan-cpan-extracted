use 5.010001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use Test::Mock::Time;

BEGIN {
    plan skip_all => 'EV not installed' if !eval { require EV };
    plan skip_all => 'Mojolicious not installed'
        if !eval { require Mojolicious; Mojolicious->VERSION('6'); require Mojo::IOLoop };
}

my $t = time;
my $id;


is ref Mojo::IOLoop->singleton->reactor, 'Mojo::Reactor::EV', 'using EV';

Mojo::IOLoop->timer(10, sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is time, $t+=10, 'Mojo::IOLoop->start terminated by timer';

Mojo::IOLoop->one_tick;
is time, $t, 'Mojo::IOLoop->one_tick terminated without timers';

Mojo::IOLoop->timer(5, sub {});
Mojo::IOLoop->one_tick;
is time, $t+=5, 'Mojo::IOLoop->one_tick terminated by timer';

Mojo::IOLoop->recurring(3, sub {});
Mojo::IOLoop->one_tick;
is time, $t+=3, 'Mojo::IOLoop->one_tick terminated by recurring';
Mojo::IOLoop->one_tick;
is time, $t+=3, 'Mojo::IOLoop->one_tick terminated by recurring';
Mojo::IOLoop->one_tick;
is time, $t+=3, 'Mojo::IOLoop->one_tick terminated by recurring';

Mojo::IOLoop->reset;
is time, $t, 'Mojo::IOLoop->one_tick terminated after reset';

Mojo::IOLoop->timer(5, sub {});
sleep 3;
is time, $t+=3, 'sleep 3 (2 seconds left until timer 5)';
Mojo::IOLoop->one_tick;
is time, $t+=2, 'Mojo::IOLoop->one_tick terminated by timer in 2 seconds';

$id = Mojo::IOLoop->timer(5, sub {});
sleep 3;
is time, $t+=3, 'sleep 3 (2 seconds left until timer 5), again';
Mojo::IOLoop->singleton->reactor->again($id);
Mojo::IOLoop->one_tick;
is time, $t+=5, 'Mojo::IOLoop->one_tick terminated by timer in 5 seconds';

$id = Mojo::IOLoop->recurring(5, sub {});
sleep 3;
is time, $t+=3, 'sleep 3 (2 seconds left until timer 5), again';
Mojo::IOLoop->singleton->reactor->again($id);
Mojo::IOLoop->one_tick;
is time, $t+=5, 'Mojo::IOLoop->one_tick terminated by timer in 5 seconds';
Mojo::IOLoop->remove($id);

$id = Mojo::IOLoop->timer(5, sub {});
sleep 3;
is time, $t+=3, 'sleep 3 (2 seconds left until timer 5), remove';
Mojo::IOLoop->remove($id);
Mojo::IOLoop->one_tick;
is time, $t, 'Mojo::IOLoop->one_tick terminated without timers';


done_testing;
