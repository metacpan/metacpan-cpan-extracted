package vptk_w::VPTK_Widget::mtkradiobutton;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Menu' }
sub PrintTitle    { 'radiobutton' }
sub AssociatedIcon{ 'radiobutton' }
sub EditorProperties {
  return {
    -label=>'text',-accelerator=>'text',-background=>'color',-value=>'text', 
    -foreground=>'color',-underline=>'int+',-command=>'callback',
    -variable=>'variable'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->radiobutton(@args);
}

1;#)
