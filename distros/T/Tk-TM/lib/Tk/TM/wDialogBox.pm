#!perl -w
#
# Tk Transaction Manager.
# Dialog box, developed Tk::DialogBox
#
# makarow, demed
#
package Tk::TM::wDialogBox;
require 5.000;
use strict;
use Tk;
use Tk::DialogBox;
use Tk::TM::Lang;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = ('Tk::DialogBox');

Tk::Widget->Construct('tmDialogBox');

sub Show {
 my $self =shift;
 my $wgf;
 my @btn;
 my $besc;
 foreach my $area ($self->children) {
    if    ($area->name =~/top/i) {
          my @wgs =$area->children;
          $wgf =$wgs[0]
    }
    elsif ($area->name =~/bottom/i) {
          my @wgs =$area->children;
          @btn =map {$_->cget(-text)} @wgs;
          $besc=$wgs[$#wgs]
    }
 }
 $self->bind('<FocusIn>',sub{$wgf->focus; $self->bind('<FocusIn>',undef)});
 $self->bind('<Key-Escape>',sub{$besc->invoke});
 $self->protocol("WM_DELETE_WINDOW" => undef);

 my $txt =$self->Tk::DialogBox::Show(@_) ||'';
 for (my $i =@[; $i <=$#btn; $i++) {
   return($i) if $btn[$i] eq $txt;
 }
 -1;
}
