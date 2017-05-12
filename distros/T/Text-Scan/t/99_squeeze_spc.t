#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 2 + 2 + 2 + 2 + 2 + 2 + 6 }

$ref = new Text::Scan;
$ref->usewild();
$ref->ignore("<>()");
$ref->charclass("\t\n "); # space equivalent
$ref->boundary("?.!\n\t "); # need space-equivs here if not in the ignore class
$ref->squeezeblanks();

$ref->insert('bla', 'bla');

my @answer = $ref->scan("yada b<>la yada");
ok($answer[0], "b<>la");
ok($answer[1], 'bla');

@answer = $ref->scan("yada \nbla yada");
ok($answer[0], "bla");
ok($answer[1], 'bla');

@answer = $ref->scan("yada bla\n yada");
ok($answer[0], "bla");
ok($answer[1], 'bla');


$ref->insert('one two', 'one two');

@answer = $ref->scan("yada ??one\n two yada");
ok($answer[0], "one\n two");
ok($answer[1], 'one two');

@answer = $ref->scan("yada one \ntwo yada");
ok($answer[0], "one \ntwo");
ok($answer[1], 'one two');

@answer = $ref->scan("yada one\ntwo yada");
ok($answer[0], "one\ntwo");
ok($answer[1], 'one two');


# Combine with wildcards
$ref->insert('gorillas * * mist', 'gorillas * * mist');

@answer = $ref->scan("what if gorillas hate \nthe mist "); 
ok($answer[0], "gorillas hate \nthe mist");
ok($answer[1], 'gorillas * * mist');

@answer = $ref->scan("what if gorillas hate\n the mist "); 
ok($answer[0], "gorillas hate\n the mist");
ok($answer[1], 'gorillas * * mist');



$ref->insert('yoda * yoda', 'yoda * yoda');
@answer = $ref->scan("yo yo yo yo yoda \nisa<>hata yoda is");
ok($answer[0], "yoda \nisa<>hata yoda");
ok($answer[1], 'yoda * yoda');

exit 0;






