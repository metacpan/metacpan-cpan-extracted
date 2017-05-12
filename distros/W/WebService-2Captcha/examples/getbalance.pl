#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WebService::2Captcha;

die "Please set ENV KEY_2CAPTCHA" unless $ENV{KEY_2CAPTCHA};

my $w2c = WebService::2Captcha->new(
    key => $ENV{KEY_2CAPTCHA}
);

my $b = $w2c->getbalance() or die $w2c->errstr;
print "Balance: $b\n";

1;