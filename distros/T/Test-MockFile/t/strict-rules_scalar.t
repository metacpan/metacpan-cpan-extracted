#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< strict >;    # yeap it's strict

ok( dies { -e "/no/mocked" }, q[-e "/no/mocked"] );
ok( dies { -l "/no/mocked" }, q[-l "/no/mocked"] );

note "add_strict_rule_for_command for stat / lstat";

# incorrect
ok( dies { Test::MockFile::add_strict_rule_for_command( [qw{ lstat stat }] => '/this/path', 1 ) }, "command not supported" );

# correct
Test::MockFile::add_strict_rule_for_command(
    [qw{ lstat stat }] => sub {
        my ($ctx) = @_;
        return 1 if $ctx->{filename} eq '/this/path';
        return;    # continue to the next rule
    }
);

ok( dies { -e "/no/mocked" },      q[-e "/no/mocked"] );
ok( dies { -l "/no/mocked" },      q[-l "/no/mocked"] );
ok( lives { -l '/this/path' },     q[-l "/this/path" mocked] );
ok( dies { -l "/another/mocked" }, q[-l "/another/mocked"] );

Test::MockFile::add_strict_rule( [qw{ lstat stat }] => '/another/path', 1 );

ok( dies { -e "/no/mocked" },     q[-e "/no/mocked"] );
ok( dies { -l "/no/mocked" },     q[-l "/no/mocked"] );
ok( lives { -l '/this/path' },    q[-l "/this/path" mocked] );
ok( lives { -l '/another/path' }, q[-l "/another/path" mocked] );

done_testing;
