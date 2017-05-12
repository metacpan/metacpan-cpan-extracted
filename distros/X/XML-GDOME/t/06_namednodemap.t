use Test;
BEGIN { plan tests => 102 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $doc = XML::GDOME->createDocFromURI("t/xml/test-namednodemap.xml", GDOME_LOAD_PARSING);
my $el = $doc->documentElement;
my $nnm = $el->attributes;

ok($nnm->length,25);

my $len = 25;
for my $i (1 .. $len) {
  my $gnode = $nnm->getNamedItem("FOO$i");
  ok(defined($gnode));
}

for my $i (0 .. $len - 1) {
  my $gnode = $nnm->item($i);
  ok(defined($gnode));
}
ok($nnm->item(25),undef);

for (my $i=1; $i<=$len; $i+=2) {
  my $gnode = $nnm->removeNamedItem("FOO$i");
  ok(defined($gnode));
  $gnode = $nnm->getNamedItem("FOO$i");
  ok($gnode,undef);
}

ok($nnm->length,12);

for (my $i=2; $i<=$len; $i+=2) {
  my $gnode = $nnm->getNamedItem("FOO$i");
  ok(defined($gnode));
}

my $gnode = $nnm->removeNamedItem("FOOBAR");
ok($gnode,undef);

my $a = $nnm->removeNamedItem("FOO6");
$gnode = $nnm->getNamedItem("FOO6");
ok($gnode,undef);
my $b = $nnm->removeNamedItem("FOO8");
$gnode = $nnm->getNamedItem("FOO8");
ok($gnode,undef);
my $c = $nnm->removeNamedItem("FOO10");
$gnode = $nnm->getNamedItem("FOO10");
ok($gnode,undef);

$gnode = $nnm->setNamedItem($a);
ok($gnode,undef);
$gnode = $nnm->getNamedItem("FOO6");
ok(defined($gnode));
$gnode = $nnm->setNamedItem($b);
ok($gnode,undef);
$gnode = $nnm->getNamedItem("FOO8");
ok(defined($gnode));
$gnode = $nnm->setNamedItem($c);
ok($gnode,undef);
$gnode = $nnm->getNamedItem("FOO10");
ok(defined($gnode));

