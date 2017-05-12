#!perl -w
use strict;

use Test::More tests => 15;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::chdirT(), "Change to t dir");
ok(WordTest::delDoc(), "Pre-delete doc files");
print "\n";





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

is($oWriter->Open("data/open.doc"), 1, "Open ok");

is($oWriter->SaveAs("01.doc"), 1, "SaveAs ok");
my $text1 = "Perl rocks, neh?";
like(WordTest::readFile("01.doc"), qr/$text1/s, " found text in file");


is($oWriter->Open("data/open.doc"), 1, "Open, discarding existing doc ok");
is($oWriter->MoveToEnd(), 1, " MoveToEnd");
my $text2 = "Yep it does!";
is($oWriter->WriteParagraph($text2), 1, " add text");

is($oWriter->SaveAs("02.doc"), 1, "SaveAs another file ok");
like(WordTest::readFile("02.doc"), qr/$text1/s, " found text in file");
like(WordTest::readFile("02.doc"), qr/$text2/s, " found second text in file");



$oWriter->Checkpoint();    #To release lock on file.
ok(WordTest::delDoc(), "Clean up doc files");




__END__
