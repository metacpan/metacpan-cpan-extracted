#!/usr/bin/env perl
use strict;
use warnings;

use JSON::MaybeXS qw(encode_json);
use WWW::Zitadel::OIDC;

my $issuer = $ENV{ZITADEL_ISSUER}
    or die "Set ZITADEL_ISSUER\n";
my $token = $ENV{ZITADEL_ACCESS_TOKEN}
    or die "Set ZITADEL_ACCESS_TOKEN\n";

my $oidc = WWW::Zitadel::OIDC->new(issuer => $issuer);
my $claims = $oidc->verify_token(
    $token,
    (defined $ENV{ZITADEL_AUDIENCE} ? (audience => $ENV{ZITADEL_AUDIENCE}) : ()),
);

print encode_json($claims), "\n";
