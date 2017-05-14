package vptk_w::VPTK_Widget::Radiobutton;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat',-indicatoron=>1] }
sub TkClassName   { 'Tk::Radiobutton' }
sub PrintTitle    { 'Radiobutton' }
sub AssociatedIcon{ 'radiobutton' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-width=>'int+',
    -justify=>'justify',-padx=>'int+',-pady=>'int+',-value=>'text',-command=>'callback',
    -relief=>'relief',-text=>'text',-underline=>'int+',-variable=>'variable',
    -anchor=>'anchor',-textvariable=>'variable',-command=>'callback',-selectcolor=>'color',
    -indicatoron=>'menu(0|1)',-state=>'menu(normal|active|disabled)'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Radiobutton(@args);
}

1;#)
