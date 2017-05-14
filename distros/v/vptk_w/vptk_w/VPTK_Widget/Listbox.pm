package vptk_w::VPTK_Widget::Listbox;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'sunken'] }
sub TkClassName   { 'Tk::Listbox' }
sub PrintTitle    { 'Listbox' }
sub AssociatedIcon{ 'listbox' }
sub EditorProperties {
  return {
    -highlightbackground=>'color',-highlightcolor=>'color',
    -selectbackground=>'color',-selectborderwidth=>'int+',
    -selectforeground=>'color',-listvariable=>'variable',
    -state=>'menu(normal|disabled)',
    -background=>'color',-foreground=>'color',-borderwidth=>'int+',-scrollbars=>'scrolled',
    -width=>'int+',-height=>'int+',-setgrid=>'menu(0|1)',-relief=>'relief',
    -selectmode=>'menu(single|browse|multiple|extended)'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  my $result = $parent->Listbox(@args);
  $result->insert('end', qw/item1 item2 item3/);
  return $result;
}

1;#)
