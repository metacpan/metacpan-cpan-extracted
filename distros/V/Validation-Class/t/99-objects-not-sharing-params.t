#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Test::More;

plan skip_all => 'TODO: Fix bug' if ! $ENV{'DEVELOPMENT_TESTS'};

package MyApp::Person;

use Validation::Class;

field 'name';

package main;

my $person1 = MyApp::Person->new(params => { name => 'foo' });
my $person2 = MyApp::Person->new(params => { name => 'bar' });

diag $person1->params->get('name');
diag $person2->params->get('name');

ok $person1->name ne $person2->name, 'parameter values are different';

done_testing();
