use Test::More tests=>2;
use OGDL::Parser;
BEGIN { use_ok('OGDL::Graph') };

my $g=OGDL::Graph->new("test");
$g->gadd("a.b.c");
$g->gadd("a.b2.c[5]");
$g->gadd("a.b*.c*.check");
open F, ">test3.g";
$g->print("printroot"=>0, "singlequote"=>1, "noblockquote"=>1, "filehandle"=>*F);
close F;


$g=OGDL::Parser::fileToGraph("test3.g");
$s=$g->getname("a.b2.c[3].[0]");
ok($s eq "check");
