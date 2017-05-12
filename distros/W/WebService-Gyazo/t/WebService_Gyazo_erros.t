#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

use lib 'lib/';

use_ok('WebService::Gyazo');

my $ua = WebService::Gyazo->new();
can_ok($ua, $_) for (qw( error isError ));

is($ua->error(), 'N/A', 'WebService::Gyazo->useOk(\'error\')');
is($ua->isError(), 0, 'WebService::Gyazo->useOk(\'isError\')');

$ua->{error} = 'XXXX'; # Set test error
is($ua->error(), 'XXXX', 'WebService::Gyazo->useOk(\'error\')');
is($ua->isError(), 1, 'WebService::Gyazo->useOk(\'isError\')');