package vptk_w::VPTK_Widget::Canvas;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [ -relief=>'plain' ] }
sub TkClassName   { 'Tk::Canvas' }
sub PrintTitle    { 'Canvas' }
sub AssociatedIcon{ 'canv_polygon' }
sub EditorProperties {
  return {
-background=> 'color',
-borderwidth=> 'int+',
-height=> 'int+',
-relief=> 'relief',
-updatecommand=> 'callback',
-width=> 'int+',
-scrollbars=>'scrolled'
  }
}

sub JustDraw {
  my ($this,$parent,%args) = @_;
  return $parent->Canvas(%args);
}

1;#)

