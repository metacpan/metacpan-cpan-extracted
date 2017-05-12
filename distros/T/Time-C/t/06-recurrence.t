use strict;
use warnings;

use Test::More tests => 9;

use Time::C;
use Time::R;

my $y = Time::R->new(Time::C->new(2016,2,29), years => 1, end => Time::C->new(2020,3,1));

is ($y->next()->epoch, Time::C->new(2017,2,28)->epoch, "1st y->next correct");
is ($y->next()->epoch, Time::C->new(2018,2,28)->epoch, "2nd y->next correct");
is ($y->next()->epoch, Time::C->new(2019,2,28)->epoch, "3rd y->next correct");
is ($y->next()->epoch, Time::C->new(2020,2,29)->epoch, "4th y->next correct");
is ($y->next(), undef, "5th y->next correct");

my $m = Time::R->new(Time::C->new(2016,1,31), months => 1);

is ($m->next()->epoch, Time::C->new(2016,2,29)->epoch, "1st m->next correct");
is ($m->next()->epoch, Time::C->new(2016,3,31)->epoch, "2nd m->next correct");

$m->current = Time::C->new(2016,6,10);

is ($m->next()->epoch, Time::C->new(2016,6,30)->epoch, "3rd m->next correct");

$m->end = Time::C->new(2016,5,31);

is ($m->next(), undef, "4th m->next correct");
