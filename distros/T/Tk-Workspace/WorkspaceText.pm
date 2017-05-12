package Tk::WorkspaceText;
# Temp version for CPAN
$VERSION=0.57;
my $RCSRevKey = '$Revision: 0.58 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

require Exporter;
use Tk qw(Ev);

Construct Tk::Widget 'WorkspaceText';
use base qw(Tk::TextUndo Tk::Toplevel);
#
# Bound in Tk::Text.pm
#
sub InsertKeypress {
  my ($w,$char)=@_;
  $w -> SUPER::InsertKeypress($char);
  $w -> {modified} = '1' if (defined $char && $char ne '');
}

sub Insert {
    my $w = shift;
    my $string = shift;
    $w -> SUPER::Insert($string);
    $w -> {modified} = '1';
}

sub Delete {
    my ($w) = @_;
    $w -> SUPER::Delete;
    $w -> {modified} = '1';
}

sub Backspace {
 my ($w) = @_;
 $w -> SUPER::Backspace;
 $w -> {modified} = '1';
}

sub clipboardColumnCut {
 my ($w) = @_;
 $w-> Column_Copy_or_Cut(1);
 $w -> {modified} = '1';
}

sub clipboardColumnPaste {
 my ($w) = @_;
 $w -> SUPER::clipboardColumnPaste;
 $w -> {modified} = '1';
}

sub ClassInit {
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw);
 $Tk::prevPos = undef;
 $mw -> bind($class, '<Tab>', 'fixed_tabs');
 $mw -> bind($class, '<Alt-h>', 'selectPara');
 $mw -> bind($class, '<Alt-l>', 'paragraphFill');
 $mw -> bind($class, '<Control-v>', ['SetCursor',Ev('ScrollPages',1)]);
 $mw -> bind($class, '<Control-r>', ['SetCursor',Ev('ScrollPages',-1)]);
 $mw -> bind($class, '<Control-period>', 'center');
 return $class;
}

sub InitObject {
    my ($w, $args)  = @_;
    $w -> {modified} = '';
    $w -> {fixedtabs} = '8';
    $w -> {fillcolumn} = '65';
    $w -> bind ('<Tab>', sub{ $w -> fixed_tabs });
    return $w;
}

sub Populate {
  my ($w, $args) = @_;
  $w -> SUPER::Populate($args);
  return $w;
}

sub paragraphFill {
  my ($w) = @_;
  my ($tmpline, $breakpos);
  my ($insertrow,$insertcol) = split /\./, $w -> index ('insert');
  $previndex = $w -> prevPara ($w -> index ('insert'));
  $nextindex = $w -> nextPara ($w -> index ('insert'));
  my $t = $w -> get ("$previndex linestart", "$nextindex - 1 line");
  $t =~ s/\n/ /smg;
  $w -> delete ("$previndex linestart", "$nextindex - 1 line");
  $w -> markSet ('insert', "$previndex linestart");
  while (length ($t) >= $w -> {fillcolumn}) {
      $tmpline = substr ($t, 0, $w -> {fillcolumn});
      $breakpos = rindex ($tmpline, ' ');
      $tmpline = substr ($t, 0, $breakpos);
      # Remove the extra space unless it's an indented line
      $tmpline =~ s/^ // unless ($tmpline =~ /^(\t|\s\s+)/) ;
      $w -> insert('insert', "$tmpline\n");
      $t = substr ($t, $breakpos);
  }
  $t =~ s/^ //;
  # Trim the extra space from the end of the last line.
  chop $t;
  $w -> insert('insert', "$t\n");
  $w -> markSet ('insert', "$insertrow.$insertcol");
  $w -> {modified} = '1';
}

sub selectPara {
    my ($w) = @_;
    my ($insertrow,$insertcol) = split /\./, $w -> index ('insert');
    $previndex = $w -> prevPara ($w -> index ('insert'));
    $nextindex = $w -> nextPara ($w -> index ('insert'));
    $w -> tagAdd ('sel', "$previndex linestart", "$nextindex linestart");
}

