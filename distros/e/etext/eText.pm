package Tk::eText;

# Copyright (c) 1996-1997 Ilya Zakharevich.  All rights reserved.
# Modernization for Perl/Tk 804 (c) 2026.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION);
$VERSION = '2.09';

use Tk qw(Ev);
use Tk::Text;
use base qw(Tk::Text);
use XSLoader;
use Scalar::Util ();

Construct Tk::Widget 'eText';

# Not "bootstrap Tk::eText": that would resolve through @ISA to the boot
# XSUB DynaLoader installed as Tk::Text::bootstrap.
XSLoader::load('Tk::eText', $VERSION);

sub Tk_cmd { \&Tk::etext }

sub Tk::Widget::ScrleText { shift->Scrolled('eText' => @_) }

# Everything Tk::Text has, plus the "block" and "ornament" subcommands.
Tk::Methods('block', 'ornament');

# Keyboard undo and redo (MainWindow maps Control-z and friends to the
# <<Undo>> and <<Redo>> virtual events; Tk::Text itself binds neither).
# An empty stack is not an error worth a bell or a Tk::Error dialog.
sub ClassInit {
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit($mw);
  $mw->bind($class, '<<Undo>>', 'undoFromKey');
  $mw->bind($class, '<<Redo>>', 'redoFromKey');

  # The insertion cursor skips elided text, as in Tk 8.5: the cursor
  # keys step by "display indices" (Tk::Text's step by characters and
  # can leave the cursor in hidden text), the word keys use "display
  # wordstart" and "display wordend", Home and End go to the first and
  # the last visible position of the display line (the wrapped line on
  # the screen, as in Tk 8.5; Tk::Text's go to the logical line's).
  my $left = Ev('index', 'insert -1 display indices');
  my $right = Ev('index', 'insert +1 display indices');
  my $wordstart = Ev('index', 'insert -1 display indices display wordstart');
  my $wordend = Ev('index', 'insert +1 display indices display wordend');
  my $home = Ev('index', 'insert display linestart +0 display indices');
  my $end = Ev('index', 'insert display lineend -0 display indices');
  $mw->bind($class, '<Left>', ['SetCursor', $left]);
  $mw->bind($class, '<Shift-Left>', ['KeySelect', $left]);
  $mw->bind($class, '<Control-Left>', ['SetCursor', $wordstart]);
  $mw->bind($class, '<Shift-Control-Left>', ['KeySelect', $wordstart]);
  $mw->bind($class, '<Right>', ['SetCursor', $right]);
  $mw->bind($class, '<Shift-Right>', ['KeySelect', $right]);
  $mw->bind($class, '<Control-Right>', ['SetCursor', $wordend]);
  $mw->bind($class, '<Shift-Control-Right>', ['KeySelect', Ev('index', 'insert display wordend')]);
  $mw->bind($class, '<Home>', ['SetCursor', $home]);
  $mw->bind($class, '<Shift-Home>', ['KeySelect', $home]);
  $mw->bind($class, '<End>', ['SetCursor', $end]);
  $mw->bind($class, '<Shift-End>', ['KeySelect', $end]);
  unless ($Tk::strictMotif) {
    $mw->bind($class, '<Control-a>', ['SetCursor', $home]);
    $mw->bind($class, '<Control-b>', ['SetCursor', $left]);
    $mw->bind($class, '<Control-e>', ['SetCursor', $end]);
    $mw->bind($class, '<Control-f>', ['SetCursor', $right]);
    $mw->bind($class, '<Meta-b>', ['SetCursor', $wordstart]);
    $mw->bind($class, '<Meta-f>', ['SetCursor', Ev('index', 'insert display wordend')]);
  }
  return $class;
}
sub undoFromKey { my $w = shift; eval { $w->editUndo }; return }
sub redoFromKey { my $w = shift; eval { $w->editRedo }; return }

