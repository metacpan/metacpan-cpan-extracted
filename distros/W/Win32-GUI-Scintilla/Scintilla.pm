#------------------------------------------------------------------------
# Scintilla control for Win32::GUI
# by Laurent ROCHER (lrocher@cpan.org)
#------------------------------------------------------------------------
#perl2exe_bundle 'SciLexer.dll'

package Win32::GUI::Scintilla;

use vars qw($ABSTRACT $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Win32::GUI;
use Config;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader Win32::GUI::Window);

$VERSION = '1.7';

bootstrap Win32::GUI::Scintilla $VERSION;

#------------------------------------------------------------------------

# Load Scintilla DLL from perl directory or standard LoadLibrary search
my $SCILEXER_PATH = $Config{'installsitelib'} . '\auto\Win32\GUI\Scintilla\SciLexer.DLL';
my $SCINTILLA_DLL = Win32::GUI::LoadLibrary($SCILEXER_PATH) || Win32::GUI::LoadLibrary('SciLexer.DLL');

Win32::GUI::Scintilla::_Initialise();

END {
  # Free Scintilla DLL
  Win32::GUI::FreeLibrary($SCINTILLA_DLL);
  Win32::GUI::Scintilla::_UnInitialise();
}

#------------------------------------------------------------------------

#
# Notify event code
#

use constant SCN_STYLENEEDED        => 2000;
use constant SCN_CHARADDED          => 2001;
use constant SCN_SAVEPOINTREACHED   => 2002;
use constant SCN_SAVEPOINTLEFT      => 2003;
use constant SCN_MODIFYATTEMPTRO    => 2004;
use constant SCN_KEY                => 2005;
use constant SCN_DOUBLECLICK        => 2006;
use constant SCN_UPDATEUI           => 2007;
use constant SCN_MODIFIED           => 2008;
use constant SCN_MACRORECORD        => 2009;
use constant SCN_MARGINCLICK        => 2010;
use constant SCN_NEEDSHOWN          => 2011;
use constant SCN_PAINTED            => 2013;
use constant SCN_USERLISTSELECTION  => 2014;
use constant SCN_URIDROPPED         => 2015;
use constant SCN_DWELLSTART         => 2016;
use constant SCN_DWELLEND           => 2017;
use constant SCN_ZOOM               => 2018;
use constant SCN_HOTSPOTCLICK       => 2019;
use constant SCN_HOTSPOTDOUBLECLICK => 2020;
use constant SCN_CALLTIPCLICK       => 2021;

#------------------------------------------------------------------------

#
# New scintilla control
#

sub new {

  my $class  = shift;

  my (%in)   = @_;
  my %out;

  ### Filtering option
  for my $option qw(
        -name -parent
        -left -top -width -height -pos -size
        -pushstyle -addstyle -popstyle -remstyle -notstyle -negstyle
        -exstyle -pushexstyle -addexstyle -popexstyle -remexstyle -notexstyle
        ) {
    $out{$option} = $in{$option} if exists $in{$option};
  }

  ### Default window
  my $constant     = Win32::GUI::constant("WIN32__GUI__STATIC", 0);
  $out{-style}     = WS_CLIPCHILDREN;
  $out{-class}     = "Scintilla";

  ### Window style
  $out{-style} |= WS_TABSTOP unless exists $in{-tabstop} && $in{-tabstop} == 0;         #Default to -tabstop => 1
  $out{-style} |= WS_VISIBLE unless exists $in{-visible} && $in{-visible} == 0;         #Default to -visible => 1
  $out{-style} |= WS_HSCROLL if     exists $in{-hscroll} && $in{-hscroll} == 1;
  $out{-style} |= WS_VSCROLL if     exists $in{-vscroll} && $in{-vscroll} == 1;

  my $self = Win32::GUI->_new($constant, $class, %out);
  if (defined ($self)) {

    # Option Text :
    $self->SetText($in{-text}) if exists $in{-text};
    $self->SetReadOnly($in{-readonly}) if exists $in{-readonly};
  }

  return $self;
}

#
# Win32 shortcut
#

sub Win32::GUI::Window::AddScintilla {
  my $parent  = shift;
  return Win32::GUI::Scintilla->new (-parent => $parent, @_);
}

#------------------------------------------------------------------------
# Miscolous function
#------------------------------------------------------------------------

#
# Clear Scintilla Text
#

sub NewFile {
  my $self = shift;

  $self->ClearAll();
  $self->EmptyUndoBuffer();
  $self->SetSavePoint();
}

#
# Load text file to Scintilla
#

sub LoadFile {
  my ($self, $file) = @_;

  $self->ClearAll();
  $self->Cancel();
  $self->SetUndoCollection(0);

  open F, "<$file" or return 0;
  while ( <F> ) {
    $self->AppendText($_);
  }
  close F;

  $self->SetUndoCollection(1);
  $self->EmptyUndoBuffer();
  $self->SetSavePoint();
  $self->GotoPos(0);

  return 1;
}

#
# Save Scintilla text to file
#

sub SaveFile {
  my ($self, $file) = @_;

  open F, ">$file" or return 0;

  for my $i (0..$self->GetLineCount()) {
    print F $self->GetLine ($i);
  }

  close F;

  $self->SetSavePoint();

  return 1;
}

#
# Help routine for StyleSet
#

sub StyleSetSpec {
  my ($self, $style, $textstyle) = @_;

  foreach my $prop (split (/,/, $textstyle)) {

    my ($key, $value) = split (/:/, $prop);

    $self->StyleSetFore($style, $value) if $key eq 'fore';
    $self->StyleSetBack($style, $value) if $key eq 'back';

    $self->StyleSetFont($style, $value) if $key eq 'face';

    $self->StyleSetSize($style, int ($value) )  if $key eq 'size';

    $self->StyleSetBold($style, 1)      if $key eq 'bold';
    $self->StyleSetBold($style, 0)      if $key eq 'notbold';
    $self->StyleSetItalic($style, 1)    if $key eq 'italic';
    $self->StyleSetItalic($style, 0)    if $key eq 'notitalic';
    $self->StyleSetUnderline($style, 1) if $key eq 'underline';
    $self->StyleSetUnderline($style, 0) if $key eq 'notunderline';
    $self->StyleSetEOLFilled ($style, 1) if $key eq 'eolfilled';
    $self->StyleSetEOLFilled ($style, 0) if $key eq 'noteolfilled';
  }
}

#------------------------------------------------------------------------
# Begin Autogenerate
#------------------------------------------------------------------------

