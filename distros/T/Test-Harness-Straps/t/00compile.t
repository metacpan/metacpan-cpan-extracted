#!/usr/bin/perl -w

BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }
    else {
        unshift @INC, 't/lib';
    }
}

use Test::More tests => 5;

BEGIN { use_ok 'Test::Harness::Straps' }

diag( "Testing Test::Harness::Straps $Test::Harness::Straps::VERSION ",
      "under Perl $] and Test::More $Test::More::VERSION" )
      unless $ENV{PERL_CORE};

use_ok 'Test::Harness::Iterator';
use_ok 'Test::Harness::Assert';
use_ok 'Test::Harness::Point';
use_ok 'Test::Harness::Results';
