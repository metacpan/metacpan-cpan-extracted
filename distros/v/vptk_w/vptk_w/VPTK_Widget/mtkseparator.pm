package vptk_w::VPTK_Widget::mtkseparator;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Menu' }
sub PrintTitle    { 'separator' }
sub AssociatedIcon{ 'separator' }
sub EditorProperties {
  return {
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->separator(@args);
}

1;#)
