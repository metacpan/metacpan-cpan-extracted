#!perl

use strict;
use warnings;

use Test::More;

use_ok($_) for (qw(Weasel Weasel::Session
  Weasel::Element Weasel::Element::Document
  Weasel::DriverRole));

done_testing;

