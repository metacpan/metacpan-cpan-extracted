#!/usr/bin/perl -w

use Test::More 'no_plan';

use_ok "Some::Employee";

my $cog = Some::Employee->new;

$cog->name("Harry Tuttle");
is $cog->name,      "Harry Tuttle";

$cog->id(12345);
is $cog->id,        12345;

$cog->salary(50_000);
is $cog->salary,    50_000;
