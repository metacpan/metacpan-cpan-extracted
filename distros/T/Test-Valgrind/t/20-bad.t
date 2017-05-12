#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

eval {
 require Test::Valgrind;
 Test::Valgrind->import(
  action => 'Test::Valgrind::Test::Action',
 );
};
if ($@) {
 diag $@;
 plan skip_all
        => 'Test::Valgrind is required to test your distribution with valgrind';
}

eval {
 require XSLoader;
 XSLoader::load('Test::Valgrind', $Test::Valgrind::VERSION);
};
if ($@) {
 diag $@;
} else {
 diag "leaking some bytes!";
 Test::Valgrind::leak();
}