use constant INVALID_POSITION => -1 ;
# Define start of Scintilla messages to be greater than all Windows edit (EM_*) messages
# as many EM_ messages can be used although that use is deprecated.
use constant SCI_START => 2000 ;
use constant SCI_OPTIONAL_START => 3000 ;
use constant SCI_LEXER_START => 4000 ;
# Add text to the document.
# AddText(text)
sub AddText {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2001, $length, $text);
}
# Add array of cells to document.
# AddStyledText(styledtext)
sub AddStyledText {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2002, $length, $text);
}
# Insert string at a position.
sub InsertText {
  my ($self, $pos, $text) = @_;
  return $self->SendMessageNP (2003, $pos, $text);
}
# Delete all text in the document.
sub ClearAll {
  my $self = shift;
  return $self->SendMessage (2004, 0, 0);
}
# Set all style bytes to 0, remove all folding information.
sub ClearDocumentStyle {
  my $self = shift;
  return $self->SendMessage (2005, 0, 0);
}
# The number of characters in the document.
sub GetLength {
  my $self = shift;
  return $self->SendMessage (2006, 0, 0);
}
# Returns the character byte at the position.
sub GetCharAt {
  my ($self, $pos) = @_;
  return chr $self->SendMessage (2007, $pos, 0);
}
# Returns the position of the caret.
sub GetCurrentPos {
  my $self = shift;
  return $self->SendMessage (2008, 0, 0);
}
# Returns the position of the opposite end of the selection to the caret.
sub GetAnchor {
  my $self = shift;
  return $self->SendMessage (2009, 0, 0);
}
# Returns the style byte at the position.
sub GetStyleAt {
  my ($self, $pos) = @_;
  return $self->SendMessage (2010, $pos, 0);
}
# Redoes the next action on the undo history.
sub Redo {
  my $self = shift;
  return $self->SendMessage (2011, 0, 0);
}
# Choose between collecting actions into the undo
# history and discarding them.
sub SetUndoCollection {
  my ($self, $collectUndo) = @_;
  return $self->SendMessage (2012, $collectUndo, 0);
}
# Select all the text in the document.
sub SelectAll {
  my $self = shift;
  return $self->SendMessage (2013, 0, 0);
}
# Remember the current position in the undo history as the position
# at which the document was saved.
sub SetSavePoint {
  my $self = shift;
  return $self->SendMessage (2014, 0, 0);
}
# Retrieve a buffer of cells.
# Returns the number of bytes in the buffer not including terminating NULs.
sub GetStyledText {
  my $self = shift;
  my $start = shift || 0;
  my $end = shift || $self->GetLength();

  return undef if $start >= $end;

  my $text = " " x (($end - $start + 1)*2);
  my $textrange = pack("LLp", $start, $end, $text);
  $self->SendMessageNP (2015, 0, $textrange);
  return $text;
}
# Are there any redoable actions in the undo history?
sub CanRedo {
  my $self = shift;
  return $self->SendMessage (2016, 0, 0);
}
# Retrieve the line number at which a particular marker is located.
sub MarkerLineFromHandle {
  my ($self, $handle) = @_;
  return $self->SendMessage (2017, $handle, 0);
}
# Delete a marker.
sub MarkerDeleteHandle {
  my ($self, $handle) = @_;
  return $self->SendMessage (2018, $handle, 0);
}
# Is undo history being collected?
sub GetUndoCollection {
  my $self = shift;
  return $self->SendMessage (2019, 0, 0);
}
use constant SCWS_INVISIBLE => 0 ;
use constant SCWS_VISIBLEALWAYS => 1 ;
use constant SCWS_VISIBLEAFTERINDENT => 2 ;
# Are white space characters currently visible?
# Returns one of SCWS_* constants.
sub GetViewWS {
  my $self = shift;
  return $self->SendMessage (2020, 0, 0);
}
# Make white space characters invisible, always visible or visible outside indentation.
sub SetViewWS {
  my ($self, $viewWS) = @_;
  return $self->SendMessage (2021, $viewWS, 0);
}
# Find the position from a point within the window.
sub PositionFromPoint {
  my ($self, $x, $y) = @_;
  return $self->SendMessage (2022, $x, $y);
}
# Find the position from a point within the window but return
# INVALID_POSITION if not close to text.
sub PositionFromPointClose {
  my ($self, $x, $y) = @_;
  return $self->SendMessage (2023, $x, $y);
}
# Set caret to start of a line and ensure it is visible.
sub GotoLine {
  my ($self, $line) = @_;
  return $self->SendMessage (2024, $line, 0);
}
# Set caret to a position and ensure it is visible.
sub GotoPos {
  my ($self, $pos) = @_;
  return $self->SendMessage (2025, $pos, 0);
}
# Set the selection anchor to a position. The anchor is the opposite
# end of the selection from the caret.
sub SetAnchor {
  my ($self, $posAnchor) = @_;
  return $self->SendMessage (2026, $posAnchor, 0);
}
# Retrieve the text of the line containing the caret.
# Returns the index of the caret on the line.
# GetCurline () : Return curent line Text
sub GetCurLine {
  my ($self) = @_;
  my $line   = $self->GetLineFromPosition ($self->GetCurrentPos());
  my $lenght = $self->LineLength($line);
  my $text   = " " x ($lenght+1);

  if ($self->SendMessageNP (2027, $lenght, $text)) {
    return $text;
  } else {
    return undef;
  }
}
# Retrieve the position of the last correctly styled character.
sub GetEndStyled {
  my $self = shift;
  return $self->SendMessage (2028, 0, 0);
}
use constant SC_EOL_CRLF => 0 ;
use constant SC_EOL_CR => 1 ;
use constant SC_EOL_LF => 2 ;
# Convert all line endings in the document to one mode.
sub ConvertEOLs {
  my ($self, $eolMode) = @_;
  return $self->SendMessage (2029, $eolMode, 0);
}
# Retrieve the current end of line mode - one of CRLF, CR, or LF.
sub GetEOLMode {
  my $self = shift;
  return $self->SendMessage (2030, 0, 0);
}
# Set the current end of line mode.
sub SetEOLMode {
  my ($self, $eolMode) = @_;
  return $self->SendMessage (2031, $eolMode, 0);
}
# Set the current styling position to pos and the styling mask to mask.
# The styling mask can be used to protect some bits in each styling byte from modification.
sub StartStyling {
  my ($self, $pos, $mask) = @_;
  return $self->SendMessage (2032, $pos, $mask);
}
# Change style from current styling position for length characters to a style
# and move the current styling position to after this newly styled segment.
sub SetStyling {
  my ($self, $length, $style) = @_;
  return $self->SendMessage (2033, $length, $style);
}
# Is drawing done first into a buffer or direct to the screen?
sub GetBufferedDraw {
  my $self = shift;
  return $self->SendMessage (2034, 0, 0);
}
# If drawing is buffered then each line of text is drawn into a bitmap buffer
# before drawing it to the screen to avoid flicker.
sub SetBufferedDraw {
  my ($self, $buffered) = @_;
  return $self->SendMessage (2035, $buffered, 0);
}
# Change the visible size of a tab to be a multiple of the width of a space character.
sub SetTabWidth {
  my ($self, $tabWidth) = @_;
  return $self->SendMessage (2036, $tabWidth, 0);
}
# Retrieve the visible size of a tab.
sub GetTabWidth {
  my $self = shift;
  return $self->SendMessage (2121, 0, 0);
}
# The SC_CP_UTF8 value can be used to enter Unicode mode.
# This is the same value as CP_UTF8 in Windows
use constant SC_CP_UTF8 => 65001 ;
# The SC_CP_DBCS value can be used to indicate a DBCS mode for GTK+.
use constant SC_CP_DBCS => 1 ;
# Set the code page used to interpret the bytes of the document as characters.
# The SC_CP_UTF8 value can be used to enter Unicode mode.
sub SetCodePage {
  my ($self, $codePage) = @_;
  return $self->SendMessage (2037, $codePage, 0);
}
# In palette mode, Scintilla uses the environment's palette calls to display
# more colours. This may lead to ugly displays.
sub SetUsePalette {
  my ($self, $usePalette) = @_;
  return $self->SendMessage (2039, $usePalette, 0);
}
use constant MARKER_MAX => 31 ;
use constant SC_MARK_CIRCLE => 0 ;
use constant SC_MARK_ROUNDRECT => 1 ;
use constant SC_MARK_ARROW => 2 ;
use constant SC_MARK_SMALLRECT => 3 ;
use constant SC_MARK_SHORTARROW => 4 ;
use constant SC_MARK_EMPTY => 5 ;
use constant SC_MARK_ARROWDOWN => 6 ;
use constant SC_MARK_MINUS => 7 ;
use constant SC_MARK_PLUS => 8 ;
# Shapes used for outlining column.
use constant SC_MARK_VLINE => 9 ;
use constant SC_MARK_LCORNER => 10 ;
use constant SC_MARK_TCORNER => 11 ;
use constant SC_MARK_BOXPLUS => 12 ;
use constant SC_MARK_BOXPLUSCONNECTED => 13 ;
use constant SC_MARK_BOXMINUS => 14 ;
use constant SC_MARK_BOXMINUSCONNECTED => 15 ;
use constant SC_MARK_LCORNERCURVE => 16 ;
use constant SC_MARK_TCORNERCURVE => 17 ;
use constant SC_MARK_CIRCLEPLUS => 18 ;
use constant SC_MARK_CIRCLEPLUSCONNECTED => 19 ;
use constant SC_MARK_CIRCLEMINUS => 20 ;
use constant SC_MARK_CIRCLEMINUSCONNECTED => 21 ;
# Invisible mark that only sets the line background color.
use constant SC_MARK_BACKGROUND => 22 ;
use constant SC_MARK_DOTDOTDOT => 23 ;
use constant SC_MARK_ARROWS => 24 ;
use constant SC_MARK_PIXMAP => 25 ;
use constant SC_MARK_CHARACTER => 10000 ;
# Markers used for outlining column.
use constant SC_MARKNUM_FOLDEREND => 25 ;
use constant SC_MARKNUM_FOLDEROPENMID => 26 ;
use constant SC_MARKNUM_FOLDERMIDTAIL => 27 ;
use constant SC_MARKNUM_FOLDERTAIL => 28 ;
use constant SC_MARKNUM_FOLDERSUB => 29 ;
use constant SC_MARKNUM_FOLDER => 30 ;
use constant SC_MARKNUM_FOLDEROPEN => 31 ;
use constant SC_MASK_FOLDERS => 0xFE000000 ;
# Set the symbol used for a particular marker number.
sub MarkerDefine {
  my ($self, $markerNumber, $markerSymbol) = @_;
  return $self->SendMessage (2040, $markerNumber, $markerSymbol);
}
# Set the foreground colour used for a particular marker number.
sub MarkerSetFore {
  my ($self, $markerNumber, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2041, $markerNumber, int hex $fore);
}
# Set the background colour used for a particular marker number.
sub MarkerSetBack {
  my ($self, $markerNumber, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2042, $markerNumber, int hex $back);
}
# Add a marker to a line, returning an ID which can be used to find or delete the marker.
sub MarkerAdd {
  my ($self, $line, $markerNumber) = @_;
  return $self->SendMessage (2043, $line, $markerNumber);
}
# Delete a marker from a line.
sub MarkerDelete {
  my ($self, $line, $markerNumber) = @_;
  return $self->SendMessage (2044, $line, $markerNumber);
}
# Delete all markers with a particular number from all lines.
sub MarkerDeleteAll {
  my ($self, $markerNumber) = @_;
  return $self->SendMessage (2045, $markerNumber, 0);
}
# Get a bit mask of all the markers set on a line.
sub MarkerGet {
  my ($self, $line) = @_;
  return $self->SendMessage (2046, $line, 0);
}
# Find the next line after lineStart that includes a marker in mask.
sub MarkerNext {
  my ($self, $lineStart, $markerMask) = @_;
  return $self->SendMessage (2047, $lineStart, $markerMask);
}
# Find the previous line before lineStart that includes a marker in mask.
sub MarkerPrevious {
  my ($self, $lineStart, $markerMask) = @_;
  return $self->SendMessage (2048, $lineStart, $markerMask);
}
# Define a marker from a pixmap.
sub MarkerDefinePixmap {
  my ($self, $markerNumber, $pixmap) = @_;
  return $self->SendMessageNP (2049, $markerNumber, $pixmap);
}
use constant SC_MARGIN_SYMBOL => 0 ;
use constant SC_MARGIN_NUMBER => 1 ;
# Set a margin to be either numeric or symbolic.
sub SetMarginTypeN {
  my ($self, $margin, $marginType) = @_;
  return $self->SendMessage (2240, $margin, $marginType);
}
# Retrieve the type of a margin.
sub GetMarginTypeN {
  my ($self, $margin) = @_;
  return $self->SendMessage (2241, $margin, 0);
}
# Set the width of a margin to a width expressed in pixels.
sub SetMarginWidthN {
  my ($self, $margin, $pixelWidth) = @_;
  return $self->SendMessage (2242, $margin, $pixelWidth);
}
# Retrieve the width of a margin in pixels.
sub GetMarginWidthN {
  my ($self, $margin) = @_;
  return $self->SendMessage (2243, $margin, 0);
}
# Set a mask that determines which markers are displayed in a margin.
sub SetMarginMaskN {
  my ($self, $margin, $mask) = @_;
  return $self->SendMessage (2244, $margin, $mask);
}
# Retrieve the marker mask of a margin.
sub GetMarginMaskN {
  my ($self, $margin) = @_;
  return $self->SendMessage (2245, $margin, 0);
}
# Make a margin sensitive or insensitive to mouse clicks.
sub SetMarginSensitiveN {
  my ($self, $margin, $sensitive) = @_;
  return $self->SendMessage (2246, $margin, $sensitive);
}
# Retrieve the mouse click sensitivity of a margin.
sub GetMarginSensitiveN {
  my ($self, $margin) = @_;
  return $self->SendMessage (2247, $margin, 0);
}
# Styles in range 32..37 are predefined for parts of the UI and are not used as normal styles.
# Styles 38 and 39 are for future use.
use constant STYLE_DEFAULT => 32 ;
use constant STYLE_LINENUMBER => 33 ;
use constant STYLE_BRACELIGHT => 34 ;
use constant STYLE_BRACEBAD => 35 ;
use constant STYLE_CONTROLCHAR => 36 ;
use constant STYLE_INDENTGUIDE => 37 ;
use constant STYLE_LASTPREDEFINED => 39 ;
use constant STYLE_MAX => 127 ;
# Character set identifiers are used in StyleSetCharacterSet.
# The values are the same as the Windows *_CHARSET values.
use constant SC_CHARSET_ANSI => 0 ;
use constant SC_CHARSET_DEFAULT => 1 ;
use constant SC_CHARSET_BALTIC => 186 ;
use constant SC_CHARSET_CHINESEBIG5 => 136 ;
use constant SC_CHARSET_EASTEUROPE => 238 ;
use constant SC_CHARSET_GB2312 => 134 ;
use constant SC_CHARSET_GREEK => 161 ;
use constant SC_CHARSET_HANGUL => 129 ;
use constant SC_CHARSET_MAC => 77 ;
use constant SC_CHARSET_OEM => 255 ;
use constant SC_CHARSET_RUSSIAN => 204 ;
use constant SC_CHARSET_SHIFTJIS => 128 ;
use constant SC_CHARSET_SYMBOL => 2 ;
use constant SC_CHARSET_TURKISH => 162 ;
use constant SC_CHARSET_JOHAB => 130 ;
use constant SC_CHARSET_HEBREW => 177 ;
use constant SC_CHARSET_ARABIC => 178 ;
use constant SC_CHARSET_VIETNAMESE => 163 ;
use constant SC_CHARSET_THAI => 222 ;
# Clear all the styles and make equivalent to the global default style.
sub StyleClearAll {
  my $self = shift;
  return $self->SendMessage (2050, 0, 0);
}
# Set the foreground colour of a style.
sub StyleSetFore {
  my ($self, $style, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2051, $style, int hex $fore);
}
# Set the background colour of a style.
sub StyleSetBack {
  my ($self, $style, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2052, $style, int hex $back);
}
# Set a style to be bold or not.
sub StyleSetBold {
  my ($self, $style, $bold) = @_;
  return $self->SendMessage (2053, $style, $bold);
}
# Set a style to be italic or not.
sub StyleSetItalic {
  my ($self, $style, $italic) = @_;
  return $self->SendMessage (2054, $style, $italic);
}
# Set the size of characters of a style.
sub StyleSetSize {
  my ($self, $style, $sizePoints) = @_;
  return $self->SendMessage (2055, $style, $sizePoints);
}
# Set the font of a style.
sub StyleSetFont {
  my ($self, $style, $fontName) = @_;
  return $self->SendMessageNP (2056, $style, $fontName);
}
# Set a style to have its end of line filled or not.
sub StyleSetEOLFilled {
  my ($self, $style, $filled) = @_;
  return $self->SendMessage (2057, $style, $filled);
}
# Reset the default style to its state at startup
sub StyleResetDefault {
  my $self = shift;
  return $self->SendMessage (2058, 0, 0);
}
# Set a style to be underlined or not.
sub StyleSetUnderline {
  my ($self, $style, $underline) = @_;
  return $self->SendMessage (2059, $style, $underline);
}
use constant SC_CASE_MIXED => 0 ;
use constant SC_CASE_UPPER => 1 ;
use constant SC_CASE_LOWER => 2 ;
# Set a style to be mixed case, or to force upper or lower case.
sub StyleSetCase {
  my ($self, $style, $caseForce) = @_;
  return $self->SendMessage (2060, $style, $caseForce);
}
# Set the character set of the font in a style.
sub StyleSetCharacterSet {
  my ($self, $style, $characterSet) = @_;
  return $self->SendMessage (2066, $style, $characterSet);
}
# Set a style to be a hotspot or not.
sub StyleSetHotSpot {
  my ($self, $style, $hotspot) = @_;
  return $self->SendMessage (2409, $style, $hotspot);
}
# Set the foreground colour of the selection and whether to use this setting.
sub SetSelFore {
  my ($self, $useSetting, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2067, $useSetting, int hex $fore);
}
# Set the background colour of the selection and whether to use this setting.
sub SetSelBack {
  my ($self, $useSetting, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2068, $useSetting, int hex $back);
}
# Set the foreground colour of the caret.
sub SetCaretFore {
  my ($self, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2069, int hex $fore, 0);
}
# When key+modifier combination km is pressed perform msg.
sub AssignCmdKey {
  my ($self, $key, $modifiers, $msg) = @_;
  my $param = pack ('ss', $key, $modifiers);
  return $self->SendMessage (2070, $param, $msg);
}
# When key+modifier combination km is pressed do nothing.
sub ClearCmdKey {
  my ($self, $key, $modifiers) = @_;
  my $param = pack ('ss', $key, $modifiers);
  return $self->SendMessage (2071, $param, 0);
}
# Drop all key mappings.
sub ClearAllCmdKeys {
  my $self = shift;
  return $self->SendMessage (2072, 0, 0);
}
# Set the styles for a segment of the document.
sub SetStylingEx {
  my ($self, $length, $styles) = @_;
  return $self->SendMessageNP (2073, $length, $styles);
}
# Set a style to be visible or not.
sub StyleSetVisible {
  my ($self, $style, $visible) = @_;
  return $self->SendMessage (2074, $style, $visible);
}
# Get the time in milliseconds that the caret is on and off.
sub GetCaretPeriod {
  my $self = shift;
  return $self->SendMessage (2075, 0, 0);
}
# Get the time in milliseconds that the caret is on and off. 0 = steady on.
sub SetCaretPeriod {
  my ($self, $periodMilliseconds) = @_;
  return $self->SendMessage (2076, $periodMilliseconds, 0);
}
# Set the set of characters making up words for when moving or selecting by word.
# First sets deaults like SetCharsDefault.
sub SetWordChars {
  my ($self, $characters) = @_;
  return $self->SendMessageNP (2077, 0, $characters);
}
# Start a sequence of actions that is undone and redone as a unit.
# May be nested.
sub BeginUndoAction {
  my $self = shift;
  return $self->SendMessage (2078, 0, 0);
}
# End a sequence of actions that is undone and redone as a unit.
sub EndUndoAction {
  my $self = shift;
  return $self->SendMessage (2079, 0, 0);
}
use constant INDIC_MAX => 7 ;
use constant INDIC_PLAIN => 0 ;
use constant INDIC_SQUIGGLE => 1 ;
use constant INDIC_TT => 2 ;
use constant INDIC_DIAGONAL => 3 ;
use constant INDIC_STRIKE => 4 ;
use constant INDIC_HIDDEN => 5 ;
use constant INDIC_BOX => 6 ;
use constant INDIC0_MASK => 0x20 ;
use constant INDIC1_MASK => 0x40 ;
use constant INDIC2_MASK => 0x80 ;
use constant INDICS_MASK => 0xE0 ;
# Set an indicator to plain, squiggle or TT.
sub IndicSetStyle {
  my ($self, $indic, $style) = @_;
  return $self->SendMessage (2080, $indic, $style);
}
# Retrieve the style of an indicator.
sub IndicGetStyle {
  my ($self, $indic) = @_;
  return $self->SendMessage (2081, $indic, 0);
}
# Set the foreground colour of an indicator.
sub IndicSetFore {
  my ($self, $indic, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2082, $indic, int hex $fore);
}
# Retrieve the foreground colour of an indicator.
sub IndicGetFore {
  my ($self, $indic) = @_;
  my $colour = $self->SendMessage (2083, $indic, 0);
  $colour = sprintf ('#%x', $colour);
  $colour =~ s/(.)(..)(..)(..)/$1$4$3$2/;
  return $colour;
}# Set the foreground colour of all whitespace and whether to use this setting.
sub SetWhitespaceFore {
  my ($self, $useSetting, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2084, $useSetting, int hex $fore);
}
# Set the background colour of all whitespace and whether to use this setting.
sub SetWhitespaceBack {
  my ($self, $useSetting, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2085, $useSetting, int hex $back);
}
# Divide each styling byte into lexical class bits (default: 5) and indicator
# bits (default: 3). If a lexer requires more than 32 lexical states, then this
# is used to expand the possible states.
sub SetStyleBits {
  my ($self, $bits) = @_;
  return $self->SendMessage (2090, $bits, 0);
}
# Retrieve number of bits in style bytes used to hold the lexical state.
sub GetStyleBits {
  my $self = shift;
  return $self->SendMessage (2091, 0, 0);
}
# Used to hold extra styling information for each line.
sub SetLineState {
  my ($self, $line, $state) = @_;
  return $self->SendMessage (2092, $line, $state);
}
# Retrieve the extra styling information for a line.
sub GetLineState {
  my ($self, $line) = @_;
  return $self->SendMessage (2093, $line, 0);
}
# Retrieve the last line number that has line state.
sub GetMaxLineState {
  my $self = shift;
  return $self->SendMessage (2094, 0, 0);
}
# Is the background of the line containing the caret in a different colour?
sub GetCaretLineVisible {
  my $self = shift;
  return $self->SendMessage (2095, 0, 0);
}
# Display the background of the line containing the caret in a different colour.
sub SetCaretLineVisible {
  my ($self, $show) = @_;
  return $self->SendMessage (2096, $show, 0);
}
# Get the colour of the background of the line containing the caret.
sub GetCaretLineBack {
  my $self = shift;
  my $colour = $self->SendMessage (2097, 0, 0);
  $colour = sprintf ('#%x', $colour);
  $colour =~ s/(.)(..)(..)(..)/$1$4$3$2/;
  return $colour;
}
# Set the colour of the background of the line containing the caret.
sub SetCaretLineBack {
  my ($self, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2098, int hex $back, 0);
}
# Set a style to be changeable or not (read only).
# Experimental feature, currently buggy.
sub StyleSetChangeable {
  my ($self, $style, $changeable) = @_;
  return $self->SendMessage (2099, $style, $changeable);
}
# Display a auto-completion list.
# The lenEntered parameter indicates how many characters before
# the caret should be used to provide context.
sub AutoCShow {
  my ($self, $lenEntered, $itemList) = @_;
  return $self->SendMessageNP (2100, $lenEntered, $itemList);
}
# Remove the auto-completion list from the screen.
sub AutoCCancel {
  my $self = shift;
  return $self->SendMessage (2101, 0, 0);
}
# Is there an auto-completion list visible?
sub AutoCActive {
  my $self = shift;
  return $self->SendMessage (2102, 0, 0);
}
# Retrieve the position of the caret when the auto-completion list was displayed.
sub AutoCPosStart {
  my $self = shift;
  return $self->SendMessage (2103, 0, 0);
}
# User has selected an item so remove the list and insert the selection.
sub AutoCComplete {
  my $self = shift;
  return $self->SendMessage (2104, 0, 0);
}
# Define a set of character that when typed cancel the auto-completion list.
sub AutoCStops {
  my ($self, $characterSet) = @_;
  return $self->SendMessageNP (2105, 0, $characterSet);
}
# Change the separator character in the string setting up an auto-completion list.
# Default is space but can be changed if items contain space.
sub AutoCSetSeparator {
  my ($self, $separatorCharacter) = @_;
  return $self->SendMessage (2106, $separatorCharacter, 0);
}
# Retrieve the auto-completion list separator character.
sub AutoCGetSeparator {
  my $self = shift;
  return $self->SendMessage (2107, 0, 0);
}
# Select the item in the auto-completion list that starts with a string.
sub AutoCSelect {
  my ($self, $text) = @_;
  return $self->SendMessageNP (2108, 0, $text);
}
# Should the auto-completion list be cancelled if the user backspaces to a
# position before where the box was created.
sub AutoCSetCancelAtStart {
  my ($self, $cancel) = @_;
  return $self->SendMessage (2110, $cancel, 0);
}
# Retrieve whether auto-completion cancelled by backspacing before start.
sub AutoCGetCancelAtStart {
  my $self = shift;
  return $self->SendMessage (2111, 0, 0);
}
# Define a set of characters that when typed will cause the autocompletion to
# choose the selected item.
sub AutoCSetFillUps {
  my ($self, $characterSet) = @_;
  return $self->SendMessageNP (2112, 0, $characterSet);
}
# Should a single item auto-completion list automatically choose the item.
sub AutoCSetChooseSingle {
  my ($self, $chooseSingle) = @_;
  return $self->SendMessage (2113, $chooseSingle, 0);
}
# Retrieve whether a single item auto-completion list automatically choose the item.
sub AutoCGetChooseSingle {
  my $self = shift;
  return $self->SendMessage (2114, 0, 0);
}
# Set whether case is significant when performing auto-completion searches.
sub AutoCSetIgnoreCase {
  my ($self, $ignoreCase) = @_;
  return $self->SendMessage (2115, $ignoreCase, 0);
}
# Retrieve state of ignore case flag.
sub AutoCGetIgnoreCase {
  my $self = shift;
  return $self->SendMessage (2116, 0, 0);
}
# Display a list of strings and send notification when user chooses one.
sub UserListShow {
  my ($self, $listType, $itemList) = @_;
  return $self->SendMessageNP (2117, $listType, $itemList);
}
# Set whether or not autocompletion is hidden automatically when nothing matches.
sub AutoCSetAutoHide {
  my ($self, $autoHide) = @_;
  return $self->SendMessage (2118, $autoHide, 0);
}
# Retrieve whether or not autocompletion is hidden automatically when nothing matches.
sub AutoCGetAutoHide {
  my $self = shift;
  return $self->SendMessage (2119, 0, 0);
}
# Set whether or not autocompletion deletes any word characters
# after the inserted text upon completion.
sub AutoCSetDropRestOfWord {
  my ($self, $dropRestOfWord) = @_;
  return $self->SendMessage (2270, $dropRestOfWord, 0);
}
# Retrieve whether or not autocompletion deletes any word characters
# after the inserted text upon completion.
sub AutoCGetDropRestOfWord {
  my $self = shift;
  return $self->SendMessage (2271, 0, 0);
}
# Register an XPM image for use in autocompletion lists.
sub RegisterImage {
  my ($self, $type, $xpmData) = @_;
  return $self->SendMessageNP (2405, $type, $xpmData);
}
# Clear all the registered XPM images.
sub ClearRegisteredImages {
  my $self = shift;
  return $self->SendMessage (2408, 0, 0);
}
# Retrieve the auto-completion list type-separator character.
sub AutoCGetTypeSeparator {
  my $self = shift;
  return $self->SendMessage (2285, 0, 0);
}
# Change the type-separator character in the string setting up an auto-completion list.
# Default is '?' but can be changed if items contain '?'.
sub AutoCSetTypeSeparator {
  my ($self, $separatorCharacter) = @_;
  return $self->SendMessage (2286, $separatorCharacter, 0);
}
# Set the number of spaces used for one level of indentation.
sub SetIndent {
  my ($self, $indentSize) = @_;
  return $self->SendMessage (2122, $indentSize, 0);
}
# Retrieve indentation size.
sub GetIndent {
  my $self = shift;
  return $self->SendMessage (2123, 0, 0);
}
# Indentation will only use space characters if useTabs is false, otherwise
# it will use a combination of tabs and spaces.
sub SetUseTabs {
  my ($self, $useTabs) = @_;
  return $self->SendMessage (2124, $useTabs, 0);
}
# Retrieve whether tabs will be used in indentation.
sub GetUseTabs {
  my $self = shift;
  return $self->SendMessage (2125, 0, 0);
}
# Change the indentation of a line to a number of columns.
sub SetLineIndentation {
  my ($self, $line, $indentSize) = @_;
  return $self->SendMessage (2126, $line, $indentSize);
}
# Retrieve the number of columns that a line is indented.
sub GetLineIndentation {
  my ($self, $line) = @_;
  return $self->SendMessage (2127, $line, 0);
}
# Retrieve the position before the first non indentation character on a line.
sub GetLineIndentPosition {
  my ($self, $line) = @_;
  return $self->SendMessage (2128, $line, 0);
}
# Retrieve the column number of a position, taking tab width into account.
sub GetColumn {
  my ($self, $pos) = @_;
  return $self->SendMessage (2129, $pos, 0);
}
# Show or hide the horizontal scroll bar.
sub SetHScrollBar {
  my ($self, $show) = @_;
  return $self->SendMessage (2130, $show, 0);
}
# Is the horizontal scroll bar visible?
sub GetHScrollBar {
  my $self = shift;
  return $self->SendMessage (2131, 0, 0);
}
# Show or hide indentation guides.
sub SetIndentationGuides {
  my ($self, $show) = @_;
  return $self->SendMessage (2132, $show, 0);
}
# Are the indentation guides visible?
sub GetIndentationGuides {
  my $self = shift;
  return $self->SendMessage (2133, 0, 0);
}
# Set the highlighted indentation guide column.
# 0 = no highlighted guide.
sub SetHighlightGuide {
  my ($self, $column) = @_;
  return $self->SendMessage (2134, $column, 0);
}
# Get the highlighted indentation guide column.
sub GetHighlightGuide {
  my $self = shift;
  return $self->SendMessage (2135, 0, 0);
}
# Get the position after the last visible characters on a line.
sub GetLineEndPosition {
  my ($self, $line) = @_;
  return $self->SendMessage (2136, $line, 0);
}
# Get the code page used to interpret the bytes of the document as characters.
sub GetCodePage {
  my $self = shift;
  return $self->SendMessage (2137, 0, 0);
}
# Get the foreground colour of the caret.
sub GetCaretFore {
  my $self = shift;
  my $colour = $self->SendMessage (2138, 0, 0);
  $colour = sprintf ('#%x', $colour);
  $colour =~ s/(.)(..)(..)(..)/$1$4$3$2/;
  return $colour;
}
# In palette mode?
sub GetUsePalette {
  my $self = shift;
  return $self->SendMessage (2139, 0, 0);
}
# In read-only mode?
sub GetReadOnly {
  my $self = shift;
  return $self->SendMessage (2140, 0, 0);
}
# Sets the position of the caret.
sub SetCurrentPos {
  my ($self, $pos) = @_;
  return $self->SendMessage (2141, $pos, 0);
}
# Sets the position that starts the selection - this becomes the anchor.
sub SetSelectionStart {
  my ($self, $pos) = @_;
  return $self->SendMessage (2142, $pos, 0);
}
# Returns the position at the start of the selection.
sub GetSelectionStart {
  my $self = shift;
  return $self->SendMessage (2143, 0, 0);
}
# Sets the position that ends the selection - this becomes the currentPosition.
sub SetSelectionEnd {
  my ($self, $pos) = @_;
  return $self->SendMessage (2144, $pos, 0);
}
# Returns the position at the end of the selection.
sub GetSelectionEnd {
  my $self = shift;
  return $self->SendMessage (2145, 0, 0);
}
# Sets the print magnification added to the point size of each style for printing.
sub SetPrintMagnification {
  my ($self, $magnification) = @_;
  return $self->SendMessage (2146, $magnification, 0);
}
# Returns the print magnification.
sub GetPrintMagnification {
  my $self = shift;
  return $self->SendMessage (2147, 0, 0);
}
# PrintColourMode - use same colours as screen.
use constant SC_PRINT_NORMAL => 0 ;
# PrintColourMode - invert the light value of each style for printing.
use constant SC_PRINT_INVERTLIGHT => 1 ;
# PrintColourMode - force black text on white background for printing.
use constant SC_PRINT_BLACKONWHITE => 2 ;
# PrintColourMode - text stays coloured, but all background is forced to be white for printing.
use constant SC_PRINT_COLOURONWHITE => 3 ;
# PrintColourMode - only the default-background is forced to be white for printing.
use constant SC_PRINT_COLOURONWHITEDEFAULTBG => 4 ;
# Modify colours when printing for clearer printed text.
sub SetPrintColourMode {
  my ($self, $mode) = @_;
  return $self->SendMessage (2148, $mode, 0);
}
# Returns the print colour mode.
sub GetPrintColourMode {
  my $self = shift;
  return $self->SendMessage (2149, 0, 0);
}
use constant SCFIND_WHOLEWORD => 2 ;
use constant SCFIND_MATCHCASE => 4 ;
use constant SCFIND_WORDSTART => 0x00100000 ;
use constant SCFIND_REGEXP => 0x00200000 ;
use constant SCFIND_POSIX => 0x00400000 ;
# Find some text in the document.
# FindText (textToFind, start=0, end=GetLength(), flag = SCFIND_WHOLEWORD)
sub FindText {
  my $self       = shift;
  my $text       = shift;
  my $start      = shift || 0;
  my $end        = shift || $self->GetLength();
  my $flag       = shift || SCFIND_WHOLEWORD;

  return undef if $start >= $end;

  my $texttofind =  pack("LLpLL", $start, $end, $text, 0, 0);
  my $pos = $self->SendMessageNP (2150, $flag, $texttofind);
  return $pos unless defined wantarray;
  my @res = unpack("LLpLL", $texttofind);
  return ($res[3], $res[4]); # pos , lenght
}
# On Windows, will draw the document into a display context such as a printer.
# FormatRange (start=0, end=GetLength(), draw=1)
sub FormatRange {
  my $self       = shift;
  my $start      = shift || 0;
  my $end        = shift || $self->GetLength();
  my $draw       = shift || 1;
  return undef if $start >= $end;

  my $formatrange = pack("LL", $start, $end);
  return $self->SendMessageNP (2151, $draw, $formatrange);
}
# Retrieve the display line at the top of the display.
sub GetFirstVisibleLine {
  my $self = shift;
  return $self->SendMessage (2152, 0, 0);
}
# Retrieve the contents of a line.
# Returns the length of the line.
# Getline (line)
sub GetLine {
  my ($self, $line)  = @_;
  my $lenght = $self->LineLength($line);
  my $text   = " " x ($lenght + 1);

  if ($self->SendMessageNP (2153, $line, $text)) {
    return $text;
  } else {
    return undef;
  }
}
# Returns the number of lines in the document. There is always at least one.
sub GetLineCount {
  my $self = shift;
  return $self->SendMessage (2154, 0, 0);
}
# Sets the size in pixels of the left margin.
sub SetMarginLeft {
  my ($self, $pixelWidth) = @_;
  return $self->SendMessage (2155, 0, $pixelWidth);
}
# Returns the size in pixels of the left margin.
sub GetMarginLeft {
  my $self = shift;
  return $self->SendMessage (2156, 0, 0);
}
# Sets the size in pixels of the right margin.
sub SetMarginRight {
  my ($self, $pixelWidth) = @_;
  return $self->SendMessage (2157, 0, $pixelWidth);
}
# Returns the size in pixels of the right margin.
sub GetMarginRight {
  my $self = shift;
  return $self->SendMessage (2158, 0, 0);
}
# Is the document different from when it was last saved?
sub GetModify {
  my $self = shift;
  return $self->SendMessage (2159, 0, 0);
}
# Select a range of text.
sub SetSel {
  my ($self, $start, $end) = @_;
  return $self->SendMessage (2160, $start, $end);
}
# Retrieve the selected text.
# Return the length of the text.
# GetSelText() : Return selected text
sub GetSelText {
  my $self  = shift;
  my $start = $self->GetSelectionStart();
  my $end   = $self->GetSelectionEnd();

  return undef if $start >= $end;
  my $text   = " " x ($end - $start + 1);

  $self->SendMessageNP (2161, 0, $text);
  return $text;
}
# Retrieve a range of text.
# Return the length of the text.
sub GetTextRange {
  my $self = shift;
  my $start = shift || 0;
  my $end = shift || $self->GetLength();

  return undef if $start >= $end;

  my $text = " " x ($end - $start + 1);
  my $textrange = pack("LLp", $start, $end, $text);
  $self->SendMessageNP (2162, 0, $textrange);
  return $text;
}
# Draw the selection in normal style or with selection highlighted.
sub HideSelection {
  my ($self, $normal) = @_;
  return $self->SendMessage (2163, $normal, 0);
}
# Retrieve the x value of the point in the window where a position is displayed.
sub PointXFromPosition {
  my ($self, $pos) = @_;
  return $self->SendMessage (2164, 0, $pos);
}
# Retrieve the y value of the point in the window where a position is displayed.
sub PointYFromPosition {
  my ($self, $pos) = @_;
  return $self->SendMessage (2165, 0, $pos);
}
# Retrieve the line containing a position.
sub LineFromPosition {
  my ($self, $pos) = @_;
  return $self->SendMessage (2166, $pos, 0);
}
# Retrieve the position at the start of a line.
sub PositionFromLine {
  my ($self, $line) = @_;
  return $self->SendMessage (2167, $line, 0);
}
# Scroll horizontally and vertically.
sub LineScroll {
  my ($self, $columns, $lines) = @_;
  return $self->SendMessage (2168, $columns, $lines);
}
# Ensure the caret is visible.
sub ScrollCaret {
  my $self = shift;
  return $self->SendMessage (2169, 0, 0);
}
# Replace the selected text with the argument text.
sub ReplaceSel {
  my ($self, $text) = @_;
  return $self->SendMessageNP (2170, 0, $text);
}
# Set to read only or read write.
sub SetReadOnly {
  my ($self, $readOnly) = @_;
  return $self->SendMessage (2171, $readOnly, 0);
}
# Null operation.
sub Null {
  my $self = shift;
  return $self->SendMessage (2172, 0, 0);
}
# Will a paste succeed?
sub CanPaste {
  my $self = shift;
  return $self->SendMessage (2173, 0, 0);
}
# Are there any undoable actions in the undo history?
sub CanUndo {
  my $self = shift;
  return $self->SendMessage (2174, 0, 0);
}
# Delete the undo history.
sub EmptyUndoBuffer {
  my $self = shift;
  return $self->SendMessage (2175, 0, 0);
}
# Undo one action in the undo history.
sub Undo {
  my $self = shift;
  return $self->SendMessage (2176, 0, 0);
}
# Cut the selection to the clipboard.
sub Cut {
  my $self = shift;
  return $self->SendMessage (2177, 0, 0);
}
# Copy the selection to the clipboard.
sub Copy {
  my $self = shift;
  return $self->SendMessage (2178, 0, 0);
}
# Paste the contents of the clipboard into the document replacing the selection.
sub Paste {
  my $self = shift;
  return $self->SendMessage (2179, 0, 0);
}
# Clear the selection.
sub Clear {
  my $self = shift;
  return $self->SendMessage (2180, 0, 0);
}
# Replace the contents of the document with the argument text.
sub SetText {
  my ($self, $text) = @_;
  return $self->SendMessageNP (2181, 0, $text);
}
# Retrieve all the text in the document.
# Returns number of characters retrieved.
# GetText() : Return all text
sub GetText {
  my $self   = shift;
  my $lenght = $self->GetTextLength() + 1;
  my $text   = " " x ($lenght+1);

  if ($self->SendMessageNP (2182, $lenght, $text)) {
    return $text;
  } else {
    return undef;
  }
}
# Retrieve the number of characters in the document.
sub GetTextLength {
  my $self = shift;
  return $self->SendMessage (2183, 0, 0);
}
# Retrieve a pointer to a function that processes messages for this Scintilla.
sub GetDirectFunction {
  my $self = shift;
  return $self->SendMessage (2184, 0, 0);
}
# Retrieve a pointer value to use as the first argument when calling
# the function returned by GetDirectFunction.
sub GetDirectPointer {
  my $self = shift;
  return $self->SendMessage (2185, 0, 0);
}
# Set to overtype (true) or insert mode.
sub SetOvertype {
  my ($self, $overtype) = @_;
  return $self->SendMessage (2186, $overtype, 0);
}
# Returns true if overtype mode is active otherwise false is returned.
sub GetOvertype {
  my $self = shift;
  return $self->SendMessage (2187, 0, 0);
}
# Set the width of the insert mode caret.
sub SetCaretWidth {
  my ($self, $pixelWidth) = @_;
  return $self->SendMessage (2188, $pixelWidth, 0);
}
# Returns the width of the insert mode caret.
sub GetCaretWidth {
  my $self = shift;
  return $self->SendMessage (2189, 0, 0);
}
# Sets the position that starts the target which is used for updating the
# document without affecting the scroll position.
sub SetTargetStart {
  my ($self, $pos) = @_;
  return $self->SendMessage (2190, $pos, 0);
}
# Get the position that starts the target.
sub GetTargetStart {
  my $self = shift;
  return $self->SendMessage (2191, 0, 0);
}
# Sets the position that ends the target which is used for updating the
# document without affecting the scroll position.
sub SetTargetEnd {
  my ($self, $pos) = @_;
  return $self->SendMessage (2192, $pos, 0);
}
# Get the position that ends the target.
sub GetTargetEnd {
  my $self = shift;
  return $self->SendMessage (2193, 0, 0);
}
# Replace the target text with the argument text.
# Text is counted so it can contain NULs.
# Returns the length of the replacement text.
# ReplaceTarget(text)
sub ReplaceTarget {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2194, $length, $text);
}
# Replace the target text with the argument text after \d processing.
# Text is counted so it can contain NULs.
# Looks for \d where d is between 1 and 9 and replaces these with the strings
# matched in the last search operation which were surrounded by \( and \).
# Returns the length of the replacement text including any change
# caused by processing the \d patterns.
# ReplaceTargetRE(text)
sub ReplaceTargetRE {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2195, $length, $text);
}
# Search for a counted string in the target and set the target to the found
# range. Text is counted so it can contain NULs.
# Returns length of range or -1 for failure in which case target is not moved.
# SearchInTarget(text)
sub SearchInTarget {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2197, $length, $text);
}
# Set the search flags used by SearchInTarget.
sub SetSearchFlags {
  my ($self, $flags) = @_;
  return $self->SendMessage (2198, $flags, 0);
}
# Get the search flags used by SearchInTarget.
sub GetSearchFlags {
  my $self = shift;
  return $self->SendMessage (2199, 0, 0);
}
# Show a call tip containing a definition near position pos.
sub CallTipShow {
  my ($self, $pos, $definition) = @_;
  return $self->SendMessageNP (2200, $pos, $definition);
}
# Remove the call tip from the screen.
sub CallTipCancel {
  my $self = shift;
  return $self->SendMessage (2201, 0, 0);
}
# Is there an active call tip?
sub CallTipActive {
  my $self = shift;
  return $self->SendMessage (2202, 0, 0);
}
# Retrieve the position where the caret was before displaying the call tip.
sub CallTipPosStart {
  my $self = shift;
  return $self->SendMessage (2203, 0, 0);
}
# Highlight a segment of the definition.
sub CallTipSetHlt {
  my ($self, $start, $end) = @_;
  return $self->SendMessage (2204, $start, $end);
}
# Set the background colour for the call tip.
sub CallTipSetBack {
  my ($self, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2205, int hex $back, 0);
}
# Set the foreground colour for the call tip.
sub CallTipSetFore {
  my ($self, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2206, int hex $fore, 0);
}
# Set the foreground colour for the highlighted part of the call tip.
sub CallTipSetForeHlt {
  my ($self, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2207, int hex $fore, 0);
}
# Find the display line of a document line taking hidden lines into account.
sub VisibleFromDocLine {
  my ($self, $line) = @_;
  return $self->SendMessage (2220, $line, 0);
}
# Find the document line of a display line taking hidden lines into account.
sub DocLineFromVisible {
  my ($self, $lineDisplay) = @_;
  return $self->SendMessage (2221, $lineDisplay, 0);
}
use constant SC_FOLDLEVELBASE => 0x400 ;
use constant SC_FOLDLEVELWHITEFLAG => 0x1000 ;
use constant SC_FOLDLEVELHEADERFLAG => 0x2000 ;
use constant SC_FOLDLEVELBOXHEADERFLAG => 0x4000 ;
use constant SC_FOLDLEVELBOXFOOTERFLAG => 0x8000 ;
use constant SC_FOLDLEVELCONTRACTED => 0x10000 ;
use constant SC_FOLDLEVELUNINDENT => 0x20000 ;
use constant SC_FOLDLEVELNUMBERMASK => 0x0FFF ;
# Set the fold level of a line.
# This encodes an integer level along with flags indicating whether the
# line is a header and whether it is effectively white space.
sub SetFoldLevel {
  my ($self, $line, $level) = @_;
  return $self->SendMessage (2222, $line, $level);
}
# Retrieve the fold level of a line.
sub GetFoldLevel {
  my ($self, $line) = @_;
  return $self->SendMessage (2223, $line, 0);
}
# Find the last child line of a header line.
sub GetLastChild {
  my ($self, $line, $level) = @_;
  return $self->SendMessage (2224, $line, $level);
}
# Find the parent line of a child line.
sub GetFoldParent {
  my ($self, $line) = @_;
  return $self->SendMessage (2225, $line, 0);
}
# Make a range of lines visible.
sub ShowLines {
  my ($self, $lineStart, $lineEnd) = @_;
  return $self->SendMessage (2226, $lineStart, $lineEnd);
}
# Make a range of lines invisible.
sub HideLines {
  my ($self, $lineStart, $lineEnd) = @_;
  return $self->SendMessage (2227, $lineStart, $lineEnd);
}
# Is a line visible?
sub GetLineVisible {
  my ($self, $line) = @_;
  return $self->SendMessage (2228, $line, 0);
}
# Show the children of a header line.
sub SetFoldExpanded {
  my ($self, $line, $expanded) = @_;
  return $self->SendMessage (2229, $line, $expanded);
}
# Is a header line expanded?
sub GetFoldExpanded {
  my ($self, $line) = @_;
  return $self->SendMessage (2230, $line, 0);
}
# Switch a header line between expanded and contracted.
sub ToggleFold {
  my ($self, $line) = @_;
  return $self->SendMessage (2231, $line, 0);
}
# Ensure a particular line is visible by expanding any header line hiding it.
sub EnsureVisible {
  my ($self, $line) = @_;
  return $self->SendMessage (2232, $line, 0);
}
use constant SC_FOLDFLAG_LINEBEFORE_EXPANDED => 0x0002 ;
use constant SC_FOLDFLAG_LINEBEFORE_CONTRACTED => 0x0004 ;
use constant SC_FOLDFLAG_LINEAFTER_EXPANDED => 0x0008 ;
use constant SC_FOLDFLAG_LINEAFTER_CONTRACTED => 0x0010 ;
use constant SC_FOLDFLAG_LEVELNUMBERS => 0x0040 ;
use constant SC_FOLDFLAG_BOX => 0x0001 ;
# Set some style options for folding.
sub SetFoldFlags {
  my ($self, $flags) = @_;
  return $self->SendMessage (2233, $flags, 0);
}
# Ensure a particular line is visible by expanding any header line hiding it.
# Use the currently set visibility policy to determine which range to display.
sub EnsureVisibleEnforcePolicy {
  my ($self, $line) = @_;
  return $self->SendMessage (2234, $line, 0);
}
# Sets whether a tab pressed when caret is within indentation indents.
sub SetTabIndents {
  my ($self, $tabIndents) = @_;
  return $self->SendMessage (2260, $tabIndents, 0);
}
# Does a tab pressed when caret is within indentation indent?
sub GetTabIndents {
  my $self = shift;
  return $self->SendMessage (2261, 0, 0);
}
# Sets whether a backspace pressed when caret is within indentation unindents.
sub SetBackSpaceUnIndents {
  my ($self, $bsUnIndents) = @_;
  return $self->SendMessage (2262, $bsUnIndents, 0);
}
# Does a backspace pressed when caret is within indentation unindent?
sub GetBackSpaceUnIndents {
  my $self = shift;
  return $self->SendMessage (2263, 0, 0);
}
use constant SC_TIME_FOREVER => 10000000 ;
# Sets the time the mouse must sit still to generate a mouse dwell event.
sub SetMouseDwellTime {
  my ($self, $periodMilliseconds) = @_;
  return $self->SendMessage (2264, $periodMilliseconds, 0);
}
# Retrieve the time the mouse must sit still to generate a mouse dwell event.
sub GetMouseDwellTime {
  my $self = shift;
  return $self->SendMessage (2265, 0, 0);
}
# Get position of start of word.
sub WordStartPosition {
  my ($self, $pos, $onlyWordCharacters) = @_;
  return $self->SendMessage (2266, $pos, $onlyWordCharacters);
}
# Get position of end of word.
sub WordEndPosition {
  my ($self, $pos, $onlyWordCharacters) = @_;
  return $self->SendMessage (2267, $pos, $onlyWordCharacters);
}
use constant SC_WRAP_NONE => 0 ;
use constant SC_WRAP_WORD => 1 ;
# Sets whether text is word wrapped.
sub SetWrapMode {
  my ($self, $mode) = @_;
  return $self->SendMessage (2268, $mode, 0);
}
# Retrieve whether text is word wrapped.
sub GetWrapMode {
  my $self = shift;
  return $self->SendMessage (2269, 0, 0);
}
use constant SC_CACHE_NONE => 0 ;
use constant SC_CACHE_CARET => 1 ;
use constant SC_CACHE_PAGE => 2 ;
use constant SC_CACHE_DOCUMENT => 3 ;
# Sets the degree of caching of layout information.
sub SetLayoutCache {
  my ($self, $mode) = @_;
  return $self->SendMessage (2272, $mode, 0);
}
# Retrieve the degree of caching of layout information.
sub GetLayoutCache {
  my $self = shift;
  return $self->SendMessage (2273, 0, 0);
}
# Sets the document width assumed for scrolling.
sub SetScrollWidth {
  my ($self, $pixelWidth) = @_;
  return $self->SendMessage (2274, $pixelWidth, 0);
}
# Retrieve the document width assumed for scrolling.
sub GetScrollWidth {
  my $self = shift;
  return $self->SendMessage (2275, 0, 0);
}
# Measure the pixel width of some text in a particular style.
# NUL terminated text argument.
# Does not handle tab or control characters.
sub TextWidth {
  my ($self, $style, $text) = @_;
  return $self->SendMessageNP (2276, $style, $text);
}
# Sets the scroll range so that maximum scroll position has
# the last line at the bottom of the view (default).
# Setting this to false allows scrolling one page below the last line.
sub SetEndAtLastLine {
  my ($self, $endAtLastLine) = @_;
  return $self->SendMessage (2277, $endAtLastLine, 0);
}
# Retrieve whether the maximum scroll position has the last
# line at the bottom of the view.
sub GetEndAtLastLine {
  my $self = shift;
  return $self->SendMessage (2278, 0, 0);
}
# Retrieve the height of a particular line of text in pixels.
sub TextHeight {
  my ($self, $line) = @_;
  return $self->SendMessage (2279, $line, 0);
}
# Show or hide the vertical scroll bar.
sub SetVScrollBar {
  my ($self, $show) = @_;
  return $self->SendMessage (2280, $show, 0);
}
# Is the vertical scroll bar visible?
sub GetVScrollBar {
  my $self = shift;
  return $self->SendMessage (2281, 0, 0);
}
# Append a string to the end of the document without changing the selection.
# AppendText(text)
sub AppendText {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2282, $length, $text);
}
# Is drawing done in two phases with backgrounds drawn before faoregrounds?
sub GetTwoPhaseDraw {
  my $self = shift;
  return $self->SendMessage (2283, 0, 0);
}
# In twoPhaseDraw mode, drawing is performed in two phases, first the background
# and then the foreground. This avoids chopping off characters that overlap the next run.
sub SetTwoPhaseDraw {
  my ($self, $twoPhase) = @_;
  return $self->SendMessage (2284, $twoPhase, 0);
}
# Make the target range start and end be the same as the selection range start and end.
sub TargetFromSelection {
  my $self = shift;
  return $self->SendMessage (2287, 0, 0);
}
# Join the lines in the target.
sub LinesJoin {
  my $self = shift;
  return $self->SendMessage (2288, 0, 0);
}
# Split the lines in the target into lines that are less wide than pixelWidth
# where possible.
sub LinesSplit {
  my ($self, $pixelWidth) = @_;
  return $self->SendMessage (2289, $pixelWidth, 0);
}
# Set the colours used as a chequerboard pattern in the fold margin
sub SetFoldMarginColour {
  my ($self, $useSetting, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2290, $useSetting, int hex $back);
}
sub SetFoldMarginHiColour {
  my ($self, $useSetting, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2291, $useSetting, int hex $fore);
}
# Move caret down one line.
sub LineDown {
  my $self = shift;
  return $self->SendMessage (2300, 0, 0);
}
# Move caret down one line extending selection to new caret position.
sub LineDownExtend {
  my $self = shift;
  return $self->SendMessage (2301, 0, 0);
}
# Move caret up one line.
sub LineUp {
  my $self = shift;
  return $self->SendMessage (2302, 0, 0);
}
# Move caret up one line extending selection to new caret position.
sub LineUpExtend {
  my $self = shift;
  return $self->SendMessage (2303, 0, 0);
}
# Move caret left one character.
sub CharLeft {
  my $self = shift;
  return $self->SendMessage (2304, 0, 0);
}
# Move caret left one character extending selection to new caret position.
sub CharLeftExtend {
  my $self = shift;
  return $self->SendMessage (2305, 0, 0);
}
# Move caret right one character.
sub CharRight {
  my $self = shift;
  return $self->SendMessage (2306, 0, 0);
}
# Move caret right one character extending selection to new caret position.
sub CharRightExtend {
  my $self = shift;
  return $self->SendMessage (2307, 0, 0);
}
# Move caret left one word.
sub WordLeft {
  my $self = shift;
  return $self->SendMessage (2308, 0, 0);
}
# Move caret left one word extending selection to new caret position.
sub WordLeftExtend {
  my $self = shift;
  return $self->SendMessage (2309, 0, 0);
}
# Move caret right one word.
sub WordRight {
  my $self = shift;
  return $self->SendMessage (2310, 0, 0);
}
# Move caret right one word extending selection to new caret position.
sub WordRightExtend {
  my $self = shift;
  return $self->SendMessage (2311, 0, 0);
}
# Move caret to first position on line.
sub Home {
  my $self = shift;
  return $self->SendMessage (2312, 0, 0);
}
# Move caret to first position on line extending selection to new caret position.
sub HomeExtend {
  my $self = shift;
  return $self->SendMessage (2313, 0, 0);
}
# Move caret to last position on line.
sub LineEnd {
  my $self = shift;
  return $self->SendMessage (2314, 0, 0);
}
# Move caret to last position on line extending selection to new caret position.
sub LineEndExtend {
  my $self = shift;
  return $self->SendMessage (2315, 0, 0);
}
# Move caret to first position in document.
sub DocumentStart {
  my $self = shift;
  return $self->SendMessage (2316, 0, 0);
}
# Move caret to first position in document extending selection to new caret position.
sub DocumentStartExtend {
  my $self = shift;
  return $self->SendMessage (2317, 0, 0);
}
# Move caret to last position in document.
sub DocumentEnd {
  my $self = shift;
  return $self->SendMessage (2318, 0, 0);
}
# Move caret to last position in document extending selection to new caret position.
sub DocumentEndExtend {
  my $self = shift;
  return $self->SendMessage (2319, 0, 0);
}
# Move caret one page up.
sub PageUp {
  my $self = shift;
  return $self->SendMessage (2320, 0, 0);
}
# Move caret one page up extending selection to new caret position.
sub PageUpExtend {
  my $self = shift;
  return $self->SendMessage (2321, 0, 0);
}
# Move caret one page down.
sub PageDown {
  my $self = shift;
  return $self->SendMessage (2322, 0, 0);
}
# Move caret one page down extending selection to new caret position.
sub PageDownExtend {
  my $self = shift;
  return $self->SendMessage (2323, 0, 0);
}
# Switch from insert to overtype mode or the reverse.
sub EditToggleOvertype {
  my $self = shift;
  return $self->SendMessage (2324, 0, 0);
}
# Cancel any modes such as call tip or auto-completion list display.
sub Cancel {
  my $self = shift;
  return $self->SendMessage (2325, 0, 0);
}
# Delete the selection or if no selection, the character before the caret.
sub DeleteBack {
  my $self = shift;
  return $self->SendMessage (2326, 0, 0);
}
# If selection is empty or all on one line replace the selection with a tab character.
# If more than one line selected, indent the lines.
sub Tab {
  my $self = shift;
  return $self->SendMessage (2327, 0, 0);
}
# Dedent the selected lines.
sub BackTab {
  my $self = shift;
  return $self->SendMessage (2328, 0, 0);
}
# Insert a new line, may use a CRLF, CR or LF depending on EOL mode.
sub NewLine {
  my $self = shift;
  return $self->SendMessage (2329, 0, 0);
}
# Insert a Form Feed character.
sub FormFeed {
  my $self = shift;
  return $self->SendMessage (2330, 0, 0);
}
# Move caret to before first visible character on line.
# If already there move to first character on line.
sub VCHome {
  my $self = shift;
  return $self->SendMessage (2331, 0, 0);
}
# Like VCHome but extending selection to new caret position.
sub VCHomeExtend {
  my $self = shift;
  return $self->SendMessage (2332, 0, 0);
}
# Magnify the displayed text by increasing the sizes by 1 point.
sub ZoomIn {
  my $self = shift;
  return $self->SendMessage (2333, 0, 0);
}
# Make the displayed text smaller by decreasing the sizes by 1 point.
sub ZoomOut {
  my $self = shift;
  return $self->SendMessage (2334, 0, 0);
}
# Delete the word to the left of the caret.
sub DelWordLeft {
  my $self = shift;
  return $self->SendMessage (2335, 0, 0);
}
# Delete the word to the right of the caret.
sub DelWordRight {
  my $self = shift;
  return $self->SendMessage (2336, 0, 0);
}
# Cut the line containing the caret.
sub LineCut {
  my $self = shift;
  return $self->SendMessage (2337, 0, 0);
}
# Delete the line containing the caret.
sub LineDelete {
  my $self = shift;
  return $self->SendMessage (2338, 0, 0);
}
# Switch the current line with the previous.
sub LineTranspose {
  my $self = shift;
  return $self->SendMessage (2339, 0, 0);
}
# Duplicate the current line.
sub LineDuplicate {
  my $self = shift;
  return $self->SendMessage (2404, 0, 0);
}
# Transform the selection to lower case.
sub LowerCase {
  my $self = shift;
  return $self->SendMessage (2340, 0, 0);
}
# Transform the selection to upper case.
sub UpperCase {
  my $self = shift;
  return $self->SendMessage (2341, 0, 0);
}
# Scroll the document down, keeping the caret visible.
sub LineScrollDown {
  my $self = shift;
  return $self->SendMessage (2342, 0, 0);
}
# Scroll the document up, keeping the caret visible.
sub LineScrollUp {
  my $self = shift;
  return $self->SendMessage (2343, 0, 0);
}
# Delete the selection or if no selection, the character before the caret.
# Will not delete the character before at the start of a line.
sub DeleteBackNotLine {
  my $self = shift;
  return $self->SendMessage (2344, 0, 0);
}
# Move caret to first position on display line.
sub HomeDisplay {
  my $self = shift;
  return $self->SendMessage (2345, 0, 0);
}
# Move caret to first position on display line extending selection to
# new caret position.
sub HomeDisplayExtend {
  my $self = shift;
  return $self->SendMessage (2346, 0, 0);
}
# Move caret to last position on display line.
sub LineEndDisplay {
  my $self = shift;
  return $self->SendMessage (2347, 0, 0);
}
# Move caret to last position on display line extending selection to new
# caret position.
sub LineEndDisplayExtend {
  my $self = shift;
  return $self->SendMessage (2348, 0, 0);
}
# These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)?
# except they behave differently when word-wrap is enabled:
# They go first to the start / end of the display line, like (Home|LineEnd)Display
# The difference is that, the cursor is already at the point, it goes on to the start
# or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.
sub HomeWrap {
  my $self = shift;
  return $self->SendMessage (2349, 0, 0);
}
sub HomeWrapExtend {
  my $self = shift;
  return $self->SendMessage (2450, 0, 0);
}
sub LineEndWrap {
  my $self = shift;
  return $self->SendMessage (2451, 0, 0);
}
sub LineEndWrapExtend {
  my $self = shift;
  return $self->SendMessage (2452, 0, 0);
}
sub VCHomeWrap {
  my $self = shift;
  return $self->SendMessage (2453, 0, 0);
}
sub VCHomeWrapExtend {
  my $self = shift;
  return $self->SendMessage (2454, 0, 0);
}
# Copy the line containing the caret.
sub LineCopy {
  my $self = shift;
  return $self->SendMessage (2455, 0, 0);
}
# Move the caret inside current view if it's not there already.
sub MoveCaretInsideView {
  my $self = shift;
  return $self->SendMessage (2401, 0, 0);
}
# How many characters are on a line, not including end of line characters?
sub LineLength {
  my ($self, $line) = @_;
  return $self->SendMessage (2350, $line, 0);
}
# Highlight the characters at two positions.
sub BraceHighlight {
  my ($self, $pos1, $pos2) = @_;
  return $self->SendMessage (2351, $pos1, $pos2);
}
# Highlight the character at a position indicating there is no matching brace.
sub BraceBadLight {
  my ($self, $pos) = @_;
  return $self->SendMessage (2352, $pos, 0);
}
# Find the position of a matching brace or INVALID_POSITION if no match.
sub BraceMatch {
  my ($self, $pos) = @_;
  return $self->SendMessage (2353, $pos, 0);
}
# Are the end of line characters visible?
sub GetViewEOL {
  my $self = shift;
  return $self->SendMessage (2355, 0, 0);
}
# Make the end of line characters visible or invisible.
sub SetViewEOL {
  my ($self, $visible) = @_;
  return $self->SendMessage (2356, $visible, 0);
}
# Retrieve a pointer to the document object.
sub GetDocPointer {
  my $self = shift;
  return $self->SendMessage (2357, 0, 0);
}
# Change the document object used.
sub SetDocPointer {
  my ($self, $pointer) = @_;
  return $self->SendMessage (2358, 0, $pointer);
}
# Set which document modification events are sent to the container.
sub SetModEventMask {
  my ($self, $mask) = @_;
  return $self->SendMessage (2359, $mask, 0);
}
use constant EDGE_NONE => 0 ;
use constant EDGE_LINE => 1 ;
use constant EDGE_BACKGROUND => 2 ;
# Retrieve the column number which text should be kept within.
sub GetEdgeColumn {
  my $self = shift;
  return $self->SendMessage (2360, 0, 0);
}
# Set the column number of the edge.
# If text goes past the edge then it is highlighted.
sub SetEdgeColumn {
  my ($self, $column) = @_;
  return $self->SendMessage (2361, $column, 0);
}
# Retrieve the edge highlight mode.
sub GetEdgeMode {
  my $self = shift;
  return $self->SendMessage (2362, 0, 0);
}
# The edge may be displayed by a line (EDGE_LINE) or by highlighting text that
# goes beyond it (EDGE_BACKGROUND) or not displayed at all (EDGE_NONE).
sub SetEdgeMode {
  my ($self, $mode) = @_;
  return $self->SendMessage (2363, $mode, 0);
}
# Retrieve the colour used in edge indication.
sub GetEdgeColour {
  my $self = shift;
  my $colour = $self->SendMessage (2364, 0, 0);
  $colour = sprintf ('#%x', $colour);
  $colour =~ s/(.)(..)(..)(..)/$1$4$3$2/;
  return $colour;
}
# Change the colour used in edge indication.
sub SetEdgeColour {
  my ($self, $edgeColour) = @_;
  $edgeColour =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2365, int hex $edgeColour, 0);
}
# Sets the current caret position to be the search anchor.
sub SearchAnchor {
  my $self = shift;
  return $self->SendMessage (2366, 0, 0);
}
# Find some text starting at the search anchor.
# Does not ensure the selection is visible.
sub SearchNext {
  my ($self, $flags, $text) = @_;
  return $self->SendMessageNP (2367, $flags, $text);
}
# Find some text starting at the search anchor and moving backwards.
# Does not ensure the selection is visible.
sub SearchPrev {
  my ($self, $flags, $text) = @_;
  return $self->SendMessageNP (2368, $flags, $text);
}
# Retrieves the number of lines completely visible.
sub LinesOnScreen {
  my $self = shift;
  return $self->SendMessage (2370, 0, 0);
}
# Set whether a pop up menu is displayed automatically when the user presses
# the wrong mouse button.
sub UsePopUp {
  my ($self, $allowPopUp) = @_;
  return $self->SendMessage (2371, $allowPopUp, 0);
}
# Is the selection rectangular? The alternative is the more common stream selection.
sub SelectionIsRectangle {
  my $self = shift;
  return $self->SendMessage (2372, 0, 0);
}
# Set the zoom level. This number of points is added to the size of all fonts.
# It may be positive to magnify or negative to reduce.
sub SetZoom {
  my ($self, $zoom) = @_;
  return $self->SendMessage (2373, $zoom, 0);
}
# Retrieve the zoom level.
sub GetZoom {
  my $self = shift;
  return $self->SendMessage (2374, 0, 0);
}
# Create a new document object.
# Starts with reference count of 1 and not selected into editor.
sub CreateDocument {
  my $self = shift;
  return $self->SendMessage (2375, 0, 0);
}
# Extend life of document.
sub AddRefDocument {
  my ($self, $doc) = @_;
  return $self->SendMessage (2376, 0, $doc);
}
# Release a reference to the document, deleting document if it fades to black.
sub ReleaseDocument {
  my ($self, $doc) = @_;
  return $self->SendMessage (2377, 0, $doc);
}
# Get which document modification events are sent to the container.
sub GetModEventMask {
  my $self = shift;
  return $self->SendMessage (2378, 0, 0);
}
# Change internal focus flag.
sub SetFocus {
  my ($self, $focus) = @_;
  return $self->SendMessage (2380, $focus, 0);
}
# Get internal focus flag.
sub GetFocus {
  my $self = shift;
  return $self->SendMessage (2381, 0, 0);
}
# Change error status - 0 = OK.
sub SetStatus {
  my ($self, $statusCode) = @_;
  return $self->SendMessage (2382, $statusCode, 0);
}
# Get error status.
sub GetStatus {
  my $self = shift;
  return $self->SendMessage (2383, 0, 0);
}
# Set whether the mouse is captured when its button is pressed.
sub SetMouseDownCaptures {
  my ($self, $captures) = @_;
  return $self->SendMessage (2384, $captures, 0);
}
# Get whether mouse gets captured.
sub GetMouseDownCaptures {
  my $self = shift;
  return $self->SendMessage (2385, 0, 0);
}
use constant SC_CURSORNORMAL => -1 ;
use constant SC_CURSORWAIT => 4 ;
# Sets the cursor to one of the SC_CURSOR* values.
sub SetCursor {
  my ($self, $cursorType) = @_;
  return $self->SendMessage (2386, $cursorType, 0);
}
# Get cursor type.
sub GetCursor {
  my $self = shift;
  return $self->SendMessage (2387, 0, 0);
}
# Change the way control characters are displayed:
# If symbol is < 32, keep the drawn way, else, use the given character.
sub SetControlCharSymbol {
  my ($self, $symbol) = @_;
  return $self->SendMessage (2388, $symbol, 0);
}
# Get the way control characters are displayed.
sub GetControlCharSymbol {
  my $self = shift;
  return $self->SendMessage (2389, 0, 0);
}
# Move to the previous change in capitalisation.
sub WordPartLeft {
  my $self = shift;
  return $self->SendMessage (2390, 0, 0);
}
# Move to the previous change in capitalisation extending selection
# to new caret position.
sub WordPartLeftExtend {
  my $self = shift;
  return $self->SendMessage (2391, 0, 0);
}
# Move to the change next in capitalisation.
sub WordPartRight {
  my $self = shift;
  return $self->SendMessage (2392, 0, 0);
}
# Move to the next change in capitalisation extending selection
# to new caret position.
sub WordPartRightExtend {
  my $self = shift;
  return $self->SendMessage (2393, 0, 0);
}
# Constants for use with SetVisiblePolicy, similar to SetCaretPolicy.
use constant VISIBLE_SLOP => 0x01 ;
use constant VISIBLE_STRICT => 0x04 ;
# Set the way the display area is determined when a particular line
# is to be moved to by Find, FindNext, GotoLine, etc.
sub SetVisiblePolicy {
  my ($self, $visiblePolicy, $visibleSlop) = @_;
  return $self->SendMessage (2394, $visiblePolicy, $visibleSlop);
}
# Delete back from the current position to the start of the line.
sub DelLineLeft {
  my $self = shift;
  return $self->SendMessage (2395, 0, 0);
}
# Delete forwards from the current position to the end of the line.
sub DelLineRight {
  my $self = shift;
  return $self->SendMessage (2396, 0, 0);
}
# Get and Set the xOffset (ie, horizonal scroll position).
sub SetXOffset {
  my ($self, $newOffset) = @_;
  return $self->SendMessage (2397, $newOffset, 0);
}
sub GetXOffset {
  my $self = shift;
  return $self->SendMessage (2398, 0, 0);
}
# Set the last x chosen value to be the caret x position.
sub ChooseCaretX {
  my $self = shift;
  return $self->SendMessage (2399, 0, 0);
}
# Set the focus to this Scintilla widget.
# GTK+ Specific.
sub GrabFocus {
  my $self = shift;
  return $self->SendMessage (2400, 0, 0);
}
# Caret policy, used by SetXCaretPolicy and SetYCaretPolicy.
# If CARET_SLOP is set, we can define a slop value: caretSlop.
# This value defines an unwanted zone (UZ) where the caret is... unwanted.
# This zone is defined as a number of pixels near the vertical margins,
# and as a number of lines near the horizontal margins.
# By keeping the caret away from the edges, it is seen within its context,
# so it is likely that the identifier that the caret is on can be completely seen,
# and that the current line is seen with some of the lines following it which are
# often dependent on that line.
use constant CARET_SLOP => 0x01 ;
# If CARET_STRICT is set, the policy is enforced... strictly.
# The caret is centred on the display if slop is not set,
# and cannot go in the UZ if slop is set.
use constant CARET_STRICT => 0x04 ;
# If CARET_JUMPS is set, the display is moved more energetically
# so the caret can move in the same direction longer before the policy is applied again.
use constant CARET_JUMPS => 0x10 ;
# If CARET_EVEN is not set, instead of having symmetrical UZs,
# the left and bottom UZs are extended up to right and top UZs respectively.
# This way, we favour the displaying of useful information: the begining of lines,
# where most code reside, and the lines after the caret, eg. the body of a function.
use constant CARET_EVEN => 0x08 ;
# Set the way the caret is kept visible when going sideway.
# The exclusion zone is given in pixels.
sub SetXCaretPolicy {
  my ($self, $caretPolicy, $caretSlop) = @_;
  return $self->SendMessage (2402, $caretPolicy, $caretSlop);
}
# Set the way the line the caret is on is kept visible.
# The exclusion zone is given in lines.
sub SetYCaretPolicy {
  my ($self, $caretPolicy, $caretSlop) = @_;
  return $self->SendMessage (2403, $caretPolicy, $caretSlop);
}
# Set printing to line wrapped (SC_WRAP_WORD) or not line wrapped (SC_WRAP_NONE).
sub SetPrintWrapMode {
  my ($self, $mode) = @_;
  return $self->SendMessage (2406, $mode, 0);
}
# Is printing line wrapped?
sub GetPrintWrapMode {
  my $self = shift;
  return $self->SendMessage (2407, 0, 0);
}
# Set a fore colour for active hotspots.
sub SetHotspotActiveFore {
  my ($self, $useSetting, $fore) = @_;
  $fore =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2410, $useSetting, int hex $fore);
}
# Set a back colour for active hotspots.
sub SetHotspotActiveBack {
  my ($self, $useSetting, $back) = @_;
  $back =~ s/.(..)(..)(..)/$3$2$1/;
  return $self->SendMessage (2411, $useSetting, int hex $back);
}
# Enable / Disable underlining active hotspots.
sub SetHotspotActiveUnderline {
  my ($self, $underline) = @_;
  return $self->SendMessage (2412, $underline, 0);
}
# Limit hotspots to single line so hotspots on two lines don't merge.
sub SetHotspotSingleLine {
  my ($self, $singleLine) = @_;
  return $self->SendMessage (2421, $singleLine, 0);
}
# Move caret between paragraphs (delimited by empty lines).
sub ParaDown {
  my $self = shift;
  return $self->SendMessage (2413, 0, 0);
}
sub ParaDownExtend {
  my $self = shift;
  return $self->SendMessage (2414, 0, 0);
}
sub ParaUp {
  my $self = shift;
  return $self->SendMessage (2415, 0, 0);
}
sub ParaUpExtend {
  my $self = shift;
  return $self->SendMessage (2416, 0, 0);
}
# Given a valid document position, return the previous position taking code
# page into account. Returns 0 if passed 0.
sub PositionBefore {
  my ($self, $pos) = @_;
  return $self->SendMessage (2417, $pos, 0);
}
# Given a valid document position, return the next position taking code
# page into account. Maximum value returned is the last position in the document.
sub PositionAfter {
  my ($self, $pos) = @_;
  return $self->SendMessage (2418, $pos, 0);
}
# Copy a range of text to the clipboard. Positions are clipped into the document.
sub CopyRange {
  my ($self, $start, $end) = @_;
  return $self->SendMessage (2419, $start, $end);
}
# Copy argument text to the clipboard.
# CopyText(text)
sub CopyText {
  my ($self, $text) = @_;
  my $length = length $text;
  return $self->SendMessageNP (2420, $length, $text);
}
use constant SC_SEL_STREAM => 0 ;
use constant SC_SEL_RECTANGLE => 1 ;
use constant SC_SEL_LINES => 2 ;
# Set the selection mode to stream (SC_SEL_STREAM) or rectangular (SC_SEL_RECTANGLE) or
# by lines (SC_SEL_LINES).
sub SetSelectionMode {
  my ($self, $mode) = @_;
  return $self->SendMessage (2422, $mode, 0);
}
# Get the mode of the current selection.
sub GetSelectionMode {
  my $self = shift;
  return $self->SendMessage (2423, 0, 0);
}
# Retrieve the position of the start of the selection at the given line (INVALID_POSITION if no selection on this line).
sub GetLineSelStartPosition {
  my ($self, $line) = @_;
  return $self->SendMessage (2424, $line, 0);
}
# Retrieve the position of the end of the selection at the given line (INVALID_POSITION if no selection on this line).
sub GetLineSelEndPosition {
  my ($self, $line) = @_;
  return $self->SendMessage (2425, $line, 0);
}
# Move caret down one line, extending rectangular selection to new caret position.
sub LineDownRectExtend {
  my $self = shift;
  return $self->SendMessage (2426, 0, 0);
}
# Move caret up one line, extending rectangular selection to new caret position.
sub LineUpRectExtend {
  my $self = shift;
  return $self->SendMessage (2427, 0, 0);
}
# Move caret left one character, extending rectangular selection to new caret position.
sub CharLeftRectExtend {
  my $self = shift;
  return $self->SendMessage (2428, 0, 0);
}
# Move caret right one character, extending rectangular selection to new caret position.
sub CharRightRectExtend {
  my $self = shift;
  return $self->SendMessage (2429, 0, 0);
}
# Move caret to first position on line, extending rectangular selection to new caret position.
sub HomeRectExtend {
  my $self = shift;
  return $self->SendMessage (2430, 0, 0);
}
# Move caret to before first visible character on line.
# If already there move to first character on line.
# In either case, extend rectangular selection to new caret position.
sub VCHomeRectExtend {
  my $self = shift;
  return $self->SendMessage (2431, 0, 0);
}
# Move caret to last position on line, extending rectangular selection to new caret position.
sub LineEndRectExtend {
  my $self = shift;
  return $self->SendMessage (2432, 0, 0);
}
# Move caret one page up, extending rectangular selection to new caret position.
sub PageUpRectExtend {
  my $self = shift;
  return $self->SendMessage (2433, 0, 0);
}
# Move caret one page down, extending rectangular selection to new caret position.
sub PageDownRectExtend {
  my $self = shift;
  return $self->SendMessage (2434, 0, 0);
}
# Move caret to top of page, or one page up if already at top of page.
sub StutteredPageUp {
  my $self = shift;
  return $self->SendMessage (2435, 0, 0);
}
# Move caret to top of page, or one page up if already at top of page, extending selection to new caret position.
sub StutteredPageUpExtend {
  my $self = shift;
  return $self->SendMessage (2436, 0, 0);
}
# Move caret to bottom of page, or one page down if already at bottom of page.
sub StutteredPageDown {
  my $self = shift;
  return $self->SendMessage (2437, 0, 0);
}
# Move caret to bottom of page, or one page down if already at bottom of page, extending selection to new caret position.
sub StutteredPageDownExtend {
  my $self = shift;
  return $self->SendMessage (2438, 0, 0);
}
# Move caret left one word, position cursor at end of word.
sub WordLeftEnd {
  my $self = shift;
  return $self->SendMessage (2439, 0, 0);
}
# Move caret left one word, position cursor at end of word, extending selection to new caret position.
sub WordLeftEndExtend {
  my $self = shift;
  return $self->SendMessage (2440, 0, 0);
}
# Move caret right one word, position cursor at end of word.
sub WordRightEnd {
  my $self = shift;
  return $self->SendMessage (2441, 0, 0);
}
# Move caret right one word, position cursor at end of word, extending selection to new caret position.
sub WordRightEndExtend {
  my $self = shift;
  return $self->SendMessage (2442, 0, 0);
}
# Set the set of characters making up whitespace for when moving or selecting by word.
# Should be called after SetWordChars.
sub SetWhitespaceChars {
  my ($self, $characters) = @_;
  return $self->SendMessageNP (2443, 0, $characters);
}
# Reset the set of characters for whitespace and word characters to the defaults.
sub SetCharsDefault {
  my $self = shift;
  return $self->SendMessage (2444, 0, 0);
}
# Get currently selected item position in the auto-completion list
sub AutoCGetCurrent {
  my $self = shift;
  return $self->SendMessage (2445, 0, 0);
}
# Enlarge the document to a particular size of text bytes.
sub Allocate {
  my ($self, $bytes) = @_;
  return $self->SendMessage (2446, $bytes, 0);
}
# Start notifying the container of all key presses and commands.
sub StartRecord {
  my $self = shift;
  return $self->SendMessage (3001, 0, 0);
}
# Stop notifying the container of all key presses and commands.
sub StopRecord {
  my $self = shift;
  return $self->SendMessage (3002, 0, 0);
}
# Set the lexing language of the document.
sub SetLexer {
  my ($self, $lexer) = @_;
  return $self->SendMessage (4001, $lexer, 0);
}
# Retrieve the lexing language of the document.
sub GetLexer {
  my $self = shift;
  return $self->SendMessage (4002, 0, 0);
}
# Colourise a segment of the document using the current lexing language.
sub Colourise {
  my ($self, $start, $end) = @_;
  return $self->SendMessage (4003, $start, $end);
}
# Set up a value that may be used by a lexer for some optional feature.
sub SetProperty {
  my ($self, $key, $value) = @_;
  return $self->SendMessagePP (4004, $key, $value);
}
# Maximum value of keywordSet parameter of SetKeyWords.
use constant KEYWORDSET_MAX => 8 ;
# Set up the key words used by the lexer.
sub SetKeyWords {
  my ($self, $keywordSet, $keyWords) = @_;
  return $self->SendMessageNP (4005, $keywordSet, $keyWords);
}
# Set the lexing language of the document based on string name.
sub SetLexerLanguage {
  my ($self, $language) = @_;
  return $self->SendMessageNP (4006, 0, $language);
}
# Load a lexer library (dll / so).
sub LoadLexerLibrary {
  my ($self, $path) = @_;
  return $self->SendMessageNP (4007, 0, $path);
}
# Notifications
# Type of modification and the action which caused the modification.
# These are defined as a bit mask to make it easy to specify which notifications are wanted.
# One bit is set from each of SC_MOD_* and SC_PERFORMED_*.
use constant SC_MOD_INSERTTEXT => 0x1 ;
use constant SC_MOD_DELETETEXT => 0x2 ;
use constant SC_MOD_CHANGESTYLE => 0x4 ;
use constant SC_MOD_CHANGEFOLD => 0x8 ;
use constant SC_PERFORMED_USER => 0x10 ;
use constant SC_PERFORMED_UNDO => 0x20 ;
use constant SC_PERFORMED_REDO => 0x40 ;
use constant SC_LASTSTEPINUNDOREDO => 0x100 ;
use constant SC_MOD_CHANGEMARKER => 0x200 ;
use constant SC_MOD_BEFOREINSERT => 0x400 ;
use constant SC_MOD_BEFOREDELETE => 0x800 ;
use constant SC_MODEVENTMASKALL => 0xF77 ;
# For compatibility, these go through the COMMAND notification rather than NOTIFY
# and should have had exactly the same values as the EN_* constants.
# Unfortunately the SETFOCUS and KILLFOCUS are flipped over from EN_*
# As clients depend on these constants, this will not be changed.
use constant SCEN_CHANGE => 768 ;
use constant SCEN_SETFOCUS => 512 ;
use constant SCEN_KILLFOCUS => 256 ;
# Symbolic key codes and modifier flags.
# ASCII and other printable characters below 256.
# Extended keys above 300.
use constant SCK_DOWN => 300 ;
use constant SCK_UP => 301 ;
use constant SCK_LEFT => 302 ;
use constant SCK_RIGHT => 303 ;
use constant SCK_HOME => 304 ;
use constant SCK_END => 305 ;
use constant SCK_PRIOR => 306 ;
use constant SCK_NEXT => 307 ;
use constant SCK_DELETE => 308 ;
use constant SCK_INSERT => 309 ;
use constant SCK_ESCAPE => 7 ;
use constant SCK_BACK => 8 ;
use constant SCK_TAB => 9 ;
use constant SCK_RETURN => 13 ;
use constant SCK_ADD => 310 ;
use constant SCK_SUBTRACT => 311 ;
use constant SCK_DIVIDE => 312 ;
use constant SCMOD_SHIFT => 1 ;
use constant SCMOD_CTRL => 2 ;
use constant SCMOD_ALT => 4 ;
# For SciLexer.h
use constant SCLEX_CONTAINER => 0 ;
use constant SCLEX_NULL => 1 ;
use constant SCLEX_PYTHON => 2 ;
use constant SCLEX_CPP => 3 ;
use constant SCLEX_HTML => 4 ;
use constant SCLEX_XML => 5 ;
use constant SCLEX_PERL => 6 ;
use constant SCLEX_SQL => 7 ;
use constant SCLEX_VB => 8 ;
use constant SCLEX_PROPERTIES => 9 ;
use constant SCLEX_ERRORLIST => 10 ;
use constant SCLEX_MAKEFILE => 11 ;
use constant SCLEX_BATCH => 12 ;
use constant SCLEX_XCODE => 13 ;
use constant SCLEX_LATEX => 14 ;
use constant SCLEX_LUA => 15 ;
use constant SCLEX_DIFF => 16 ;
use constant SCLEX_CONF => 17 ;
use constant SCLEX_PASCAL => 18 ;
use constant SCLEX_AVE => 19 ;
use constant SCLEX_ADA => 20 ;
use constant SCLEX_LISP => 21 ;
use constant SCLEX_RUBY => 22 ;
use constant SCLEX_EIFFEL => 23 ;
use constant SCLEX_EIFFELKW => 24 ;
use constant SCLEX_TCL => 25 ;
use constant SCLEX_NNCRONTAB => 26 ;
use constant SCLEX_BULLANT => 27 ;
use constant SCLEX_VBSCRIPT => 28 ;
use constant SCLEX_ASP => 29 ;
use constant SCLEX_PHP => 30 ;
use constant SCLEX_BAAN => 31 ;
use constant SCLEX_MATLAB => 32 ;
use constant SCLEX_SCRIPTOL => 33 ;
use constant SCLEX_ASM => 34 ;
use constant SCLEX_CPPNOCASE => 35 ;
use constant SCLEX_FORTRAN => 36 ;
use constant SCLEX_F77 => 37 ;
use constant SCLEX_CSS => 38 ;
use constant SCLEX_POV => 39 ;
use constant SCLEX_LOUT => 40 ;
use constant SCLEX_ESCRIPT => 41 ;
use constant SCLEX_PS => 42 ;
use constant SCLEX_NSIS => 43 ;
use constant SCLEX_MMIXAL => 44 ;
use constant SCLEX_CLW => 45 ;
use constant SCLEX_CLWNOCASE => 46 ;
use constant SCLEX_LOT => 47 ;
use constant SCLEX_YAML => 48 ;
use constant SCLEX_TEX => 49 ;
use constant SCLEX_METAPOST => 50 ;
use constant SCLEX_POWERBASIC => 51 ;
use constant SCLEX_FORTH => 52 ;
use constant SCLEX_ERLANG => 53 ;
use constant SCLEX_OCTAVE => 54 ;
use constant SCLEX_MSSQL => 55 ;
use constant SCLEX_VERILOG => 56 ;
# When a lexer specifies its language as SCLEX_AUTOMATIC it receives a
# value assigned in sequence from SCLEX_AUTOMATIC+1.
use constant SCLEX_AUTOMATIC => 1000 ;
# Lexical states for SCLEX_PYTHON
# Python=SCLEX_PYTHON SCE_P_
# Ruby=SCLEX_RUBY SCE_P_
use constant SCE_P_DEFAULT => 0 ;
use constant SCE_P_COMMENTLINE => 1 ;
use constant SCE_P_NUMBER => 2 ;
use constant SCE_P_STRING => 3 ;
use constant SCE_P_CHARACTER => 4 ;
use constant SCE_P_WORD => 5 ;
use constant SCE_P_TRIPLE => 6 ;
use constant SCE_P_TRIPLEDOUBLE => 7 ;
use constant SCE_P_CLASSNAME => 8 ;
use constant SCE_P_DEFNAME => 9 ;
use constant SCE_P_OPERATOR => 10 ;
use constant SCE_P_IDENTIFIER => 11 ;
use constant SCE_P_COMMENTBLOCK => 12 ;
use constant SCE_P_STRINGEOL => 13 ;
# Lexical states for SCLEX_CPP
# Cpp=SCLEX_CPP SCE_C_
# SQL=SCLEX_SQL SCE_C_
# Pascal=SCLEX_PASCAL SCE_C_
# TCL=SCLEX_TCL SCE_C_
# BullAnt=SCLEX_BULLANT SCE_C_
use constant SCE_C_DEFAULT => 0 ;
use constant SCE_C_COMMENT => 1 ;
use constant SCE_C_COMMENTLINE => 2 ;
use constant SCE_C_COMMENTDOC => 3 ;
use constant SCE_C_NUMBER => 4 ;
use constant SCE_C_WORD => 5 ;
use constant SCE_C_STRING => 6 ;
use constant SCE_C_CHARACTER => 7 ;
use constant SCE_C_UUID => 8 ;
use constant SCE_C_PREPROCESSOR => 9 ;
use constant SCE_C_OPERATOR => 10 ;
use constant SCE_C_IDENTIFIER => 11 ;
use constant SCE_C_STRINGEOL => 12 ;
use constant SCE_C_VERBATIM => 13 ;
use constant SCE_C_REGEX => 14 ;
use constant SCE_C_COMMENTLINEDOC => 15 ;
use constant SCE_C_WORD2 => 16 ;
use constant SCE_C_COMMENTDOCKEYWORD => 17 ;
use constant SCE_C_COMMENTDOCKEYWORDERROR => 18 ;
use constant SCE_C_GLOBALCLASS => 19 ;
# Lexical states for SCLEX_HTML, SCLEX_XML
# HTML=SCLEX_HTML SCE_H
# XML=SCLEX_XML SCE_H
# ASP=SCLEX_ASP SCE_H
# PHP=SCLEX_PHP SCE_H
use constant SCE_H_DEFAULT => 0 ;
use constant SCE_H_TAG => 1 ;
use constant SCE_H_TAGUNKNOWN => 2 ;
use constant SCE_H_ATTRIBUTE => 3 ;
use constant SCE_H_ATTRIBUTEUNKNOWN => 4 ;
use constant SCE_H_NUMBER => 5 ;
use constant SCE_H_DOUBLESTRING => 6 ;
use constant SCE_H_SINGLESTRING => 7 ;
use constant SCE_H_OTHER => 8 ;
use constant SCE_H_COMMENT => 9 ;
use constant SCE_H_ENTITY => 10 ;
# XML and ASP
use constant SCE_H_TAGEND => 11 ;
use constant SCE_H_XMLSTART => 12 ;
use constant SCE_H_XMLEND => 13 ;
use constant SCE_H_SCRIPT => 14 ;
use constant SCE_H_ASP => 15 ;
use constant SCE_H_ASPAT => 16 ;
use constant SCE_H_CDATA => 17 ;
use constant SCE_H_QUESTION => 18 ;
# More HTML
use constant SCE_H_VALUE => 19 ;
# X-Code
use constant SCE_H_XCCOMMENT => 20 ;
# SGML
use constant SCE_H_SGML_DEFAULT => 21 ;
use constant SCE_H_SGML_COMMAND => 22 ;
use constant SCE_H_SGML_1ST_PARAM => 23 ;
use constant SCE_H_SGML_DOUBLESTRING => 24 ;
use constant SCE_H_SGML_SIMPLESTRING => 25 ;
use constant SCE_H_SGML_ERROR => 26 ;
use constant SCE_H_SGML_SPECIAL => 27 ;
use constant SCE_H_SGML_ENTITY => 28 ;
use constant SCE_H_SGML_COMMENT => 29 ;
use constant SCE_H_SGML_1ST_PARAM_COMMENT => 30 ;
use constant SCE_H_SGML_BLOCK_DEFAULT => 31 ;
# Embedded Javascript
use constant SCE_HJ_START => 40 ;
use constant SCE_HJ_DEFAULT => 41 ;
use constant SCE_HJ_COMMENT => 42 ;
use constant SCE_HJ_COMMENTLINE => 43 ;
use constant SCE_HJ_COMMENTDOC => 44 ;
use constant SCE_HJ_NUMBER => 45 ;
use constant SCE_HJ_WORD => 46 ;
use constant SCE_HJ_KEYWORD => 47 ;
use constant SCE_HJ_DOUBLESTRING => 48 ;
use constant SCE_HJ_SINGLESTRING => 49 ;
use constant SCE_HJ_SYMBOLS => 50 ;
use constant SCE_HJ_STRINGEOL => 51 ;
use constant SCE_HJ_REGEX => 52 ;
# ASP Javascript
use constant SCE_HJA_START => 55 ;
use constant SCE_HJA_DEFAULT => 56 ;
use constant SCE_HJA_COMMENT => 57 ;
use constant SCE_HJA_COMMENTLINE => 58 ;
use constant SCE_HJA_COMMENTDOC => 59 ;
use constant SCE_HJA_NUMBER => 60 ;
use constant SCE_HJA_WORD => 61 ;
use constant SCE_HJA_KEYWORD => 62 ;
use constant SCE_HJA_DOUBLESTRING => 63 ;
use constant SCE_HJA_SINGLESTRING => 64 ;
use constant SCE_HJA_SYMBOLS => 65 ;
use constant SCE_HJA_STRINGEOL => 66 ;
use constant SCE_HJA_REGEX => 67 ;
# Embedded VBScript
use constant SCE_HB_START => 70 ;
use constant SCE_HB_DEFAULT => 71 ;
use constant SCE_HB_COMMENTLINE => 72 ;
use constant SCE_HB_NUMBER => 73 ;
use constant SCE_HB_WORD => 74 ;
use constant SCE_HB_STRING => 75 ;
use constant SCE_HB_IDENTIFIER => 76 ;
use constant SCE_HB_STRINGEOL => 77 ;
# ASP VBScript
use constant SCE_HBA_START => 80 ;
use constant SCE_HBA_DEFAULT => 81 ;
use constant SCE_HBA_COMMENTLINE => 82 ;
use constant SCE_HBA_NUMBER => 83 ;
use constant SCE_HBA_WORD => 84 ;
use constant SCE_HBA_STRING => 85 ;
use constant SCE_HBA_IDENTIFIER => 86 ;
use constant SCE_HBA_STRINGEOL => 87 ;
# Embedded Python
use constant SCE_HP_START => 90 ;
use constant SCE_HP_DEFAULT => 91 ;
use constant SCE_HP_COMMENTLINE => 92 ;
use constant SCE_HP_NUMBER => 93 ;
use constant SCE_HP_STRING => 94 ;
use constant SCE_HP_CHARACTER => 95 ;
use constant SCE_HP_WORD => 96 ;
use constant SCE_HP_TRIPLE => 97 ;
use constant SCE_HP_TRIPLEDOUBLE => 98 ;
use constant SCE_HP_CLASSNAME => 99 ;
use constant SCE_HP_DEFNAME => 100 ;
use constant SCE_HP_OPERATOR => 101 ;
use constant SCE_HP_IDENTIFIER => 102 ;
# ASP Python
use constant SCE_HPA_START => 105 ;
use constant SCE_HPA_DEFAULT => 106 ;
use constant SCE_HPA_COMMENTLINE => 107 ;
use constant SCE_HPA_NUMBER => 108 ;
use constant SCE_HPA_STRING => 109 ;
use constant SCE_HPA_CHARACTER => 110 ;
use constant SCE_HPA_WORD => 111 ;
use constant SCE_HPA_TRIPLE => 112 ;
use constant SCE_HPA_TRIPLEDOUBLE => 113 ;
use constant SCE_HPA_CLASSNAME => 114 ;
use constant SCE_HPA_DEFNAME => 115 ;
use constant SCE_HPA_OPERATOR => 116 ;
use constant SCE_HPA_IDENTIFIER => 117 ;
# PHP
use constant SCE_HPHP_DEFAULT => 118 ;
use constant SCE_HPHP_HSTRING => 119 ;
use constant SCE_HPHP_SIMPLESTRING => 120 ;
use constant SCE_HPHP_WORD => 121 ;
use constant SCE_HPHP_NUMBER => 122 ;
use constant SCE_HPHP_VARIABLE => 123 ;
use constant SCE_HPHP_COMMENT => 124 ;
use constant SCE_HPHP_COMMENTLINE => 125 ;
use constant SCE_HPHP_HSTRING_VARIABLE => 126 ;
use constant SCE_HPHP_OPERATOR => 127 ;
# Lexical states for SCLEX_PERL
# Perl=SCLEX_PERL SCE_PL_
use constant SCE_PL_DEFAULT => 0 ;
use constant SCE_PL_ERROR => 1 ;
use constant SCE_PL_COMMENTLINE => 2 ;
use constant SCE_PL_POD => 3 ;
use constant SCE_PL_NUMBER => 4 ;
use constant SCE_PL_WORD => 5 ;
use constant SCE_PL_STRING => 6 ;
use constant SCE_PL_CHARACTER => 7 ;
use constant SCE_PL_PUNCTUATION => 8 ;
use constant SCE_PL_PREPROCESSOR => 9 ;
use constant SCE_PL_OPERATOR => 10 ;
use constant SCE_PL_IDENTIFIER => 11 ;
use constant SCE_PL_SCALAR => 12 ;
use constant SCE_PL_ARRAY => 13 ;
use constant SCE_PL_HASH => 14 ;
use constant SCE_PL_SYMBOLTABLE => 15 ;
use constant SCE_PL_REGEX => 17 ;
use constant SCE_PL_REGSUBST => 18 ;
use constant SCE_PL_LONGQUOTE => 19 ;
use constant SCE_PL_BACKTICKS => 20 ;
use constant SCE_PL_DATASECTION => 21 ;
use constant SCE_PL_HERE_DELIM => 22 ;
use constant SCE_PL_HERE_Q => 23 ;
use constant SCE_PL_HERE_QQ => 24 ;
use constant SCE_PL_HERE_QX => 25 ;
use constant SCE_PL_STRING_Q => 26 ;
use constant SCE_PL_STRING_QQ => 27 ;
use constant SCE_PL_STRING_QX => 28 ;
use constant SCE_PL_STRING_QR => 29 ;
use constant SCE_PL_STRING_QW => 30 ;
# Lexical states for SCLEX_VB, SCLEX_VBSCRIPT, SCLEX_POWERBASIC
# VB=SCLEX_VB SCE_B_
# VBScript=SCLEX_VBSCRIPT SCE_B_
# PowerBasic=SCLEX_POWERBASIC SCE_B_
use constant SCE_B_DEFAULT => 0 ;
use constant SCE_B_COMMENT => 1 ;
use constant SCE_B_NUMBER => 2 ;
use constant SCE_B_KEYWORD => 3 ;
use constant SCE_B_STRING => 4 ;
use constant SCE_B_PREPROCESSOR => 5 ;
use constant SCE_B_OPERATOR => 6 ;
use constant SCE_B_IDENTIFIER => 7 ;
use constant SCE_B_DATE => 8 ;
use constant SCE_B_STRINGEOL => 9 ;
use constant SCE_B_KEYWORD2 => 10 ;
use constant SCE_B_KEYWORD3 => 11 ;
use constant SCE_B_KEYWORD4 => 12 ;
use constant SCE_B_CONSTANT => 13 ;
use constant SCE_B_ASM => 14 ;
# Lexical states for SCLEX_PROPERTIES
# Properties=SCLEX_PROPERTIES SCE_PROPS_
use constant SCE_PROPS_DEFAULT => 0 ;
use constant SCE_PROPS_COMMENT => 1 ;
use constant SCE_PROPS_SECTION => 2 ;
use constant SCE_PROPS_ASSIGNMENT => 3 ;
use constant SCE_PROPS_DEFVAL => 4 ;
# Lexical states for SCLEX_LATEX
# LaTeX=SCLEX_LATEX SCE_L_
use constant SCE_L_DEFAULT => 0 ;
use constant SCE_L_COMMAND => 1 ;
use constant SCE_L_TAG => 2 ;
use constant SCE_L_MATH => 3 ;
use constant SCE_L_COMMENT => 4 ;
# Lexical states for SCLEX_LUA
# Lua=SCLEX_LUA SCE_LUA_
use constant SCE_LUA_DEFAULT => 0 ;
use constant SCE_LUA_COMMENT => 1 ;
use constant SCE_LUA_COMMENTLINE => 2 ;
use constant SCE_LUA_COMMENTDOC => 3 ;
use constant SCE_LUA_NUMBER => 4 ;
use constant SCE_LUA_WORD => 5 ;
use constant SCE_LUA_STRING => 6 ;
use constant SCE_LUA_CHARACTER => 7 ;
use constant SCE_LUA_LITERALSTRING => 8 ;
use constant SCE_LUA_PREPROCESSOR => 9 ;
use constant SCE_LUA_OPERATOR => 10 ;
use constant SCE_LUA_IDENTIFIER => 11 ;
use constant SCE_LUA_STRINGEOL => 12 ;
use constant SCE_LUA_WORD2 => 13 ;
use constant SCE_LUA_WORD3 => 14 ;
use constant SCE_LUA_WORD4 => 15 ;
use constant SCE_LUA_WORD5 => 16 ;
use constant SCE_LUA_WORD6 => 17 ;
use constant SCE_LUA_WORD7 => 18 ;
use constant SCE_LUA_WORD8 => 19 ;
# Lexical states for SCLEX_ERRORLIST
# ErrorList=SCLEX_ERRORLIST SCE_ERR_
use constant SCE_ERR_DEFAULT => 0 ;
use constant SCE_ERR_PYTHON => 1 ;
use constant SCE_ERR_GCC => 2 ;
use constant SCE_ERR_MS => 3 ;
use constant SCE_ERR_CMD => 4 ;
use constant SCE_ERR_BORLAND => 5 ;
use constant SCE_ERR_PERL => 6 ;
use constant SCE_ERR_NET => 7 ;
use constant SCE_ERR_LUA => 8 ;
use constant SCE_ERR_CTAG => 9 ;
use constant SCE_ERR_DIFF_CHANGED => 10 ;
use constant SCE_ERR_DIFF_ADDITION => 11 ;
use constant SCE_ERR_DIFF_DELETION => 12 ;
use constant SCE_ERR_DIFF_MESSAGE => 13 ;
use constant SCE_ERR_PHP => 14 ;
use constant SCE_ERR_ELF => 15 ;
use constant SCE_ERR_IFC => 16 ;
use constant SCE_ERR_IFORT => 17 ;
use constant SCE_ERR_ABSF => 18 ;
# Lexical states for SCLEX_BATCH
# Batch=SCLEX_BATCH SCE_BAT_
use constant SCE_BAT_DEFAULT => 0 ;
use constant SCE_BAT_COMMENT => 1 ;
use constant SCE_BAT_WORD => 2 ;
use constant SCE_BAT_LABEL => 3 ;
use constant SCE_BAT_HIDE => 4 ;
use constant SCE_BAT_COMMAND => 5 ;
use constant SCE_BAT_IDENTIFIER => 6 ;
use constant SCE_BAT_OPERATOR => 7 ;
# Lexical states for SCLEX_MAKEFILE
# MakeFile=SCLEX_MAKEFILE SCE_MAKE_
use constant SCE_MAKE_DEFAULT => 0 ;
use constant SCE_MAKE_COMMENT => 1 ;
use constant SCE_MAKE_PREPROCESSOR => 2 ;
use constant SCE_MAKE_IDENTIFIER => 3 ;
use constant SCE_MAKE_OPERATOR => 4 ;
use constant SCE_MAKE_TARGET => 5 ;
use constant SCE_MAKE_IDEOL => 9 ;
# Lexical states for SCLEX_DIFF
# Diff=SCLEX_DIFF SCE_DIFF_
use constant SCE_DIFF_DEFAULT => 0 ;
use constant SCE_DIFF_COMMENT => 1 ;
use constant SCE_DIFF_COMMAND => 2 ;
use constant SCE_DIFF_HEADER => 3 ;
use constant SCE_DIFF_POSITION => 4 ;
use constant SCE_DIFF_DELETED => 5 ;
use constant SCE_DIFF_ADDED => 6 ;
# Lexical states for SCLEX_CONF (Apache Configuration Files Lexer)
# Conf=SCLEX_CONF SCE_CONF_
use constant SCE_CONF_DEFAULT => 0 ;
use constant SCE_CONF_COMMENT => 1 ;
use constant SCE_CONF_NUMBER => 2 ;
use constant SCE_CONF_IDENTIFIER => 3 ;
use constant SCE_CONF_EXTENSION => 4 ;
use constant SCE_CONF_PARAMETER => 5 ;
use constant SCE_CONF_STRING => 6 ;
use constant SCE_CONF_OPERATOR => 7 ;
use constant SCE_CONF_IP => 8 ;
use constant SCE_CONF_DIRECTIVE => 9 ;
# Lexical states for SCLEX_AVE, Avenue
# Avenue=SCLEX_AVE SCE_AVE_
use constant SCE_AVE_DEFAULT => 0 ;
use constant SCE_AVE_COMMENT => 1 ;
use constant SCE_AVE_NUMBER => 2 ;
use constant SCE_AVE_WORD => 3 ;
use constant SCE_AVE_STRING => 6 ;
use constant SCE_AVE_ENUM => 7 ;
use constant SCE_AVE_STRINGEOL => 8 ;
use constant SCE_AVE_IDENTIFIER => 9 ;
use constant SCE_AVE_OPERATOR => 10 ;
use constant SCE_AVE_WORD1 => 11 ;
use constant SCE_AVE_WORD2 => 12 ;
use constant SCE_AVE_WORD3 => 13 ;
use constant SCE_AVE_WORD4 => 14 ;
use constant SCE_AVE_WORD5 => 15 ;
use constant SCE_AVE_WORD6 => 16 ;
# Lexical states for SCLEX_ADA
# Ada=SCLEX_ADA SCE_ADA_
use constant SCE_ADA_DEFAULT => 0 ;
use constant SCE_ADA_WORD => 1 ;
use constant SCE_ADA_IDENTIFIER => 2 ;
use constant SCE_ADA_NUMBER => 3 ;
use constant SCE_ADA_DELIMITER => 4 ;
use constant SCE_ADA_CHARACTER => 5 ;
use constant SCE_ADA_CHARACTEREOL => 6 ;
use constant SCE_ADA_STRING => 7 ;
use constant SCE_ADA_STRINGEOL => 8 ;
use constant SCE_ADA_LABEL => 9 ;
use constant SCE_ADA_COMMENTLINE => 10 ;
use constant SCE_ADA_ILLEGAL => 11 ;
# Lexical states for SCLEX_BAAN
# Baan=SCLEX_BAAN SCE_BAAN_
use constant SCE_BAAN_DEFAULT => 0 ;
use constant SCE_BAAN_COMMENT => 1 ;
use constant SCE_BAAN_COMMENTDOC => 2 ;
use constant SCE_BAAN_NUMBER => 3 ;
use constant SCE_BAAN_WORD => 4 ;
use constant SCE_BAAN_STRING => 5 ;
use constant SCE_BAAN_PREPROCESSOR => 6 ;
use constant SCE_BAAN_OPERATOR => 7 ;
use constant SCE_BAAN_IDENTIFIER => 8 ;
use constant SCE_BAAN_STRINGEOL => 9 ;
use constant SCE_BAAN_WORD2 => 10 ;
# Lexical states for SCLEX_LISP
# Lisp=SCLEX_LISP SCE_LISP_
use constant SCE_LISP_DEFAULT => 0 ;
use constant SCE_LISP_COMMENT => 1 ;
use constant SCE_LISP_NUMBER => 2 ;
use constant SCE_LISP_KEYWORD => 3 ;
use constant SCE_LISP_STRING => 6 ;
use constant SCE_LISP_STRINGEOL => 8 ;
use constant SCE_LISP_IDENTIFIER => 9 ;
use constant SCE_LISP_OPERATOR => 10 ;
# Lexical states for SCLEX_EIFFEL and SCLEX_EIFFELKW
# Eiffel=SCLEX_EIFFEL SCE_EIFFEL_
# EiffelKW=SCLEX_EIFFELKW SCE_EIFFEL_
use constant SCE_EIFFEL_DEFAULT => 0 ;
use constant SCE_EIFFEL_COMMENTLINE => 1 ;
use constant SCE_EIFFEL_NUMBER => 2 ;
use constant SCE_EIFFEL_WORD => 3 ;
use constant SCE_EIFFEL_STRING => 4 ;
use constant SCE_EIFFEL_CHARACTER => 5 ;
use constant SCE_EIFFEL_OPERATOR => 6 ;
use constant SCE_EIFFEL_IDENTIFIER => 7 ;
use constant SCE_EIFFEL_STRINGEOL => 8 ;
# Lexical states for SCLEX_NNCRONTAB (nnCron crontab Lexer)
# NNCronTab=SCLEX_NNCRONTAB SCE_NNCRONTAB_
use constant SCE_NNCRONTAB_DEFAULT => 0 ;
use constant SCE_NNCRONTAB_COMMENT => 1 ;
use constant SCE_NNCRONTAB_TASK => 2 ;
use constant SCE_NNCRONTAB_SECTION => 3 ;
use constant SCE_NNCRONTAB_KEYWORD => 4 ;
use constant SCE_NNCRONTAB_MODIFIER => 5 ;
use constant SCE_NNCRONTAB_ASTERISK => 6 ;
use constant SCE_NNCRONTAB_NUMBER => 7 ;
use constant SCE_NNCRONTAB_STRING => 8 ;
use constant SCE_NNCRONTAB_ENVIRONMENT => 9 ;
use constant SCE_NNCRONTAB_IDENTIFIER => 10 ;
# Lexical states for SCLEX_FORTH (Forth Lexer)
# Forth=SCLEX_FORTH SCE_FORTH_
use constant SCE_FORTH_DEFAULT => 0 ;
use constant SCE_FORTH_COMMENT => 1 ;
use constant SCE_FORTH_COMMENT_ML => 2 ;
use constant SCE_FORTH_IDENTIFIER => 3 ;
use constant SCE_FORTH_CONTROL => 4 ;
use constant SCE_FORTH_KEYWORD => 5 ;
use constant SCE_FORTH_DEFWORD => 6 ;
use constant SCE_FORTH_PREWORD1 => 7 ;
use constant SCE_FORTH_PREWORD2 => 8 ;
use constant SCE_FORTH_NUMBER => 9 ;
use constant SCE_FORTH_STRING => 10 ;
use constant SCE_FORTH_LOCALE => 11 ;
# Lexical states for SCLEX_MATLAB
# MatLab=SCLEX_MATLAB SCE_MATLAB_
use constant SCE_MATLAB_DEFAULT => 0 ;
use constant SCE_MATLAB_COMMENT => 1 ;
use constant SCE_MATLAB_COMMAND => 2 ;
use constant SCE_MATLAB_NUMBER => 3 ;
use constant SCE_MATLAB_KEYWORD => 4 ;
# single quoted string
use constant SCE_MATLAB_STRING => 5 ;
use constant SCE_MATLAB_OPERATOR => 6 ;
use constant SCE_MATLAB_IDENTIFIER => 7 ;
use constant SCE_MATLAB_DOUBLEQUOTESTRING => 8 ;
# Lexical states for SCLEX_SCRIPTOL
# Sol=SCLEX_SCRIPTOL SCE_SCRIPTOL_
use constant SCE_SCRIPTOL_DEFAULT => 0 ;
use constant SCE_SCRIPTOL_WHITE => 1 ;
use constant SCE_SCRIPTOL_COMMENTLINE => 2 ;
use constant SCE_SCRIPTOL_PERSISTENT => 3 ;
use constant SCE_SCRIPTOL_CSTYLE => 4 ;
use constant SCE_SCRIPTOL_COMMENTBLOCK => 5 ;
use constant SCE_SCRIPTOL_NUMBER => 6 ;
use constant SCE_SCRIPTOL_STRING => 7 ;
use constant SCE_SCRIPTOL_CHARACTER => 8 ;
use constant SCE_SCRIPTOL_STRINGEOL => 9 ;
use constant SCE_SCRIPTOL_KEYWORD => 10 ;
use constant SCE_SCRIPTOL_OPERATOR => 11 ;
use constant SCE_SCRIPTOL_IDENTIFIER => 12 ;
use constant SCE_SCRIPTOL_TRIPLE => 13 ;
use constant SCE_SCRIPTOL_CLASSNAME => 14 ;
use constant SCE_SCRIPTOL_PREPROCESSOR => 15 ;
# Lexical states for SCLEX_ASM
# Asm=SCLEX_ASM SCE_ASM_
use constant SCE_ASM_DEFAULT => 0 ;
use constant SCE_ASM_COMMENT => 1 ;
use constant SCE_ASM_NUMBER => 2 ;
use constant SCE_ASM_STRING => 3 ;
use constant SCE_ASM_OPERATOR => 4 ;
use constant SCE_ASM_IDENTIFIER => 5 ;
use constant SCE_ASM_CPUINSTRUCTION => 6 ;
use constant SCE_ASM_MATHINSTRUCTION => 7 ;
use constant SCE_ASM_REGISTER => 8 ;
use constant SCE_ASM_DIRECTIVE => 9 ;
use constant SCE_ASM_DIRECTIVEOPERAND => 10 ;
use constant SCE_ASM_COMMENTBLOCK => 11 ;
use constant SCE_ASM_CHARACTER => 12 ;
use constant SCE_ASM_STRINGEOL => 13 ;
use constant SCE_ASM_EXTINSTRUCTION => 14 ;
# Lexical states for SCLEX_FORTRAN
# Fortran=SCLEX_FORTRAN SCE_F_
# F77=SCLEX_F77 SCE_F_
use constant SCE_F_DEFAULT => 0 ;
use constant SCE_F_COMMENT => 1 ;
use constant SCE_F_NUMBER => 2 ;
use constant SCE_F_STRING1 => 3 ;
use constant SCE_F_STRING2 => 4 ;
use constant SCE_F_STRINGEOL => 5 ;
use constant SCE_F_OPERATOR => 6 ;
use constant SCE_F_IDENTIFIER => 7 ;
use constant SCE_F_WORD => 8 ;
use constant SCE_F_WORD2 => 9 ;
use constant SCE_F_WORD3 => 10 ;
use constant SCE_F_PREPROCESSOR => 11 ;
use constant SCE_F_OPERATOR2 => 12 ;
use constant SCE_F_LABEL => 13 ;
use constant SCE_F_CONTINUATION => 14 ;
# Lexical states for SCLEX_CSS
# CSS=SCLEX_CSS SCE_CSS_
use constant SCE_CSS_DEFAULT => 0 ;
use constant SCE_CSS_TAG => 1 ;
use constant SCE_CSS_CLASS => 2 ;
use constant SCE_CSS_PSEUDOCLASS => 3 ;
use constant SCE_CSS_UNKNOWN_PSEUDOCLASS => 4 ;
use constant SCE_CSS_OPERATOR => 5 ;
use constant SCE_CSS_IDENTIFIER => 6 ;
use constant SCE_CSS_UNKNOWN_IDENTIFIER => 7 ;
use constant SCE_CSS_VALUE => 8 ;
use constant SCE_CSS_COMMENT => 9 ;
use constant SCE_CSS_ID => 10 ;
use constant SCE_CSS_IMPORTANT => 11 ;
use constant SCE_CSS_DIRECTIVE => 12 ;
use constant SCE_CSS_DOUBLESTRING => 13 ;
use constant SCE_CSS_SINGLESTRING => 14 ;
# Lexical states for SCLEX_POV
# POV=SCLEX_POV SCE_POV_
use constant SCE_POV_DEFAULT => 0 ;
use constant SCE_POV_COMMENT => 1 ;
use constant SCE_POV_COMMENTLINE => 2 ;
use constant SCE_POV_NUMBER => 3 ;
use constant SCE_POV_OPERATOR => 4 ;
use constant SCE_POV_IDENTIFIER => 5 ;
use constant SCE_POV_STRING => 6 ;
use constant SCE_POV_STRINGEOL => 7 ;
use constant SCE_POV_DIRECTIVE => 8 ;
use constant SCE_POV_BADDIRECTIVE => 9 ;
use constant SCE_POV_WORD2 => 10 ;
use constant SCE_POV_WORD3 => 11 ;
use constant SCE_POV_WORD4 => 12 ;
use constant SCE_POV_WORD5 => 13 ;
use constant SCE_POV_WORD6 => 14 ;
use constant SCE_POV_WORD7 => 15 ;
use constant SCE_POV_WORD8 => 16 ;
# Lexical states for SCLEX_LOUT
# LOUT=SCLEX_LOUT SCE_LOUT_
use constant SCE_LOUT_DEFAULT => 0 ;
use constant SCE_LOUT_COMMENT => 1 ;
use constant SCE_LOUT_NUMBER => 2 ;
use constant SCE_LOUT_WORD => 3 ;
use constant SCE_LOUT_WORD2 => 4 ;
use constant SCE_LOUT_WORD3 => 5 ;
use constant SCE_LOUT_WORD4 => 6 ;
use constant SCE_LOUT_STRING => 7 ;
use constant SCE_LOUT_OPERATOR => 8 ;
use constant SCE_LOUT_IDENTIFIER => 9 ;
use constant SCE_LOUT_STRINGEOL => 10 ;
# Lexical states for SCLEX_ESCRIPT
# ESCRIPT=SCLEX_ESCRIPT SCE_ESCRIPT_
use constant SCE_ESCRIPT_DEFAULT => 0 ;
use constant SCE_ESCRIPT_COMMENT => 1 ;
use constant SCE_ESCRIPT_COMMENTLINE => 2 ;
use constant SCE_ESCRIPT_COMMENTDOC => 3 ;
use constant SCE_ESCRIPT_NUMBER => 4 ;
use constant SCE_ESCRIPT_WORD => 5 ;
use constant SCE_ESCRIPT_STRING => 6 ;
use constant SCE_ESCRIPT_OPERATOR => 7 ;
use constant SCE_ESCRIPT_IDENTIFIER => 8 ;
use constant SCE_ESCRIPT_BRACE => 9 ;
use constant SCE_ESCRIPT_WORD2 => 10 ;
use constant SCE_ESCRIPT_WORD3 => 11 ;
# Lexical states for SCLEX_PS
# PS=SCLEX_PS SCE_PS_
use constant SCE_PS_DEFAULT => 0 ;
use constant SCE_PS_COMMENT => 1 ;
use constant SCE_PS_DSC_COMMENT => 2 ;
use constant SCE_PS_DSC_VALUE => 3 ;
use constant SCE_PS_NUMBER => 4 ;
use constant SCE_PS_NAME => 5 ;
use constant SCE_PS_KEYWORD => 6 ;
use constant SCE_PS_LITERAL => 7 ;
use constant SCE_PS_IMMEVAL => 8 ;
use constant SCE_PS_PAREN_ARRAY => 9 ;
use constant SCE_PS_PAREN_DICT => 10 ;
use constant SCE_PS_PAREN_PROC => 11 ;
use constant SCE_PS_TEXT => 12 ;
use constant SCE_PS_HEXSTRING => 13 ;
use constant SCE_PS_BASE85STRING => 14 ;
use constant SCE_PS_BADSTRINGCHAR => 15 ;
# Lexical states for SCLEX_NSIS
# NSIS=SCLEX_NSIS SCE_NSIS_
use constant SCE_NSIS_DEFAULT => 0 ;
use constant SCE_NSIS_COMMENT => 1 ;
use constant SCE_NSIS_STRINGDQ => 2 ;
use constant SCE_NSIS_STRINGLQ => 3 ;
use constant SCE_NSIS_STRINGRQ => 4 ;
use constant SCE_NSIS_FUNCTION => 5 ;
use constant SCE_NSIS_VARIABLE => 6 ;
use constant SCE_NSIS_LABEL => 7 ;
use constant SCE_NSIS_USERDEFINED => 8 ;
use constant SCE_NSIS_SECTIONDEF => 9 ;
use constant SCE_NSIS_SUBSECTIONDEF => 10 ;
use constant SCE_NSIS_IFDEFINEDEF => 11 ;
use constant SCE_NSIS_MACRODEF => 12 ;
use constant SCE_NSIS_STRINGVAR => 13 ;
use constant SCE_NSIS_NUMBER => 14 ;
# Lexical states for SCLEX_MMIXAL
# MMIXAL=SCLEX_MMIXAL SCE_MMIXAL_
use constant SCE_MMIXAL_LEADWS => 0 ;
use constant SCE_MMIXAL_COMMENT => 1 ;
use constant SCE_MMIXAL_LABEL => 2 ;
use constant SCE_MMIXAL_OPCODE => 3 ;
use constant SCE_MMIXAL_OPCODE_PRE => 4 ;
use constant SCE_MMIXAL_OPCODE_VALID => 5 ;
use constant SCE_MMIXAL_OPCODE_UNKNOWN => 6 ;
use constant SCE_MMIXAL_OPCODE_POST => 7 ;
use constant SCE_MMIXAL_OPERANDS => 8 ;
use constant SCE_MMIXAL_NUMBER => 9 ;
use constant SCE_MMIXAL_REF => 10 ;
use constant SCE_MMIXAL_CHAR => 11 ;
use constant SCE_MMIXAL_STRING => 12 ;
use constant SCE_MMIXAL_REGISTER => 13 ;
use constant SCE_MMIXAL_HEX => 14 ;
use constant SCE_MMIXAL_OPERATOR => 15 ;
use constant SCE_MMIXAL_SYMBOL => 16 ;
use constant SCE_MMIXAL_INCLUDE => 17 ;
# Lexical states for SCLEX_CLW
# Clarion=SCLEX_CLW SCE_CLW_
use constant SCE_CLW_DEFAULT => 0 ;
use constant SCE_CLW_LABEL => 1 ;
use constant SCE_CLW_COMMENT => 2 ;
use constant SCE_CLW_STRING => 3 ;
use constant SCE_CLW_USER_IDENTIFIER => 4 ;
use constant SCE_CLW_INTEGER_CONSTANT => 5 ;
use constant SCE_CLW_REAL_CONSTANT => 6 ;
use constant SCE_CLW_PICTURE_STRING => 7 ;
use constant SCE_CLW_KEYWORD => 8 ;
use constant SCE_CLW_COMPILER_DIRECTIVE => 9 ;
use constant SCE_CLW_BUILTIN_PROCEDURES_FUNCTION => 10 ;
use constant SCE_CLW_STRUCTURE_DATA_TYPE => 11 ;
use constant SCE_CLW_ATTRIBUTE => 12 ;
use constant SCE_CLW_STANDARD_EQUATE => 13 ;
use constant SCE_CLW_ERROR => 14 ;
# Lexical states for SCLEX_LOT
# LOT=SCLEX_LOT SCE_LOT_
use constant SCE_LOT_DEFAULT => 0 ;
use constant SCE_LOT_HEADER => 1 ;
use constant SCE_LOT_BREAK => 2 ;
use constant SCE_LOT_SET => 3 ;
use constant SCE_LOT_PASS => 4 ;
use constant SCE_LOT_FAIL => 5 ;
use constant SCE_LOT_ABORT => 6 ;
# Lexical states for SCLEX_YAML
# YAML=SCLEX_YAML SCE_YAML_
use constant SCE_YAML_DEFAULT => 0 ;
use constant SCE_YAML_COMMENT => 1 ;
use constant SCE_YAML_IDENTIFIER => 2 ;
use constant SCE_YAML_KEYWORD => 3 ;
use constant SCE_YAML_NUMBER => 4 ;
use constant SCE_YAML_REFERENCE => 5 ;
use constant SCE_YAML_DOCUMENT => 6 ;
use constant SCE_YAML_TEXT => 7 ;
use constant SCE_YAML_ERROR => 8 ;
# Lexical states for SCLEX_TEX
# TeX=SCLEX_TEX SCE_TEX_
use constant SCE_TEX_DEFAULT => 0 ;
use constant SCE_TEX_SPECIAL => 1 ;
use constant SCE_TEX_GROUP => 2 ;
use constant SCE_TEX_SYMBOL => 3 ;
use constant SCE_TEX_COMMAND => 4 ;
use constant SCE_TEX_TEXT => 5 ;
# Metapost=SCLEX_METAPOST SCE_METAPOST_
use constant SCE_METAPOST_DEFAULT => 0 ;
use constant SCE_METAPOST_SPECIAL => 1 ;
use constant SCE_METAPOST_GROUP => 2 ;
use constant SCE_METAPOST_SYMBOL => 3 ;
use constant SCE_METAPOST_COMMAND => 4 ;
use constant SCE_METAPOST_TEXT => 5 ;
use constant SCE_METAPOST_EXTRA => 6 ;
# Lexical states for SCLEX_ERLANG
# Erlang=SCLEX_ERLANG SCE_ERLANG_
use constant SCE_ERLANG_DEFAULT => 0 ;
use constant SCE_ERLANG_COMMENT => 1 ;
use constant SCE_ERLANG_VARIABLE => 2 ;
use constant SCE_ERLANG_NUMBER => 3 ;
use constant SCE_ERLANG_KEYWORD => 4 ;
use constant SCE_ERLANG_STRING => 5 ;
use constant SCE_ERLANG_OPERATOR => 6 ;
use constant SCE_ERLANG_ATOM => 7 ;
use constant SCE_ERLANG_FUNCTION_NAME => 8 ;
use constant SCE_ERLANG_CHARACTER => 9 ;
use constant SCE_ERLANG_MACRO => 10 ;
use constant SCE_ERLANG_RECORD => 11 ;
use constant SCE_ERLANG_SEPARATOR => 12 ;
use constant SCE_ERLANG_NODE_NAME => 13 ;
use constant SCE_ERLANG_UNKNOWN => 31 ;
# Lexical states for SCLEX_OCTAVE are identical to MatLab
# Octave=SCLEX_OCTAVE SCE_MATLAB_
# Lexical states for SCLEX_MSSQL
# MSSQL=SCLEX_MSSQL SCE_MSSQL_
use constant SCE_MSSQL_DEFAULT => 0 ;
use constant SCE_MSSQL_COMMENT => 1 ;
use constant SCE_MSSQL_LINE_COMMENT => 2 ;
use constant SCE_MSSQL_NUMBER => 3 ;
use constant SCE_MSSQL_STRING => 4 ;
use constant SCE_MSSQL_OPERATOR => 5 ;
use constant SCE_MSSQL_IDENTIFIER => 6 ;
use constant SCE_MSSQL_VARIABLE => 7 ;
use constant SCE_MSSQL_COLUMN_NAME => 8 ;
use constant SCE_MSSQL_STATEMENT => 9 ;
use constant SCE_MSSQL_DATATYPE => 10 ;
use constant SCE_MSSQL_SYSTABLE => 11 ;
use constant SCE_MSSQL_GLOBAL_VARIABLE => 12 ;
use constant SCE_MSSQL_FUNCTION => 13 ;
# Lexical states for SCLEX_VERILOG
# Verilog=SCLEX_VERILOG SCE_V_
use constant SCE_V_DEFAULT => 0 ;
use constant SCE_V_COMMENT => 1 ;
use constant SCE_V_COMMENTLINE => 2 ;
use constant SCE_V_COMMENTLINEBANG => 3 ;
use constant SCE_V_NUMBER => 4 ;
use constant SCE_V_WORD => 5 ;
use constant SCE_V_STRING => 6 ;
use constant SCE_V_WORD2 => 7 ;
use constant SCE_V_WORD3 => 8 ;
use constant SCE_V_PREPROCESSOR => 9 ;
use constant SCE_V_OPERATOR => 10 ;
use constant SCE_V_IDENTIFIER => 11 ;
use constant SCE_V_STRINGEOL => 12 ;
use constant SCE_V_USER => 19 ;
# Events
# GTK+ Specific to work around focus and accelerator problems:
# CARET_POLICY changed in 1.47
sub SetCaretPolicy {
  my ($self, $caretPolicy, $caretSlop) = @_;
  return $self->SendMessage (2369, $caretPolicy, $caretSlop);
}
use constant CARET_CENTER => 0x02 ;
use constant CARET_XEVEN => 0x08 ;
use constant CARET_XJUMPS => 0x10 ;
# The old name for SCN_UPDATEUI
use constant SCN_CHECKBRACE => 2007 ;

