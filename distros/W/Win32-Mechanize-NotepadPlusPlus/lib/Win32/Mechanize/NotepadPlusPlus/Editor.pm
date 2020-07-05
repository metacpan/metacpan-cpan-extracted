package Win32::Mechanize::NotepadPlusPlus::Editor;
use 5.010;
use warnings;
use warnings::register;
use strict;
use Exporter 'import';
use Carp;
use Win32::Mechanize::NotepadPlusPlus::__hwnd;
use Win32::Mechanize::NotepadPlusPlus::Editor::Messages;  # exports %SCIMSG, which contains the messages used by the Scintilla editor
use utf8;   # there are UTF8 arrows throughout the source code (in POD and strings)
use Config;

our $VERSION = '0.004001'; # auto-populated from W::M::NPP

our @EXPORT_VARS = (@Win32::Mechanize::NotepadPlusPlus::Editor::Messages::EXPORT);
our @EXPORT_OK = (@EXPORT_VARS);
our %EXPORT_TAGS = (
    vars            => [@EXPORT_VARS],
    all             => [@EXPORT_OK],
);

my %autogen;    # used during AUTOLOAD to automatically generate the source code


=pod

=encoding utf8

=head1 NAME

Win32::Mechanize::NotepadPlusPlus::Editor - The editor object for Notepad++ automation

=head1 SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus qw/:main/;
    my $editor = editor();

=head1 DESCRIPTION

The editor object for Notepad++ automation using L<Win32::Mechanize::NotepadPlusPlus>:
this object will interface with Notepad++'s Scintilla component instances.

Please note that because this module is driving Notepad++'s Scintilla components
externally, rather than internally through a plugin or inside the actual Notepad++
source code, some messages will take longer than you might expect before they are
fully complete; you may find that a L</setText> requires 10ms or more to complete,
depending on how long the text is, so don't be surprised if you have to add in
delays to get your script to reliably execute.

Also note that Notepad++ itself is sending messages to the Scintilla components,
so there may be changes in state that are not related to the running Perl code;
there may be times when Notepad++ changes things unexpectedly in the middle of
the Perl execution (especially for things like the Target-oriented methods
like L</getTargetText>).

=head2 Version Requirements

The module was developed with Notepad++ v7.7 or newer in mind, though some features should still
work on older versions of Notepad++.  As Notepad++ adds new features, the minimum version for
that method will be indicated in the help.

=cut

=head1 OBJECT CREATION

The Editor objects are created as appropriate, both with the original

    use Win32::Mechanize::NotepadPlusPlus;

or, as needed when the Notepad object creates a hidden Scintilla using

    my $hidden = notepad()->createScintilla;

Warning: some users of Notepad++'s C<createScintilla> interface in scripting plugins
using the same message-based interface as B<Win32::Mechanize::NotepadPlusPlus> have
found that they cannot create more than one extra Scintilla instance from inside
their scripts without causing instability in Notepad++.  The same might
be true using this Perl interface as well, so it is recommended that you reuse the
same hidden instance throughout your script, rather than trying to create multiple
hidden instances, if at all possible.

=cut

#=over
#
#=item Win32::Mechanize::NotepadPlusPlus::Editor->_new
#
#There is a C<_new> object-creation method, but it's really only needed
#behind the scenes.  If you want a spare scintilla editor, use
#
#    notepad()->createScintilla;
#
#=back
#
#=cut


# Win32::Mechanize::NotepadPlusPlus::Editor->new(hwnd)
#   Normally, the user won't call this; it will be instantiated for the two main view-scintillas by the Notepad.pm object;
#   If the user wants to create a new (behind the scenes) Scintilla, use the ->create method, instead
sub _new
{
    my ($class, $hwnd, $parent) = @_;
    my $self = bless {}, $class;
    $self->{_hwnd} = $hwnd;
    $self->{_hwobj} = Win32::Mechanize::NotepadPlusPlus::__hwnd->new( $hwnd ); # create an object
    if( defined $parent ) {
        # set the Editor's parent, if it's been passed
        if( ref($parent) ) {
            # if it's an object, error out on unknown, else set the parent
            croak "unknown object $parent" unless $parent->isa('Win32::Mechanize::NotepadPlusPlus::__hwnd');
            $self->{_parent_hwobj} = $parent;
        } else {
            # when non-reference, assume it's the parent window's HWND
            $self->{_parent_hwobj} = Win32::Mechanize::NotepadPlusPlus::__hwnd->new( $parent );
        }
    }
    return $self;
}

# __ptrBytes and __ptrPack: use for setting number of bytes or the pack/unpack character for a perl-compatible pointer
sub __ptrBytes64 () { 8 }
sub __ptrPack64  () { 'Q' }
sub __ptrBytes32 () { 4 }
sub __ptrPack32  () { 'L' }

if( $Config{ptrsize}==8 ) {
    *__ptrBytes = \&__ptrBytes64;
    *__ptrPack  = \&__ptrPack64;
} elsif ( $Config{ptrsize}==4) {
    *__ptrBytes = \&__ptrBytes32;
    *__ptrPack  = \&__ptrPack32;
} else {
    die "unknown pointer size: $Config{ptrsize}bytes";
}

# __test_autogen is used in the test suite to expose the contents of %autogen
#   for verification purposes.  There is no reason for the end-user to ever use
#   __test_autogen()
sub __test_autogen { return %autogen; }

=head2 Window Handle

=over

=item hwnd

    editor->hwnd();

    my $sci_hWnd = editor1->hwnd();

Grabs the window handle of the Scintilla editor.

This is used for sending Windows messages; if you are enhancing the Editor object's functionality (implementing some new Scintilla
message that hasn't made its way into this module, for example), you will likely need access to this handle.

=back

=cut

sub hwnd {
    $_[0]->{_hwnd};
}

# doc to pod+code:
# tested at regexr.com/4n9gb
#   ^(?s)\h*(Editor\.)(.*?)(\R)\h*(.*?)\h*(See Scintilla documentation for)\h*(\w+)
#   =item editor\(\)->$2$3$3$4$5 L<$6|https://www.scintilla.org/ScintillaDoc.html/#$6>$3$3=cut$3$3sub $2 { ... $6 ... }
#
# tested at regexr.com/4nhob for similar...
#   (?s)^    Editor\.(.*?)(\R)(.*?)\2    (See Scintilla documentation for )(\w+)\2+
#   =item editor\(\)->$1$2$2$3$2$4 L<$5|https://www.scintilla.org/ScintillaDoc.html#$5>$2$2=cut$2$2\$autogen{$5} = {$2    subProto => '$1',$2    sciProto => '$5',$2};$2$2
#
#   I can use that for auto-generating a sub framework, or if I use hash notation instead,
#   starting to populate the autoload map

=head1 SCINTILLA EDITOR API

These are the object-oriented methods for manipulating the Scintilla editor objects inside the Notepad++ application,
usually using the C<editor()> instance for the active editor or C<editor1()> and C<editor2()> for direct control of
the two default editors available to Notepad++, and also any L<$hidden|/OBJECT CREATION> Scintilla instances.

=head2 Text retrieval and modification



=over

=item setText

    editor->setText($text);

Replace the contents of the document with the argument text.

See Scintilla documentation for  L<SCI_SETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTEXT>

=cut

$autogen{SCI_SETTEXT} = {
    subProto => 'setText(text)',
    sciProto => 'SCI_SETTEXT(<unused>, const char *text)',
};

=item getText

    editor->getText();

Retrieve all the text in the document.

See Scintilla documentation for  L<SCI_GETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTEXT>

=cut

$autogen{SCI_GETTEXT} = {
    subProto => 'getText() => str',
    sciProto => 'SCI_GETTEXT(position length, char *text) => position',
};

=item setSavePoint

    editor->setSavePoint();

Remember the current position in the undo history as the position at which the document was saved.

See Scintilla documentation for  L<SCI_SETSAVEPOINT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSAVEPOINT>

=cut

$autogen{SCI_SETSAVEPOINT} = {
    subProto => 'setSavePoint()',
    sciProto => 'SCI_SETSAVEPOINT',
};

=item getLine

    editor->getLine($line);

Retrieve the contents of a line.

See Scintilla documentation for  L<SCI_GETLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINE>

=cut

$autogen{SCI_GETLINE} = {
    subProto => 'getLine(line) => str',
    sciProto => 'SCI_GETLINE(line line, char *text) => position',
};

=item replaceSel

    editor->replaceSel($text);

Replace the selected text with the argument text.

See Scintilla documentation for  L<SCI_REPLACESEL|https://www.scintilla.org/ScintillaDoc.html#SCI_REPLACESEL>

=cut

$autogen{SCI_REPLACESEL} = {
    subProto => 'replaceSel(text)',
    sciProto => 'SCI_REPLACESEL(<unused>, const char *text)',
};

=item setReadOnly

=item getReadOnly

    editor->setReadOnly($readOnly);
    editor->getReadOnly();

Set read only or read/write mode.

See Scintilla documentation for  L<SCI_SETREADONLY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETREADONLY>

See Scintilla documentation for  L<SCI_GETREADONLY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETREADONLY>

=cut

$autogen{SCI_SETREADONLY} = {
    subProto => 'setReadOnly(readOnly)',
    sciProto => 'SCI_SETREADONLY(bool readOnly)',
};

$autogen{SCI_GETREADONLY} = {
    subProto => 'getReadOnly() => bool',
    sciProto => 'SCI_GETREADONLY => bool',
};

=item getTextRange

    editor->getTextRange($start, $end);

Retrieve a range of text.

See Scintilla documentation for  L<SCI_GETTEXTRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTEXTRANGE>

=cut

# basically the same as getStyledText() below, but without the style values interleaved

#$autogen{SCI_GETTEXTRANGE} = {
#    subProto => 'getTextRange(start, end) => str',
#    sciProto => 'SCI_GETTEXTRANGE(<unused>, Sci_TextRange *tr) => position',
#};

sub getTextRange {
    my ($self, $start, $end) = @_;
    croak sprintf qq|%s->getTextRange(%s,%s): end must be greater than or equal to start|, ref($self), $start//'<undef>', $end//'<undef>'
        unless 0+$end >= 0+$start;

    # the wparam is 0.  the lparam is a struct { cpMin, cpMax, char* },
    #   where cpMin and cpMax are set before calling, and char* must be an allocated virtual-buffer

    # prepare the text buffer
    my $buflen = 1 + $end-$start;
    my $text_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), $buflen );
    if(0) { # DEBUG
        my $readback = Win32::GuiTest::ReadFromVirtualBuffer( $text_buf , $buflen );
        printf STDERR "text buf virtual string = '%s'\n", $readback;
    }

    # create the packed string for the structure
    my $pk = __ptrPack();     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize
    my $packed_struct = pack "ll $pk", $start, $end, $text_buf->{ptr};
    if(0) { # DEBUG
        print STDERR "packed_struct = 0x"; printf STDERR "%02x ", ord($_) for split //, $packed_struct; print STDERR "\n";
        my ($smin,$smax,$ptr) = unpack "ll $pk", $packed_struct;
        printf STDERR "\t(%s,%s) 0x%08x\n", $smin,$smax,$ptr;
    }

    # allocate memory and populate the virtual-buffer structure
    my $struct_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), length($packed_struct) );
    Win32::GuiTest::WriteToVirtualBuffer( $struct_buf, $packed_struct );

    # send the GETSTYLEDTEXT message
    my $ret = $self->SendMessage( $SCIMSG{SCI_GETTEXTRANGE} , 0 , $struct_buf->{ptr} );

    # read back from the string
    my $readback = Win32::GuiTest::ReadFromVirtualBuffer( $text_buf , $buflen-1 );  # don't grab the end null
    if(0) { printf STDERR "text buf virtual string = '%s'\n", $readback; }

    # cleanup
    Win32::GuiTest::FreeVirtualBuffer( $_ ) for $struct_buf, $text_buf;

    return $readback;
}


=item allocate

    editor->allocate($bytes);

Enlarge the document to a particular size of text bytes.

See Scintilla documentation for  L<SCI_ALLOCATE|https://www.scintilla.org/ScintillaDoc.html#SCI_ALLOCATE>

=cut

$autogen{SCI_ALLOCATE} = {
    subProto => 'allocate(bytes)',
    sciProto => 'SCI_ALLOCATE(position bytes)',
};

=item addText

    editor->addText($text);

Add text to the document at current position.

See Scintilla documentation for  L<SCI_ADDTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDTEXT>

=cut

$autogen{SCI_ADDTEXT} = {
    subProto => 'addText(text) => int',
    sciProto => 'SCI_ADDTEXT(position length, const char *text)',
};

=item addStyledText

    editor->addStyledText($text, $style);
    editor->addStyledText($text, \@style_array);

Add text with associated style indices.

The first form applies one style index C<$style> to all the characters in C<$text>:

    editor->addStyledText("Hello World", 3); # applies style-number-3 to all the characters in the string

The second form requires an array-reference C<\@style_array> (or C<[list of styles]>), with one style index per character in C<$text>:

    @style_array = (1,2,3)
    editor->addStyledText("One", \@style_array ); # applies style 1 to "O", 2 to "n", and 3 to "e"
    editor->addStyledText("Two", [9,8,7] );       # applies style 9 to "T", 8 to "w", and 7 to "o"

If there is a size mismatch, it will die:

    editor->addStyledText("LongWord", [1,2]);     # will die, because there are not enough elements in the anonymous array

See Scintilla documentation for  L<SCI_ADDSTYLEDTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDSTYLEDTEXT>

=cut

#$autogen{SCI_ADDSTYLEDTEXT} = {
#    subProto => 'addStyledText(c) => int',
#    sciProto => 'SCI_ADDSTYLEDTEXT(position length, cell *c)',
#};

# per https://github.com/bruderstein/PythonScript/blob/1402c12944cdad041595043812f324b0e3131dcc/PythonScript/src/ScintillaCells.cpp,
#   it appears that the `cell *c` is an array of alternating character/style-index pairs (each one byte long)...

sub addStyledText {
    my ($self, $text, $styles) = @_;
    my $tlen = length($text);
    my @s = ref($styles) ? @$styles : (($styles) x $tlen);
    croak sprintf "%s::addStyledText(%s, [%s]): need 1:1 ratio between text and number of styles", ref($self), $text, join(',',@s) unless $tlen == scalar @s;
    my $cell = '';
    for my $p ( 0 .. $tlen-1 ) {
        $cell .= substr($text, $p, 1);
        $cell .= pack "C", $s[$p];
    }

    return my $ret = $self->{_hwobj}->SendMessage_sendRawString( $SCIMSG{SCI_ADDSTYLEDTEXT}, length($cell), $cell );
}


=item appendText

    editor->appendText($text);

Append a string to the end of the document without changing the selection.

See Scintilla documentation for  L<SCI_APPENDTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_APPENDTEXT>

=cut

$autogen{SCI_APPENDTEXT} = {
    subProto => 'appendText(text) => int',
    sciProto => 'SCI_APPENDTEXT(position length, const char *text)',
};

=item insertText

    editor->insertText($pos, $text);

Insert string at a position.

See Scintilla documentation for  L<SCI_INSERTTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_INSERTTEXT>

=cut

$autogen{SCI_INSERTTEXT} = {
    subProto => 'insertText(pos, text)',
    sciProto => 'SCI_INSERTTEXT(position pos, const char *text)',
};

=item changeInsertion

    editor->changeInsertion($length, $text);

Change the text that is being inserted in response to SC_MOD_INSERTCHECK.

(This is only meaningful in a notification handler for the SC_MOD_INSERTCHECK notification, and will not be
implemented in this module until notifications and callbacks are implemented.)

See Scintilla documentation for  L<SCI_CHANGEINSERTION|https://www.scintilla.org/ScintillaDoc.html#SCI_CHANGEINSERTION>

=cut

$autogen{SCI_CHANGEINSERTION} = {
    subProto => 'changeInsertion(length,text)',
    sciProto => 'SCI_CHANGEINSERTION(position length, const char *text)',
};

=item clearAll

    editor->clearAll();

Delete all text in the document.

See Scintilla documentation for  L<SCI_CLEARALL|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARALL>

=cut

$autogen{SCI_CLEARALL} = {
    subProto => 'clearAll()',
    sciProto => 'SCI_CLEARALL',
};

=item deleteRange

    editor->deleteRange($pos, $deleteLength);

Delete a range of text in the document.

See Scintilla documentation for  L<SCI_DELETERANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_DELETERANGE>

=cut

$autogen{SCI_DELETERANGE} = {
    subProto => 'deleteRange(pos, deleteLength)',
    sciProto => 'SCI_DELETERANGE(position start, position lengthDelete)',
};

=item clearDocumentStyle

    editor->clearDocumentStyle();

Set all style bytes to 0, remove all folding information.

See Scintilla documentation for  L<SCI_CLEARDOCUMENTSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARDOCUMENTSTYLE>

=cut

$autogen{SCI_CLEARDOCUMENTSTYLE} = {
    subProto => 'clearDocumentStyle()',
    sciProto => 'SCI_CLEARDOCUMENTSTYLE',
};

=item getCharAt

    editor->getCharAt($pos);

Returns the character byte at the position.

See Scintilla documentation for  L<SCI_GETCHARAT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCHARAT>

=cut

$autogen{SCI_GETCHARAT} = {
    subProto => 'getCharAt(pos) => int',
    sciProto => 'SCI_GETCHARAT(position pos) => int',
};

=item getStyleAt

    editor->getStyleAt($pos);

Returns the style byte at the position.

See Scintilla documentation for  L<SCI_GETSTYLEAT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSTYLEAT>

=cut

$autogen{SCI_GETSTYLEAT} = {
    subProto => 'getStyleAt(pos) => int',
    sciProto => 'SCI_GETSTYLEAT(position pos) => int',
};

=item getStyledText

    editor->getStyledText($start, $end);

Retrieve a buffer of cells. Returns the number of bytes in the buffer not including terminating NULs.

See Scintilla documentation for  L<SCI_GETSTYLEDTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSTYLEDTEXT>

=cut

#$autogen{SCI_GETSTYLEDTEXT} = {
#    subProto => 'getStyledText(start, end) => tuple',
#    sciProto => 'SCI_GETSTYLEDTEXT(<unused>, Sci_TextRange *tr) => position',
#};

sub getStyledText {
    my ($self, $start, $end) = @_;
    croak sprintf qq|%s->getStyledText(%s,%s): end must be greater than or equal to start|, ref($self), $start//'<undef>', $end//'<undef>'
        unless 0+$end >= 0+$start;

    # the wparam is 0.  the lparam is a struct { cpMin, cpMax, char* },
    #   where cpMin and cpMax are set before calling, and char* must be an allocated virtual-buffer

    # prepare the text buffer
    my $buflen = 2 + 2*($end-$start);
    my $text_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), $buflen );
    if(0) { # DEBUG
        my $readback = Win32::GuiTest::ReadFromVirtualBuffer( $text_buf , $buflen );
        printf STDERR "text buf virtual string = '%s'\n", $readback;
    }

    # create the packed string for the structure
    my $pk = __ptrPack();     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize
    my $packed_struct = pack "ll $pk", $start, $end, $text_buf->{ptr};
    if(0) { # DEBUG
        print STDERR "packed_struct = 0x"; printf STDERR "%02x ", ord($_) for split //, $packed_struct; print STDERR "\n";
        my ($smin,$smax,$ptr) = unpack "ll $pk", $packed_struct;
        printf STDERR "\t(%s,%s) 0x%08x\n", $smin,$smax,$ptr;
    }

    # allocate memory and populate the virtual-buffer structure
    my $struct_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), length($packed_struct) );
    Win32::GuiTest::WriteToVirtualBuffer( $struct_buf, $packed_struct );

    # send the GETSTYLEDTEXT message
    my $ret = $self->SendMessage( $SCIMSG{SCI_GETSTYLEDTEXT} , 0 , $struct_buf->{ptr} );

    # read back from the string
    my $readback = Win32::GuiTest::ReadFromVirtualBuffer( $text_buf , $buflen-2 );  # don't grab the end nulls
    if(0) {
        printf STDERR "text buf virtual string = '%s'\n", $readback;
        print STDERR "hex(readback) = 0x";
        printf STDERR "%02x ", ord($_) for split //, $readback;
        print STDERR "\n";
    }

    # deinterleave string...
    my $text = '';
    my @styles = ();
    my $tlen = $end-$start;
    for my $i (0 .. $tlen-1) {
        $text .= substr($readback, 2*$i+0, 1);
        $styles[$i] = ord substr($readback, 2*$i+1, 1);
    }
    if(0) {
        printf STDERR "=> '%s', [%s]\n", $text, join(',',@styles);
    }

    # cleanup
    Win32::GuiTest::FreeVirtualBuffer( $_ ) for $struct_buf, $text_buf;

    return wantarray ? ($text, [@styles]) : $readback;
}

=item releaseAllExtendedStyles

    editor->releaseAllExtendedStyles();

Release all extended (>255) style numbers

See Scintilla documentation for  L<SCI_RELEASEALLEXTENDEDSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_RELEASEALLEXTENDEDSTYLES>

=cut

$autogen{SCI_RELEASEALLEXTENDEDSTYLES} = {
    subProto => 'releaseAllExtendedStyles()',
    sciProto => 'SCI_RELEASEALLEXTENDEDSTYLES',
};

=item allocateExtendedStyles

    editor->allocateExtendedStyles($numberStyles);

Allocate some extended (>255) style numbers and return the start of the range

See Scintilla documentation for  L<SCI_ALLOCATEEXTENDEDSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_ALLOCATEEXTENDEDSTYLES>

=cut

$autogen{SCI_ALLOCATEEXTENDEDSTYLES} = {
    subProto => 'allocateExtendedStyles(numberStyles) => int',
    sciProto => 'SCI_ALLOCATEEXTENDEDSTYLES(int numberStyles) => int',
};

=item targetAsUTF8

    editor->targetAsUTF8();

Returns the target converted to UTF8. Return the length in bytes.

See Scintilla documentation for  L<SCI_TARGETASUTF8|https://www.scintilla.org/ScintillaDoc.html#SCI_TARGETASUTF8>

=cut

$autogen{SCI_TARGETASUTF8} = {
    subProto => 'targetAsUTF8() => str',
    sciProto => 'SCI_TARGETASUTF8(<unused>, char *s) => position',
};

=item encodedFromUTF8

    editor->encodedFromUTF8();

Translates a UTF8 string into the document encoding. Return the length of the result in bytes. On error return 0.

See Scintilla documentation for  L<SCI_ENCODEDFROMUTF8|https://www.scintilla.org/ScintillaDoc.html#SCI_ENCODEDFROMUTF8>

=cut

$autogen{SCI_ENCODEDFROMUTF8} = {
    subProto => 'encodedFromUTF8() => str',
    sciProto => 'SCI_ENCODEDFROMUTF8(const char *utf8, char *encoded) => position',
};

=item setLengthForEncode

    editor->setLengthForEncode($bytes);

Set the length of the utf8 argument for calling EncodedFromUTF8. Set to -1 and the string will be measured to the first nul.

See Scintilla documentation for  L<SCI_SETLENGTHFORENCODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLENGTHFORENCODE>

=cut

$autogen{SCI_SETLENGTHFORENCODE} = {
    subProto => 'setLengthForEncode(bytes)',
    sciProto => 'SCI_SETLENGTHFORENCODE(position bytes)',
};

=back

=head2 Searching





=over

=item setTargetStart

=item getTargetStart

    editor->setTargetStart($pos);
    editor->getTargetStart();

Set the position that starts the target which is used for updating the document without affecting the scroll position.

See Scintilla documentation for  L<SCI_SETTARGETSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTARGETSTART>

See Scintilla documentation for  L<SCI_GETTARGETSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTARGETSTART>

=cut

$autogen{SCI_SETTARGETSTART} = {
    subProto => 'setTargetStart(pos)',
    sciProto => 'SCI_SETTARGETSTART(position start)',
};

$autogen{SCI_GETTARGETSTART} = {
    subProto => 'getTargetStart() => int',
    sciProto => 'SCI_GETTARGETSTART => position',
};

=item setTargetEnd

=item getTargetEnd

    editor->setTargetEnd($pos);
    editor->getTargetEnd();

Set the position that ends the target which is used for updating the document without affecting the scroll position.

See Scintilla documentation for  L<SCI_SETTARGETEND|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTARGETEND>

See Scintilla documentation for  L<SCI_GETTARGETEND|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTARGETEND>

=cut

$autogen{SCI_SETTARGETEND} = {
    subProto => 'setTargetEnd(pos)',
    sciProto => 'SCI_SETTARGETEND(position end)',
};

$autogen{SCI_GETTARGETEND} = {
    subProto => 'getTargetEnd() => int',
    sciProto => 'SCI_GETTARGETEND => position',
};

=item setTargetRange

    editor->setTargetRange($start, $end);

Sets both the start and end of the target in one call.

See Scintilla documentation for  L<SCI_SETTARGETRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTARGETRANGE>

=cut

$autogen{SCI_SETTARGETRANGE} = {
    subProto => 'setTargetRange(start, end)',
    sciProto => 'SCI_SETTARGETRANGE(position start, position end)',
};

=item targetFromSelection

    editor->targetFromSelection();

Make the target range start and end be the same as the selection range start and end.

See Scintilla documentation for  L<SCI_TARGETFROMSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_TARGETFROMSELECTION>

=cut

$autogen{SCI_TARGETFROMSELECTION} = {
    subProto => 'targetFromSelection()',
    sciProto => 'SCI_TARGETFROMSELECTION',
};

=item targetWholeDocument

    editor->targetWholeDocument();

Sets the target to the whole document.

See Scintilla documentation for  L<SCI_TARGETWHOLEDOCUMENT|https://www.scintilla.org/ScintillaDoc.html#SCI_TARGETWHOLEDOCUMENT>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_TARGETWHOLEDOCUMENT} = {
    subProto => 'targetWholeDocument',
    sciProto => 'SCI_TARGETWHOLEDOCUMENT',
};

=item setSearchFlags

=item getSearchFlags

    editor->setSearchFlags($searchFlags);
    editor->getSearchFlags();

Set the search flags used by searchInTarget.

The c<$searchFlags> should be a combination of the elements from L<%SC_FIND|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FIND">

See Scintilla documentation for  L<SCI_SETSEARCHFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSEARCHFLAGS>

See Scintilla documentation for  L<SCI_GETSEARCHFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSEARCHFLAGS>

See Scintilla documentation for  L<searchFlags|https://www.scintilla.org/ScintillaDoc.html#searchFlags>

=cut

$autogen{SCI_SETSEARCHFLAGS} = {
    subProto => 'setSearchFlags(flags)',
    sciProto => 'SCI_SETSEARCHFLAGS(int searchFlags)',
};

$autogen{SCI_GETSEARCHFLAGS} = {
    subProto => 'getSearchFlags() => int',
    sciProto => 'SCI_GETSEARCHFLAGS => int',
};

=item searchInTarget

    editor->searchInTarget($textRE);

Search for a counted string in the target and set the target to the found range. Text is counted so it can contain NULs. Returns length of range or -1 for failure in which case target is not moved.

C<$textRE> is a Boost regular expression in a string, I<not> a perl C<qr//> regular expression.

See Scintilla documentation for  L<SCI_SEARCHINTARGET|https://www.scintilla.org/ScintillaDoc.html#SCI_SEARCHINTARGET>

=cut

$autogen{SCI_SEARCHINTARGET} = {
    subProto => 'searchInTarget(text) => int',
    sciProto => 'SCI_SEARCHINTARGET(position length, const char *text) => position',
};

=item getTargetText

    editor->getTargetText();

Retrieve the text in the target.

See Scintilla documentation for  L<SCI_GETTARGETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTARGETTEXT>

=cut

#$autogen{SCI_GETTARGETTEXT} = {
#    subProto => 'getTargetText => str',
#    sciProto => 'SCI_GETTARGETTEXT(<unused>, char *text) => position',
#};

sub getTargetText {
    my $self = shift;
    # the autogen detection would have wrapped this like getText, which assumes
    # that MSG(0, NUL) returns a length _including_ the \0 EOS marker
    # but getTargetText's MSG returns the length of the string WITHOUT the \0
    #   hence, a manual wrapper which tells getRawString that I need the extra character

    my $args = { trim => 'retval+1', wlength => 1 };
    return $self->{_hwobj}->SendMessage_getRawString( $SCIMSG{SCI_GETTARGETTEXT} , 0, $args );
}

=item replaceTarget

    editor->replaceTarget($text);

Replace the target text with the argument text. Text is counted so it can contain NULs. Returns the length of the replacement text.

See Scintilla documentation for  L<SCI_REPLACETARGET|https://www.scintilla.org/ScintillaDoc.html#SCI_REPLACETARGET>

=cut

$autogen{SCI_REPLACETARGET} = {
    subProto => 'replaceTarget(text) => int',
    sciProto => 'SCI_REPLACETARGET(position length, const char *text) => position',
};

=item replaceTargetRE

    editor->replaceTargetRE($textRE);

Replace the target text with the argument text after \d processing.
Text is counted so it can contain NULs.
Looks for \d where d is between 1 and 9 and replaces these with the
strings matched in the last search operation which were surrounded
by \( and \). Returns the length of the replacement text including
any change caused by processing the \d patterns.

Please note: the C<$textRE> is a string containing a Boost regular
expression replacement I<string>, not a perl regular expression C<qr//>.
To avoid perl interpolating the C<\0> and similar in the string, make
sure you use perl's single-quote C<''> or C<q{}> notation (or properly
escape the backslashes in the string.)

    editor->setText("Hello World");
    select undef,undef,undef, 0.01; # after setText, you sometimes need a delay of 10ms or more to ensure the text is there before continuing
    editor->setTargetRange(0,5);
    editor->setSearchFlags($SC_FIND{SCFIND_REGEXP});
    editor->searchInTarget('([aeiou])');
    editor->replaceTargetRE('_\\1_');
    print editor->getTargetText(); # "H_e_llo World"

See Scintilla documentation for  L<SCI_REPLACETARGETRE|https://www.scintilla.org/ScintillaDoc.html#SCI_REPLACETARGETRE>

=cut

$autogen{SCI_REPLACETARGETRE} = {
    subProto => 'replaceTargetRE(text) => int',
    sciProto => 'SCI_REPLACETARGETRE(position length, const char *text) => position',
};

=item getTag

    editor->getTag($tagNumber);

Retrieve the value of a tag from a regular expression search.

See Scintilla documentation for  L<SCI_GETTAG|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTAG>

=cut

$autogen{SCI_GETTAG} = {
    subProto => 'getTag(tagNumber) => str',
    sciProto => 'SCI_GETTAG(int tagNumber, char *tagValue) => int',
};

=item findText

    editor->findText($searchFlags, $start, $end, $textToFind);

Find some text in the document.

Returns the position of the match, or C<undef> if the text is not found.

The c<$searchFlags> should be a combination of the elements from L<%SC_FIND|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FIND">

C<$textToFind> is a literal string or a Boost regular expression in a string, I<not> a perl C<qr//> regular expression.

See Scintilla documentation for  L<SCI_FINDTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_FINDTEXT> and L<searchFlags|https://www.scintilla.org/ScintillaDoc.html#searchFlags>

See Scintilla documentation for  L<searchFlags|https://www.scintilla.org/ScintillaDoc.html#searchFlags>

=cut

#$autogen{SCI_FINDTEXT} = {
#    subProto => 'findText(flags, start, end, ft) => object',
#    sciProto => 'SCI_FINDTEXT(int searchFlags, Sci_TextToFind *ft) => position',
#};

# https://github.com/bruderstein/PythonScript/blob/4c34bfb545a348f3f12c9ef5135ab201e81ed480/PythonScript/src/ScintillaWrapperGenerated.cpp#L1821-L1840
# Sci_TextToFind = struct { Sci_CharacterRange chrg; const char*text; Sci_CharacterRange chrgText; }
# Sci_CharacterRange = struct { long cpMin; long cpMax }
# so need MSG( searchFlags, { {min,max}, "text", {min,max} )
#   where the first is where to search, and the second is the result
#   Some C-based experiments showed that I can use pack "ll Q ll", where the Q is the ptr (64bit) or switch to another L in 32-bit

sub findText {
    my ($self, $flags, $start, $end, $textToFind) = @_;
    #{my $oldfh = select STDERR;$|++;select $oldfh;$|++;}

    my $pk = __ptrPack();     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize

    # prepare the search text
    my $buflen = 1 + length($textToFind);   # null terminated string, so one char longer
    my $text_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), $buflen );
    Win32::GuiTest::WriteToVirtualBuffer( $text_buf, $textToFind );
    if(0) { # DEBUG
        my $readback = Win32::GuiTest::ReadFromVirtualBuffer( $text_buf , $buflen );
        printf STDERR "text buf virtual string = '%s'\n", $readback;
    }

    # create the packed string for the structure
    my $packed_struct = pack "ll $pk ll", $start, $end, $text_buf->{ptr}, 0, 0;
    if(0) { # DEBUG
        print STDERR "packed_struct = 0x"; printf STDERR "%02x ", ord($_) for split //, $packed_struct; print STDERR "\n";
        my ($smin,$smax,$ptr,$tmin,$tmax) = unpack "ll $pk ll", $packed_struct;
        printf STDERR "\t(%s,%s) 0x%08x (%s,%s)\n", $smin,$smax,$ptr,$tmin,$tmax;
    }

    # allocate memory and populate the virtual-buffer structure
    my $struct_buf = Win32::GuiTest::AllocateVirtualBuffer( $self->hwnd(), length($packed_struct) );
    Win32::GuiTest::WriteToVirtualBuffer( $struct_buf, $packed_struct );

    # perform the search
    my $ret; # crashes = $self->{_hwobj}->SendMessage( $SCIMSG{SCI_FINDTEXT} , $flags , $struct_buf->{ptr} );
        # CRASH: will need to debug this in more detail; my guess is it needs to be long, long, ptr, long, long, but it will take experimentation to get right
    $ret = $self->SendMessage( $SCIMSG{SCI_FINDTEXT} , $flags , $struct_buf->{ptr} );
    if(0) { printf STDERR "SendMessage() retval = '%s'\n", $ret//'<undef>'; }

    # read back the virtual structure
    my $new_struct = Win32::GuiTest::ReadFromVirtualBuffer( $struct_buf , length($packed_struct) );
    if(0) { print STDERR "new_struct    = 0x"; printf STDERR "%02x ", ord($_) for split //, $new_struct; print STDERR "\n"; }
    my ($smin,$smax,$ptr,$tmin,$tmax) = unpack "ll $pk ll", $new_struct;
    if(0) { printf STDERR "\t(%s,%s) 0x%08x (%s,%s)\n", $smin,$smax,$ptr,$tmin,$tmax; }

    # cleanup
    Win32::GuiTest::FreeVirtualBuffer( $_ ) for $struct_buf, $text_buf;

    # return array-ref with the start and end locations for the found text; if nothing found, return undef
    return ($ret<0) ? undef : [$tmin,$tmax];
}


=item searchAnchor

    editor->searchAnchor();

Sets the current caret position to be the search anchor.

See Scintilla documentation for  L<SCI_SEARCHANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_SEARCHANCHOR>

=cut

$autogen{SCI_SEARCHANCHOR} = {
    subProto => 'searchAnchor()',
    sciProto => 'SCI_SEARCHANCHOR',
};

=item searchNext

    editor->searchNext($flags, $text);

Find some text starting at the search anchor. Does not ensure the selection is visible.

See Scintilla documentation for  L<SCI_SEARCHNEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_SEARCHNEXT>

=cut

$autogen{SCI_SEARCHNEXT} = {
    subProto => 'searchNext(flags, text) => int',
    sciProto => 'SCI_SEARCHNEXT(int searchFlags, const char *text) => position',
};

=item searchPrev

    editor->searchPrev($flags, $text);

Find some text starting at the search anchor and moving backwards. Does not ensure the selection is visible.

See Scintilla documentation for  L<SCI_SEARCHPREV|https://www.scintilla.org/ScintillaDoc.html#SCI_SEARCHPREV>

=cut

$autogen{SCI_SEARCHPREV} = {
    subProto => 'searchPrev(flags, text) => int',
    sciProto => 'SCI_SEARCHPREV(int searchFlags, const char *text) => position',
};

=back

=head2 Overtype




=over

=item setOvertype

=item getOvertype

    editor->setOvertype($overtype);
    editor->getOvertype();

Set to overtype (true) or insert mode.

See Scintilla documentation for  L<SCI_SETOVERTYPE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETOVERTYPE>

See Scintilla documentation for  L<SCI_GETOVERTYPE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETOVERTYPE>

=cut

$autogen{SCI_SETOVERTYPE} = {
    subProto => 'setOvertype(overtype)',
    sciProto => 'SCI_SETOVERTYPE(bool overType)',
};

$autogen{SCI_GETOVERTYPE} = {
    subProto => 'getOvertype() => bool',
    sciProto => 'SCI_GETOVERTYPE => bool',
};

=back

=head2 Cut, Copy, and Paste




=over

=item cut

    editor->cut();

Cut the selection to the clipboard.

See Scintilla documentation for  L<SCI_CUT|https://www.scintilla.org/ScintillaDoc.html#SCI_CUT>

=cut

$autogen{SCI_CUT} = {
    subProto => 'cut()',
    sciProto => 'SCI_CUT',
};

=item copy

    editor->copy();

Copy the selection to the clipboard.

See Scintilla documentation for  L<SCI_COPY|https://www.scintilla.org/ScintillaDoc.html#SCI_COPY>

=cut

$autogen{SCI_COPY} = {
    subProto => 'copy()',
    sciProto => 'SCI_COPY',
};

=item paste

    editor->paste();

Paste the contents of the clipboard into the document replacing the selection.

See Scintilla documentation for  L<SCI_PASTE|https://www.scintilla.org/ScintillaDoc.html#SCI_PASTE>

=cut

$autogen{SCI_PASTE} = {
    subProto => 'paste()',
    sciProto => 'SCI_PASTE',
};

=item clear

    editor->clear();

Clear the selection.

See Scintilla documentation for  L<SCI_CLEAR|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEAR>

=cut

$autogen{SCI_CLEAR} = {
    subProto => 'clear()',
    sciProto => 'SCI_CLEAR',
};

=item canPaste

    editor->canPaste();

Will a paste succeed?

See Scintilla documentation for  L<SCI_CANPASTE|https://www.scintilla.org/ScintillaDoc.html#SCI_CANPASTE>

=cut

$autogen{SCI_CANPASTE} = {
    subProto => 'canPaste() => bool',
    sciProto => 'SCI_CANPASTE => bool',
};

=item copyRange

    editor->copyRange($start, $end);

Copy a range of text to the clipboard. Positions are clipped into the document.

See Scintilla documentation for  L<SCI_COPYRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_COPYRANGE>

=cut

$autogen{SCI_COPYRANGE} = {
    subProto => 'copyRange(start, end)',
    sciProto => 'SCI_COPYRANGE(position start, position end)',
};

=item copyText

    editor->copyText($text);

Copy argument text to the clipboard.

See Scintilla documentation for  L<SCI_COPYTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_COPYTEXT>

=cut

$autogen{SCI_COPYTEXT} = {
    subProto => 'copyText(text) => int',
    sciProto => 'SCI_COPYTEXT(position length, const char *text)',
};

=item copyAllowLine

    editor->copyAllowLine();

Copy the selection, if selection empty copy the line with the caret

See Scintilla documentation for  L<SCI_COPYALLOWLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_COPYALLOWLINE>

=cut

$autogen{SCI_COPYALLOWLINE} = {
    subProto => 'copyAllowLine()',
    sciProto => 'SCI_COPYALLOWLINE',
};

=item setPasteConvertEndings

=item getPasteConvertEndings

    editor->setPasteConvertEndings($convert);
    editor->getPasteConvertEndings();

Enable/Disable convert-on-paste for line endings

See Scintilla documentation for  L<SCI_SETPASTECONVERTENDINGS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPASTECONVERTENDINGS>

See Scintilla documentation for  L<SCI_GETPASTECONVERTENDINGS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPASTECONVERTENDINGS>

=cut

$autogen{SCI_SETPASTECONVERTENDINGS} = {
    subProto => 'setPasteConvertEndings(convert)',
    sciProto => 'SCI_SETPASTECONVERTENDINGS(bool convert)',
};

$autogen{SCI_GETPASTECONVERTENDINGS} = {
    subProto => 'getPasteConvertEndings() => bool',
    sciProto => 'SCI_GETPASTECONVERTENDINGS => bool',
};

=back

=head2 Error handling




=over

=item setStatus

=item getStatus

    editor->setStatus($statusCode);
    editor->getStatus();

Change error status.  Failures from 1 to 999 are errors, and 1000 and above are warnings.  There are predefined errors in L<%SC_STATUS|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_STATUS">.


See Scintilla documentation for  L<SCI_SETSTATUS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSTATUS>

See Scintilla documentation for  L<SCI_GETSTATUS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSTATUS>

=cut

$autogen{SCI_SETSTATUS} = {
    subProto => 'setStatus(statusCode)',
    sciProto => 'SCI_SETSTATUS(int status)',
};

$autogen{SCI_GETSTATUS} = {
    subProto => 'getStatus() => int',
    sciProto => 'SCI_GETSTATUS => int',
};

=back

=head2 Undo and redo




=over

=item undo

    editor->undo();

Undo one action in the undo history.

See Scintilla documentation for  L<SCI_UNDO|https://www.scintilla.org/ScintillaDoc.html#SCI_UNDO>

=cut

$autogen{SCI_UNDO} = {
    subProto => 'undo()',
    sciProto => 'SCI_UNDO',
};

=item canUndo

    editor->canUndo();

Are there any undoable actions in the undo history?

See Scintilla documentation for  L<SCI_CANUNDO|https://www.scintilla.org/ScintillaDoc.html#SCI_CANUNDO>

=cut

$autogen{SCI_CANUNDO} = {
    subProto => 'canUndo() => bool',
    sciProto => 'SCI_CANUNDO => bool',
};

=item emptyUndoBuffer

    editor->emptyUndoBuffer();

Delete the undo history.

See Scintilla documentation for  L<SCI_EMPTYUNDOBUFFER|https://www.scintilla.org/ScintillaDoc.html#SCI_EMPTYUNDOBUFFER>

=cut

$autogen{SCI_EMPTYUNDOBUFFER} = {
    subProto => 'emptyUndoBuffer()',
    sciProto => 'SCI_EMPTYUNDOBUFFER',
};

=item canRedo

    editor->canRedo();

Are there any redoable actions in the undo history?

See Scintilla documentation for  L<SCI_CANREDO|https://www.scintilla.org/ScintillaDoc.html#SCI_CANREDO>

=cut

$autogen{SCI_CANREDO} = {
    subProto => 'canRedo() => bool',
    sciProto => 'SCI_CANREDO => bool',
};

=item redo

    editor->redo();

Redoes the next action on the undo history.

See Scintilla documentation for  L<SCI_REDO|https://www.scintilla.org/ScintillaDoc.html#SCI_REDO>

=cut

$autogen{SCI_REDO} = {
    subProto => 'redo()',
    sciProto => 'SCI_REDO',
};

=item setUndoCollection

=item getUndoCollection

    editor->setUndoCollection($collectUndo);
    editor->getUndoCollection();

Choose between collecting actions into the undo history and discarding them.

See Scintilla documentation for  L<SCI_SETUNDOCOLLECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETUNDOCOLLECTION>

See Scintilla documentation for  L<SCI_GETUNDOCOLLECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETUNDOCOLLECTION>

=cut

$autogen{SCI_SETUNDOCOLLECTION} = {
    subProto => 'setUndoCollection(collectUndo)',
    sciProto => 'SCI_SETUNDOCOLLECTION(bool collectUndo)',
};

$autogen{SCI_GETUNDOCOLLECTION} = {
    subProto => 'getUndoCollection() => bool',
    sciProto => 'SCI_GETUNDOCOLLECTION => bool',
};

=item beginUndoAction

    editor->beginUndoAction();

Start a sequence of actions that is undone and redone as a unit. May be nested.

See Scintilla documentation for  L<SCI_BEGINUNDOACTION|https://www.scintilla.org/ScintillaDoc.html#SCI_BEGINUNDOACTION>

=cut

$autogen{SCI_BEGINUNDOACTION} = {
    subProto => 'beginUndoAction()',
    sciProto => 'SCI_BEGINUNDOACTION',
};

=item endUndoAction

    editor->endUndoAction();

End a sequence of actions that is undone and redone as a unit.

See Scintilla documentation for  L<SCI_ENDUNDOACTION|https://www.scintilla.org/ScintillaDoc.html#SCI_ENDUNDOACTION>

=cut

$autogen{SCI_ENDUNDOACTION} = {
    subProto => 'endUndoAction()',
    sciProto => 'SCI_ENDUNDOACTION',
};

=item addUndoAction

    editor->addUndoAction($token, $flags);

Add a container action to the undo stack.

Use $flags from L<%SC_UNDO|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_UNDO">.


See Scintilla documentation for  L<SCI_ADDUNDOACTION|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDUNDOACTION>

=cut

$autogen{SCI_ADDUNDOACTION} = {
    subProto => 'addUndoAction(token, flags)',
    sciProto => 'SCI_ADDUNDOACTION(int token, int flags)',
};

=back

=head2 Selection and information




=over

=item getTextLength

    editor->getTextLength();

Retrieve the number of characters in the document.

See Scintilla documentation for  L<SCI_GETTEXTLENGTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTEXTLENGTH>

=cut

$autogen{SCI_GETTEXTLENGTH} = {
    subProto => 'getTextLength() => int',
    sciProto => 'SCI_GETTEXTLENGTH => position',
};

=item getLength

    editor->getLength();

Returns the number of bytes in the document.

See Scintilla documentation for  L<SCI_GETLENGTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLENGTH>

=cut

$autogen{SCI_GETLENGTH} = {
    subProto => 'getLength() => int',
    sciProto => 'SCI_GETLENGTH => position',
};

=item getLineCount

    editor->getLineCount();

Returns the number of lines in the document. There is always at least one.

See Scintilla documentation for  L<SCI_GETLINECOUNT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINECOUNT>

=cut

$autogen{SCI_GETLINECOUNT} = {
    subProto => 'getLineCount() => int',
    sciProto => 'SCI_GETLINECOUNT => line',
};

=item linesOnScreen

    editor->linesOnScreen();

Retrieves the number of lines completely visible.

See Scintilla documentation for  L<SCI_LINESONSCREEN|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESONSCREEN>

=cut

$autogen{SCI_LINESONSCREEN} = {
    subProto => 'linesOnScreen() => int',
    sciProto => 'SCI_LINESONSCREEN => line',
};

=item getModify

    editor->getModify();

Is the document different from when it was last saved?

See Scintilla documentation for  L<SCI_GETMODIFY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMODIFY>

=cut

$autogen{SCI_GETMODIFY} = {
    subProto => 'getModify() => bool',
    sciProto => 'SCI_GETMODIFY => bool',
};

=item setSel

    editor->setSel($start, $end);

Select a range of text.

See Scintilla documentation for  L<SCI_SETSEL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSEL>

=cut

$autogen{SCI_SETSEL} = {
    subProto => 'setSel(start, end)',
    sciProto => 'SCI_SETSEL(position anchor, position caret)',
};

=item gotoPos

    editor->gotoPos($pos);

Set caret to a position and ensure it is visible.

See Scintilla documentation for  L<SCI_GOTOPOS|https://www.scintilla.org/ScintillaDoc.html#SCI_GOTOPOS>

=cut

$autogen{SCI_GOTOPOS} = {
    subProto => 'gotoPos(pos)',
    sciProto => 'SCI_GOTOPOS(position caret)',
};

=item gotoLine

    editor->gotoLine($line);

Set caret to start of a line and ensure it is visible.

See Scintilla documentation for  L<SCI_GOTOLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GOTOLINE>

=cut

$autogen{SCI_GOTOLINE} = {
    subProto => 'gotoLine(line)',
    sciProto => 'SCI_GOTOLINE(line line)',
};

=item setCurrentPos

=item getCurrentPos

    editor->setCurrentPos($pos);
    editor->getCurrentPos();

Sets the position of the caret.

See Scintilla documentation for  L<SCI_SETCURRENTPOS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCURRENTPOS>

See Scintilla documentation for  L<SCI_GETCURRENTPOS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCURRENTPOS>

=cut

$autogen{SCI_SETCURRENTPOS} = {
    subProto => 'setCurrentPos(pos)',
    sciProto => 'SCI_SETCURRENTPOS(position caret)',
};

$autogen{SCI_GETCURRENTPOS} = {
    subProto => 'getCurrentPos() => int',
    sciProto => 'SCI_GETCURRENTPOS => position',
};

=item setAnchor

=item getAnchor

    editor->setAnchor($posAnchor);
    editor->getAnchor();

Set the selection anchor to a position. The anchor is the opposite end of the selection from the caret.

See Scintilla documentation for  L<SCI_SETANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETANCHOR>

See Scintilla documentation for  L<SCI_GETANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETANCHOR>

=cut

$autogen{SCI_SETANCHOR} = {
    subProto => 'setAnchor(posAnchor)',
    sciProto => 'SCI_SETANCHOR(position anchor)',
};

$autogen{SCI_GETANCHOR} = {
    subProto => 'getAnchor() => int',
    sciProto => 'SCI_GETANCHOR => position',
};

=item setSelectionStart

=item getSelectionStart

    editor->setSelectionStart($pos);
    editor->getSelectionStart();

Sets the position that starts the selection - this becomes the anchor.

See Scintilla documentation for  L<SCI_SETSELECTIONSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONSTART>

See Scintilla documentation for  L<SCI_GETSELECTIONSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONSTART>

=cut

$autogen{SCI_SETSELECTIONSTART} = {
    subProto => 'setSelectionStart(pos)',
    sciProto => 'SCI_SETSELECTIONSTART(position anchor)',
};

$autogen{SCI_GETSELECTIONSTART} = {
    subProto => 'getSelectionStart() => int',
    sciProto => 'SCI_GETSELECTIONSTART => position',
};

=item setSelectionEnd

=item getSelectionEnd

    editor->setSelectionEnd($pos);
    editor->getSelectionEnd();

Sets the position that ends the selection - this becomes the currentPosition.

See Scintilla documentation for  L<SCI_SETSELECTIONEND|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONEND>

See Scintilla documentation for  L<SCI_GETSELECTIONEND|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONEND>

=cut

$autogen{SCI_SETSELECTIONEND} = {
    subProto => 'setSelectionEnd(pos)',
    sciProto => 'SCI_SETSELECTIONEND(position caret)',
};

$autogen{SCI_GETSELECTIONEND} = {
    subProto => 'getSelectionEnd() => int',
    sciProto => 'SCI_GETSELECTIONEND => position',
};

=item setEmptySelection

    editor->setEmptySelection($pos);

Set caret to a position, while removing any existing selection.

See Scintilla documentation for  L<SCI_SETEMPTYSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEMPTYSELECTION>

=cut

$autogen{SCI_SETEMPTYSELECTION} = {
    subProto => 'setEmptySelection(pos)',
    sciProto => 'SCI_SETEMPTYSELECTION(position caret)',
};

=item selectAll

    editor->selectAll();

Select all the text in the document.

See Scintilla documentation for  L<SCI_SELECTALL|https://www.scintilla.org/ScintillaDoc.html#SCI_SELECTALL>

=cut

$autogen{SCI_SELECTALL} = {
    subProto => 'selectAll()',
    sciProto => 'SCI_SELECTALL',
};

=item lineFromPosition

    editor->lineFromPosition($pos);

Retrieve the line containing a position.

See Scintilla documentation for  L<SCI_LINEFROMPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEFROMPOSITION>

=cut

$autogen{SCI_LINEFROMPOSITION} = {
    subProto => 'lineFromPosition(pos) => int',
    sciProto => 'SCI_LINEFROMPOSITION(position pos) => line',
};

=item positionFromLine

    editor->positionFromLine($line);

Retrieve the position at the start of a line.

See Scintilla documentation for  L<SCI_POSITIONFROMLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONFROMLINE>

=cut

$autogen{SCI_POSITIONFROMLINE} = {
    subProto => 'positionFromLine(line) => int',
    sciProto => 'SCI_POSITIONFROMLINE(line line) => position',
};

=item getLineEndPosition

    editor->getLineEndPosition($line);

Get the position after the last visible characters on a line.

See Scintilla documentation for  L<SCI_GETLINEENDPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEENDPOSITION>

=cut

$autogen{SCI_GETLINEENDPOSITION} = {
    subProto => 'getLineEndPosition(line) => int',
    sciProto => 'SCI_GETLINEENDPOSITION(line line) => position',
};

=item lineLength

    editor->lineLength($line);

How many characters are on a line, including end of line characters?

See Scintilla documentation for  L<SCI_LINELENGTH|https://www.scintilla.org/ScintillaDoc.html#SCI_LINELENGTH>

=cut

$autogen{SCI_LINELENGTH} = {
    subProto => 'lineLength(line) => int',
    sciProto => 'SCI_LINELENGTH(line line) => position',
};

=item getColumn

    editor->getColumn($pos);

Retrieve the column number of a position, taking tab width into account.

See Scintilla documentation for  L<SCI_GETCOLUMN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCOLUMN>

=cut

$autogen{SCI_GETCOLUMN} = {
    subProto => 'getColumn(pos) => int',
    sciProto => 'SCI_GETCOLUMN(position pos) => position',
};

=item findColumn

    editor->findColumn($line, $column);

Find the position of a column on a line taking into account tabs and multi-byte characters. If beyond end of line, return line end position.

See Scintilla documentation for  L<SCI_FINDCOLUMN|https://www.scintilla.org/ScintillaDoc.html#SCI_FINDCOLUMN>

=cut

$autogen{SCI_FINDCOLUMN} = {
    subProto => 'findColumn(line, column) => int',
    sciProto => 'SCI_FINDCOLUMN(line line, position column) => position',
};

=item positionFromPoint

    editor->positionFromPoint($x, $y);

Find the position from a point within the window.

See Scintilla documentation for  L<SCI_POSITIONFROMPOINT|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONFROMPOINT>

=cut

$autogen{SCI_POSITIONFROMPOINT} = {
    subProto => 'positionFromPoint(x, y) => int',
    sciProto => 'SCI_POSITIONFROMPOINT(int x, int y) => position',
};

=item positionFromPointClose

    editor->positionFromPointClose($x, $y);

Find the position from a point within the window but return INVALID_POSITION if not close to text.

See Scintilla documentation for  L<SCI_POSITIONFROMPOINTCLOSE|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONFROMPOINTCLOSE>

=cut

$autogen{SCI_POSITIONFROMPOINTCLOSE} = {
    subProto => 'positionFromPointClose(x, y) => int',
    sciProto => 'SCI_POSITIONFROMPOINTCLOSE(int x, int y) => position',
};

=item charPositionFromPoint

    editor->charPositionFromPoint($x, $y);

Find the position of a character from a point within the window.

See Scintilla documentation for  L<SCI_CHARPOSITIONFROMPOINT|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARPOSITIONFROMPOINT>

=cut

$autogen{SCI_CHARPOSITIONFROMPOINT} = {
    subProto => 'charPositionFromPoint(x, y) => int',
    sciProto => 'SCI_CHARPOSITIONFROMPOINT(int x, int y) => position',
};

=item charPositionFromPointClose

    editor->charPositionFromPointClose($x, $y);

Find the position of a character from a point within the window. Return INVALID_POSITION if not close to text.

See Scintilla documentation for  L<SCI_CHARPOSITIONFROMPOINTCLOSE|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARPOSITIONFROMPOINTCLOSE>

=cut

$autogen{SCI_CHARPOSITIONFROMPOINTCLOSE} = {
    subProto => 'charPositionFromPointClose(x, y) => int',
    sciProto => 'SCI_CHARPOSITIONFROMPOINTCLOSE(int x, int y) => position',
};

=item pointXFromPosition

    editor->pointXFromPosition($pos);

Retrieve the x value of the point in the window where a position is displayed.

See Scintilla documentation for  L<SCI_POINTXFROMPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_POINTXFROMPOSITION>

=cut

$autogen{SCI_POINTXFROMPOSITION} = {
    subProto => 'pointXFromPosition(pos) => int',
    sciProto => 'SCI_POINTXFROMPOSITION(<unused>, position pos) => int',
};

=item pointYFromPosition

    editor->pointYFromPosition($pos);

Retrieve the y value of the point in the window where a position is displayed.

See Scintilla documentation for  L<SCI_POINTYFROMPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_POINTYFROMPOSITION>

=cut

$autogen{SCI_POINTYFROMPOSITION} = {
    subProto => 'pointYFromPosition(pos) => int',
    sciProto => 'SCI_POINTYFROMPOSITION(<unused>, position pos) => int',
};

=item hideSelection

    editor->hideSelection($normal);

Draw the selection in normal style or with selection highlighted.

See Scintilla documentation for  L<SCI_HIDESELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_HIDESELECTION>

=cut

$autogen{SCI_HIDESELECTION} = {
    subProto => 'hideSelection(normal)',
    sciProto => 'SCI_HIDESELECTION(bool hide)',
};

=item getSelText

    editor->getSelText();

Retrieve the selected text. Return the length of the text.

See Scintilla documentation for  L<SCI_GETSELTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELTEXT>

=cut

$autogen{SCI_GETSELTEXT} = {
    subProto => 'getSelText() => str',
    sciProto => 'SCI_GETSELTEXT(<unused>, char *text) => position',
};

=item getCurLine

    editor->getCurLine();

Retrieve the text of the line containing the caret. Returns the index of the caret on the line.

See Scintilla documentation for  L<SCI_GETCURLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCURLINE>

=cut

$autogen{SCI_GETCURLINE} = {
    subProto => 'getCurLine() => str',
    sciProto => 'SCI_GETCURLINE(position length, char *text) => position',
};

=item selectionIsRectangle

    editor->selectionIsRectangle();

Is the selection rectangular? The alternative is the more common stream selection.

See Scintilla documentation for  L<SCI_SELECTIONISRECTANGLE|https://www.scintilla.org/ScintillaDoc.html#SCI_SELECTIONISRECTANGLE>

=cut

$autogen{SCI_SELECTIONISRECTANGLE} = {
    subProto => 'selectionIsRectangle() => bool',
    sciProto => 'SCI_SELECTIONISRECTANGLE => bool',
};

=item setSelectionMode

=item getSelectionMode

    editor->setSelectionMode($mode);
    editor->getSelectionMode();

Set the selection mode to stream (normal selection) or rectangular or by lines.

Use $mode from L<%SC_SEL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_SEL">.

See Scintilla documentation for  L<SCI_SETSELECTIONMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONMODE>

See Scintilla documentation for  L<SCI_GETSELECTIONMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONMODE>

=cut

$autogen{SCI_SETSELECTIONMODE} = {
    subProto => 'setSelectionMode(mode)',
    sciProto => 'SCI_SETSELECTIONMODE(int selectionMode)',
};

$autogen{SCI_GETSELECTIONMODE} = {
    subProto => 'getSelectionMode() => int',
    sciProto => 'SCI_GETSELECTIONMODE => int',
};

=item getMoveExtendsSelection

    editor->getMoveExtendsSelection;

Get whether or not regular caret moves will extend or reduce the selection.

See Scintilla documentation for  L<SCI_GETMOVEEXTENDSSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMOVEEXTENDSSELECTION>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_GETMOVEEXTENDSSELECTION} = {
    subProto => 'getMoveExtendsSelection',
    sciProto => 'SCI_GETMOVEEXTENDSSELECTION => bool',
};

=item getLineSelStartPosition

    editor->getLineSelStartPosition($line);

Retrieve the position of the start of the selection at the given line (INVALID_POSITION if no selection on this line).

See Scintilla documentation for  L<SCI_GETLINESELSTARTPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINESELSTARTPOSITION>

=cut

$autogen{SCI_GETLINESELSTARTPOSITION} = {
    subProto => 'getLineSelStartPosition(line) => int',
    sciProto => 'SCI_GETLINESELSTARTPOSITION(line line) => position',
};

=item getLineSelEndPosition

    editor->getLineSelEndPosition($line);

Retrieve the position of the end of the selection at the given line (INVALID_POSITION if no selection on this line).

See Scintilla documentation for  L<SCI_GETLINESELENDPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINESELENDPOSITION>

=cut

$autogen{SCI_GETLINESELENDPOSITION} = {
    subProto => 'getLineSelEndPosition(line) => int',
    sciProto => 'SCI_GETLINESELENDPOSITION(line line) => position',
};

=item moveCaretInsideView

    editor->moveCaretInsideView();

Move the caret inside current view if it’s not there already.

See Scintilla documentation for  L<SCI_MOVECARETINSIDEVIEW|https://www.scintilla.org/ScintillaDoc.html#SCI_MOVECARETINSIDEVIEW>

=cut

$autogen{SCI_MOVECARETINSIDEVIEW} = {
    subProto => 'moveCaretInsideView()',
    sciProto => 'SCI_MOVECARETINSIDEVIEW',
};

=item positionBefore

    editor->positionBefore($pos);

Given a valid document position, return the previous position taking code page into account. Returns 0 if passed 0.

See Scintilla documentation for  L<SCI_POSITIONBEFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONBEFORE>

=cut

$autogen{SCI_POSITIONBEFORE} = {
    subProto => 'positionBefore(pos) => int',
    sciProto => 'SCI_POSITIONBEFORE(position pos) => position',
};

=item positionAfter

    editor->positionAfter($pos);

Given a valid document position, return the next position taking code page into account. Maximum value returned is the last position in the document.

See Scintilla documentation for  L<SCI_POSITIONAFTER|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONAFTER>

=cut

$autogen{SCI_POSITIONAFTER} = {
    subProto => 'positionAfter(pos) => int',
    sciProto => 'SCI_POSITIONAFTER(position pos) => position',
};

=item textWidth

    editor->textWidth($style, $text);

Measure the pixel width of some text in a particular style. NUL terminated text argument. Does not handle tab or control characters.

See Scintilla documentation for  L<SCI_TEXTWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_TEXTWIDTH>

=cut

$autogen{SCI_TEXTWIDTH} = {
    subProto => 'textWidth(style, text) => int',
    sciProto => 'SCI_TEXTWIDTH(int style, const char *text) => int',
};

=item textHeight

    editor->textHeight($line);

Retrieve the height of a particular line of text in pixels.

See Scintilla documentation for  L<SCI_TEXTHEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_TEXTHEIGHT>

=cut

$autogen{SCI_TEXTHEIGHT} = {
    subProto => 'textHeight(line) => int',
    sciProto => 'SCI_TEXTHEIGHT(line line) => int',
};

=item chooseCaretX

    editor->chooseCaretX();

Set the last x chosen value to be the caret x position.

See Scintilla documentation for  L<SCI_CHOOSECARETX|https://www.scintilla.org/ScintillaDoc.html#SCI_CHOOSECARETX>

=cut

$autogen{SCI_CHOOSECARETX} = {
    subProto => 'chooseCaretX()',
    sciProto => 'SCI_CHOOSECARETX',
};

=item moveSelectedLinesUp

    editor->moveSelectedLinesUp();

Move the selected lines up one line, shifting the line above after the selection

See Scintilla documentation for  L<SCI_MOVESELECTEDLINESUP|https://www.scintilla.org/ScintillaDoc.html#SCI_MOVESELECTEDLINESUP>

=cut

$autogen{SCI_MOVESELECTEDLINESUP} = {
    subProto => 'moveSelectedLinesUp()',
    sciProto => 'SCI_MOVESELECTEDLINESUP',
};

=item moveSelectedLinesDown

    editor->moveSelectedLinesDown();

Move the selected lines down one line, shifting the line below before the selection

See Scintilla documentation for  L<SCI_MOVESELECTEDLINESDOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_MOVESELECTEDLINESDOWN>

=cut

$autogen{SCI_MOVESELECTEDLINESDOWN} = {
    subProto => 'moveSelectedLinesDown()',
    sciProto => 'SCI_MOVESELECTEDLINESDOWN',
};

=item setMouseSelectionRectangularSwitch

=item getMouseSelectionRectangularSwitch

    editor->setMouseSelectionRectangularSwitch($mouseSelectionRectangularSwitch);
    editor->getMouseSelectionRectangularSwitch();

Set whether switching to rectangular mode while selecting with the mouse is allowed.

See Scintilla documentation for  L<SCI_SETMOUSESELECTIONRECTANGULARSWITCH|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMOUSESELECTIONRECTANGULARSWITCH>

See Scintilla documentation for  L<SCI_GETMOUSESELECTIONRECTANGULARSWITCH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMOUSESELECTIONRECTANGULARSWITCH>

=cut

$autogen{SCI_SETMOUSESELECTIONRECTANGULARSWITCH} = {
    subProto => 'setMouseSelectionRectangularSwitch(mouseSelectionRectangularSwitch)',
    sciProto => 'SCI_SETMOUSESELECTIONRECTANGULARSWITCH(bool mouseSelectionRectangularSwitch)',
};

$autogen{SCI_GETMOUSESELECTIONRECTANGULARSWITCH} = {
    subProto => 'getMouseSelectionRectangularSwitch() => bool',
    sciProto => 'SCI_GETMOUSESELECTIONRECTANGULARSWITCH => bool',
};

=back

=head2 By character or UTF-16 code unit




=over

=item positionRelative

    editor->positionRelative($pos, $relative);

Given a valid document position, return a position that differs in a number of characters. Returned value is always between 0 and last position in document.

See Scintilla documentation for  L<SCI_POSITIONRELATIVE|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONRELATIVE>

=cut

$autogen{SCI_POSITIONRELATIVE} = {
    subProto => 'positionRelative(pos, relative) => int',
    sciProto => 'SCI_POSITIONRELATIVE(position pos, position relative) => position',
};

=item positionRelativeCodeUnits

    editor->positionRelativeCodeUnits($pos, $relative);

Given a valid document position, return a position that differs in a number of UTF-16 code units. Returned value is always between 0 and last position in document. The result may point half way (2 bytes) inside a non-BMP character.

See Scintilla documentation for  L<SCI_POSITIONRELATIVECODEUNITS|https://www.scintilla.org/ScintillaDoc.html#SCI_POSITIONRELATIVECODEUNITS>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_POSITIONRELATIVECODEUNITS} = {
    subProto => 'positionRelativeCodeUnits(pos, relative) => int',
    sciProto => 'SCI_POSITIONRELATIVECODEUNITS(position pos, position relative) => position',
};

=item countCharacters

    editor->countCharacters($startPos, $endPos);

Count characters between two positions.

See Scintilla documentation for  L<SCI_COUNTCHARACTERS|https://www.scintilla.org/ScintillaDoc.html#SCI_COUNTCHARACTERS>

=cut

$autogen{SCI_COUNTCHARACTERS} = {
    subProto => 'countCharacters(startPos, endPos) => int',
    sciProto => 'SCI_COUNTCHARACTERS(position start, position end) => position',
};

=item countCodeUnits

    editor->countCodeUnits($start, $end);

Count code units between two positions.

See Scintilla documentation for  L<SCI_COUNTCODEUNITS|https://www.scintilla.org/ScintillaDoc.html#SCI_COUNTCODEUNITS>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_COUNTCODEUNITS} = {
    subProto => 'countCodeUnits(start, end) => int',
    sciProto => 'SCI_COUNTCODEUNITS(position start, position end) => position',
};

=item getLineCharacterIndex

    editor->getLineCharacterIndex();

Retrieve line character index state.

Returns a value from L<%SC_LINECHARACTERINDEX|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%SC_LINECHARACTERINDEX>.

See Scintilla documentation for  L<SCI_GETLINECHARACTERINDEX|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINECHARACTERINDEX>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_GETLINECHARACTERINDEX} = {
    subProto => 'getLineCharacterIndex() => int',
    sciProto => 'SCI_GETLINECHARACTERINDEX => int',
};

=item allocateLineCharacterIndex

    editor->allocateLineCharacterIndex($lineCharacterIndex);

Request line character index be created or its use count increased.

Use $lineCharacterIndex from L<%lineCharacterIndex|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%lineCharacterIndex>.

See Scintilla documentation for  L<SCI_ALLOCATELINECHARACTERINDEX|https://www.scintilla.org/ScintillaDoc.html#SCI_ALLOCATELINECHARACTERINDEX>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_ALLOCATELINECHARACTERINDEX} = {
    subProto => 'allocateLineCharacterIndex(lineCharacterIndex)',
    sciProto => 'SCI_ALLOCATELINECHARACTERINDEX(int lineCharacterIndex)',
};

=item releaseLineCharacterIndex

    editor->releaseLineCharacterIndex($lineCharacterIndex);

Decrease use count of line character index and remove if 0.

Use $lineCharacterIndex from L<%lineCharacterIndex|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%lineCharacterIndex>.

See Scintilla documentation for  L<SCI_RELEASELINECHARACTERINDEX|https://www.scintilla.org/ScintillaDoc.html#SCI_RELEASELINECHARACTERINDEX>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_RELEASELINECHARACTERINDEX} = {
    subProto => 'releaseLineCharacterIndex(lineCharacterIndex)',
    sciProto => 'SCI_RELEASELINECHARACTERINDEX(int lineCharacterIndex)',
};

=item lineFromIndexPosition

    editor->lineFromIndexPosition($pos, $lineCharacterIndex);

Retrieve the document line containing a position measured in index units.

Use $lineCharacterIndex from L<%lineCharacterIndex|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%lineCharacterIndex>.

See Scintilla documentation for  L<SCI_LINEFROMINDEXPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEFROMINDEXPOSITION>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_LINEFROMINDEXPOSITION} = {
    subProto => 'lineFromIndexPosition(pos, lineCharacterIndex) => int',
    sciProto => 'SCI_LINEFROMINDEXPOSITION(position pos, int lineCharacterIndex) => line',
};

=item indexPositionFromLine

    editor->indexPositionFromLine($line, $lineCharacterIndex);

Retrieve the position measured in index units at the start of a document line.

Use $lineCharacterIndex from L<%lineCharacterIndex|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%lineCharacterIndex>.

See Scintilla documentation for  L<SCI_INDEXPOSITIONFROMLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDEXPOSITIONFROMLINE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_INDEXPOSITIONFROMLINE} = {
    subProto => 'indexPositionFromLine(line, lineCharacterIndex) => int',
    sciProto => 'SCI_INDEXPOSITIONFROMLINE(line line, int lineCharacterIndex) => position',
};

=back

=head2 Multiple Selection and Virtual Space

=over

=item setMultipleSelection

=item getMultipleSelection

    editor->setMultipleSelection($multipleSelection);
    editor->getMultipleSelection();

Set whether multiple selections can be made

See Scintilla documentation for  L<SCI_SETMULTIPLESELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMULTIPLESELECTION>

See Scintilla documentation for  L<SCI_GETMULTIPLESELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMULTIPLESELECTION>

=cut

$autogen{SCI_SETMULTIPLESELECTION} = {
    subProto => 'setMultipleSelection(multipleSelection)',
    sciProto => 'SCI_SETMULTIPLESELECTION(bool multipleSelection)',
};

$autogen{SCI_GETMULTIPLESELECTION} = {
    subProto => 'getMultipleSelection() => bool',
    sciProto => 'SCI_GETMULTIPLESELECTION => bool',
};

=item setAdditionalSelectionTyping

=item getAdditionalSelectionTyping

    editor->setAdditionalSelectionTyping($additionalSelectionTyping);
    editor->getAdditionalSelectionTyping();

Set whether typing can be performed into multiple selections

See Scintilla documentation for  L<SCI_SETADDITIONALSELECTIONTYPING|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALSELECTIONTYPING>

See Scintilla documentation for  L<SCI_GETADDITIONALSELECTIONTYPING|https://www.scintilla.org/ScintillaDoc.html#SCI_GETADDITIONALSELECTIONTYPING>

=cut

$autogen{SCI_SETADDITIONALSELECTIONTYPING} = {
    subProto => 'setAdditionalSelectionTyping(additionalSelectionTyping)',
    sciProto => 'SCI_SETADDITIONALSELECTIONTYPING(bool additionalSelectionTyping)',
};

$autogen{SCI_GETADDITIONALSELECTIONTYPING} = {
    subProto => 'getAdditionalSelectionTyping() => bool',
    sciProto => 'SCI_GETADDITIONALSELECTIONTYPING => bool',
};

=item setMultiPaste

=item getMultiPaste

    editor->setMultiPaste($multiPaste);
    editor->getMultiPaste();

Change the effect of pasting when there are multiple selections.

Use $multiPaste from L<%SC_MULTIPASTE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MULTIPASTE">.


See Scintilla documentation for  L<SCI_SETMULTIPASTE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMULTIPASTE>

See Scintilla documentation for  L<SCI_GETMULTIPASTE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMULTIPASTE>

=cut

$autogen{SCI_SETMULTIPASTE} = {
    subProto => 'setMultiPaste(multiPaste)',
    sciProto => 'SCI_SETMULTIPASTE(int multiPaste)',
};

$autogen{SCI_GETMULTIPASTE} = {
    subProto => 'getMultiPaste() => int',
    sciProto => 'SCI_GETMULTIPASTE => int',
};

=item setVirtualSpaceOptions

=item getVirtualSpaceOptions

    editor->setVirtualSpaceOptions($virtualSpaceOptions);
    editor->getVirtualSpaceOptions();

Returns the position at the end of the selection.

$virtualSpaceOptions from L<%SC_VIRTUALSPACE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_VIRTUALSPACE">

See Scintilla documentation for  L<SCI_SETVIRTUALSPACEOPTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETVIRTUALSPACEOPTIONS>

See Scintilla documentation for  L<SCI_GETVIRTUALSPACEOPTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETVIRTUALSPACEOPTIONS>

=cut

$autogen{SCI_SETVIRTUALSPACEOPTIONS} = {
    subProto => 'setVirtualSpaceOptions(virtualSpaceOptions)',
    sciProto => 'SCI_SETVIRTUALSPACEOPTIONS(int virtualSpaceOptions)',
};

$autogen{SCI_GETVIRTUALSPACEOPTIONS} = {
    subProto => 'getVirtualSpaceOptions() => int',
    sciProto => 'SCI_GETVIRTUALSPACEOPTIONS => int',
};

=item setRectangularSelectionModifier

=item getRectangularSelectionModifier

    editor->setRectangularSelectionModifier($modifier);
    editor->getRectangularSelectionModifier();

On GTK+, allow selecting the modifier key to use for mouse-based rectangular selection. Often the window manager requires Alt+Mouse Drag for moving windows. Valid values are SCMOD_CTRL(default), SCMOD_ALT, or SCMOD_SUPER.

See Scintilla documentation for  L<SCI_SETRECTANGULARSELECTIONMODIFIER|https://www.scintilla.org/ScintillaDoc.html#SCI_SETRECTANGULARSELECTIONMODIFIER>

See Scintilla documentation for  L<SCI_GETRECTANGULARSELECTIONMODIFIER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRECTANGULARSELECTIONMODIFIER>

=cut

$autogen{SCI_SETRECTANGULARSELECTIONMODIFIER} = {
    subProto => 'setRectangularSelectionModifier(modifier)',
    sciProto => 'SCI_SETRECTANGULARSELECTIONMODIFIER(int modifier)',
};

$autogen{SCI_GETRECTANGULARSELECTIONMODIFIER} = {
    subProto => 'getRectangularSelectionModifier() => int',
    sciProto => 'SCI_GETRECTANGULARSELECTIONMODIFIER => int',
};

=item getSelections

    editor->getSelections();

How many selections are there?

See Scintilla documentation for  L<SCI_GETSELECTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONS>

=cut

$autogen{SCI_GETSELECTIONS} = {
    subProto => 'getSelections() => int',
    sciProto => 'SCI_GETSELECTIONS => int',
};

=item getSelectionEmpty

    editor->getSelectionEmpty();

Is every selected range empty?

See Scintilla documentation for  L<SCI_GETSELECTIONEMPTY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONEMPTY>

=cut

$autogen{SCI_GETSELECTIONEMPTY} = {
    subProto => 'getSelectionEmpty() => bool',
    sciProto => 'SCI_GETSELECTIONEMPTY => bool',
};

=item clearSelections

    editor->clearSelections();

Clear selections to a single empty stream selection

See Scintilla documentation for  L<SCI_CLEARSELECTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARSELECTIONS>

=cut

$autogen{SCI_CLEARSELECTIONS} = {
    subProto => 'clearSelections()',
    sciProto => 'SCI_CLEARSELECTIONS',
};

=item setSelection

    editor->setSelection($caret, $anchor);

Set a simple selection

See Scintilla documentation for  L<SCI_SETSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTION>

=cut

$autogen{SCI_SETSELECTION} = {
    subProto => 'setSelection(caret, anchor) => int',
    sciProto => 'SCI_SETSELECTION(position caret, position anchor)',
};

=item addSelection

    editor->addSelection($caret, $anchor);

Add a selection

See Scintilla documentation for  L<SCI_ADDSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDSELECTION>

=cut

$autogen{SCI_ADDSELECTION} = {
    subProto => 'addSelection(caret, anchor) => int',
    sciProto => 'SCI_ADDSELECTION(position caret, position anchor)',
};

=item dropSelectionN

    editor->dropSelectionN($selection);

Drop one selection

See Scintilla documentation for  L<SCI_DROPSELECTIONN|https://www.scintilla.org/ScintillaDoc.html#SCI_DROPSELECTIONN>

=cut

$autogen{SCI_DROPSELECTIONN} = {
    subProto => 'dropSelectionN(selection)',
    sciProto => 'SCI_DROPSELECTIONN(int selection)',
};

=item setMainSelection

=item getMainSelection

    editor->setMainSelection($selection);
    editor->getMainSelection();

Set the main selection

See Scintilla documentation for  L<SCI_SETMAINSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMAINSELECTION>

See Scintilla documentation for  L<SCI_GETMAINSELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMAINSELECTION>

=cut

$autogen{SCI_SETMAINSELECTION} = {
    subProto => 'setMainSelection(selection)',
    sciProto => 'SCI_SETMAINSELECTION(int selection)',
};

$autogen{SCI_GETMAINSELECTION} = {
    subProto => 'getMainSelection() => int',
    sciProto => 'SCI_GETMAINSELECTION => int',
};

=item setSelectionNCaret

=item getSelectionNCaret

    editor->setSelectionNCaret($selection, $pos);
    editor->getSelectionNCaret($selection);

Which selection is the main selection

See Scintilla documentation for  L<SCI_SETSELECTIONNCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNCARET>

See Scintilla documentation for  L<SCI_GETSELECTIONNCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNCARET>

=cut

$autogen{SCI_SETSELECTIONNCARET} = {
    subProto => 'setSelectionNCaret(selection, pos)',
    sciProto => 'SCI_SETSELECTIONNCARET(int selection, position caret)',
};

$autogen{SCI_GETSELECTIONNCARET} = {
    subProto => 'getSelectionNCaret(selection) => int',
    sciProto => 'SCI_GETSELECTIONNCARET(int selection) => position',
};

=item setSelectionNCaretVirtualSpace

=item getSelectionNCaretVirtualSpace

    editor->setSelectionNCaretVirtualSpace($selection, $space);
    editor->getSelectionNCaretVirtualSpace($selection);

Which selection is the main selection

See Scintilla documentation for  L<SCI_SETSELECTIONNCARETVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNCARETVIRTUALSPACE>

See Scintilla documentation for  L<SCI_GETSELECTIONNCARETVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNCARETVIRTUALSPACE>


=cut

$autogen{SCI_SETSELECTIONNCARETVIRTUALSPACE} = {
    subProto => 'setSelectionNCaretVirtualSpace(selection, space)',
    sciProto => 'SCI_SETSELECTIONNCARETVIRTUALSPACE(int selection, position space)',
};

$autogen{SCI_GETSELECTIONNCARETVIRTUALSPACE} = {
    subProto => 'getSelectionNCaretVirtualSpace(selection) => int',
    sciProto => 'SCI_GETSELECTIONNCARETVIRTUALSPACE(int selection) => position',
};

=item setSelectionNAnchor

=item getSelectionNAnchor

    editor->setSelectionNAnchor($selection, $posAnchor);
    editor->getSelectionNAnchor($selection);

Which selection is the main selection

See Scintilla documentation for  L<SCI_SETSELECTIONNANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNANCHOR>

See Scintilla documentation for  L<SCI_GETSELECTIONNANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNANCHOR>

=cut

$autogen{SCI_SETSELECTIONNANCHOR} = {
    subProto => 'setSelectionNAnchor(selection, posAnchor)',
    sciProto => 'SCI_SETSELECTIONNANCHOR(int selection, position anchor)',
};

$autogen{SCI_GETSELECTIONNANCHOR} = {
    subProto => 'getSelectionNAnchor(selection) => int',
    sciProto => 'SCI_GETSELECTIONNANCHOR(int selection) => position',
};

=item setSelectionNAnchorVirtualSpace

=item getSelectionNAnchorVirtualSpace

    editor->setSelectionNAnchorVirtualSpace($selection, $space);
    editor->getSelectionNAnchorVirtualSpace($selection);

Which selection is the main selection

See Scintilla documentation for  L<SCI_SETSELECTIONNANCHORVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNANCHORVIRTUALSPACE>

See Scintilla documentation for  L<SCI_GETSELECTIONNANCHORVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNANCHORVIRTUALSPACE>

=cut

$autogen{SCI_SETSELECTIONNANCHORVIRTUALSPACE} = {
    subProto => 'setSelectionNAnchorVirtualSpace(selection, space)',
    sciProto => 'SCI_SETSELECTIONNANCHORVIRTUALSPACE(int selection, position space)',
};

$autogen{SCI_GETSELECTIONNANCHORVIRTUALSPACE} = {
    subProto => 'getSelectionNAnchorVirtualSpace(selection) => int',
    sciProto => 'SCI_GETSELECTIONNANCHORVIRTUALSPACE(int selection) => position',
};

=item setSelectionNStart

=item getSelectionNStart

    editor->setSelectionNStart($selection, $pos);
    editor->getSelectionNStart($selection);

Sets the position that starts the selection - this becomes the anchor.

See Scintilla documentation for  L<SCI_SETSELECTIONNSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNSTART>

See Scintilla documentation for  L<SCI_GETSELECTIONNSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNSTART>

=cut

$autogen{SCI_SETSELECTIONNSTART} = {
    subProto => 'setSelectionNStart(selection, pos)',
    sciProto => 'SCI_SETSELECTIONNSTART(int selection, position anchor)',
};

$autogen{SCI_GETSELECTIONNSTART} = {
    subProto => 'getSelectionNStart(selection) => int',
    sciProto => 'SCI_GETSELECTIONNSTART(int selection) => position',
};

=item setSelectionNEnd

=item getSelectionNEnd

    editor->setSelectionNEnd($selection, $pos);
    editor->getSelectionNEnd($selection);

Sets the position that ends the selection - this becomes the currentPosition.

See Scintilla documentation for  L<SCI_SETSELECTIONNEND|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELECTIONNEND>

See Scintilla documentation for  L<SCI_GETSELECTIONNEND|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELECTIONNEND>

=cut

$autogen{SCI_SETSELECTIONNEND} = {
    subProto => 'setSelectionNEnd(selection, pos)',
    sciProto => 'SCI_SETSELECTIONNEND(int selection, position caret)',
};

$autogen{SCI_GETSELECTIONNEND} = {
    subProto => 'getSelectionNEnd(selection) => int',
    sciProto => 'SCI_GETSELECTIONNEND(int selection) => position',
};

=item setRectangularSelectionCaret

=item getRectangularSelectionCaret

    editor->setRectangularSelectionCaret($pos);
    editor->getRectangularSelectionCaret();

Returns the position at the end of the selection.

See Scintilla documentation for  L<SCI_SETRECTANGULARSELECTIONCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_SETRECTANGULARSELECTIONCARET>

See Scintilla documentation for  L<SCI_GETRECTANGULARSELECTIONCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRECTANGULARSELECTIONCARET>

=cut

$autogen{SCI_SETRECTANGULARSELECTIONCARET} = {
    subProto => 'setRectangularSelectionCaret(pos)',
    sciProto => 'SCI_SETRECTANGULARSELECTIONCARET(position caret)',
};

$autogen{SCI_GETRECTANGULARSELECTIONCARET} = {
    subProto => 'getRectangularSelectionCaret() => int',
    sciProto => 'SCI_GETRECTANGULARSELECTIONCARET => position',
};

=item setRectangularSelectionCaretVirtualSpace

=item getRectangularSelectionCaretVirtualSpace

    editor->setRectangularSelectionCaretVirtualSpace($space);
    editor->getRectangularSelectionCaretVirtualSpace();

Returns the position at the end of the selection.

See Scintilla documentation for  L<SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE>

See Scintilla documentation for  L<SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE>

=cut

$autogen{SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE} = {
    subProto => 'setRectangularSelectionCaretVirtualSpace(space)',
    sciProto => 'SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE(position space)',
};

$autogen{SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE} = {
    subProto => 'getRectangularSelectionCaretVirtualSpace() => int',
    sciProto => 'SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE => position',
};

=item setRectangularSelectionAnchor

=item getRectangularSelectionAnchor

    editor->setRectangularSelectionAnchor($posAnchor);
    editor->getRectangularSelectionAnchor();

Returns the position at the end of the selection.

See Scintilla documentation for  L<SCI_SETRECTANGULARSELECTIONANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETRECTANGULARSELECTIONANCHOR>

See Scintilla documentation for  L<SCI_GETRECTANGULARSELECTIONANCHOR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRECTANGULARSELECTIONANCHOR>

=cut

$autogen{SCI_SETRECTANGULARSELECTIONANCHOR} = {
    subProto => 'setRectangularSelectionAnchor(posAnchor)',
    sciProto => 'SCI_SETRECTANGULARSELECTIONANCHOR(position anchor)',
};

$autogen{SCI_GETRECTANGULARSELECTIONANCHOR} = {
    subProto => 'getRectangularSelectionAnchor() => int',
    sciProto => 'SCI_GETRECTANGULARSELECTIONANCHOR => position',
};

=item setRectangularSelectionAnchorVirtualSpace

    editor->setRectangularSelectionAnchorVirtualSpace($space);

Returns the position at the end of the selection.

See Scintilla documentation for  L<SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE>

=cut

$autogen{SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE} = {
    subProto => 'setRectangularSelectionAnchorVirtualSpace(space)',
    sciProto => 'SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE(position space)',
};

=item getRectangularSelectionAnchorVirtualSpace

    editor->getRectangularSelectionAnchorVirtualSpace();

Returns the position at the end of the selection.

See Scintilla documentation for  L<SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE>

=cut

$autogen{SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE} = {
    subProto => 'getRectangularSelectionAnchorVirtualSpace() => int',
    sciProto => 'SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE => position',
};

=item setAdditionalSelAlpha

=item getAdditionalSelAlpha

    editor->setAdditionalSelAlpha($alpha);
    editor->getAdditionalSelAlpha();

Set the alpha of the selection.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_SETADDITIONALSELALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALSELALPHA>

See Scintilla documentation for  L<SCI_GETADDITIONALSELALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_GETADDITIONALSELALPHA>

=cut

$autogen{SCI_SETADDITIONALSELALPHA} = {
    subProto => 'setAdditionalSelAlpha(alpha)',
    sciProto => 'SCI_SETADDITIONALSELALPHA(alpha alpha)',
};

$autogen{SCI_GETADDITIONALSELALPHA} = {
    subProto => 'getAdditionalSelAlpha() => int',
    sciProto => 'SCI_GETADDITIONALSELALPHA => int',
};

=item setAdditionalSelFore

    editor->setAdditionalSelFore($fore);

Set the foreground colour of additional selections. Must have previously called SetSelFore with non-zero first argument for this to have an effect.

See Scintilla documentation for  L<SCI_SETADDITIONALSELFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALSELFORE>

=cut

$autogen{SCI_SETADDITIONALSELFORE} = {
    subProto => 'setAdditionalSelFore(fore)',
    sciProto => 'SCI_SETADDITIONALSELFORE(colour fore)',
};

=item setAdditionalSelBack

    editor->setAdditionalSelBack($back);

Set the background colour of additional selections. Must have previously called SetSelBack with non-zero first argument for this to have an effect.

See Scintilla documentation for  L<SCI_SETADDITIONALSELBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALSELBACK>

=cut

$autogen{SCI_SETADDITIONALSELBACK} = {
    subProto => 'setAdditionalSelBack(back)',
    sciProto => 'SCI_SETADDITIONALSELBACK(colour back)',
};

=item setAdditionalCaretFore

=item getAdditionalCaretFore

    editor->setAdditionalCaretFore($fore);
    editor->getAdditionalCaretFore();

Set the foreground colour of additional carets.

See Scintilla documentation for  L<SCI_SETADDITIONALCARETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALCARETFORE>

See Scintilla documentation for  L<SCI_GETADDITIONALCARETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETADDITIONALCARETFORE>

=cut

$autogen{SCI_SETADDITIONALCARETFORE} = {
    subProto => 'setAdditionalCaretFore(fore)',
    sciProto => 'SCI_SETADDITIONALCARETFORE(colour fore)',
};

$autogen{SCI_GETADDITIONALCARETFORE} = {
    subProto => 'getAdditionalCaretFore() => tuple',
    sciProto => 'SCI_GETADDITIONALCARETFORE => colour',
};

=item setAdditionalCaretsBlink

=item getAdditionalCaretsBlink

    editor->setAdditionalCaretsBlink($additionalCaretsBlink);
    editor->getAdditionalCaretsBlink();

Set whether additional carets will blink

See Scintilla documentation for  L<SCI_SETADDITIONALCARETSBLINK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALCARETSBLINK>

See Scintilla documentation for  L<SCI_GETADDITIONALCARETSBLINK|https://www.scintilla.org/ScintillaDoc.html#SCI_GETADDITIONALCARETSBLINK>

=cut

$autogen{SCI_SETADDITIONALCARETSBLINK} = {
    subProto => 'setAdditionalCaretsBlink(additionalCaretsBlink)',
    sciProto => 'SCI_SETADDITIONALCARETSBLINK(bool additionalCaretsBlink)',
};

$autogen{SCI_GETADDITIONALCARETSBLINK} = {
    subProto => 'getAdditionalCaretsBlink() => bool',
    sciProto => 'SCI_GETADDITIONALCARETSBLINK => bool',
};

=item setAdditionalCaretsVisible

=item getAdditionalCaretsVisible

    editor->setAdditionalCaretsVisible($additionalCaretsBlink);
    editor->getAdditionalCaretsVisible();

Set whether additional carets are visible

See Scintilla documentation for  L<SCI_SETADDITIONALCARETSVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETADDITIONALCARETSVISIBLE>

See Scintilla documentation for  L<SCI_GETADDITIONALCARETSVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETADDITIONALCARETSVISIBLE>

=cut

$autogen{SCI_SETADDITIONALCARETSVISIBLE} = {
    subProto => 'setAdditionalCaretsVisible(additionalCaretsBlink)',
    sciProto => 'SCI_SETADDITIONALCARETSVISIBLE(bool additionalCaretsVisible)',
};

$autogen{SCI_GETADDITIONALCARETSVISIBLE} = {
    subProto => 'getAdditionalCaretsVisible() => bool',
    sciProto => 'SCI_GETADDITIONALCARETSVISIBLE => bool',
};

=item swapMainAnchorCaret

    editor->swapMainAnchorCaret();

Swap that caret and anchor of the main selection.

See Scintilla documentation for  L<SCI_SWAPMAINANCHORCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_SWAPMAINANCHORCARET>

=cut

$autogen{SCI_SWAPMAINANCHORCARET} = {
    subProto => 'swapMainAnchorCaret()',
    sciProto => 'SCI_SWAPMAINANCHORCARET',
};

=item rotateSelection

    editor->rotateSelection();

Set the main selection to the next selection.

See Scintilla documentation for  L<SCI_ROTATESELECTION|https://www.scintilla.org/ScintillaDoc.html#SCI_ROTATESELECTION>

=cut

$autogen{SCI_ROTATESELECTION} = {
    subProto => 'rotateSelection()',
    sciProto => 'SCI_ROTATESELECTION',
};

=item multipleSelectAddNext

    editor->multipleSelectAddNext;

Adds the next occurrence of the main selection within the target to the multi-selection set.

See Scintilla documentation for  L<SCI_MULTIPLESELECTADDNEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_MULTIPLESELECTADDNEXT>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_MULTIPLESELECTADDNEXT} = {
    subProto => 'multipleSelectAddNext',
    sciProto => 'SCI_MULTIPLESELECTADDNEXT',
};

=item multipleSelectAddEach

    editor->multipleSelectAddEach;

Adds multiple occurrences of the main selection within the target to the multi-selection set.

See Scintilla documentation for  L<SCI_MULTIPLESELECTADDEACH|https://www.scintilla.org/ScintillaDoc.html#SCI_MULTIPLESELECTADDEACH>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_MULTIPLESELECTADDEACH} = {
    subProto => 'multipleSelectAddEach',
    sciProto => 'SCI_MULTIPLESELECTADDEACH',
};

=back

=head2 Scrolling and automatic scrolling




=over

=item setFirstVisibleLine

=item getFirstVisibleLine

    editor->setFirstVisibleLine($lineDisplay);
    editor->getFirstVisibleLine();

Scroll so that a display line is at the top of the display.

See Scintilla documentation for  L<SCI_SETFIRSTVISIBLELINE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFIRSTVISIBLELINE>

See Scintilla documentation for  L<SCI_GETFIRSTVISIBLELINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFIRSTVISIBLELINE>

=cut

$autogen{SCI_SETFIRSTVISIBLELINE} = {
    subProto => 'setFirstVisibleLine(lineDisplay)',
    sciProto => 'SCI_SETFIRSTVISIBLELINE(line displayLine)',
};

$autogen{SCI_GETFIRSTVISIBLELINE} = {
    subProto => 'getFirstVisibleLine() => int',
    sciProto => 'SCI_GETFIRSTVISIBLELINE => line',
};

=item setXOffset

=item getXOffset

    editor->setXOffset($newOffset);
    editor->getXOffset();

Get and Set the xOffset (ie, horizontal scroll position).

See Scintilla documentation for  L<SCI_SETXOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_SETXOFFSET>

See Scintilla documentation for  L<SCI_GETXOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_GETXOFFSET>

=cut

$autogen{SCI_SETXOFFSET} = {
    subProto => 'setXOffset(newOffset)',
    sciProto => 'SCI_SETXOFFSET(int xOffset)',
};

$autogen{SCI_GETXOFFSET} = {
    subProto => 'getXOffset() => int',
    sciProto => 'SCI_GETXOFFSET => int',
};

=item lineScroll

    editor->lineScroll($columns, $lines);

Scroll horizontally and vertically.

See Scintilla documentation for  L<SCI_LINESCROLL|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESCROLL>

=cut

$autogen{SCI_LINESCROLL} = {
    subProto => 'lineScroll(columns, lines)',
    sciProto => 'SCI_LINESCROLL(position columns, line lines)',
};

=item scrollCaret

    editor->scrollCaret();

Ensure the caret is visible.

See Scintilla documentation for  L<SCI_SCROLLCARET|https://www.scintilla.org/ScintillaDoc.html#SCI_SCROLLCARET>

=cut

$autogen{SCI_SCROLLCARET} = {
    subProto => 'scrollCaret()',
    sciProto => 'SCI_SCROLLCARET',
};

=item scrollRange

    editor->scrollRange($secondary, $primary);

Scroll the argument positions and the range between them into view giving priority to the primary position then the secondary position. This may be used to make a search match visible.

See Scintilla documentation for  L<SCI_SCROLLRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_SCROLLRANGE>

=cut

$autogen{SCI_SCROLLRANGE} = {
    subProto => 'scrollRange(secondary, primary)',
    sciProto => 'SCI_SCROLLRANGE(position secondary, position primary)',
};

=item setXCaretPolicy

    editor->setXCaretPolicy($caretPolicy, $caretSlop);

Set the way the caret is kept visible when going sideways. The exclusion zone ($caretSlop) is given in pixels.

C<$caretPolicy> a combination of L<%SC_CARETPOLICY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CARETPOLICY"> values.

See Scintilla documentation for  L<SCI_SETXCARETPOLICY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETXCARETPOLICY>

=cut

$autogen{SCI_SETXCARETPOLICY} = {
    subProto => 'setXCaretPolicy(caretPolicy, caretSlop)',
    sciProto => 'SCI_SETXCARETPOLICY(int caretPolicy, int caretSlop)',
};

=item setYCaretPolicy

    editor->setYCaretPolicy($caretPolicy, $caretSlop);

Set the way the line the caret is on is kept visible. The exclusion zone ($caretSlop) is given in lines.

C<$caretPolicy> from L<%SC_CARETPOLICY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CARETPOLICY">.

See Scintilla documentation for  L<SCI_SETYCARETPOLICY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETYCARETPOLICY>

=cut

$autogen{SCI_SETYCARETPOLICY} = {
    subProto => 'setYCaretPolicy(caretPolicy, caretSlop)',
    sciProto => 'SCI_SETYCARETPOLICY(int caretPolicy, int caretSlop)',
};

=item setVisiblePolicy

    editor->setVisiblePolicy($visiblePolicy, $visibleSlop);

Set the way the display area is determined when a particular line is to be moved to by Find, FindNext, GotoLine, etc.  The exclusion zone ($visibleSlop) is given in lines.

Use $visiblePolicy from L<%SC_VISIBLE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_VISIBLE">.


See Scintilla documentation for  L<SCI_SETVISIBLEPOLICY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETVISIBLEPOLICY>

=cut

$autogen{SCI_SETVISIBLEPOLICY} = {
    subProto => 'setVisiblePolicy(visiblePolicy, visibleSlop)',
    sciProto => 'SCI_SETVISIBLEPOLICY(int visiblePolicy, int visibleSlop)',
};

=item setHScrollBar

=item getHScrollBar

    editor->setHScrollBar($show);
    editor->getHScrollBar();

Show or hide the horizontal scroll bar.

See Scintilla documentation for  L<SCI_SETHSCROLLBAR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHSCROLLBAR>

See Scintilla documentation for  L<SCI_GETHSCROLLBAR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHSCROLLBAR>

=cut

$autogen{SCI_SETHSCROLLBAR} = {
    subProto => 'setHScrollBar(show)',
    sciProto => 'SCI_SETHSCROLLBAR(bool visible)',
};

$autogen{SCI_GETHSCROLLBAR} = {
    subProto => 'getHScrollBar() => bool',
    sciProto => 'SCI_GETHSCROLLBAR => bool',
};

=item setVScrollBar

=item getVScrollBar

    editor->setVScrollBar($show);
    editor->getVScrollBar();

Show or hide the vertical scroll bar.

See Scintilla documentation for  L<SCI_SETVSCROLLBAR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETVSCROLLBAR>

See Scintilla documentation for  L<SCI_GETVSCROLLBAR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETVSCROLLBAR>

=cut

$autogen{SCI_SETVSCROLLBAR} = {
    subProto => 'setVScrollBar(show)',
    sciProto => 'SCI_SETVSCROLLBAR(bool visible)',
};

$autogen{SCI_GETVSCROLLBAR} = {
    subProto => 'getVScrollBar() => bool',
    sciProto => 'SCI_GETVSCROLLBAR => bool',
};

=item setScrollWidth

=item getScrollWidth

    editor->setScrollWidth($pixelWidth);
    editor->getScrollWidth();

Sets the document width assumed for scrolling.

See Scintilla documentation for  L<SCI_SETSCROLLWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSCROLLWIDTH>

See Scintilla documentation for  L<SCI_GETSCROLLWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSCROLLWIDTH>

=cut

$autogen{SCI_SETSCROLLWIDTH} = {
    subProto => 'setScrollWidth(pixelWidth)',
    sciProto => 'SCI_SETSCROLLWIDTH(int pixelWidth)',
};

$autogen{SCI_GETSCROLLWIDTH} = {
    subProto => 'getScrollWidth() => int',
    sciProto => 'SCI_GETSCROLLWIDTH => int',
};

=item setScrollWidthTracking

=item getScrollWidthTracking

    editor->setScrollWidthTracking($tracking);
    editor->getScrollWidthTracking();

Sets whether the maximum width line displayed is used to set scroll width.

See Scintilla documentation for  L<SCI_SETSCROLLWIDTHTRACKING|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSCROLLWIDTHTRACKING>

See Scintilla documentation for  L<SCI_GETSCROLLWIDTHTRACKING|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSCROLLWIDTHTRACKING>

=cut

$autogen{SCI_SETSCROLLWIDTHTRACKING} = {
    subProto => 'setScrollWidthTracking(tracking)',
    sciProto => 'SCI_SETSCROLLWIDTHTRACKING(bool tracking)',
};

$autogen{SCI_GETSCROLLWIDTHTRACKING} = {
    subProto => 'getScrollWidthTracking() => bool',
    sciProto => 'SCI_GETSCROLLWIDTHTRACKING => bool',
};

=item setEndAtLastLine

=item getEndAtLastLine

    editor->setEndAtLastLine($endAtLastLine);
    editor->getEndAtLastLine();

Sets the scroll range so that maximum scroll position has the last line at the bottom of the view (default). Setting this to false allows scrolling one page below the last line.

See Scintilla documentation for  L<SCI_SETENDATLASTLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETENDATLASTLINE>

See Scintilla documentation for  L<SCI_GETENDATLASTLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETENDATLASTLINE>

=cut

$autogen{SCI_SETENDATLASTLINE} = {
    subProto => 'setEndAtLastLine(endAtLastLine)',
    sciProto => 'SCI_SETENDATLASTLINE(bool endAtLastLine)',
};

$autogen{SCI_GETENDATLASTLINE} = {
    subProto => 'getEndAtLastLine() => bool',
    sciProto => 'SCI_GETENDATLASTLINE => bool',
};

=back

=head2 White space




=over

=item setViewWS

=item getViewWS

    editor->setViewWS($viewWS);
    editor->getViewWS();

Make white space characters invisible, always visible or visible outside indentation.

$viewWS from L<%SC_WHITESPACE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WHITESPACE">

See Scintilla documentation for  L<SCI_SETVIEWWS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETVIEWWS>

See Scintilla documentation for  L<SCI_GETVIEWWS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETVIEWWS>

=cut

$autogen{SCI_SETVIEWWS} = {
    subProto => 'setViewWS(viewWS)',
    sciProto => 'SCI_SETVIEWWS(int viewWS)',
};

$autogen{SCI_GETVIEWWS} = {
    subProto => 'getViewWS() => int',
    sciProto => 'SCI_GETVIEWWS => int',
};

=item setWhitespaceFore

    editor->setWhitespaceFore($useSetting, $fore);

Set the foreground colour of all whitespace and whether to use this setting.

See Scintilla documentation for  L<SCI_SETWHITESPACEFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWHITESPACEFORE>

=cut

$autogen{SCI_SETWHITESPACEFORE} = {
    subProto => 'setWhitespaceFore(useSetting, fore)',
    sciProto => 'SCI_SETWHITESPACEFORE(bool useSetting, colour fore)',
};

=item setWhitespaceBack

    editor->setWhitespaceBack($useSetting, $back);

Set the background colour of all whitespace and whether to use this setting.

See Scintilla documentation for  L<SCI_SETWHITESPACEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWHITESPACEBACK>

=cut

$autogen{SCI_SETWHITESPACEBACK} = {
    subProto => 'setWhitespaceBack(useSetting, back)',
    sciProto => 'SCI_SETWHITESPACEBACK(bool useSetting, colour back)',
};

=item setWhitespaceSize

=item getWhitespaceSize

    editor->setWhitespaceSize($size);
    editor->getWhitespaceSize();

Set the size of the dots used to mark space characters.

See Scintilla documentation for  L<SCI_SETWHITESPACESIZE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWHITESPACESIZE>

See Scintilla documentation for  L<SCI_GETWHITESPACESIZE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWHITESPACESIZE>

=cut

$autogen{SCI_SETWHITESPACESIZE} = {
    subProto => 'setWhitespaceSize(size)',
    sciProto => 'SCI_SETWHITESPACESIZE(int size)',
};

$autogen{SCI_GETWHITESPACESIZE} = {
    subProto => 'getWhitespaceSize() => int',
    sciProto => 'SCI_GETWHITESPACESIZE => int',
};

=item setTabDrawMode

=item getTabDrawMode

    editor->setTabDrawMode($tabDrawMode);
    editor->getTabDrawMode;

Set how tabs are drawn when whitespace is visible.

Use $tabDrawMode from L<%SC_TABDRAW|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_TABDRAW">.

See Scintilla documentation for  L<SCI_SETTABDRAWMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTABDRAWMODE>

See Scintilla documentation for  L<SCI_GETTABDRAWMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTABDRAWMODE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETTABDRAWMODE} = {
    subProto => 'setTabDrawMode(tabDrawMode)',
    sciProto => 'SCI_SETTABDRAWMODE(int tabDrawMode)',
};

$autogen{SCI_GETTABDRAWMODE} = {
    subProto => 'getTabDrawMode',
    sciProto => 'SCI_GETTABDRAWMODE => int',
};

=item setExtraAscent

=item getExtraAscent

    editor->setExtraAscent($extraAscent);
    editor->getExtraAscent();

Set extra ascent for each line

See Scintilla documentation for  L<SCI_SETEXTRAASCENT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEXTRAASCENT>

See Scintilla documentation for  L<SCI_GETEXTRAASCENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEXTRAASCENT>

=cut

$autogen{SCI_SETEXTRAASCENT} = {
    subProto => 'setExtraAscent(extraAscent)',
    sciProto => 'SCI_SETEXTRAASCENT(int extraAscent)',
};

$autogen{SCI_GETEXTRAASCENT} = {
    subProto => 'getExtraAscent() => int',
    sciProto => 'SCI_GETEXTRAASCENT => int',
};

=item setExtraDescent

=item getExtraDescent

    editor->setExtraDescent($extraDescent);
    editor->getExtraDescent();

Set extra descent for each line

See Scintilla documentation for  L<SCI_SETEXTRADESCENT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEXTRADESCENT>

See Scintilla documentation for  L<SCI_GETEXTRADESCENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEXTRADESCENT>

=cut

$autogen{SCI_SETEXTRADESCENT} = {
    subProto => 'setExtraDescent(extraDescent)',
    sciProto => 'SCI_SETEXTRADESCENT(int extraDescent)',
};

$autogen{SCI_GETEXTRADESCENT} = {
    subProto => 'getExtraDescent() => int',
    sciProto => 'SCI_GETEXTRADESCENT => int',
};

=back

=head2 Cursor




=over

=item setCursor

=item getCursor

    editor->setCursor($cursorType);
    editor->getCursor();

Sets the cursor behavior.

Use $cursor from L<%SC_CURSOR|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CURSOR">, either C<$SC_CURSOR{SC_CURSORNORMAL}> or C<$SC_CURSOR{SC_CURSORWAIT}>.


See Scintilla documentation for  L<SCI_SETCURSOR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCURSOR>

See Scintilla documentation for  L<SCI_GETCURSOR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCURSOR>

=cut

$autogen{SCI_SETCURSOR} = {
    subProto => 'setCursor(cursorType)',
    sciProto => 'SCI_SETCURSOR(int cursorType)',
};

$autogen{SCI_GETCURSOR} = {
    subProto => 'getCursor() => int',
    sciProto => 'SCI_GETCURSOR => int',
};

=back

=head2 Mouse capture




=over

=item setMouseDownCaptures

=item getMouseDownCaptures

    editor->setMouseDownCaptures($captures);
    editor->getMouseDownCaptures();

Set whether the mouse is captured when its button is pressed.

See Scintilla documentation for  L<SCI_SETMOUSEDOWNCAPTURES|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMOUSEDOWNCAPTURES>

See Scintilla documentation for  L<SCI_GETMOUSEDOWNCAPTURES|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMOUSEDOWNCAPTURES>

=cut

$autogen{SCI_SETMOUSEDOWNCAPTURES} = {
    subProto => 'setMouseDownCaptures(captures)',
    sciProto => 'SCI_SETMOUSEDOWNCAPTURES(bool captures)',
};

$autogen{SCI_GETMOUSEDOWNCAPTURES} = {
    subProto => 'getMouseDownCaptures() => bool',
    sciProto => 'SCI_GETMOUSEDOWNCAPTURES => bool',
};

=item setMouseWheelCaptures

=item getMouseWheelCaptures

    editor->setMouseWheelCaptures($captures);
    editor->getMouseWheelCaptures;

Sets whether or not the Scintilla instance will handle all WM_MOUSEWHEEL messages if it has the focus, even if the mouse is nowhere near the Scintilla window.

Defaults to on; set C<$captures> to a false value in order to require the mouse cursor to be over the Scintilla window to process those messages.

See Scintilla documentation for  L<SCI_SETMOUSEWHEELCAPTURES|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMOUSEWHEELCAPTURES>

See Scintilla documentation for  L<SCI_GETMOUSEWHEELCAPTURES|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMOUSEWHEELCAPTURES>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETMOUSEWHEELCAPTURES} = {
    subProto => 'setMouseWheelCaptures(captures)',
    sciProto => 'SCI_SETMOUSEWHEELCAPTURES(bool captures)',
};

$autogen{SCI_GETMOUSEWHEELCAPTURES} = {
    subProto => 'getMouseWheelCaptures',
    sciProto => 'SCI_GETMOUSEWHEELCAPTURES => bool',
};

=back

=head2 Line endings




=over

=item setEOLMode

=item getEOLMode

    editor->setEOLMode($eolMode);
    editor->getEOLMode();

Set the current end of line mode.

Use $eolMode from L<%SC_EOL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_EOL">.

See also L</getEOLString()> method for getting the correct string.

See Scintilla documentation for  L<SCI_SETEOLMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEOLMODE>

See Scintilla documentation for  L<SCI_GETEOLMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEOLMODE>

=cut

$autogen{SCI_SETEOLMODE} = {
    subProto => 'setEOLMode(eolMode)',
    sciProto => 'SCI_SETEOLMODE(int eolMode)',
};

$autogen{SCI_GETEOLMODE} = {
    subProto => 'getEOLMode() => int',
    sciProto => 'SCI_GETEOLMODE => int',
};

=item convertEOLs

    editor->convertEOLs($eolMode);

Convert all line endings in the document to one mode.

Use $eolMode from L<%SC_EOL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_EOL">.

See Scintilla documentation for  L<SCI_CONVERTEOLS|https://www.scintilla.org/ScintillaDoc.html#SCI_CONVERTEOLS>

=cut

$autogen{SCI_CONVERTEOLS} = {
    subProto => 'convertEOLs(eolMode)',
    sciProto => 'SCI_CONVERTEOLS(int eolMode)',
};

=item setViewEOL

=item getViewEOL

    editor->setViewEOL($visible);
    editor->getViewEOL();

Make the end of line characters visible or invisible.

See Scintilla documentation for  L<SCI_SETVIEWEOL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETVIEWEOL>

See Scintilla documentation for  L<SCI_GETVIEWEOL|https://www.scintilla.org/ScintillaDoc.html#SCI_GETVIEWEOL>

=cut

$autogen{SCI_SETVIEWEOL} = {
    subProto => 'setViewEOL(visible)',
    sciProto => 'SCI_SETVIEWEOL(bool visible)',
};

$autogen{SCI_GETVIEWEOL} = {
    subProto => 'getViewEOL() => bool',
    sciProto => 'SCI_GETVIEWEOL => bool',
};

=item getLineEndTypesSupported

    editor->getLineEndTypesSupported();

Returns whether line endings beyond the standard (LF, CR, and CRLF) are supported by the lexer.  (Unicode has other line-endings defined, so this will tell you if those line endings are supported or not.)

Returns values from L<%SC_EOLSUPPORT|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_EOLSUPPORT">,
but effectively, a true value means Unicode's extra line-endings are supported.

See Scintilla documentation for  L<SCI_GETLINEENDTYPESSUPPORTED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEENDTYPESSUPPORTED>

=cut

$autogen{SCI_GETLINEENDTYPESSUPPORTED} = {
    subProto => 'getLineEndTypesSupported() => int',
    sciProto => 'SCI_GETLINEENDTYPESSUPPORTED => int',
};

=item setLineEndTypesAllowed

=item getLineEndTypesAllowed

    editor->setLineEndTypesAllowed($lineEndBitSet);
    editor->getLineEndTypesAllowed();

Set the line end types that the application wants to use. May not be used if incompatible with lexer or encoding.

Use $lineEndBitSet from L<%SC_EOLSUPPORT|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_EOLSUPPORT">.


See Scintilla documentation for  L<SCI_SETLINEENDTYPESALLOWED|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLINEENDTYPESALLOWED>

See Scintilla documentation for  L<SCI_GETLINEENDTYPESALLOWED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEENDTYPESALLOWED>

=cut

$autogen{SCI_SETLINEENDTYPESALLOWED} = {
    subProto => 'setLineEndTypesAllowed(lineEndBitSet)',
    sciProto => 'SCI_SETLINEENDTYPESALLOWED(int lineEndBitSet)',
};

$autogen{SCI_GETLINEENDTYPESALLOWED} = {
    subProto => 'getLineEndTypesAllowed() => int',
    sciProto => 'SCI_GETLINEENDTYPESALLOWED => int',
};

=item getLineEndTypesActive

    editor->getLineEndTypesActive();

Get the line end types currently recognised. May be a subset of the allowed types due to lexer limitation.

See Scintilla documentation for  L<SCI_GETLINEENDTYPESACTIVE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEENDTYPESACTIVE>

=cut

$autogen{SCI_GETLINEENDTYPESACTIVE} = {
    subProto => 'getLineEndTypesActive() => int',
    sciProto => 'SCI_GETLINEENDTYPESACTIVE => int',
};

=back

=head2 Words




=over

=item wordStartPosition

    editor->wordStartPosition($pos, $onlyWordCharacters);

Get position of start of word.

See Scintilla documentation for  L<SCI_WORDSTARTPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDSTARTPOSITION>

=cut

$autogen{SCI_WORDSTARTPOSITION} = {
    subProto => 'wordStartPosition(pos, onlyWordCharacters) => int',
    sciProto => 'SCI_WORDSTARTPOSITION(position pos, bool onlyWordCharacters) => position',
};

=item wordEndPosition

    editor->wordEndPosition($pos, $onlyWordCharacters);

Get position of end of word.

See Scintilla documentation for  L<SCI_WORDENDPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDENDPOSITION>

=cut

$autogen{SCI_WORDENDPOSITION} = {
    subProto => 'wordEndPosition(pos, onlyWordCharacters) => int',
    sciProto => 'SCI_WORDENDPOSITION(position pos, bool onlyWordCharacters) => position',
};

=item isRangeWord

    editor->isRangeWord($start, $end);

Is the range defined by C<$start> .. C<$end> a word or set of words?  (It checks for word-boundary at the beginning
and ending of the range; if there are intermediate word boundaries, it will still return true.)

See Scintilla documentation for  L<SCI_ISRANGEWORD|https://www.scintilla.org/ScintillaDoc.html#SCI_ISRANGEWORD>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_ISRANGEWORD} = {
    subProto => 'isRangeWord(start, end)',
    sciProto => 'SCI_ISRANGEWORD(position start, position end) => bool',
};

=item setWordChars

=item getWordChars

    editor->setWordChars($characters);
    editor->getWordChars();

Set the set of characters making up words for when moving or selecting by word. First sets defaults like L<setCharsDefault()|/setCharsDefault>.

See Scintilla documentation for  L<SCI_SETWORDCHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWORDCHARS>

See Scintilla documentation for  L<SCI_GETWORDCHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWORDCHARS>

=cut

$autogen{SCI_SETWORDCHARS} = {
    subProto => 'setWordChars(characters)',
    sciProto => 'SCI_SETWORDCHARS(<unused>, const char *characters)',
};

$autogen{SCI_GETWORDCHARS} = {
    subProto => 'getWordChars() => str',
    sciProto => 'SCI_GETWORDCHARS(<unused>, char *characters) => int',
};

=item setWhitespaceChars

=item getWhitespaceChars

    editor->setWhitespaceChars($characters);
    editor->getWhitespaceChars();

Set the set of characters making up whitespace for when moving or selecting by word. Should be called after SetWordChars.

See Scintilla documentation for  L<SCI_SETWHITESPACECHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWHITESPACECHARS>

See Scintilla documentation for  L<SCI_GETWHITESPACECHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWHITESPACECHARS>

=cut

$autogen{SCI_SETWHITESPACECHARS} = {
    subProto => 'setWhitespaceChars(characters)',
    sciProto => 'SCI_SETWHITESPACECHARS(<unused>, const char *characters)',
};

$autogen{SCI_GETWHITESPACECHARS} = {
    subProto => 'getWhitespaceChars() => str',
    sciProto => 'SCI_GETWHITESPACECHARS(<unused>, char *characters) => int',
};

=item setPunctuationChars

=item getPunctuationChars

    editor->setPunctuationChars($characters);
    editor->getPunctuationChars();

Set the set of characters making up punctuation characters Should be called after SetWordChars.

See Scintilla documentation for  L<SCI_SETPUNCTUATIONCHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPUNCTUATIONCHARS>

See Scintilla documentation for  L<SCI_GETPUNCTUATIONCHARS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPUNCTUATIONCHARS>

=cut

$autogen{SCI_SETPUNCTUATIONCHARS} = {
    subProto => 'setPunctuationChars(characters)',
    sciProto => 'SCI_SETPUNCTUATIONCHARS(<unused>, const char *characters)',
};

$autogen{SCI_GETPUNCTUATIONCHARS} = {
    subProto => 'getPunctuationChars() => str',
    sciProto => 'SCI_GETPUNCTUATIONCHARS(<unused>, char *characters) => int',
};

=item setCharsDefault

    editor->setCharsDefault();

Reset the set of characters for whitespace and word characters to the defaults.

See Scintilla documentation for  L<SCI_SETCHARSDEFAULT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCHARSDEFAULT>

=cut

$autogen{SCI_SETCHARSDEFAULT} = {
    subProto => 'setCharsDefault()',
    sciProto => 'SCI_SETCHARSDEFAULT',
};

=item setCharacterCategoryOptimization

=item getCharacterCategoryOptimization

    editor->setCharacterCategoryOptimization($countCharacters);
    editor->getCharacterCategoryOptimization;

Optimize speed of character category features like determining whether a character is a space or number at the expense of memory. Mostly used for Unicode documents. The C<$countCharacters> parameter determines how many character starting from 0 are added to a look-up table with one byte used for each character. It is reasonable to cover the set of characters likely to be used in a document so 0x100 for simple Roman text, 0x1000 to cover most simple alphabets, 0x10000 to cover most of East Asian languages, and 0x110000 to cover all possible characters.

See Scintilla documentation for  L<SCI_SETCHARACTERCATEGORYOPTIMIZATION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCHARACTERCATEGORYOPTIMIZATION>

See Scintilla documentation for  L<SCI_GETCHARACTERCATEGORYOPTIMIZATION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCHARACTERCATEGORYOPTIMIZATION>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETCHARACTERCATEGORYOPTIMIZATION} = {
    subProto => 'setCharacterCategoryOptimization(countCharacters)',
    sciProto => 'SCI_SETCHARACTERCATEGORYOPTIMIZATION(int countCharacters)',
};


$autogen{SCI_GETCHARACTERCATEGORYOPTIMIZATION} = {
    subProto => 'getCharacterCategoryOptimization',
    sciProto => 'SCI_GETCHARACTERCATEGORYOPTIMIZATION => int',
};

=back

=head2 Styling




=over

=item getEndStyled

    editor->getEndStyled();

Retrieve the position of the last correctly styled character.

See Scintilla documentation for  L<SCI_GETENDSTYLED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETENDSTYLED>

=cut

$autogen{SCI_GETENDSTYLED} = {
    subProto => 'getEndStyled() => int',
    sciProto => 'SCI_GETENDSTYLED => position',
};

=item startStyling

    editor->startStyling($pos, $mask);

Set the current styling position to pos and the styling mask to mask. The styling mask can be used to protect some bits in each styling byte from modification.

See Scintilla documentation for  L<SCI_STARTSTYLING|https://www.scintilla.org/ScintillaDoc.html#SCI_STARTSTYLING>

=cut

$autogen{SCI_STARTSTYLING} = {
    subProto => 'startStyling(pos, mask)',
    sciProto => 'SCI_STARTSTYLING(position start, int unused)',
};

=item setStyling

    editor->setStyling($length, $style);

Change style from current styling position for length characters to a style and move the current styling position to after this newly styled segment.

See Scintilla documentation for  L<SCI_SETSTYLING|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSTYLING>

=cut

$autogen{SCI_SETSTYLING} = {
    subProto => 'setStyling(length, style)',
    sciProto => 'SCI_SETSTYLING(position length, int style)',
};

=item setStylingEx

    editor->setStylingEx($styles);

Set the styles for a segment of the document.

See Scintilla documentation for  L<SCI_SETSTYLINGEX|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSTYLINGEX>

=cut

$autogen{SCI_SETSTYLINGEX} = {
    subProto => 'setStylingEx(styles) => int',
    sciProto => 'SCI_SETSTYLINGEX(position length, const char *styles)',
};

=item setIdleStyling

=item getIdleStyling

    editor->setIdleStyling($idleStyling);
    editor->getIdleStyling;

Defines when and how syntax styling is applied.  By default, style visible text; the other options allow styling the whole document in the background, or styling the visible first, and then some or all of the rest of the document is styled as a background process during Notepad++ idle time.

Use $idleStyling from L<%SC_IDLESTYLING|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_IDLESTYLING">.


Since wrapping also needs to perform styling and also uses idle time, this setting has no effect when the document is displayed wrapped.

See Scintilla documentation for  L<SCI_SETIDLESTYLING|https://www.scintilla.org/ScintillaDoc.html#SCI_SETIDLESTYLING>

See Scintilla documentation for  L<SCI_GETIDLESTYLING|https://www.scintilla.org/ScintillaDoc.html#SCI_GETIDLESTYLING>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETIDLESTYLING} = {
    subProto => 'setIdleStyling(idleStyling)',
    sciProto => 'SCI_SETIDLESTYLING(int idleStyling)',
};


$autogen{SCI_GETIDLESTYLING} = {
    subProto => 'getIdleStyling',
    sciProto => 'SCI_GETIDLESTYLING => int',
};

=item setLineState

=item getLineState

    editor->setLineState($line, $state);
    editor->getLineState($line);

Used to hold extra styling information for each line.

See Scintilla documentation for  L<SCI_SETLINESTATE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLINESTATE>

See Scintilla documentation for  L<SCI_GETLINESTATE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINESTATE>

=cut

$autogen{SCI_SETLINESTATE} = {
    subProto => 'setLineState(line, state)',
    sciProto => 'SCI_SETLINESTATE(line line, int state)',
};

$autogen{SCI_GETLINESTATE} = {
    subProto => 'getLineState(line) => int',
    sciProto => 'SCI_GETLINESTATE(line line) => int',
};

=item getMaxLineState

    editor->getMaxLineState();

Retrieve the last line number that has line state.

See Scintilla documentation for  L<SCI_GETMAXLINESTATE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMAXLINESTATE>

=cut

$autogen{SCI_GETMAXLINESTATE} = {
    subProto => 'getMaxLineState() => int',
    sciProto => 'SCI_GETMAXLINESTATE => int',
};

=back

=head2 Style definition

There are 256 lexer styles that can be set, numbered 0 to $SC_STYLE{STYLE_MAX} (255). There are also some predefined numbered styles starting at 32, available in L<%SC_STYLE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_STYLE">.



=over

=item styleResetDefault

    editor->styleResetDefault();

Reset the default style to its state at startup

See Scintilla documentation for  L<SCI_STYLERESETDEFAULT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLERESETDEFAULT>

=cut

$autogen{SCI_STYLERESETDEFAULT} = {
    subProto => 'styleResetDefault()',
    sciProto => 'SCI_STYLERESETDEFAULT',
};

=item styleClearAll

    editor->styleClearAll();

Clear all the styles and make equivalent to the global default style.

See Scintilla documentation for  L<SCI_STYLECLEARALL|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLECLEARALL>

=cut

$autogen{SCI_STYLECLEARALL} = {
    subProto => 'styleClearAll()',
    sciProto => 'SCI_STYLECLEARALL',
};

=item styleSetFont

=item styleGetFont

    editor->styleSetFont($style, $fontName);
    editor->styleGetFont($style);

Set the font of a style.

See Scintilla documentation for  L<SCI_STYLESETFONT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETFONT>

See Scintilla documentation for  L<SCI_STYLEGETFONT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETFONT>

=cut

$autogen{SCI_STYLESETFONT} = {
    subProto => 'styleSetFont(style, fontName)',
    sciProto => 'SCI_STYLESETFONT(int style, const char *fontName)',
};

$autogen{SCI_STYLEGETFONT} = {
    subProto => 'styleGetFont(style) => str',
    sciProto => 'SCI_STYLEGETFONT(int style, char *fontName) => int',
};

=item styleSetSize

=item styleGetSize

    editor->styleSetSize($style, $sizePoints);
    editor->styleGetSize($style);

Set the size of characters of a style.

See Scintilla documentation for  L<SCI_STYLESETSIZE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETSIZE>

See Scintilla documentation for  L<SCI_STYLEGETSIZE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETSIZE>

=cut

$autogen{SCI_STYLESETSIZE} = {
    subProto => 'styleSetSize(style, sizePoints)',
    sciProto => 'SCI_STYLESETSIZE(int style, int sizePoints)',
};

$autogen{SCI_STYLEGETSIZE} = {
    subProto => 'styleGetSize(style) => int',
    sciProto => 'SCI_STYLEGETSIZE(int style) => int',
};

=item styleSetSizeFractional

=item styleGetSizeFractional

    editor->styleSetSizeFractional($style, $caseForce);
    editor->styleGetSizeFractional($style);

Set the size of characters of a style. Size is in points multiplied by 100.

(Technically, that 100 is from L<$SC_FONTSIZE{SC_FONT_SIZE_MULTIPLIER}|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FONTSIZE">.)

    my $style = ...;
    my $points = 12.5;  # want a 12.5pt font
    editor->styleSetSizeFractional( $style, $points * $SC_FONTSIZE{SC_FONT_SIZE_MULTIPLIER} );


See Scintilla documentation for  L<SCI_STYLESETSIZEFRACTIONAL|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETSIZEFRACTIONAL>

See Scintilla documentation for  L<SCI_STYLEGETSIZEFRACTIONAL|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETSIZEFRACTIONAL>

=cut

$autogen{SCI_STYLESETSIZEFRACTIONAL} = {
    subProto => 'styleSetSizeFractional(style, caseForce)',
    sciProto => 'SCI_STYLESETSIZEFRACTIONAL(int style, int sizeHundredthPoints)',
};

$autogen{SCI_STYLEGETSIZEFRACTIONAL} = {
    subProto => 'styleGetSizeFractional(style) => int',
    sciProto => 'SCI_STYLEGETSIZEFRACTIONAL(int style) => int',
};

=item styleSetBold

=item styleGetBold

    editor->styleSetBold($style, $bold);
    editor->styleGetBold($style);

Set a style to be bold or not.

See Scintilla documentation for  L<SCI_STYLESETBOLD|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETBOLD>

See Scintilla documentation for  L<SCI_STYLEGETBOLD|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETBOLD>

=cut

$autogen{SCI_STYLESETBOLD} = {
    subProto => 'styleSetBold(style, bold)',
    sciProto => 'SCI_STYLESETBOLD(int style, bool bold)',
};

$autogen{SCI_STYLEGETBOLD} = {
    subProto => 'styleGetBold(style) => bool',
    sciProto => 'SCI_STYLEGETBOLD(int style) => bool',
};

=item styleSetWeight

=item styleGetWeight

    editor->styleSetWeight($style, $weight);
    editor->styleGetWeight($style);

Set the weight of characters of a style.

Use $weight as an integer from 1 to 999, where 1 is very light and 999 is quite heavy; predefined values for normal and bold text can be used from L<%SC_WEIGHT|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WEIGHT">.


See Scintilla documentation for  L<SCI_STYLESETWEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETWEIGHT>

See Scintilla documentation for  L<SCI_STYLEGETWEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETWEIGHT>

=cut

$autogen{SCI_STYLESETWEIGHT} = {
    subProto => 'styleSetWeight(style, weight)',
    sciProto => 'SCI_STYLESETWEIGHT(int style, int weight)',
};

$autogen{SCI_STYLEGETWEIGHT} = {
    subProto => 'styleGetWeight(style) => int',
    sciProto => 'SCI_STYLEGETWEIGHT(int style) => int',
};

=item styleSetItalic

=item styleGetItalic

    editor->styleSetItalic($style, $italic);
    editor->styleGetItalic($style);

Set a style to be italic or not.

See Scintilla documentation for  L<SCI_STYLESETITALIC|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETITALIC>

See Scintilla documentation for  L<SCI_STYLEGETITALIC|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETITALIC>

=cut

$autogen{SCI_STYLESETITALIC} = {
    subProto => 'styleSetItalic(style, italic)',
    sciProto => 'SCI_STYLESETITALIC(int style, bool italic)',
};

$autogen{SCI_STYLEGETITALIC} = {
    subProto => 'styleGetItalic(style) => bool',
    sciProto => 'SCI_STYLEGETITALIC(int style) => bool',
};

=item styleSetUnderline

=item styleGetUnderline

    editor->styleSetUnderline($style, $underline);
    editor->styleGetUnderline($style);

Set a style to be underlined or not.

See Scintilla documentation for  L<SCI_STYLESETUNDERLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETUNDERLINE>

See Scintilla documentation for  L<SCI_STYLEGETUNDERLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETUNDERLINE>

=cut

$autogen{SCI_STYLESETUNDERLINE} = {
    subProto => 'styleSetUnderline(style, underline)',
    sciProto => 'SCI_STYLESETUNDERLINE(int style, bool underline)',
};

$autogen{SCI_STYLEGETUNDERLINE} = {
    subProto => 'styleGetUnderline(style) => bool',
    sciProto => 'SCI_STYLEGETUNDERLINE(int style) => bool',
};

=item styleSetFore

=item styleGetFore

    editor->styleSetFore($style, $fore);
    editor->styleGetFore($style);

Set the foreground colour of a style.

See Scintilla documentation for  L<SCI_STYLESETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETFORE>

See Scintilla documentation for  L<SCI_STYLEGETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETFORE>

=cut

$autogen{SCI_STYLESETFORE} = {
    subProto => 'styleSetFore(style, fore)',
    sciProto => 'SCI_STYLESETFORE(int style, colour fore)',
};

$autogen{SCI_STYLEGETFORE} = {
    subProto => 'styleGetFore(style) => tuple',
    sciProto => 'SCI_STYLEGETFORE(int style) => colour',
};

=item styleSetBack

=item styleGetBack

    editor->styleSetBack($style, $back);
    editor->styleGetBack($style);

Set the background colour of a style.

See Scintilla documentation for  L<SCI_STYLESETBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETBACK>

See Scintilla documentation for  L<SCI_STYLEGETBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETBACK>

=cut

$autogen{SCI_STYLESETBACK} = {
    subProto => 'styleSetBack(style, back)',
    sciProto => 'SCI_STYLESETBACK(int style, colour back)',
};

$autogen{SCI_STYLEGETBACK} = {
    subProto => 'styleGetBack(style) => tuple',
    sciProto => 'SCI_STYLEGETBACK(int style) => colour',
};

=item styleSetEOLFilled

=item styleGetEOLFilled

    editor->styleSetEOLFilled($style, $filled);
    editor->styleGetEOLFilled($style);

Set a style to have its end of line filled or not.

See Scintilla documentation for  L<SCI_STYLESETEOLFILLED|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETEOLFILLED>

See Scintilla documentation for  L<SCI_STYLEGETEOLFILLED|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETEOLFILLED>

=cut

$autogen{SCI_STYLESETEOLFILLED} = {
    subProto => 'styleSetEOLFilled(style, filled)',
    sciProto => 'SCI_STYLESETEOLFILLED(int style, bool eolFilled)',
};

$autogen{SCI_STYLEGETEOLFILLED} = {
    subProto => 'styleGetEOLFilled(style) => bool',
    sciProto => 'SCI_STYLEGETEOLFILLED(int style) => bool',
};

=item styleSetCharacterSet

=item styleGetCharacterSet

    editor->styleSetCharacterSet($style, $characterSet);
    editor->styleGetCharacterSet;

You can set a style to use a different character set than the default. The places where such characters sets are likely to be useful are comments and literal strings.

Use $characterSet from L<%SC_CHARSET|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CHARSET">.

See Scintilla documentation for  L<SCI_STYLESETCHARACTERSET|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETCHARACTERSET>

See Scintilla documentation for  L<SCI_STYLEGETCHARACTERSET|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETCHARACTERSET>

=cut

$autogen{SCI_STYLESETCHARACTERSET} = {
    subProto => 'styleSetCharacterSet(style, characterSet)',
    sciProto => 'SCI_STYLESETCHARACTERSET(int style, int characterSet)',
};


$autogen{SCI_STYLEGETCHARACTERSET} = {
    subProto => 'styleGetCharacterSet',
    sciProto => 'SCI_STYLEGETCHARACTERSET(int style) => int',
};

=item styleSetCase

=item styleGetCase

    editor->styleSetCase($style, $caseForce);
    editor->styleGetCase($style);

Set a style to be mixed case, or to force upper or lower case.  (Affects how text is displayed, not how it is stored.)

Use $caseForce from L<%SC_CASE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CASE">.

See Scintilla documentation for  L<SCI_STYLESETCASE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETCASE>

See Scintilla documentation for  L<SCI_STYLEGETCASE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETCASE>

=cut

$autogen{SCI_STYLESETCASE} = {
    subProto => 'styleSetCase(style, caseForce)',
    sciProto => 'SCI_STYLESETCASE(int style, int caseVisible)',
};

$autogen{SCI_STYLEGETCASE} = {
    subProto => 'styleGetCase(style) => int',
    sciProto => 'SCI_STYLEGETCASE(int style) => int',
};

=item styleSetVisible

=item styleGetVisible

    editor->styleSetVisible($style, $visible);
    editor->styleGetVisible($style);

Set a style to be visible or not.

See Scintilla documentation for  L<SCI_STYLESETVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETVISIBLE>

See Scintilla documentation for  L<SCI_STYLEGETVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETVISIBLE>

=cut

$autogen{SCI_STYLESETVISIBLE} = {
    subProto => 'styleSetVisible(style, visible)',
    sciProto => 'SCI_STYLESETVISIBLE(int style, bool visible)',
};

$autogen{SCI_STYLEGETVISIBLE} = {
    subProto => 'styleGetVisible(style) => bool',
    sciProto => 'SCI_STYLEGETVISIBLE(int style) => bool',
};

=item styleSetChangeable

=item styleGetChangeable

    editor->styleSetChangeable($style, $changeable);
    editor->styleGetChangeable($style);

Set a style to be changeable or not (read only). Experimental feature, currently buggy.

See Scintilla documentation for  L<SCI_STYLESETCHANGEABLE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETCHANGEABLE>

See Scintilla documentation for  L<SCI_STYLEGETCHANGEABLE|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETCHANGEABLE>

=cut

$autogen{SCI_STYLESETCHANGEABLE} = {
    subProto => 'styleSetChangeable(style, changeable)',
    sciProto => 'SCI_STYLESETCHANGEABLE(int style, bool changeable)',
};

$autogen{SCI_STYLEGETCHANGEABLE} = {
    subProto => 'styleGetChangeable(style) => bool',
    sciProto => 'SCI_STYLEGETCHANGEABLE(int style) => bool',
};

=item styleSetHotSpot

=item styleGetHotSpot

    editor->styleSetHotSpot($style, $hotspot);
    editor->styleGetHotSpot($style);

Set a style to be a hotspot or not.

See Scintilla documentation for  L<SCI_STYLESETHOTSPOT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLESETHOTSPOT>

See Scintilla documentation for  L<SCI_STYLEGETHOTSPOT|https://www.scintilla.org/ScintillaDoc.html#SCI_STYLEGETHOTSPOT>

=cut

$autogen{SCI_STYLESETHOTSPOT} = {
    subProto => 'styleSetHotSpot(style, hotspot)',
    sciProto => 'SCI_STYLESETHOTSPOT(int style, bool hotspot)',
};

$autogen{SCI_STYLEGETHOTSPOT} = {
    subProto => 'styleGetHotSpot(style) => bool',
    sciProto => 'SCI_STYLEGETHOTSPOT(int style) => bool',
};

=back

=head2 Caret, selection, and hotspot styles




=over

=item setSelFore

    editor->setSelFore($useSetting, $fore);

Set the foreground colour of the main and additional selections and whether to use this setting.

See Scintilla documentation for  L<SCI_SETSELFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELFORE>

=cut

$autogen{SCI_SETSELFORE} = {
    subProto => 'setSelFore(useSetting, fore)',
    sciProto => 'SCI_SETSELFORE(bool useSetting, colour fore)',
};

=item setSelBack

    editor->setSelBack($useSetting, $back);

Set the background colour of the main and additional selections and whether to use this setting.

See Scintilla documentation for  L<SCI_SETSELBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELBACK>

=cut

$autogen{SCI_SETSELBACK} = {
    subProto => 'setSelBack(useSetting, back)',
    sciProto => 'SCI_SETSELBACK(bool useSetting, colour back)',
};

=item setSelAlpha

=item getSelAlpha

    editor->setSelAlpha($alpha);
    editor->getSelAlpha();

Get the alpha of the selection.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_GETSELALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELALPHA>

See Scintilla documentation for  L<SCI_SETSELALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELALPHA>

=cut

$autogen{SCI_GETSELALPHA} = {
    subProto => 'getSelAlpha() => int',
    sciProto => 'SCI_GETSELALPHA => int',
};

$autogen{SCI_SETSELALPHA} = {
    subProto => 'setSelAlpha(alpha)',
    sciProto => 'SCI_SETSELALPHA(alpha alpha)',
};

=item setSelEOLFilled

=item getSelEOLFilled

    editor->setSelEOLFilled($filled);
    editor->getSelEOLFilled();

Is the selection end of line filled?

See Scintilla documentation for  L<SCI_GETSELEOLFILLED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSELEOLFILLED>

See Scintilla documentation for  L<SCI_SETSELEOLFILLED|https://www.scintilla.org/ScintillaDoc.html#SCI_SETSELEOLFILLED>

=cut

$autogen{SCI_GETSELEOLFILLED} = {
    subProto => 'getSelEOLFilled() => bool',
    sciProto => 'SCI_GETSELEOLFILLED => bool',
};

$autogen{SCI_SETSELEOLFILLED} = {
    subProto => 'setSelEOLFilled(filled)',
    sciProto => 'SCI_SETSELEOLFILLED(bool filled)',
};

=item setCaretFore

=item getCaretFore

    editor->setCaretFore($fore);
    editor->getCaretFore();

Set and retrieve the foreground colour of the caret.

See Scintilla documentation for  L<SCI_SETCARETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETFORE>

See Scintilla documentation for  L<SCI_GETCARETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETFORE>

=cut

$autogen{SCI_SETCARETFORE} = {
    subProto => 'setCaretFore(fore)',
    sciProto => 'SCI_SETCARETFORE(colour fore)',
};

$autogen{SCI_GETCARETFORE} = {
    subProto => 'getCaretFore() => tuple',
    sciProto => 'SCI_GETCARETFORE => colour',
};

=item setCaretLineVisible

=item getCaretLineVisible

    editor->setCaretLineVisible($show);
    editor->getCaretLineVisible();

Display the background of the line containing the caret in a different colour.

See Scintilla documentation for  L<SCI_SETCARETLINEVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETLINEVISIBLE>

See Scintilla documentation for  L<SCI_GETCARETLINEVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETLINEVISIBLE>

=cut

$autogen{SCI_GETCARETLINEVISIBLE} = {
    subProto => 'getCaretLineVisible() => bool',
    sciProto => 'SCI_GETCARETLINEVISIBLE => bool',
};

$autogen{SCI_SETCARETLINEVISIBLE} = {
    subProto => 'setCaretLineVisible(show)',
    sciProto => 'SCI_SETCARETLINEVISIBLE(bool show)',
};

=item setCaretLineBack

=item getCaretLineBack

    editor->setCaretLineBack($back);
    editor->getCaretLineBack();

Set the colour of the background of the line containing the caret.

See Scintilla documentation for  L<SCI_GETCARETLINEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETLINEBACK>

See Scintilla documentation for  L<SCI_SETCARETLINEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETLINEBACK>

=cut

$autogen{SCI_GETCARETLINEBACK} = {
    subProto => 'getCaretLineBack() => tuple',
    sciProto => 'SCI_GETCARETLINEBACK => colour',
};

$autogen{SCI_SETCARETLINEBACK} = {
    subProto => 'setCaretLineBack(back)',
    sciProto => 'SCI_SETCARETLINEBACK(colour back)',
};

=item setCaretLineBackAlpha

=item getCaretLineBackAlpha

    editor->setCaretLineBackAlpha($alpha);
    editor->getCaretLineBackAlpha();

Set and retrieve background alpha of the caret line.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_SETCARETLINEBACKALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETLINEBACKALPHA>

See Scintilla documentation for  L<SCI_GETCARETLINEBACKALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETLINEBACKALPHA>

=cut

$autogen{SCI_SETCARETLINEBACKALPHA} = {
    subProto => 'setCaretLineBackAlpha(alpha)',
    sciProto => 'SCI_SETCARETLINEBACKALPHA(alpha alpha)',
};

$autogen{SCI_GETCARETLINEBACKALPHA} = {
    subProto => 'getCaretLineBackAlpha() => int',
    sciProto => 'SCI_GETCARETLINEBACKALPHA => int',
};

=item setCaretLineFrame

=item getCaretLineFrame

    editor->setCaretLineFrame($width);
    editor->getCaretLineFrame;

Set and retrieve the width of the frame around the caret line.

See Scintilla documentation for  L<SCI_SETCARETLINEFRAME|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETLINEFRAME>

See Scintilla documentation for  L<SCI_GETCARETLINEFRAME|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETLINEFRAME>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETCARETLINEFRAME} = {
    subProto => 'setCaretLineFrame(width)',
    sciProto => 'SCI_SETCARETLINEFRAME(int width)',
};

$autogen{SCI_GETCARETLINEFRAME} = {
    subProto => 'getCaretLineFrame',
    sciProto => 'SCI_GETCARETLINEFRAME => int',
};

=item setCaretLineVisibleAlways

=item getCaretLineVisibleAlways

    editor->setCaretLineVisibleAlways($alwaysVisible);
    editor->getCaretLineVisibleAlways();

Sets the caret line to always visible.

See Scintilla documentation for  L<SCI_SETCARETLINEVISIBLEALWAYS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETLINEVISIBLEALWAYS>

See Scintilla documentation for  L<SCI_GETCARETLINEVISIBLEALWAYS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETLINEVISIBLEALWAYS>

=cut

$autogen{SCI_GETCARETLINEVISIBLEALWAYS} = {
    subProto => 'getCaretLineVisibleAlways() => bool',
    sciProto => 'SCI_GETCARETLINEVISIBLEALWAYS => bool',
};

$autogen{SCI_SETCARETLINEVISIBLEALWAYS} = {
    subProto => 'setCaretLineVisibleAlways(alwaysVisible)',
    sciProto => 'SCI_SETCARETLINEVISIBLEALWAYS(bool alwaysVisible)',
};

=item setCaretPeriod

=item getCaretPeriod

    editor->setCaretPeriod($periodMilliseconds);
    editor->getCaretPeriod();

Get the time in milliseconds that the caret is on and off. 0 = steady on.

See Scintilla documentation for  L<SCI_SETCARETPERIOD|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETPERIOD>

See Scintilla documentation for  L<SCI_GETCARETPERIOD|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETPERIOD>

=cut

$autogen{SCI_GETCARETPERIOD} = {
    subProto => 'getCaretPeriod() => int',
    sciProto => 'SCI_GETCARETPERIOD => int',
};

$autogen{SCI_SETCARETPERIOD} = {
    subProto => 'setCaretPeriod(periodMilliseconds)',
    sciProto => 'SCI_SETCARETPERIOD(int periodMilliseconds)',
};

=item setCaretStyle

=item getCaretStyle

    editor->setCaretStyle($caretStyle);
    editor->getCaretStyle();

Set the style of the caret to be drawn.

C<$caretStyle> from L<%SC_CARETSTYLE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CARETSTYLE">.

See Scintilla documentation for  L<SCI_SETCARETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETSTYLE>

See Scintilla documentation for  L<SCI_GETCARETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETSTYLE>

=cut

$autogen{SCI_SETCARETSTYLE} = {
    subProto => 'setCaretStyle(caretStyle)',
    sciProto => 'SCI_SETCARETSTYLE(int caretStyle)',
};

$autogen{SCI_GETCARETSTYLE} = {
    subProto => 'getCaretStyle() => int',
    sciProto => 'SCI_GETCARETSTYLE => int',
};

=item setCaretWidth

=item getCaretWidth

    editor->setCaretWidth($pixelWidth);
    editor->getCaretWidth();

Set the width of the insert mode caret.

See Scintilla documentation for  L<SCI_SETCARETWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETWIDTH>

See Scintilla documentation for  L<SCI_GETCARETWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETWIDTH>

=cut

$autogen{SCI_SETCARETWIDTH} = {
    subProto => 'setCaretWidth(pixelWidth)',
    sciProto => 'SCI_SETCARETWIDTH(int pixelWidth)',
};

$autogen{SCI_GETCARETWIDTH} = {
    subProto => 'getCaretWidth() => int',
    sciProto => 'SCI_GETCARETWIDTH => int',
};

=item setHotspotActiveFore

=item getHotspotActiveFore

    editor->setHotspotActiveFore($useSetting, $fore);
    editor->getHotspotActiveFore();

Set a fore colour for active hotspots.

See Scintilla documentation for  L<SCI_SETHOTSPOTACTIVEFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHOTSPOTACTIVEFORE>

See Scintilla documentation for  L<SCI_GETHOTSPOTACTIVEFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHOTSPOTACTIVEFORE>

=cut

$autogen{SCI_SETHOTSPOTACTIVEFORE} = {
    subProto => 'setHotspotActiveFore(useSetting, fore)',
    sciProto => 'SCI_SETHOTSPOTACTIVEFORE(bool useSetting, colour fore)',
};

$autogen{SCI_GETHOTSPOTACTIVEFORE} = {
    subProto => 'getHotspotActiveFore() => tuple',
    sciProto => 'SCI_GETHOTSPOTACTIVEFORE => colour',
};

=item setHotspotActiveBack

=item getHotspotActiveBack

    editor->setHotspotActiveBack($useSetting, $back);
    editor->getHotspotActiveBack();

Set a back colour for active hotspots.

See Scintilla documentation for  L<SCI_SETHOTSPOTACTIVEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHOTSPOTACTIVEBACK>

See Scintilla documentation for  L<SCI_GETHOTSPOTACTIVEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHOTSPOTACTIVEBACK>

=cut

$autogen{SCI_SETHOTSPOTACTIVEBACK} = {
    subProto => 'setHotspotActiveBack(useSetting, back)',
    sciProto => 'SCI_SETHOTSPOTACTIVEBACK(bool useSetting, colour back)',
};

$autogen{SCI_GETHOTSPOTACTIVEBACK} = {
    subProto => 'getHotspotActiveBack() => tuple',
    sciProto => 'SCI_GETHOTSPOTACTIVEBACK => colour',
};

=item setHotspotActiveUnderline

=item getHotspotActiveUnderline

    editor->setHotspotActiveUnderline($underline);
    editor->getHotspotActiveUnderline();

Enable / Disable underlining active hotspots.

See Scintilla documentation for  L<SCI_SETHOTSPOTACTIVEUNDERLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHOTSPOTACTIVEUNDERLINE>

See Scintilla documentation for  L<SCI_GETHOTSPOTACTIVEUNDERLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHOTSPOTACTIVEUNDERLINE>

=cut

$autogen{SCI_SETHOTSPOTACTIVEUNDERLINE} = {
    subProto => 'setHotspotActiveUnderline(underline)',
    sciProto => 'SCI_SETHOTSPOTACTIVEUNDERLINE(bool underline)',
};

$autogen{SCI_GETHOTSPOTACTIVEUNDERLINE} = {
    subProto => 'getHotspotActiveUnderline() => bool',
    sciProto => 'SCI_GETHOTSPOTACTIVEUNDERLINE => bool',
};

=item setHotspotSingleLine

=item getHotspotSingleLine

    editor->setHotspotSingleLine($singleLine);
    editor->getHotspotSingleLine();

Limit hotspots to single line so hotspots on two lines don’t merge.

See Scintilla documentation for  L<SCI_SETHOTSPOTSINGLELINE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHOTSPOTSINGLELINE>

See Scintilla documentation for  L<SCI_GETHOTSPOTSINGLELINE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHOTSPOTSINGLELINE>

=cut

$autogen{SCI_SETHOTSPOTSINGLELINE} = {
    subProto => 'setHotspotSingleLine(singleLine)',
    sciProto => 'SCI_SETHOTSPOTSINGLELINE(bool singleLine)',
};

$autogen{SCI_GETHOTSPOTSINGLELINE} = {
    subProto => 'getHotspotSingleLine() => bool',
    sciProto => 'SCI_GETHOTSPOTSINGLELINE => bool',
};

=item setCaretSticky

=item getCaretSticky

    editor->setCaretSticky($useCaretStickyBehaviour);
    editor->getCaretSticky();

Can the caret preferred x position only be changed by explicit movement commands?

Use $useCaretStickyBehavior from L<%SC_CARETSTICKY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CARETSTICKY">

See Scintilla documentation for  L<SCI_GETCARETSTICKY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCARETSTICKY>

See Scintilla documentation for  L<SCI_SETCARETSTICKY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCARETSTICKY>

=cut

$autogen{SCI_GETCARETSTICKY} = {
    subProto => 'getCaretSticky() => int',
    sciProto => 'SCI_GETCARETSTICKY => int',
};

$autogen{SCI_SETCARETSTICKY} = {
    subProto => 'setCaretSticky(useCaretStickyBehaviour)',
    sciProto => 'SCI_SETCARETSTICKY(int useCaretStickyBehaviour)',
};

=item toggleCaretSticky

    editor->toggleCaretSticky();

Switch between sticky and non-sticky: meant to be bound to a key.

See Scintilla documentation for  L<SCI_TOGGLECARETSTICKY|https://www.scintilla.org/ScintillaDoc.html#SCI_TOGGLECARETSTICKY>

=cut

$autogen{SCI_TOGGLECARETSTICKY} = {
    subProto => 'toggleCaretSticky()',
    sciProto => 'SCI_TOGGLECARETSTICKY',
};

=back

=head2 Character representations




=over

=item setRepresentation

=item getRepresentation

    editor->setRepresentation($encodedCharacter, $representation);
    editor->getRepresentation();

Set the way a character is drawn.

See Scintilla documentation for  L<SCI_SETREPRESENTATION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETREPRESENTATION>

See Scintilla documentation for  L<SCI_GETREPRESENTATION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETREPRESENTATION>

=cut

$autogen{SCI_SETREPRESENTATION} = {
    subProto => 'setRepresentation(encodedCharacter, representation)',
    sciProto => 'SCI_SETREPRESENTATION(const char *encodedCharacter, const char *representation)',
};

$autogen{SCI_GETREPRESENTATION} = {
    subProto => 'getRepresentation() => str',
    sciProto => 'SCI_GETREPRESENTATION(const char *encodedCharacter, char *representation) => int',
};

=item clearRepresentation

    editor->clearRepresentation($encodedCharacter);

Remove a character representation.

See Scintilla documentation for  L<SCI_CLEARREPRESENTATION|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARREPRESENTATION>

=cut

$autogen{SCI_CLEARREPRESENTATION} = {
    subProto => 'clearRepresentation(encodedCharacter)',
    sciProto => 'SCI_CLEARREPRESENTATION(const char *encodedCharacter)',
};

=item setControlCharSymbol

=item getControlCharSymbol

    editor->setControlCharSymbol($symbol);
    editor->getControlCharSymbol();

Change the way control characters are displayed: If symbol is < 32, keep the drawn way, else, use the given character.

See Scintilla documentation for  L<SCI_SETCONTROLCHARSYMBOL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCONTROLCHARSYMBOL>

See Scintilla documentation for  L<SCI_GETCONTROLCHARSYMBOL|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCONTROLCHARSYMBOL>

=cut

$autogen{SCI_SETCONTROLCHARSYMBOL} = {
    subProto => 'setControlCharSymbol(symbol)',
    sciProto => 'SCI_SETCONTROLCHARSYMBOL(int symbol)',
};

$autogen{SCI_GETCONTROLCHARSYMBOL} = {
    subProto => 'getControlCharSymbol() => int',
    sciProto => 'SCI_GETCONTROLCHARSYMBOL => int',
};

=back

=head2 Margins




=over

=item setMargins

=item getMargins

    editor->setMargins($numberOfMargins);
    editor->getMargins;

Allocate the number of margins or find the number of margins currently allocated.

Overrides L<$SC_MARGIN{SC_MAX_MARGIN}|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARGIN">.

See Scintilla documentation for  L<SCI_SETMARGINS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINS>

See Scintilla documentation for  L<SCI_GETMARGINS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINS>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETMARGINS} = {
    subProto => 'setMargins(margins)',
    sciProto => 'SCI_SETMARGINS(int margins)',
};

$autogen{SCI_GETMARGINS} = {
    subProto => 'getMargins',
    sciProto => 'SCI_GETMARGINS => int',
};

=item setMarginTypeN

=item getMarginTypeN

    editor->setMarginTypeN($margin, $marginType);
    editor->getMarginTypeN($margin);

Set a specific margin to be either numeric or symbolic.

The $margin argument needs to be an index between 0 and $SC_MARGIN{SC_MAX_MARGIN} (inclusive), unless L</setMargins> has been called to increase the number of margins available.

Use $marginType value should come from L<%SC_MARGIN|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARGIN">.

See Scintilla documentation for  L<SCI_SETMARGINTYPEN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINTYPEN>

See Scintilla documentation for  L<SCI_GETMARGINTYPEN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINTYPEN>

=cut

$autogen{SCI_SETMARGINTYPEN} = {
    subProto => 'setMarginTypeN(margin, marginType)',
    sciProto => 'SCI_SETMARGINTYPEN(int margin, int marginType)',
};

$autogen{SCI_GETMARGINTYPEN} = {
    subProto => 'getMarginTypeN(margin) => int',
    sciProto => 'SCI_GETMARGINTYPEN(int margin) => int',
};

=item setMarginWidthN

=item getMarginWidthN

    editor->setMarginWidthN($margin, $pixelWidth);
    editor->getMarginWidthN($margin);

Set the width of a margin to a width expressed in pixels.

See Scintilla documentation for  L<SCI_SETMARGINWIDTHN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINWIDTHN>

See Scintilla documentation for  L<SCI_GETMARGINWIDTHN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINWIDTHN>

=cut

$autogen{SCI_SETMARGINWIDTHN} = {
    subProto => 'setMarginWidthN(margin, pixelWidth)',
    sciProto => 'SCI_SETMARGINWIDTHN(int margin, int pixelWidth)',
};

$autogen{SCI_GETMARGINWIDTHN} = {
    subProto => 'getMarginWidthN(margin) => int',
    sciProto => 'SCI_GETMARGINWIDTHN(int margin) => int',
};

=item setMarginMaskN

=item getMarginMaskN

    editor->setMarginMaskN($margin, $mask);
    editor->getMarginMaskN($margin);

Set a mask that determines which markers are displayed in a margin.

The $mask is a 32-bit number, where each bit represents one of the 32 numbered markers.  If the bit is set in the mask, that marker will be enabled for that margin.  It can be useful to only include the seven code-folding markers in bits 25-31 using the predefined mask L<C<$SC_MARKNUM{SC_MASK_FOLDER}>|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARKNUM">; to enable all the markers _except_ those seven, use C<~$SC_MARKNUM{SC_MASK_FOLDER}>.


See Scintilla documentation for  L<SCI_SETMARGINMASKN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINMASKN>

See Scintilla documentation for  L<SCI_GETMARGINMASKN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINMASKN>

=cut

$autogen{SCI_SETMARGINMASKN} = {
    subProto => 'setMarginMaskN(margin, mask)',
    sciProto => 'SCI_SETMARGINMASKN(int margin, int mask)',
};

$autogen{SCI_GETMARGINMASKN} = {
    subProto => 'getMarginMaskN(margin) => int',
    sciProto => 'SCI_GETMARGINMASKN(int margin) => int',
};

=item setMarginSensitiveN

=item getMarginSensitiveN

    editor->setMarginSensitiveN($margin, $sensitive);
    editor->getMarginSensitiveN($margin);

Make a margin sensitive or insensitive to mouse clicks.

See Scintilla documentation for  L<SCI_SETMARGINSENSITIVEN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINSENSITIVEN>

See Scintilla documentation for  L<SCI_GETMARGINSENSITIVEN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINSENSITIVEN>

=cut

$autogen{SCI_SETMARGINSENSITIVEN} = {
    subProto => 'setMarginSensitiveN(margin, sensitive)',
    sciProto => 'SCI_SETMARGINSENSITIVEN(int margin, bool sensitive)',
};

$autogen{SCI_GETMARGINSENSITIVEN} = {
    subProto => 'getMarginSensitiveN(margin) => bool',
    sciProto => 'SCI_GETMARGINSENSITIVEN(int margin) => bool',
};

=item setMarginCursorN

=item getMarginCursorN

    editor->setMarginCursorN($margin, $cursor);
    editor->getMarginCursorN($margin);

Set the cursor shown when the mouse is inside a margin.

Use $cursor from L<%SC_CURSOR|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CURSOR">, either C<$SC_CURSOR{SC_CURSORARROW}> or C<$SC_CURSOR{SC_CURSORREVERSEARROW}>

See Scintilla documentation for  L<SCI_SETMARGINCURSORN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINCURSORN>

See Scintilla documentation for  L<SCI_GETMARGINCURSORN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINCURSORN>

=cut

$autogen{SCI_SETMARGINCURSORN} = {
    subProto => 'setMarginCursorN(margin, cursor)',
    sciProto => 'SCI_SETMARGINCURSORN(int margin, int cursor)',
};

$autogen{SCI_GETMARGINCURSORN} = {
    subProto => 'getMarginCursorN(margin) => int',
    sciProto => 'SCI_GETMARGINCURSORN(int margin) => int',
};

=item setMarginBackN

=item getMarginBackN

    editor->setMarginBackN($margin, $backgroundColor);
    editor->getMarginBackN;

Set and retrieve the background color for the specified margin

See Scintilla documentation for  L<SCI_SETMARGINBACKN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINBACKN>

See Scintilla documentation for  L<SCI_GETMARGINBACKN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINBACKN>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETMARGINBACKN} = {
    subProto => 'setMarginBackN(margin, back)',
    sciProto => 'SCI_SETMARGINBACKN(int margin, colour back)',
};

$autogen{SCI_GETMARGINBACKN} = {
    subProto => 'getMarginBackN',
    sciProto => 'SCI_GETMARGINBACKN(int margin) => colour',
};

=item setMarginLeft

=item getMarginLeft

    editor->setMarginLeft($pixelWidth);
    editor->getMarginLeft();

Sets the size in pixels of the left margin.

See Scintilla documentation for  L<SCI_SETMARGINLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINLEFT>

See Scintilla documentation for  L<SCI_GETMARGINLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINLEFT>

=cut

$autogen{SCI_SETMARGINLEFT} = {
    subProto => 'setMarginLeft(pixelWidth)',
    sciProto => 'SCI_SETMARGINLEFT(<unused>, int pixelWidth)',
};

$autogen{SCI_GETMARGINLEFT} = {
    subProto => 'getMarginLeft() => int',
    sciProto => 'SCI_GETMARGINLEFT => int',
};

=item setMarginRight

=item getMarginRight

    editor->setMarginRight($pixelWidth);
    editor->getMarginRight();

Sets the size in pixels of the right margin.

See Scintilla documentation for  L<SCI_SETMARGINRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINRIGHT>

See Scintilla documentation for  L<SCI_GETMARGINRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINRIGHT>

=cut

$autogen{SCI_SETMARGINRIGHT} = {
    subProto => 'setMarginRight(pixelWidth)',
    sciProto => 'SCI_SETMARGINRIGHT(<unused>, int pixelWidth)',
};

$autogen{SCI_GETMARGINRIGHT} = {
    subProto => 'getMarginRight() => int',
    sciProto => 'SCI_GETMARGINRIGHT => int',
};

=item setFoldMarginColour

    editor->setFoldMarginColour($useSetting, $back);

Set the colours used as a chequerboard pattern in the fold margin

See Scintilla documentation for  L<SCI_SETFOLDMARGINCOLOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDMARGINCOLOUR>

=cut

$autogen{SCI_SETFOLDMARGINCOLOUR} = {
    subProto => 'setFoldMarginColour(useSetting, back)',
    sciProto => 'SCI_SETFOLDMARGINCOLOUR(bool useSetting, colour back)',
};

=item setFoldMarginHiColour

    editor->setFoldMarginHiColour($useSetting, $fore);

Set the colours used as a chequerboard pattern in the fold margin

See Scintilla documentation for  L<SCI_SETFOLDMARGINHICOLOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDMARGINHICOLOUR>

=cut

$autogen{SCI_SETFOLDMARGINHICOLOUR} = {
    subProto => 'setFoldMarginHiColour(useSetting, fore)',
    sciProto => 'SCI_SETFOLDMARGINHICOLOUR(bool useSetting, colour fore)',
};

=item marginSetText

=item marginGetText

    editor->marginSetText($line, $text);
    editor->marginGetText($line);

Set the text in the text margin for a line

See Scintilla documentation for  L<SCI_MARGINSETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINSETTEXT>

See Scintilla documentation for  L<SCI_MARGINGETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINGETTEXT>

=cut

$autogen{SCI_MARGINSETTEXT} = {
    subProto => 'marginSetText(line, text)',
    sciProto => 'SCI_MARGINSETTEXT(line line, const char *text)',
};

$autogen{SCI_MARGINGETTEXT} = {
    subProto => 'marginGetText(line) => str',
    sciProto => 'SCI_MARGINGETTEXT(line line, char *text) => int',
};

=item marginSetStyle

=item marginGetStyle

    editor->marginSetStyle($line, $style);
    editor->marginGetStyle($line);

Set the style number for the text margin for a line.

Use $style from L<%SC_MARGIN|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARGIN">.

See Scintilla documentation for  L<SCI_MARGINSETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINSETSTYLE>

See Scintilla documentation for  L<SCI_MARGINGETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINGETSTYLE>

=cut

$autogen{SCI_MARGINSETSTYLE} = {
    subProto => 'marginSetStyle(line, style)',
    sciProto => 'SCI_MARGINSETSTYLE(line line, int style)',
};

$autogen{SCI_MARGINGETSTYLE} = {
    subProto => 'marginGetStyle(line) => int',
    sciProto => 'SCI_MARGINGETSTYLE(line line) => int',
};

=item marginSetStyles

=item marginGetStyles

    editor->marginSetStyles($line, $styles);
    editor->marginGetStyles($line);

Set the style in the text margin for a line

See Scintilla documentation for  L<SCI_MARGINSETSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINSETSTYLES>

See Scintilla documentation for  L<SCI_MARGINGETSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINGETSTYLES>

=cut

$autogen{SCI_MARGINSETSTYLES} = {
    subProto => 'marginSetStyles(line, styles)',
    sciProto => 'SCI_MARGINSETSTYLES(line line, const char *styles)',
};

$autogen{SCI_MARGINGETSTYLES} = {
    subProto => 'marginGetStyles(line) => str',
    sciProto => 'SCI_MARGINGETSTYLES(line line, char *styles) => int',
};

=item marginTextClearAll

    editor->marginTextClearAll();

Clear the margin text on all lines

See Scintilla documentation for  L<SCI_MARGINTEXTCLEARALL|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINTEXTCLEARALL>

=cut

$autogen{SCI_MARGINTEXTCLEARALL} = {
    subProto => 'marginTextClearAll()',
    sciProto => 'SCI_MARGINTEXTCLEARALL',
};

=item marginSetStyleOffset

=item marginGetStyleOffset

    editor->marginSetStyleOffset($style);
    editor->marginGetStyleOffset();

Get the start of the range of style numbers used for margin text

See Scintilla documentation for  L<SCI_MARGINSETSTYLEOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINSETSTYLEOFFSET>

See Scintilla documentation for  L<SCI_MARGINGETSTYLEOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_MARGINGETSTYLEOFFSET>

=cut

$autogen{SCI_MARGINSETSTYLEOFFSET} = {
    subProto => 'marginSetStyleOffset(style)',
    sciProto => 'SCI_MARGINSETSTYLEOFFSET(int style)',
};

$autogen{SCI_MARGINGETSTYLEOFFSET} = {
    subProto => 'marginGetStyleOffset() => int',
    sciProto => 'SCI_MARGINGETSTYLEOFFSET => int',
};

=item setMarginOptions

=item getMarginOptions

    editor->setMarginOptions($marginOptions);
    editor->getMarginOptions();

Set the margin options.

See Scintilla documentation for  L<SCI_SETMARGINOPTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMARGINOPTIONS>

See Scintilla documentation for  L<SCI_GETMARGINOPTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMARGINOPTIONS>

=cut

$autogen{SCI_SETMARGINOPTIONS} = {
    subProto => 'setMarginOptions(marginOptions)',
    sciProto => 'SCI_SETMARGINOPTIONS(int marginOptions)',
};

$autogen{SCI_GETMARGINOPTIONS} = {
    subProto => 'getMarginOptions() => int',
    sciProto => 'SCI_GETMARGINOPTIONS => int',
};

=back

=head2 Annotations




=over

=item annotationSetText

=item annotationGetText

    editor->annotationSetText($line, $text);
    editor->annotationGetText($line);

Set the annotation text for a line

See Scintilla documentation for  L<SCI_ANNOTATIONSETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONSETTEXT>

See Scintilla documentation for  L<SCI_ANNOTATIONGETTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETTEXT>

=cut

$autogen{SCI_ANNOTATIONSETTEXT} = {
    subProto => 'annotationSetText(line, text)',
    sciProto => 'SCI_ANNOTATIONSETTEXT(line line, const char *text)',
};

$autogen{SCI_ANNOTATIONGETTEXT} = {
    subProto => 'annotationGetText(line) => str',
    sciProto => 'SCI_ANNOTATIONGETTEXT(line line, char *text) => int',
};

=item annotationSetStyle

=item annotationGetStyle

    editor->annotationSetStyle($line, $style);
    editor->annotationGetStyle($line);

Set the style number for the annotations for a line

See Scintilla documentation for  L<SCI_ANNOTATIONSETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONSETSTYLE>

See Scintilla documentation for  L<SCI_ANNOTATIONGETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETSTYLE>

=cut

$autogen{SCI_ANNOTATIONSETSTYLE} = {
    subProto => 'annotationSetStyle(line, style)',
    sciProto => 'SCI_ANNOTATIONSETSTYLE(line line, int style)',
};

$autogen{SCI_ANNOTATIONGETSTYLE} = {
    subProto => 'annotationGetStyle(line) => int',
    sciProto => 'SCI_ANNOTATIONGETSTYLE(line line) => int',
};

=item annotationSetStyles

=item annotationGetStyles

    editor->annotationSetStyles($line, $styles);
    editor->annotationGetStyles($line);

Set the annotation styles for a line

See Scintilla documentation for  L<SCI_ANNOTATIONSETSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONSETSTYLES>

See Scintilla documentation for  L<SCI_ANNOTATIONGETSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETSTYLES>

=cut

$autogen{SCI_ANNOTATIONSETSTYLES} = {
    subProto => 'annotationSetStyles(line, styles)',
    sciProto => 'SCI_ANNOTATIONSETSTYLES(line line, const char *styles)',
};

$autogen{SCI_ANNOTATIONGETSTYLES} = {
    subProto => 'annotationGetStyles(line) => str',
    sciProto => 'SCI_ANNOTATIONGETSTYLES(line line, char *styles) => int',
};

=item annotationGetLines

    editor->annotationGetLines($line);

Get the number of annotation lines for a line

See Scintilla documentation for  L<SCI_ANNOTATIONGETLINES|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETLINES>

=cut

$autogen{SCI_ANNOTATIONGETLINES} = {
    subProto => 'annotationGetLines(line) => int',
    sciProto => 'SCI_ANNOTATIONGETLINES(line line) => int',
};

=item annotationClearAll

    editor->annotationClearAll();

Clear the annotations from all lines

See Scintilla documentation for  L<SCI_ANNOTATIONCLEARALL|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONCLEARALL>

=cut

$autogen{SCI_ANNOTATIONCLEARALL} = {
    subProto => 'annotationClearAll()',
    sciProto => 'SCI_ANNOTATIONCLEARALL',
};

=item annotationSetVisible

=item annotationGetVisible

    editor->annotationSetVisible($visible);
    editor->annotationGetVisible();

Set the visibility for the annotations for a view, where C<$visible> comes from L<%SC_ANNOTATION|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ANNOTATION">.

See Scintilla documentation for  L<SCI_ANNOTATIONSETVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONSETVISIBLE>

See Scintilla documentation for  L<SCI_ANNOTATIONGETVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETVISIBLE>

=cut

$autogen{SCI_ANNOTATIONSETVISIBLE} = {
    subProto => 'annotationSetVisible(visible)',
    sciProto => 'SCI_ANNOTATIONSETVISIBLE(int visible)',
};

$autogen{SCI_ANNOTATIONGETVISIBLE} = {
    subProto => 'annotationGetVisible() => int',
    sciProto => 'SCI_ANNOTATIONGETVISIBLE => int',
};

=item annotationSetStyleOffset

=item annotationGetStyleOffset

    editor->annotationSetStyleOffset($style);
    editor->annotationGetStyleOffset();

Get the start of the range of style numbers used for annotations

See Scintilla documentation for  L<SCI_ANNOTATIONSETSTYLEOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONSETSTYLEOFFSET>

See Scintilla documentation for  L<SCI_ANNOTATIONGETSTYLEOFFSET|https://www.scintilla.org/ScintillaDoc.html#SCI_ANNOTATIONGETSTYLEOFFSET>

=cut

$autogen{SCI_ANNOTATIONSETSTYLEOFFSET} = {
    subProto => 'annotationSetStyleOffset(style)',
    sciProto => 'SCI_ANNOTATIONSETSTYLEOFFSET(int style)',
};

$autogen{SCI_ANNOTATIONGETSTYLEOFFSET} = {
    subProto => 'annotationGetStyleOffset() => int',
    sciProto => 'SCI_ANNOTATIONGETSTYLEOFFSET => int',
};

=back

=head2 Other settings




=over

=item setBufferedDraw

=item getBufferedDraw

    editor->setBufferedDraw($buffered);
    editor->getBufferedDraw();

Is drawing done first into a buffer or direct to the screen?

See Scintilla documentation for  L<SCI_GETBUFFEREDDRAW|https://www.scintilla.org/ScintillaDoc.html#SCI_GETBUFFEREDDRAW>

See Scintilla documentation for  L<SCI_SETBUFFEREDDRAW|https://www.scintilla.org/ScintillaDoc.html#SCI_SETBUFFEREDDRAW>

=cut

$autogen{SCI_GETBUFFEREDDRAW} = {
    subProto => 'getBufferedDraw() => bool',
    sciProto => 'SCI_GETBUFFEREDDRAW => bool',
};

$autogen{SCI_SETBUFFEREDDRAW} = {
    subProto => 'setBufferedDraw(buffered)',
    sciProto => 'SCI_SETBUFFEREDDRAW(bool buffered)',
};

=item setPhasesDraw

=item getPhasesDraw

    editor->setPhasesDraw($phases);
    editor->getPhasesDraw;

Changes the sequence of drawing a text area, to trade off speed of drawing and allowing all pixels to be seen.

Use $phases from L<%SC_PHASES|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_PHASES">.


See Scintilla documentation for  L<SCI_SETPHASESDRAW|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPHASESDRAW>

See Scintilla documentation for  L<SCI_GETPHASESDRAW|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPHASESDRAW>

=cut

$autogen{SCI_SETPHASESDRAW} = {
    subProto => 'setPhasesDraw(phases)',
    sciProto => 'SCI_SETPHASESDRAW(int phases)',
};

$autogen{SCI_GETPHASESDRAW} = {
    subProto => 'getPhasesDraw',
    sciProto => 'SCI_GETPHASESDRAW => int',
};

=item setTechnology

=item getTechnology

    editor->setTechnology($technology);
    editor->getTechnology();

Set the video card and driver technology used (whether or not to use DirectDraw API).  In Windows XP and earlier, only the default video technology is available.

Use $technology from L<%SC_TECHNOLOGY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_TECHNOLOGY">.

See Scintilla documentation for  L<SCI_SETTECHNOLOGY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTECHNOLOGY>

See Scintilla documentation for  L<SCI_GETTECHNOLOGY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTECHNOLOGY>

=cut

$autogen{SCI_SETTECHNOLOGY} = {
    subProto => 'setTechnology(technology)',
    sciProto => 'SCI_SETTECHNOLOGY(int technology)',
};

$autogen{SCI_GETTECHNOLOGY} = {
    subProto => 'getTechnology() => int',
    sciProto => 'SCI_GETTECHNOLOGY => int',
};

=item setFontQuality

=item getFontQuality

    editor->setFontQuality($fontQuality);
    editor->getFontQuality();

Choose the quality level (antialiasing method) for text.

Use $fontQuality from L<%SC_FONTQUAL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FONTQUAL">.

See Scintilla documentation for  L<SCI_SETFONTQUALITY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFONTQUALITY>

See Scintilla documentation for  L<SCI_GETFONTQUALITY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFONTQUALITY>

=cut

$autogen{SCI_SETFONTQUALITY} = {
    subProto => 'setFontQuality(fontQuality)',
    sciProto => 'SCI_SETFONTQUALITY(int fontQuality)',
};

$autogen{SCI_GETFONTQUALITY} = {
    subProto => 'getFontQuality() => int',
    sciProto => 'SCI_GETFONTQUALITY => int',
};

=item setCodePage

=item getCodePage

    editor->setCodePage($codePage);
    editor->getCodePage();

Set the code page used to interpret the bytes of the document as characters.

Scintilla supports UTF-8, Japanese, Chinese and Korean DBCS along with single byte encodings like Latin-1. UTF-8 (SC_CP_UTF8) is the default. Use this message with codePage set to the code page number to set Scintilla to use code page information to ensure multiple byte characters are treated as one character rather than multiple. This also stops the caret from moving between the bytes in a multi-byte character. Do not use this message to choose between different single byte character sets - use L</styleSetCharacterSet> for that. Call with $codePage set to zero to disable multi-byte support.

Use $codePage from L<%SC_CODEPAGE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CODEPAGE">,
or use a valid multibyte-codepage value.


See Scintilla documentation for  L<SCI_SETCODEPAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCODEPAGE>

See Scintilla documentation for  L<SCI_GETCODEPAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCODEPAGE>

=cut

$autogen{SCI_SETCODEPAGE} = {
    subProto => 'setCodePage(codePage)',
    sciProto => 'SCI_SETCODEPAGE(int codePage)',
};

$autogen{SCI_GETCODEPAGE} = {
    subProto => 'getCodePage() => int',
    sciProto => 'SCI_GETCODEPAGE => int',
};

=item setIMEInteraction

=item getIMEInteraction

    editor->setIMEInteraction($imeInteraction);
    editor->getIMEInteraction;

Sets or retrieves the Input Method Editor (IME) for Chinese, Japanese, and Korean text.

Use $imeInteraction from L<%SC_IME|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_IME">.

See Scintilla documentation for  L<SCI_SETIMEINTERACTION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETIMEINTERACTION>

See Scintilla documentation for  L<SCI_GETIMEINTERACTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETIMEINTERACTION>

=cut

$autogen{SCI_SETIMEINTERACTION} = {
    subProto => 'setIMEInteraction(imeInteraction)',
    sciProto => 'SCI_SETIMEINTERACTION(int imeInteraction)',
};

$autogen{SCI_GETIMEINTERACTION} = {
    subProto => 'getIMEInteraction',
    sciProto => 'SCI_GETIMEINTERACTION => int',
};

=item setBirdirectional

    editor->setBirdirectional($bidirectional);

=item getBidirectional

    editor->getBidirectional;

Per Scintilla, these features are experimental and incomplete.  They are used to be able to mix LTR and RTL languages.

Use $bidirectional from L<%SC_BIDIRECTIONAL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_BIDIRECTIONAL">.

The default C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_DISABLED}> (0) means that only one direction is supported.

Enabling C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_L2R}> (1) means that left-to-right is the normal active direction, but UTF sequences can change text to right-to-left.

Enabling C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_R2L}> (2) means that right-to-left is the normal active direction, but UTF sequences can change text to left-to-right.

You may also need to use L</setTechnology> to a DirectWrite option.

See Scintilla documentation for  L<SCI_SETBIDIRECTIONAL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETBIDIRECTIONAL>

See Scintilla documentation for  L<SCI_GETBIDIRECTIONAL|https://www.scintilla.org/ScintillaDoc.html#SCI_GETBIDIRECTIONAL>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETBIDIRECTIONAL} = {
    subProto => 'setBirdirectional(bidirectional)',
    sciProto => 'SCI_SETBIDIRECTIONAL(int bidirectional)',
};


$autogen{SCI_GETBIDIRECTIONAL} = {
    subProto => 'getBidirectional',
    sciProto => 'SCI_GETBIDIRECTIONAL => int',
};

=item grabFocus

    editor->grabFocus();

Set the focus to this Scintilla widget.

See Scintilla documentation for  L<SCI_GRABFOCUS|https://www.scintilla.org/ScintillaDoc.html#SCI_GRABFOCUS>

=cut

$autogen{SCI_GRABFOCUS} = {
    subProto => 'grabFocus()',
    sciProto => 'SCI_GRABFOCUS',
};

=item setFocus

=item getFocus

    editor->setFocus($focus);
    editor->getFocus();

Change internal focus flag.

See Scintilla documentation for  L<SCI_SETFOCUS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOCUS>

See Scintilla documentation for  L<SCI_GETFOCUS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFOCUS>

=cut

$autogen{SCI_SETFOCUS} = {
    subProto => 'setFocus(focus)',
    sciProto => 'SCI_SETFOCUS(bool focus)',
};

$autogen{SCI_GETFOCUS} = {
    subProto => 'getFocus() => bool',
    sciProto => 'SCI_GETFOCUS => bool',
};

=back

=head2 Brace highlighting




=over

=item braceHighlight

    editor->braceHighlight($pos1, $pos2);

Highlight the characters at two positions.

See Scintilla documentation for  L<SCI_BRACEHIGHLIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_BRACEHIGHLIGHT>

=cut

$autogen{SCI_BRACEHIGHLIGHT} = {
    subProto => 'braceHighlight(pos1, pos2)',
    sciProto => 'SCI_BRACEHIGHLIGHT(position posA, position posB)',
};

=item braceBadLight

    editor->braceBadLight($pos);

Highlight the character at a position indicating there is no matching brace.

See Scintilla documentation for  L<SCI_BRACEBADLIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_BRACEBADLIGHT>

=cut

$autogen{SCI_BRACEBADLIGHT} = {
    subProto => 'braceBadLight(pos)',
    sciProto => 'SCI_BRACEBADLIGHT(position pos)',
};

=item braceHighlightIndicator

    editor->braceHighlightIndicator($useBraceHighlightIndicator, $indicator);

Use specified indicator to highlight matching braces instead of changing their style.

See Scintilla documentation for  L<SCI_BRACEHIGHLIGHTINDICATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_BRACEHIGHLIGHTINDICATOR>

=cut

$autogen{SCI_BRACEHIGHLIGHTINDICATOR} = {
    subProto => 'braceHighlightIndicator(useBraceHighlightIndicator, indicator)',
    sciProto => 'SCI_BRACEHIGHLIGHTINDICATOR(bool useSetting, int indicator)',
};

=item braceBadLightIndicator

    editor->braceBadLightIndicator($useBraceBadLightIndicator, $indicator);

Use specified indicator to highlight non matching brace instead of changing its style.

See Scintilla documentation for  L<SCI_BRACEBADLIGHTINDICATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_BRACEBADLIGHTINDICATOR>

=cut

$autogen{SCI_BRACEBADLIGHTINDICATOR} = {
    subProto => 'braceBadLightIndicator(useBraceBadLightIndicator, indicator)',
    sciProto => 'SCI_BRACEBADLIGHTINDICATOR(bool useSetting, int indicator)',
};

=item braceMatch

    editor->braceMatch($pos);

Find the position of a matching brace or INVALID_POSITION if no match.

See Scintilla documentation for  L<SCI_BRACEMATCH|https://www.scintilla.org/ScintillaDoc.html#SCI_BRACEMATCH>

=cut

$autogen{SCI_BRACEMATCH} = {
    subProto => 'braceMatch(pos) => int',
    sciProto => 'SCI_BRACEMATCH(position pos, int maxReStyle) => position',
};

=back

=head2 Tabs and Indentation Guides




=over

=item setTabWidth

=item getTabWidth

    editor->setTabWidth($tabWidth);
    editor->getTabWidth();

Change the visible size of a tab to be a multiple of the width of a space character.

See Scintilla documentation for  L<SCI_SETTABWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTABWIDTH>

See Scintilla documentation for  L<SCI_GETTABWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTABWIDTH>

=cut

$autogen{SCI_SETTABWIDTH} = {
    subProto => 'setTabWidth(tabWidth)',
    sciProto => 'SCI_SETTABWIDTH(int tabWidth)',
};

$autogen{SCI_GETTABWIDTH} = {
    subProto => 'getTabWidth() => int',
    sciProto => 'SCI_GETTABWIDTH => int',
};

=item clearTabStops

    editor->clearTabStops($line);

Clears explicit tab stops on the indicated C<$line>.

See Scintilla documentation for  L<SCI_CLEARTABSTOPS|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARTABSTOPS>

=cut

$autogen{SCI_CLEARTABSTOPS} = {
    subProto => 'clearTabStops(line)',
    sciProto => 'SCI_CLEARTABSTOPS(line line)',
};

=item addTabStop

    editor->addTabStop($line, $pixel);

Adds an explicit tab stop on the indicated C<$line> at the indicated column C<$pixel>.

See Scintilla documentation for  L<SCI_ADDTABSTOP|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDTABSTOP>

=cut

$autogen{SCI_ADDTABSTOP} = {
    subProto => 'addTabStop(line, x)',
    sciProto => 'SCI_ADDTABSTOP(line line, int x)',
};

=item getNextTabStop

    editor->getNextTabStop($line, $pixel);

Finds the next explicit tab stop on the indicated C<$line> after the indicated column <$pixel>.

See Scintilla documentation for  L<SCI_GETNEXTTABSTOP|https://www.scintilla.org/ScintillaDoc.html#SCI_GETNEXTTABSTOP>

=cut

$autogen{SCI_GETNEXTTABSTOP} = {
    subProto => 'getNextTabStop(line, x)',
    sciProto => 'SCI_GETNEXTTABSTOP(line line, int x) => int',
};

=item setUseTabs

=item getUseTabs

    editor->setUseTabs($useTabs);
    editor->getUseTabs();

Indentation will only use space characters if useTabs is false, otherwise it will use a combination of tabs and spaces.

See Scintilla documentation for  L<SCI_SETUSETABS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETUSETABS>

See Scintilla documentation for  L<SCI_GETUSETABS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETUSETABS>

=cut

$autogen{SCI_SETUSETABS} = {
    subProto => 'setUseTabs(useTabs)',
    sciProto => 'SCI_SETUSETABS(bool useTabs)',
};

$autogen{SCI_GETUSETABS} = {
    subProto => 'getUseTabs() => bool',
    sciProto => 'SCI_GETUSETABS => bool',
};

=item setIndent

=item getIndent

    editor->setIndent($indentSize);
    editor->getIndent();

Set the number of spaces used for one level of indentation.

See Scintilla documentation for  L<SCI_SETINDENT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETINDENT>

See Scintilla documentation for  L<SCI_GETINDENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETINDENT>

=cut

$autogen{SCI_SETINDENT} = {
    subProto => 'setIndent(indentSize)',
    sciProto => 'SCI_SETINDENT(int indentSize)',
};

$autogen{SCI_GETINDENT} = {
    subProto => 'getIndent() => int',
    sciProto => 'SCI_GETINDENT => int',
};

=item setTabIndents

=item getTabIndents

    editor->setTabIndents($tabIndents);
    editor->getTabIndents();

Sets whether a tab pressed when caret is within indentation indents.

See Scintilla documentation for  L<SCI_SETTABINDENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETTABINDENTS>

See Scintilla documentation for  L<SCI_GETTABINDENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETTABINDENTS>

=cut

$autogen{SCI_SETTABINDENTS} = {
    subProto => 'setTabIndents(tabIndents)',
    sciProto => 'SCI_SETTABINDENTS(bool tabIndents)',
};

$autogen{SCI_GETTABINDENTS} = {
    subProto => 'getTabIndents() => bool',
    sciProto => 'SCI_GETTABINDENTS => bool',
};

=item setBackSpaceUnIndents

=item getBackSpaceUnIndents

    editor->setBackSpaceUnIndents($bsUnIndents);
    editor->getBackSpaceUnIndents();

Sets whether a backspace pressed when caret is within indentation unindents.

See Scintilla documentation for  L<SCI_SETBACKSPACEUNINDENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETBACKSPACEUNINDENTS>

See Scintilla documentation for  L<SCI_GETBACKSPACEUNINDENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETBACKSPACEUNINDENTS>

=cut

$autogen{SCI_SETBACKSPACEUNINDENTS} = {
    subProto => 'setBackSpaceUnIndents(bsUnIndents)',
    sciProto => 'SCI_SETBACKSPACEUNINDENTS(bool bsUnIndents)',
};

$autogen{SCI_GETBACKSPACEUNINDENTS} = {
    subProto => 'getBackSpaceUnIndents() => bool',
    sciProto => 'SCI_GETBACKSPACEUNINDENTS => bool',
};

=item setLineIndentation

=item getLineIndentation

    editor->setLineIndentation($line, $indentSize);
    editor->getLineIndentation($line);

Change the indentation of a line to a number of columns.

See Scintilla documentation for  L<SCI_SETLINEINDENTATION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLINEINDENTATION>

See Scintilla documentation for  L<SCI_GETLINEINDENTATION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEINDENTATION>

=cut

$autogen{SCI_SETLINEINDENTATION} = {
    subProto => 'setLineIndentation(line, indentSize)',
    sciProto => 'SCI_SETLINEINDENTATION(line line, int indentation)',
};

$autogen{SCI_GETLINEINDENTATION} = {
    subProto => 'getLineIndentation(line) => int',
    sciProto => 'SCI_GETLINEINDENTATION(line line) => int',
};

=item getLineIndentPosition

    editor->getLineIndentPosition($line);

Retrieve the position before the first non indentation character on a line.

See Scintilla documentation for  L<SCI_GETLINEINDENTPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEINDENTPOSITION>

=cut

$autogen{SCI_GETLINEINDENTPOSITION} = {
    subProto => 'getLineIndentPosition(line) => int',
    sciProto => 'SCI_GETLINEINDENTPOSITION(line line) => position',
};

=item setIndentationGuides

=item getIndentationGuides

    editor->setIndentationGuides($indentView);
    editor->getIndentationGuides();

Show or hide indentation guides.

Use $indentView from L<%SC_INDENTGUIDE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_INDENTGUIDE">

See Scintilla documentation for  L<SCI_SETINDENTATIONGUIDES|https://www.scintilla.org/ScintillaDoc.html#SCI_SETINDENTATIONGUIDES>

See Scintilla documentation for  L<SCI_GETINDENTATIONGUIDES|https://www.scintilla.org/ScintillaDoc.html#SCI_GETINDENTATIONGUIDES>

=cut

$autogen{SCI_SETINDENTATIONGUIDES} = {
    subProto => 'setIndentationGuides(indentView)',
    sciProto => 'SCI_SETINDENTATIONGUIDES(int indentView)',
};

$autogen{SCI_GETINDENTATIONGUIDES} = {
    subProto => 'getIndentationGuides() => int',
    sciProto => 'SCI_GETINDENTATIONGUIDES => int',
};

=item setHighlightGuide

=item getHighlightGuide

    editor->setHighlightGuide($column);
    editor->getHighlightGuide();

Set the highlighted indentation guide column. 0 = no highlighted guide.

See Scintilla documentation for  L<SCI_SETHIGHLIGHTGUIDE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETHIGHLIGHTGUIDE>

See Scintilla documentation for  L<SCI_GETHIGHLIGHTGUIDE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETHIGHLIGHTGUIDE>

=cut

$autogen{SCI_SETHIGHLIGHTGUIDE} = {
    subProto => 'setHighlightGuide(column)',
    sciProto => 'SCI_SETHIGHLIGHTGUIDE(position column)',
};

$autogen{SCI_GETHIGHLIGHTGUIDE} = {
    subProto => 'getHighlightGuide() => int',
    sciProto => 'SCI_GETHIGHLIGHTGUIDE => position',
};

=back

=head2 Markers

Scintilla allows for 32 markers, numbered 0 to
L<$SC_MARGIN{MARKER_MAX}|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARGIN">.
Scintilla reserves marker numbers 25 to 31 for use in code-folding; these are the other keys defined in
L<%SC_MARGIN|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARGIN">.
Numbers 0 to 24 are available for use, though Notepad++ or its plugins may be using
some already.  The $markerNumber listed in these methods should be in that range, or use
one of the predefined values.

=over

=item markerDefine

    editor->markerDefine($markerNumber, $markerSymbol);

Set the symbol used for a particular marker number.

Use $markerSymbol from L<%SC_MARK|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MARK">.

See Scintilla documentation for  L<SCI_MARKERDEFINE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDEFINE>

=cut

$autogen{SCI_MARKERDEFINE} = {
    subProto => 'markerDefine(markerNumber, markerSymbol)',
    sciProto => 'SCI_MARKERDEFINE(int markerNumber, int markerSymbol)',
};

=item markerDefinePixmap

    editor->markerDefinePixmap($markerNumber, $pixmap);

Define a marker from a pixmap.

See Scintilla documentation for  L<SCI_MARKERDEFINEPIXMAP|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDEFINEPIXMAP>

=cut

$autogen{SCI_MARKERDEFINEPIXMAP} = {
    subProto => 'markerDefinePixmap(markerNumber, pixmap)',
    sciProto => 'SCI_MARKERDEFINEPIXMAP(int markerNumber, const char *pixmap)',
};

=item rGBAImageSetWidth

    editor->rGBAImageSetWidth($width);

Set the width for future RGBA image data.

See Scintilla documentation for  L<SCI_RGBAIMAGESETWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_RGBAIMAGESETWIDTH>

=cut

$autogen{SCI_RGBAIMAGESETWIDTH} = {
    subProto => 'rGBAImageSetWidth(width)',
    sciProto => 'SCI_RGBAIMAGESETWIDTH(int width)',
};

=item rGBAImageSetHeight

    editor->rGBAImageSetHeight($height);

Set the height for future RGBA image data.

See Scintilla documentation for  L<SCI_RGBAIMAGESETHEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_RGBAIMAGESETHEIGHT>

=cut

$autogen{SCI_RGBAIMAGESETHEIGHT} = {
    subProto => 'rGBAImageSetHeight(height)',
    sciProto => 'SCI_RGBAIMAGESETHEIGHT(int height)',
};

=item rGBAImageSetScale

    editor->rGBAImageSetScale($scalePercent);

Set the scale factor in percent for future RGBA image data.

See Scintilla documentation for  L<SCI_RGBAIMAGESETSCALE|https://www.scintilla.org/ScintillaDoc.html#SCI_RGBAIMAGESETSCALE>

=cut

$autogen{SCI_RGBAIMAGESETSCALE} = {
    subProto => 'rGBAImageSetScale(scalePercent)',
    sciProto => 'SCI_RGBAIMAGESETSCALE(int scalePercent)',
};

=item markerDefineRGBAImage

    editor->markerDefineRGBAImage($markerNumber, $pixels);

Define a marker from RGBA data. It has the width and height from RGBAImageSetWidth/Height

See Scintilla documentation for  L<SCI_MARKERDEFINERGBAIMAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDEFINERGBAIMAGE>

=cut

$autogen{SCI_MARKERDEFINERGBAIMAGE} = {
    subProto => 'markerDefineRGBAImage(markerNumber, pixels)',
    sciProto => 'SCI_MARKERDEFINERGBAIMAGE(int markerNumber, const char *pixels)',
};

=item markerSymbolDefined

    editor->markerSymbolDefined($markerNumber);

Which symbol was defined for markerNumber with MarkerDefine

See Scintilla documentation for  L<SCI_MARKERSYMBOLDEFINED|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERSYMBOLDEFINED>

=cut

$autogen{SCI_MARKERSYMBOLDEFINED} = {
    subProto => 'markerSymbolDefined(markerNumber) => int',
    sciProto => 'SCI_MARKERSYMBOLDEFINED(int markerNumber) => int',
};

=item markerSetFore

    editor->markerSetFore($markerNumber, $fore);

Set the foreground colour used for a particular marker number.

See Scintilla documentation for  L<SCI_MARKERSETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERSETFORE>

=cut

$autogen{SCI_MARKERSETFORE} = {
    subProto => 'markerSetFore(markerNumber, fore)',
    sciProto => 'SCI_MARKERSETFORE(int markerNumber, colour fore)',
};

=item markerSetBack

    editor->markerSetBack($markerNumber, $back);

Set the background colour used for a particular marker number.

See Scintilla documentation for  L<SCI_MARKERSETBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERSETBACK>

=cut

$autogen{SCI_MARKERSETBACK} = {
    subProto => 'markerSetBack(markerNumber, back)',
    sciProto => 'SCI_MARKERSETBACK(int markerNumber, colour back)',
};

=item markerSetBackSelected

    editor->markerSetBackSelected($markerNumber, $back);

Set the background colour used for a particular marker number when its folding block is selected.

See Scintilla documentation for  L<SCI_MARKERSETBACKSELECTED|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERSETBACKSELECTED>

=cut

$autogen{SCI_MARKERSETBACKSELECTED} = {
    subProto => 'markerSetBackSelected(markerNumber, back)',
    sciProto => 'SCI_MARKERSETBACKSELECTED(int markerNumber, colour back)',
};

=item markerEnableHighlight

    editor->markerEnableHighlight($enabled);

Enable/disable highlight for current folding bloc (smallest one that contains the caret)

See Scintilla documentation for  L<SCI_MARKERENABLEHIGHLIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERENABLEHIGHLIGHT>

=cut

$autogen{SCI_MARKERENABLEHIGHLIGHT} = {
    subProto => 'markerEnableHighlight(enabled)',
    sciProto => 'SCI_MARKERENABLEHIGHLIGHT(bool enabled)',
};

=item markerSetAlpha

    editor->markerSetAlpha($markerNumber, $alpha);

Set the alpha used for a marker that is drawn in the text area, not the margin.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_MARKERSETALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERSETALPHA>

=cut

$autogen{SCI_MARKERSETALPHA} = {
    subProto => 'markerSetAlpha(markerNumber, alpha)',
    sciProto => 'SCI_MARKERSETALPHA(int markerNumber, alpha alpha)',
};

=item markerAdd

    editor->markerAdd($line, $markerNumber);

Add a marker to a line, returning an ID which can be used to find or delete the marker.

See Scintilla documentation for  L<SCI_MARKERADD|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERADD>

=cut

$autogen{SCI_MARKERADD} = {
    subProto => 'markerAdd(line, markerNumber) => int',
    sciProto => 'SCI_MARKERADD(line line, int markerNumber) => int',
};

=item markerAddSet

    editor->markerAddSet($line, $set);

Add a set of markers to a line.

See Scintilla documentation for  L<SCI_MARKERADDSET|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERADDSET>

=cut

$autogen{SCI_MARKERADDSET} = {
    subProto => 'markerAddSet(line, set)',
    sciProto => 'SCI_MARKERADDSET(line line, int markerSet)',
};

=item markerDelete

    editor->markerDelete($line, $markerNumber);

Delete a marker from a line.

See Scintilla documentation for  L<SCI_MARKERDELETE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDELETE>

=cut

$autogen{SCI_MARKERDELETE} = {
    subProto => 'markerDelete(line, markerNumber)',
    sciProto => 'SCI_MARKERDELETE(line line, int markerNumber)',
};

=item markerDeleteAll

    editor->markerDeleteAll($markerNumber);

Delete all markers with a particular number from all lines.

See Scintilla documentation for  L<SCI_MARKERDELETEALL|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDELETEALL>

=cut

$autogen{SCI_MARKERDELETEALL} = {
    subProto => 'markerDeleteAll(markerNumber)',
    sciProto => 'SCI_MARKERDELETEALL(int markerNumber)',
};

=item markerGet

    editor->markerGet($line);

Get a bit mask of all the markers set on a line.

See Scintilla documentation for  L<SCI_MARKERGET|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERGET>

=cut

$autogen{SCI_MARKERGET} = {
    subProto => 'markerGet(line) => int',
    sciProto => 'SCI_MARKERGET(line line) => int',
};

=item markerNext

    editor->markerNext($lineStart, $markerMask);

Find the next line at or after lineStart that includes a marker in mask. Return -1 when no more lines.

See Scintilla documentation for  L<SCI_MARKERNEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERNEXT>

=cut

$autogen{SCI_MARKERNEXT} = {
    subProto => 'markerNext(lineStart, markerMask) => int',
    sciProto => 'SCI_MARKERNEXT(line lineStart, int markerMask) => line',
};

=item markerPrevious

    editor->markerPrevious($lineStart, $markerMask);

Find the previous line before lineStart that includes a marker in mask.

See Scintilla documentation for  L<SCI_MARKERPREVIOUS|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERPREVIOUS>

=cut

$autogen{SCI_MARKERPREVIOUS} = {
    subProto => 'markerPrevious(lineStart, markerMask) => int',
    sciProto => 'SCI_MARKERPREVIOUS(line lineStart, int markerMask) => line',
};

=item markerLineFromHandle

    editor->markerLineFromHandle($handle);

Retrieve the line number at which a particular marker is located.

See Scintilla documentation for  L<SCI_MARKERLINEFROMHANDLE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERLINEFROMHANDLE>

=cut

$autogen{SCI_MARKERLINEFROMHANDLE} = {
    subProto => 'markerLineFromHandle(handle) => int',
    sciProto => 'SCI_MARKERLINEFROMHANDLE(int markerHandle) => int',
};

=item markerDeleteHandle

    editor->markerDeleteHandle($handle);

Delete a marker.

See Scintilla documentation for  L<SCI_MARKERDELETEHANDLE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDELETEHANDLE>

=cut

$autogen{SCI_MARKERDELETEHANDLE} = {
    subProto => 'markerDeleteHandle(handle)',
    sciProto => 'SCI_MARKERDELETEHANDLE(int markerHandle)',
};

=back

=head2 Indicators





=over

=item indicSetStyle

=item indicGetStyle

    editor->indicSetStyle($indic, $style);
    editor->indicGetStyle($indic);

Set an indicator to plain, squiggle or TT.

$style from L<%SC_INDICSTYLE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_INDICSTYLE">

See Scintilla documentation for  L<SCI_INDICSETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETSTYLE>

See Scintilla documentation for  L<SCI_INDICGETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETSTYLE>

=cut

$autogen{SCI_INDICSETSTYLE} = {
    subProto => 'indicSetStyle(indic, style)',
    sciProto => 'SCI_INDICSETSTYLE(int indicator, int indicatorStyle)',
};

$autogen{SCI_INDICGETSTYLE} = {
    subProto => 'indicGetStyle(indic) => int',
    sciProto => 'SCI_INDICGETSTYLE(int indicator) => int',
};

=item indicSetFore

=item indicGetFore

    editor->indicSetFore($indic, $fore);
    editor->indicGetFore($indic);

Set the foreground colour of an indicator.

See Scintilla documentation for  L<SCI_INDICSETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETFORE>

See Scintilla documentation for  L<SCI_INDICGETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETFORE>

=cut

$autogen{SCI_INDICSETFORE} = {
    subProto => 'indicSetFore(indic, fore)',
    sciProto => 'SCI_INDICSETFORE(int indicator, colour fore)',
};

$autogen{SCI_INDICGETFORE} = {
    subProto => 'indicGetFore(indic) => tuple',
    sciProto => 'SCI_INDICGETFORE(int indicator) => colour',
};

=item indicSetAlpha

=item indicGetAlpha

    editor->indicSetAlpha($indicator, $alpha);
    editor->indicGetAlpha($indicator);

Set the alpha fill colour of the given indicator.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_INDICSETALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETALPHA>

See Scintilla documentation for  L<SCI_INDICGETALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETALPHA>

=cut

$autogen{SCI_INDICSETALPHA} = {
    subProto => 'indicSetAlpha(indicator, alpha)',
    sciProto => 'SCI_INDICSETALPHA(int indicator, alpha alpha)',
};

$autogen{SCI_INDICGETALPHA} = {
    subProto => 'indicGetAlpha(indicator) => int',
    sciProto => 'SCI_INDICGETALPHA(int indicator) => int',
};

=item indicSetOutlineAlpha

=item indicGetOutlineAlpha

    editor->indicSetOutlineAlpha($indicator, $alpha);
    editor->indicGetOutlineAlpha($indicator);

Set the alpha outline colour of the given indicator.

The value for $alpha must be one of the predefined
L<%SC_ALPHA|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ALPHA">
values, or any integer between C<$SC_ALPHA{SC_ALPHA_TRANSPARENT}> and
C<$SC_ALPHA{SC_ALPHA_OPAQUE}>, inclusive.

See Scintilla documentation for  L<SCI_INDICSETOUTLINEALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETOUTLINEALPHA>

See Scintilla documentation for  L<SCI_INDICGETOUTLINEALPHA|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETOUTLINEALPHA>

=cut

$autogen{SCI_INDICSETOUTLINEALPHA} = {
    subProto => 'indicSetOutlineAlpha(indicator, alpha)',
    sciProto => 'SCI_INDICSETOUTLINEALPHA(int indicator, alpha alpha)',
};

$autogen{SCI_INDICGETOUTLINEALPHA} = {
    subProto => 'indicGetOutlineAlpha(indicator) => int',
    sciProto => 'SCI_INDICGETOUTLINEALPHA(int indicator) => int',
};

=item indicSetUnder

=item indicGetUnder

    editor->indicSetUnder($indic, $under);
    editor->indicGetUnder($indic);

Set an indicator to draw under text or over(default).

See Scintilla documentation for  L<SCI_INDICSETUNDER|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETUNDER>

See Scintilla documentation for  L<SCI_INDICGETUNDER|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETUNDER>

=cut

$autogen{SCI_INDICSETUNDER} = {
    subProto => 'indicSetUnder(indic, under)',
    sciProto => 'SCI_INDICSETUNDER(int indicator, bool under)',
};

$autogen{SCI_INDICGETUNDER} = {
    subProto => 'indicGetUnder(indic) => bool',
    sciProto => 'SCI_INDICGETUNDER(int indicator) => bool',
};

=item indicSetHoverStyle

=item indicGetHoverStyle

    editor->indicSetHoverStyle($indicator, $indicatorStyle);
    editor->indicGetHoverStyle($indicator);

=item indicSetHoverFore

=item indicGetHoverFore

    editor->indicSetHoverFore($indicator, $foreground);
    editor->indicGetHoverFore($indicator);

Used to set or get the style or foreground color used when the mouse cursor is hovering over a piece of text.

See Scintilla documentation for  L<SCI_INDICSETHOVERSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETHOVERSTYLE>

See Scintilla documentation for  L<SCI_INDICGETHOVERSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETHOVERSTYLE>
See Scintilla documentation for  L<SCI_INDICSETHOVERFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETHOVERFORE>

See Scintilla documentation for  L<SCI_INDICGETHOVERFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETHOVERFORE>

=cut

$autogen{SCI_INDICSETHOVERSTYLE} = {
    subProto => 'indicSetHoverStyle(indicator, indicatorStyle)',
    sciProto => 'SCI_INDICSETHOVERSTYLE(int indicator, int indicatorStyle)',
};

$autogen{SCI_INDICGETHOVERSTYLE} = {
    subProto => 'indicGetHoverStyle(indicator)',
    sciProto => 'SCI_INDICGETHOVERSTYLE(int indicator) => int',
};

$autogen{SCI_INDICSETHOVERFORE} = {
    subProto => 'indicSetHoverFore(indicator, fore)',
    sciProto => 'SCI_INDICSETHOVERFORE(int indicator, colour fore)',
};

$autogen{SCI_INDICGETHOVERFORE} = {
    subProto => 'indicGetHoverFore(indicator)',
    sciProto => 'SCI_INDICGETHOVERFORE(int indicator) => colour',
};

=item indicSetFlags

=item indicGetFlags

    editor->indicSetFlags($indicator, $flags);
    editor->indicGetFlags($indicator);

Sets or retrieves the flags for a particular indicator.

Use $flags from L<%SC_INDIC|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_INDIC">

See Scintilla documentation for  L<SCI_INDICSETFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICSETFLAGS>

See Scintilla documentation for  L<SCI_INDICGETFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICGETFLAGS>

=cut

$autogen{SCI_INDICSETFLAGS} = {
    subProto => 'indicSetFlags(indicator, flags)',
    sciProto => 'SCI_INDICSETFLAGS(int indicator, int flags)',
};

$autogen{SCI_INDICGETFLAGS} = {
    subProto => 'indicGetFlags(indicator)',
    sciProto => 'SCI_INDICGETFLAGS(int indicator) => int',
};

=item setIndicatorCurrent

=item getIndicatorCurrent

    editor->setIndicatorCurrent($indicator);
    editor->getIndicatorCurrent();

Set the indicator used for IndicatorFillRange and IndicatorClearRange

See Scintilla documentation for  L<SCI_SETINDICATORCURRENT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETINDICATORCURRENT>

See Scintilla documentation for  L<SCI_GETINDICATORCURRENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETINDICATORCURRENT>

=cut

$autogen{SCI_SETINDICATORCURRENT} = {
    subProto => 'setIndicatorCurrent(indicator)',
    sciProto => 'SCI_SETINDICATORCURRENT(int indicator)',
};

$autogen{SCI_GETINDICATORCURRENT} = {
    subProto => 'getIndicatorCurrent() => int',
    sciProto => 'SCI_GETINDICATORCURRENT => int',
};

=item setIndicatorValue

=item getIndicatorValue

    editor->setIndicatorValue($value);
    editor->getIndicatorValue();

Set the value used for IndicatorFillRange

Use $value as a 24-bit RGB color, ored with C<$SC_INDIC{SC_INDICVALUEBIT}> from L<%SC_INDIC|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_INDIC">.
To extract just the color from the C<getIndicatorValue()> call, mask it with C<$SC_INDIC{SC_INDICVALUEMASK}>.

See Scintilla documentation for  L<SCI_SETINDICATORVALUE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETINDICATORVALUE>

See Scintilla documentation for  L<SCI_GETINDICATORVALUE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETINDICATORVALUE>

=cut

$autogen{SCI_SETINDICATORVALUE} = {
    subProto => 'setIndicatorValue(value)',
    sciProto => 'SCI_SETINDICATORVALUE(int value)',
};

$autogen{SCI_GETINDICATORVALUE} = {
    subProto => 'getIndicatorValue() => int',
    sciProto => 'SCI_GETINDICATORVALUE => int',
};

=item indicatorFillRange

    editor->indicatorFillRange($position, $fillLength);

Turn a indicator on over a range.

See Scintilla documentation for  L<SCI_INDICATORFILLRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATORFILLRANGE>

=cut

$autogen{SCI_INDICATORFILLRANGE} = {
    subProto => 'indicatorFillRange(position, fillLength)',
    sciProto => 'SCI_INDICATORFILLRANGE(position start, position lengthFill)',
};

=item indicatorClearRange

    editor->indicatorClearRange($position, $clearLength);

Turn a indicator off over a range.

See Scintilla documentation for  L<SCI_INDICATORCLEARRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATORCLEARRANGE>

=cut

$autogen{SCI_INDICATORCLEARRANGE} = {
    subProto => 'indicatorClearRange(position, clearLength)',
    sciProto => 'SCI_INDICATORCLEARRANGE(position start, position lengthClear)',
};

=item indicatorAllOnFor

    editor->indicatorAllOnFor($position);

Are any indicators present at position?

See Scintilla documentation for  L<SCI_INDICATORALLONFOR|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATORALLONFOR>

=cut

$autogen{SCI_INDICATORALLONFOR} = {
    subProto => 'indicatorAllOnFor(position) => int',
    sciProto => 'SCI_INDICATORALLONFOR(position pos) => int',
};

=item indicatorValueAt

    editor->indicatorValueAt($indicator, $position);

What value does a particular indicator have at at a position?

See Scintilla documentation for  L<SCI_INDICATORVALUEAT|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATORVALUEAT>

=cut

$autogen{SCI_INDICATORVALUEAT} = {
    subProto => 'indicatorValueAt(indicator, position) => int',
    sciProto => 'SCI_INDICATORVALUEAT(int indicator, position pos) => int',
};

=item indicatorStart

    editor->indicatorStart($indicator, $position);

Where does a particular indicator start?

See Scintilla documentation for  L<SCI_INDICATORSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATORSTART>

=cut

$autogen{SCI_INDICATORSTART} = {
    subProto => 'indicatorStart(indicator, position) => int',
    sciProto => 'SCI_INDICATORSTART(int indicator, position pos) => int',
};

=item indicatorEnd

    editor->indicatorEnd($indicator, $position);

Where does a particular indicator end?

See Scintilla documentation for  L<SCI_INDICATOREND|https://www.scintilla.org/ScintillaDoc.html#SCI_INDICATOREND>

=cut

$autogen{SCI_INDICATOREND} = {
    subProto => 'indicatorEnd(indicator, position) => int',
    sciProto => 'SCI_INDICATOREND(int indicator, position pos) => int',
};

=item findIndicatorShow

    editor->findIndicatorShow($start, $end);

On OS X, show a find indicator.

See Scintilla documentation for  L<SCI_FINDINDICATORSHOW|https://www.scintilla.org/ScintillaDoc.html#SCI_FINDINDICATORSHOW>

=cut

$autogen{SCI_FINDINDICATORSHOW} = {
    subProto => 'findIndicatorShow(start, end)',
    sciProto => 'SCI_FINDINDICATORSHOW(position start, position end)',
};

=item findIndicatorFlash

    editor->findIndicatorFlash($start, $end);

On OS X, flash a find indicator, then fade out.

See Scintilla documentation for  L<SCI_FINDINDICATORFLASH|https://www.scintilla.org/ScintillaDoc.html#SCI_FINDINDICATORFLASH>

=cut

$autogen{SCI_FINDINDICATORFLASH} = {
    subProto => 'findIndicatorFlash(start, end)',
    sciProto => 'SCI_FINDINDICATORFLASH(position start, position end)',
};

=item findIndicatorHide

    editor->findIndicatorHide();

On OS X, hide the find indicator.

See Scintilla documentation for  L<SCI_FINDINDICATORHIDE|https://www.scintilla.org/ScintillaDoc.html#SCI_FINDINDICATORHIDE>

=cut

$autogen{SCI_FINDINDICATORHIDE} = {
    subProto => 'findIndicatorHide()',
    sciProto => 'SCI_FINDINDICATORHIDE',
};

=back

=head2 Autocompletion




=over

=item autoCShow

    editor->autoCShow($lenEntered, $itemList);

Display a auto-completion list. The lenEntered parameter indicates how many characters before the caret should be used to provide context.

See Scintilla documentation for  L<SCI_AUTOCSHOW|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSHOW>

=cut

$autogen{SCI_AUTOCSHOW} = {
    subProto => 'autoCShow(lenEntered, itemList)',
    sciProto => 'SCI_AUTOCSHOW(position lengthEntered, const char *itemList)',
};

=item autoCCancel

    editor->autoCCancel();

Remove the auto-completion list from the screen.

See Scintilla documentation for  L<SCI_AUTOCCANCEL|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCCANCEL>

=cut

$autogen{SCI_AUTOCCANCEL} = {
    subProto => 'autoCCancel()',
    sciProto => 'SCI_AUTOCCANCEL',
};

=item autoCActive

    editor->autoCActive();

Is there an auto-completion list visible?

See Scintilla documentation for  L<SCI_AUTOCACTIVE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCACTIVE>

=cut

$autogen{SCI_AUTOCACTIVE} = {
    subProto => 'autoCActive() => bool',
    sciProto => 'SCI_AUTOCACTIVE => bool',
};

=item autoCPosStart

    editor->autoCPosStart();

Retrieve the position of the caret when the auto-completion list was displayed.

See Scintilla documentation for  L<SCI_AUTOCPOSSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCPOSSTART>

=cut

$autogen{SCI_AUTOCPOSSTART} = {
    subProto => 'autoCPosStart() => int',
    sciProto => 'SCI_AUTOCPOSSTART => position',
};

=item autoCComplete

    editor->autoCComplete();

User has selected an item so remove the list and insert the selection.

See Scintilla documentation for  L<SCI_AUTOCCOMPLETE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCCOMPLETE>

=cut

$autogen{SCI_AUTOCCOMPLETE} = {
    subProto => 'autoCComplete()',
    sciProto => 'SCI_AUTOCCOMPLETE',
};

=item autoCStops

    editor->autoCStops($characterSet);

Define a set of character that when typed cancel the auto-completion list.

See Scintilla documentation for  L<SCI_AUTOCSTOPS|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSTOPS>

=cut

$autogen{SCI_AUTOCSTOPS} = {
    subProto => 'autoCStops(characterSet)',
    sciProto => 'SCI_AUTOCSTOPS(<unused>, const char *characterSet)',
};

=item autoCSetSeparator

=item autoCGetSeparator

    editor->autoCSetSeparator($separatorCharacter);
    editor->autoCGetSeparator();

Change the separator character in the string setting up an auto-completion list. Default is space but can be changed if items contain space.

See Scintilla documentation for  L<SCI_AUTOCSETSEPARATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETSEPARATOR>

See Scintilla documentation for  L<SCI_AUTOCGETSEPARATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETSEPARATOR>

=cut

$autogen{SCI_AUTOCSETSEPARATOR} = {
    subProto => 'autoCSetSeparator(separatorCharacter)',
    sciProto => 'SCI_AUTOCSETSEPARATOR(int separatorCharacter)',
};

$autogen{SCI_AUTOCGETSEPARATOR} = {
    subProto => 'autoCGetSeparator() => int',
    sciProto => 'SCI_AUTOCGETSEPARATOR => int',
};

=item autoCSelect

    editor->autoCSelect($text);

Select the item in the auto-completion list that starts with a string.

See Scintilla documentation for  L<SCI_AUTOCSELECT|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSELECT>

=cut

$autogen{SCI_AUTOCSELECT} = {
    subProto => 'autoCSelect(text)',
    sciProto => 'SCI_AUTOCSELECT(<unused>, const char *select)',
};

=item autoCGetCurrent

    editor->autoCGetCurrent();

Get currently selected item position in the auto-completion list

See Scintilla documentation for  L<SCI_AUTOCGETCURRENT|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETCURRENT>

=cut

$autogen{SCI_AUTOCGETCURRENT} = {
    subProto => 'autoCGetCurrent() => int',
    sciProto => 'SCI_AUTOCGETCURRENT => int',
};

=item autoCGetCurrentText

    editor->autoCGetCurrentText();

Get currently selected item text in the auto-completion list Returns the length of the item text

See Scintilla documentation for  L<SCI_AUTOCGETCURRENTTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETCURRENTTEXT>

=cut

$autogen{SCI_AUTOCGETCURRENTTEXT} = {
    subProto => 'autoCGetCurrentText() => str',
    sciProto => 'SCI_AUTOCGETCURRENTTEXT(<unused>, char *text) => int',
};

=item autoCSetCancelAtStart

=item autoCGetCancelAtStart

    editor->autoCSetCancelAtStart($cancel);
    editor->autoCGetCancelAtStart();

Should the auto-completion list be cancelled if the user backspaces to a position before where the box was created.

See Scintilla documentation for  L<SCI_AUTOCSETCANCELATSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETCANCELATSTART>

See Scintilla documentation for  L<SCI_AUTOCGETCANCELATSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETCANCELATSTART>

=cut

$autogen{SCI_AUTOCSETCANCELATSTART} = {
    subProto => 'autoCSetCancelAtStart(cancel)',
    sciProto => 'SCI_AUTOCSETCANCELATSTART(bool cancel)',
};

$autogen{SCI_AUTOCGETCANCELATSTART} = {
    subProto => 'autoCGetCancelAtStart() => bool',
    sciProto => 'SCI_AUTOCGETCANCELATSTART => bool',
};

=item autoCSetFillUps

    editor->autoCSetFillUps($characterSet);

Define a set of characters that when typed will cause the autocompletion to choose the selected item.

See Scintilla documentation for  L<SCI_AUTOCSETFILLUPS|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETFILLUPS>

=cut

$autogen{SCI_AUTOCSETFILLUPS} = {
    subProto => 'autoCSetFillUps(characterSet)',
    sciProto => 'SCI_AUTOCSETFILLUPS(<unused>, const char *characterSet)',
};

=item autoCSetChooseSingle

=item autoCGetChooseSingle

    editor->autoCSetChooseSingle($chooseSingle);
    editor->autoCGetChooseSingle();

Should a single item auto-completion list automatically choose the item.

See Scintilla documentation for  L<SCI_AUTOCSETCHOOSESINGLE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETCHOOSESINGLE>

See Scintilla documentation for  L<SCI_AUTOCGETCHOOSESINGLE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETCHOOSESINGLE>

=cut

$autogen{SCI_AUTOCSETCHOOSESINGLE} = {
    subProto => 'autoCSetChooseSingle(chooseSingle)',
    sciProto => 'SCI_AUTOCSETCHOOSESINGLE(bool chooseSingle)',
};

$autogen{SCI_AUTOCGETCHOOSESINGLE} = {
    subProto => 'autoCGetChooseSingle() => bool',
    sciProto => 'SCI_AUTOCGETCHOOSESINGLE => bool',
};

=item autoCSetIgnoreCase

=item autoCGetIgnoreCase

    editor->autoCSetIgnoreCase($ignoreCase);
    editor->autoCGetIgnoreCase();

Set whether case is significant when performing auto-completion searches.

See Scintilla documentation for  L<SCI_AUTOCSETIGNORECASE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETIGNORECASE>

See Scintilla documentation for  L<SCI_AUTOCGETIGNORECASE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETIGNORECASE>

=cut

$autogen{SCI_AUTOCSETIGNORECASE} = {
    subProto => 'autoCSetIgnoreCase(ignoreCase)',
    sciProto => 'SCI_AUTOCSETIGNORECASE(bool ignoreCase)',
};

$autogen{SCI_AUTOCGETIGNORECASE} = {
    subProto => 'autoCGetIgnoreCase() => bool',
    sciProto => 'SCI_AUTOCGETIGNORECASE => bool',
};

=item autoCSetCaseInsensitiveBehaviour

=item autoCGetCaseInsensitiveBehaviour

    editor->autoCSetCaseInsensitiveBehaviour($behaviour);
    editor->autoCGetCaseInsensitiveBehaviour();

Set auto-completion case insensitive behaviour to either prefer case-sensitive matches or have no preference.

Use $behavior from L<%SC_CASEINSENSITIVE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CASEINSENSITIVE">

See Scintilla documentation for  L<SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR>

See Scintilla documentation for  L<SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR>

=cut

$autogen{SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR} = {
    subProto => 'autoCSetCaseInsensitiveBehaviour(behaviour)',
    sciProto => 'SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR(int behaviour)',
};

$autogen{SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR} = {
    subProto => 'autoCGetCaseInsensitiveBehaviour() => int',
    sciProto => 'SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR => int',
};

=item autoCSetMulti

=item autoCGetMulti

    editor->autoCSetMulti($multi);
    editor->autoCGetMulti;

Determine whether the autocompletion goes into the first area of a multi-selection
or into each area of the multi-selection.

Use $multi from L<%SC_MULTIAUTOC|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MULTIAUTOC">.


See Scintilla documentation for  L<SCI_AUTOCSETMULTI|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETMULTI>

See Scintilla documentation for  L<SCI_AUTOCGETMULTI|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETMULTI>

=cut


$autogen{SCI_AUTOCSETMULTI} = {
    subProto => 'autoCSetMulti(multi)',
    sciProto => 'SCI_AUTOCSETMULTI(int multi)',
};

$autogen{SCI_AUTOCGETMULTI} = {
    subProto => 'autoCGetMulti',
    sciProto => 'SCI_AUTOCGETMULTI => int',
};

=item autoCSetOrder

=item autoCGetOrder

    editor->autoCSetOrder($order);
    editor->autoCGetOrder();

Set the way autocompletion lists are ordered.

Use $order from L<%SC_AUTOC_ORDER|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_AUTOC_ORDER">.

See Scintilla documentation for  L<SCI_AUTOCSETORDER|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETORDER>

See Scintilla documentation for  L<SCI_AUTOCGETORDER|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETORDER>

=cut

$autogen{SCI_AUTOCSETORDER} = {
    subProto => 'autoCSetOrder(order)',
    sciProto => 'SCI_AUTOCSETORDER(int order)',
};

$autogen{SCI_AUTOCGETORDER} = {
    subProto => 'autoCGetOrder() => int',
    sciProto => 'SCI_AUTOCGETORDER => int',
};

=item autoCSetAutoHide

=item autoCGetAutoHide

    editor->autoCSetAutoHide($autoHide);
    editor->autoCGetAutoHide();

Set whether or not autocompletion is hidden automatically when nothing matches.

See Scintilla documentation for  L<SCI_AUTOCSETAUTOHIDE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETAUTOHIDE>

See Scintilla documentation for  L<SCI_AUTOCGETAUTOHIDE|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETAUTOHIDE>

=cut

$autogen{SCI_AUTOCSETAUTOHIDE} = {
    subProto => 'autoCSetAutoHide(autoHide)',
    sciProto => 'SCI_AUTOCSETAUTOHIDE(bool autoHide)',
};

$autogen{SCI_AUTOCGETAUTOHIDE} = {
    subProto => 'autoCGetAutoHide() => bool',
    sciProto => 'SCI_AUTOCGETAUTOHIDE => bool',
};

=item autoCSetDropRestOfWord

=item autoCGetDropRestOfWord

    editor->autoCSetDropRestOfWord($dropRestOfWord);
    editor->autoCGetDropRestOfWord();

Set whether or not autocompletion deletes any word characters after the inserted text upon completion.

See Scintilla documentation for  L<SCI_AUTOCSETDROPRESTOFWORD|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETDROPRESTOFWORD>

See Scintilla documentation for  L<SCI_AUTOCGETDROPRESTOFWORD|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETDROPRESTOFWORD>

=cut

$autogen{SCI_AUTOCSETDROPRESTOFWORD} = {
    subProto => 'autoCSetDropRestOfWord(dropRestOfWord)',
    sciProto => 'SCI_AUTOCSETDROPRESTOFWORD(bool dropRestOfWord)',
};

$autogen{SCI_AUTOCGETDROPRESTOFWORD} = {
    subProto => 'autoCGetDropRestOfWord() => bool',
    sciProto => 'SCI_AUTOCGETDROPRESTOFWORD => bool',
};

=item registerImage

    editor->registerImage($type, $xpmData);

Register an XPM image for use in autocompletion lists.

See Scintilla documentation for  L<SCI_REGISTERIMAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_REGISTERIMAGE>

=cut

$autogen{SCI_REGISTERIMAGE} = {
    subProto => 'registerImage(type, xpmData)',
    sciProto => 'SCI_REGISTERIMAGE(int type, const char *xpmData)',
};

=item registerRGBAImage

    editor->registerRGBAImage($type, $pixels);

Register an RGBA image for use in autocompletion lists. It has the width and height from RGBAImageSetWidth/Height

See Scintilla documentation for  L<SCI_REGISTERRGBAIMAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_REGISTERRGBAIMAGE>

=cut

$autogen{SCI_REGISTERRGBAIMAGE} = {
    subProto => 'registerRGBAImage(type, pixels)',
    sciProto => 'SCI_REGISTERRGBAIMAGE(int type, const char *pixels)',
};

=item clearRegisteredImages

    editor->clearRegisteredImages();

Clear all the registered XPM images.

See Scintilla documentation for  L<SCI_CLEARREGISTEREDIMAGES|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARREGISTEREDIMAGES>

=cut

$autogen{SCI_CLEARREGISTEREDIMAGES} = {
    subProto => 'clearRegisteredImages()',
    sciProto => 'SCI_CLEARREGISTEREDIMAGES',
};

=item autoCSetTypeSeparator

=item autoCGetTypeSeparator

    editor->autoCSetTypeSeparator($separatorCharacter);
    editor->autoCGetTypeSeparator();

Retrieve the auto-completion list type-separator character.

See Scintilla documentation for  L<SCI_AUTOCGETTYPESEPARATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETTYPESEPARATOR>

See Scintilla documentation for  L<SCI_AUTOCSETTYPESEPARATOR|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETTYPESEPARATOR>

=cut

$autogen{SCI_AUTOCGETTYPESEPARATOR} = {
    subProto => 'autoCGetTypeSeparator() => int',
    sciProto => 'SCI_AUTOCGETTYPESEPARATOR => int',
};

$autogen{SCI_AUTOCSETTYPESEPARATOR} = {
    subProto => 'autoCSetTypeSeparator(separatorCharacter)',
    sciProto => 'SCI_AUTOCSETTYPESEPARATOR(int separatorCharacter)',
};

=item autoCSetMaxHeight

=item autoCGetMaxHeight

    editor->autoCSetMaxHeight($rowCount);
    editor->autoCGetMaxHeight();

Set the maximum height, in rows, of auto-completion and user lists. The default is 5 rows.

See Scintilla documentation for  L<SCI_AUTOCSETMAXHEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETMAXHEIGHT>

See Scintilla documentation for  L<SCI_AUTOCGETMAXHEIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETMAXHEIGHT>

=cut

$autogen{SCI_AUTOCSETMAXHEIGHT} = {
    subProto => 'autoCSetMaxHeight(rowCount)',
    sciProto => 'SCI_AUTOCSETMAXHEIGHT(int rowCount)',
};

$autogen{SCI_AUTOCGETMAXHEIGHT} = {
    subProto => 'autoCGetMaxHeight() => int',
    sciProto => 'SCI_AUTOCGETMAXHEIGHT => int',
};

=item autoCSetMaxWidth

=item autoCGetMaxWidth

    editor->autoCSetMaxWidth($characterCount);
    editor->autoCGetMaxWidth();

Set the maximum width, in characters, of auto-completion and user lists. Set to 0 to autosize to fit longest item, which is the default.

See Scintilla documentation for  L<SCI_AUTOCSETMAXWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCSETMAXWIDTH>

See Scintilla documentation for  L<SCI_AUTOCGETMAXWIDTH|https://www.scintilla.org/ScintillaDoc.html#SCI_AUTOCGETMAXWIDTH>

=cut

$autogen{SCI_AUTOCSETMAXWIDTH} = {
    subProto => 'autoCSetMaxWidth(characterCount)',
    sciProto => 'SCI_AUTOCSETMAXWIDTH(int characterCount)',
};

$autogen{SCI_AUTOCGETMAXWIDTH} = {
    subProto => 'autoCGetMaxWidth() => int',
    sciProto => 'SCI_AUTOCGETMAXWIDTH => int',
};

=back

=head2 User lists




=over

=item userListShow

    editor->userListShow($listType, $itemList);

Display a list of strings and send notification when user chooses one.

See Scintilla documentation for  L<SCI_USERLISTSHOW|https://www.scintilla.org/ScintillaDoc.html#SCI_USERLISTSHOW>

=cut

$autogen{SCI_USERLISTSHOW} = {
    subProto => 'userListShow(listType, itemList)',
    sciProto => 'SCI_USERLISTSHOW(int listType, const char *itemList)',
};

=back

=head2 Call tips




=over

=item callTipShow

    editor->callTipShow($pos, $definition);

Show a call tip containing a definition near position pos.

See Scintilla documentation for  L<SCI_CALLTIPSHOW|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSHOW>

=cut

$autogen{SCI_CALLTIPSHOW} = {
    subProto => 'callTipShow(pos, definition)',
    sciProto => 'SCI_CALLTIPSHOW(position pos, const char *definition)',
};

=item callTipCancel

    editor->callTipCancel();

Remove the call tip from the screen.

See Scintilla documentation for  L<SCI_CALLTIPCANCEL|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPCANCEL>

=cut

$autogen{SCI_CALLTIPCANCEL} = {
    subProto => 'callTipCancel()',
    sciProto => 'SCI_CALLTIPCANCEL',
};

=item callTipActive

    editor->callTipActive();

Is there an active call tip?

See Scintilla documentation for  L<SCI_CALLTIPACTIVE|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPACTIVE>

=cut

$autogen{SCI_CALLTIPACTIVE} = {
    subProto => 'callTipActive() => bool',
    sciProto => 'SCI_CALLTIPACTIVE => bool',
};

=item callTipPosStart

    editor->callTipPosStart();

Retrieve the position where the caret was before displaying the call tip.

See Scintilla documentation for  L<SCI_CALLTIPPOSSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPPOSSTART>

=cut

$autogen{SCI_CALLTIPPOSSTART} = {
    subProto => 'callTipPosStart() => int',
    sciProto => 'SCI_CALLTIPPOSSTART => position',
};

=item callTipSetPosStart

    editor->callTipSetPosStart($posStart);

Set the start position in order to change when backspacing removes the calltip.

See Scintilla documentation for  L<SCI_CALLTIPSETPOSSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETPOSSTART>

=cut

$autogen{SCI_CALLTIPSETPOSSTART} = {
    subProto => 'callTipSetPosStart(posStart)',
    sciProto => 'SCI_CALLTIPSETPOSSTART(position posStart)',
};

=item callTipSetHlt

    editor->callTipSetHlt($start, $end);

Highlight a segment of the definition.

See Scintilla documentation for  L<SCI_CALLTIPSETHLT|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETHLT>

=cut

$autogen{SCI_CALLTIPSETHLT} = {
    subProto => 'callTipSetHlt(start, end)',
    sciProto => 'SCI_CALLTIPSETHLT(int highlightStart, int highlightEnd)',
};

=item callTipSetBack

    editor->callTipSetBack($back);

Set the background colour for the call tip.

See Scintilla documentation for  L<SCI_CALLTIPSETBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETBACK>

=cut

$autogen{SCI_CALLTIPSETBACK} = {
    subProto => 'callTipSetBack(back)',
    sciProto => 'SCI_CALLTIPSETBACK(colour back)',
};

=item callTipSetFore

    editor->callTipSetFore($fore);

Set the foreground colour for the call tip.

See Scintilla documentation for  L<SCI_CALLTIPSETFORE|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETFORE>

=cut

$autogen{SCI_CALLTIPSETFORE} = {
    subProto => 'callTipSetFore(fore)',
    sciProto => 'SCI_CALLTIPSETFORE(colour fore)',
};

=item callTipSetForeHlt

    editor->callTipSetForeHlt($fore);

Set the foreground colour for the highlighted part of the call tip.

See Scintilla documentation for  L<SCI_CALLTIPSETFOREHLT|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETFOREHLT>

=cut

$autogen{SCI_CALLTIPSETFOREHLT} = {
    subProto => 'callTipSetForeHlt(fore)',
    sciProto => 'SCI_CALLTIPSETFOREHLT(colour fore)',
};

=item callTipUseStyle

    editor->callTipUseStyle($tabSize);

Enable use of STYLE_CALLTIP and set call tip tab size in pixels.

See Scintilla documentation for  L<SCI_CALLTIPUSESTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPUSESTYLE>

=cut

$autogen{SCI_CALLTIPUSESTYLE} = {
    subProto => 'callTipUseStyle(tabSize)',
    sciProto => 'SCI_CALLTIPUSESTYLE(int tabSize)',
};

=item callTipSetPosition

    editor->callTipSetPosition($above);

Set position of calltip, above or below text.

See Scintilla documentation for  L<SCI_CALLTIPSETPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_CALLTIPSETPOSITION>

=cut

$autogen{SCI_CALLTIPSETPOSITION} = {
    subProto => 'callTipSetPosition(above)',
    sciProto => 'SCI_CALLTIPSETPOSITION(bool above)',
};

=back

=head2 Keyboard commands





=over

=item lineDown

    editor->lineDown();

Move caret down one line.

See Scintilla documentation for  L<SCI_LINEDOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEDOWN>

=cut

$autogen{SCI_LINEDOWN} = {
    subProto => 'lineDown()',
    sciProto => 'SCI_LINEDOWN',
};

=item lineDownExtend

    editor->lineDownExtend();

Move caret down one line extending selection to new caret position.

See Scintilla documentation for  L<SCI_LINEDOWNEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEDOWNEXTEND>

=cut

$autogen{SCI_LINEDOWNEXTEND} = {
    subProto => 'lineDownExtend()',
    sciProto => 'SCI_LINEDOWNEXTEND',
};

=item lineUp

    editor->lineUp();

Move caret up one line.

See Scintilla documentation for  L<SCI_LINEUP|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEUP>

=cut

$autogen{SCI_LINEUP} = {
    subProto => 'lineUp()',
    sciProto => 'SCI_LINEUP',
};

=item lineUpExtend

    editor->lineUpExtend();

Move caret up one line extending selection to new caret position.

See Scintilla documentation for  L<SCI_LINEUPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEUPEXTEND>

=cut

$autogen{SCI_LINEUPEXTEND} = {
    subProto => 'lineUpExtend()',
    sciProto => 'SCI_LINEUPEXTEND',
};

=item charLeft

    editor->charLeft();

Move caret left one character.

See Scintilla documentation for  L<SCI_CHARLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARLEFT>

=cut

$autogen{SCI_CHARLEFT} = {
    subProto => 'charLeft()',
    sciProto => 'SCI_CHARLEFT',
};

=item charLeftExtend

    editor->charLeftExtend();

Move caret left one character extending selection to new caret position.

See Scintilla documentation for  L<SCI_CHARLEFTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARLEFTEXTEND>

=cut

$autogen{SCI_CHARLEFTEXTEND} = {
    subProto => 'charLeftExtend()',
    sciProto => 'SCI_CHARLEFTEXTEND',
};

=item charRight

    editor->charRight();

Move caret right one character.

See Scintilla documentation for  L<SCI_CHARRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARRIGHT>

=cut

$autogen{SCI_CHARRIGHT} = {
    subProto => 'charRight()',
    sciProto => 'SCI_CHARRIGHT',
};

=item charRightExtend

    editor->charRightExtend();

Move caret right one character extending selection to new caret position.

See Scintilla documentation for  L<SCI_CHARRIGHTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARRIGHTEXTEND>

=cut

$autogen{SCI_CHARRIGHTEXTEND} = {
    subProto => 'charRightExtend()',
    sciProto => 'SCI_CHARRIGHTEXTEND',
};

=item wordLeft

    editor->wordLeft();

Move caret left one word.

See Scintilla documentation for  L<SCI_WORDLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDLEFT>

=cut

$autogen{SCI_WORDLEFT} = {
    subProto => 'wordLeft()',
    sciProto => 'SCI_WORDLEFT',
};

=item wordLeftExtend

    editor->wordLeftExtend();

Move caret left one word extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDLEFTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDLEFTEXTEND>

=cut

$autogen{SCI_WORDLEFTEXTEND} = {
    subProto => 'wordLeftExtend()',
    sciProto => 'SCI_WORDLEFTEXTEND',
};

=item wordRight

    editor->wordRight();

Move caret right one word.

See Scintilla documentation for  L<SCI_WORDRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDRIGHT>

=cut

$autogen{SCI_WORDRIGHT} = {
    subProto => 'wordRight()',
    sciProto => 'SCI_WORDRIGHT',
};

=item wordRightExtend

    editor->wordRightExtend();

Move caret right one word extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDRIGHTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDRIGHTEXTEND>

=cut

$autogen{SCI_WORDRIGHTEXTEND} = {
    subProto => 'wordRightExtend()',
    sciProto => 'SCI_WORDRIGHTEXTEND',
};

=item home

    editor->home();

Move caret to first position on line.

See Scintilla documentation for  L<SCI_HOME|https://www.scintilla.org/ScintillaDoc.html#SCI_HOME>

=cut

$autogen{SCI_HOME} = {
    subProto => 'home()',
    sciProto => 'SCI_HOME',
};

=item homeExtend

    editor->homeExtend();

Move caret to first position on line extending selection to new caret position.

See Scintilla documentation for  L<SCI_HOMEEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMEEXTEND>

=cut

$autogen{SCI_HOMEEXTEND} = {
    subProto => 'homeExtend()',
    sciProto => 'SCI_HOMEEXTEND',
};

=item lineEnd

    editor->lineEnd();

Move caret to last position on line.

See Scintilla documentation for  L<SCI_LINEEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEEND>

=cut

$autogen{SCI_LINEEND} = {
    subProto => 'lineEnd()',
    sciProto => 'SCI_LINEEND',
};

=item lineEndExtend

    editor->lineEndExtend();

Move caret to last position on line extending selection to new caret position.

See Scintilla documentation for  L<SCI_LINEENDEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDEXTEND>

=cut

$autogen{SCI_LINEENDEXTEND} = {
    subProto => 'lineEndExtend()',
    sciProto => 'SCI_LINEENDEXTEND',
};

=item documentStart

    editor->documentStart();

Move caret to first position in document.

See Scintilla documentation for  L<SCI_DOCUMENTSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_DOCUMENTSTART>

=cut

$autogen{SCI_DOCUMENTSTART} = {
    subProto => 'documentStart()',
    sciProto => 'SCI_DOCUMENTSTART',
};

=item documentStartExtend

    editor->documentStartExtend();

Move caret to first position in document extending selection to new caret position.

See Scintilla documentation for  L<SCI_DOCUMENTSTARTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_DOCUMENTSTARTEXTEND>

=cut

$autogen{SCI_DOCUMENTSTARTEXTEND} = {
    subProto => 'documentStartExtend()',
    sciProto => 'SCI_DOCUMENTSTARTEXTEND',
};

=item documentEnd

    editor->documentEnd();

Move caret to last position in document.

See Scintilla documentation for  L<SCI_DOCUMENTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_DOCUMENTEND>

=cut

$autogen{SCI_DOCUMENTEND} = {
    subProto => 'documentEnd()',
    sciProto => 'SCI_DOCUMENTEND',
};

=item documentEndExtend

    editor->documentEndExtend();

Move caret to last position in document extending selection to new caret position.

See Scintilla documentation for  L<SCI_DOCUMENTENDEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_DOCUMENTENDEXTEND>

=cut

$autogen{SCI_DOCUMENTENDEXTEND} = {
    subProto => 'documentEndExtend()',
    sciProto => 'SCI_DOCUMENTENDEXTEND',
};

=item pageUp

    editor->pageUp();

Move caret one page up.

See Scintilla documentation for  L<SCI_PAGEUP|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEUP>

=cut

$autogen{SCI_PAGEUP} = {
    subProto => 'pageUp()',
    sciProto => 'SCI_PAGEUP',
};

=item pageUpExtend

    editor->pageUpExtend();

Move caret one page up extending selection to new caret position.

See Scintilla documentation for  L<SCI_PAGEUPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEUPEXTEND>

=cut

$autogen{SCI_PAGEUPEXTEND} = {
    subProto => 'pageUpExtend()',
    sciProto => 'SCI_PAGEUPEXTEND',
};

=item pageDown

    editor->pageDown();

Move caret one page down.

See Scintilla documentation for  L<SCI_PAGEDOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEDOWN>

=cut

$autogen{SCI_PAGEDOWN} = {
    subProto => 'pageDown()',
    sciProto => 'SCI_PAGEDOWN',
};

=item pageDownExtend

    editor->pageDownExtend();

Move caret one page down extending selection to new caret position.

See Scintilla documentation for  L<SCI_PAGEDOWNEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEDOWNEXTEND>

=cut

$autogen{SCI_PAGEDOWNEXTEND} = {
    subProto => 'pageDownExtend()',
    sciProto => 'SCI_PAGEDOWNEXTEND',
};

=item editToggleOvertype

    editor->editToggleOvertype();

Switch from insert to overtype mode or the reverse.

See Scintilla documentation for  L<SCI_EDITTOGGLEOVERTYPE|https://www.scintilla.org/ScintillaDoc.html#SCI_EDITTOGGLEOVERTYPE>

=cut

$autogen{SCI_EDITTOGGLEOVERTYPE} = {
    subProto => 'editToggleOvertype()',
    sciProto => 'SCI_EDITTOGGLEOVERTYPE',
};

=item cancel

    editor->cancel();

Cancel any modes such as call tip or auto-completion list display.

See Scintilla documentation for  L<SCI_CANCEL|https://www.scintilla.org/ScintillaDoc.html#SCI_CANCEL>

=cut

$autogen{SCI_CANCEL} = {
    subProto => 'cancel()',
    sciProto => 'SCI_CANCEL',
};

=item deleteBack

    editor->deleteBack();

Delete the selection or if no selection, the character before the caret.

See Scintilla documentation for  L<SCI_DELETEBACK|https://www.scintilla.org/ScintillaDoc.html#SCI_DELETEBACK>

=cut

$autogen{SCI_DELETEBACK} = {
    subProto => 'deleteBack()',
    sciProto => 'SCI_DELETEBACK',
};

=item tab

    editor->tab();

If selection is empty or all on one line replace the selection with a tab character. If more than one line selected, indent the lines.

See Scintilla documentation for  L<SCI_TAB|https://www.scintilla.org/ScintillaDoc.html#SCI_TAB>

=cut

$autogen{SCI_TAB} = {
    subProto => 'tab()',
    sciProto => 'SCI_TAB',
};

=item backTab

    editor->backTab();

Dedent the selected lines.

See Scintilla documentation for  L<SCI_BACKTAB|https://www.scintilla.org/ScintillaDoc.html#SCI_BACKTAB>

=cut

$autogen{SCI_BACKTAB} = {
    subProto => 'backTab()',
    sciProto => 'SCI_BACKTAB',
};

=item newLine

    editor->newLine();

Insert a new line, may use a CRLF, CR or LF depending on EOL mode.

See Scintilla documentation for  L<SCI_NEWLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_NEWLINE>

=cut

$autogen{SCI_NEWLINE} = {
    subProto => 'newLine()',
    sciProto => 'SCI_NEWLINE',
};

=item formFeed

    editor->formFeed();

Insert a Form Feed character.

See Scintilla documentation for  L<SCI_FORMFEED|https://www.scintilla.org/ScintillaDoc.html#SCI_FORMFEED>

=cut

$autogen{SCI_FORMFEED} = {
    subProto => 'formFeed()',
    sciProto => 'SCI_FORMFEED',
};

=item vCHome

    editor->vCHome();

Move caret to before first visible character on line. If already there move to first character on line.

See Scintilla documentation for  L<SCI_VCHOME|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOME>

=cut

$autogen{SCI_VCHOME} = {
    subProto => 'vCHome()',
    sciProto => 'SCI_VCHOME',
};

=item vCHomeExtend

    editor->vCHomeExtend();

Like VCHome but extending selection to new caret position.

See Scintilla documentation for  L<SCI_VCHOMEEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMEEXTEND>

=cut

$autogen{SCI_VCHOMEEXTEND} = {
    subProto => 'vCHomeExtend()',
    sciProto => 'SCI_VCHOMEEXTEND',
};

=item delWordLeft

    editor->delWordLeft();

Delete the word to the left of the caret.

See Scintilla documentation for  L<SCI_DELWORDLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_DELWORDLEFT>

=cut

$autogen{SCI_DELWORDLEFT} = {
    subProto => 'delWordLeft()',
    sciProto => 'SCI_DELWORDLEFT',
};

=item delWordRight

    editor->delWordRight();

Delete the word to the right of the caret.

See Scintilla documentation for  L<SCI_DELWORDRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_DELWORDRIGHT>

=cut

$autogen{SCI_DELWORDRIGHT} = {
    subProto => 'delWordRight()',
    sciProto => 'SCI_DELWORDRIGHT',
};

=item delWordRightEnd

    editor->delWordRightEnd();

Delete the word to the right of the caret, but not the trailing non-word characters.

See Scintilla documentation for  L<SCI_DELWORDRIGHTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_DELWORDRIGHTEND>

=cut

$autogen{SCI_DELWORDRIGHTEND} = {
    subProto => 'delWordRightEnd()',
    sciProto => 'SCI_DELWORDRIGHTEND',
};

=item lineCut

    editor->lineCut();

Cut the line containing the caret.

See Scintilla documentation for  L<SCI_LINECUT|https://www.scintilla.org/ScintillaDoc.html#SCI_LINECUT>

=cut

$autogen{SCI_LINECUT} = {
    subProto => 'lineCut()',
    sciProto => 'SCI_LINECUT',
};

=item lineDelete

    editor->lineDelete();

Delete the line containing the caret.

See Scintilla documentation for  L<SCI_LINEDELETE|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEDELETE>

=cut

$autogen{SCI_LINEDELETE} = {
    subProto => 'lineDelete()',
    sciProto => 'SCI_LINEDELETE',
};

=item lineTranspose

    editor->lineTranspose();

Switch the current line with the previous.

See Scintilla documentation for  L<SCI_LINETRANSPOSE|https://www.scintilla.org/ScintillaDoc.html#SCI_LINETRANSPOSE>

=cut

$autogen{SCI_LINETRANSPOSE} = {
    subProto => 'lineTranspose()',
    sciProto => 'SCI_LINETRANSPOSE',
};

=item lineReverse

    editor->lineReverse();

Reverse the current line.

See Scintilla documentation for  L<SCI_LINEREVERSE|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEREVERSE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_LINEREVERSE} = {
    subProto => 'lineReverse()',
    sciProto => 'SCI_LINEREVERSE',
};

=item lineDuplicate

    editor->lineDuplicate();

Duplicate the current line.

See Scintilla documentation for  L<SCI_LINEDUPLICATE|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEDUPLICATE>

=cut

$autogen{SCI_LINEDUPLICATE} = {
    subProto => 'lineDuplicate()',
    sciProto => 'SCI_LINEDUPLICATE',
};

=item lowerCase

    editor->lowerCase();

Transform the selection to lower case.

See Scintilla documentation for  L<SCI_LOWERCASE|https://www.scintilla.org/ScintillaDoc.html#SCI_LOWERCASE>

=cut

$autogen{SCI_LOWERCASE} = {
    subProto => 'lowerCase()',
    sciProto => 'SCI_LOWERCASE',
};

=item upperCase

    editor->upperCase();

Transform the selection to upper case.

See Scintilla documentation for  L<SCI_UPPERCASE|https://www.scintilla.org/ScintillaDoc.html#SCI_UPPERCASE>

=cut

$autogen{SCI_UPPERCASE} = {
    subProto => 'upperCase()',
    sciProto => 'SCI_UPPERCASE',
};

=item lineScrollDown

    editor->lineScrollDown();

Scroll the document down, keeping the caret visible.

See Scintilla documentation for  L<SCI_LINESCROLLDOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESCROLLDOWN>

=cut

$autogen{SCI_LINESCROLLDOWN} = {
    subProto => 'lineScrollDown()',
    sciProto => 'SCI_LINESCROLLDOWN',
};

=item lineScrollUp

    editor->lineScrollUp();

Scroll the document up, keeping the caret visible.

See Scintilla documentation for  L<SCI_LINESCROLLUP|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESCROLLUP>

=cut

$autogen{SCI_LINESCROLLUP} = {
    subProto => 'lineScrollUp()',
    sciProto => 'SCI_LINESCROLLUP',
};

=item deleteBackNotLine

    editor->deleteBackNotLine();

Delete the selection or if no selection, the character before the caret. Will not delete the character before at the start of a line.

See Scintilla documentation for  L<SCI_DELETEBACKNOTLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_DELETEBACKNOTLINE>

=cut

$autogen{SCI_DELETEBACKNOTLINE} = {
    subProto => 'deleteBackNotLine()',
    sciProto => 'SCI_DELETEBACKNOTLINE',
};

=item homeDisplay

    editor->homeDisplay();

Move caret to first position on display line.

See Scintilla documentation for  L<SCI_HOMEDISPLAY|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMEDISPLAY>

=cut

$autogen{SCI_HOMEDISPLAY} = {
    subProto => 'homeDisplay()',
    sciProto => 'SCI_HOMEDISPLAY',
};

=item homeDisplayExtend

    editor->homeDisplayExtend();

Move caret to first position on display line extending selection to new caret position.

See Scintilla documentation for  L<SCI_HOMEDISPLAYEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMEDISPLAYEXTEND>

=cut

$autogen{SCI_HOMEDISPLAYEXTEND} = {
    subProto => 'homeDisplayExtend()',
    sciProto => 'SCI_HOMEDISPLAYEXTEND',
};

=item lineEndDisplay

    editor->lineEndDisplay();

Move caret to last position on display line.

See Scintilla documentation for  L<SCI_LINEENDDISPLAY|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDDISPLAY>

=cut

$autogen{SCI_LINEENDDISPLAY} = {
    subProto => 'lineEndDisplay()',
    sciProto => 'SCI_LINEENDDISPLAY',
};

=item lineEndDisplayExtend

    editor->lineEndDisplayExtend();

Move caret to last position on display line extending selection to new caret position.

See Scintilla documentation for  L<SCI_LINEENDDISPLAYEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDDISPLAYEXTEND>

=cut

$autogen{SCI_LINEENDDISPLAYEXTEND} = {
    subProto => 'lineEndDisplayExtend()',
    sciProto => 'SCI_LINEENDDISPLAYEXTEND',
};

=item homeWrap

    editor->homeWrap();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_HOMEWRAP|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMEWRAP>

=cut

$autogen{SCI_HOMEWRAP} = {
    subProto => 'homeWrap()',
    sciProto => 'SCI_HOMEWRAP',
};

=item homeWrapExtend

    editor->homeWrapExtend();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_HOMEWRAPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMEWRAPEXTEND>

=cut

$autogen{SCI_HOMEWRAPEXTEND} = {
    subProto => 'homeWrapExtend()',
    sciProto => 'SCI_HOMEWRAPEXTEND',
};

=item lineEndWrap

    editor->lineEndWrap();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_LINEENDWRAP|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDWRAP>

=cut

$autogen{SCI_LINEENDWRAP} = {
    subProto => 'lineEndWrap()',
    sciProto => 'SCI_LINEENDWRAP',
};

=item lineEndWrapExtend

    editor->lineEndWrapExtend();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_LINEENDWRAPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDWRAPEXTEND>

=cut

$autogen{SCI_LINEENDWRAPEXTEND} = {
    subProto => 'lineEndWrapExtend()',
    sciProto => 'SCI_LINEENDWRAPEXTEND',
};

=item vCHomeWrap

    editor->vCHomeWrap();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_VCHOMEWRAP|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMEWRAP>

=cut

$autogen{SCI_VCHOMEWRAP} = {
    subProto => 'vCHomeWrap()',
    sciProto => 'SCI_VCHOMEWRAP',
};

=item vCHomeWrapExtend

    editor->vCHomeWrapExtend();

These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)? except they behave differently when word-wrap is enabled: They go first to the start / end of the display line, like (Home|LineEnd)Display The difference is that, the cursor is already at the point, it goes on to the start or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

See Scintilla documentation for  L<SCI_VCHOMEWRAPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMEWRAPEXTEND>

=cut

$autogen{SCI_VCHOMEWRAPEXTEND} = {
    subProto => 'vCHomeWrapExtend()',
    sciProto => 'SCI_VCHOMEWRAPEXTEND',
};

=item lineCopy

    editor->lineCopy();

Copy the line containing the caret.

See Scintilla documentation for  L<SCI_LINECOPY|https://www.scintilla.org/ScintillaDoc.html#SCI_LINECOPY>

=cut

$autogen{SCI_LINECOPY} = {
    subProto => 'lineCopy()',
    sciProto => 'SCI_LINECOPY',
};

=item wordPartLeft

    editor->wordPartLeft();

Move to the previous change in capitalisation.

See Scintilla documentation for  L<SCI_WORDPARTLEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDPARTLEFT>

=cut

$autogen{SCI_WORDPARTLEFT} = {
    subProto => 'wordPartLeft()',
    sciProto => 'SCI_WORDPARTLEFT',
};

=item wordPartLeftExtend

    editor->wordPartLeftExtend();

Move to the previous change in capitalisation extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDPARTLEFTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDPARTLEFTEXTEND>

=cut

$autogen{SCI_WORDPARTLEFTEXTEND} = {
    subProto => 'wordPartLeftExtend()',
    sciProto => 'SCI_WORDPARTLEFTEXTEND',
};

=item wordPartRight

    editor->wordPartRight();

Move to the change next in capitalisation.

See Scintilla documentation for  L<SCI_WORDPARTRIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDPARTRIGHT>

=cut

$autogen{SCI_WORDPARTRIGHT} = {
    subProto => 'wordPartRight()',
    sciProto => 'SCI_WORDPARTRIGHT',
};

=item wordPartRightExtend

    editor->wordPartRightExtend();

Move to the next change in capitalisation extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDPARTRIGHTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDPARTRIGHTEXTEND>

=cut

$autogen{SCI_WORDPARTRIGHTEXTEND} = {
    subProto => 'wordPartRightExtend()',
    sciProto => 'SCI_WORDPARTRIGHTEXTEND',
};

=item delLineLeft

    editor->delLineLeft();

Delete back from the current position to the start of the line.

See Scintilla documentation for  L<SCI_DELLINELEFT|https://www.scintilla.org/ScintillaDoc.html#SCI_DELLINELEFT>

=cut

$autogen{SCI_DELLINELEFT} = {
    subProto => 'delLineLeft()',
    sciProto => 'SCI_DELLINELEFT',
};

=item delLineRight

    editor->delLineRight();

Delete forwards from the current position to the end of the line.

See Scintilla documentation for  L<SCI_DELLINERIGHT|https://www.scintilla.org/ScintillaDoc.html#SCI_DELLINERIGHT>

=cut

$autogen{SCI_DELLINERIGHT} = {
    subProto => 'delLineRight()',
    sciProto => 'SCI_DELLINERIGHT',
};

=item paraDown

    editor->paraDown();

Move caret between paragraphs (delimited by empty lines).

See Scintilla documentation for  L<SCI_PARADOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_PARADOWN>

=cut

$autogen{SCI_PARADOWN} = {
    subProto => 'paraDown()',
    sciProto => 'SCI_PARADOWN',
};

=item paraDownExtend

    editor->paraDownExtend();

Move caret between paragraphs (delimited by empty lines).

See Scintilla documentation for  L<SCI_PARADOWNEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PARADOWNEXTEND>

=cut

$autogen{SCI_PARADOWNEXTEND} = {
    subProto => 'paraDownExtend()',
    sciProto => 'SCI_PARADOWNEXTEND',
};

=item paraUp

    editor->paraUp();

Move caret between paragraphs (delimited by empty lines).

See Scintilla documentation for  L<SCI_PARAUP|https://www.scintilla.org/ScintillaDoc.html#SCI_PARAUP>

=cut

$autogen{SCI_PARAUP} = {
    subProto => 'paraUp()',
    sciProto => 'SCI_PARAUP',
};

=item paraUpExtend

    editor->paraUpExtend();

Move caret between paragraphs (delimited by empty lines).

See Scintilla documentation for  L<SCI_PARAUPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PARAUPEXTEND>

=cut

$autogen{SCI_PARAUPEXTEND} = {
    subProto => 'paraUpExtend()',
    sciProto => 'SCI_PARAUPEXTEND',
};

=item lineDownRectExtend

    editor->lineDownRectExtend();

Move caret down one line, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_LINEDOWNRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEDOWNRECTEXTEND>

=cut

$autogen{SCI_LINEDOWNRECTEXTEND} = {
    subProto => 'lineDownRectExtend()',
    sciProto => 'SCI_LINEDOWNRECTEXTEND',
};

=item lineUpRectExtend

    editor->lineUpRectExtend();

Move caret up one line, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_LINEUPRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEUPRECTEXTEND>

=cut

$autogen{SCI_LINEUPRECTEXTEND} = {
    subProto => 'lineUpRectExtend()',
    sciProto => 'SCI_LINEUPRECTEXTEND',
};

=item charLeftRectExtend

    editor->charLeftRectExtend();

Move caret left one character, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_CHARLEFTRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARLEFTRECTEXTEND>

=cut

$autogen{SCI_CHARLEFTRECTEXTEND} = {
    subProto => 'charLeftRectExtend()',
    sciProto => 'SCI_CHARLEFTRECTEXTEND',
};

=item charRightRectExtend

    editor->charRightRectExtend();

Move caret right one character, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_CHARRIGHTRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_CHARRIGHTRECTEXTEND>

=cut

$autogen{SCI_CHARRIGHTRECTEXTEND} = {
    subProto => 'charRightRectExtend()',
    sciProto => 'SCI_CHARRIGHTRECTEXTEND',
};

=item homeRectExtend

    editor->homeRectExtend();

Move caret to first position on line, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_HOMERECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_HOMERECTEXTEND>

=cut

$autogen{SCI_HOMERECTEXTEND} = {
    subProto => 'homeRectExtend()',
    sciProto => 'SCI_HOMERECTEXTEND',
};

=item vCHomeRectExtend

    editor->vCHomeRectExtend();

Move caret to before first visible character on line. If already there move to first character on line. In either case, extend rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_VCHOMERECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMERECTEXTEND>

=cut

$autogen{SCI_VCHOMERECTEXTEND} = {
    subProto => 'vCHomeRectExtend()',
    sciProto => 'SCI_VCHOMERECTEXTEND',
};

=item lineEndRectExtend

    editor->lineEndRectExtend();

Move caret to last position on line, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_LINEENDRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_LINEENDRECTEXTEND>

=cut

$autogen{SCI_LINEENDRECTEXTEND} = {
    subProto => 'lineEndRectExtend()',
    sciProto => 'SCI_LINEENDRECTEXTEND',
};

=item pageUpRectExtend

    editor->pageUpRectExtend();

Move caret one page up, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_PAGEUPRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEUPRECTEXTEND>

=cut

$autogen{SCI_PAGEUPRECTEXTEND} = {
    subProto => 'pageUpRectExtend()',
    sciProto => 'SCI_PAGEUPRECTEXTEND',
};

=item pageDownRectExtend

    editor->pageDownRectExtend();

Move caret one page down, extending rectangular selection to new caret position.

See Scintilla documentation for  L<SCI_PAGEDOWNRECTEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_PAGEDOWNRECTEXTEND>

=cut

$autogen{SCI_PAGEDOWNRECTEXTEND} = {
    subProto => 'pageDownRectExtend()',
    sciProto => 'SCI_PAGEDOWNRECTEXTEND',
};

=item stutteredPageUp

    editor->stutteredPageUp();

Move caret to top of page, or one page up if already at top of page.

See Scintilla documentation for  L<SCI_STUTTEREDPAGEUP|https://www.scintilla.org/ScintillaDoc.html#SCI_STUTTEREDPAGEUP>

=cut

$autogen{SCI_STUTTEREDPAGEUP} = {
    subProto => 'stutteredPageUp()',
    sciProto => 'SCI_STUTTEREDPAGEUP',
};

=item stutteredPageUpExtend

    editor->stutteredPageUpExtend();

Move caret to top of page, or one page up if already at top of page, extending selection to new caret position.

See Scintilla documentation for  L<SCI_STUTTEREDPAGEUPEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_STUTTEREDPAGEUPEXTEND>

=cut

$autogen{SCI_STUTTEREDPAGEUPEXTEND} = {
    subProto => 'stutteredPageUpExtend()',
    sciProto => 'SCI_STUTTEREDPAGEUPEXTEND',
};

=item stutteredPageDown

    editor->stutteredPageDown();

Move caret to bottom of page, or one page down if already at bottom of page.

See Scintilla documentation for  L<SCI_STUTTEREDPAGEDOWN|https://www.scintilla.org/ScintillaDoc.html#SCI_STUTTEREDPAGEDOWN>

=cut

$autogen{SCI_STUTTEREDPAGEDOWN} = {
    subProto => 'stutteredPageDown()',
    sciProto => 'SCI_STUTTEREDPAGEDOWN',
};

=item stutteredPageDownExtend

    editor->stutteredPageDownExtend();

Move caret to bottom of page, or one page down if already at bottom of page, extending selection to new caret position.

See Scintilla documentation for  L<SCI_STUTTEREDPAGEDOWNEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_STUTTEREDPAGEDOWNEXTEND>

=cut

$autogen{SCI_STUTTEREDPAGEDOWNEXTEND} = {
    subProto => 'stutteredPageDownExtend()',
    sciProto => 'SCI_STUTTEREDPAGEDOWNEXTEND',
};

=item wordLeftEnd

    editor->wordLeftEnd();

Move caret left one word, position cursor at end of word.

See Scintilla documentation for  L<SCI_WORDLEFTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDLEFTEND>

=cut

$autogen{SCI_WORDLEFTEND} = {
    subProto => 'wordLeftEnd()',
    sciProto => 'SCI_WORDLEFTEND',
};

=item wordLeftEndExtend

    editor->wordLeftEndExtend();

Move caret left one word, position cursor at end of word, extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDLEFTENDEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDLEFTENDEXTEND>

=cut

$autogen{SCI_WORDLEFTENDEXTEND} = {
    subProto => 'wordLeftEndExtend()',
    sciProto => 'SCI_WORDLEFTENDEXTEND',
};

=item wordRightEnd

    editor->wordRightEnd();

Move caret right one word, position cursor at end of word.

See Scintilla documentation for  L<SCI_WORDRIGHTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDRIGHTEND>

=cut

$autogen{SCI_WORDRIGHTEND} = {
    subProto => 'wordRightEnd()',
    sciProto => 'SCI_WORDRIGHTEND',
};

=item wordRightEndExtend

    editor->wordRightEndExtend();

Move caret right one word, position cursor at end of word, extending selection to new caret position.

See Scintilla documentation for  L<SCI_WORDRIGHTENDEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_WORDRIGHTENDEXTEND>

=cut

$autogen{SCI_WORDRIGHTENDEXTEND} = {
    subProto => 'wordRightEndExtend()',
    sciProto => 'SCI_WORDRIGHTENDEXTEND',
};

=item selectionDuplicate

    editor->selectionDuplicate();

Duplicate the selection. If selection empty duplicate the line containing the caret.

See Scintilla documentation for  L<SCI_SELECTIONDUPLICATE|https://www.scintilla.org/ScintillaDoc.html#SCI_SELECTIONDUPLICATE>

=cut

$autogen{SCI_SELECTIONDUPLICATE} = {
    subProto => 'selectionDuplicate()',
    sciProto => 'SCI_SELECTIONDUPLICATE',
};

=item verticalCentreCaret

    editor->verticalCentreCaret();

Centre current line in window.

See Scintilla documentation for  L<SCI_VERTICALCENTRECARET|https://www.scintilla.org/ScintillaDoc.html#SCI_VERTICALCENTRECARET>

=cut

$autogen{SCI_VERTICALCENTRECARET} = {
    subProto => 'verticalCentreCaret()',
    sciProto => 'SCI_VERTICALCENTRECARET',
};

=item scrollToStart

    editor->scrollToStart();

Scroll to start of document.

See Scintilla documentation for  L<SCI_SCROLLTOSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_SCROLLTOSTART>

=cut

$autogen{SCI_SCROLLTOSTART} = {
    subProto => 'scrollToStart()',
    sciProto => 'SCI_SCROLLTOSTART',
};

=item scrollToEnd

    editor->scrollToEnd();

Scroll to end of document.

See Scintilla documentation for  L<SCI_SCROLLTOEND|https://www.scintilla.org/ScintillaDoc.html#SCI_SCROLLTOEND>

=cut

$autogen{SCI_SCROLLTOEND} = {
    subProto => 'scrollToEnd()',
    sciProto => 'SCI_SCROLLTOEND',
};

=item vCHomeDisplay

    editor->vCHomeDisplay();

Move caret to before first visible character on display line. If already there move to first character on display line.

See Scintilla documentation for  L<SCI_VCHOMEDISPLAY|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMEDISPLAY>

=cut

$autogen{SCI_VCHOMEDISPLAY} = {
    subProto => 'vCHomeDisplay()',
    sciProto => 'SCI_VCHOMEDISPLAY',
};

=item vCHomeDisplayExtend

    editor->vCHomeDisplayExtend();

Like VCHomeDisplay but extending selection to new caret position.

See Scintilla documentation for  L<SCI_VCHOMEDISPLAYEXTEND|https://www.scintilla.org/ScintillaDoc.html#SCI_VCHOMEDISPLAYEXTEND>

=cut

$autogen{SCI_VCHOMEDISPLAYEXTEND} = {
    subProto => 'vCHomeDisplayExtend()',
    sciProto => 'SCI_VCHOMEDISPLAYEXTEND',
};

=back

=head2 Key bindings

These methods affect keybindings (keyboard shortcuts), and all make use of the
from L<%SC_KEY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_KEY"> hash values.

For normal keys (letters, numbers, punctuation), the $km ("key+modifier") code is the
codepoint for that character.  For special keys (arrows, Escape, and similar), use the
C<$SC_KEY{SCK_*}> entry for that key.  If you want to indicate a modified key, add on
the C<$SC_KEY{SCK_*}> shifted 16 bits up.

    # Ctrl+HOME being assigned to SCI_HOME
    my $km_ctrl_home = $SC_KEY{SCK_HOME} + ($SC_KEY{SCMOD_CTRL}<<16);
    notepad->assignCmdKey($km_alt_q, $SCIMSG{SCI_HOME});

    # Alt+Q being assigned to SCI_SELECTALL
    my $km_alt_q = ord('Q') + ($SC_KEY{SCMOD_ALT}<<16);
    notepad->assignCmdKey($km_alt_q, $SCIMSG{SCI_SELECTALL});

=over

=item assignCmdKey

    editor->assignCmdKey($km, $msg);

When key+modifier combination km is pressed perform msg.

See Scintilla documentation for  L<SCI_ASSIGNCMDKEY|https://www.scintilla.org/ScintillaDoc.html#SCI_ASSIGNCMDKEY>

=cut

$autogen{SCI_ASSIGNCMDKEY} = {
    subProto => 'assignCmdKey(km, msg)',
    sciProto => 'SCI_ASSIGNCMDKEY(int keyDefinition, int sciCommand)',
};

=item clearCmdKey

    editor->clearCmdKey($km);

When key+modifier combination km is pressed do nothing.

See Scintilla documentation for  L<SCI_CLEARCMDKEY|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARCMDKEY>

=cut

$autogen{SCI_CLEARCMDKEY} = {
    subProto => 'clearCmdKey(km)',
    sciProto => 'SCI_CLEARCMDKEY(int keyDefinition)',
};

=item clearAllCmdKeys

    editor->clearAllCmdKeys();

Drop all key mappings.

See Scintilla documentation for  L<SCI_CLEARALLCMDKEYS|https://www.scintilla.org/ScintillaDoc.html#SCI_CLEARALLCMDKEYS>

=cut

$autogen{SCI_CLEARALLCMDKEYS} = {
    subProto => 'clearAllCmdKeys()',
    sciProto => 'SCI_CLEARALLCMDKEYS',
};

=item null

    editor->null();

Null operation.

See Scintilla documentation for  L<SCI_NULL|https://www.scintilla.org/ScintillaDoc.html#SCI_NULL>

=cut

$autogen{SCI_NULL} = {
    subProto => 'null()',
    sciProto => 'SCI_NULL',
};

=back

=head2 Popup edit menu




=over

=item usePopUp

    editor->usePopUp($allowPopUp);

Set whether a pop up menu is displayed automatically when the user presses the wrong mouse button.

Use $allowPopUp from L<%SC_POPUP|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%SC_POPUP>.

See Scintilla documentation for  L<SCI_USEPOPUP|https://www.scintilla.org/ScintillaDoc.html#SCI_USEPOPUP>

=cut

$autogen{SCI_USEPOPUP} = {
    subProto => 'usePopUp(allowPopUp)',
    sciProto => 'SCI_USEPOPUP(int popUpMode)',
};

=back

=head2 Macro recording




=over

=item startRecord

    editor->startRecord();

Start notifying the container of all key presses and commands.

See Scintilla documentation for  L<SCI_STARTRECORD|https://www.scintilla.org/ScintillaDoc.html#SCI_STARTRECORD>

=cut

$autogen{SCI_STARTRECORD} = {
    subProto => 'startRecord()',
    sciProto => 'SCI_STARTRECORD',
};

=item stopRecord

    editor->stopRecord();

Stop notifying the container of all key presses and commands.

See Scintilla documentation for  L<SCI_STOPRECORD|https://www.scintilla.org/ScintillaDoc.html#SCI_STOPRECORD>

=cut

$autogen{SCI_STOPRECORD} = {
    subProto => 'stopRecord()',
    sciProto => 'SCI_STOPRECORD',
};

=back

=head2





=over


=back

=head2 Printing




=over

=item TODO: formatRange

NOT YET IMPLEMENTED

Might not be in the initial release

See Scintilla documentation for  L<SCI_FORMATRANGE|https://www.scintilla.org/ScintillaDoc.html#SCI_FORMATRANGE>

=cut

#$autogen{SCI_FORMATRANGE} = {
#    subProto => 'formatRange',
#    sciProto => 'SCI_FORMATRANGE(bool draw, Sci_RangeToFormat *fr) => position',
#};

sub formatRange {
    my $self = shift;
    warnings::warn qq|%s->formatRange(): not yet implemented.|, ref($self);
}

=item setPrintMagnification

=item getPrintMagnification

    editor->setPrintMagnification($magnification);
    editor->getPrintMagnification();

Sets the print magnification added to the point size of each style for printing.

See Scintilla documentation for  L<SCI_SETPRINTMAGNIFICATION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPRINTMAGNIFICATION>

See Scintilla documentation for  L<SCI_GETPRINTMAGNIFICATION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPRINTMAGNIFICATION>

=cut

$autogen{SCI_SETPRINTMAGNIFICATION} = {
    subProto => 'setPrintMagnification(magnification)',
    sciProto => 'SCI_SETPRINTMAGNIFICATION(int magnification)',
};

$autogen{SCI_GETPRINTMAGNIFICATION} = {
    subProto => 'getPrintMagnification() => int',
    sciProto => 'SCI_GETPRINTMAGNIFICATION => int',
};

=item setPrintColourMode

=item getPrintColourMode

    editor->setPrintColourMode($mode);
    editor->getPrintColourMode();

Modify colours when printing for clearer printed text.

Use $mode from L<%SC_PRINTCOLOURMODE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_PRINTCOLOURMODE">.


See Scintilla documentation for  L<SCI_SETPRINTCOLOURMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPRINTCOLOURMODE>

See Scintilla documentation for  L<SCI_GETPRINTCOLOURMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPRINTCOLOURMODE>

=cut

$autogen{SCI_SETPRINTCOLOURMODE} = {
    subProto => 'setPrintColourMode(mode)',
    sciProto => 'SCI_SETPRINTCOLOURMODE(int mode)',
};

$autogen{SCI_GETPRINTCOLOURMODE} = {
    subProto => 'getPrintColourMode() => int',
    sciProto => 'SCI_GETPRINTCOLOURMODE => int',
};

=item setPrintWrapMode

=item getPrintWrapMode

    editor->setPrintWrapMode($mode);
    editor->getPrintWrapMode();

Set printing to line wrapped (SC_WRAP_WORD) or not line wrapped (SC_WRAP_NONE).

See Scintilla documentation for  L<SCI_SETPRINTWRAPMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPRINTWRAPMODE>

See Scintilla documentation for  L<SCI_GETPRINTWRAPMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPRINTWRAPMODE>

=cut

$autogen{SCI_SETPRINTWRAPMODE} = {
    subProto => 'setPrintWrapMode(mode)',
    sciProto => 'SCI_SETPRINTWRAPMODE(int wrapMode)',
};

$autogen{SCI_GETPRINTWRAPMODE} = {
    subProto => 'getPrintWrapMode() => int',
    sciProto => 'SCI_GETPRINTWRAPMODE => int',
};

=back

=head2 Direct access




=over

=item getDirectFunction

    editor->getDirectFunction();

Retrieve a pointer to a function that processes messages for this Scintilla.

See Scintilla documentation for  L<SCI_GETDIRECTFUNCTION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETDIRECTFUNCTION>

=cut

$autogen{SCI_GETDIRECTFUNCTION} = {
    subProto => 'getDirectFunction() => int',
    sciProto => 'SCI_GETDIRECTFUNCTION => pointer',
};

=item getDirectPointer

    editor->getDirectPointer();

Retrieve a pointer value to use as the first argument when calling the function returned by GetDirectFunction.

See Scintilla documentation for  L<SCI_GETDIRECTPOINTER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETDIRECTPOINTER>

=cut

$autogen{SCI_GETDIRECTPOINTER} = {
    subProto => 'getDirectPointer() => int',
    sciProto => 'SCI_GETDIRECTPOINTER => pointer',
};

=item getCharacterPointer

    editor->getCharacterPointer();

Gets a copy of the text of the document, without first allowing Scintilla to make its copy of it. In practice, that means it does exactly the same as C<editor-E<gt>getText>, however, if you have the possibility of the user interfering with the document _whilst_ getCharacterPointer() is running, then it’s safer to use getText(). On larger documents, getCharacterPointer() could be noticable quicker.

See Scintilla documentation for  L<SCI_GETCHARACTERPOINTER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCHARACTERPOINTER>

=cut

$autogen{SCI_GETCHARACTERPOINTER} = {
    subProto => 'getCharacterPointer() => str',
    sciProto => 'SCI_GETCHARACTERPOINTER => pointer',
};

=item getRangePointer

    editor->getRangePointer($start, $lengthRange);

Provides direct access to the range requested.

See Scintilla documentation for  L<SCI_GETRANGEPOINTER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETRANGEPOINTER>

=cut

$autogen{SCI_GETRANGEPOINTER} = {
    subProto => 'getRangePointer(start, lengthRange)',
    sciProto => 'SCI_GETRANGEPOINTER(position start, position lengthRange) => pointer',
};

=item getGapPosition

    editor->getGapPosition();

Return a position which, to avoid performance costs, should not be within the range of a call to GetRangePointer.

See Scintilla documentation for  L<SCI_GETGAPPOSITION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETGAPPOSITION>

=cut

$autogen{SCI_GETGAPPOSITION} = {
    subProto => 'getGapPosition() => int',
    sciProto => 'SCI_GETGAPPOSITION => position',
};

=back

=head2 Multiple views




=over

=item setDocPointer

=item getDocPointer

    editor->setDocPointer($pointer);
    editor->getDocPointer();

Retrieve a pointer to the document object.

See Scintilla documentation for  L<SCI_GETDOCPOINTER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETDOCPOINTER>

See Scintilla documentation for  L<SCI_SETDOCPOINTER|https://www.scintilla.org/ScintillaDoc.html#SCI_SETDOCPOINTER>

=cut

$autogen{SCI_GETDOCPOINTER} = {
    subProto => 'getDocPointer() => int',
    sciProto => 'SCI_GETDOCPOINTER => pointer',
};

$autogen{SCI_SETDOCPOINTER} = {
    subProto => 'setDocPointer(pointer)',
    sciProto => 'SCI_SETDOCPOINTER(<unused>, pointer doc)',
};

=item createDocument

    editor->createDocument();

Create a new document object. Starts with reference count of 1 and not selected into editor.

Use $documentOptions from L<%SC_DOCUMENTOPTIONS|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/%SC_DOCUMENTOPTIONS>.

See Scintilla documentation for  L<SCI_CREATEDOCUMENT|https://www.scintilla.org/ScintillaDoc.html#SCI_CREATEDOCUMENT>

=cut

$autogen{SCI_CREATEDOCUMENT} = {
    subProto => 'createDocument() => int',
    sciProto => 'SCI_CREATEDOCUMENT(position bytes, int documentOptions) => pointer',
};

=item addRefDocument

    editor->addRefDocument($doc);

Extend life of document.

See Scintilla documentation for  L<SCI_ADDREFDOCUMENT|https://www.scintilla.org/ScintillaDoc.html#SCI_ADDREFDOCUMENT>

=cut

$autogen{SCI_ADDREFDOCUMENT} = {
    subProto => 'addRefDocument(doc)',
    sciProto => 'SCI_ADDREFDOCUMENT(<unused>, pointer doc)',
};

=item releaseDocument

    editor->releaseDocument($doc);

Release a reference to the document, deleting document if it fades to black.

See Scintilla documentation for  L<SCI_RELEASEDOCUMENT|https://www.scintilla.org/ScintillaDoc.html#SCI_RELEASEDOCUMENT>

=cut

$autogen{SCI_RELEASEDOCUMENT} = {
    subProto => 'releaseDocument(doc)',
    sciProto => 'SCI_RELEASEDOCUMENT(<unused>, pointer doc)',
};

=item getDocumentOptions

    editor->getDocumentOptions;

Returns the options that were used to create the document.

See Scintilla documentation for  L<SCI_GETDOCUMENTOPTIONS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETDOCUMENTOPTIONS>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_GETDOCUMENTOPTIONS} = {
    subProto => 'getDocumentOptions',
    sciProto => 'SCI_GETDOCUMENTOPTIONS => int',
};

=back

=head2 Background loading and saving




=over

=item createLoader

    editor->createLoader($bytes);

Create an ILoader*.

See Scintilla documentation for  L<SCI_CREATELOADER|https://www.scintilla.org/ScintillaDoc.html#SCI_CREATELOADER>

=cut

$autogen{SCI_CREATELOADER} = {
    subProto => 'createLoader(bytes) => int',
    sciProto => 'SCI_CREATELOADER(position bytes, int documentOptions) => pointer',
};

=back

=head2 Folding




=over

=item visibleFromDocLine

    editor->visibleFromDocLine($line);

Find the display line of a document line taking hidden lines into account.

See Scintilla documentation for  L<SCI_VISIBLEFROMDOCLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_VISIBLEFROMDOCLINE>

=cut

$autogen{SCI_VISIBLEFROMDOCLINE} = {
    subProto => 'visibleFromDocLine(line) => int',
    sciProto => 'SCI_VISIBLEFROMDOCLINE(line docLine) => line',
};

=item docLineFromVisible

    editor->docLineFromVisible($lineDisplay);

Find the document line of a display line taking hidden lines into account.

See Scintilla documentation for  L<SCI_DOCLINEFROMVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_DOCLINEFROMVISIBLE>

=cut

$autogen{SCI_DOCLINEFROMVISIBLE} = {
    subProto => 'docLineFromVisible(lineDisplay) => int',
    sciProto => 'SCI_DOCLINEFROMVISIBLE(line displayLine) => line',
};

=item showLines

    editor->showLines($lineStart, $lineEnd);

Make a range of lines visible.

See Scintilla documentation for  L<SCI_SHOWLINES|https://www.scintilla.org/ScintillaDoc.html#SCI_SHOWLINES>

=cut

$autogen{SCI_SHOWLINES} = {
    subProto => 'showLines(lineStart, lineEnd)',
    sciProto => 'SCI_SHOWLINES(line lineStart, line lineEnd)',
};

=item hideLines

    editor->hideLines($lineStart, $lineEnd);

Make a range of lines invisible.

See Scintilla documentation for  L<SCI_HIDELINES|https://www.scintilla.org/ScintillaDoc.html#SCI_HIDELINES>

=cut

$autogen{SCI_HIDELINES} = {
    subProto => 'hideLines(lineStart, lineEnd)',
    sciProto => 'SCI_HIDELINES(line lineStart, line lineEnd)',
};

=item getLineVisible

    editor->getLineVisible($line);

Is a line visible?

See Scintilla documentation for  L<SCI_GETLINEVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLINEVISIBLE>

=cut

$autogen{SCI_GETLINEVISIBLE} = {
    subProto => 'getLineVisible(line) => bool',
    sciProto => 'SCI_GETLINEVISIBLE(line line) => bool',
};

=item getAllLinesVisible

    editor->getAllLinesVisible();

Are all lines visible?

See Scintilla documentation for  L<SCI_GETALLLINESVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETALLLINESVISIBLE>

=cut

$autogen{SCI_GETALLLINESVISIBLE} = {
    subProto => 'getAllLinesVisible() => bool',
    sciProto => 'SCI_GETALLLINESVISIBLE => bool',
};

=item setFoldLevel

=item getFoldLevel

    editor->setFoldLevel($line, $level);
    editor->getFoldLevel($line);

Set the fold level of a line. This encodes an integer level along with flags indicating whether the line is a header and whether it is effectively white space.

Use $level as described in L<%SC_FOLDLEVEL|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FOLDLEVEL">.

See Scintilla documentation for  L<SCI_SETFOLDLEVEL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDLEVEL>

See Scintilla documentation for  L<SCI_GETFOLDLEVEL|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFOLDLEVEL>

=cut

$autogen{SCI_SETFOLDLEVEL} = {
    subProto => 'setFoldLevel(line, level)',
    sciProto => 'SCI_SETFOLDLEVEL(line line, int level)',
};

$autogen{SCI_GETFOLDLEVEL} = {
    subProto => 'getFoldLevel(line) => int',
    sciProto => 'SCI_GETFOLDLEVEL(line line) => int',
};

=item setAutomaticFold

=item getAutomaticFold

    editor->setAutomaticFold($automaticFold);
    editor->getAutomaticFold();

Set automatic folding behaviours.

Use $automaticFold from L<%SC_AUTOMATICFOLD|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_AUTOMATICFOLD">

See Scintilla documentation for  L<SCI_SETAUTOMATICFOLD|https://www.scintilla.org/ScintillaDoc.html#SCI_SETAUTOMATICFOLD>

See Scintilla documentation for  L<SCI_GETAUTOMATICFOLD|https://www.scintilla.org/ScintillaDoc.html#SCI_GETAUTOMATICFOLD>

=cut

$autogen{SCI_SETAUTOMATICFOLD} = {
    subProto => 'setAutomaticFold(automaticFold)',
    sciProto => 'SCI_SETAUTOMATICFOLD(int automaticFold)',
};

$autogen{SCI_GETAUTOMATICFOLD} = {
    subProto => 'getAutomaticFold() => int',
    sciProto => 'SCI_GETAUTOMATICFOLD => int',
};

=item setFoldFlags

    editor->setFoldFlags($flags);

Set some style options for folding.

Use $flags from L<%SC_FOLDFLAG|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FOLDFLAG">

See Scintilla documentation for  L<SCI_SETFOLDFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDFLAGS>

=cut

$autogen{SCI_SETFOLDFLAGS} = {
    subProto => 'setFoldFlags(flags)',
    sciProto => 'SCI_SETFOLDFLAGS(int flags)',
};

=item getLastChild

    editor->getLastChild($line, $level);

Find the last child line of a header line.

See Scintilla documentation for  L<SCI_GETLASTCHILD|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLASTCHILD>

=cut

$autogen{SCI_GETLASTCHILD} = {
    subProto => 'getLastChild(line, level) => int',
    sciProto => 'SCI_GETLASTCHILD(line line, int level) => line',
};

=item getFoldParent

    editor->getFoldParent($line);

Find the parent line of a child line.

See Scintilla documentation for  L<SCI_GETFOLDPARENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFOLDPARENT>

=cut

$autogen{SCI_GETFOLDPARENT} = {
    subProto => 'getFoldParent(line) => int',
    sciProto => 'SCI_GETFOLDPARENT(line line) => line',
};

=item setFoldExpanded

=item getFoldExpanded

    editor->setFoldExpanded($line, $expanded);
    editor->getFoldExpanded($line);

Show the children of a header line.

See Scintilla documentation for  L<SCI_SETFOLDEXPANDED|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDEXPANDED>

See Scintilla documentation for  L<SCI_GETFOLDEXPANDED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETFOLDEXPANDED>

=cut

$autogen{SCI_SETFOLDEXPANDED} = {
    subProto => 'setFoldExpanded(line, expanded)',
    sciProto => 'SCI_SETFOLDEXPANDED(line line, bool expanded)',
};

$autogen{SCI_GETFOLDEXPANDED} = {
    subProto => 'getFoldExpanded(line) => bool',
    sciProto => 'SCI_GETFOLDEXPANDED(line line) => bool',
};

=item contractedFoldNext

    editor->contractedFoldNext($lineStart);

Find the next line at or after lineStart that is a contracted fold header line. Return -1 when no more lines.

See Scintilla documentation for  L<SCI_CONTRACTEDFOLDNEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_CONTRACTEDFOLDNEXT>

=cut

$autogen{SCI_CONTRACTEDFOLDNEXT} = {
    subProto => 'contractedFoldNext(lineStart) => int',
    sciProto => 'SCI_CONTRACTEDFOLDNEXT(line lineStart) => line',
};

=item toggleFold

    editor->toggleFold($line);

Switch a header line between expanded and contracted.

See Scintilla documentation for  L<SCI_TOGGLEFOLD|https://www.scintilla.org/ScintillaDoc.html#SCI_TOGGLEFOLD>

=cut

$autogen{SCI_TOGGLEFOLD} = {
    subProto => 'toggleFold(line)',
    sciProto => 'SCI_TOGGLEFOLD(line line)',
};

=item toggleFoldShowText

    editor->toggleFoldShowText($line, $text);

Similar to L</toggleFold>, but also shows the C<$text> tag to the right of the folded text.

See Scintilla documentation for  L<SCI_TOGGLEFOLDSHOWTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_TOGGLEFOLDSHOWTEXT>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_TOGGLEFOLDSHOWTEXT} = {
    subProto => 'toggleFoldShowText(line, text)',
    sciProto => 'SCI_TOGGLEFOLDSHOWTEXT(line line, const char *text)',
};

=item foldDisplayTextSetStyle

=item foldDisplayTextGetStyle

    editor->foldDisplayTextSetStyle($style);
    editor->foldDisplayTextGetStyle;

Changes the appearance of fold text tags.

Use $style from L<%SC_FOLDDISPLAYTEXT|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FOLDDISPLAYTEXT">.

See Scintilla documentation for  L<SCI_FOLDDISPLAYTEXTSETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_FOLDDISPLAYTEXTSETSTYLE>

See Scintilla documentation for  L<SCI_FOLDDISPLAYTEXTGETSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_FOLDDISPLAYTEXTGETSTYLE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_FOLDDISPLAYTEXTSETSTYLE} = {
    subProto => 'foldDisplayTextSetStyle',
    sciProto => 'SCI_FOLDDISPLAYTEXTSETSTYLE(int style)',
};

$autogen{SCI_FOLDDISPLAYTEXTGETSTYLE} = {
    subProto => 'foldDisplayTextGetStyle',
    sciProto => 'SCI_FOLDDISPLAYTEXTGETSTYLE => int',
};

=item setDefaultFoldDisplayText

=item getDefaultFoldDisplayText

    editor->setDefaultFoldDisplayText;
    editor->getDefaultFoldDisplayText;

Set and get the default text displayed at the right of the folded text.

See Scintilla documentation for  L<SCI_SETDEFAULTFOLDDISPLAYTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETDEFAULTFOLDDISPLAYTEXT>

See Scintilla documentation for  L<SCI_GETDEFAULTFOLDDISPLAYTEXT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETDEFAULTFOLDDISPLAYTEXT>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETDEFAULTFOLDDISPLAYTEXT} = {
    subProto => 'setDefaultFoldDisplayText(text)',
    sciProto => 'SCI_SETDEFAULTFOLDDISPLAYTEXT(<unused>, const char *text)',
};

$autogen{SCI_GETDEFAULTFOLDDISPLAYTEXT} = {
    subProto => 'getDefaultFoldDisplayText',
    sciProto => 'SCI_GETDEFAULTFOLDDISPLAYTEXT(<unused>, char *text) => int',
};

=item foldLine

    editor->foldLine($line, $action);

Expand or contract a fold header.

Use $action from L<%SC_FOLDACTION|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_FOLDACTION">.

See Scintilla documentation for  L<SCI_FOLDLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_FOLDLINE>

=cut

$autogen{SCI_FOLDLINE} = {
    subProto => 'foldLine(line, action)',
    sciProto => 'SCI_FOLDLINE(line line, int action)',
};

=item foldChildren

    editor->foldChildren($line, $action);

Expand or contract a fold header and its children.

See Scintilla documentation for  L<SCI_FOLDCHILDREN|https://www.scintilla.org/ScintillaDoc.html#SCI_FOLDCHILDREN>

=cut

$autogen{SCI_FOLDCHILDREN} = {
    subProto => 'foldChildren(line, action)',
    sciProto => 'SCI_FOLDCHILDREN(line line, int action)',
};

=item foldAll

    editor->foldAll($action);

Expand or contract all fold headers.

See Scintilla documentation for  L<SCI_FOLDALL|https://www.scintilla.org/ScintillaDoc.html#SCI_FOLDALL>

=cut

$autogen{SCI_FOLDALL} = {
    subProto => 'foldAll(action)',
    sciProto => 'SCI_FOLDALL(int action)',
};

=item expandChildren

    editor->expandChildren($line, $level);

Expand a fold header and all children. Use the level argument instead of the line’s current level.

See Scintilla documentation for  L<SCI_EXPANDCHILDREN|https://www.scintilla.org/ScintillaDoc.html#SCI_EXPANDCHILDREN>

=cut

$autogen{SCI_EXPANDCHILDREN} = {
    subProto => 'expandChildren(line, level)',
    sciProto => 'SCI_EXPANDCHILDREN(line line, int level)',
};

=item ensureVisible

    editor->ensureVisible($line);

Ensure a particular line is visible by expanding any header line hiding it.

See Scintilla documentation for  L<SCI_ENSUREVISIBLE|https://www.scintilla.org/ScintillaDoc.html#SCI_ENSUREVISIBLE>

=cut

$autogen{SCI_ENSUREVISIBLE} = {
    subProto => 'ensureVisible(line)',
    sciProto => 'SCI_ENSUREVISIBLE(line line)',
};

=item ensureVisibleEnforcePolicy

    editor->ensureVisibleEnforcePolicy($line);

Ensure a particular line is visible by expanding any header line hiding it. Use the currently set visibility policy to determine which range to display.

See Scintilla documentation for  L<SCI_ENSUREVISIBLEENFORCEPOLICY|https://www.scintilla.org/ScintillaDoc.html#SCI_ENSUREVISIBLEENFORCEPOLICY>

=cut

$autogen{SCI_ENSUREVISIBLEENFORCEPOLICY} = {
    subProto => 'ensureVisibleEnforcePolicy(line)',
    sciProto => 'SCI_ENSUREVISIBLEENFORCEPOLICY(line line)',
};

=back

=head2 Line wrapping




=over

=item setWrapMode

=item getWrapMode

    editor->setWrapMode($mode);
    editor->getWrapMode();

Sets whether text is word wrapped.

Use $mode from L<%SC_WRAPMODE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WRAPMODE">.


See Scintilla documentation for  L<SCI_SETWRAPMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWRAPMODE>

See Scintilla documentation for  L<SCI_GETWRAPMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWRAPMODE>

=cut

$autogen{SCI_SETWRAPMODE} = {
    subProto => 'setWrapMode(mode)',
    sciProto => 'SCI_SETWRAPMODE(int wrapMode)',
};

$autogen{SCI_GETWRAPMODE} = {
    subProto => 'getWrapMode() => int',
    sciProto => 'SCI_GETWRAPMODE => int',
};

=item setWrapVisualFlags

=item getWrapVisualFlags

    editor->setWrapVisualFlags($wrapVisualFlags);
    editor->getWrapVisualFlags();

Set the display mode of visual flags for wrapped lines.

Use $wrapVisualFlags from L<%SC_WRAPVISUALFLAG|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WRAPVISUALFLAG">.


See Scintilla documentation for  L<SCI_SETWRAPVISUALFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWRAPVISUALFLAGS>

See Scintilla documentation for  L<SCI_GETWRAPVISUALFLAGS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWRAPVISUALFLAGS>

=cut

$autogen{SCI_SETWRAPVISUALFLAGS} = {
    subProto => 'setWrapVisualFlags(wrapVisualFlags)',
    sciProto => 'SCI_SETWRAPVISUALFLAGS(int wrapVisualFlags)',
};

$autogen{SCI_GETWRAPVISUALFLAGS} = {
    subProto => 'getWrapVisualFlags() => int',
    sciProto => 'SCI_GETWRAPVISUALFLAGS => int',
};

=item setWrapVisualFlagsLocation

=item getWrapVisualFlagsLocation

    editor->setWrapVisualFlagsLocation($wrapVisualFlagsLocation);
    editor->getWrapVisualFlagsLocation();

Set the location of visual flags for wrapped lines.

Use $wrapVisualFlagsLocation from L<%SC_WRAPVISUALFLAGLOC|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WRAPVISUALFLAGLOC">.

See Scintilla documentation for  L<SCI_SETWRAPVISUALFLAGSLOCATION|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWRAPVISUALFLAGSLOCATION>

See Scintilla documentation for  L<SCI_GETWRAPVISUALFLAGSLOCATION|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWRAPVISUALFLAGSLOCATION>

=cut

$autogen{SCI_SETWRAPVISUALFLAGSLOCATION} = {
    subProto => 'setWrapVisualFlagsLocation(wrapVisualFlagsLocation)',
    sciProto => 'SCI_SETWRAPVISUALFLAGSLOCATION(int wrapVisualFlagsLocation)',
};

$autogen{SCI_GETWRAPVISUALFLAGSLOCATION} = {
    subProto => 'getWrapVisualFlagsLocation() => int',
    sciProto => 'SCI_GETWRAPVISUALFLAGSLOCATION => int',
};

=item setWrapIndentMode

=item getWrapIndentMode

    editor->setWrapIndentMode($mode);
    editor->getWrapIndentMode();

Sets how wrapped sublines are placed. Default is fixed.

Use $mode from L<%SC_WRAPINDENT|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_WRAPINDENT">.

See Scintilla documentation for  L<SCI_SETWRAPINDENTMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWRAPINDENTMODE>

See Scintilla documentation for  L<SCI_GETWRAPINDENTMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWRAPINDENTMODE>

=cut

$autogen{SCI_SETWRAPINDENTMODE} = {
    subProto => 'setWrapIndentMode(mode)',
    sciProto => 'SCI_SETWRAPINDENTMODE(int wrapIndentMode)',
};

$autogen{SCI_GETWRAPINDENTMODE} = {
    subProto => 'getWrapIndentMode() => int',
    sciProto => 'SCI_GETWRAPINDENTMODE => int',
};

=item setWrapStartIndent

=item getWrapStartIndent

    editor->setWrapStartIndent($indent);
    editor->getWrapStartIndent();

Set the start indent for wrapped lines.

See Scintilla documentation for  L<SCI_SETWRAPSTARTINDENT|https://www.scintilla.org/ScintillaDoc.html#SCI_SETWRAPSTARTINDENT>

See Scintilla documentation for  L<SCI_GETWRAPSTARTINDENT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETWRAPSTARTINDENT>

=cut

$autogen{SCI_SETWRAPSTARTINDENT} = {
    subProto => 'setWrapStartIndent(indent)',
    sciProto => 'SCI_SETWRAPSTARTINDENT(int indent)',
};

$autogen{SCI_GETWRAPSTARTINDENT} = {
    subProto => 'getWrapStartIndent() => int',
    sciProto => 'SCI_GETWRAPSTARTINDENT => int',
};

=item setLayoutCache

=item getLayoutCache

    editor->setLayoutCache($mode);
    editor->getLayoutCache();

Sets the degree of caching of layout information.

Use $mode from L<%SC_CACHE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_CACHE">

See Scintilla documentation for  L<SCI_SETLAYOUTCACHE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLAYOUTCACHE>

See Scintilla documentation for  L<SCI_GETLAYOUTCACHE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLAYOUTCACHE>

=cut

$autogen{SCI_SETLAYOUTCACHE} = {
    subProto => 'setLayoutCache(mode)',
    sciProto => 'SCI_SETLAYOUTCACHE(int cacheMode)',
};

$autogen{SCI_GETLAYOUTCACHE} = {
    subProto => 'getLayoutCache() => int',
    sciProto => 'SCI_GETLAYOUTCACHE => int',
};

=item setPositionCache

=item getPositionCache

    editor->setPositionCache($size);
    editor->getPositionCache();

Set number of entries in position cache

See Scintilla documentation for  L<SCI_SETPOSITIONCACHE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPOSITIONCACHE>

See Scintilla documentation for  L<SCI_GETPOSITIONCACHE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPOSITIONCACHE>

=cut

$autogen{SCI_SETPOSITIONCACHE} = {
    subProto => 'setPositionCache(size)',
    sciProto => 'SCI_SETPOSITIONCACHE(int size)',
};

$autogen{SCI_GETPOSITIONCACHE} = {
    subProto => 'getPositionCache() => int',
    sciProto => 'SCI_GETPOSITIONCACHE => int',
};

=item linesSplit

    editor->linesSplit($pixelWidth);

Split the lines in the target into lines that are less wide than pixelWidth where possible.

See Scintilla documentation for  L<SCI_LINESSPLIT|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESSPLIT>

=cut

$autogen{SCI_LINESSPLIT} = {
    subProto => 'linesSplit(pixelWidth)',
    sciProto => 'SCI_LINESSPLIT(int pixelWidth)',
};

=item linesJoin

    editor->linesJoin();

Join the lines in the target.

See Scintilla documentation for  L<SCI_LINESJOIN|https://www.scintilla.org/ScintillaDoc.html#SCI_LINESJOIN>

=cut

$autogen{SCI_LINESJOIN} = {
    subProto => 'linesJoin()',
    sciProto => 'SCI_LINESJOIN',
};

=item wrapCount

    editor->wrapCount($line);

The number of display lines needed to wrap a document line

See Scintilla documentation for  L<SCI_WRAPCOUNT|https://www.scintilla.org/ScintillaDoc.html#SCI_WRAPCOUNT>

=cut

$autogen{SCI_WRAPCOUNT} = {
    subProto => 'wrapCount(line) => int',
    sciProto => 'SCI_WRAPCOUNT(line docLine) => line',
};

=back

=head2 Zooming




=over

=item zoomIn

    editor->zoomIn();

Magnify the displayed text by increasing the sizes by 1 point.

See Scintilla documentation for  L<SCI_ZOOMIN|https://www.scintilla.org/ScintillaDoc.html#SCI_ZOOMIN>

=cut

$autogen{SCI_ZOOMIN} = {
    subProto => 'zoomIn()',
    sciProto => 'SCI_ZOOMIN',
};

=item zoomOut

    editor->zoomOut();

Make the displayed text smaller by decreasing the sizes by 1 point.

See Scintilla documentation for  L<SCI_ZOOMOUT|https://www.scintilla.org/ScintillaDoc.html#SCI_ZOOMOUT>

=cut

$autogen{SCI_ZOOMOUT} = {
    subProto => 'zoomOut()',
    sciProto => 'SCI_ZOOMOUT',
};

=item setZoom

=item getZoom

    editor->setZoom($zoom);
    editor->getZoom();

Set the zoom level. This number of points is added to the size of all fonts. It may be positive to magnify or negative to reduce.

See Scintilla documentation for  L<SCI_SETZOOM|https://www.scintilla.org/ScintillaDoc.html#SCI_SETZOOM>

See Scintilla documentation for  L<SCI_GETZOOM|https://www.scintilla.org/ScintillaDoc.html#SCI_GETZOOM>

=cut

$autogen{SCI_SETZOOM} = {
    subProto => 'setZoom(zoom)',
    sciProto => 'SCI_SETZOOM(int zoomInPoints)',
};

$autogen{SCI_GETZOOM} = {
    subProto => 'getZoom() => int',
    sciProto => 'SCI_GETZOOM => int',
};

=back

=head2 Long lines





=over

=item setEdgeMode

=item getEdgeMode

    editor->setEdgeMode($mode);
    editor->getEdgeMode();

Retrieve the edge highlight mode.

$mode from L<%SC_EDGEMODE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_EDGEMODE">.

See Scintilla documentation for  L<SCI_GETEDGEMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEDGEMODE>

See Scintilla documentation for  L<SCI_SETEDGEMODE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEDGEMODE>

=cut

$autogen{SCI_GETEDGEMODE} = {
    subProto => 'getEdgeMode() => int',
    sciProto => 'SCI_GETEDGEMODE => int',
};

$autogen{SCI_SETEDGEMODE} = {
    subProto => 'setEdgeMode(mode)',
    sciProto => 'SCI_SETEDGEMODE(int edgeMode)',
};

=item setEdgeColumn

=item getEdgeColumn

    editor->setEdgeColumn($column);
    editor->getEdgeColumn();

Retrieve the column number which text should be kept within.

See Scintilla documentation for  L<SCI_GETEDGECOLUMN|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEDGECOLUMN>

See Scintilla documentation for  L<SCI_SETEDGECOLUMN|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEDGECOLUMN>

=cut

$autogen{SCI_GETEDGECOLUMN} = {
    subProto => 'getEdgeColumn() => int',
    sciProto => 'SCI_GETEDGECOLUMN => position',
};

$autogen{SCI_SETEDGECOLUMN} = {
    subProto => 'setEdgeColumn(column)',
    sciProto => 'SCI_SETEDGECOLUMN(position column)',
};

=item setEdgeColour

=item getEdgeColour

    editor->setEdgeColour($edgeColour);
    editor->getEdgeColour();

Retrieve the colour used in edge indication.

See Scintilla documentation for  L<SCI_GETEDGECOLOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_GETEDGECOLOUR>

See Scintilla documentation for  L<SCI_SETEDGECOLOUR|https://www.scintilla.org/ScintillaDoc.html#SCI_SETEDGECOLOUR>

=cut

$autogen{SCI_GETEDGECOLOUR} = {
    subProto => 'getEdgeColour() => tuple',
    sciProto => 'SCI_GETEDGECOLOUR => colour',
};

$autogen{SCI_SETEDGECOLOUR} = {
    subProto => 'setEdgeColour(edgeColour)',
    sciProto => 'SCI_SETEDGECOLOUR(colour edgeColour)',
};

=item multiEdgeAddLine

    editor->multiEdgeAddLine($column, $edgeColor);

=item multiEdgeClearAll

    editor->multiEdgeClearAll;

C<multiEdgeAddLine> adds a new vertical edge to the view. The edge will be displayed at the given column number. The resulting edge position depends on the metric of a space character in STYLE_DEFAULT. All the edges can be cleared with C<multiEdgeClearAll>.

See Scintilla documentation for  L<SCI_MULTIEDGEADDLINE|https://www.scintilla.org/ScintillaDoc.html#SCI_MULTIEDGEADDLINE>

See Scintilla documentation for  L<SCI_MULTIEDGECLEARALL|https://www.scintilla.org/ScintillaDoc.html#SCI_MULTIEDGECLEARALL>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_MULTIEDGEADDLINE} = {
    subProto => 'multiEdgeAddLine(column, edgeColour)',
    sciProto => 'SCI_MULTIEDGEADDLINE(position column, colour edgeColour)',
};

$autogen{SCI_MULTIEDGECLEARALL} = {
    subProto => 'multiEdgeClearAll',
    sciProto => 'SCI_MULTIEDGECLEARALL',
};

=back

=head2 Accessibility




=over

=item setAccessibility

=item getAccessibility

    editor->setAccessibility($accessibility);
    editor->getAccessibility;

These methods may enable or disable accessibility and report its current status.  The system caret is manipulated to help screen readers when enabled.

Use $accessibility from L<%SC_ACCESSIBILITY|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_ACCESSIBILITY">.

See Scintilla documentation for  L<SCI_SETACCESSIBILITY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETACCESSIBILITY>

See Scintilla documentation for  L<SCI_GETACCESSIBILITY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETACCESSIBILITY>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETACCESSIBILITY} = {
    subProto => 'setAccessibility(accessibility)',
    sciProto => 'SCI_SETACCESSIBILITY(int accessibility)',
};

$autogen{SCI_GETACCESSIBILITY} = {
    subProto => 'getAccessibility',
    sciProto => 'SCI_GETACCESSIBILITY => int',
};

=back

=head2 Lexer




=over

=item setLexer

=item getLexer

    editor->setLexer($lexer);
    editor->getLexer();

Set the lexing language of the document.

See Scintilla documentation for  L<SCI_SETLEXER|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLEXER>

See Scintilla documentation for  L<SCI_GETLEXER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLEXER>

=cut

$autogen{SCI_SETLEXER} = {
    subProto => 'setLexer(lexer)',
    sciProto => 'SCI_SETLEXER(int lexer)',
};

$autogen{SCI_GETLEXER} = {
    subProto => 'getLexer() => int',
    sciProto => 'SCI_GETLEXER => int',
};

=item setLexerLanguage

=item getLexerLanguage

    editor->setLexerLanguage($language);
    editor->getLexerLanguage();

Set the lexing language of the document based on string name.

See Scintilla documentation for  L<SCI_SETLEXERLANGUAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETLEXERLANGUAGE>

See Scintilla documentation for  L<SCI_GETLEXERLANGUAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETLEXERLANGUAGE>

=cut

$autogen{SCI_SETLEXERLANGUAGE} = {
    subProto => 'setLexerLanguage(language)',
    sciProto => 'SCI_SETLEXERLANGUAGE(<unused>, const char *language)',
};

$autogen{SCI_GETLEXERLANGUAGE} = {
    subProto => 'getLexerLanguage() => str',
    sciProto => 'SCI_GETLEXERLANGUAGE(<unused>, char *language) => int',
};

=item loadLexerLibrary

    editor->loadLexerLibrary($path);

Load a lexer library (dll / so).

See Scintilla documentation for  L<SCI_LOADLEXERLIBRARY|https://www.scintilla.org/ScintillaDoc.html#SCI_LOADLEXERLIBRARY>

=cut

$autogen{SCI_LOADLEXERLIBRARY} = {
    subProto => 'loadLexerLibrary(path)',
    sciProto => 'SCI_LOADLEXERLIBRARY(<unused>, const char *path)',
};

=item colourise

    editor->colourise($start, $end);

Colourise a segment of the document using the current lexing language.

See Scintilla documentation for  L<SCI_COLOURISE|https://www.scintilla.org/ScintillaDoc.html#SCI_COLOURISE>

=cut

$autogen{SCI_COLOURISE} = {
    subProto => 'colourise(start, end)',
    sciProto => 'SCI_COLOURISE(position start, position end)',
};

=item changeLexerState

    editor->changeLexerState($start, $end);

Indicate that the internal state of a lexer has changed over a range and therefore there may be a need to redraw.

See Scintilla documentation for  L<SCI_CHANGELEXERSTATE|https://www.scintilla.org/ScintillaDoc.html#SCI_CHANGELEXERSTATE>

=cut

$autogen{SCI_CHANGELEXERSTATE} = {
    subProto => 'changeLexerState(start, end) => int',
    sciProto => 'SCI_CHANGELEXERSTATE(position start, position end) => int',
};

=item propertyNames

    editor->propertyNames();

Retrieve a ‘\n’ separated list of properties understood by the current lexer.

See Scintilla documentation for  L<SCI_PROPERTYNAMES|https://www.scintilla.org/ScintillaDoc.html#SCI_PROPERTYNAMES>

=cut

#$autogen{SCI_PROPERTYNAMES} = {
#    subProto => 'propertyNames() => str',
#    sciProto => 'SCI_PROPERTYNAMES(<unused>, char *names) => int',
#};

sub propertyNames {
    my $self = shift;
    my $wparam = shift;

    my $args = {
        trim => 'retval',   # uses return value to determine length
        wlength => 0,       # retval does _not_ include \0 string terminator
    };
    return $self->{_hwobj}->SendMessage_getRawString( $SCIMSG{SCI_PROPERTYNAMES} , 0 , $args );
}


=item propertyType

    editor->propertyType($name);

Retrieve the type of a property (boolean, integer, or string).  Returns one of the values in
L<%SC_TYPE|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_TYPE">.


See Scintilla documentation for  L<SCI_PROPERTYTYPE|https://www.scintilla.org/ScintillaDoc.html#SCI_PROPERTYTYPE>

=cut

$autogen{SCI_PROPERTYTYPE} = {
    subProto => 'propertyType(name) => int',
    sciProto => 'SCI_PROPERTYTYPE(const char *name) => int',
};

=item describeProperty

    editor->describeProperty();

Describe a property

See Scintilla documentation for  L<SCI_DESCRIBEPROPERTY|https://www.scintilla.org/ScintillaDoc.html#SCI_DESCRIBEPROPERTY>

=cut

$autogen{SCI_DESCRIBEPROPERTY} = {
    subProto => 'describeProperty() => str',
    sciProto => 'SCI_DESCRIBEPROPERTY(const char *name, char *description) => int',
};

=item setProperty

=item getProperty

    editor->setProperty($key, $value);
    editor->getProperty($key);

Set up a value that may be used by a lexer for some optional feature.

See Scintilla documentation for  L<SCI_SETPROPERTY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETPROPERTY>

See Scintilla documentation for  L<SCI_GETPROPERTY|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPROPERTY>

=cut

$autogen{SCI_SETPROPERTY} = {
    subProto => 'setProperty(key, value)',
    sciProto => 'SCI_SETPROPERTY(const char *key, const char *value)',
};

$autogen{SCI_GETPROPERTY} = {
    subProto => 'getProperty(key) => str',
    sciProto => 'SCI_GETPROPERTY(const char *key, char *value) => int',
};

=item getPropertyExpanded

    editor->getPropertyExpanded($key);

Retrieve a “property” value previously set with SetProperty, with “$()” variable replacement on returned buffer.

See Scintilla documentation for  L<SCI_GETPROPERTYEXPANDED|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPROPERTYEXPANDED>

=cut

$autogen{SCI_GETPROPERTYEXPANDED} = {
    subProto => 'getPropertyExpanded(key) => str',
    sciProto => 'SCI_GETPROPERTYEXPANDED(const char *key, char *value) => int',
};

=item getPropertyInt

    editor->getPropertyInt($key);

Retrieve a “property” value previously set with SetProperty, interpreted as an int AFTER any “$()” variable replacement.

See Scintilla documentation for  L<SCI_GETPROPERTYINT|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPROPERTYINT>

=cut

#$autogen{SCI_GETPROPERTYINT} = {
#    subProto => 'getPropertyInt(key) => int',
#    sciProto => 'SCI_GETPROPERTYINT(const char *key, int defaultValue) => int',
#};
sub getPropertyInt
{
    my $self = shift;
    my $prop = shift;
    my $default = shift||0;
    return $self->{_hwobj}->SendMessage_sendRawStringAsWparam( $SCIMSG{SCI_GETPROPERTYINT}, $prop, $default );
}

=item describeKeyWordSets

    editor->describeKeyWordSets();

Retrieve a ‘\n’ separated list of descriptions of the keyword sets understood by the current lexer.

See Scintilla documentation for  L<SCI_DESCRIBEKEYWORDSETS|https://www.scintilla.org/ScintillaDoc.html#SCI_DESCRIBEKEYWORDSETS>

=cut

$autogen{SCI_DESCRIBEKEYWORDSETS} = {
    subProto => 'describeKeyWordSets() => str',
    sciProto => 'SCI_DESCRIBEKEYWORDSETS(<unused>, char *descriptions) => int',
};

=item setKeyWords

    editor->setKeyWords($keywordSet, $keyWords);

Set up the key words used by the lexer.

$keywordSet is an index from 0 to L<$KEYWORDSET{KEYWORDSET_MAX}|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%KEYWORDSET">, indicating which group of keywords is being defined.


See Scintilla documentation for  L<SCI_SETKEYWORDS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETKEYWORDS>

=cut

$autogen{SCI_SETKEYWORDS} = {
    subProto => 'setKeyWords(keywordSet, keyWords)',
    sciProto => 'SCI_SETKEYWORDS(int keyWordSet, const char *keyWords)',
};

=item getSubStyleBases

    editor->getSubStyleBases();

Get the set of base styles that can be extended with sub styles

See Scintilla documentation for  L<SCI_GETSUBSTYLEBASES|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSUBSTYLEBASES>

=cut

$autogen{SCI_GETSUBSTYLEBASES} = {
    subProto => 'getSubStyleBases() => str',
    sciProto => 'SCI_GETSUBSTYLEBASES(<unused>, char *styles) => int',
};

=item distanceToSecondaryStyles

    editor->distanceToSecondaryStyles();

Where styles are duplicated by a feature such as active/inactive code return the distance between the two types.

See Scintilla documentation for  L<SCI_DISTANCETOSECONDARYSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_DISTANCETOSECONDARYSTYLES>

=cut

$autogen{SCI_DISTANCETOSECONDARYSTYLES} = {
    subProto => 'distanceToSecondaryStyles() => int',
    sciProto => 'SCI_DISTANCETOSECONDARYSTYLES => int',
};

=item allocateSubStyles

    editor->allocateSubStyles($styleBase, $numberStyles);

Allocate a set of sub styles for a particular base style, returning start of range

See Scintilla documentation for  L<SCI_ALLOCATESUBSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_ALLOCATESUBSTYLES>

=cut

$autogen{SCI_ALLOCATESUBSTYLES} = {
    subProto => 'allocateSubStyles(styleBase, numberStyles) => int',
    sciProto => 'SCI_ALLOCATESUBSTYLES(int styleBase, int numberStyles) => int',
};

=item freeSubStyles

    editor->freeSubStyles();

Free allocated sub styles

See Scintilla documentation for  L<SCI_FREESUBSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_FREESUBSTYLES>

=cut

$autogen{SCI_FREESUBSTYLES} = {
    subProto => 'freeSubStyles()',
    sciProto => 'SCI_FREESUBSTYLES',
};

=item getSubStylesStart

    editor->getSubStylesStart($styleBase);

The starting style number for the sub styles associated with a base style

See Scintilla documentation for  L<SCI_GETSUBSTYLESSTART|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSUBSTYLESSTART>

=cut

$autogen{SCI_GETSUBSTYLESSTART} = {
    subProto => 'getSubStylesStart(styleBase) => int',
    sciProto => 'SCI_GETSUBSTYLESSTART(int styleBase) => int',
};

=item getSubStylesLength

    editor->getSubStylesLength($styleBase);

The number of sub styles associated with a base style

See Scintilla documentation for  L<SCI_GETSUBSTYLESLENGTH|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSUBSTYLESLENGTH>

=cut

$autogen{SCI_GETSUBSTYLESLENGTH} = {
    subProto => 'getSubStylesLength(styleBase) => int',
    sciProto => 'SCI_GETSUBSTYLESLENGTH(int styleBase) => int',
};

=item getStyleFromSubStyle

    editor->getStyleFromSubStyle($subStyle);

For a sub style, return the base style, else return the argument.

See Scintilla documentation for  L<SCI_GETSTYLEFROMSUBSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETSTYLEFROMSUBSTYLE>

=cut

$autogen{SCI_GETSTYLEFROMSUBSTYLE} = {
    subProto => 'getStyleFromSubStyle(subStyle) => int',
    sciProto => 'SCI_GETSTYLEFROMSUBSTYLE(int subStyle) => int',
};

=item getPrimaryStyleFromStyle

    editor->getPrimaryStyleFromStyle($style);

For a secondary style, return the primary style, else return the argument.

See Scintilla documentation for  L<SCI_GETPRIMARYSTYLEFROMSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_GETPRIMARYSTYLEFROMSTYLE>

=cut

$autogen{SCI_GETPRIMARYSTYLEFROMSTYLE} = {
    subProto => 'getPrimaryStyleFromStyle(style) => int',
    sciProto => 'SCI_GETPRIMARYSTYLEFROMSTYLE(int style) => int',
};

=item setIdentifiers

    editor->setIdentifiers($style, $identifiers);

Set the identifiers that are shown in a particular style

See Scintilla documentation for  L<SCI_SETIDENTIFIERS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETIDENTIFIERS>

=cut

$autogen{SCI_SETIDENTIFIERS} = {
    subProto => 'setIdentifiers(style, identifiers)',
    sciProto => 'SCI_SETIDENTIFIERS(int style, const char *identifiers)',
};

=item privateLexerCall

    editor->privateLexerCall($operation, $pointer);

For private communication between an application and a known lexer.

See Scintilla documentation for  L<SCI_PRIVATELEXERCALL|https://www.scintilla.org/ScintillaDoc.html#SCI_PRIVATELEXERCALL>

=cut

$autogen{SCI_PRIVATELEXERCALL} = {
    subProto => 'privateLexerCall(operation, pointer) => int',
    sciProto => 'SCI_PRIVATELEXERCALL(int operation, pointer pointer) => pointer',
};

=item getNamedStyles

    editor->getNamedStyles;

Retrieve the number of named styles for the lexer.

See Scintilla documentation for  L<SCI_GETNAMEDSTYLES|https://www.scintilla.org/ScintillaDoc.html#SCI_GETNAMEDSTYLES>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_GETNAMEDSTYLES} = {
    subProto => 'getNamedStyles',
    sciProto => 'SCI_GETNAMEDSTYLES => int',
};

=item nameOfStyle

    editor->nameOfStyle($style);

Retrieve the name of a style.  The name will look like a constant, such as "SCE_C_COMMENTDOC"

See Scintilla documentation for  L<SCI_NAMEOFSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_NAMEOFSTYLE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_NAMEOFSTYLE} = {
    subProto => 'nameOfStyle(style)',
    sciProto => 'SCI_NAMEOFSTYLE(int style, char *name) => int',
};

=item tagsOfStyle

    editor->tagsOfStyle($style);

Retrieve the tags of a style. This is a space-separated set of words like "comment documentation".

See Scintilla documentation for  L<SCI_TAGSOFSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_TAGSOFSTYLE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_TAGSOFSTYLE} = {
    subProto => 'tagsOfStyle(style)',
    sciProto => 'SCI_TAGSOFSTYLE(int style, char *tags) => int',
};

=item descriptionOfStyle

    editor->descriptionOfStyle($style);

Retrieve an English-language description of a style which may be suitable for display in a user interface. This looks like "Doc comment: block comments beginning with /** or /*!".

See Scintilla documentation for  L<SCI_DESCRIPTIONOFSTYLE|https://www.scintilla.org/ScintillaDoc.html#SCI_DESCRIPTIONOFSTYLE>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_DESCRIPTIONOFSTYLE} = {
    subProto => 'descriptionOfStyle(style)',
    sciProto => 'SCI_DESCRIPTIONOFSTYLE(int style, char *description) => int',
};

=back

=head2 Notifications

=for comment the SCN_* and SCEN_* are in %scimsg hash, so I could probably convert these into subs (or AUTOLOAD them into subs, even better)

=for comment SCN_STYLENEEDED

=for comment SCN_CHARADDED

=for comment SCN_SAVEPOINTREACHED

=for comment SCN_SAVEPOINTLEFT

=for comment SCN_MODIFYATTEMPTRO

=for comment SCN_KEY

=for comment SCN_DOUBLECLICK

=for comment SCN_UPDATEUI

=for comment SCN_MODIFIED

=for comment SCN_MACRORECORD

=for comment SCN_MARGINCLICK

=for comment SCN_NEEDSHOWN

=for comment SCN_PAINTED

=for comment SCN_USERLISTSELECTION

=for comment SCN_URIDROPPED

=for comment SCN_DWELLSTART

=for comment SCN_DWELLEND

=for comment SCN_ZOOM

=for comment SCN_HOTSPOTCLICK

=for comment SCN_HOTSPOTDOUBLECLICK

=for comment SCN_HOTSPOTRELEASECLICK

=for comment SCN_INDICATORCLICK

=for comment SCN_INDICATORRELEASE

=for comment SCN_CALLTIPCLICK

=for comment SCN_AUTOCSELECTION

=for comment SCN_AUTOCCANCELLED

=for comment SCN_AUTOCCHARDELETED

=for comment SCN_FOCUSIN

=for comment SCN_FOCUSOUT

=for comment SCN_AUTOCCOMPLETED

=for comment SCN_MARGINRIGHTCLICK

=for comment SCN_AUTOCSELECTIONCHANGE



=for comment SCEN_CHANGE

=for comment SCEN_SETFOCUS

=for comment SCEN_KILLFOCUS



=over

=item setModEventMask

=item getModEventMask

    editor->setModEventMask($mask);
    editor->getModEventMask();

Set which document modification events are sent to the container.

Use $mask as a bitwise-or of values from L<%SC_MOD|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_MOD">.

See Scintilla documentation for  L<SCI_SETMODEVENTMASK|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMODEVENTMASK>

See Scintilla documentation for  L<SCI_GETMODEVENTMASK|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMODEVENTMASK>

=cut

$autogen{SCI_SETMODEVENTMASK} = {
    subProto => 'setModEventMask(mask)',
    sciProto => 'SCI_SETMODEVENTMASK(int eventMask)',
};

$autogen{SCI_GETMODEVENTMASK} = {
    subProto => 'getModEventMask() => int',
    sciProto => 'SCI_GETMODEVENTMASK => int',
};

=item setCommandEvents

=item getCommandEvents

    editor->setCommandEvents($commandEvents);
    editor->getCommandEvents;

These messages set and get whether SCEN_* command events are sent to the container.  C<$commandEvents> needs to be
set to 1 to to send the events, or 0 to disable sending.

See Scintilla documentation for  L<SCI_SETCOMMANDEVENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCOMMANDEVENTS>

See Scintilla documentation for  L<SCI_GETCOMMANDEVENTS|https://www.scintilla.org/ScintillaDoc.html#SCI_GETCOMMANDEVENTS>

Requires at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

$autogen{SCI_SETCOMMANDEVENTS} = {
    subProto => 'setCommandEvents(commandEvents',
    sciProto => 'SCI_SETCOMMANDEVENTS(bool commandEvents)',
};

$autogen{SCI_GETCOMMANDEVENTS} = {
    subProto => 'getCommandEvents',
    sciProto => 'SCI_GETCOMMANDEVENTS => bool',
};

=item setMouseDwellTime

=item getMouseDwellTime

    editor->setMouseDwellTime($periodMilliseconds);
    editor->getMouseDwellTime();

Sets the time the mouse must sit still to generate a mouse dwell event, in milliseconds (so a value of 1000 would set a dwell time of 1 second).

Use $periodMilliseconds of L<$SC_TIMEOUT{SC_TIME_FOREVER}|Win32::Mechanize::NotepadPlusPlus::Editor::Messages/"%SC_TIMEOUT"> to generate no dwell events.


See Scintilla documentation for  L<SCI_SETMOUSEDWELLTIME|https://www.scintilla.org/ScintillaDoc.html#SCI_SETMOUSEDWELLTIME>

See Scintilla documentation for  L<SCI_GETMOUSEDWELLTIME|https://www.scintilla.org/ScintillaDoc.html#SCI_GETMOUSEDWELLTIME>

=cut

$autogen{SCI_SETMOUSEDWELLTIME} = {
    subProto => 'setMouseDwellTime(periodMilliseconds)',
    sciProto => 'SCI_SETMOUSEDWELLTIME(int periodMilliseconds)',
};

$autogen{SCI_GETMOUSEDWELLTIME} = {
    subProto => 'getMouseDwellTime() => int',
    sciProto => 'SCI_GETMOUSEDWELLTIME => int',
};

=item setIdentifier

=item getIdentifier

    editor->setIdentifier($identifier);
    editor->getIdentifier();

Set the identifier reported as idFrom in notification messages.

See Scintilla documentation for  L<SCI_SETIDENTIFIER|https://www.scintilla.org/ScintillaDoc.html#SCI_SETIDENTIFIER>

See Scintilla documentation for  L<SCI_GETIDENTIFIER|https://www.scintilla.org/ScintillaDoc.html#SCI_GETIDENTIFIER>

=cut

$autogen{SCI_SETIDENTIFIER} = {
    subProto => 'setIdentifier(identifier)',
    sciProto => 'SCI_SETIDENTIFIER(int identifier)',
};

$autogen{SCI_GETIDENTIFIER} = {
    subProto => 'getIdentifier() => int',
    sciProto => 'SCI_GETIDENTIFIER => int',
};

=back

=head2 Other Messages

=over

=item notepad()-E<gt>SendMessage( $msgid, $wparam, $lparam )

For any messages not implemented in the API, if you know the
appropriate $msgid, and what are needed as $wparam and $lparam,
you can send the message to the Notepad GUI directly.

If you have developed a wrapper for a missing message, feel free to send in a
L<Pull Request|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/pulls>,
or open an L<issue|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>,
including your wrapper code.

=cut

sub SendMessage {
    my ($self, $msgid, $wparam, $lparam) = @_;
    return $self->{_hwobj}->SendMessage( $msgid, $wparam, $lparam );
}

=back

=head2 Helper Methods

=over

=item forEachLine

    my $coderef = sub { my ($contents, $lineNumber, $totalLines)=@_; ... };
    editor->forEachLine( $coderef );

The C<$coderef> can be an anonymous subroutine (as shown above) or
use C<\&namedFunc> to run a named function.

This helper will run the code found at C<$coderef>, once per line in the
editor's document.  The function gets passed three arguments: the contents
of the line (including any newline sequence), the line number (starts at 0),
and the total number of lines.

If the function returns a number, that number is added to the current line
number to determine the next line number; if it returns an undef, it will
use the default increment of 1 (effectively, C<$lineNumber += $retval//1)>).
The function should return a zero to indicate that it should stay on the same
line (which is useful if the function deleted a line)

For example,

    sub testContents {
        my ($contents, $lineNumber, $totalLines) = @_;
        chomp($contents);
        if($contents eq 'rubbish') {
            editor->deleteLine($lineNumber);
            return 0; # stay on same line, because it's deleted
        } elsif($contents eq 'something old') {
            editor->replaceLine($lineNumber, "something new"); # replaceLine not yet implemented
        } elsif($contents eq 'little something') {
            editor->replaceLine($lineNumber, "BIG\r\nSOMETHING"); # replaceLine not yet implemented
            return 2;   # replaced single with two lines, so need to go the extra line
        }
        # could return 1 here, but undef works as well;
        #   note in perl, you _could_ just exit without returning, as in the PythonScript example,
        #   but in perl, that would return the last statement value, which isn't what you want
        return;
    }

    editor->forEachLine(\&testContents);

=cut

sub forEachLine {
    my $self = shift;
    my $fn = shift;
    my $delta = 1;

    for(my $l=0; $l<$self->getLineCount(); $l += $delta ) {
        my $ret = $fn->( $self->getLine($l), $l, $self->getLineCount() );
        $delta = $ret//1;
    }
}

=item deleteLine

    editor->deleteLine($lineNumber);

Deletes the given (zero indexed) line number.

=cut

sub deleteLine {
    my ($self, $lineNumber) = @_;
    $self->replaceWholeLine($lineNumber, "");
}

=item replaceLine

    editor->replaceLine($lineNumber, $newContents);

Replaces the given (zero indexed) line number (excluding newline sequence)
with the given contents

=cut
sub __dumper(@) {
    my @args = @_;
    map { $_='<undef>' unless defined $_; s/([^\x20-\x7e])/sprintf'\\x{%02X}',ord($1)/ge; $_ } @args;
}

sub replaceLine {
    my ($self, $lineNumber, $newContents) = @_;
    my $start = $self->positionFromLine($lineNumber);
    my $end = $self->getLineEndPosition($lineNumber);
    $self->setTargetRange($start,$end);
    #carp sprintf "debug replaceLine: target = (%s,%s) vs (%s,%s)\n", __dumper $self->getTargetStart(), $self->getTargetEnd(),$start,$end;
    #carp sprintf "debug replaceLine: old='%s', new='%s'\n", __dumper $self->getTargetText(), $newContents;
    $self->replaceTarget($newContents);
}

=item replaceWholeLine

    editor->replaceWholeLine($lineNumber, $newContents);

Replaces the given (zero indexed) line number (including newline sequence)
with the given contents: thus, if $newContents does not end with a newline,
then it will be on the same line as what was originally line C<$lineNumber+1>.

=cut

sub replaceWholeLine {
    my ($self, $lineNumber, $newContents) = @_;
    my $lineCount = $self->getLineCount();
    my $start = $self->positionFromLine($lineNumber);
    my $end = ($lineCount > $lineNumber) ?
        $self->positionFromLine($lineNumber+1) :
        $self->getLineEndPosition($lineNumber);
    $self->setTargetRange($start,$end);
    #carp sprintf "debug replaceWholeLine: target = (%s,%s) vs (%s,%s)\n", __dumper $self->getTargetStart(), $self->getTargetEnd(),$start,$end;
    #carp sprintf "debug replaceWholeLine: old='%s', new='%s'\n", __dumper $self->getTargetText(), $newContents;
    $self->replaceTarget($newContents);
}

=item ================================================

TODO: need to figure out how to implement the search/replace helper methods described in PythonScript API, as much as is possible.

Until such time as they are implemented, it is recommended you just use the already-existing L</Searching> methods; or,
if that's not sufficient, use L<C<getText()>|/getText> and L<C<setText()>|/setText> to pass the whole file into and out
of Perl, and use the power of Perl for your text manipulations.

=item search

    editor->search(...);

=item research

    editor->research(...);

=item replace

    editor->replace(...);

=item rereplace

    editor->rereplace(...);

=cut

# ->replace() https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L709-L746
# ->rereplace() https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L749-L858
# ->search() and ->research() come from https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L860-L969


=item ================================================

=item flash

    editor->flash();                # 50ms (default)
    editor->flash($sec);            # flashes for $sec seconds
    editor->flash($sec, $force);    # force a time that's longer than 1sec if $sec>=1 and $force is true

Flashes the active editor file by inverting the colors of the active file
for a time (in seconds) of C<$sec> (or 50ms if no argument passed); after that
time has elapsed, it will go back to the normal coloring.

Please notice that C<$sec> is in seconds, so 50ms would be written as C<$sec = 0.050;>,
I<not> C<$sec = 50;>.

If you supply a C<$sec> of 1 or greater, the C<flash()> method will warn you that
there will be a long delay, unless you also set C<$force> to a true value.

=cut

#https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L1520-L1542
my $__invert_colors = sub {
    my $self = shift;
    my $WM_SETDRAW = 11;

    $self->SendMessage($WM_SETDRAW, 0, 0);  # disable redraw-after-change

    # swap f/b for all 256 colors, but enable redraw on the very last change
    # (PythonScript used  API:InvalideateRect and API::UpdateWindow after last change,
    #   but I didn't want to wrap those)
    for my $i (reverse 0 .. 255) {
        my $f = $self->SendMessage( $SCIMSG{SCI_STYLEGETFORE}, $i );
        my $b = $self->SendMessage( $SCIMSG{SCI_STYLEGETBACK}, $i );
        $self->SendMessage( $SCIMSG{SCI_STYLESETFORE}, $i, $b );
        $self->SendMessage( $WM_SETDRAW , 1, 0) if $i==0;  # enable redraw-for the very last change
        $self->SendMessage( $SCIMSG{SCI_STYLESETBACK}, $i, $f );
    }
    return;
};

sub flash {
    my $self = shift;
    my $sec = shift // 0.050;
    my $force = shift;

    if($sec>=1 and !$force) {
        warnings::warnif("editor->flash($sec): long flash-time; use flash($sec,1) to disable this warning");
    }

    $__invert_colors->($self);
    select undef,undef,undef,$sec; # use `select` as a high-resolution sleep()
    $__invert_colors->($self);
    return;
}

=item getEOLString

    editor->getEOLString();

Returns the actual string for the EOL symbol (either C<\r\n>, C<\r>, or C<\n>).  This is derived from L</getEOLMode>, which just returns the mode number.

=cut

sub getEOLString {
    my $self = shift;
    return ("\r\n", "\r", "\n")[ $self->getEOLMode() ];
}

=item getFileEndPosition

    editor->getFileEndPosition();

Returns the position after the final character in the file.

This is similar to C<getLineCount()>, but returns a position rather than a line number.

This is similar to C<getLineEndPosition($line)>, but returns the position of the last line rather than the specified line.

This is similar to C<getLength()>, but in multi-byte encodings, they may or may not be different numbers.

=cut

sub getFileEndPosition {
    my $self = shift;
    return $self->getLineEndPosition( $self->getLineCount() -  1 );
}

=item getUserLineSelection

=item getUserCharSelection

    my ($startLine, $endLine) = @{ editor->getUserLineSelection() };
    my ($startByte, $endByte) = @{ editor->getUserCharSelection() };

Get either the line numbers or byte numbers for the start and end of the
currently-active selection (0 indicates the start of the document).
If nothing is selected, it will return the start and end positions
(lines or bytes) values for the whole file.

These are useful if you want your script to be able to run over a
number of lines or characters: if your user selects nothing,
the whole file will be processed; if the user selects text, then
the actions in your script can be limited to just the active
selection.

=cut

# https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L540-L556
sub getUserLineSelection {
    my $self = shift;
    my $start = $self->getSelectionStart();
    my $end = $self->getSelectionEnd();
    return my $ret = ($start==$end) ?
        [0, $self->getLineCount() - 1] :
        [$self->lineFromPosition($start), $self->lineFromPosition($end)];
}

# https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L560-L573
sub getUserCharSelection {
    my $self = shift;
    my $start = $self->getSelectionStart();
    my $end = $self->getSelectionEnd();
    return my $ret = ($start==$end) ?
        [0, $self->getLength()] :
        [$start, $end];
}

=item getWord

=item getCurrentWord

    editor->getWord($position, $useOnlyWordChars);
    editor->getWord($position);
    editor->getWord(undef, $useOnlyWordChars);
    editor->getWord();
    editor->getCurrentWord();

Uses L<C<wordStartPosition>|/wordStartPosition>, L<C<wordEndPosition>|/wordEndPosition>, and L<C<getTextRange>|/getTextRange> to grab the value of the word at the given $position.

If C<$position> is not given or C<undef>, the current caret position is used.

C<$useOnlyWordChars> is a boolean which determines whether to use Scintilla's
default definition of "words" (see L<Scintilla "Words" documentation|https://www.scintilla.org/ScintillaDoc.html#Words>) or not.  If it is not given or C<
undef>, it will default to a I<true> value.

The C<getCurrentWord> method is an alias for C<getWord()> with no arguments (so using the current word and the default "word" definition).

=cut

# https://github.com/bruderstein/PythonScript/blob/ee0f267f07a0838607d69b0cdee4319981ea071b/PythonScript/src/ScintillaWrapper.cpp#L1475-L1507

sub getCurrentWord { $_[0]->getWord(); }

sub getWord {
    my $self = shift;
    my $pos = shift // $self->getCurrentPos();  # default to current position
    my $only = shift // 1;                      # default to TRUE

    my $start = $self->wordStartPosition($pos);
    my $end   = $self->wordEndPosition($pos);

    # carp sprintf "\n\ngetWord(%s,%s) => [%s,%s]\n", $pos, $only, $start, $end;

    return $self->getTextRange($start, $end);
}

=item setTarget

    editor->setTarget($start, $end);        # HELPER: alias for setTargetRange

For compatibility reasons, C<setTarget()> is an alias for L<C<setTargetRange()>|/setTargetRange>

=cut

sub setTarget { goto &setTargetRange; }

=item write

    editor->write($text);       # HELPER: alias for addText

For compatibility reasons, C<write()> is an alias for L<C<addText()>|/addText>

=cut

sub write { goto &addText; }

=back

=cut

my %methods;
{
    #binmode STDERR, ':raw:utf8:crlf';
    #use Encode 'encode';
    #use Win32::Console;
    #Win32::Console::OutputCP( 65001 );

    for my $sci ( sort keys %autogen ) {
        if( $autogen{$sci}{subProto} =~ m/^(\w+)(?:\((.*)\))?(?: *=> *(.*))?$/ ) {
            my $sub = $1;
            my $args = $2;
            my $ret = $3;
            #printf STDERR "DEBUG alt: '%s' => '%s' '%s' '%s'\n", map { encode 'utf8', $_//'<undef>' } $autogen{$sci}{subProto}, $sub, $args, $ret;
            #printf STDERR "DEBUG: did    match '%s'\n", $autogen{$sci}{subProto};

            # save method, args and rettype from
            $autogen{$sci}{subName} = $sub;  # also store the method name
            $autogen{$sci}{subArgs} = defined($args) ? [split /, */, $args] : [];
            $autogen{$sci}{subRet} = $ret;

            # map from sub to sci as well
            $methods{$sub} = $sci;          # point the method to the appropriate autogen key

            #} else {
            #printf STDERR "DEBUG: didn't match '%s'\n", $autogen{$sci}{subProto};
        }

        # similarly check for parens and commas in the SCI message
        if( $autogen{$sci}{sciProto} =~ m/^(\w+)(?:\((.*)\))?(?: *=> *(.*))?$/ ) {
            my $sub = $1;
            my $args = $2;
            my $ret = $3;
            #printf STDERR "DEBUG alt: '%s' => '%s' '%s' '%s'\n", map { encode 'utf8', $_//'<undef>' } $autogen{$sci}{sciProto}, $sub, $args, $ret;

            # save message, args and rettype from
            $autogen{$sci}{sciName} = $sub;  # also store the method name
            $autogen{$sci}{sciArgs} = defined($args) ? [ split /, */, $args] : [];
            $autogen{$sci}{sciRet} = $ret;
        }
    }
    #print "methods keys = ", join(', ', sort keys %methods), "\n";
    if(0) {
        # using this to eventually get a list sorted by the number of scintilla arguments
        #   TODO: sort by size of array, then by joined array, then by size of sub-array and sub-args-joined
        my $sortby = sub {
            scalar(@{ $autogen{$methods{$b}}{sciArgs} }) <=> scalar(@{ $autogen{$methods{$a}}{sciArgs} })
            ||
            join(', ', @{ $autogen{$methods{$a}}{sciArgs}//[] } ) cmp join(', ', @{ $autogen{$methods{$b}}{sciArgs}//[] } )
        };
        foreach my $method ( sort $sortby keys %methods ) {
            my $sci = $methods{$method};
            printf STDERR qq|%s(%s):%s\n\t%s(%s):%s\n|,
                $method, join(', ', @{ $autogen{$sci}{subArgs}//[] } ), $autogen{$sci}{subRet}//'<undef>',
                $sci, join(', ', @{ $autogen{$sci}{sciArgs}//[] } ), $autogen{$sci}{sciRet}//'<undef>',
            ;
        }
        #die;
    }
}

sub DESTROY {}; # empty DESTROY, so AUTOLOAD doesn't create it

sub AUTOLOAD {
    our $AUTOLOAD;
    (my $method = $AUTOLOAD) =~ s/.*:://;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR "autoload(%s) = ->%s(%s)\n", $AUTOLOAD, $method, @_ ? join(", ", map(qq("$_"),@_)) : '';
    if( exists $methods{$method} ) {
        my $sci = $methods{$method};
        no strict 'refs';
        *$method = __auto_generate( $autogen{$sci} );
        goto &$method;
    }
    die sprintf qq|Undefined subroutine %s called at %s line %d|, $method, (caller(0))[1,2];

}

my $TRACE_AUTOGEN;
sub __trace_autogen { $TRACE_AUTOGEN = 1; }
sub __untrace_autogen { $TRACE_AUTOGEN = 0; }
# use editor->__trace_raw_string(); to enable debugging for the auto-generated methods

sub __auto_generate($) {
    my %info = %{ $_[0] };
    my ($method, $sci) = @info{qw/subName sciName/};
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR "\n\n__%04d__ auto_generate ->%s(%s): %s\n", __LINE__, $method, join(', ', @{ $info{subArgs}//[] } ), $info{subRet}//'<undef>';
#printf STDERR "\t from %s(%s): %s\n\n", $sci, join(', ', @{ $info{sciArgs}//[] } ), $info{sciRet}//'<undef>';
    my $nSubArgs = !exists($info{subArgs}) ? 0 : !defined($info{subArgs}) ? 0 : @{$info{subArgs}};
    my $nSciArgs = !exists($info{sciArgs}) ? 0 : !defined($info{sciArgs}) ? 0 : @{$info{sciArgs}};
#printf STDERR "\t nSubArg=%d, nSciArgs=%d\n", $nSubArgs, $nSciArgs;

    if ( 0 == $nSciArgs ) {
        ################################
        # no arguments in; return type doesn't matter (yet)...
        ################################
        return sub {
            my $self = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs}//[] } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs}//[] } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->SendMessage($SCIMSG{$sci}, 0, 0);
        };
    } elsif( $info{subRet}//'<undef>' eq 'str' and $nSciArgs==2 and $info{sciArgs}[1] =~ /^\Qchar *\E/ and $info{sciArgs}[0] =~ /\Qchar *\E/) {
        ################################
        # asking for a string in lparam, _and_ sending a string as wparam
        #       aka: effectively convert one string into another
        #       need to allocate another buffer here for the wparam_string
        ################################
        return sub {
            my $self = shift;
            my $wparam_string = shift // "";
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG string -> string conversion:\n\t%s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet},
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet},
#;
#printf STDERR qq|\tcalled as %s("%s")\n|, $method, join(', ', $wparam_string//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            my $args = { trim => 'retval' };

            return $self->{_hwobj}->SendMessage_sendRawString_getRawString( $SCIMSG{$sci} , $wparam_string, $args );
        };
    } elsif( $nSciArgs==2 and $info{subRet}//'<undef>' eq 'str' and $info{sciArgs}[1] =~ /^\Qchar *\E/) {
        ################################
        # asking for a string: ex ->getText()
        ################################
        return sub {
            my $self = shift;
            my $wparam = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet},
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet},
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wparam//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            my $args = { trim => 'retval'};
            if( !defined $wparam ) {
                # when not defined, need to pass a 0 and tell it to derive the SendMessage wParam from the length rather than from the passed wParam
                $wparam = 0;
                $args->{wlength} = 1;
            }
#printf STDERR qq|\tmodified to %s(%s) with args = {%s}\n|, $method, join(', ', $wparam//'<undef>', @_ ), join(', ', %$args);
            return $self->{_hwobj}->SendMessage_getRawString( $SCIMSG{$sci} , $wparam, $args );
        };
    } elsif( $nSciArgs==2 and $info{sciArgs}[0] =~ /^\Qconst char *\E/ and $info{sciArgs}[1] =~ /^\Qconst char *\E/) {
        ################################
        # send string as wparam, string as lparam
        ################################
        return sub {
            my $self = shift;
            my $wstring = shift;
            my $lstring = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wstring//'<undef>', $lstring//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->{_hwobj}->SendMessage_sendTwoRawStrings( $SCIMSG{$sci}, $wstring, $lstring );
        };
    } elsif( 2==$nSubArgs and $info{sciArgs}[1] =~ /^\Qconst char *\E/) {
        ################################
        # send non-string as wparam, string as lparam
        ################################
        return sub {
            my $self = shift;
            my $wparam = shift;
            my $lstring = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wparam//'<undef>', $lstring//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->{_hwobj}->SendMessage_sendRawString( $SCIMSG{$sci}, $wparam, $lstring );
        };
    } elsif( 1==$nSubArgs and 1==$nSciArgs and $info{sciArgs}[0] =~ /^\Qconst char *\E/) {
        ################################
        # send string as wparam, nothing (0) in lparam
        ################################
        return sub {
            my $self = shift;
            my $wstring = shift;
            my $lparam = shift // 0;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wstring//'<undef>', $lparam//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->{_hwobj}->SendMessage_sendRawStringAsWparam( $SCIMSG{$sci}, $wstring, $lparam );
        };
    } elsif( 1==$nSubArgs and 2==$nSciArgs and $info{sciArgs}[0] =~ /length$/ and $info{sciArgs}[1] =~ /^\Qconst char *\E/) {
        ################################
        # send string as lparam, wparam=length(lparam), using only single subArg
        ################################
        return sub {
            my $self = shift;
            my $lstring = shift;
            my $wparam = length($lstring);
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $lstring//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->{_hwobj}->SendMessage_sendRawString( $SCIMSG{$sci}, $wparam, $lstring );
        };
    } elsif( 1==$nSubArgs and 2==$nSciArgs and $info{sciArgs}[1] =~ /^\Qconst char *\E/) {
        ################################
        # send string as lparam, only single subArg
        ################################
        return sub {
            my $self = shift;
            my $lstring = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $lstring//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->{_hwobj}->SendMessage_sendRawString( $SCIMSG{$sci}, 0, $lstring );
        };
    } elsif( 1==$nSubArgs and 2==$nSciArgs and $info{sciArgs}[0] =~ /^\Q<unused>\E/) {
        ################################
        # method(arg)->msg(<unused>,arg): 1-to-1 mapping from method-arg to lparam
        ################################
        return sub {
            my $self = shift;
            my $lparam = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $lparam//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->SendMessage( $SCIMSG{$sci}, 0, $lparam );
        };
    } elsif( 2==$nSubArgs and 2==$nSciArgs ) {
        ################################
        # method(arg,arg)->msg(arg,arg): 1-to-1 mapping
        ################################
        return sub {
            my $self = shift;
            my $wparam = shift;
            my $lparam = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wparam//'<undef>', $lparam//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->SendMessage( $SCIMSG{$sci}, $wparam, $lparam);
        };
    } elsif( 1==$nSubArgs and 1==$nSciArgs ) {
        ################################
        # method(arg)->msg(arg): 1-to-1 mapping from method arg to wparam
        ################################
        return sub {
            my $self = shift;
            my $wparam = shift;
#{my $oldfh = select STDERR;$|++;select $oldfh;}
#printf STDERR qq|__%04d__ DEBUG: %s(%s):%s\n\tfrom %s(%s):%s\n|, __LINE__,
#    $method, join(', ', @{ $info{subArgs} } ), $info{subRet}//'<undef>',
#    $sci, join(', ', @{ $info{sciArgs} } ), $info{sciRet}//'<undef>',
#;
#printf STDERR qq|\tcalled as %s(%s)\n|, $method, join(', ', $wparam//'<undef>', @_ );
            printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
            return $self->SendMessage( $SCIMSG{$sci}, $wparam, 0);
        };
    } else {
        ################################
        # dummy placeholder sub
        ################################
        return sub {
                # uncoverable subroutine
                # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
                printf STDERR qq|__%04d__:autogen(%s)\n|, __LINE__, $method if $TRACE_AUTOGEN;
                sprintf qq|I was created as "%s" with "%s"\n\t(%s)|,
                    $method, $sci,
                    join("\n\t",
                        map {
                            my $t = $info{$_}//'<undef>';   # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
                            $t =~ s/ *=> */: /;              # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
                                                            # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
                            sprintf qq|"%s"=>"%s"|,
                                $_,
                                $t;
                        } sort keys %info
                    );                                      # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
        };                                                  # uncoverable statement dummy placeholder should never be reached; I don't even know how to test
    }

}

=head1 EXPORTS

The primary interface is through the L</SCINTILLA EDITOR API>, implemented through object methods.

However, there are some hash variables that are useful for use with the API.
These can be exported individually, or using the C<:vars> or C<:all> tags.

=over

=item :vars

Exports the variables in L<Win32::Mechanize::NotepadPlusPlus::Editor::Messages>.
See that sub-module for details on all the variables available.

It's usually used via L<Win32::Mechanize::NotepadPlusPlus>'s C<:vars> tag, which
exports the variables in L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages> and
in L<Win32::Mechanize::NotepadPlusPlus::Editor::Messages>:

    use Win32::Mechanize::NotepadPlusPlus ':vars';

=item :all

Exports everything that can be exported.

=back

=head1 INSTALLATION

Installed as part of L<Win32::Mechanize::NotepadPlusPlus>


=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests emailing C<E<lt>bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.orgE<gt>>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus>,
or thru the repository's interface at L<https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>.

=head1 COPYRIGHT

Copyright (C) 2019,2020 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
