package vptk_w::VPTK_Widget::LabEntry;

use strict;
use base qw(vptk_w::VPTK_Widget);

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'sunken',-labelPack=>"[-side=>'left',-anchor=>'n']"] }
sub TkClassName   { 'Tk::LabEntry' }
sub PrintTitle    { 'LabEntry' }
sub AssociatedIcon{ 'labentry' }
sub EditorProperties {
  return {
    -background=>'color',-foreground=>'color',-borderwidth=>'int+',
    -width=>'int+',-justify=>'justify',-labelPack=>'lpack',
    -validate=>'menu(none|focus|focusin|focusout|key|all)',
    -validatecommand=>'callback',
    -textvariable=>'variable',-relief=>'relief',-label=>'text',-padx=>'int+',
    -pady=>'int+',-width=>'int+',-state=>'menu(normal|disabled|readonly)'
  }
}

sub JustDraw {
  my ($this,$parent,@args) = @_;
  my (%args)=@args;
  my $lpack= delete $args{'-labelPack'};
  delete $args{'-textvariable'};
  $lpack=~s/[\[\]']//g;
  return $parent->LabEntry(%args,-labelPack=>[split(/\s*(?:,|=>)\s*/,$lpack)]);
}

1;#)