#------------------------------------------------------------------------
# End Autogenerate
#------------------------------------------------------------------------

# Code Here because need constant

#------------------------------------------------------------------------
# BraceHighEvent Management
#------------------------------------------------------------------------

sub BraceHighEvent {

  my $self   = shift;
  my $braces = shift || "[]{}()";

  my $braceAtCaret = -1;
  my $braceOpposite = -1;
  my $caretPos = $self->GetCurrentPos();

  if ($caretPos > 0) {
    my $charBefore  = $self->GetCharAt($caretPos - 1);
    $braceAtCaret = $caretPos - 1 if (index ($braces, $charBefore) >= 0 );
  }

  if ($braceAtCaret < 0)
  {
    my $charAfter  = $self->GetCharAt($caretPos);
    my $styleAfter = $self->GetCharAt($caretPos);

    $braceAtCaret = $caretPos if (index ($braces, $charAfter) >= 0);
  }

  $braceOpposite = $self->BraceMatch($braceAtCaret) if ($braceAtCaret >= 0);

  if ($braceAtCaret != -1  and $braceOpposite == -1) {
    $self->BraceBadLight($braceAtCaret);
  }
  else {
    $self->BraceHighlight($braceAtCaret, $braceOpposite);
  }
}

#------------------------------------------------------------------------
# Folder Management
#------------------------------------------------------------------------