# Determines if insertion cursor is on the first line of 
# a paragraph before calling standard routine.
sub prevPara {
    my ($w,$args) = @_;
    my $i = $w -> index ('insert');
    my $t = $w -> get ( "$i - 1 line" );
    if ($t eq "\n") {
	return $w -> index ('insert');
    }
    return $w -> SUPER::PrevPara ($args);
}

sub fillcolumn {
    my $self = shift;
    if (@_) { $self -> {fillcolumn} = shift }
    return $self -> {fillcolumn}
}

sub setFixedTabs {
    my ($w,$args) = @_;
    $w -> {fixedtabs} = $args;
}

sub fixed_tabs {
    my ($w, $args) = @_;
    my $tabsize = $w -> {fixedtabs};
    my ($row,$col) = split /\./, $w -> index ('insert');
    my $ntabs = int ($col/$tabsize);
    my $nextab = ($ntabs + 1) * $tabsize;
    $w -> insert( $w -> index ('insert'),
		       ' ' x ($nextab - $col));
    $w -> markSet( 'insert',  "$row.$nextab");
    $w -> break; 
}

sub nextPara {
    my ($w,$args) = @_;
    return $w -> SUPER::NextPara ($args);
}

sub center {
    my ($w,$args) = @_;
    my ($row,$col) = split /\./, $w->index('insert');
    my ($endrow,$endcol) = split /\./, $w->index('end');
    my $start = ($w->yview)[0];
    my $end = ($w->yview)[1];
    my $linefraction = 1/$endrow;
    my $firstline = int $start/$linefraction;
    my $lastline = int $end/$linefraction;
    my $visible = $end - $start;
    my $visiblelines = int $visible/$linefraction;
    my $dotline = int $visiblelines/2;
    my $cursorline = $row - $firstline;
    $w -> yviewScroll(($cursorline - $dotline), 'units' );
    $w -> break;
}

sub modified {
    my $self = shift;
    if (@_) { $self -> {modified} = shift }
    return $self -> {modified}
}

1;

=head1 NAME

    WorkspaceText.pm - Text editor widget.

=head1 SYNOPSIS

    use Tk::WorkspaceText;

    my $w = new Tk::WorkspaceText (<options>);

=head1 DESCRIPTION

The Tk::WorkspaceText widget is derived from the Tk::Text
and Tk::TextUndo widgets.  For information about standard
options, refer to the widgets' documentation. 

Tk::WorkspaceText widgets use fixed tabs, and support paragraph
filling and selection, a "text modified" flag, recentering, and
additional key bindings.

Paragraphs are defined as contiguous lines of text separated
by blank lines - lines that consist only of a newline ("\n").

=head1 WIDGET METHODS

The Tk::WorkspaceText widget supports the B<configure>
and B<cget> methods described in the L<Tk::options> 
documentation.  The Tk::WorkspaceText widget also inherits
all the methods of the Tk::Widget, Tk::Text, and
Tk::TextUndo widget classes.

In addition, Tk::WorkspaceText widgets recognize these
methods:

=over 4

=item I<$text>-E<gt>B<paragraphFill>

Fill the paragraph that contains the insertion point.  Paragraphs
are defined as a series of contiguous lines of text separated by
blank lines.  Text is filled against the left margin, and wraps
before the right margin, which can be set with the B<wrapcolumn>
method, below.

=item I<$text>-E<gt>B<selectPara>

Select the entire paragraph.  As with paragraphFill, paragraphs are
defined as a set of contiguous lines separated by blank lines.

=item I<$text>-E<gt>B<prevPara>

Set the insertion cursor to the first line of a paragraph.  Does
nothing if the insertion cursor is already on the first line of 
the paragraph.  

=item I<$text>-E<gt>B<setFixedTabs>

Set fixed tab stops to the value of the numeric argument.  Tab
stops occur every 8 columns by default.

=item I<$text>-E<gt>B<center>

