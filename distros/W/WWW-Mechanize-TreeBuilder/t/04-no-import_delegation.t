package My::Mech;
use Moose;

extends 'WWW::Mechanize';
with 'WWW::Mechanize::TreeBuilder';

package main;
use strict;
use warnings;
use Test::More tests => 1;

eval { My::Mech->import };
diag $@ if $@;
ok !$@, q{My::Mech->import() doesn't explode};
