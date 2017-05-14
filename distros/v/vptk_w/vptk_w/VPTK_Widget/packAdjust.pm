package vptk_w::VPTK_Widget::packAdjust;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Adjuster' }
sub PrintTitle    { 'packAdjust' }
sub AssociatedIcon{ 'packadjust' }
sub EditorProperties {
  return {
    -side=>'side'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->packAdjust(@args);
}

1;#)
