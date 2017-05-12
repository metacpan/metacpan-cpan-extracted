#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

BEGIN { use_ok( 'Tie::File::FixedRecLen::Store' ); }

my $file = "t_$$.dat";
my @store;

eval {tie @store, 'Tie::File::FixedRecLen::Store'};
ok($@ =~ m/usage/, "missing filename");

eval {tie @store, 'Tie::File::FixedRecLen::Store', $file};
ok($@ =~ m/usage/, "missing reclen");

eval {tie @store, 'Tie::File::FixedRecLen::Store', $file, record_length => 10};
ok($@ eq '', "loads okay");

ok(scalar @store == 0, "empty file size read okay");

eval {push @store, 'test1'};
ok($@ eq '', "pushed an item");

ok(scalar @store == 1, "non-empty file size (1) read okay");
ok($#store == 0, "non-empty last index (0) read okay");

eval {$#store = 9};
ok($@ eq '', "read the last index");
ok($#store == 9, "non-empty last index (9) read okay");

eval {$store[20] = 'test2'};
ok($@ eq '', "stored into the future");
ok(scalar @store == 21, "non-empty file size (21) read okay");

eval {push @store, 'a very long thing which is too long'};
ok($@ =~ m/length of value/, "pushing oversized value");

eval {$store[21] = 'a very long thing which is too long'};
ok($@ =~ m/length of value/, "assigning oversized value");

ok(scalar @store == 21, "file size is still 21");

eval {untie @store};
ok($@ eq '', "untied array");

END {
    untie @store;
    unlink $file;
}
