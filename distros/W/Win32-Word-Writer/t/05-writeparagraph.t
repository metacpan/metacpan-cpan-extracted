#!perl -w
use strict;

use Test::More tests => 21;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

my @aText;
my $text;


push(@aText, { pre => ">", text => $text = "Para1 with some text", post => "</p"});
is($oWriter->WriteParagraph($text), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "Para2 with heading 1 text", post => "</h1>"});
is($oWriter->WriteParagraph($text, heading => 1), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "Para3 with heading 2 text", post => "</h2>"});
is($oWriter->WriteParagraph($text, heading => 2), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "Para4 with heading 5 text", post => "</h5>"});
is($oWriter->WriteParagraph($text, heading => 5), 1, "WriteParagraph");

push(@aText, { pre => ">", text => $text = "Para5 with heading 6 text", post => "</h6>"});
is($oWriter->WriteParagraph($text, heading => 6), 1, "WriteParagraph");

$text = "Para6 with heading 251 text";
throws_ok(sub { $oWriter->WriteParagraph($text, heading => 251) }, qr/Could not set style/s, "WriteParagraph failed with missing heading level");


push(@aText, { pre => ">", text => $text = "Para6 with style 'Heading 1'", post => "</h1>"});
is($oWriter->WriteParagraph($text, style => "Heading 1"), 1, "WriteParagraph");


push(@aText, { pre => "MsoMacroText>", text => $text = "Para7 with style 'Macro Text'", post => "</p"});
is($oWriter->WriteParagraph($text, style => "Macro Text"), 1, "WriteParagraph");





is($oWriter->SaveAs("05-writeparagraph.html", format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile("05-writeparagraph.html");

for my $rhText (@aText) {
    like($html, qr/$rhText->{pre}$rhText->{text}$rhText->{post}/s, " found text ($rhText->{text}) in file");
}




$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