# The ready-made -valuecommand: "-valuecommand => 'DETACH'" makes the
# widget call this method (a callback given as a string is a method of
# the widget), which passes the notification on to the value if it is
# an object with a DETACH method: $value->DETACH($widget, $event, $kind,
# $where, $cause).  Other values are skipped.
sub DETACH {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  $value->DETACH($w, $event, $kind, $where, $cause)
    if Scalar::Util::blessed($value) && $value->can('DETACH');
  return;
}

# Cut, copy and paste with structure.  The clipboard gets the string, as
# from Tk::Text (other programs see the text, with the delimiters of the
# blocks as characters).  The MainWindow also keeps the list of "block
# list -values" (or of "block cut") of the selection beside that string,
# and clipboardPaste pastes the list with "block paste" while the
# clipboard still holds the same string: the separators come back at
# their depths with the values of what they begin, whole blocks with
# their data, runs with their values.  When the clipboard holds
# something else (another program, or another widget, has set it), the
# string is inserted as text, as Tk::Text does.  A selection of several
# ranges is handled by Tk::Text, as text.
sub clipboardCopy {
  my $w = shift;
  my @sel = $w->tagRanges('sel');
  my $val = $w->SUPER::clipboardCopy(@_);
  my $mw = $w->MainWindow;
  delete $mw->{'_eTextClipboard'};
  $mw->{'_eTextClipboard'} = [$val, [$w->blockList('-values', @sel)]]
    if defined $val and @sel == 2;
  return $val;
}

sub clipboardCut {
  my $w = shift;
  my @sel = $w->tagRanges('sel');
  return $w->SUPER::clipboardCut(@_) unless @sel == 2;
  my $val = $w->SUPER::clipboardCopy(@_);
  return $val unless defined $val;
  $w->MainWindow->{'_eTextClipboard'} = [$val, [$w->blockCut(@sel)]];
  return $val;
}

sub clipboardPaste {
  my $w = shift;
  my $kept = $w->MainWindow->{'_eTextClipboard'};
  my $string = $kept ? Tk::catch { $w->clipboardGet } : undef;
  return $w->SUPER::clipboardPaste(@_)
    unless $kept and defined $string and $string eq $kept->[0];
  # As Tk::Text::Insert: a selection that covers the insertion cursor
  # is replaced; the deletion and the paste are one undo step.
  my @sel = $w->tagRanges('sel');
  $w->editStep(sub {
    while (my ($first, $last) = splice @sel, 0, 2) {
      next unless $w->compare($first, '<=', 'insert')
	and $w->compare($last, '>=', 'insert');
      $w->blockCut($first, $last);	# Its values go with it.
      last;
    }
    my @range = $w->blockPaste('insert', $kept->[1]);
    $w->markSet('insert', $range[1]) if @range == 2;
  });
  $w->see('insert');
  return;
}

# Several changes as one undo step.  $w->editStep(sub { ... }, @args)
# runs the code between "edit step begin" and "edit step end" (the end
# also when the code dies) and returns what the code returns.  Inside,
# no separator goes into the undo history, and the values set (block
# nodedata, tag data, mark data, block data) are recorded, so that one
# editUndo takes everything back.  Steps nest: the outermost one is the
# undo step.  Without code it is the subcommand: editStep('begin'),
# editStep('end'), and editStep() for the number of steps open.
sub editStep {
  my $w = shift;
  return $w->edit('step', @_) unless @_ and ref $_[0] eq 'CODE';
  my $code = shift;
  my $want = wantarray;
  my @result;
  $w->edit('step', 'begin');
  my $ok = eval {
    if ($want) { @result = $code->(@_) }
    elsif (defined $want) { $result[0] = $code->(@_) }
    else { $code->(@_) }
    1;
  };
  my $error = $@;
  eval { $w->edit('step', 'end') } if Tk::Exists($w);
  die $error unless $ok;
  return $want ? @result : $result[0];
}

