#!perl -w
use strict;

use Test::More tests => 18;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );


my @aText;
my $text;
my $file;
my $html;
my $oWriter;


ok($oWriter = Win32::Word::Writer->new(), "new ok");
$text = "Para1 with some text";
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");
is($oWriter->WriteParagraph("new para"), 1, "WriteParagraph");

$file = "05a-writeparagraph1.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
is($oWriter->SaveAs("$file.doc"), 1, "SaveAs HTML ok");
$oWriter->Checkpoint();    #To release lock on file.
$html = WordTest::readFile($file);

ok($html =~ m|(<body.*?</h1>)|s, "Got first section");
my $first1 = $1;



ok($oWriter = Win32::Word::Writer->new(), "new ok");
is($oWriter->NewParagraph(heading => 1), 1, "WriteParagraph");
is($oWriter->Write($text), 1, "Write");
is($oWriter->WriteParagraph("new para"), 1, "WriteParagraph");

$file = "05a-writeparagraph2.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
$oWriter->Checkpoint();    #To release lock on file.
$html = WordTest::readFile($file);

ok($html =~ m|(<body.*?</h1>)|s, "Got first section");
my $first2 = $1;
#print "((($html)))\n";

ok($first2 !~ m{\Q>&nbsp;<\E}s, "No empty line above the heading 1");


is($first1, $first2, "NewParagraph and Writeparagraph are identical");


$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