# Folder Event call
# If Shift and Control are pressed, open or close all folder
# Otherwise
#  if shift is pressed, Toggle 1 level of current folder
#  else if control is pressed, expand all subfolder of current folder
#  else Toggle current folder
sub FolderEvent {

  my $self  = shift;
  my (%evt) = @_;

  if ($evt{-shift} and $evt{-control}) {
    $self->FolderAll();
  }
  else {
    my $lineClicked = $self->LineFromPosition($evt{-position});

    if ($self->GetFoldLevel($lineClicked) & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
       if ($evt{-shift}) {
           $self->SetFoldExpanded($lineClicked, 1);
           $self->FolderExpand($lineClicked, 1, 1, 1);
       }
       elsif ($evt{-control}) {
           if ($self->GetFoldExpanded($lineClicked)) {
               $self->SetFoldExpanded($lineClicked, 0);
               $self->FolderExpand($lineClicked, 0, 1, 0);
           }
           else {
               $self->SetFoldExpanded($lineClicked, 1);
               $self->FolderExpand($lineClicked, 1, 1, 100);
           }
       }
       else {
          $self->ToggleFold($lineClicked);
       }
     }
  }
}

# Open All Folder
sub FolderAll {

  my $self = shift;
  my $lineCount = $self->GetLineCount();
  my $expanding = 1;
  my $lineNum;

  # find out if we are folding or unfolding
  for $lineNum (1..$lineCount) {
    if ($self->GetFoldLevel($lineNum) & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
      $expanding = not $self->GetFoldExpanded($lineNum);
      last;
    }
  }

  $lineNum = 0;
  while ($lineNum < $lineCount) {
    my $level = $self->GetFoldLevel($lineNum);
    if (($level & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) and
        ($level & Win32::GUI::Scintilla::SC_FOLDLEVELNUMBERMASK) == Win32::GUI::Scintilla::SC_FOLDLEVELBASE) {

      if ($expanding) {
        $self->SetFoldExpanded($lineNum, 1);
        $lineNum = $self->FolderExpand($lineNum, 1);
        $lineNum--;
      }
      else {
        my $lastChild = $self->GetLastChild($lineNum, -1);
        $self->SetFoldExpanded($lineNum, 0);
        $self->HideLines($lineNum+1, $lastChild) if ($lastChild > $lineNum);
      }
    }
    $lineNum++;
  }
}

