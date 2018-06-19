#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Text::Editor::Perl - Perl source code head-less editor written in Perl.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------

package Text::Editor::Perl;
our $VERSION = "20180616";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Storable;
use utf8;

#1 Editor                                                                       # A new editor

sub newEditor(@)                                                                #S Construct a new editor
 {my (@attributes) = @_;                                                        # Attributes for a new editor
  bless {@_};
 }

#2 Editor Attributes                                                            # Attributes for an editor
genLValueScalarMethods(qw(editorFile));                                         # Name of the file from whence the text came
genLValueScalarMethods(qw(editorLog));                                          # [Instruction to roll changes back or reapply them ...]
genLValueScalarMethods(qw(editorLines));                                        # [lines of text to be editted ...]
genLValueScalarMethods(qw(editorViews));                                        # [Views of the text ...]

#2 Editor Methods                                                               # Methods for a Attributes of a view

sub newLastLine($@)                                                             # Create a new line
 {my ($editor, @attributes) = @_;                                               # Editor, attributes
  my $l = Text::Editor::Perl::Line::newLine(@attributes);
  $l->lineEditor = $editor;
  push @{$editor->editorLines}, $l;
  $l
 }

sub newEditorView($@)                                                           # Create a new view
 {my ($editor, @attributes) = @_;                                               # Editor, attributes
  my $v = Text::Editor::Perl::View::newView(@attributes);
  $v->viewEditor = $editor;
  $v
 }

sub printEditor($)                                                              # Print an editor
 {my ($editor) = @_;                                                            # Editor
  my $lines  = $editor->editorLines;
  my @l;
  for my $line(@$lines)
   {push @l, $line->lineText
   }
  {lines=>[@l]}
 }

#1 View                                                                         # A view of the text being editted

package Text::Editor::Perl::View;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

#2 View Attributes                                                              # Attributes of a view
genLValueScalarMethods(qw(viewEditor));                                         # The editor that owns this view
genLValueScalarMethods(qw(viewCursorLine));                                     # Line the cursor is in
genLValueScalarMethods(qw(viewCursorChar));                                     # The char position of the cursor with 0 being just before the first character
genLValueScalarMethods(qw(viewCursorVertical));                                 # The number of lines the cursor spans
genLValueScalarMethods(qw(viewStartLine));                                      # The line number (numbered from zero) at which this view starts to display
genLValueScalarMethods(qw(viewStartChar));                                      # The character position at which this view starts to display
genLValueScalarMethods(qw(viewLines));                                          # The height of the view in rows
genLValueScalarMethods(qw(viewChars));                                          # The width of the view in chars
genLValueScalarMethods(qw(viewSelections));                                     # [Selection specifications ...]
genLValueScalarMethods(qw(viewBoxes));                                          # [Box specifications ...] - a rectangular selection

#2 View Methods                                                                 # Methods for a Attributes of a view

sub newView(@)                                                                  #S Create a new view
 {my (@attributes) = @_;                                                        # Attributes
  bless {viewCursorChar=>0, viewCursorVertical=>1, @_}
 }

sub viewAddChars($$)                                                            # Add the specified chars through the specifed view
 {my ($view, $textToAdd) = @_;                                                  # View, text to add
  my $line = $view->viewCursorLine;
  my $text = $line->lineText;
  my $cc   = $view->viewCursorChar;
  if ($cc >= length($text))
   {$line->lineText .= $textToAdd;
   }
  else
   {$line->lineText  = substr($text, 0, $cc).$textToAdd.substr($text, $cc+1);   # Update line of text
   }
 }

sub printView($)                                                                # Print a view
 {my ($view) = @_;                                                              # View
  my $editor = $view->viewEditor;
  my $lines  = $editor->editorLines;
  my @l;
  for my $line(@$lines)
   {push @l, $line->text
   }
  {lines=>[@l]}
 }

#1 Selection                                                                    # A selection delimits a contiguous block of text

package Text::Editor::Perl::Selection;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

sub newSelection(@)                                                             #S Construct a new view of the data being editted
 {my (@attributes) = @_;                                                        # Attributes for a new selection
  bless {@_};
 }

#2 Selection Attributes                                                         # Attributes for a selection
genLValueScalarMethods(qw(selectionView));                                      # The view that owns this selection
genLValueScalarMethods(qw(selectionStartLine));                                 # The line number (numbered from zero) at which this selection starts
genLValueScalarMethods(qw(selectionStartChar));                                 # The character position at which this selection starts
genLValueScalarMethods(qw(selectionEndLine));                                   # The line number (numbered from zero) at which this selection ends
genLValueScalarMethods(qw(selectionEndChar));                                   # The character position at which this selection ends

#1 Box                                                                          # A box is a rectangular block of text

package Text::Editor::Perl::Box;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

sub newBox(@)                                                                   #S Construct a new box
 {my (@attributes) = @_;                                                        # Attributes for a new box
  bless {@_};
 }

