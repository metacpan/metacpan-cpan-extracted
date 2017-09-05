#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Data::Dumper;
use WWW::Mechanize::GZip;
use WebService::AntiCaptcha;

my $ua = WWW::Mechanize::GZip->new(
    agent   => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:50.0) Gecko/20100101 Firefox/50.0',
    stack_depth => 1, autocheck => 0, timeout => 20,
    cookie_jar => {},
);

my $wac = WebService::AntiCaptcha->new(
    clientKey => $ENV{ANTICAPTCHA_CLIENTKEY} || die 'ENV ANTICAPTCHA_CLIENTKEY is required',
);

my $res = $ua->get('https://www.google.com/recaptcha/api2/demo');

## recaptcha handle
my $wac_res = $wac->createTask({
    type => 'NoCaptchaTaskProxyless',
    websiteURL => 'https://www.google.com/recaptcha/api2/demo',
    websiteKey => '6Le-wvkSAAAAAPBMRTvw0Q4Muexq9bi0DJwx_mJ-'
}) or die $wac->errstr;
die $wac_res->{errorDescription} if $wac_res->{errorId};

sleep 20;
my $recaptcha_res;
while (1) {
    $wac_res = $wac->getTaskResult($wac_res->{taskId});
    die $wac_res->{errorDescription} if $wac_res->{errorId};

    warn Dumper(\$wac_res);
    if ($wac_res->{status} eq 'ready') {
        $recaptcha_res = $wac_res->{solution};
        last;
    } elsif ($wac_res->{status} eq 'processing') {
        sleep 5; # another sleep
    } else {
        die; # should never happen
    }
}

if ($recaptcha_res) {
    $res = $ua->post('https://www.google.com/recaptcha/api2/demo', Content => [
        'g-recaptcha-response' => $recaptcha_res->{gRecaptchaResponse},
    ]);
    say Dumper(\$res);
}
