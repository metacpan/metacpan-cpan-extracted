#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok("Text::Lorem::More");
ok( my $lorem = Text::Lorem::More->new(), "Instantiate a Text::Lorem::More object" );
ok( my $name = $lorem->name, "Generate a name" );
like( $name, qr/^[A-Z]/, "First letter of name is uppercase" );
ok( my $fullname = $lorem->fullname, "Generate a fullname (first and last)" );
like( $fullname, qr/^(?:[A-Z][a-z]*(\s|$)){2}/, "First letter of firstname and lastname is uppercase" );
like( $lorem->sentence, qr/^[A-Z].*\.$/, "Sentence has a capital first letter and a period at the end" );
unlike($lorem->email, qr/domainname/, "Test for a bug");


#ok( my $words = $object->words(3),              "Got some words" );
#is( my @foo = split( /\s+/, $words ), 3,        "There were 3 words" );
#ok( my $sentences = $object->sentences(3),      "Got some sentences" );
#is( my @bar = split( /\./, $sentences ), 3,     "There were 3 sentences" );
#ok( my $paragraphs = $object->paragraphs(4),    "Got some paragraphs" );
#is( my @baz = split ( /\n\n/, $paragraphs ), 4, "There were 4 paragraphs" );
