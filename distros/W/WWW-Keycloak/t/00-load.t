#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::Keycloak
  WWW::Keycloak::Admin
  WWW::Keycloak::Auth
  WWW::Keycloak::Diff
  WWW::Keycloak::Error
  WWW::Keycloak::Error::API
  WWW::Keycloak::Error::Network
  WWW::Keycloak::Error::Validation
  WWW::Keycloak::OIDC
  WWW::Keycloak::Role::HTTP
)) {
  use_ok($_);
}

done_testing;
