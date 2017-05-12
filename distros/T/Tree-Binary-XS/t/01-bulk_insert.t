#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Tree::Binary::XS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use Tree::Binary::XS;

my $tree = Tree::Binary::XS->new({ by_key => 'id' });
ok($tree);

my @ret;
@ret = $tree->insert_those([{ id => 10, 'name' => 'Bob' },  { id => 3, 'name' => 'John' }, { id => 2, 'name' => 'Hank' } ]);
ok(@ret);

$tree->dump();