# Expand folder
sub FolderExpand {
  my $self     = shift;
  my $line     = shift;
  my $doExpand = shift;
  my $force    = shift || 0;
  my $visLevels= shift || 0;
  my $level    = shift || -1;

  my $lastChild = $self->GetLastChild($line, $level);
  $line++;
  while ($line <= $lastChild) {
      if ($force) {
          if ($visLevels > 0) {
              $self->ShowLines($line, $line);
          }
          else {
              $self->HideLines($line, $line);
          }
      }
      else {
          $self->ShowLines($line, $line) if ($doExpand);
      }

      $level = $self->GetFoldLevel($line) if ($level == -1);

      if ($level & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
          if ($force) {
              if ($visLevels > 1) {
                  $self->SetFoldExpanded($line, 1);
              }
              else {
                  $self->SetFoldExpanded($line, 0);
              }
              $line = $self->FolderExpand($line, $doExpand, $force, $visLevels-1);
          }
          else {
              if ($doExpand and $self->GetFoldExpanded($line)) {
                  $line = $self->FolderExpand($line, 1, $force, $visLevels-1);
              }
              else {
                  $line = $self->FolderExpand($line, 0, $force, $visLevels-1);
              }
          }
      }
      else {
          $line ++;
      }
  }

  return $line;
}

