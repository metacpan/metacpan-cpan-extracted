package vptk_w::VPTK_Widget::NoteBookFrame;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::NoteBook' }
sub PrintTitle    { 'NoteBookFrame' }
sub AssociatedIcon{ 'notebookframe' }
sub EditorProperties {
  return {
    -anchor=>'anchor',-label=>'text',-justify=>'justify',
    -createcmd=>'callback',-raisecmd=>'callback',
    -state=>'menu(normal|disabled)',-underline=>'int+',-wraplength=>'int+'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->add($this->{'-id'},@args);
}

1;#)
