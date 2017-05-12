#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 2 + 2 + 2 + 2 + 2 + 2 }

$ref = new Text::Scan;
$ref->usewild();
$ref->ignore("\n\r<>()");

$ref->insert('bla', 'bla');

my @answer = $ref->scan("yada b\n<>la yada");
ok($answer[0], "b\n<>la");
ok($answer[1], 'bla');

@answer = $ref->scan("yada \nbla yada");
ok($answer[0], "bla");
ok($answer[1], 'bla');

@answer = $ref->scan("yada bla\n yada");
ok($answer[0], "bla");
ok($answer[1], 'bla');


# Combine with wildcards
$ref->insert('gorillas * * mist', 'gorillas * * mist');

@answer = $ref->scan("what if gorillas hate \nthe mist "); 
ok($answer[0], "gorillas hate \nthe mist");
ok($answer[1], 'gorillas * * mist');

@answer = $ref->scan("what if gorillas hate\n the mist "); 
ok($answer[0], "gorillas hate\n the mist");
ok($answer[1], 'gorillas * * mist');



$ref->insert('yoda * yoda', 'yoda * yoda');
@answer = $ref->scan("yo yo yo yo yoda isa\n<>hata yoda is");
ok($answer[0], "yoda isa\n<>hata yoda");
ok($answer[1], 'yoda * yoda');

exit 0;






