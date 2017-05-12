#!perl -w

use strict;
use Test::More tests => 2;
use XS::Assert;

use XSLoader;
XSLoader::load('XS::Assert');

ok  eval{ XS::Assert::assert_success(); 1 };
ok !eval{ XS::Assert::assert_fail(); 1 };
diag $@ if -d 'inc/.author';
