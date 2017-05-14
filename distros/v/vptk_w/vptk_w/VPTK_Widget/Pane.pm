package vptk_w::VPTK_Widget::Pane;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Pane' }
sub PrintTitle    { 'Pane' }
sub AssociatedIcon{ 'frame' }
sub EditorProperties {
  return {
    -scrollbars=>'scrolled',-sticky=>'sticky',
    -background=>'color',-width=>'int+',-height=>'int+',
    -borderwidth=>'int+',-relief=>'relief',
    -gridded => 'menu(|x|y|xy)'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Pane(@args);
}

1;
