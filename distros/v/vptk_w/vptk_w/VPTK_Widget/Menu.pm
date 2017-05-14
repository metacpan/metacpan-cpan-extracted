package vptk_w::VPTK_Widget::Menu;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 0 }
sub DefaultParams { [-tearoff=>0] }
sub TkClassName   { 'Tk::Menu' }
sub PrintTitle    { 'Menu' }
sub AssociatedIcon{ 'menu' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-tearoff=>'menu(0|1)',
    -relief=>'relief',-borderwidth=>'int+',-postcommand=>'callback',
    -menuitems=>'variable'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  my $root_menu=$parent;
  # For cascade-based Menu use root menu widget in place of $parent:
  if(ref($parent) =~ /::Cascade/) {
    $root_menu = $parent->parentMenu->parent;
  }
  my $result = $root_menu->Menu(@args);
  # If the intended parent is a MainWindow (or Toplevel), we cannot
  # actually connect it, here, because the preview frame is just a frame.
  ## TBD: Create a Toplevel to use for previewing a menubar.
  $parent->configure(-menu=>$result) unless (ref($parent) =~ /::Frame/);
  return $result;
}

1;#)
