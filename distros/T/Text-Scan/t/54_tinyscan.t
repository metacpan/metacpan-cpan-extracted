#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 9 }

$ref = new Text::Scan;

my $term1 = "telephone me";
my $term2 = "telefax me";
my $term3 = "banana boat";

my $text1 = "Why don't you ever telephone me at work?";
my $text2 = "telefax me with more keys shall we...";
my $text3 = "banana boat in the mist";

$ref->insert($term1, $term1);
$ref->insert($term2, $term2);
$ref->insert($term3, $term3);

my @result = $ref->scan( $text1 );
my @answer = ( $term1, $term1 );

ok( $#result, $#answer );
ok($result[0], $answer[0] );
ok($result[1], $answer[1] );


@result = $ref->scan( $text2 );
@answer = ( $term2, $term2 );

ok( $#result, $#answer );
ok($result[0], $answer[0] );
ok($result[1], $answer[1] );


@result = $ref->scan( $text3 );
@answer = ( $term3, $term3 );

ok( $#result, $#answer );
ok($result[0], $answer[0] );
ok($result[1], $answer[1] );



