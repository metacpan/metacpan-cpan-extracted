package Tk::eText;

# Copyright (c) 1996-1997 Ilya Zakharevich.  All rights reserved.
# Modernization for Perl/Tk 804 (c) 2026.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION);
$VERSION = '2.01';

use Tk qw(Ev);
use Tk::Text;
use base qw(Tk::Text);
use XSLoader;

Construct Tk::Widget 'eText';

# Not "bootstrap Tk::eText": that would resolve through @ISA to the boot
# XSUB DynaLoader installed as Tk::Text::bootstrap.
XSLoader::load('Tk::eText', $VERSION);

sub Tk_cmd { \&Tk::etext }

sub Tk::Widget::ScrleText { shift->Scrolled('eText' => @_) }

# Everything Tk::Text has, plus the "block" subcommand.
Tk::Methods('block');

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

# The editXxx and imageXxx spellings are generated in this package too
# (Tk::Text's versions call Tk::Text::edit and Tk::Text::image directly,
# which would bypass an override here).
use Tk::Submethods ( 'block' => [qw(at addline cget configure data delete
				    deletelines insert list names of
				    split trim)],
		     'edit'  => [qw(modified redo reset separator undo)],
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
first release of the modernized distribution.

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