#2 Box Attributes                                                               # Attributes for a box
genLValueScalarMethods(qw(boxView));                                            # The view that owns this box
genLValueScalarMethods(qw(boxStartLine));                                       # The line number (numbered from zero) at which this box starts
genLValueScalarMethods(qw(boxStartChar));                                       # The character position at which this box end
genLValueScalarMethods(qw(boxWidth));                                           # The width of the box in characters - can be positive, zero or negative
genLValueScalarMethods(qw(boxHeight));                                          # The height if the boc in lines     - can be positive, zero or negative

#1 Line                                                                         # A line holds a line of text being editted

package Text::Editor::Perl::Line;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

sub newLine(@)                                                                  #S Construct a new line
 {my (@attributes) = @_;                                                        # Attributes for a new line
  bless {lineText=>q(), @_};
 }

#2 Line Attributes                                                              # Attributes for a line
genLValueScalarMethods(qw(lineEditor));                                         # The editor that contains this line
genLValueScalarMethods(qw(lineText));                                           # A string holding the text being editted
genLValueScalarMethods(qw(lineCharAttrs));                                      # A vec string which bolds 8 bits for each character in the string describing its display attributes
genLValueScalarMethods(qw(lineLabel));                                          # A string naming this line
genLValueScalarMethods(qw(lineCommand));                                        # A string naming a command that starts or ends on this line
genLValueScalarMethods(qw(lineVisible));                                        # The line id visible if true

#1 Snippet                                                                      # A snippet is a replacement string

package Text::Editor::Perl::Snippet;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

sub newSnippet(@)                                                               #S Construct a new snippet
 {my (@attributes) = @_;                                                        # Attributes for a new snippet
  bless {@_};
 }

#2 Snippet Attributes                                                           # Attributes for a snippet
genLValueScalarMethods(qw(snippetSource));                                      # The source to be expanded
genLValueScalarMethods(qw(snippetReplacement));                                 # Replacement string
genLValueScalarMethods(qw(snippetCursor));                                      # cursor offset in replacement string

package Text::Editor::Perl;
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Text::Editor::Perl - Perl source code head-less editor written in Perl.

=head1 Synopsis

Perl source code head-less editor written in Perl.

=head1 Description

Perl source code head-less editor written in Perl.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Editor

A new editor

=head2 newEditor(@)

Construct a new editor

     Parameter    Description
  1  @attributes  Attributes for a new editor

Example:


  my $e = newEditor;


This is a static method and so should be invoked as:

  Text::Editor::Perl::newEditor


=head2 Editor Attributes

Attributes for an editor

=head3 editorFile :lvalue

Name of the file from whence the text came


=head3 editorLog :lvalue

[Instruction to roll changes back or reapply them ...]


=head3 editorLines :lvalue

[lines of text to be editted ...]


=head3 editorViews :lvalue

[Views of the text ...]


=head2 Editor Methods

Methods for a Attributes of a view

=head3 newLastLine($@)

Create a new line

     Parameter    Description
  1  $editor      Editor
  2  @attributes  Attributes

Example:


  my $l = $e->newLastLine();


=head3 newEditorView($@)

Create a new view

     Parameter    Description
  1  $editor      Editor
  2  @attributes  Attributes

Example:


  my $v = $e->newEditorView(viewCursorLine=>$l, viewCursorChar=>0);


=head3 printEditor($)

Print an editor

     Parameter  Description
  1  $editor    Editor

Example:


  is_deeply $e->printEditor, {lines => ["Hello World"]};


=head1 View

A view of the text being editted

=head2 View Attributes

Attributes of a view

=head3 viewEditor :lvalue

The editor that owns this view


=head3 viewCursorLine :lvalue

Line the cursor is in


=head3 viewCursorChar :lvalue

The char position of the cursor with 0 being just before the first character


=head3 viewCursorVertical :lvalue

The number of lines the cursor spans


=head3 viewStartLine :lvalue

The line number (numbered from zero) at which this view starts to display


=head3 viewStartChar :lvalue

The character position at which this view starts to display


=head3 viewLines :lvalue

The height of the view in rows


=head3 viewChars :lvalue

The width of the view in chars


=head3 viewSelections :lvalue

[Selection specifications ...]


=head3 viewBoxes :lvalue

[Box specifications ...] - a rectangular selection


=head2 View Methods

Methods for a Attributes of a view

=head3 newView(@)

Create a new view

     Parameter    Description
  1  @attributes  Attributes

This is a static method and so should be invoked as:

  Text::Editor::Perl::newView


=head3 viewAddChars($$)

Add the specified chars through the specifed view

     Parameter   Description
  1  $view       View
  2  $textToAdd  Text to add

Example:


  $v->viewAddChars(q(Hello World));


=head3 printView($)

Print a view

     Parameter  Description
  1  $view      View

=head1 Selection

A selection delimits a contiguous block of text

=head2 newSelection(@)

