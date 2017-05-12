
use lib 't/lib';
use strict;
use warnings;

use Gugod;
use Normal;


use Benchmark qw(:all :hireswallclock);

my $obj1 = Gugod->new;
my $obj2 = Normal->new;

cmpthese(1000000, {
    Gugod => sub {
        $obj1->inc;
    },
    Normal => sub {
        $obj2->inc
    },
});
