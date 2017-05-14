package vptk_w::VPTK_Widget::Message;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat'] }
sub TkClassName   { 'Tk::Message' }
sub PrintTitle    { 'Message' }
sub AssociatedIcon{ 'message' }
sub EditorProperties {
  return {
    -anchor=>'anchor',-background=>'color',-foreground=>'color',
    -padx=>'int+',-text=>'text',-borderwidth=>'int+',-pady=>'int+',
    -relief=>'relief',-width=>'int+',-aspect=>'int+',-justify=>'justify'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  return $parent->Message(@args);
}

1;#)
