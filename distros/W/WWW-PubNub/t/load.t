#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::PubNub
  WWW::PubNub::Message
)) {
  use_ok($_);
}

done_testing;