Construct a new view of the data being editted

     Parameter    Description
  1  @attributes  Attributes for a new selection

This is a static method and so should be invoked as:

  Text::Editor::Perl::newSelection


=head2 Selection Attributes

Attributes for a selection

=head3 selectionView :lvalue

The view that owns this selection


=head3 selectionStartLine :lvalue

The line number (numbered from zero) at which this selection starts


=head3 selectionStartChar :lvalue

The character position at which this selection starts


=head3 selectionEndLine :lvalue

The line number (numbered from zero) at which this selection ends


=head3 selectionEndChar :lvalue

The character position at which this selection ends


=head1 Box

A box is a rectangular block of text

=head2 newBox(@)

Construct a new box

     Parameter    Description
  1  @attributes  Attributes for a new box

This is a static method and so should be invoked as:

  Text::Editor::Perl::newBox


=head2 Box Attributes

Attributes for a box

=head3 boxView :lvalue

The view that owns this box


=head3 boxStartLine :lvalue

The line number (numbered from zero) at which this box starts


=head3 boxStartChar :lvalue

The character position at which this box end


=head3 boxWidth :lvalue

The width of the box in characters - can be positive, zero or negative


=head3 boxHeight :lvalue

The height if the boc in lines     - can be positive, zero or negative


=head1 Line

A line holds a line of text being editted

=head2 newLine(@)

Construct a new line

     Parameter    Description
  1  @attributes  Attributes for a new line

This is a static method and so should be invoked as:

  Text::Editor::Perl::newLine


=head2 Line Attributes

Attributes for a line

=head3 lineEditor :lvalue

The editor that contains this line


=head3 lineText :lvalue

A string holding the text being editted


=head3 lineCharAttrs :lvalue

A vec string which bolds 8 bits for each character in the string describing its display attributes


=head3 lineLabel :lvalue

A string naming this line


=head3 lineCommand :lvalue

A string naming a command that starts or ends on this line


=head3 lineVisible :lvalue

The line id visible if true


=head1 Snippet

A snippet is a replacement string

=head2 newSnippet(@)

Construct a new snippet

     Parameter    Description
  1  @attributes  Attributes for a new snippet

This is a static method and so should be invoked as:

  Text::Editor::Perl::newSnippet


=head2 Snippet Attributes

Attributes for a snippet

=head3 snippetSource :lvalue

The source to be expanded


=head3 snippetReplacement :lvalue

Replacement string


=head3 snippetCursor :lvalue

cursor offset in replacement string



=head1 Index


1 L<boxHeight|/boxHeight>

2 L<boxStartChar|/boxStartChar>

3 L<boxStartLine|/boxStartLine>

4 L<boxView|/boxView>

5 L<boxWidth|/boxWidth>

6 L<editorFile|/editorFile>

7 L<editorLines|/editorLines>

8 L<editorLog|/editorLog>

9 L<editorViews|/editorViews>

10 L<lineCharAttrs|/lineCharAttrs>

11 L<lineCommand|/lineCommand>

12 L<lineEditor|/lineEditor>

13 L<lineLabel|/lineLabel>

14 L<lineText|/lineText>

15 L<lineVisible|/lineVisible>

16 L<newBox|/newBox>

17 L<newEditor|/newEditor>

18 L<newEditorView|/newEditorView>

19 L<newLastLine|/newLastLine>

20 L<newLine|/newLine>

21 L<newSelection|/newSelection>

22 L<newSnippet|/newSnippet>

23 L<newView|/newView>

24 L<printEditor|/printEditor>

25 L<printView|/printView>

26 L<selectionEndChar|/selectionEndChar>

27 L<selectionEndLine|/selectionEndLine>

28 L<selectionStartChar|/selectionStartChar>

29 L<selectionStartLine|/selectionStartLine>

30 L<selectionView|/selectionView>

31 L<snippetCursor|/snippetCursor>

32 L<snippetReplacement|/snippetReplacement>

33 L<snippetSource|/snippetSource>

34 L<viewAddChars|/viewAddChars>

35 L<viewBoxes|/viewBoxes>

36 L<viewChars|/viewChars>

37 L<viewCursorChar|/viewCursorChar>

38 L<viewCursorLine|/viewCursorLine>

39 L<viewCursorVertical|/viewCursorVertical>

40 L<viewEditor|/viewEditor>

41 L<viewLines|/viewLines>

42 L<viewSelections|/viewSelections>

43 L<viewStartChar|/viewStartChar>

44 L<viewStartLine|/viewStartLine>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Text::Editor::Perl

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>1;

if (1)
 {my $e = newEditor;                                                            #TnewEditor
  my $l = $e->newLastLine();                                                    #TnewLastLine
  my $v = $e->newEditorView(viewCursorLine=>$l, viewCursorChar=>0);             #TnewEditorView
     $v->viewAddChars(q(Hello World));                                          #TviewAddChars
  is_deeply $e->printEditor, {lines => ["Hello World"]};                        #TprintEditor
 }