Center the line that contains the insertion cursor in the window.

=item I<$text>-E<gt>B<modified>

With argument, sets the modified flag to the argument.  With no
argument, returns the value of the modified flag.  By default, the
value of the modified flag is '1' if text was modified, '' if
unmodified.

=item I<$text>-E<gt>B<fillcolumn>

With argument, set the right margin column for filling 
paragraphs.  Returns the value of the right margin.
The default is column 65.

=back

=head1 KEY BINDINGS

Tk::WorkspaceText widgets support the keybindings of the Tk::Text and
Tk::TextUndo widgets, in addition to its own bindings.  For further
information, please refer to the Tk::Text, Tk::TextUndo, and
Tk::bind man pages.

    Alt-H                 Select Paragraph
    Alt-L                 Fill Paragraph

    Right, Ctrl-F         Forward Character
    Left, Ctrl-B          Backward Character
    Up, Ctrl-P            Up One Line
    Down, Ctrl-N          Down One Line
    Shift-Right           Forward Character Extend Selection
    Shift-Left            Backward Character Extend Selection
    Shift-Up              Up One Line, Extend Selection
    Shift-Down            Down One Line, Extend Selection
    Ctrl-Right, Meta-F    Forward Word
    Ctrl-Left, Meta-B     Backward Word
    Ctrl-Up               Up One Paragraph
    Ctrl-Down             Down One Paragraph
    PgUp                  Scroll View Up One Screen
    PgDn                  Scroll View Down One Screen
    Ctrl-PgUp             Scroll View Right
    Ctrl-PgDn             Scroll View Left
    Home, Ctrl-A          Beginning of Line
    End, Ctrl-E           End of Line
    Ctrl-Home, Meta-<     Beginning of Text
    Ctrl-End, Meta->      End of Text
    Ctrl-/                Select All
    Ctrl-\                Clear Selection
    F16, Copy, Meta-W     Copy Selection to Clipboard
    F20, Cut, Ctrl-W      Copy Selection to Clipboard and Delete
    F18, Paste, Ctrl-Y    Paste Clipboard Text at Insertion Point
    Delete, Ctrl-D        Delete Character to Right, or Selection
    Backspace, Ctrl-H     Delete Character to Left, or Selection
    Meta-D                Delete Word to Right
    Meta-Backspace, Meta-Delete
                          Delete Word to Left
    Ctrl-K                Delete from Cursor to End of Line
    Ctrl-O                Open a Blank Line
    Ctrl-X                Clear Selection
    Ctrl-T                Reverse Order of Characters on Either Side
                          of the Cursor
    Ctrl-.                Center the line the insertion point is on
                          in the window.

    Mouse Button 1:
    Single Click: Set Insertion Cursor at Mouse Pointer
    Double Click: Select Word Under the Mouse Pointer and Position 
    Cursor at the Beginning of the Word
    Triple Click: Select Line Under the Mouse Pointer and Position 
    Cursor at the Beginning of the Line
    Drag: Define Selection from Insertion Cursor
    Shift-Drag: Extend Selection
    Double Click, Shift-Drag: Extend Selection by Whole Words
    Triple Click, Shift-Drag: Extend Selection by Whole Lines
    Ctrl: Position Insertion Cursor without Affecting Selection

    Mouse Button 2:
    Click: Copy Selection into Text at the Mouse Pointer
    Drag:Shift View

    Mouse Button 3:
    Pop Up Menu Bar

    Meta                  Escape

=head1 CREDITS

  Tk::WorkspaceText by rkiesling@mainmatter.com (Robert Kiesling)

  Perl/Tk by Nick Ing-Simmons.
  Perl by Larry Wall and many others.

=head1 REVISION

$Id: WorkspaceText.pm,v 0.58 2001/09/15 02:22:54 kiesling Exp $

=head1 SEE ALSO:

Tk::Workspace(3), Tk::overview(3), Tk::ColorEditor(3), perl(1) manual
pages.

=cut

    


