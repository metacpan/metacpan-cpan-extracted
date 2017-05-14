package vptk_w::VPTK_Widget::mtkcommand;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Menu' }
sub PrintTitle    { 'command' }
sub AssociatedIcon{ 'command' }
sub EditorProperties {
  return {
    -label=>'text',-accelerator=>'text',-background=>'color', 
    -foreground=>'color',-underline=>'int+',-command=>'callback',
    -compound=>'menu(none|bottom|center|left|right)',-bitmap=>'bitmap',
    -image=>'variable'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->command(@args);
}

1;#)
