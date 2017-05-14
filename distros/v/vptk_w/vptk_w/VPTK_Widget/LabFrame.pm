package vptk_w::VPTK_Widget::LabFrame;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'ridge',-labelside=>'acrosstop'] }
sub TkClassName   { 'Tk::LabFrame' }
sub PrintTitle    { 'LabFrame' }
sub AssociatedIcon{ 'labframe' }
sub EditorProperties {
  return {
    -foreground=>'color',-labelvariable=>'variable',
    -background=>'color',-borderwidth=>'int+',-relief=>'relief',
    -label=>'text',-width=>'int+',-height=>'int+',
    -labelside=>'menu(left|right|top|bottom|acrosstop)'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->LabFrame(@args);
}

1;#)
