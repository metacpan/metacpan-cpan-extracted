=head1 NAME

Win32::Word::Writer - Create Microsoft Word documents


=head1 DESCRIPTION

Easily create MS Word documents, abstracting away the Word.Application
DOM interface and all the required workarounds. The DOM interface is
still exposed for doing more fancy stuff.



=head1 SYNOPSIS

    use strict;
    use Win32::Word::Writer;

    my $oWriter = Win32::Word::Writer->new();

    #Adding text and paragraphs with different styles
    $oWriter->WriteParagraph("Example document", heading => 1);          #Heading  level 1
    $oWriter->WriteParagraph("Usage", style => "Heading 2");             #Style "Heading 2"
    $oWriter->WriteParagraph("Write sentences to the document using a"); #Normal
    $oWriter->WriteParagraph("heading level, or Normal
    if none is specified. ");                            #\n is new paragraph

    $oWriter->Write("Add some more text the current paragraph");

    $oWriter->NewParagraph(style => "Envelope Return");  #The style must exist
    $oWriter->Write("Return to sender. ");

    $oWriter->SetStyle("Envelope Address");              #Change the current style
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



=head1 INSTALLATION

With L<Strawberry Perl|http://strawberryperl.com/>, the regular CPAN
shell should work:

  cpan Win32::Word::Writer

All L<dependencies|Build.pm> except Microsoft Word itself should
sort itself out automatically.

This may work with ActiveState too if you have the MinGW compiler, or
it might be easier to install with C<ppm> (if available, I'm not sure
about the state of the PPM repos at this point).



=head1 CONCEPTS

Win32::Word::Writer uses an OLE instance of Word to create Word
documents.

The documents are constructed in a linear fashion, i.e. you add text
to the document and generally don't move around the document a lot.


=head2 Styles

A "style" in Word is a set of properties that can be assigned to a
piece of text.  There are two types of styles: Paragraph and Character
styles.

"Normal", and "Heading 1" are example of paragraph styles.

When a paragraph gets applied to a piece of text it applies to the
entire paragraph, whereas the character style only affects the actual
chars. You can see the difference if you open a Word document and look
at the available styles.


=cut

package Win32::Word::Writer;

our $VERSION = '0.03';



use warnings;
use strict;

use Carp;

use File::Spec;
use Win32::OLE;
use Win32::OLE::Const;
use File::Temp;
use Data::Dumper;

use Win32::Word::Writer::Table;


my $rhConst = Win32::OLE::Const->Load('Microsoft Word') or Croak("Could not load Word constants. Is Word installed?");





=head1 PROPERTIES

=head2 oWord

A Win32::OLE object with a Word Application instance.


=head2 oDocument

A Win32::OLE object with the Application's Document object. Often used
shorthand.


=head2 oSelection

A Win32::OLE object with the Application's Selection object.


=head2 oTable

The current Win32::Word::Writer::Table object, if a table is
being created, or undef if not.


=cut
use Class::MethodMaker new_with_init => "new", get_set =>
        [ qw(
             oWord
             oDocument
             oSelection
             hasWrittenParagraph
             hasWrittenText
             levelIndent
             hasWrittenInIndent
             oTable
             rhConst
             styleOld
             fileTemp
         )
      ];





=head1 METHODS

Note that all methods return 1 or die on errors, unless otherwise
stated.


=head2 new()

Create new Word Writer object which can be written to.

Return new object, or die on errors.



=head2 init()

Init the object. Called by new.

=cut
sub init {
    my $self = shift;         
    my (%hParam) = @_;

    $self->levelIndent(0);
    $self->hasWrittenInIndent(0);
    $self->hasWrittenParagraph(0);
    $self->hasWrittenText(0);
    $self->rhConst($rhConst);
    $self->oWord( Win32::OLE->new('Word.Application'));
    Win32::OLE->Option(Warn => 3);

    $self->oDocument( $self->oWord->Documents->Add ) or die("Could not add Word document\n");
    $self->oSelection( $self->oWord->Selection ) or die("Could not get Word selection\n");
    $self->oTable(undef);
    $self->styleOld("");
    $self->fileTemp("");

#    $self->oWord->{ScreenUpdating } = 0;        #Makes it faster. Visible = 0 would make it faster, but doesn't work for all operations. See also: http://word.mvps.org/FAQs/InterDev/MakeAppInvisible.htm
    $self->oWord->{DisplayAlerts} = $rhConst->{wdAlertsNone};            #Suppress dialog boxes. Doesn't work that well though...
    return;
}





=head2 Open($file)

Discard the current document and open the Word document in
$file.

Note that you may want to MoveToEnd() after opening an existing
document before adding new text.

Note that this object is in an unusable state if the Open
fails to load a document.

=cut
sub Open {
    my $self = shift;
    my ($file) = @_;

    $file = File::Spec->rel2abs($file);
    -f $file or croak("Could not open file: File ($file) does not exist");
    -r $file or croak("Could not open file: Can't read File ($file)");

    $self->Close();

    my $oDocument = $self->oWord->Documents->Open({
                FileName => $file,
                ConfirmConversions => $self->rhConst->{False},        #Don't show dialog
                Revert => 1,                                        #Discard changes
                Visible => 0,                                        #No window
                });
    $oDocument->Select;                #Otherwise we have no selection
    $self->oSelection( $self->oWord->Selection ) or die("Could not get Word selection\n");

    $self->oDocument($oDocument);

    $self->Checkpoint();            #Release locks on the template file, otherwise other Word instances may not be able to open it

    return(1);
}





=head2 SaveAs($file, %hOpt)

Save the document to $file (may be a relative file name). %hOpt is:

  format => $format -- Save $file as $format (default:
  Document). Valid values are: Document, DOSText, DOSTextLineBreaks,
  EncodedText, HTML, RTF, Template, Text, TextLineBreaks, UnicodeText

(A common mistake is to inspect the document in another Word instance
when re-running a script. The document will be locked by Word and the
script can't re-create the file.)

=cut
sub SaveAs {
    my $self = shift;
    my ($file, %hOpt) = @_;
    my $format = $hOpt{format} || "Document";

    defined(my $formatConst = $self->rhConst->{"wdFormat$format"}) or croak("Invalid format ($format), use Document, DOSText, DOSTextLineBreaks, EncodedText, HTML, RTF, Template, Text, TextLineBreaks, UnicodeText");
       
    $file = File::Spec->rel2abs($file);
    
    eval { $self->oDocument->SaveAs({ FileName => $file, FileFormat => $formatConst }) };
    if($@) {
        my $err = $@;
        if($err =~ /OLE exception from "Microsoft Word":\n\n(.+?)\nWin32::OLE/si) {
            croak("Could not save file ($file): $1");
        }
        croak($err);
    }

    return(1);
}





=head2 Checkpoint()

Checkpoint the document, i.e. save it to a temp file.

This is necessary to do sometimes because Word seems to keep state
until the document is saved, and when using Word automation you tend
to exercise the application in ways they haven't tested properly. And
after a while you get weird errors, just because Word couldn't deal
with all that information.

So you should call this after adding, say, 20K of text to the document
(this is true for Word 2000, it may be better in later versions).

=cut
sub Checkpoint {
    my $self = shift;

    $self->SaveAs( $self->GetFileTemp );

    return(1);
}





=head2 Close()

Discard the current document no-questions-asked (i.e. even if it's not
saved).

Note that this object is in an unusable state until a new document is
created or opened.

=cut
sub Close {
    my $self = shift;

    $self->MarkDocumentAsSaved();

    $self->oSelection(undef);
    $self->oDocument->Close({ SaveChanges => $self->rhConst->{wdDoNotSaveChanges} });
    $self->oDocument(undef);

    return(1);
}




=head1 METHODS - ADDING TEXT

=head2 Write($text)

Append $text to the document (using the current style etc).

=cut
sub Write {
    my $self = shift;
    my ($text) = @_;

    $self->oSelection->TypeText($text);
    $self->hasWrittenText(1);

    return(1);
}





=head2 WriteParagraph($text, [heading => $level], [style => $name])

Append $text as a new paragraph of heading $level or style $name. The
style overrides heading. The style should be a paragraph style.

The default style is "Normal".

=cut
sub WriteParagraph {
    my $self = shift;
    my ($text, %hOpt) = @_;

    if($self->hasWrittenParagraph) {
        $self->NewParagraph(%hOpt);
    } else {
        $self->SetStyle( $self->StyleSpec(%hOpt) );
    }
    
    $self->hasWrittenParagraph(1);
    $self->Write($text);

    return(1);
}





=head2 NewParagraph([heading => $level], [style => $name])

Start a new paragraph of heading $level or with style $name. The style
overrides heading. The style should be a paragraph style.

The default style is "Normal".

=cut
sub NewParagraph {
    my $self = shift;
    my (%hOpt) = @_;

    $self->hasWrittenText and $self->oSelection->TypeParagraph();

    $self->hasWrittenText(1);
    $self->hasWrittenParagraph(1);

    $self->SetStyle( $self->StyleSpec(%hOpt) );

    return(1);
}





=head2 SetStyle([$style = "Normal"])

Set the style to $style.

If $style is a paragraph style, it will change the style of the
current paragraph.

If $style is a character style, it will turn on that style. It will be
in effect until a new style is set somehow, or until it's cleared with
ClearCharacterFormatting().

=cut
sub SetStyle {
    my $self = shift;
    my ($style) = @_;
    $style ||= "Normal";

    return(1) if($style eq $self->styleOld);        #Workaround for bug in Word 2000/2002: http://support.microsoft.com/kb/292174
    $self->styleOld($style);

    local $SIG{__WARN__} = sub { die(@_) };
    eval { $self->oSelection->{Style} = $style; };
    if($@) {
        my $err = $@;
        if($err =~ /OLE exception from "Microsoft Word":\n\n(.+?)\nWin32::OLE/si) {
            die("Could not set style ($style), it may not be defined in the document: $1\n");
        }
        die($err);
    }

    return(1);
}






=head2 ClearCharacterFormatting()

Clear the characther formatting/set it to default.

The paragraph can have a style, and individual characters a separate
formatting style.

=cut
sub ClearCharacterFormatting {
    my $self = shift;

    $self->SetStyle("Default Paragraph Font");        ##Change for Word 2002 to "Clear Formatting", or does it work?

    return(1);
}






=head2 StyleSpec([heading => $level], [style => $name])

Return the final style, given a specification of heading $level or
style $name. The style overrides heading.

The default style is "Normal".

=cut
sub StyleSpec {
    my $self = shift;
    my (%hOpt) = @_;
    my $heading = $hOpt{heading};
    my $style = $hOpt{style};

    $heading && !$style and return( "Heading $heading" );
    return($style || "Normal");
}





=head2 ToggleBold()

Toggle the current Bold charachter setting

=cut
sub ToggleBold {
    my $self = shift;

    $self->oSelection->Font->{Bold} = $rhConst->{wdToggle};

    return($self->oSelection->Font->{Bold} ? 1 : 0);
}





=head2 SetBold($enable)

Set the Bold status to 1 or 0.

Return the new Bold state, or throw OLE exception.

=cut
sub SetBold {
    my $self = shift;
    my ($enable) = @_;
    $enable = $enable ? 1 : 0;

    $self->oSelection->Font->{Bold} = $enable;

    return($self->oSelection->Font->{Bold} ? 1 : 0);
}





=head2 ToggleItalic()

Toggle the current Italic charachter setting

=cut
sub ToggleItalic {
    my $self = shift;

    $self->oSelection->Font->{Italic} = $rhConst->{wdToggle};

    return($self->oSelection->Font->{Italic} ? 1 : 0);
}





=head2 SetItalic($enable)

Set the Italic status to 1 or 0.

Return the new Italic state, or throw OLE exception.

=cut
sub SetItalic {
    my $self = shift;
    my ($enable) = @_;
    $enable = $enable ? 1 : 0;

    $self->oSelection->Font->{Italic} = $enable;

    return($self->oSelection->Font->{Italic} ? 1 : 0);
}





=head1 METHODS - BULLET POINT LISTS

=head2 ListBegin()

Begin a new bullet point list.

Can be nested to create sub-lists.

Use ListItem() to create new bullet points before adding text to the
list.

=cut
sub ListBegin {
    my $self = shift;

    $self->oSelection->TypeParagraph();
    if( ! $self->levelIndent) {        #Not yet started a list at all
        $self->oSelection->Range->ListFormat->ApplyBulletDefault();
    } else {
        $self->oSelection->Range->ListFormat->ListIndent();
    }

    $self->levelIndent( $self->levelIndent + 1);
    $self->hasWrittenInIndent(0);

    return(1);
}





=head2 ListItem()

Start a new bullet point in the list.

The first text you Write() after this becomes the new bullet text.

You should not WriteParagraph() within a list item. New paragraphs are
signals to Word to advance to the next list item, so that will confuse
Win32::Word::Writer and/or Word.

=cut
sub ListItem {
    my $self = shift;

    if($self->hasWrittenInIndent) {
        $self->oSelection->TypeParagraph();
    }

    $self->hasWrittenInIndent(1);

    return(1);
}






=head2 ListEnd()

End an existing bullet point list.

If it's the outermost list, go back to normal text.

=cut
sub ListEnd {
    my $self = shift;

    $self->oSelection->TypeParagraph();

    if($self->levelIndent <= 1) {    #Is the first level
        $self->oSelection->Range->ListFormat->RemoveNumbers();
    } elsif($self->levelIndent <= 2) {    #Is the second level. This is just weird and I don't like to not understand why it works, but it does...
        $self->oSelection->Range->ListFormat->RemoveNumbers();
        $self->oSelection->Range->ListFormat->ApplyBulletDefault();
    } else {
        $self->oSelection->Range->ListFormat->ListOutdent();
    }

    $self->levelIndent( $self->levelIndent - 1);
    $self->hasWrittenInIndent(0);

    return(1);
}





=head1 METHODS - TABLES

=head2 TableBegin()

Begin a new table.

The table model resembles a HTML table with rows and columns, but you don't
have to close columns or rows. Simply start a new one.

A row and col must be created with TableRowBegin() and
TableColumnBegin() before any text is added.

Tables can not be nested.

Note that tables are rather fragile so don't expect them to work with
very complex layouts, or very wide columns. Prepare for exceptions to
be thrown.

=cut
sub TableBegin {
    my $self = shift;

    $self->oTable and return(0);

    my $oTable = Win32::Word::Writer::Table->new(oWriter => $self) or die("Could not create Table object\n");
    $self->oTable($oTable);
    $self->oTable->TableBegin();
#    $self->oTable(undef);

    return(1);
}





=head2 TableRowBegin()

Begin a new row in the current table.

Add a column also before adding text to the table.

=cut
sub TableRowBegin {
    my $self = shift;

    $self->oTable or return(0);
    $self->oTable->RowBegin();

    return(1);
}





=head2 TableColumnBegin()

Begin a column in the current table in the current row.

Any new text/paragraph added to the document will end up in this table
cell until a new row or column is created, or the table is ended.

=cut
sub TableColumnBegin {
    my $self = shift;

    $self->oTable or return(0);
    $self->oTable->ColumnBegin();

    return(1);
}





=head2 TableEnd()

Begin a column in the current table in the current row.

Any new text/paragraph added to the document will end up in this table
cell until a new row or column is created, or the table is ended.

=cut
sub TableEnd {
    my $self = shift;

    $self->oTable or return(0);

    $self->oTable->TableEnd();
    $self->oTable(undef);

    $self->styleOld("Normal");  #We jump to the end of the document, so the style is currently Normal

    return(1);
}





=head1 METHODS - MOVEMENT AND SELECTION

=head2 MoveToEnd()

Set the insertion point at the end of the document.

=cut
sub MoveToEnd {
    my $self = shift;

    $self->oSelection->EndKey({ Unit => $self->rhConst->{wdStory}});

    return(1);
}





=head2 SelectAll()

Make the selection the entire document.

Return 1 on success, else die.

=cut
sub SelectAll {
    my $self = shift;

    $self->oSelection->WholeStory();

    return(1);
}





=head1 METHODS - FIELDS AND TABLES

=head2 FieldsUpdate()

Update the fields in the entire document. Retain the current
cursor location.

But note this doesn't always work with Table of Contents
tables.

Return 1 on success, else die.

=cut
sub FieldsUpdate {
    my $self = shift;

    $self->oDocument->Fields->Update() and croak("Could not update all fields");

#    my $nameBookmark = "wordwriter" . int(rand(10000));
#    $self->BookmarkAdd($nameBookmark);
#    $self->SelectAll();

#    $self->oSelection->Fields->Update();

#    $self->BookmarkGoto($nameBookmark);
#    $self->BookmarkDelete($nameBookmark);

    return(1);
}





=head2 ToCUpdate()

Update both entries and page numebers of all the Tables of 
Contents in the entire document. Retain the current cursor 
location.

Return 1 on success, else die.

=cut
sub ToCUpdate {
    my $self = shift;

    my $count = 0;
    for my $oToC ($self->oDocument->TablesOfContents->in()) {
        $count++;
        $oToC->Update() and croak("Could not update entries of Table of Contents number ($count)");
        $oToC->UpdatePageNumbers() and croak("Could not update page numbers of Table of Contents number ($count)");
    }

    return(1);
}





=head1 METHODS - IMAGES

=head2 InsertPicture($file, $embed = 0)

Insert the picture $file at the current cursor location. $file must be
one Word supports.

If $embed is 1, the picture $file itself will be embedded inside the
Word document. If $embed is 0, the picture is isn't embedded in the
document, but linked to it.

Return 1 on success, else die.

=cut
sub InsertPicture {
    my $self = shift;
    my ($file, $embed) = @_;
    $embed ||= 0;

    $file = File::Spec->rel2abs($file);
    -f $file or croak("Could not open file: File ($file) does not exist");
    -r $file or croak("Could not open file: Can't read File ($file)");

    # LinkToFile, SaveWithDocument
    my @aLinkSave = qw/ True False /;
    $embed and @aLinkSave = qw/ False True /;
    $self->oSelection->InlineShapes->AddPicture($file, @aLinkSave) or croak("Could not insert image object");
    
    return(1);
}





=head1 METHODS - BOOKMARKS

=head2 BookmarkAdd($name)

Add a new bookmark called $name at the current cursor
location.

Return 1 on success, else die.

=cut
sub BookmarkAdd {
    my $self = shift;
    my ($name) = @_;

    $self->oDocument->Bookmarks->Add( { Name => $name } );

    return(1);
}





=head2 BookmarkGoto($name)

Go to bookmark called $name. The bookmark should exist.

Return 1 on success, else die.

=cut
sub BookmarkGoto {
    my $self = shift;
    my ($name) = @_;

    $self->oSelection->GoTo( { What => $self->rhConst->{wdGoToBookmark}, Name => $name } );

    return(1);
}





=head2 BookmarkDelete($name)

Delete bookmark called $name. The bookmark should exist.

Return 1 on success, else die.

=cut
sub BookmarkDelete {
    my $self = shift;
    my ($name) = @_;

    $self->oDocument->Bookmarks($name)->Delete();

    return(1);
}





=head1 METHODS - UTILITY

=head2 MarkDocumentAsSaved()

Mark the Word document as "saved". This is in effect until
the document is changed again.

Being saved e.g. means it can be abandoned without
questions.

Return 1 on success, else die.

=cut
sub MarkDocumentAsSaved {
    my $self = shift;

    $self->oDocument->{Saved} = 1;

    return(1);
}





=head2 GetFileTemp()

Return a temporary file name in fileTemp().

=cut
sub GetFileTemp {
    my $self = shift;

    $self->fileTemp or $self->fileTemp( File::Temp::tmpnam() . "-wordwriter.doc" );        #Can't use the proper auto-unlink because that only works with the file handles

    return($self->fileTemp);
}





=head2 DESTROY

Release objects including the OLE Word object.

=cut
sub DESTROY {
    my $self = shift;
    $self->oTable(undef);

    $self->oWord->{DisplayAlerts} = $rhConst->{wdAlertsNone};
    $self->MarkDocumentAsSaved();        ##workaround: wdAlertsNone doesn't work in Word2000 so we insist that the document is already saved to avoid the dialog box

    $self->oWord->Quit();
    $self->oWord(undef);        #This destroys the OLE object

    #Save after quitting to keep Word from locking the file
    if($self->fileTemp and -e $self->fileTemp) {
        unlink($self->fileTemp) or ($^W and warn("Could not delete temp file (" . $self->fileTemp . "): $!\n"));
    }
}





1;





__END__

=head1 KNOWN BUGS

=head2 Supressing dialog boxes

The most serious problem I have with Word is that the
documented way of supressing interactive dialog boxes...
doesn't work! This is worked around in a few cases (see
below), but mostly it's broken.

I don't know if this only goes for my Office 2000 Word, but
it may affect you too.

It's a very bad thing anyhow, since it can cause your
program to just freeze, waiting for user interaction. To
boot, the dialog boxes are usually displayed below other
applications.

I blame Bill's minions.


=head2 Only four columns in tables

It might be that your version of Word only supports four
columns. Using Word 2003, adding a fifth column results in:

  This exceeds the maximum width.

This is described in
L<http://support.microsoft.com/kb/253600/>. Unfortunately(?), this
doesn't happen when I use Word interactively, only under OLE
Automation. The suggestions in the KB article won't solve the problem.

In Word 2000 this wasn't a problem. It may be fixed in later
versions. Who knows?


=head2 OLE errors during global destruction

If you are in the middle of a table and something goes
wrong, there will be strange OLE warnings during global
destruction. I haven't found out why this happens.


=head2 Layout too complex

I have run into this problem where, despite the no-don't-
show-dialogs, Word pops up an error dialog below all other
windows (so you can't see it, great!).

After clicking Ok in this dialog a number of times, the OLE
call finally fails properly and dies in the Perl
application layer.

http://support.microsoft.com/kb/292174

The only way to not run into this problem seems to be to
save the document to disk after adding some text. The
Checkpoint() method does this for you.


=head2 Rouge WINWORD.EXE processes

Sometimes it seems like Win32::OLE has some problems with
closing the Word instance during global destruction. This
happens mostly when things die().



=head1 TODO

Tests for Tables of Contents etc

Tests for Bookmarks



=head1 APPLICATION DOM INFORMATION

So what does the Word DOM look like? Actually, the documentation is
available when installing Office.

Start Word and press Alt-F11 to bring up the VBA window. There is an
Object Browser in the toolbar. Select an object, method or property
and press F1 to bring up the help.

A good way to figure out how to do something is to record a Macro and
then bring up the VBA window and inspect the code written by the Macro
Recorder.



=head1 DESIGN ISSUES

=head2 Software versions

This is tested and developed using w2k and Office 2000.
Things may be different with other versions. Please let me know.


=head2 Supressing the "Save as..." dialog box

The problem with this is that it doesn't work to follow the
manual and advice found on the Net.

The usual answer is to set DisplayAlerts to False, or
wdAlertsNone. That doesn't work for me.

What works is to set the Document.Saved property to False
before quitting (the MarkDocumentAsSaved() method).

That's why the ActiveX object is Quit from the DESTROY
method, and not using the exit handler in CreateObject which
is the normal course of action.



=head1 GOOD IDEAS

=head2 Keep an eye on the Task Manager

When you fiddle around with this program, it's useful to
keep the Task Manager window open to keep track of any
WINWORD.EXE processes that may be stuck in memory if you
e.g. C-Break out of the script (don't do that, Win32::OLE
won't have a chance of cleaning up the Word instance it
created).

Kill abandoned Word processes (but make sure you don't kill
any documents you may be editing :)



=head1 EXTENDING THE MODULE

The interface of this module is spotty in an opportunistic
way; I have added utility methods as I needed them.

If you need to add your own methods, I suggest you simply
inject them in this namespace to get your application
working and send me a patch.

If you don't know how to create a patch file, just send me the code in
an email, or the changed source file as an attachment.

If you write something non-trivial, I'd like some tests to go with it
too, thanks!


=head1 FAQ

Actual questions. Some of them even frequent.


=head2 Do I need Windows to run Win32::Word::Writer or does it work on Linux?

Yes, you do need Windows. Win32::Word::Writer is using the actual
Microsoft Word program installed on your computer.


=head2 Can Win32::Word::Writer do X?

If you can't find it described in the docs, probaby not. But if you've
seen it done in Word, it's clearly doable somehow (modulo Word bugs
courtesy of MS).

You can probably implement it yourself if you give it a try. Read the
Win32::Word::Writer source for hints on how to accomplish things.


=head2 Can you implement X for me?

No, not really.

I rarely touch this project nowadays, and I don't think I've actually
used it after the initial thing I needed to write it for years ago.

I'm happy that others find it useful though.

If you find it so useful that you need it to do more things, I urge
you to give it a shot at adding the functionality yourself.


=head2 If so many people e-mail you to say they like Win32::Word::Writer, why are there no reviews?

(okay, so this is my question)

Maybe they don't know the link to the L<CPAN Reviews
site|http://cpanratings.perl.org/rate/?distribution=Win32-Word-Writer>.


=head1 AUTHOR

Johan Lindström, C<< <johanl[ÄT]DarSerMan.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-word-writer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Word-Writer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Johan Lindström, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



=head1 PRIVATE PROPERTIES

These are considered implementation details, but you may need to
fiddle with them if you extend the module.


=head2 hasWrittenParagraph

Whether the writer has written a paragraph yet.


=head2 hasWrittenText

Whether the writer has written any text or paragraph yet.


=head2 levelIndent

The indentation level for bullet point lists.

Default: 0


=head2 hasWrittenInIndent

Whether the writer has written anything after changing indentation
level.


=head2 rhConst

Ref to hash with imported Word constant symbold.


=head2 styleOld

The previous style.


=head2 fileTemp

The name of a temporary file.


=cut
