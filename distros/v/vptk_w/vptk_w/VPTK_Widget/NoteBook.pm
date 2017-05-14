package vptk_w::VPTK_Widget::NoteBook;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::NoteBook' }
sub PrintTitle    { 'NoteBook' }
sub AssociatedIcon{ 'notebook' }
sub EditorProperties {
  return {
    -ipadx=>'int+',-ipady=>'int+'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->NoteBook(@args);
}

1;#)
