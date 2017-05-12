#!/usr/bin/env perl

use strict;
use warnings;

use UR;

use Test::More tests => 10;

use_ok('UR::Observer');

my %fired = (
    a => 0,
    b => 0,
);
my %id = (
    a => UR::Observer->register_callback(callback => sub { $fired{a}++ }),
    b => UR::Observer->register_callback(callback => sub { $fired{b}++ }),
);
ok($id{a}, q(registered callback 'a'));
ok($id{b}, q(registered callback 'b'));

UR::Object->__signal_observers__('create');
is($fired{a}, 1, q(callback 'a' fired No. 1));
is($fired{b}, 1, q(callback 'b' fired No. 1));

UR::Object->__signal_observers__('create');
is($fired{a}, 2, q(callback 'a' fired No. 2));
is($fired{b}, 2, q(callback 'b' fired No. 2));

ok(UR::Observer->unregister_callback(id => $id{a}), q(unregistered callback 'a'));

UR::Object->__signal_observers__('create');
is($fired{a}, 2, q(callback 'a' did not fire again after unregistering 'a'));
is($fired{b}, 3, q(callback 'b' did fire again after unregistering 'a'));
