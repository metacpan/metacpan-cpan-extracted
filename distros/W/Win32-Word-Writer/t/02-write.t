#!perl -w
use strict;

use Test::More tests => 15;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::chdirT(), "Change to t dir");
ok(WordTest::delDoc(), "Pre-delete doc files");
print "\n";





use_ok( 'Win32::Word::Writer' );


{
    ok(my $oWriter = Win32::Word::Writer->new(), "new ok");
    
    my $text = "Some unique text";
    ok($oWriter->Write($text), "Write ok");
    is($oWriter->SaveAs("01.doc"), 1, "SaveAs ok");
    like(WordTest::readFile("01.doc"), qr/$text/s, " Contains text");
}


{
    ok(my $oWriter = Win32::Word::Writer->new(), "new ok");
    
    my $text = "Some unique text";
    ok($oWriter->WriteParagraph($text), "Write ok");

    my $text2 = "Helt annan unik text";
    ok($oWriter->WriteParagraph($text2), "Write ok");
    is($oWriter->SaveAs("02.doc"), 1, "SaveAs ok");
    like(WordTest::readFile("02.doc"), qr/$text/s, " Contains text");
    like(WordTest::readFile("02.doc"), qr/$text2/s, " Contains second text");
}



ok(WordTest::delDoc(), "Clean up doc files");



__END__
