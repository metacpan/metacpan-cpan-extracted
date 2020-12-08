#!/usr/bin/env perl
use Test::More tests=>2;
use strict;
use warnings;

BEGIN {
  use_ok(qw(Test::WWW::Simple));
}

like mech->agent(), qr/Windows/, "default agent";

