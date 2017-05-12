#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
  use_ok('dtRdr::Plugins');
  use_ok('dtRdr::Plugins::Base');
  use_ok('dtRdr::Plugins::Book');
  use_ok('dtRdr::Plugins::Library');
}

dtRdr::Plugins->init();

# vi:syntax=perl:ts=2:sw=2:et:sta
