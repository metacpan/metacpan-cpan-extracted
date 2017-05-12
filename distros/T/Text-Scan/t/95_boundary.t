#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 1 + 2 + 4 + 4 }

$dict1 = new Text::Scan;
$dict2 = new Text::Scan;
$dict3 = new Text::Scan;
$dict4 = new Text::Scan;

# $dict1 gets default boundary of single space plus null byte
$dict2->boundary('a?');
$dict3->boundary('');
$dict4->boundary(". ");
$dict4->ignore("\n");

$dict1->insert('bla', 'bla');
$dict2->insert('bla', 'bla');
$dict3->insert('bla', 'bla');
$dict4->insert('bla', 'bla');

my @answer = $dict1->scan("Hablas tu ingles? No habla?");
ok($#answer, -1);

@answer = $dict2->scan("Hablas tu ingles? No habla?");
ok($answer[0], 'bla');
ok($answer[1], 'bla');

@answer = $dict3->scan("Hablas tu ingles? No habla?");
ok($answer[0], 'bla');
ok($answer[1], 'bla');
ok($answer[2], 'bla');
ok($answer[3], 'bla');

@answer = $dict4->scan("I say bla... What about that?\nbla.");
ok($answer[0], 'bla');
ok($answer[1], 'bla');
ok($answer[2], 'bla');
ok($answer[3], 'bla');

exit 0;

