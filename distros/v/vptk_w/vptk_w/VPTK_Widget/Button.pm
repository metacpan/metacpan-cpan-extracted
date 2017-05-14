package vptk_w::VPTK_Widget::Button;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [] }
sub TkClassName   { 'Tk::Button' }
sub PrintTitle    { 'Button' }
sub AssociatedIcon{ 'button' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-borderwidth=>'int+',-relief=>'relief',
    -activebackground=>'color',-highlightthickness=>'int+',-takefocus=>'menu(0|1)',
    -activeforeground=>'color',-disabledforeground=>'color',-highlightbackground=>'color',
    -wraplength=>'int+',-highlightcolor=>'color',-overrelief=>'relief',
    -command=>'callback',-text=>'text',-width=>'int+',-height=>'int+',-anchor=>'anchor',
    -padx=>'int+',-pady=>'int+',-textvariable=>'variable',-underline=>'int+',
    -bitmap=>'bitmap',-image=>'variable',-state=>'menu(normal|active|disabled)',
    -compound=>'menu(none|bottom|center|left|right)'
  }
}

sub JustDraw {
  my ($this,$parent,%args) = @_;
  delete $args{'-image'};
  return $parent->Button(%args);
}

1;#)
