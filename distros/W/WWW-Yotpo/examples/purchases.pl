#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::Yotpo;
use Data::Dumper;

die "ENV YOTPO_CLIENT_ID and YOTPO_CLIENT_SECRET is required."
    unless $ENV{YOTPO_CLIENT_ID} and $ENV{YOTPO_CLIENT_SECRET};

my $yotpo = WWW::Yotpo->new(
    client_id => $ENV{YOTPO_CLIENT_ID},
    client_secret => $ENV{YOTPO_CLIENT_SECRET},
);

REDO:
my $access_token;
my $token_file = "$Bin/.token";
if (-e $token_file) {
    open(my $fh, '<', $token_file) or die $!;
    $access_token = do { local $/; <$fh> };
    close($fh);
    $access_token =~ s/^\s+|\s+$//g;
} else {
    my $token = $yotpo->oauth_token();
    die Dumper(\$token) unless $token->{access_token};
    $access_token = $token->{access_token};
    open(my $fh, '>', $token_file);
    print $fh $access_token;
    close($fh);
}

my $res = $yotpo->purchases(
    utoken => $access_token,
);

print Dumper(\$res);

1;