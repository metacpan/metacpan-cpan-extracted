# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Working-Daemon.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Working::Daemon') };

{
    my $daemon = Working::Daemon->new;

    ok($daemon->daemon, "Trying daemon(0)");
    ok(!$daemon->foreground, "And not forgrounded");

    $daemon->daemon(0);
    ok(!$daemon->daemon, "And now they should be flipped");
    ok($daemon->foreground, "");

}

{
    my $daemon = Working::Daemon->new;

    ok($daemon->daemon, "Now trying foreground(1)");
    ok(!$daemon->foreground, "And not forgrounded");

    $daemon->foreground(1);
    ok(!$daemon->daemon, "And now they should be flipped");
    ok($daemon->foreground, "");

}

1;
