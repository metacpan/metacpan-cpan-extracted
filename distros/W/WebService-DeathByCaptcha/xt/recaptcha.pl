#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Data::Dumper;
use WWW::Mechanize::GZip;
use WebService::DeathByCaptcha;

my $ua = WWW::Mechanize::GZip->new(
    agent   => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:50.0) Gecko/20100101 Firefox/50.0',
    stack_depth => 1, autocheck => 0, timeout => 20,
    cookie_jar => {},
);

die 'ENV DEATHBYCAPTCHA_USER is required' unless $ENV{DEATHBYCAPTCHA_USER};
die 'ENV DEATHBYCAPTCHA_PASS is required' unless $ENV{DEATHBYCAPTCHA_PASS};
my $dbc = WebService::DeathByCaptcha->new(
    username => $ENV{DEATHBYCAPTCHA_USER},
    password => $ENV{DEATHBYCAPTCHA_PASS},
);

my $res = $ua->get('https://www.google.com/recaptcha/api2/demo');

## recaptcha handle
my $dbc_res = $dbc->recaptcha({
    googlekey => '6Le-wvkSAAAAAPBMRTvw0Q4Muexq9bi0DJwx_mJ-',
    pageurl => 'https://www.google.com/recaptcha/api2/demo',
}) or die $dbc->errstr;
die $dbc_res->{error} if $dbc_res->{error};
say Dumper(\$dbc_res);
my $captcha_id = $dbc_res->{captcha};

sleep 60;
my $recaptcha_res;
while (1) {
    $dbc_res = $dbc->get($captcha_id);
    die $dbc_res->{error} if $dbc_res->{error};

    warn Dumper(\$dbc_res);
    if ($dbc_res->{status} eq '0' and $dbc_res->{text}) {
        $recaptcha_res = $dbc_res->{text};
        last;
    } elsif ($dbc_res->{status} eq '0') {
        sleep 5; # another sleep
    } else {
        die; # should never happen
    }
}

if ($recaptcha_res) {
    $res = $ua->post('https://www.google.com/recaptcha/api2/demo', Content => [
        'g-recaptcha-response' => $recaptcha_res,
    ]);
    say Dumper(\$res);
}
