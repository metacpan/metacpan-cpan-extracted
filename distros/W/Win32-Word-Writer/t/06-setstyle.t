#!perl -w
use strict;

use Test::More tests => 13;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

my @aText;
my $text;


push(@aText, { pre => ">", text => $text = "Para1 with some text, now some text in a ", post => "<"});
is($oWriter->WriteParagraph($text), 1, "WriteParagraph");

push(@aText, { pre => "MsoHyperlink>", text => $text = "Underlined link", post => "<"});
is($oWriter->SetStyle("Hyperlink"), 1, "SetStyle Hyperlink");
is($oWriter->Write($text), 1, "Write");
is($oWriter->ClearCharacterFormatting(), 1, "ClearCharacterFormatting back to normal");
is($oWriter->Write(" and then some more text"), 1, "Write");





my $file = "06-setstyle.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile($file);

for my $rhText (@aText) {
    like($html, qr/$rhText->{pre}$rhText->{text}$rhText->{post}/s, " found text ($rhText->{text}) in file");
}



$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
