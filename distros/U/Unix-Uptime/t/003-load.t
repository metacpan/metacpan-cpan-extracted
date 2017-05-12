#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 9;

use Unix::Uptime;

$ENV{LC_ALL} = 'C';

ok my ($load1, $load5, $load15) = Unix::Uptime->load(), 'received a load avarage';
like $load1, qr/^\d+(\.\d+)?$/, 'load1 looks right';
like $load5, qr/^\d+(\.\d+)?$/, 'load5 looks right';
like $load15, qr/^\d+(\.\d+)?$/, 'load15 looks right';

ok my $pretty_uptime = `uptime`;
ok my ($pload1, $pload5, $pload15) = $pretty_uptime =~ /load\s+averages?:\s+(\d+\.?\d*),?\s+(\d+\.?\d*),?\s+(\d+\.?\d*)/i
    or diag "\$ uptime\n$pretty_uptime";
is $load1, $pload1;
is $load5, $pload5;
is $load15, $pload15;

