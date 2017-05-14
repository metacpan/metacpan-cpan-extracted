package vptk_w::VPTK_Widget::mtkcascade;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Menu' }
sub PrintTitle    { 'cascade' }
sub AssociatedIcon{ 'cascade' }
sub EditorProperties {
  return {
    -label=>'text',-accelerator=>'text',-background=>'color', 
    -foreground=>'color',-underline=>'int+'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->cascade(@args);
}

1;#)
