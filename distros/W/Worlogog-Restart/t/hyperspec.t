#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 16;

use Worlogog::Restart -all => { -prefix => 'restart_' };

is +(restart_case {
    my $r = restart_find 'my_restart';
    isnt $r, undef;
    is $r->name, 'my_restart';
    is ref($r->code), 'CODE';
    42
} {
    my_restart => sub {},
}), 42;

is restart_find('my_restart'), undef;

is +(restart_case {
    my $r = restart_find 'my_restart_2';
    isnt $r, undef;
    is $r->name, 'my_restart_2';
    is ref($r->code), 'CODE';
    restart_invoke $r, 'hai';
    ok 0;
} {
    my_restart_2 => sub { "o @_" },
}), "o hai";

is restart_find('my_restart'), undef;
is restart_find('my_restart_2'), undef;

is +(restart_case {
    restart_invoke 'my_restart_3', 'rly';
    ok 0;
} {
    my_restart_3 => sub { "o @_" },
}), "o rly";

is restart_find('my_restart'), undef;
is restart_find('my_restart_2'), undef;
is restart_find('my_restart_3'), undef;


is_deeply [restart_case {
    restart_bind {
        map $_->name, restart_compute
    } {
        case1 => sub { 1 },
    };
} {
    nil => sub { 2 },
    case3 => sub { 3 },
    case1 => sub { 4 },
}], [qw(case1 case1 case3 nil)];
