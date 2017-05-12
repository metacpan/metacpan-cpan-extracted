#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

use lib 'lib/';

use_ok('WebService::Gyazo::B');

my $ua = WebService::Gyazo::B->new();
can_ok($ua, $_) for (qw( error isError ));

is($ua->error(), 'N/A', 'WebService::Gyazo::B->useOk(\'error\')');
is($ua->isError(), 0, 'WebService::Gyazo::B->useOk(\'isError\')');

$ua->{error} = 'XXXX'; # Set test error
is($ua->error(), 'XXXX', 'WebService::Gyazo::B->useOk(\'error\')');
is($ua->isError(), 1, 'WebService::Gyazo::B->useOk(\'isError\')');
