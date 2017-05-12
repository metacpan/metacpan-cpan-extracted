#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Parse::Crontab;
use Test::Parse::Crontab::Simple;

my $crontab        = Parse::Crontab->new(file => './crontab.txt');
my $crontab_strict = Parse::Crontab->new(file => './crontab_strict.txt');

ok $crontab->is_valid;
match_ok $crontab;

ok $crontab_strict->is_valid;
strict_match_ok $crontab_strict;

done_testing;
