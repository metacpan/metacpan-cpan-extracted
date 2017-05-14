#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;

use_ok('Test::MockObject::Extra');

my $mock = Test::MockObject::Extra->new();

$mock->fake_module( 'Dummy', foo => sub { 'fake dummy' } );
is(Dummy::foo(), 'fake dummy', "Faked Dummy module");
$mock->unfake_module();

use_ok('Dummy', "Loaded 'real' Dummy module");
is(Dummy::foo(), 'bar', "Real Dummy method called");