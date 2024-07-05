#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;

BEGIN {
    if( ! eval { require Module::Load::Conditional; 1 }) {
        SKIP: {
            skip "Module::Load::Conditional not installed: $@", 2;
        };
    };
};
use Test::Without::Module qw(Test::More);

local $TODO = 'Module::Load::Conditional doesn\'t guard against failures in @INC hook';

my $res;
my $lived = eval {
    $res = Module::Load::Conditional::can_load(
         modules => {
             'Test::More' => undef,
         }
    );
    1;
};
ok $lived or diag "Caught error $@";
ok !$res, "We don't load Test::More";

diag "Test::Without::Module: $Test::Without::Module::VERSION";
diag "Module::Load::Conditional: $Module::Load::Conditional::VERSION";
done_testing;
