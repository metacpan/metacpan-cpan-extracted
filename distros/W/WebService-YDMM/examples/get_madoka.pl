#!/usr/bin/env perl
use strict;
use warnings;

use utf8;
use feature 'say';

use WebService::YDMM;

my $dmm = WebService::YDMM->new(
    affiliate_id => $ENV{affiliate_id},
    api_id       => $ENV{api_id},
);

my $items = $dmm->item("DMM.com", +{ keyword => "魔法少女まどか☆マギカ")->{items};

say $items->[0]->{iteminfo}->{title};