#------------------------------------------------------------------------
# Find Management
#------------------------------------------------------------------------

sub FindAndSelect {

  my $self = shift;
  my $text = shift;
  my $flag = shift || Win32::GUI::Scintilla::SCFIND_WHOLEWORD;
  my $direction = shift || 1;
  my $wrap = shift || 1;

  my ($start, $end);

  # Set Search target
  if ($direction >= 0) {
    $start = $self->GetSelectionEnd ();
    $end   = $self->GetLength();
  }
  else {
    $start = $self->GetSelectionStart() - 1;
    $end   = 0;
  }

  $self->SetTargetStart ($start);
  $self->SetTargetEnd   ($end);
  $self->SetSearchFlags  ($flag);

  # Find text
  my $pos = $self->SearchInTarget($text);

  # Not found and Wrap mode
  if ($pos == -1 and $wrap == 1)
  {
    # New search target
    if ($direction >= 0) {
     $start = 0;
     $end = $self->GetLength();
    }
    else {
     $start = $self->GetLength();
     $end = 0;
    }

    $self->SetTargetStart ($start);
    $self->SetTargetEnd   ($end);

    # Find Text
    $pos = $self->SearchInTarget($text);
  }

  # Select and visible
  unless ($pos == -1)
  {
    # GetTarget
    $start = $self->GetTargetStart();
    $end   = $self->GetTargetEnd();

    # Ensure range visible
    my ($lstart, $lend);
    if ($start <= $end)
    {
      $lstart = $self->LineFromPosition($start);
      $lend   = $self->LineFromPosition($end);
    }
    else
    {
      $lstart = $self->LineFromPosition($end);
      $lend   = $self->LineFromPosition($start);
    }

    for my $i ($lstart .. $lend)
    {
      $self->EnsureVisible ($i);
    }

    # Select Target
    $self->SetSel ($start, $end);
  }
  else
  {
    $self->SetSelectionStart ($self->GetSelectionEnd());
  }

  return $pos;
}

1;
__END__

=head1 NAME

  Win32::GUI::Scintilla - Add Scintilla edit control to Win32::GUI

=head1 SYNOPSIS

  use Win32::GUI;
  use Win32::GUI::Scintilla;

  # main Window
  $Window = new Win32::GUI::Window (
      -name     => "Window",
      -title    => "Scintilla test",
      -pos      => [100, 100],
      -size     => [400, 400],
  ) or die "new Window";


  # Create Scintilla Edit Window
  # $Edit = new Win32::GUI::Scintilla  (
  #               -parent  => $Window,
  # Or
  $Edit = $Window->AddScintilla  (
                 -name    => "Edit",
                 -pos     => [0, 0],
                 -size    => [400, 400],
                 -text    => "Test\n",
  ) or die "new Edit";

  # Call Some method
  $Edit->AddText ("add\n");
  $Edit->AppendText ("append\n");

  # Event loop
  $Window->Show();
  Win32::GUI::Dialog();

  # Main window event handler
  sub Window_Terminate {
   # Call Some method
   print "GetText = ", $Edit->GetText(), "\n";
   print "GetSelText = ", $Edit->GetSelText(), "\n";
   print "GetTextRange(2) = ", $Edit->GetTextRange(2), "\n";
   print "GetTextRange(2, 6) = ", $Edit->GetTextRange(2, 6), "\n";
   return -1;
  }
  # Main window resize
  sub Window_Resize {

    if (defined $Window) {
      ($width, $height) = ($Window->GetClientRect)[2..3];
      $Edit->Move   (0, 0);
      $Edit->Resize ($width, $height);
    }
  }

  # Scintilla Event Notification
  sub Edit_Notify {

    my (%evt) = @_;
    print "Edit Notify = ", %evt, "\n";
  }

=head1 DESCRIPTION

  Scintilla is a free source code editing component.

  See : http:/www.scintilla.org/

=head2 Scintilla creation

=item C<new> (...)

  Create a new Scintilla control.

  Parameter :
    -name        : Window name
    -parent      : Parent window

    -left        : Left position
    -top         : Top  position
    -width       : Width
    -height      : Height

    -pos         : [x, y] position
    -size        : [w, h] size

    -text        : Text
    -visible     : Visible
    -readonly    : ReadOnly
    -hscroll     : Horizontal scroll
    -vscroll     : Vertical scroll

    -pushstyle   : Push style
    -addstyle    : Add style
    -popstyle    : Pop style
    -remstyle    : Remove style
    -notstyle    : Not style
    -negstyle    : Negation style
    -exstyle     : Extended style
    -pushexstyle : Push extended style
    -addexstyle  : Add extended style
    -popexstyle  : Pop extended style
    -remexstyle  : Remove extended style
    -notexstyle  : Not extended style
    -negexstyle  : Negation extended style

=item C<Win32::GUI::Window::AddScintilla> (...)

  Add a scintilla control in a Win32::GUI::Window.
  Parent window is automaticly add to new method.
  See Win32::GUI::Scintilla new method for parameters.

=head2 Scintilla Event

