#!/usr/bin/perl -w

use Test::More tests => 10;

my $Parent = $$;

use_ok 'Test::Fork';

fork_ok(2, sub{ 
    pass("child 1");
    pass("child 1 again");
});

pass("parent one");

fork_ok(2, sub { 
    pass("child 2");
    pass("child 2 again");
});

pass("parent two");

1 while Test::Fork::_reaper();
ok( Test::More->builder->use_numbers, "use_numbers back on after all children reaped" );
