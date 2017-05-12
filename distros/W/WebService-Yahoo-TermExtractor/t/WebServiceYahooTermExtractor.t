#!perl -w
use strict;
use Test::More tests => 2;

BEGIN {
  use_ok('WebService::Yahoo::TermExtractor');
}

can_ok('WebService::Yahoo::TermExtractor', 'get_terms');
