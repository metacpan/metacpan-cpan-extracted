#!/usr/bin/perl

use strict;
# use warnings;
use WebService::MyAffiliates;
use Test::More;

plan skip_all => "ENV MYAFFILIATES_USER/MYAFFILIATES_PASS/MYAFFILIATES_HOST is required to continue."
    unless $ENV{MYAFFILIATES_USER}
    and $ENV{MYAFFILIATES_PASS}
    and $ENV{MYAFFILIATES_HOST};
my $aff = WebService::MyAffiliates->new(
    user => $ENV{MYAFFILIATES_USER},
    pass => $ENV{MYAFFILIATES_PASS},
    host => $ENV{MYAFFILIATES_HOST});

my $token_info = $aff->decode_token('PQ4YXsO2q5mVAv0U_Fv2nWNd7ZgqdRLk');
# use Data::Dumper;
# diag(Dumper(\$token_info));
is(ref $token_info->{'TOKEN'}, 'HASH', 'We got data back about one token, so the ->{\'TOKEN\'} key is a hash ref.');
ok($token_info->{TOKEN}->{USER}, 'USER exists');

my $token_info = $aff->decode_token('PQ4YXsO2q5mVAv0U_Fv2nWNd7ZgqdRLk', 'PQ4YXsO2q5mVAv0U_Fv2nWNd7ZgqdRLk');
is(ref $token_info->{'TOKEN'}, 'ARRAY', 'Got data back about two tokens, so the ->{\'TOKEN\'} key is an array ref.');

my $affiliate_id = $aff->get_affiliate_id_from_token('jGZUKO3JWgyVAv0U_Fv2nVOqZLGcUW5p');
is($affiliate_id, 6, 'Token has affiliate id 6');

done_testing();

1;