=item C<Notify> (%evt)

  -code : Event Code

    SCN_STYLENEEDED
      -position
    SCN_CHARADDED
      -ch                : Character
    SCN_KEY
      -ch                : Character
      -modifiers         : Key mask
      -shift             : Shift key
      -control           : Control key
      -alt               : Alt key
    SCN_MODIFIED
      -position          : Position
      -modificationType  :
      -length            : Length
      -linesAdded        : Line added
      -line              : Line
      -foldLevelNow      :
      -foldLevelPrev     :
    SCN_MACRORECORD
      -message           : Message
    SCN_MARGINCLICK
      -position
      -modifiers         : Key mask
      -shift             : Shift key
      -control           : Control key
      -alt               : Alt key
      -margin            : Margin number
    SCN_USERLISTSELECTION
      -listType          : List item
    SCN_DWELLSTART
      -position          : Position
      -x                 : X position
      -y                 : Y position
    SCN_DWELLEND
      -position          : Position
      -x                 : X position
      -y                 : Y position
    SCN_SAVEPOINTREACHED
    SCN_SAVEPOINTLEFT
    SCN_MODIFYATTEMPTRO
    SCN_DOUBLECLICK
    SCN_UPDATEUI
    SCN_ZOOM
    SCN_URIDROPPED
    SCN_NEEDSHOWN
    SCN_PAINTED
    SCN_HOTSPOTCLICK & SCN_HOTSPOTDOUBLECLICK
      -position          : Position
      -modifiers         : Key mask
      -shift             : Shift key
      -control           : Control key
      -alt               : Alt key
    SCN_CALLTIPCLICK
      -position          : Position

=item C<Change>

  Fire when Scintilla edit control text change.
  See also Notify SCN_MODIFIED event.

=item C<GotFocus>

  Fire when Scintilla edit control got focus.

=item C<LostFocus>

  Fire when Scintilla edit control lost focus.

=head2 Scintilla utility method

=item C<NewFile>

  Clean control for editing a new file.
  - Clear Text
  - Clear Undo buffer
  - Set save point

=item C<LoadFile> (filename)

  Load a text file.
  - Clear undo buffer
  - Set save point

  Return : bool

=item C<SaveFile> (filename)

  Save text in file.
  - Set save point

  Return : bool

=item C<StyleSetSpec> (style, stringstyle)

  Set a style from a string style.

  A string style is a comma separated property string.
  Each property, is compose a property name, an optional value separate by a ':'.


  Property :
    - fore:#RRGGBB  = Set foreground color (RRGGBB is a hexadecimal value)
    - back:#RRGGBB  = Set background color
    - face:name     = Set font
    - size:N        = Set font size (N is a numeric value)
    - bold          = Bold font
    - notbold       = Not Bold font
    - italic        = Italic font
    - notitalic     = Not Italic font
    - underline     = Underline font
    - notunderline  = Not Underline font
    - eolfilled     = eolfilled
    - noteolfilled  = Not eolfilled

  Sample : "face:Times New Roman,size:12,fore:#0000FF,back#FF0000,bold,italic"

=item C<BraceHighEvent> (bracematch = "[](){}")

  A standard brace highligthing event manager.

=item C<FolderEvent> (%evt)

  A standard event manager.

  If Shift and Control are pressed, open or close all folder
  Else
    If Shift is pressed, Toggle 1 level of current folder
    Else If Control is pressed, expand all subfolder of current folder
    Else Toggle current folder

=item C<FolderAll>

  Folding or Unfolding all text.

=item C<FolderExpand> (line, doExpand, force=0, visLevel=0, level=-1)

  Manage Folder Expanding

=item C<FindAndSelect> (text, flag = SCFIND_WHOLEWORD, direction=1, wrap=1)

  Find a text and select it.

  Parameter:
    - text : Text to find (or regular expression).
    - flag : A Scintilla Find constante.
      SCFIND_WHOLEWORD
      SCFIND_MATCHCASE
      SCFIND_WORDSTART
      SCFIND_REGEXP

    - direction : ForWard >= 0, Backward < 0
    - wrap : Use Wrap mode.

=head2 Scintilla standard method

  For full documentation off Scintilla control see http:\\www.scintilla.org\

=item C<AddText> (text)

  Add text to the document.

=item C<AddStyledText> (styledtext)

  Add array of cells to document.

=item C<InsertText> (position, text)

  Insert string at a position.

=item C<ClearAll>

  Delete all text in the document.

=item C<ClearDocumentStyle>

  Set all style bytes to 0, remove all folding information.

=item C<GetLength>

  Return the number of characters in the document.

=item C<GetCharAt> (position)

  Returns the character byte at the position.

=item C<GetCurrentPos>

  Returns the position of the caret.

=item C<GetAnchor>

  Returns the position of the opposite end of the selection to the caret.

=item C<GetStyleAt> (position)

  Returns the style byte at the position.

=item C<Redo>

  Redoes the next action on the undo history.

=item C<SetUndoCollection> (collectUndo)

  Choose between collecting actions into the undo history and discarding them.

=item C<SelectAll>

  Select all the text in the document.

=item C<SetSavePoint>

  Remember the current position in the undo history as the position at which the document was saved.

=item C<GetStyledText> (start=0, end=TextLength)

  Returns the number of bytes in the buffer not including terminating NULs.

=item C<CanRedo>

  Are there any redoable actions in the undo history?

=item C<MarkerLineFromHandle> (handle)

  Retrieve the line number at which a particular marker is located.

=item C<MarkerDeleteHandle> (handle)

  Delete a marker.

=item C<GetUndoCollection>

  Is undo history being collected?

=item C<WS Constant>

 SCWS_INVISIBLE, SCWS_VISIBLEALWAYS, SCWS_VISIBLEAFTERINDENT

=item C<GetViewWS>

  Are white space characters currently visible?

=item C<SetViewWS> (viewWS)

  Make white space characters invisible, always visible or visible outside indentation.

=item C<PositionFromPoint> (x, y)

  Find the position from a point within the window.

=item C<PositionFromPointClose> (x, y)

  Find the position from a point within the window but return INVALID_POSITION if not close to text.

=item C<GotoLine> (line)

  Set caret to start of a line and ensure it is visible.

=item C<GotoPos> (position)

  Set caret to a position and ensure it is visible.

=item C<SetAnchor> (position)

  Set the selection anchor to a position. The anchor is the opposite end of the selection from the caret.

=item C<GetCurLine>

  Return the text of the line containing the caret.

=item C<GetEndStyled>

  Retrieve the position of the last correctly styled character.

=item C<EOL constant>

  SC_EOL_CRLF, SC_EOL_CR, SC_EOL_LF.

=item C<ConvertEOLs> (eolMode)

  Convert all line endings in the document to one mode.

=item C<GetEOLMode>

  Retrieve the current end of line mode - one of CRLF, CR, or LF.

=item C<SetEOLMode> (eolMode)

  Set the current end of line mode.

=item C<StartStyling> (position, mask)

  Set the current styling position to pos and the styling mask to mask.
  The styling mask can be used to protect some bits in each styling byte from modification.

=item C<SetStyling> (length, style)

  Change style from current styling position for length characters to a style
  and move the current styling position to after this newly styled segment.

=item C<GetBufferedDraw>

  Is drawing done first into a buffer or direct to the screen?

=item C<SetBufferedDraw> (buffered)

  If drawing is buffered then each line of text is drawn into a bitmap buffer
  before drawing it to the screen to avoid flicker.

=item C<SetTabWidth> (tabWidth)

  Change the visible size of a tab to be a multiple of the width of a space character.

=item C<GetTabWidth>

  Retrieve the visible size of a tab.

=item C<Constant code page>

  SC_CP_UTF8, SC_CP_DBCS

=item C<SetCodePage> (codepage)

  Set the code page used to interpret the bytes of the document as characters.

=item C<SetUsePalette> (usePalette)

  In palette mode, Scintilla uses the environment's palette calls to display
  more colours. This may lead to ugly displays.

=item C<MARK constant>

  Shapes
    SC_MARK_CIRCLE
    SC_MARK_ROUNDRECT
    SC_MARK_ARROW
    SC_MARK_SMALLRECT
    SC_MARK_SHORTARROW
    SC_MARK_EMPTY
    SC_MARK_ARROWDOWN
    SC_MARK_MINUS
    SC_MARK_PLUS
  Shapes used for outlining column.
    SC_MARK_VLINE
    SC_MARK_LCORNER
    SC_MARK_TCORNER
    SC_MARK_BOXPLUS
    SC_MARK_BOXPLUSCONNECTED
    SC_MARK_BOXMINUS
    SC_MARK_BOXMINUSCONNECTED
    SC_MARK_LCORNERCURVE
    SC_MARK_TCORNERCURVE
    SC_MARK_CIRCLEPLUS
    SC_MARK_CIRCLEPLUSCONNECTED
    SC_MARK_CIRCLEMINUS
    SC_MARK_CIRCLEMINUSCONNECTED
  Invisible mark that only sets the line background color.
    SC_MARK_BACKGROUND
    SC_MARK_DOTDOTDOT
    SC_MARK_ARROWS
    SC_MARK_PIXMAP
    SC_MARK_CHARACTER
  Markers used for outlining column.
    SC_MARKNUM_FOLDEREND
    SC_MARKNUM_FOLDEROPENMID
    SC_MARKNUM_FOLDERMIDTAIL
    SC_MARKNUM_FOLDERTAIL
    SC_MARKNUM_FOLDERSUB
    SC_MARKNUM_FOLDER
    SC_MARKNUM_FOLDEROPEN
  Mask folder
    SC_MASK_FOLDERS

=item C<MarkerDefine> (markerNumber, markerSymbol)

  Set the symbol used for a particular marker number.

=item C<MarkerSetFore> (markerNumber, fore)

  Set the foreground colour used for a particular marker number.

=item C<MarkerSetBack> (markerNumber, back)

  Set the background colour used for a particular marker number.

=item C<MarkerAdd> (line, markerNumber)

  Add a marker to a line, returning an ID which can be used to find or delete the marker.

=item C<MarkerDelete> (line, markerNumber)

  Delete a marker from a line.

=item C<MarkerDeleteAll> (markerNumber)

  Delete all markers with a particular number from all lines.

=item C<MarkerGet> (line)

  Get a bit mask of all the markers set on a line.

=item C<MarkerNext> (lineStart, markerMask)

  Find the next line after lineStart that includes a marker in mask.

=item C<MarkerPrevious> (lineStart, markerMask)

  Find the previous line before lineStart that includes a marker in mask.

=item C<MarkerDefinePixmap> (markerNumber, pixmap)

  Define a marker from a pixmap.

=item C<MARGIN constant>

  SC_MARGIN_SYMBOL, SC_MARGIN_NUMBER

=item C<SetMarginTypeN> (margin, marginType)

  Set a margin to be either numeric or symbolic.

=item C<GetMarginTypeN> (margin)

  Retrieve the type of a margin.

=item C<SetMarginWidthN> (margin, pixelWidth)

  Set the width of a margin to a width expressed in pixels.

=item C<GetMarginWidthN> (margin)

  Retrieve the width of a margin in pixels.

=item C<SetMarginMaskN> (margin, mask)

  Set a mask that determines which markers are displayed in a margin.

=item C<GetMarginMaskN> (margin)

  Retrieve the marker mask of a margin.

=item C<SetMarginSensitiveN> (margin, sensitive)

  Make a margin sensitive or insensitive to mouse clicks.

=item C<GetMarginSensitiveN> (margin)

  Retrieve the mouse click sensitivity of a margin.

=item C<Style constant>

  Styles in range 32..37 are predefined for parts of the UI and are not used as normal styles.
  Styles 38 and 39 are for future use.
  STYLE_DEFAULT
  STYLE_LINENUMBER
  STYLE_BRACELIGHT
  STYLE_BRACEBAD
  STYLE_CONTROLCHAR
  STYLE_INDENTGUIDE
  STYLE_LASTPREDEFINED
  STYLE_MAX

=item C<StyleClearAll>

  Clear all the styles and make equivalent to the global default style.

=item C<StyleSetFore> (style, color)

  Set the foreground colour of a style.
  Color format : '#RRGGBB'

=item C<StyleSetBack> (style, color)

  Set the background colour of a style.
  Color format : '#RRGGBB'

=item C<StyleSetBold> (style, bool)

  Set a style to be bold or not.

=item C<StyleSetItalic> (style, bool)

  Set a style to be italic or not.

=item C<StyleSetSize> (style, size)

  Set the size of characters of a style.

=item C<StyleSetFont> (style, fontname)

  Set the font of a style.

=item C<StyleSetEOLFilled> (style, bool)

  Set a style to have its end of line filled or not.

=item C<StyleResetDefault>

  Reset the default style to its state at startup

=item C<StyleSetUnderline> (style, bool)

  Set a style to be underlined or not.

=item C<CASE constant>

  SC_CASE_MIXED
  SC_CASE_UPPER
  SC_CASE_LOWER

=item C<StyleSetCase> (style, case)

  Set a style to be mixed case, or to force upper or lower case.

=item C<CHARSET constant>

  SC_CHARSET_ANSI
  SC_CHARSET_DEFAULT
  SC_CHARSET_BALTIC
  SC_CHARSET_CHINESEBIG5
  SC_CHARSET_EASTEUROPE
  SC_CHARSET_GB2312
  SC_CHARSET_GREEK
  SC_CHARSET_HANGUL
  SC_CHARSET_MAC
  SC_CHARSET_OEM
  SC_CHARSET_RUSSIAN
  SC_CHARSET_SHIFTJIS
  SC_CHARSET_SYMBOL
  SC_CHARSET_TURKISH
  SC_CHARSET_JOHAB
  SC_CHARSET_HEBREW
  SC_CHARSET_ARABIC
  SC_CHARSET_VIETNAMESE
  SC_CHARSET_THAI

=item C<StyleSetCharacterSet> (style, characterSet)

  Set the character set of the font in a style.

=item C<StyleSetHotSpot> (style, hotspot)

  Set a style to be a hotspot or not.

=item C<SetSelFore> (useSetting, color)

  Set the foreground colour of the selection and whether to use this setting.

=item C<SetSelBack> (useSetting, color)

  Set the background colour of the selection and whether to use this setting.

=item C<SetCaretFore> (color)

  Set the foreground colour of the caret.

=item C<AssignCmdKey> (key, modifiers, msg)

  When key+modifier combination km is pressed perform msg.

=item C<ClearCmdKey> (key, modifiers)

  When key+modifier combination km is pressed do nothing.

=item C<ClearAllCmdKeys>

  Drop all key mappings.

=item C<SetStylingEx> (length, styles)

  Set the styles for a segment of the document.

=item C<StyleSetVisible> (style, bool)

  Set a style to be visible or not.

=item C<GetCaretPeriod>

  Get the time in milliseconds that the caret is on and off.

=item C<SetCaretPeriod> (period)

  Set the time in milliseconds that the caret is on and off. 0 = steady on.

=item C<SetWordChars> (characters)

  Set the set of characters making up words for when moving or selecting by word.
  First sets defaults like SetCharsDefault.

=item C<BeginUndoAction>

  Start a sequence of actions that is undone and redone as a unit.

=item C<EndUndoAction>

  End a sequence of actions that is undone and redone as a unit.

=item C<STYLE constant>

  INDIC_PLAIN
  INDIC_SQUIGGLE
  INDIC_TT
  INDIC_DIAGONAL
  INDIC_STRIKE
  INDIC_HIDDEN
  INDIC_BOX
  INDIC0_MASK
  INDIC1_MASK
  INDIC2_MASK
  INDICS_MASK

=item C<IndicSetStyle> (indic, style)

  Set an indicator to plain, squiggle or TT.

=item C<IndicGetStyle> (indic)

  Retrieve the style of an indicator.

=item C<IndicSetFore> (indic, color)

  Set the foreground colour of an indicator

=item C<IndicGetFore> (indic)

  Retrieve the foreground colour of an indicator.

=item C<SetWhitespaceFore> (useSetting, color)

  Set the foreground colour of all whitespace and whether to use this setting.

=item C<SetWhitespaceBack> (useSetting, color)

  Set the background colour of all whitespace and whether to use this setting.

=item C<SetStyleBits> (bits)

  Divide each styling byte into lexical class bits (default: 5) and indicator
  bits (default: 3). If a lexer requires more than 32 lexical states, then this
  is used to expand the possible states.

=item C<GetStyleBits>

  Retrieve number of bits in style bytes used to hold the lexical state.

=item C<SetLineState> (line, state)

  Used to hold extra styling information for each line.

=item C<GetLineState> (line)

  Retrieve the extra styling information for a line.

=item C<GetMaxLineState>

  Retrieve the last line number that has line state.

=item C<GetCaretLineVisible>

  Is the background of the line containing the caret in a different colour?

=item C<SetCaretLineVisible> (show)

  Display the background of the line containing the caret in a different colour.

=item C<GetCaretLineBack>

  Get the colour of the background of the line containing the caret.

=item C<SetCaretLineBack> (color)

  Set the colour of the background of the line containing the caret.

=item C<StyleSetChangeable> (style, bool)

  Set a style to be changeable or not (read only).

=item C<AutoCShow> (lenEntered, itemList))

  Display a auto-completion list.
  The lenEntered parameter indicates how many characters before
  the caret should be used to provide context.

=item C<AutoCCancel>

  Remove the auto-completion list from the screen.

=item C<AutoCActive>

  Is there an auto-completion list visible?

=item C<AutoCPosStart>

  Retrieve the position of the caret when the auto-completion list was displayed.

=item C<AutoCComplete>

  User has selected an item so remove the list and insert the selection.

=item C<AutoCStops> (characterSet)

  Define a set of character that when typed cancel the auto-completion list.

=item C<AutoCSetSeparator> (characterSet)

  Change the separator character in the string setting up an auto-completion list.
  Default is space but can be changed if items contain space.

=item C<AutoCGetSeparator>

  Retrieve the auto-completion list separator character.

=item C<AutoCSelect> (text)

  Select the item in the auto-completion list that starts with a string.

=item C<AutoCSetCancelAtStart> (cancel)

  Should the auto-completion list be cancelled if the user backspaces to a
  position before where the box was created.

=item C<AutoCGetCancelAtStart>

  Retrieve whether auto-completion cancelled by backspacing before start.

=item C<AutoCSetFillUps> (characterSet)

  Define a set of characters that when typed will cause the autocompletion to
  choose the selected item.

=item C<AutoCSetChooseSingle> (chooseSingle)

  Should a single item auto-completion list automatically choose the item.

=item C<AutoCGetChooseSingle>

  Retrieve whether a single item auto-completion list automatically choose the item.

=item C<AutoCSetIgnoreCase> (ignoreCase)

  Set whether case is significant when performing auto-completion searches.

=item C<AutoCGetIgnoreCase>

  Retrieve state of ignore case flag.

=item C<UserListShow> (listType, itemList)

  Display a list of strings and send notification when user chooses one.

=item C<AutoCSetAutoHide> (autoHide)

  Set whether or not autocompletion is hidden automatically when nothing matches.

=item C<AutoCGetAutoHide>

  Retrieve whether or not autocompletion is hidden automatically when nothing matches.

=item C<AutoCSetDropRestOfWord> (auutoHide)

  Retrieve whether or not autocompletion is hidden automatically when nothing matches.

=item C<AutoCGetDropRestOfWord>

  Retrieve whether or not autocompletion is hidden automatically when nothing matches.

=item C<RegisterImage> (type, xpmData)

  Register an XPM image for use in autocompletion lists.

=item C<ClearRegisteredImages>

  Clear all the registered XPM images.

=item C<AutoCGetTypeSeparator>

  Retrieve the auto-completion list type-separator character.

=item C<AutoCSetTypeSeparator>

  Change the type-separator character in the string setting up an auto-completion list.
  Default is '?' but can be changed if items contain '?'.

=item C<SetIndent> (indentSize)

  Set the number of spaces used for one level of indentation.

=item C<GetIndent>

  Retrieve indentation size.

=item C<SetUseTabs> (useTabs)

  Indentation will only use space characters if useTabs is false, otherwise
  it will use a combination of tabs and spaces.

=item C<GetUseTabs>

  Retrieve whether tabs will be used in indentation.

=item C<SetLineIndentation> (line, indentSize)

  Change the indentation of a line to a number of columns.

=item C<GetLineIndentation> (line)

  Retrieve the number of columns that a line is indented.

=item C<GetLineIndentPosition> (line)

  Retrieve the position before the first non indentation character on a line.

=item C<GetColumn> (pos)

  Retrieve the column number of a position, taking tab width into account.

=item C<SetHScrollBar> (show)

  Show or hide the horizontal scroll bar.

=item C<GetHScrollBar>

  Is the horizontal scroll bar visible?

=item C<SetIndentationGuides> (bool)

  Show or hide indentation guides.

=item C<GetIndentationGuides>

  Are the indentation guides visible?

=item C<SetHighlightGuide> (column)

  Set the highlighted indentation guide column.
  0 = no highlighted guide.

=item C<GetHighlightGuide>

  Get the highlighted indentation guide column.

=item C<GetLineEndPosition> (line)

  Get the position after the last visible characters on a line.

=item C<GetCodePage>

  Get the code page used to interpret the bytes of the document as characters.

=item C<GetCaretFore> (color)

  Get the foreground colour of the caret.

=item C<GetUsePalette>

  In palette mode?

=item C<GetReadOnly>

  In read-only mode?

=item C<SetCurrentPos> (position)

  Sets the position of the caret.

=item C<SetSelectionStart> (position)

  Sets the position that starts the selection - this becomes the anchor.

=item C<GetSelectionStart>

  Returns the position at the start of the selection.

=item C<SetSelectionEnd> (position)

  Sets the position that ends the selection - this becomes the currentPosition.

=item C<GetSelectionEnd>

  Returns the position at the start of the selection.

=item C<SetPrintMagnification> (magnification)

  Sets the print magnification added to the point size of each style for printing.

=item C<GetPrintMagnification>

  Returns the print magnification.

=item C<PRINT constant>

  PrintColourMode - use same colours as screen.
    SC_PRINT_NORMAL
  PrintColourMode - invert the light value of each style for printing.
    SC_PRINT_INVERTLIGHT
  PrintColourMode - force black text on white background for printing.
    SC_PRINT_BLACKONWHITE
  PrintColourMode - text stays coloured, but all background is forced to be white for printing.
    SC_PRINT_COLOURONWHITE
  PrintColourMode - only the default-background is forced to be white for printing.
  SC_PRINT_COLOURONWHITEDEFAULTBG

=item C<SetPrintColourMode> (mode)

  Modify colours when printing for clearer printed text.

=item C<GetPrintColourMode>

  Returns the print colour mode.

=item C<FIND constant>

  SCFIND_WHOLEWORD
  SCFIND_MATCHCASE
  SCFIND_WORDSTART
  SCFIND_REGEXP
  SCFIND_POSIX

=item C<FindText> (textToFind, start=0, end=GetLength(), flag = SCFIND_WHOLEWORD)

  Find some text in the document.

=item C<FormatRange> (start=0, end=GetLength(), draw=1)

  On Windows, will draw the document into a display context such as a printer.

=item C<GetFirstVisibleLine>

  Retrieve the display line at the top of the display.

=item C<GetLine> (line)

  Return text of line.

=item C<GetLineCount>

  Returns the number of lines in the document. There is always at least one.

=item C<SetMarginLeft> (pixelWidth)

  Sets the size in pixels of the left margin.

=item C<GetMarginLeft>

  Returns the size in pixels of the left margin.

=item C<SetMarginRight> (pixelWidth)

  Sets the size in pixels of the right margin.

=item C<GetMarginRight>

  Returns the size in pixels of the right margin.

=item C<GetModify>

  Is the document different from when it was last saved?

=item C<SetSel> (start, end)

  Select a range of text.

=item C<GetSelText>

  Retrieve the selected text.

=item C<GetTextRange> (start=0, end=Length)

  Retrieve a range of text.

=item C<HideSelection> (normal)

  Draw the selection in normal style or with selection highlighted.

=item C<PointXFromPosition> (position)

  Retrieve the x value of the point in the window where a position is displayed.

=item C<PointYFromPosition> (position)

  Retrieve the y value of the point in the window where a position is displayed.

=item C<LineFromPosition> (position)

  Retrieve the line containing a position.

=item C<PositionFromLine> (line)

  Retrieve the position at the start of a line.

=item C<LineScroll> (columns, lines)

  Scroll horizontally and vertically.

=item C<ScrollCaret>

  Ensure the caret is visible.

=item C<ReplaceSel> (text)

  Replace the selected text with the argument text.

=item C<SetReadOnly> (bool)

  Set to read only or read write.

=item C<Null>

  Null operation.

