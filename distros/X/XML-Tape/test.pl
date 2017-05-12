use File::Temp qw(:mktemp);
use Test::More tests => 27;

BEGIN { 
    use_ok('XML::Tape'); 
    use_ok('XML::Tape::Index'); 
}
require_ok('XML::Tape');
require_ok('XML::Tape::Index');

my $tmp_file = mktemp("/tmp/xmltapeXXXXXX");

@xmls = (
        '<foo/>' ,
        '<foo>&lt;</foo>' ,
        '<foo x="&amp;13"></foo>' ,
        '<foo><![CDATA[<<>>]]></foo>' ,
        '<foo>Āāऄअᠠ∀㐀&#x1d5d4;<!-- bar --></foo>' ,
        '<foo><?bar?></foo>' 
        );

ok($tape = XML::Tape::tapeopen($tmp_file,"w"), "tapeopen()");

my $ok = 0;
my $id = 0;
foreach (@xmls) {
    $ok += $tape->add_record($id, $id < 3 ? '1970-01-01' : '1970-02-02' ,$_);
    $id++;
}

ok($ok == @xmls, "add_record()");

ok($tape->tapeclose(), "tapeclose()");

ok($tape = XML::Tape::tapeopen($tmp_file, "r"), "tapeparse()");

my $i = 0;

while ($record = $tape->get_record()) {
    ok($xmls[$i] eq $record->getRecord(), "get_record()");
    $i++;
}

ok($tape->tapeclose(), "tapeclose()");

my $index;
ok($index = XML::Tape::Index::indexopen($tmp_file, "w"), "indexopen()");
ok($index->reindex() == @xmls, "reindex()");
ok($index->indexclose(),  "indexclose()");

ok($index = XML::Tape::Index::indexopen($tmp_file, "r"), "indexopen()");

my $ok = 0;
for (my $id = 0; $id < @xmls ; $id++) {
   if ($index->get_record($id) eq $xmls[$id]) {
       $ok++;
   }
   else {
       warn $index->get_record($id);
       warn "failed to find $id";
   }
}
ok($ok == @xmls, "get_record()");

my $count = 0;
for (my $r = $index->list_identifiers(); defined($r) ; $r = $index->list_identifiers($r->{token})) {
    $count++;
}
ok($count == @xmls, "list_identifiers()");

my $count = 0;
for (my $r = $index->list_identifiers('1970-01-01','1970-02-02'); defined($r) ; $r = $index->list_identifiers($r->{token})) {
    $count++;
}
ok($count == @xmls/2, "list_identifiers(FROM,UNTIL)");

my $count = 0;
for (my $r = $index->list_identifiers('1970-01-02',undef); defined($r) ; $r = $index->list_identifiers($r->{token})) {
    $count++ if ($r->{identifier} >= 3);
}
ok($count == @xmls/2, "list_identifiers(FROM,undef)");

my $count = 0;
for (my $r = $index->list_identifiers(undef,'1970-01-2'); defined($r) ; $r = $index->list_identifiers($r->{token})) {
    $count++ if ($r->{identifier} < 3);
}
ok($count == @xmls/2, "list_identifiers(undef,UNTIL)");


ok($index->indexclose(),  "indexclose()");

ok(XML::Tape::Index::indexexists($tmp_file), "indexexists()");
ok(XML::Tape::Index::indexdrop($tmp_file), "indexdrop()");
unlink $tmp_file;
