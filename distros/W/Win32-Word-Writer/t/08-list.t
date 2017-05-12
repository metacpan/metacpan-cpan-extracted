#!perl -w
use strict;

use Test::More tests => 38;
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



$oWriter->WriteParagraph("One item list", heading => 2);

push(@aText, { pre => ">", text => $text = "The first item in the first list", post => "</li"});
is($oWriter->ListBegin(), 1, "ListBegin");
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");
is($oWriter->ListEnd(), 1, "ListEnd");


$oWriter->WriteParagraph("More items", heading => 2);

is($oWriter->ListBegin(), 1, "ListBegin");

push(@aText, { pre => ">", text => $text = "The first item in the second list", post => "</li"});
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");

push(@aText, { pre => ">", text => $text = "The second item in the second list", post => "</li"});
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");

is($oWriter->ListEnd(), 1, "ListEnd");




$oWriter->WriteParagraph("Nested lists", heading => 2);

is($oWriter->ListBegin(), 1, "ListBegin");

push(@aText, { pre => ">", text => $text = "Outer list 1", post => "</li"});
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");

push(@aText, { pre => ">", text => $text = "Outer list 2", post => "</li"});
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");


is($oWriter->ListBegin(), 1, "ListBegin");

push(@aText, { pre => "", text => $text = "Inner list 1", post => ""});  #No <ul> for nested lists
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");

is($oWriter->ListEnd(), 1, "ListEnd");


push(@aText, { pre => ">", text => $text = "Outer list 3", post => "</li"});
is($oWriter->ListItem(), 1, "ListItem");
is($oWriter->Write($text), 1, "Write");


is($oWriter->ListEnd(), 1, "ListEnd");




is($oWriter->SaveAs("08-list.doc"), 1, "SaveAs HTML ok");
my $file = "08-list.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile($file);

for my $rhText (@aText) {
    my $cleanHtml = $html; $cleanHtml =~ s/\s//gs;
    my $cleanRex = "$rhText->{pre}$rhText->{text}$rhText->{post}"; $cleanRex =~ s/\s//gs;
    like($cleanHtml, qr/$cleanRex/s, " found text ($rhText->{text}) in file");
}




$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");




__END__
