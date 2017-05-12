#!perl -w
use strict;

use Test::More tests => 21;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

is($oWriter->Open("data/open.doc"), 1, "Open ok");

throws_ok( sub { $oWriter->SaveAs("01.html", format => "blsdf MISSING sflk") }, qr/Invalid format/i, "SaveAs failed on invalid format ok");



is($oWriter->SaveAs("01.html", format => "HTML"), 1, "SaveAs HTML ok");
my $text1 = "Perl rocks, neh?";
like(WordTest::readFile("01.html"), qr/$text1/s, " found text in file");


is($oWriter->Open("data/open.doc"), 1, "Open, discarding existing doc ok");
is($oWriter->MoveToEnd(), 1, " MoveToEnd");
my $text2 = "Yep it does!";
is($oWriter->WriteParagraph($text2), 1, " add text");

is($oWriter->SaveAs("02.html", format => "HTML"), 1, "SaveAs HTML file ok");
like(WordTest::readFile("02.html"), qr|>$text1</|s, " found text in file");
like(WordTest::readFile("02.html"), qr|>$text2</|s, " found second text in file");


is($oWriter->Open("data/open.doc"), 1, "Open, discarding existing doc ok");
is($oWriter->MoveToEnd(), 1, " MoveToEnd");
my $text3 = "Holy cow, it does!";
is($oWriter->WriteParagraph($text3, heading => 1), 1, " add text");

is($oWriter->SaveAs("03.rtf", format => "RTF"), 1, "SaveAs RTF file ok");
# Relaxed RTF identification since the format changes
like(WordTest::readFile("03.rtf"), qr|$text1|s, " found text in file");
like(WordTest::readFile("03.rtf"), qr|$text3|s, " found second text in file");



$oWriter->Checkpoint();    #To release lock on file.
ok(WordTest::teardown(), "Tear down test harness");




__END__
