#!perl -w
use strict;

use Test::More tests => 324;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

my @aText;
my $text;

my $tableCount = 0;
my $rowCount = 0;
my $colCount = 0;


push(@aText, { pre => ">", text => $text = "Para1 with some text, now some text in ", post => "<"});
is($oWriter->WriteParagraph($text), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "Empty table", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");

is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;
$rowCount++;
$colCount++;
is($oWriter->TableEnd(), 1, "TableEnd");



push(@aText, { pre => ">", text => $text = "Single cell table", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph(""), 1, "newline");
is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;
is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;
is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
push(@aText, { pre => ">", text => $text = "single cell text", post => "<"});
is($oWriter->Write($text), 1, "Write");
is($oWriter->TableEnd(), 1, "TableEnd");



push(@aText, { pre => ">", text => $text = "Two cells, heading and stuff", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph(""), 1, "newline");
is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;
is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;

is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
push(@aText, { pre => ">", text => $text = "First col", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "Write");

push(@aText, { pre => ">", text => $text = "and some regular text", post => "</"});
is($oWriter->WriteParagraph($text), 1, "Write");


is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
push(@aText, { pre => ">", text => $text = "Second col", post => "</h2"});
is($oWriter->WriteParagraph($text, heading => 2), 1, "Write");

push(@aText, { pre => ">", text => $text = "and some regular text", post => "</"});
is($oWriter->WriteParagraph($text), 1, "Write");

push(@aText, { pre => ">", text => $text = "And yet some more stuff here", post => "</h2"});
is($oWriter->WriteParagraph($text, heading => 2), 1, "Write");


is($oWriter->TableEnd(), 1, "TableEnd");



push(@aText, { pre => ">", text => $text = "Two tables with no separating text (will merge)", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph(""), 1, "newline");

is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;
is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;
is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
push(@aText, { pre => ">", text => $text = "First table text", post => "<"});
is($oWriter->Write($text), 1, "Write");
is($oWriter->TableEnd(), 1, "TableEnd");

is($oWriter->TableBegin(), 1, "TableBegin"); 
is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;
is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
push(@aText, { pre => ">", text => $text = "Second table text", post => "<"});
is($oWriter->Write($text), 1, "Write");
is($oWriter->TableEnd(), 1, "TableEnd");




push(@aText, { pre => ">", text => $text = "One row, many cols", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph(""), 1, "newline");

is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;
is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;

for my $col (1..20) {
    is($oWriter->TableColumnBegin(), 1, "TableBegin"); $colCount++;
    push(@aText, { pre => ">", text => $text = "c$col text", post => "<"});
    is($oWriter->Write($text), 1, "Write");
}

is($oWriter->TableEnd(), 1, "TableEnd");




push(@aText, { pre => ">", text => $text = "Many rows, many cols", post => "</h1"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph(""), 1, "newline");

is($oWriter->TableBegin(), 1, "TableBegin"); $tableCount++;

for my $row (1..15) {
    is($oWriter->TableRowBegin(), 1, "TableBegin"); $rowCount++;
 
    for my $col (1..4) {
        is($oWriter->TableColumnBegin(), 1, "TableColumnBegin col ($col) "); $colCount++;
        push(@aText, { pre => ">", text => $text = "r$row, c$col text", post => "<"});
        is($oWriter->Write($text), 1, "Write");
    }
}    
is($oWriter->TableEnd(), 1, "TableEnd");





is($oWriter->SaveAs("09-table.doc"), 1, "SaveAs HTML ok");
my $file = "09-table.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile($file);

for my $rhText (@aText) {
    my $cleanHtml = $html; $cleanHtml =~ s/\s//gs;
    my $cleanRex = "$rhText->{pre}$rhText->{text}$rhText->{post}"; $cleanRex =~ s/\s//gs; $cleanRex = quotemeta($cleanRex);
    like($cleanHtml, qr/$cleanRex/s, " found text ($rhText->{text}) in file");
}

my $actualTableCount = () = $html =~ /<table\b/gs;
is($actualTableCount, $tableCount, " correct number of <table> tags");

my $actualRowCount = () = $html =~ /<tr\b/gs;
is($actualRowCount, $rowCount, " correct number of <tr> tags");

my $actualColCount = () = $html =~ /<td\b/gs;
is($actualColCount, $colCount, " correct number of <td> tags");



$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
