use strict;
BEGIN {
    $ENV{LC_MESSAGES} = 'C';

    my $have_threads = eval{require threads; threads->create(sub{return 1})->join};
    require Test::More;
    Test::More->import();
    if (!$have_threads) {
        plan(skip_all => 'for threaded perls only');
    } elsif ($] == 5.010) {
        plan(skip_all => 'threads severely broken on 5.10.0');
    } else {
        plan(tests => 15_002);
    }
}

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