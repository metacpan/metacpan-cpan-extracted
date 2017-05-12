#!perl -w
#
# Tk Transaction Manager.
# Table data widget. To use with data object.
#
# makarow, demed
#

package Tk::TM::wgTable;
require 5.000;
use strict;
use Tk;
use Tk::TM::Common;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.53';
@ISA = ('Tk::Derived','Tk::Frame');

Tk::Widget->Construct('tmTable'); 

#######################
sub Populate {
 my ($self, $args) = @_;
 my $mw =$self->parent;

 # print "********Populate/Initing...\n";
 $self->initialize();
 foreach my $opt ($self->set()) {
   if (exists($args->{$opt})) {
      $self->set($opt=>$args->{$opt});
      delete($args->{$opt});
   }
 }
 $self->configure(-borderwidth=>2,-relief=>'groove');
 $self->ConfigSpecs(-font=>['DESCENDANTS']);
 $self->ConfigSpecs(-relief=>['CHILDREN']);
 $self->ConfigSpecs(-background=>['CHILDREN']);
 $self->ConfigSpecs(-foreground=>['CHILDREN']);

 # print "********Populate/Populating...\n";
 $self->Remake();
 $self
}

#######################
sub initialize {
 my $self = shift;
 my $mw   =$self->parent;
 $self->{-do}       =undef; # transaction manager            # configurable
 $self->{-colspecs} =[];    # widgetSpec =$self->[$col]      # configurable
 $self->{-rowcount} =8;     # count of rows                  # configurable
 $self->{-wgscroll} =undef; # scrollbar
 $self->{-widgets}  =[];    # widget =$self->[$row]->[$col]
}

#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }
 if ($opt{-do} || ($self->{-do} && $opt{-widgets})) {
    # print "****bindings****\n";
    my $row =-1;
    foreach my $wgrow (@{$self->{-widgets}}) {
      $row++;
      my $col =-1;
      foreach my $wg (@$wgrow) {
        $col++;
        next if !$wg || ref($wg) eq 'Tk::Label';
        my $tv;
        $wg->configure(-textvariable=>\$tv);
        my ($row1, $col1) =($row, $col);
        $wg->bind('<Up>'          ,sub{$self->{-do}->RowGo('prev')});
        $wg->bind('<Down>'        ,sub{$self->{-do}->RowGo('next')});
        $wg->bind('<Prior>'       ,sub{$self->{-do}->RowGo('pgup')});
        $wg->bind('<Next>'        ,sub{$self->{-do}->RowGo('pgdn')});
        $wg->bind('<Control-Home>',sub{$self->{-do}->RowGo('top')});
        $wg->bind('<Control-End>' ,sub{$self->{-do}->RowGo('bot')});
        $wg->bind('<FocusIn>' ,sub{$self->{-do}->wgFldFocusIn ($wg, $col1, $row1)});
        $wg->bind('<FocusOut>',sub{$self->{-do}->wgFldFocusOut($wg, $col1, $row1)});
      # $wg->bind('<Key-F4>'  ,sub{$self->{-do}->wgFldHelper  ($wg, $col1, $row1)});
      }
    }
 }
 $self;
}

#######################
sub Remake {
 my $self =shift;

 $self->{-widgets}=[];
 foreach my $wg ($self->children) {
   $wg->destroy();
 }
 my $wga =$self;
    $wga =$self->Frame()->pack(-side=>'left');

 my $col =-1;
 foreach my $wgs (@{$self->{-colspecs}}) {
       next if !defined($wgs);
       $col++;
       my $wgn =$wgs->[!defined($wgs->[0]) || $wgs->[0] =~/^\d+$/ ? 1 : 0];
       my $wg;
       if ($wgn) {
          $wg =$wga->Label(-text, !ref($wgn) ? $wgn : @$wgn);
          $wg->grid(-column=>$col, -row=>0, -sticky=>'w');
       }
 }

 for (my $row=0; $row <$self->{-rowcount}; $row++) {
   push(@{$self->{-widgets}}, []);
   my ($col,$colp) =(-1,-1);
   foreach my $wgs (@{$self->{-colspecs}}) {
       $col++;
       if (!defined($wgs)) {$self->{-widgets}->[$row]->[$col] =undef; next}
       $colp++;
       my $wgi =1;
       $wgi++ if    !defined($wgs->[0]) || $wgs->[0] =~/^\d+$/;
       $wgi++ while !defined($wgs->[$wgi]) || $wgs->[$wgi] =~/^\d+$/;
       my $wgn =$wgs->[$wgi];
       my @wgs =$#{@$wgs} <$wgi ? () : @{$wgs}[$wgi+1 .. $#{@$wgs}];
       my $wg  =$wga->$wgn(@wgs);
       $wg->grid(-column=>$colp, -row=>$row+1, -sticky=>'w');
       $self->{-widgets}->[$row]->[$col] =$wg;
   }
 }

 $self->set(-widgets=>$self->{-widgets});
 $self->{-wgscroll} =$self->Scrollbar(-orient=>'vertical',-command=>['sbCBack'=>$self])
       ->pack(-fill=>'y',-expand=>'yes');
 $self->sbSet() if $self->{-wgscroll};

 $self
}

