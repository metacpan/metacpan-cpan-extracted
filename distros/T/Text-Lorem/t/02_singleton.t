#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok("Text::Lorem");
ok( my $object = Text::Lorem->new(),            "Made a new object" );
ok( my $words = $object->words(3),              "Got some words" );
ok( my $object_bis = Text::Lorem->new(),            "Made a new object" );
ok( my $words_bis = $object_bis->words(3),              "Got some words" );
