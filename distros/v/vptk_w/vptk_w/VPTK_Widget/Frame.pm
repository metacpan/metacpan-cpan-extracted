package vptk_w::VPTK_Widget::Frame;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat'] }
sub TkClassName   { 'Tk::Frame' }
sub PrintTitle    { 'Frame' }
sub AssociatedIcon{ 'frame' }
sub EditorProperties {
  return {
    -background=>'color',-borderwidth=>'int+',-relief=>'relief',-scrollbars=>'scrolled',
    -label=>'text',-width=>'int+',-height=>'int+'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Frame(@args);
}

1;
