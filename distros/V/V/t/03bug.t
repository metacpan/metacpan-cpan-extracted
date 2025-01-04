#!/usr/bin/perl -I.

use strict;
use warnings;

use t::Test::abeltje;

require_ok ("V");

my @modules = map {
    s{/}{::}g;
    s{\.pm$}{};
    $_;
    } grep { m/\.pm$/ && !m/^Config\.pm$/ } keys %INC;

my $versions = eval {
    join ", " => map { "$_: " . V::get_version ($_) } qw( Cwd );
    };

is ($@, "", "readonly bug");

abeltje_done_testing ();