# The editXxx and imageXxx spellings are generated in this package too
# (Tk::Text's versions call Tk::Text::edit and Tk::Text::image directly,
# which would bypass an override here); markData and tagData are new.
use Tk::Submethods ( 'block' => [qw(at addline cget configure cut data delete
				    deletelines flatten insert level list names nodedata
				    of paste split sprout trim)],
		     'edit'  => [qw(modified redo reset separator undo)],
		     'ornament' => [qw(cget configure coords create delete names
				       point points)],
		     'mark'  => [qw(data)],
		     'tag'   => [qw(data)],
		     'image' => [qw(cget configure create names)],
		   );

1;

__END__

=head1 NAME

Tk::eText - a Tk text widget with nestable "blocks" (editable formulas)

=head1 SYNOPSIS

  use Tk;
  use Tk::eText;

  my $mw   = MainWindow->new;
  my $text = $mw->ScrleText(-wrap => 'word')->pack(-expand => 1, -fill => 'both');

  $text->blockConfigure('Fraction', -layoutcmd => \&fraction_layout);
  $text->insert('end', "A fraction: ");
  $text->blockInsert('end', 'Fraction', "numerator\ndenominator");

=head1 DESCRIPTION

C<Tk::eText> is a drop-in replacement for L<Tk::Text> (it inherits all of
its Perl-level bindings and methods) which adds one more kind of text
annotation to tags, marks and embedded windows: the I<block>.

Blocks have an internal structure (they contain lines of text, which in
turn may contain nested blocks), nest arbitrarily, and perform geometry
management over their contents.  The geometry management is governed by
a Perl callback (the C<-layoutcmd> of the block type), which makes it
possible to typeset -- and edit in place -- things like fractions,
super- and subscripts, radicals, labeled equations, tables, etc.  All
the usual editing commands work on blocks.

The widget command additionally supports the C<block> subcommand
(available as the C<blockI<Xxx>> methods) and an "object-oriented dump"
(C<blockList>), which returns the contents of a range as a list of
strings and blessed objects (C<Tk::Text::Block>, C<Tk::Text::TagOn>,
...).

A Perl scalar (a I<value>) can be kept with every node of the tree of
a block, the leaves included (C<blockNodedata>, the C<block nodedata>
subcommand), with every mark (C<markData>, C<mark data>) and with every
run of a tag (C<tagData>, C<tag data>).  The widget keeps a copy; the
values move with the text, edits that join nodes or merge runs keep
the first value present, C<editUndo> gives back the values a deletion
dropped, and a value is freed only at documented moments, never in the
middle of a change: when the widget command that drops it returns, so
that a C<DESTROY> method may read the widget (as a stopgap, the
commands that would modify it fail meanwhile).  C<blockList> shows them:
a fourth element of a block's header holds its node values, the
start of a run with a value is a C<Tk::Text::TagOn> holding
C<[name, value]> instead of a reference to the name, and a mark with a
value is a C<Tk::Text::MarkLeft> or C<Tk::Text::MarkRight> holding
C<[name, value]>.  See "Values" in
F<doc/etext.pod>.

A piece of a block can be taken out and put in elsewhere with its
structure and its values: C<blockList('-values', $from, $to)> lists a
range with the values of the leaves and nodes that begin in it,
C<blockCut($from, $to)> returns that list and deletes the range, and
C<blockPaste($index, \@list)> puts such a list in as one command
(see "Cut and paste with structure" in F<doc/etext.pod>).  The methods
C<clipboardCopy>, C<clipboardCut> and C<clipboardPaste> use them: the
clipboard gets the string of the selection, as from L<Tk::Text> (the
delimiters of blocks are characters in it), and the MainWindow keeps
the list beside it; C<clipboardPaste> pastes the list while the
clipboard still holds that string, so that a piece cut from a table
comes back as rows and cells, and inserts the string as text when the
clipboard was set by something else.  A selection that covers the
insertion cursor is replaced, as L<Tk::Text> does it.

