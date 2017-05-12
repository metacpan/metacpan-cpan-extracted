#!perl.exe -w
use strict;

use lib "../lib";

use Win32::Word::Writer;
my $oWriter = Win32::Word::Writer->new();

#Adding text and paragraphs with different styles
$oWriter->WriteParagraph("Example document", heading => 1);          #Heading  level 1
$oWriter->WriteParagraph("Usage", style => "Heading 2");             #Style "Heading 2"
$oWriter->WriteParagraph("Write sentences to the document using a"); #Normal
$oWriter->WriteParagraph("heading level, or Normal
if none is specified. ");                            #\n: new paragraph

$oWriter->Write("Add some more text the current paragraph");

$oWriter->NewParagraph(style => "Envelope Return");  #The style must exist
$oWriter->Write("Return to sender. ");

$oWriter->SetStyle("Envelope Address");          #Change the current style
$oWriter->Write("Nope, we changed the style of the entire paragraph");
$oWriter->Write("to a footer style");

#Setting character styles
$oWriter->WriteParagraph("Some more normal text. ");
$oWriter->SetStyle("Hyperlink");                 #A charachter style
$oWriter->Write("http://www.DarSerMan.com/Perl/");
$oWriter->ClearCharacterFormatting();            #Clear character style
$oWriter->Write("  <-- my ");

#Bold/Italics
$oWriter->ToggleBold();         #Toggle bold
$oWriter->Write("Perl ");
$oWriter->SetItalic(1);         #Turn on Italic
$oWriter->Write("stuff.");
$oWriter->ToggleItalic();       #Toggle Italic
$oWriter->SetBold(0);           #Turn off bold

#Bullet point lists
$oWriter->ListBegin();
$oWriter->ListItem();
$oWriter->Write("The first bullet item");
$oWriter->ListItem();
$oWriter->Write("The second bullet item");

$oWriter->ListBegin();   #Nested bullet point list
$oWriter->ListItem();
$oWriter->Write("The first inner bullet item");
$oWriter->ListItem();
$oWriter->Write("The second inner bullet item");

$oWriter->ListEnd();
$oWriter->ListEnd();


#Do this at regular intervals (say, every couple of 10K of text you add)
$oWriter->Checkpoint();


#Tables
$oWriter->WriteParagraph("Table example", heading => 1);
$oWriter->NewParagraph();

$oWriter->TableBegin();
$oWriter->TableRowBegin();
$oWriter->TableColumnBegin();
$oWriter->SetBold(1);
$oWriter->Write("HTML table");
$oWriter->TableColumnBegin();
$oWriter->Write("Win32::Word::Writer");

$oWriter->TableRowBegin();
$oWriter->TableColumnBegin();
$oWriter->SetBold(0);
$oWriter->Write("<table>");
$oWriter->TableColumnBegin();
$oWriter->Write("TableBegin()");

$oWriter->TableRowBegin();
$oWriter->TableColumnBegin();
$oWriter->Write("<tr>");
$oWriter->TableColumnBegin();
$oWriter->Write("TableRowBegin()");

$oWriter->TableEnd();


#Save the document
$oWriter->SaveAs("01example.doc");


__END__
