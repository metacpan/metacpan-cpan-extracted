#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::Authentik
  WWW::Authentik::API
  WWW::Authentik::Diff
  WWW::Authentik::Error
  WWW::Authentik::Error::API
  WWW::Authentik::Error::Network
  WWW::Authentik::Error::Validation
  WWW::Authentik::OIDC
  WWW::Authentik::Role::HTTP
)) {
  use_ok($_);
}

done_testing;
