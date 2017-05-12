#!perl -w
use strict;

use Test::More tests => 28;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

my @aText;
my $text;


push(@aText, { pre => ">", text => $text = "Para1 with some text, now some text in ", post => "<"});
is($oWriter->WriteParagraph($text), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "phat teXt", post => "</b"});
is($oWriter->ToggleBold(), 1, "ToggleBold");
is($oWriter->Write($text), 1, "Write");
is($oWriter->ToggleBold(), 0, "ToggleBold back to normal");
is($oWriter->Write(" and then some more text, and then "), 1, "Write");

push(@aText, { pre => ">", text => $text = "largish chars again", post => "</b"});
is($oWriter->SetBold(1), 1, "SetBold on");
is($oWriter->Write($text), 1, "Write");
is($oWriter->SetBold(0), 0, "SetBold back to normal");
is($oWriter->Write(" and yet more ordinary blaha text, and then "), 1, "Write");


push(@aText, { pre => ">", text => $text = "skewed stuff", post => "</i"});
is($oWriter->ToggleItalic(), 1, "ToggleItalic");
is($oWriter->Write($text), 1, "Write");
is($oWriter->ToggleItalic(), 0, "ToggleItalic back to normal");
is($oWriter->Write(" and then some more text, and then "), 1, "Write");

push(@aText, { pre => ">", text => $text = "leaning chars again", post => "</i"});
is($oWriter->SetItalic(1), 1, "SetItalic on");
is($oWriter->Write($text), 1, "Write");
is($oWriter->SetItalic(0), 0, "SetItalic back to normal");
is($oWriter->Write(" and that's all folks..."), 1, "Write");



my $file = "07-italic_bold.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile($file);

for my $rhText (@aText) {
    like($html, qr/$rhText->{pre}$rhText->{text}$rhText->{post}/s, " found text ($rhText->{text}) in file");
}



$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
