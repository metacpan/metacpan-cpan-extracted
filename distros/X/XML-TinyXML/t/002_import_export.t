
use strict;

use Test::More tests => 4;
BEGIN { use_ok('XML::TinyXML') };

my $txml = XML::TinyXML->new();
$txml->loadFile("./t/t.xml");
my $out = $txml->dump;

# here we KNOW that t.xml should have XML::TinyXML to produce exactly the same output
# note that this isn't always true ... since XML::TinyXML never expands leading tabs 
# and, in general, ignores whitespaces (apart those in the value)
open(IN, "./t/t.xml"); 
my $in = "";
while(<IN>) {
    $in .= $_;
}
close(IN);
ok( $out eq $in, "import/export" );


$txml->ignoreBlanks(0);
$txml->ignoreWhiteSpaces(0);
$txml->loadFile("./t/t-noblanks.xml");

open(IN, "./t/t-noblanks.xml"); 
$in = "";
while(<IN>) {
    $in .= $_;
}
chomp($in);
close(IN);
$out = $txml->dump;
ok( $out eq $in, "import/export" );
$txml->ignoreBlanks(1);
$txml->ignoreWhiteSpaces(0);
$txml->loadFile("./t/t-noblanks.xml");

my $node = $txml->getNode("/qtest");
is ($node->value, ' ');

#warn "IN '$in'";
#warn "OUT '$out'";
