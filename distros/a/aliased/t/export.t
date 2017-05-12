#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use B;
use lib "t/lib";

use aliased 'Really::Long::Module::Name';

my $cv = B::svref_2object(\&Name);
is($cv->GV->STASH->NAME, 'aliased', 'installed symbol was compiled in the aliased package');

done_testing;
