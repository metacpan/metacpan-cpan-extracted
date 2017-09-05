#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WebService::AntiCaptcha;
use Data::Dumper;

my $wac = WebService::AntiCaptcha->new(
    clientKey => $ENV{ANTICAPTCHA_CLIENTKEY} || die 'ENV ANTICAPTCHA_CLIENTKEY is required',
);

my $res = $wac->getBalance;
print Dumper(\$res);