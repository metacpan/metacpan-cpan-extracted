#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 1 + 1 + 1 + 1 }

my $dict = new Text::Scan;
$dict->usewild();
$dict->ignorecase();
$dict->charclass('?.!-/;: '); 
$dict->ignore("\n\r’'");
$dict->ignore('#$%&()+,<=>@[\]^`{|}~¡£¤¥');
$dict->ignore('¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾');
$dict->ignore('¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×');
$dict->ignore('ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïð');
$dict->ignore('ñòóôõö÷øùúûüýþÿ');
$dict->boundary("\n\r?.!-/;: ");

ok($dict);

my $sbdict = new Text::Scan;
$sbdict->boundary('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ');

ok($sbdict);

$dict->insert("GEs acquisition", "bingo");
$dict->insert("kg", "kg");

my @answers = $dict->scan("LBO groaned.\n\n GE’s acquisition last fall");
ok($answers[0], "GE’s acquisition");

@answers = $dict->scan("It appears that the explosive charge weighed over 10 kg. Shops and businesses at the site of the explosion were seriously damaged.");
ok($answers[0], "kg");

exit 0;