#######################
sub Adapt {
  my $self =shift;
  return($self) if !$self->{-do} || !$self->{-do}->{-dbfds};
  my $dd =$self->{-do}->{-dbfds};
  my $aw =$self->{-do}->{-dbfaw};
  for (my $c =0; $c <=$#{@{$self->{-widgets}->[0]}}; $c++) {
      next if !$dd->[$c] || !$dd->[$c]->{PRECISION};
      my $w =$dd->[$c]->{PRECISION}; $w =$aw if $w >$aw && $aw >1;
      for (my $r =0; $r <=$#{@{$self->{-widgets}}}; $r++) {
          next if !Exists($self->{-widgets}->[$r]->[$c]);
          eval{$self->{-widgets}->[$r]->[$c]->configure(-width=>$w)};
      }
  }
  $self
}

#######################
sub Display {
 my $self =shift;
 return $self if !$self->{-do};
 my $do  =$self->{-do};
 my $row =-1;
 my $rowadd =$do->{-dsrid} -($do->{-dsrsd} ||0);
 if ($rowadd <0) {
    $rowadd =0;
    $do->{-dsrsd} =$do->{-dsrid};
 }
 foreach my $wgrow (@{$self->{-widgets}}) {
   $row++;
   my $rowdta =$do->dsRowDta($row +$rowadd);
   my $col    =-1;
   foreach my $wg (@$wgrow) {
     $col++;
     next if !Exists($wg) || ref($wg) eq 'Tk::Label';
     eval{${$wg->cget(-textvariable)} =$rowdta->[$col]};
   }
 }
 $self->sbSet() if $self->{-wgscroll};
 $self
}

#######################
sub Focus {
 my ($self) =(shift);
 my $do  =$self->{-do};
 return if !$do;
 if (ref($do) && defined($do->{-dsrfd}) && defined($do->{-dsrsd})) {
    my $wg =$self->{-widgets}->[($do->{-dsrsd} <0 ? 0 : $do->{-dsrsd})]->[$do->{-dsrfd}];
    return $wg->focusForce() if ref($wg)
 }
 else {
    foreach my $wg (@{$self->{-widgets}->[0]}) {
       return $wg->focusForce() if ref($wg)
    }
 }
 return $self->focusForce()
}

#######################
sub sbCBack {
 if    (!$_[0]->{-do}) {}
 elsif ($_[1] eq 'scroll' && $_[3] eq 'units') {$_[0]->{-do}->RowGo($_[2] >0 ? 'next' : 'prev')}
 elsif ($_[1] eq 'scroll' && $_[3] eq 'pages') {$_[0]->{-do}->RowGo($_[2] >0 ? 'pgdn' : 'pgup')}
 elsif ($_[1] eq 'moveto') {$_[0]->{-do}->RowGo(int($_[2] *$_[0]->{-do}->dsRowCount()))}
}

#######################
sub sbSet {
 if    (!$_[0]->{-wgscroll}) {}
 elsif (!$_[0]->{-do}) {$_[0]->{-wgscroll}->set(0,1)}
 else {
   my $t =$_[0]->{-do}->{-dsrid} -$_[0]->{-do}->{-dsrsd};
   my $b =$t +$_[0]->{-rowcount} -1;
   my $c =$_[0]->{-do}->dsRowCount() -1;
      $c =1  if $c <=0;
   if ($b >$c) {
      $t =$t +$c -$b; $t =0 if $t <0;
      $c =$b
   }
   $_[0]->{-wgscroll}->set($t/$c,$b/$c);
 }
}