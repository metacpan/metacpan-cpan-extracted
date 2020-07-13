#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Data::Dumper;
use Mojo::UserAgent;
use WebService::AntiCaptcha;

my $ua = Mojo::UserAgent->new;

my $wac = WebService::AntiCaptcha->new(
    clientKey => $ENV{ANTICAPTCHA_CLIENTKEY} || die 'ENV ANTICAPTCHA_CLIENTKEY is required',
);

my $res = $ua->get('https://client-demo.arkoselabs.com/solo-animals')->result;
# public_key: "029EF0D3-41DE-03E1-6971-466539B47725",
my ($public_key) = ($res->body =~ m{public_key: "(.*?)"});
die unless $public_key;
say "# Got key: $public_key";

## recaptcha handle
my $wac_res = $wac->createTask({
    type => 'FunCaptchaTaskProxyless',
    websiteURL => 'https://client-demo.arkoselabs.com/solo-animals',
    websitePublicKey => $public_key
}) or die $wac->errstr;
die $wac_res->{errorDescription} if $wac_res->{errorId};
my $taskId = $wac_res->{taskId};

sleep 30;
my $recaptcha_res;
while (1) {
    $wac_res = $wac->getTaskResult($taskId);
    die $wac_res->{errorDescription} if $wac_res->{errorId};

    warn Dumper(\$wac_res);
    if ($wac_res->{status} eq 'ready') {
        $recaptcha_res = $wac_res->{solution};
        last;
    } elsif ($wac_res->{status} eq 'processing') {
        sleep 10; # another sleep
    } else {
        # die; # should never happen
        sleep 10;
    }
}

if ($recaptcha_res) {
    say "# Got token: $recaptcha_res->{token}";
    $res = $ua->post('https://client-demo.arkoselabs.com/solo-animals/verify' => form => {
        'name' => 'Fayland',
        'verification-token' => $recaptcha_res->{token},
        'fc-token' => $recaptcha_res->{token},
    })->result;
    say $res->body =~ 'Solved' ? 'OK' : 'FAILED';
}