=item C<CanPaste>

  Will a paste succeed?

=item C<CanUndo>

  Are there any undoable actions in the undo history?

=item C<EmptyUndoBuffer>

  Delete the undo history.

=item C<Undo>

  Undo one action in the undo history.

=item C<Cut>

  Cut the selection to the clipboard.

=item C<Copy>

  Copy the selection to the clipboard.

=item C<Paste>

  Paste the contents of the clipboard into the document replacing the selection.

=item C<Clear>

  Clear the selection.

=item C<SetText> (text)

  Replace the contents of the document with the argument text.

=item C<GetText>

  Retrieve all the text in the document.

=item C<GetTextLength>

  Retrieve the number of characters in the document.

=item C<GetDirectFunction>

  Retrieve a pointer to a function that processes messages for this Scintilla.

=item C<GetDirectPointer>

  Retrieve a pointer to a function that processes messages for this Scintilla.

=item C<SetOvertype> (overtype)

  Set to overtype (true) or insert mode.

=item C<GetOvertype>

  Returns true if overtype mode is active otherwise false is returned.

=item C<SetCaretWidth> (pixelWidth)

  Set the width of the insert mode caret.

=item C<GetCaretWidth>

  Returns the width of the insert mode caret.

=item C<SetTargetStart> (position)

  Sets the position that starts the target which is used for updating the
  document without affecting the scroll position.

=item C<GetTargetStart>

  Get the position that starts the target.

=item C<SetTargetEnd> (position)

  Sets the position that ends the target which is used for updating the
  document without affecting the scroll position.

=item C<GetTargetEnd>

  Get the position that ends the target.

=item C<ReplaceTarget> (text)

  Replace the target text with the argument text.
  Text is counted so it can contain NULs.
  Returns the length of the replacement text.

=item C<ReplaceTargetRE> ($text)

  Replace the target text with the argument text after \d processing.
  Text is counted so it can contain NULs.
  Looks for \d where d is between 1 and 9 and replaces these with the strings
  matched in the last search operation which were surrounded by \( and \).
  Returns the length of the replacement text including any change
  caused by processing the \d patterns

=item C<SearchInTarget> (text)

  Search for a counted string in the target and set the target to the found
  range. Text is counted so it can contain NULs.
  Returns length of range or -1 for failure in which case target is not moved.

=item C<SetSearchFlags> (flags)

  Set the search flags used by SearchInTarget.

=item C<GetSearchFlags>

  Get the search flags used by SearchInTarget.

=item C<CallTipShow> (position, definition)

  Show a call tip containing a definition near position pos.

=item C<CallTipCancel>

  Remove the call tip from the screen.

=item C<CallTipActive>

  Is there an active call tip?

=item C<CallTipPosStart>

  Retrieve the position where the caret was before displaying the call tip.

=item C<CallTipSetHlt> (start, end)

  Highlight a segment of the definition.

=item C<CallTipSetBack> (color)

  Set the background colour for the call tip.

=item C<CallTipSetFore> (color)

  Set the foreground colour for the call tip.

=item C<CallTipSetForeHlt> (color)

  Set the foreground colour for the highlighted part of the call tip.

=item C<VisibleFromDocLine> (line)

  Find the display line of a document line taking hidden lines into account.

=item C<DocLineFromVisible> (lineDisplay)

  Find the document line of a display line taking hidden lines into account.

=item C<FOLDERLEVEL constant>

  SC_FOLDLEVELBASE
  SC_FOLDLEVELWHITEFLAG
  SC_FOLDLEVELHEADERFLAG
  SC_FOLDLEVELBOXHEADERFLAG
  SC_FOLDLEVELBOXFOOTERFLAG
  SC_FOLDLEVELCONTRACTED
  SC_FOLDLEVELUNINDENT
  SC_FOLDLEVELNUMBERMASK

=item C<SetFoldLevel> (line, level)

  Set the fold level of a line.
  This encodes an integer level along with flags indicating whether the
  line is a header and whether it is effectively white space.

=item C<GetFoldLevel> (line)

  Retrieve the fold level of a line.

=item C<GetLastChild> (line, level)

  Find the last child line of a header line.

=item C<GetFoldParent> (line)

  Find the parent line of a child line.

=item C<ShowLines> (lineStart, lineEnd)

  Make a range of lines visible.

=item C<HideLines> (lineStart, lineEnd)

  Make a range of lines invisible.

=item C<GetLineVisible> (line)

  Is a line visible?

=item C<SetFoldExpanded> (line, expanded)

  Show the children of a header line.

=item C<GetFoldExpanded> (line)

  Is a header line expanded ?

=item C<ToggleFold> (line)

  Switch a header line between expanded and contracted.

=item C<EnsureVisible> (line)

  Ensure a particular line is visible by expanding any header line hiding it.

=item C<FOLDFLAG constant>

  SC_FOLDFLAG_LINEBEFORE_EXPANDED
  SC_FOLDFLAG_LINEBEFORE_CONTRACTED
  SC_FOLDFLAG_LINEAFTER_EXPANDED
  SC_FOLDFLAG_LINEAFTER_CONTRACTED
  SC_FOLDFLAG_LEVELNUMBERS
  SC_FOLDFLAG_BOX

=item C<SetFoldFlags> (flags)

  Set some style options for folding.

=item C<EnsureVisibleEnforcePolicy> (line)

  Ensure a particular line is visible by expanding any header line hiding it.
  Use the currently set visibility policy to determine which range to display.

=item C<SetTabIndents> (tabIndents)

  Sets whether a tab pressed when caret is within indentation indents.

=item C<GetTabIndents>

  Does a tab pressed when caret is within indentation indent?

=item C<SetBackSpaceUnIndents> (bsUnIndents)

  Sets whether a backspace pressed when caret is within indentation unindents.

=item C<GetBackSpaceUnIndents>

  Does a backspace pressed when caret is within indentation unindent?

=item C<TIME constant>

  SC_TIME_FOREVER

=item C<SetMouseDwellTime> (period)

  Sets the time the mouse must sit still to generate a mouse dwell event.

=item C<GetMouseDwellTime>

  Retrieve the time the mouse must sit still to generate a mouse dwell event.

=item C<WordStartPosition> (pos, onlyWordCharacters)

  Get position of start of word.

=item C<WordEndPosition> (pos, onlyWordCharacters)

  Get position of end of word.

=item C<WRAP constant>

  SC_WRAP_NONE
  SC_WRAP_WORD

=item C<SetWrapMode> (mode)

  Sets whether text is word wrapped.

=item C<GetWrapMode>

  Retrieve whether text is word wrapped.

=item C<CACHE constant>

  SC_CACHE_NONE
  SC_CACHE_CARET
  SC_CACHE_PAGE
  SC_CACHE_DOCUMENT

=item C<SetLayoutCache> (mode)

  Sets the degree of caching of layout information.

=item C<GetLayoutCache>

  Retrieve the degree of caching of layout information.

=item C<SetScrollWidth> (pixelWidth)

  Sets the document width assumed for scrolling.

=item C<GetScrollWidth>

  Retrieve the document width assumed for scrolling.

=item C<TextWidth> (style, text)

  Measure the pixel width of some text in a particular style.
  NUL terminated text argument.
  Does not handle tab or control characters.

=item C<SetEndAtLastLine> (endAtLastLine)

  Sets the scroll range so that maximum scroll position has
  the last line at the bottom of the view (default).
  Setting this to false allows scrolling one page below the last line.

=item C<GetEndAtLastLine>

  Retrieve whether the maximum scroll position has the last
  line at the bottom of the view.

=item C<TextHeight> (line)

  Retrieve the height of a particular line of text in pixels.

=item C<SetVScrollBar> (bool)

  Show or hide the vertical scroll bar.

=item C<GetVScrollBar>

  Is the vertical scroll bar visible?

=item C<AppendText> (text)

  Append a string to the end of the document without changing the selection.

=item C<GetTwoPhaseDraw>

  Is drawing done in two phases with backgrounds drawn before faoregrounds?

=item C<SetTwoPhaseDraw>(bool twoPhase)

  In twoPhaseDraw mode, drawing is performed in two phases, first the background
  and then the foreground. This avoids chopping off characters that overlap the next run.

=item C<TargetFromSelection>

  Make the target range start and end be the same as the selection range start and end.

=item C<LinesJoin>

  Join the lines in the target.
  This is an experimental feature and may be changed or removed.

=item C<LinesSplit>(pixelWidth)

  Split the lines in the target into lines that are less wide than pixelWidth where possible.

=item C<SetFoldMarginColour>(bool useSetting, color back)

  Set the colours used as a chequerboard pattern in the fold margin

=item C<SetFoldMarginHiColour>(bool useSetting, color back)

  Set the colours used as a chequerboard pattern in the fold margin

=item C<LineDown>

  Move caret down one line.

=item C<LineDownExtend>

  Move caret down one line extending selection to new caret position.

=item C<LineUp>

  Move caret up one line.

=item C<LineUpExtend>

  Move caret up one line extending selection to new caret position.

=item C<CharLeft>

  Move caret left one character.

=item C<CharLeftExtend>

  Move caret left one character extending selection to new caret position.

=item C<CharRight>

  Move caret right one character.

=item C<CharRightExtend>

  Move caret right one character extending selection to new caret position.

=item C<WordLeft>

  Move caret left one word.

=item C<WordLeftExtend>

  Move caret left one word extending selection to new caret position.

=item C<WordRight>

  Move caret right one word.

=item C<WordRightExtend>

  Move caret right one word extending selection to new caret position.

=item C<Home>

  Move caret to first position on line.

=item C<HomeExtend>

  Move caret to first position on line extending selection to new caret position.

=item C<LineEnd>

  Move caret to last position on line.

=item C<LineEndExtend>

  Move caret to last position on line extending selection to new caret position.

=item C<DocumentStart>

  Move caret to first position in document.

=item C<DocumentStartExtend>

  Move caret to first position in document extending selection to new caret position.

=item C<DocumentEnd>

  Move caret to last position in document.

=item C<DocumentEndExtend>

  Move caret to last position in document extending selection to new caret position.

=item C<PageUp>

  Move caret one page up.

=item C<PageUpExtend>

  Move caret one page up extending selection to new caret position.

=item C<PageDown>

  Move caret one page down.

=item C<PageDownExtend>

  Move caret one page down extending selection to new caret position.

=item C<EditToggleOvertype>

  Switch from insert to overtype mode or the reverse.

=item C<Cancel>

  Cancel any modes such as call tip or auto-completion list display.

=item C<DeleteBack>

  Delete the selection or if no selection, the character before the caret.

=item C<Tab>

  If selection is empty or all on one line replace the selection with a tab character.
  If more than one line selected, indent the lines.

=item C<BackTab>

  Dedent the selected lines.

=item C<NewLine>

  Insert a new line, may use a CRLF, CR or LF depending on EOL mode.

=item C<FormFeed>

  Insert a Form Feed character.

=item C<VCHome>

  Move caret to before first visible character on line.
  If already there move to first character on line.

=item C<VCHomeExtend>

  Like VCHome but extending selection to new caret position.

=item C<ZoomIn>

  Magnify the displayed text by increasing the sizes by 1 point.

=item C<ZoomOut>

  Make the displayed text smaller by decreasing the sizes by 1 point.

=item C<DelWordLeft>

  Delete the word to the left of the caret.

=item C<DelWordRight>

  Delete the word to the right of the caret.

=item C<LineCut>

  Cut the line containing the caret.

=item C<LineDelete>

  Delete the line containing the caret.

=item C<LineTranspose>

  Switch the current line with the previous.

=item C<LineDuplicate>

  Duplicate the current line.

=item C<LowerCase>

  Transform the selection to lower case.

=item C<UpperCase>

  Transform the selection to upper case.

=item C<LineScrollDown>

  Scroll the document down, keeping the caret visible.

=item C<LineScrollUp>

  Scroll the document up, keeping the caret visible.

=item C<DeleteBackNotLine>

  Delete the selection or if no selection, the character before the caret.
  Will not delete the character before at the start of a line.

=item C<HomeDisplay>

  Move caret to first position on display line.

=item C<HomeDisplayExtend>

  Move caret to first position on display line extending selection to
  new caret position.

=item C<LineEndDisplay>

  Move caret to last position on display line.

=item C<LineEndDisplayExtend>

  Move caret to last position on display line extending selection to new
  caret position.

=item C<HomeWrap>

  These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)?
  except they behave differently when word-wrap is enabled:
  They go first to the start / end of the display line, like (Home|LineEnd)Display
  The difference is that, the cursor is already at the point, it goes on to the start
  or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.

=item C<HomeWrapExtend>

  See HomeWrap

=item C<LineEndWrap>

  See HomeWrap

=item C<LineEndWrapExtend>

  See HomeWrap

=item C<VCHomeWrap>

  See HomeWrap

=item C<VCHomeWrapExtend>

  See HomeWrap

=item C<LineCopy>

  Copy the line containing the caret.

=item C<MoveCaretInsideView>

  Move the caret inside current view if it's not there already.

=item C<LineLength> (line)

  How many characters are on a line, not including end of line characters?

=item C<BraceHighlight> (pos1, pos2)

  Highlight the characters at two positions.

=item C<BraceBadLight> (pos)

  Highlight the character at a position indicating there is no matching brace.

=item C<BraceMatch> (pos)

  Find the position of a matching brace or INVALID_POSITION if no match.

=item C<GetViewEOL>

  Are the end of line characters visible?

=item C<SetViewEOL> (visible)

  Make the end of line characters visible or invisible.

=item C<GetDocPointer>

  Retrieve a pointer to the document object.

=item C<SetDocPointer> (pointer)

  Change the document object used.

=item C<SetModEventMask> (mask)

  Set which document modification events are sent to the container.

=item C<EDGE constant>

  EDGE_NONE
  EDGE_LINE
  EDGE_BACKGROUND

=item C<GetEdgeColumn>

  Retrieve the column number which text should be kept within.

=item C<SetEdgeColumn> (column)

  Set the column number of the edge.
  If text goes past the edge then it is highlighted.

=item C<GetEdgeMode>

  Retrieve the edge highlight mode.

=item C<SetEdgeMode> (mode)

  The edge may be displayed by a line (EDGE_LINE) or by highlighting text that
  goes beyond it (EDGE_BACKGROUND) or not displayed at all (EDGE_NONE).

=item C<GetEdgeColour>

  Retrieve the colour used in edge indication.

=item C<SetEdgeColour> (color)

  Change the colour used in edge indication.

=item C<SearchAnchor>

  Sets the current caret position to be the search anchor.

=item C<SearchNext> (flags, text)

  Find some text starting at the search anchor.
  Does not ensure the selection is visible.

=item C<SearchPrev> (flags, text)

  Find some text starting at the search anchor and moving backwards.
  Does not ensure the selection is visible.

=item C<LinesOnScreen>

  Retrieves the number of lines completely visible.

=item C<UsePopUp> (allowPopUp)

  Set whether a pop up menu is displayed automatically when the user presses
  the wrong mouse button

=item C<SelectionIsRectangle>

  Is the selection rectangular? The alternative is the more common stream selection.

=item C<SetZoom> (zoom)

  Set the zoom level. This number of points is added to the size of all fonts.
  It may be positive to magnify or negative to reduce.

=item C<GetZoom>

  Retrieve the zoom level.

=item C<CreateDocument>

  Create a new document object.
  Starts with reference count of 1 and not selected into editor.

=item C<AddRefDocument> (doc)

  Extend life of document.

=item C<ReleaseDocument> (doc)

  Release a reference to the document, deleting document if it fades to black.

=item C<GetModEventMask>

  Get which document modification events are sent to the container.

=item C<SetFocus> (flag)

  Change internal focus flag.

=item C<GetFocus>

  Get internal focus flag.

=item C<SetStatus>

  Change error status - 0 = OK.

=item C<GetStatus>

  Get error status.

=item C<SetMouseDownCaptures> (capture)

  Set whether the mouse is captured when its button is pressed.

=item C<GetMouseDownCaptures>

  Get whether mouse gets captured.

=item C<CURSOR constant>

  SC_CURSORNORMAL
  SC_CURSORWAIT

=item C<SetCursor> (cursorType)

  Sets the cursor to one of the SC_CURSOR* values.

=item C<GetCursor>

  Get cursor type.

=item C<SetControlCharSymbol> (symbol)

  Change the way control characters are displayed:
  If symbol is < 32, keep the drawn way, else, use the given character.

=item C<GetControlCharSymbol>

  Get the way control characters are displayed.

=item C<WordPartLeft>

  Move to the previous change in capitalisation.

=item C<WordPartLeftExtend>

  Move to the previous change in capitalisation extending selection
  to new caret position.

=item C<WordPartRight>

  Move to the change next in capitalisation.

=item C<WordPartRightExtend>

  Move to the next change in capitalisation extending selection
  to new caret position.

=item C<VISIBLE constant>

  VISIBLE_SLOP
  VISIBLE_STRICT

=item C<SetVisiblePolicy> (visiblePolicy, visibleSlop)

  Set the way the display area is determined when a particular line
  is to be moved to by Find, FindNext, GotoLine, etc.

=item C<DelLineLeft>

  Delete back from the current position to the start of the line.

=item C<DelLineRight>

  Delete forwards from the current position to the end of the line.

=item C<SetXOffset>

  Set the xOffset (ie, horizonal scroll position).

=item C<GetXOffset>

  Get the xOffset (ie, horizonal scroll position).

=item C<ChooseCaretX>

  Set the last x chosen value to be the caret x position.

=item C<GrabFocus>

  Set the focus to this Scintilla widget.

=item C<CARET constant>

  CARET_SLOP
  If CARET_SLOP is set, we can define a slop value: caretSlop.
  This value defines an unwanted zone (UZ) where the caret is... unwanted.
  This zone is defined as a number of pixels near the vertical margins,
  and as a number of lines near the horizontal margins.
  By keeping the caret away from the edges, it is seen within its context,
  so it is likely that the identifier that the caret is on can be completely seen,
  and that the current line is seen with some of the lines following it which are
  often dependent on that line.

  CARET_STRICT
  If CARET_STRICT is set, the policy is enforced... strictly.
  The caret is centred on the display if slop is not set,
  and cannot go in the UZ if slop is set.

  CARET_JUMPS
  If CARET_JUMPS is set, the display is moved more energetically
  so the caret can move in the same direction longer before the policy is applied again.

  CARET_EVEN
  If CARET_EVEN is not set, instead of having symmetrical UZs,
  the left and bottom UZs are extended up to right and top UZs respectively.
  This way, we favour the displaying of useful information: the begining of lines,
  where most code reside, and the lines after the caret, eg. the body of a function.

=item C<SetXCaretPolicy> (caretPolicy, caretSlop)

  Set the way the caret is kept visible when going sideway.
  The exclusion zone is given in pixels.

=item C<SetYCaretPolicy> (caretPolicy, caretSlop)

  Set the way the line the caret is on is kept visible.
  The exclusion zone is given in lines.

=item C<SetPrintWrapMode> (mode)

  Set printing to line wrapped (SC_WRAP_WORD) or not line wrapped (SC_WRAP_NONE).

=item C<GetPrintWrapMode>

  Is printing line wrapped?

=item C<SetHotspotActiveFore> (useSetting, color)

  Set a fore colour for active hotspots.

=item C<SetHotspotActiveBack> (useSetting, color)

  Set a back colour for active hotspots.

=item C<SetHotspotActiveUnderline> (underline)

  Enable / Disable underlining active hotspots.

=item C<SetHotspotSingleLine> (singleLine)

  Limit hotspots to single line so hotspots on two lines don't merge.

=item C<ParaDown>

  Move caret between paragraphs (delimited by empty lines).

=item C<ParaDownExtend>

  Move caret between paragraphs (delimited by empty lines).

=item C<ParaUp>

  Move caret between paragraphs (delimited by empty lines).

=item C<ParaUpExtend>

  Move caret between paragraphs (delimited by empty lines).

=item C<PositionBefore> (pos)

  Given a valid document position, return the previous position taking code
  page into account. Returns 0 if passed 0.

=item C<PositionAfter>(pos)

  Given a valid document position, return the next position taking code
  page into account. Maximum value returned is the last position in the document.

=item C<CopyRange>(start, end)

  Copy a range of text to the clipboard. Positions are clipped into the document.

=item C<CopyText> (length, text)

  Copy argument text to the clipboard.

=item C<SetSelectionMode> (mode)

  Set the selection mode to stream (SC_SEL_STREAM) or rectangular (SC_SEL_RECTANGLE) or by lines (SC_SEL_LINES).

=item C<GetSelectionMode>

  Get the mode of the current selection.

=item C<GetLineSelStartPosition> (line)

  Retrieve the position of the start of the selection at the given line (INVALID_POSITION if no selection on this line).

=item C<GetLineSelEndPosition> (line)

  Retrieve the position of the end of the selection at the given line (INVALID_POSITION if no selection on this line).

=item C<LineDownRectExtend>

  Move caret down one line, extending rectangular selection to new caret position.

=item C<LineUpRectExtend>

  Move caret up one line, extending rectangular selection to new caret position.

=item C<CharLeftRectExtend>

  Move caret left one character, extending rectangular selection to new caret position.

=item C<CharRightRectExtend>

  Move caret right one character, extending rectangular selection to new caret position.

=item C<HomeRectExtend>

  Move caret to first position on line, extending rectangular selection to new caret position.

=item C<VCHomeRectExtend>

  Move caret to before first visible character on line.
  If already there move to first character on line.
  In either case, extend rectangular selection to new caret position.

=item C<LineEndRectExtend>

  Move caret to last position on line, extending rectangular selection to new caret position.

=item C<PageUpRectExtend>

  Move caret one page up, extending rectangular selection to new caret position.

=item C<PageDownRectExtend>

  Move caret one page down, extending rectangular selection to new caret position.

=item C<StutteredPageUp>

  Move caret to top of page, or one page up if already at top of page.

=item C<StutteredPageUpExtend>

  Move caret to top of page, or one page up if already at top of page, extending selection to new caret position.

=item C<StutteredPageDown>

  Move caret to bottom of page, or one page down if already at bottom of page.

=item C<StutteredPageDownExtend>

  Move caret to bottom of page, or one page down if already at bottom of page, extending selection to new caret position.

=item C<WordLeftEnd>

  Move caret left one word, position cursor at end of word.

=item C<WordLeftEndExtend>

  Move caret left one word, position cursor at end of word, extending selection to new caret position.

=item C<WordRightEnd>

  Move caret right one word, position cursor at end of word.

=item C<WordRightEndExtend>

  Move caret right one word, position cursor at end of word, extending selection to new caret position.

=item C<SetWhitespaceChars> (characters)

  Set the set of characters making up whitespace for when moving or selecting by word.
  Should be called after SetWordChars.

=item C<SetCharsDefault>

  Reset the set of characters for whitespace and word characters to the defaults.

=item C<AutoCGetCurrent>

  Get currently selected item position in the auto-completion list.

=item C<Allocate> (bytes)

  Enlarge the document to a particular size of text bytes.

=item C<StartRecord>

  Start notifying the container of all key presses and commands.

=item C<StopRecord>

  Stop notifying the container of all key presses and commands.

=item C<SetLexer> (lexer)

  Set the lexing language of the document.

=item C<GetLexer>

  Retrieve the lexing language of the document.

=item C<Colourise> (start, end)

  Colourise a segment of the document using the current lexing language.

=item C<SetProperty> (key, value)

  Set up a value that may be used by a lexer for some optional feature.

=item C<SetKeyWords> (keywordSet, keyWords)

  Set up the key words used by the lexer.

  Maximum value of keywordSet parameter of SetKeyWordsis defined by KEYWORDSET_MAX.

=item C<SetLexerLanguage> (language)

  Set the lexing language of the document based on string name.

=item C<LoadLexerLibrary> (path)

  Load a lexer library (dll / so).

=item C<Lexer constant>

  See Scintilla.pm

  SCLEX_* contante for lexer language.
  SCE_* for lexer constante.

  See comment for relation between Lexer language and lexer constante.

=head1 AUTHOR

  Laurent Rocher (lrocher@cpan.org)
  HomePage :http://perso.club-internet.fr/rocherl/Win32GUI.html

=head1 SEE ALSO

  Win32::GUI

=cut
