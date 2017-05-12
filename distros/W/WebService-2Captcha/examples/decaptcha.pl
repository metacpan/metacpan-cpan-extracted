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

my $res = $w2c->decaptcha("$Bin/captcha.png") or die $w2c->errstr;
print "Got text as " . $res->{text} . "\n";

if (0) {
    $w2c->reportbad($res->{id}) or die $w2c->errstr;
}

1;