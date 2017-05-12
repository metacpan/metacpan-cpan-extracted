#!/usr/bin/env perl -w
use strict;
use lib 't/lib2';
use Test::More tests => 5;

use Selfvar;

my $s = new Selfvar;
$s->pet("oreo");

is $s->pet, "oreo";

is( Selfvar::echo("hi"), "hi" );
is( Selfvar::echo0("hi"), "hi" );
is( Selfvar::echo1("hi"), "hi" );
is( Selfvar::echo2("hi"), "hi" );

