#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;

# TODO:
# * Better prerequisites checking
# * Split up the tests into separate files

# First, check the prerequisites
use_ok('Test::Builder')
  or BAILOUT("The tests require Test::Builder");
use_ok('HTML::TokeParser')
  or BAILOUT("The tests require HTML::TokeParser");
use_ok('Test::HTML::Content')
  or Test::Builder::BAILOUT("The tests require Test::HTML::Content - this shouldn't happen at all");
