use strict;
BEGIN { $ENV{LC_MESSAGES} = 'C' }
our $have_threads;
BEGIN {
    $have_threads = eval{require threads; threads->create(sub{return 1})->join};
}
use Test::More ($have_threads) ? (tests => 15_002) : (skip_all => 'for threaded perls only');

use namespace::clean::xs;

package Foo;

sub foo {}
::is(!!__PACKAGE__->can('foo'), 1);

my @threads = map +threads->create(sub {
    sleep 0.1;

    for (1..5_000) {
        eval 'use namespace::clean::xs';
        ::is(!!__PACKAGE__->can('foo'), '');
    }
}), (0..2);

$_->join for splice @threads;
::is(!!__PACKAGE__->can('foo'), 1);