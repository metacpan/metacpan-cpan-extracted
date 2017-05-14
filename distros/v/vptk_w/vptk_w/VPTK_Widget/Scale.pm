package vptk_w::VPTK_Widget::Scale;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat'] }
sub TkClassName   { 'Tk::Scale' }
sub PrintTitle    { 'Scale' }
sub AssociatedIcon{ 'scale' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-label=>'text',-relief=>'relief',
    -borderwidth=>'int+',-bigincrement=>'int+',-digits=>'int+',-from=>'float',
    '-length'=>'int+',-resolution=>'float',-orient => 'menu(vertical|horizontal)',
    -sliderlength=>'int+',-to=>'float',-width=>'int+',-showvalue=>'menu(1|0)',
    -variable=>'variable',-state=>'menu(normal|active|disabled)',-command=>'callback',
    -tickinterval=>'int+',-troughcolor=>'color'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Scale(@args);
}

1;#)
