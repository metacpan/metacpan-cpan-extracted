package vptk_w::VPTK_Widget::ProgressBar;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat'] }
sub TkClassName   { 'Tk::ProgressBar' }
sub PrintTitle    { 'ProgressBar' }
sub AssociatedIcon{ 'scale' }
sub EditorProperties {
  return {
    -borderwidth=>'int+',-padx=>'int+',-pady=>'int+',-relief=>'relief',
    -anchor=>'menu(n|s|w|e)',-blocks=>'int+',-from=>'float',-gap=>'int+',
    '-length'=>'int+',-resolution=>'float',-to=>'float',-variable=>'variable',
    -value=>'float',-width=>'int+',-troughcolor=>'color'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->ProgressBar(@args);
}

1;#)
