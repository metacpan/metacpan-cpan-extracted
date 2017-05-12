use strict;
use warnings;

use Test::More tests => 10;
use Blosxom::Entry::Twitter;
use Error qw(:try);

my $entry = Blosxom::Entry::Twitter->new();

isa_ok($entry, 'Blosxom::Entry::Twitter');

ok(  $entry->getLines() == 0, "No lines yet");

$entry->addLine("Linea 1",'Thu Jan 13 14:26:49 +0000 2011');
ok(  $entry->getLines() == 1, "First line added");

$entry->addLine("Linea 2",'Thu Jan 13 13:49:27 +0000 2011');
ok(  $entry->getLines() == 2, "Second line added");

$entry->addLine("Linea 3",'Thu Jan 13 18:09:00 +0000 2011');
ok(  $entry->getLines() == 3, "Third line added");

my @entry = $entry->getLines();

ok( $entry[0] eq "Linea 2", "First line ordered by date");
ok( $entry[1] eq "Linea 1", "Second line ordered by date");
ok( $entry[2] eq "Linea 3", "Third line ordered by date");

my $fullEntry = "\n" .
"<ul>\n" .
"    <li>Linea 2</li>\n" .
"    <li>Linea 1</li>\n" .
"    <li>Linea 3</li>\n" .
"</ul>";

is (  $entry->getEntry(), $fullEntry, "Full text (no title)" );

$entry->setTitle("PEPE");
$fullEntry = "PEPE" . $fullEntry;
is ( $entry->getEntry(), $fullEntry, "Full text plus title" );



