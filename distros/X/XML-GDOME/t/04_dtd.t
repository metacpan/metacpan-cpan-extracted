use Test;
BEGIN { plan tests => 18 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $doc = XML::GDOME->createDocFromURI("t/xml/test-dtd.xml", GDOME_LOAD_VALIDATING);
my $dt = $doc->doctype;
ok($dt->name, "TEST-DTD");
ok($dt->publicId, undef);
ok($dt->systemId, "test-dtd.dtd");
ok($dt->internalSubset, "<!DOCTYPE TEST-DTD SYSTEM \"test-dtd.dtd\">");

my $ents = $dt->entities;
ok($ents->length, 5);

my $nots = $dt->notations;
ok($nots->length, 5);

my $ent = $ents->getNamedItem("FOO1");
ok($ent->nodeName, "FOO1");
ok($ent->publicId, undef);
ok($ent->systemId, undef);
ok($ent->notationName, undef);

$ent = $ents->getNamedItem("FOO2");
ok($ent->nodeName, "FOO2");
ok($ent->publicId, undef);
ok($ent->systemId, "file.type2");
ok($ent->notationName, "type2");

my $not = $nots->getNamedItem("type1");
ok($not->nodeName, "type1");
ok($not->publicId, undef);
ok($not->systemId, "program1");

