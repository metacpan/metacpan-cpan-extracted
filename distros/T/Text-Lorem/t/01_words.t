#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use_ok("Text::Lorem");
ok( my $object = Text::Lorem->new(),            "Made a new object" );
ok( my $words = $object->words(3),              "Got some words" );
is( my @foo = split( /\s+/, $words ), 3,        "There were 3 words" );
ok( my $sentences = $object->sentences(3),      "Got some sentences" );
is( my @bar = split( /\./, $sentences ), 3,     "There were 3 sentences" );
ok( my $paragraphs = $object->paragraphs(4),    "Got some paragraphs" );
is( my @baz = split ( /\n\n/, $paragraphs ), 4, "There were 4 paragraphs" );

