#!/usr/bin/env perl
use warnings;
use strict;
use Text::Pipe 'PIPE';
use Test::More tests => 10;
my $pipe   = PIPE('W3CDTF::Parse');
my $w3cdtf = '2003-02-15T13:50:05-05:00';
isa_ok($pipe, 'Text::Pipe::W3CDTF::Parse');
my $dt = $pipe->filter($w3cdtf);
isa_ok($dt, 'DateTime');
is($dt->year,   2003, 'year');
is($dt->month,  2,    'month');
is($dt->day,    15,   'day');
is($dt->hour,   13,   'hour');
is($dt->minute, 50,   'minute');
is($dt->second, 5,    'second');
$pipe = PIPE('W3CDTF::Format');
isa_ok($pipe, 'Text::Pipe::W3CDTF::Format');
is($pipe->filter($dt), $w3cdtf, 'W3CDTF::Format');
