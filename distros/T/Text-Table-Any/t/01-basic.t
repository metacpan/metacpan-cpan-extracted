#!perl

use strict;
use warnings;
#use Test::Differences;
use Test::Exception;
use Test::More 0.98;
#use Test::Needs;

use Text::Table::Any qw(generate_table);

subtest "basics" => sub {
    is(generate_table(rows=>[]), "");
};

subtest "table() is still available" => sub {
    lives_ok { Text::Table::Any::table(rows=>[]) };
};

done_testing;
