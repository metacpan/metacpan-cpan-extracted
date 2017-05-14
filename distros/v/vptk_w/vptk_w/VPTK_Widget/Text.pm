package vptk_w::VPTK_Widget::Text;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'sunken'] }
sub TkClassName   { 'Tk::Text' }
sub PrintTitle    { 'Text' }
sub AssociatedIcon{ 'text' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-borderwidth=>'int+',
    -takefocus=>'menu(0|1)',-state=>'menu(normal|disabled)',
    -relief=>'relief',-scrollbars=>'scrolled',
    -wrap=>'menu(none|char|word)',-setgrid=>'menu(0|1)',-width=>'int+',
    -height=>'int+',-padx=>'int+',-pady=>'int+'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Text(@args);
}

1;#)
