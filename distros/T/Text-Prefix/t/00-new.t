#!/bin/env perl

use strict;
use warnings;
use Test::Most;
use JSON::PP qw(encode_json);

use lib "./lib";
use Text::Prefix;

my $p = Text::Prefix->new();
is ref($p), 'Text::Prefix', 'new works in simple case';

$p = Text::Prefix->new(host_sans => '.', perl => '1', order => 'lt, tm, pl, d', tai => '35');
is ref($p), 'Text::Prefix', 'new works in complex case';

done_testing();
exit(0);