C<< $text->editStep(sub { ... }, @args) >> runs the code as one undo
step: one C<editUndo> takes back all its changes, the values it set
with C<blockNodedata>, C<tagData>, C<markData> and C<blockData>
included (outside such a step the setting of a value is not
recorded).  The step is ended also when the code dies, and the method
returns what the code returns.  It uses the subcommands C<edit step
begin> and C<edit step end>, which C<editStep('begin')> and
C<editStep('end')> call directly; see "Several changes as one undo
step" in F<doc/etext.pod>.

The complete documentation of the widget, of blocks and of the
C<-layoutcmd> protocol is in F<doc/etext.pod> of this distribution
(source repository: L<https://github.com/ilyaz-ai/etext>); a large demo
(with TeX import/export) is in F<demo/etext.pl>.

=head1 HISTORY

The C part of this widget is the tk4.0b3 text widget as modified by Ilya
Zakharevich in 1995-1997 (I<etext> 0.4 ... 1.6.2 on CPAN), which was
written against the Perl/Tk b9 "portable Tk" layer.  Version 2.00 (2026,
never released) is the same widget code ported to the API of Perl/Tk 804
and Perl 5.38, built as an ordinary standalone extension; 2.01 is the
first release of the modernized distribution, and 2.02 makes it work on
Windows (tested under Wine, with fixes to Perl/Tk itself; see README.md);
2.03 lets block nodes, marks and tag runs keep Perl values (see the manual,
"Values"); 2.04 makes block insert, split and trim and tag add and remove
undoable, with their values, and redo re-inserts exactly what was inserted;
2.05 keeps the values in data containers, tells the program before a value
is detached (C<-valuecommand>), lets DESTROY methods change the widget again,
and fixes the bugs listed in F<Changes>.

The features that the Tk text widget acquired after tk4.0 were added in
version 2.00: indices count characters (the text is UTF-8), the C<edit>
(undo/redo, modified flag) and C<image> (embedded images) subcommands
and the C<-elide> tag option exist and work inside blocks, the
C<display> and C<any> index modifiers of Tk 8.5 are understood
(C<display lines>, C<display linestart> and C<display lineend>
included), the cursor keys skip elided text, and the widget binds the C<< <<Undo>> >>
and C<< <<Redo>> >> virtual events (Control-z and friends) to
C<editUndo> and C<editRedo>.  Note that
C<edit undo> undoes here, while in Perl/Tk's own L<Tk::Text> it never
has anything to undo (that widget's undo is L<Tk::TextUndo>, written in
Perl).  C<search -regexp> is handled by Perl's regexp engine.

Differences from L<Tk::Text>: undoing a deletion re-creates the blocks,
tags, marks, embedded images and embedded windows that were in the
range, the blocks the deletion cut included (Tk re-creates none of
these; a window given with C<-window> was destroyed with the deletion
and comes back as an empty window segment, one with C<-create> is
created again when displayed); C<dump>
looks into blocks and reports C<block> and C<blockend>
elements (the C<-block> switch); C<+N lines> keeps the character
position where Tk keeps the byte offset; C<search -nocase> leaves alone
the few characters whose lower-case form has another UTF-8 length; the
insertion cursor skips elided text (Left, Right, Home, End and the word
keys step by C<display indices>, as in Tk 8.5).  Display lines never
span logical lines: a line whose newline is elided still ends a
display line, and an entirely elided line is a display line of no
height, where Tk 8.5 merges such lines with the next one; C<display
lines> passes over the elided lines and stops at the last display line
of the text, and the widget wraps as Tk 8.4 does (a space at the right
margin needs a pixel of room, Tk 8.5 lets it hang over).  The object-oriented
dump (C<blockList>) reports embedded images as C<Tk::Text::EmbImage>
objects, and lists the options of embedded images and windows after
their names (see F<doc/etext.pod>).

=head1 SEE ALSO

L<Tk::Text>, F<doc/etext.pod> in the distribution.

=head1 AUTHOR

Ilya Zakharevich.

=cut
