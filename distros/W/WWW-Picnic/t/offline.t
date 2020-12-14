#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WWW::Picnic'); }

my $fake_user = 'xxx@xxx.xxx';
my $fake_pass = 'xxxxxxxxx';
my $fake_country = 'XX';

my $picnic = WWW::Picnic->new(
  user => $fake_user,
  pass => $fake_pass,
  country => $fake_country,
);

isa_ok($picnic, 'WWW::Picnic');
is($picnic->user, $fake_user, "User is user");
is($picnic->pass, $fake_pass, "Pass is pass");
is($picnic->country, $fake_country, "Country is country");

done_testing;
