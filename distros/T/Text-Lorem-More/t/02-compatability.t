#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use_ok("Text::Lorem::More");
ok( my $object = Text::Lorem::More->new(),            "Made a new object" );
ok( my $words = $object->words(3),              "Got some words" );
is( my @foo = split( /\s+/, $words ), 3,        "There were 3 words" );
ok( my $sentences = $object->sentences(3),      "Got some sentences" );
is( my @bar = split( /\./, $sentences ), 3,     "There were 3 sentences" );
ok( my $paragraphs = $object->paragraphs(4),    "Got some paragraphs" );
is( my @baz = split ( /\n\n/, $paragraphs ), 4, "There were 4 paragraphs" );

ok( $words = $object->words(3),              "Got some words" );
ok( my $object_bis = Text::Lorem::More->new(),            "Made a new object" );
ok( my $words_bis = $object_bis->words(3),              "Got some words" );
