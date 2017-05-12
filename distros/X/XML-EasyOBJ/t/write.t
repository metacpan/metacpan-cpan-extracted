
use strict;
use Test;
use XML::EasyOBJ;
use FindBin qw/$Bin/;

BEGIN { plan tests => 11 }

ok( my $doc = XML::EasyOBJ->new( -type => 'new', -param => "root" ) );

$doc->level1_a->level2_a->setString("L1AL2A");
$doc->level1_a->level2_b->setString("L1AL2B");
$doc->level1_a->level2_c->setString("L1AL2C");
$doc->level1_b->level2_a->setString("L1BL2A");
$doc->level1_b->level2_b->setString("L1BL2B");
$doc->level1_c->level2_a->setString("L1CL2A");

$doc->level1_a->level2_b->setAttr("L1AL2B", 'test="1"');
$doc->level1_b->level2_b->setAttr("L1BL2B", 'test<>2');
$doc->level1_c->level2_a->setAttr("L1CL2A", 'test<>3');

$doc->getDomObj->printToFile("$Bin/write.xml");

ok( my $doc2 = XML::EasyOBJ->new( -type => 'file', -param => "$Bin/write.xml" ) );

ok( $doc2->level1_a->level2_a->getString, "L1AL2A" );
ok( $doc2->level1_a->level2_b->getString, "L1AL2B" );
ok( $doc2->level1_a->level2_c->getString, "L1AL2C" );
ok( $doc2->level1_b->level2_a->getString, "L1BL2A" );
ok( $doc2->level1_b->level2_b->getString, "L1BL2B" );
ok( $doc2->level1_c->level2_a->getString, "L1CL2A" );

ok( $doc2->level1_a->level2_b->getAttr("L1AL2B"), 'test="1"' );
ok( $doc2->level1_b->level2_b->getAttr("L1BL2B"), 'test<>2' );
ok( $doc2->level1_c->level2_a->getAttr("L1CL2A"), 'test<>3' );

