#!perl -w
#
# Tk Transaction Manager.
# Menu & Toolbar - Set of data objects.
#
# makarow, demed
#

package Tk::TM::wgMenu;
require 5.000;
use strict;
use Tk;
use Tk::TM::Common;
use Tk::TM::Lang;
use Tk::TM::DataObjSet;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.53';
@ISA = ('Tk::Frame','Tk::TM::DataObjSet');

Tk::Widget->Construct('tmMenu'); 


sub Populate {
 my ($self, $args) = @_;
 my $mw =$self->parent;

 print "Populate0(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->Tk::TM::DataObjSet::initialize();
 foreach my $opt ($self->set()) {
   if (exists($args->{$opt})) {
      $self->set($opt=>$args->{$opt});
      delete($args->{$opt})
   }
 }
 $self->ConfigSpecs(-font=>['DESCENDANTS']);
 $self->ConfigSpecs(-relief=>['CHILDREN']);

 print "Populate1(",keys(%$args),")\n" if $Tk::TM::Common::Debug;

 my $mt  =Tk::TM::Lang::txtMenu();
 my @mnu =( [$$mt[0], 'f' .substr($$mt[0],0,1)
            ,[$$mt[1],'',-accelerator=>'Shift+F2',-command=>sub{$self->Save()}]
            ,[$$mt[2],'',-accelerator=>'F5',-command=>sub{$self->Reread()}]
            ,['separator']
            ,[$$mt[3],'',-accelerator=>'Ctrl+P',-command=>sub{$self->Print()}]
            ,[$$mt[4],'',-command=>sub{$self->Export()}]
            ,[$$mt[5],'',-command=>sub{$self->Import()}]
            ,['separator']
            ,[$$mt[6],'',-accelerator=>'Alt+F4',-command=>sub{$self->toplevel->destroy}]
            ,[$$mt[7],'',-accelerator=>'Shift+F3',-command=>sub{Tk::exit}]
            ]
           ,[$$mt[8], 'e' .substr($$mt[8],0,1)
            ,[$$mt[ 9],'',-accelerator=>'Ctrl+N',-command=>sub{$self->RowNew()}]
            ,[$$mt[10],'',-accelerator=>'Ctrl+Y',-command=>sub{$self->RowDel()}]
            ,[$$mt[11],'',-command=>sub{$self->RowUndo()}]
            ,['separator']
            ,[$$mt[12],'',-accelerator=>'F4',-command=>sub{$self->FldHelp()}]
            ,['separator']
         #  ,[$$mt[13],'',-command=>sub{$mw->focusCurrent->undo}]
            ,[$$mt[14],'',-accelerator=>'Shift+Del',-command=>sub{$mw->focusCurrent->clipboardCut}]
            ,[$$mt[15],'',-accelerator=>'Ctrl+Ins',-command=>sub{$mw->focusCurrent->clipboardCopy}]
            ,[$$mt[16],'',-accelerator=>'Shift+Ins',-command=>sub{$mw->focusCurrent->clipboardPaste}]
            ,[$$mt[17],'',-accelerator=>'Ctrl+Del',-command=>sub{$mw->focusCurrent->clipboardClear}]
         #  ,[$$mt[18],'',-command=>sub{$mw->focusCurrent->selectAll}]
            ]
           ,[$$mt[19], 'a' .substr($$mt[19],0,1)]
           ,[$$mt[20], 's' .substr($$mt[20],0,1)
            ,[$$mt[21],'',-command=>sub{$self->Retrieve()}]
            ,[$$mt[22],'',-accelerator=>'F5',-command=>sub{$self->Reread()}]
            ,[$$mt[23],'',-command=>sub{$self->Clear()}]
            ,[$$mt[24],'',-command=>sub{$self->DBICnd()}]
            ,['separator']
            ,[$$mt[25],'',-accelerator=>'Ctrl+F',-command=>sub{$self->Find()}]
            ,[$$mt[26],'',-accelerator=>'Ctrl+G',-command=>sub{$self->FindNxt()}]
            ,['separator']
            ,[$$mt[27],'',-accelerator=>'Ctrl+Home',-command=>sub{$self->RowGo('top')}]
            ,[$$mt[28],'',-accelerator=>'PageUp',-command=>sub{$self->RowGo('pgup')}]
            ,[$$mt[29],'',-accelerator=>'PageDown',-command=>sub{$self->RowGo('pgdn')}]
            ,[$$mt[30],'',-accelerator=>'Ctrl+End',-command=>sub{$self->RowGo('bot')}]
            ]
           ,[$$mt[31], 'h' .substr($$mt[31],0,1)
            ,[$$mt[32],'',-accelerator=>'F1',-command=>sub{$self->Help()}]
            ,[$$mt[33],'',-command=>sub{$self->Help('about')}]
            ]);

 my %bo=(-takefocus=>0,-relief=>'groove');
 my %bf=();
 my $bc;

 if    ($self->{-mdnav}) {
       $self->{-mdmnu}='';
       $bo{-takefocus}=1;
 }
 elsif ($self->{-mdmnu}=~/bar/i) { 
       $self->{'wmBar'} =$self->MenuBarCreate(@mnu);
 }
 elsif ($self->{-mdmnu}=~/button/i) {
       $self->{'wmBar'} =$self->MenuButCreate(@mnu);
       $mt =$self->{'wmBar'}->[0];
       %bf=(-t=>$mt);
 }
 else {
       $bo{-takefocus}=1;
 }

 if ($self->{-mdtbr}) {
 if (!$self->{-mdnav}) {
    $bc =$self->{'wbSave'}      =$self->Button(-text=>'S' ,%bo,-command=>sub{$self->Save()})->form(%bf);
    $bc =$self->{'wbReread'}    =$self->Button(-text=>'<>',%bo,-command=>sub{$self->Reread()})->form(-l=>$bc,%bf);
    $bc =$self->{'wbRowNew'}    =$self->Button(-text=>'+' ,%bo,-command=>sub{$self->RowNew()})->form(-l=>$bc,-lp=>3,%bf);
    $bc =$self->{'wbRowDel'}    =$self->Button(-text=>'-' ,%bo,-command=>sub{$self->RowDel()})->form(-l=>$bc,%bf);
    if (!$self->{-mdmnu}) {
        $bc =$self->{'wbActions'}=$self->Button(-text=>'..',%bo)->form(-l=>$bc,-lp=>3,%bf);
        my $m =$bc->Menu(-type=>'normal',-tearoff=>0); my $b =$bc;
        $bc->configure(-command=>sub{$m->post($b->rootx,$b->rooty +$b->height)});
    }
    $bc =$self->{'wbQuery'}     =$self->Button(-text=>'Q' ,%bo,-command=>sub{$self->Retrieve()})->form(-l=>$bc,-lp=>3,%bf);
    $bc =$self->{'wbClear'}     =$self->Button(-text=>'C' ,%bo,-command=>sub{$self->Clear()})->form(-l=>$bc,%bf);
 }
    $bc =$self->{'wbFind'}      =$self->Button(-text=>'F' ,%bo,-command=>sub{$self->Find()})->form(%bf, $self->{-mdnav} ?() :(-l=>$bc,-lp=>2));
    $bc =$self->{'wbRowGoTop'}  =$self->Button(-text=>'<<',%bo,-command=>sub{$self->RowGo('top')})->form(-l=>$bc,%bf);
    $bc =$self->{'wbRowGoPrev'} =$self->Button(-text=>'<' ,%bo,-command=>sub{$self->RowGo('pgup')})->form(-l=>$bc,%bf);
    $bc =$self->{'wbRowGoNext'} =$self->Button(-text=>'>' ,%bo,-command=>sub{$self->RowGo('pgdn')})->form(-l=>$bc,%bf);
    $bc =$self->{'wbRowGoBot'}  =$self->Button(-text=>'>>',%bo,-command=>sub{$self->RowGo('bot')})->form(-l=>$bc,%bf);
 if (!$self->{-mdnav}) {
    $bc =$self->{'wbHelp'}      =$self->Button(-text=>'?' ,%bo,-command=>sub{$self->Help()})->form(-l=>$bc,-lp=>3,%bf);
 }
    $self->set(-wgind=>$self->Label()->form(-l=>$bc,-lp=>10,%bf));
 }
 elsif ($self->{-mdmnu}=~/button/i) {
    $self->set(-wgind=>$self->Label()->form(-l=>$self->{'wmBar'}->[4],-lp=>10));
 }

 $mw->bind('<Shift-F2>'    ,sub{$self->Save()});
 $mw->bind('<Control-s>'   ,sub{$self->Save()});
 $mw->bind('<Key-F5>'      ,sub{$self->Reread()});
 $mw->bind('<Alt-F4>'      ,sub{$self->toplevel->destroy});
 $mw->bind('<Shift-F3>'    ,sub{exit});
 $mw->bind('<Control-n>'   ,sub{$self->RowNew()});
 $mw->bind('<Control-y>'   ,sub{$self->RowDel()});
 $mw->bind('<Key-F4>'      ,sub{$self->FldHelp()});
 $mw->bind('<Control-f>'   ,sub{$self->Find()});
 $mw->bind('<Control-l>'   ,sub{$self->FindNxt()});
 $mw->bind('<Control-g>'   ,sub{$self->FindNxt()});
 $mw->bind('<Key-F1>'      ,sub{$self->Help()});

 $self->bind('<Destroy>'   ,sub{$self->destroybind() if $_[0] && $_[0] eq $self});

 $self->mdApply();
}


sub MenuBarCreate {
 my $self =shift;
 my $mw   =$self->toplevel;
 my $fnt  =($_[0] !~/^array/i ? shift : $mw->cget(-font));
    if (!$fnt) {my $mb =$mw->Menubutton(-text=>'Проба'); $fnt =$mb->cget(-font); $mb->destroy}
 my $mb   =$mw->Menu(-type=>'menubar',-tearoff=>0);
    $mw->configure(-menu=>$mb);
 my $mi   =0;

 foreach my $pd (@_) {
   my $mp =$mb->Menu(-type=>'normal', -tearoff=>0); #-font=>$fnt
   my $i0 =1; $i0 =2 if !ref($pd->[1]) && defined($pd->[1]);
   for (my $i =$i0; $i <=$#{$pd}; $i++) {
       my $me =$pd->[$i];
       my $nm =$me->[0];
       my $um =index($nm,"~"); $nm =~s/~//;
       $mp->add((!defined($me->[1]) ? ($me->[0] ||'separator') : ($me->[1] ||'command',-label=>$nm,-underline=>$um,-font=>$fnt))
               ,@$me[2..$#{$me}]);
   };
   my $nm =$pd->[0];
   my $um =index($nm,"~"); $nm =~s/~//;
   $um =0 if $um <0;
   $mb->add('cascade',-columnbreak=>1,-label=>$nm,-underline=>$um,-font=>$fnt,-menu=>$mp);
   if (!ref($pd->[1]) && defined($pd->[1])) {
      foreach my $c (split //, $pd->[1]) {
        next if $c =~/~/i;
        my $i =$mi;
        $mw->bind("<Alt-$c>", sub{$mb->postcascade($i)});
      }
   }
   $mi +=1;
 }
 $mb;
}


sub MenuButCreate {
 my $self =shift;
 my $mw   =$self->parent;
 my $fnt  =($_[0] !~/^array/i ? shift : undef);
 my $mb   =[];
 my $bc;

 foreach my $pd (@_) {
   $bc = $self->Menubutton(-text=>$pd->[0],-underline=>0,-relief=>'groove')
                 ->form($bc ? (-l=>$bc) : ());
      push(@$mb, $bc);
      $fnt = $bc->cget(-font) if !$fnt;
   my $mp =$bc->menu(-tearoff=>0,-font=>$fnt);
   my $i0 =1; $i0 =2 if !ref($pd->[1]) && defined($pd->[1]);
   for (my $i =$i0; $i <=$#{$pd}; $i++) {
       my $me =$pd->[$i];
       my $nm =$me->[0];
       my $um =index($nm,"~"); $nm =~s/~//;
       $mp->add((!defined($me->[1]) ? ($me->[0] ||'separator') : ($me->[1] ||'command',-label=>$nm,-underline=>$um,-font=>$fnt))
               ,@$me[2..$#{$me}]);
   }
   if (!ref($pd->[1]) && defined($pd->[1])) {
      foreach my $c (split //, $pd->[1]) {
        next if $c =~/~/i;
        my $b =$bc;
        $mw->bind("<Alt-$c>", sub{$b->cget(-menu)->post($b->rootx,$b->rooty +$b->height)});
      }
   }
 }
 $mb;
}


sub mdApply {
 my $self =shift;
 
 if ($self->{'wbRowGoTop'}) {                               ## Action bar buttons
    foreach my $btn ($self->children) {
      next if $btn !~/^Tk::Button/i;
      $btn->configure(-state=>'normal')
    }
    if (!$self->{-mdedt} || !scalar(@{$self->{-dos}})) {
       foreach my $nme (qw(wbSave wbRowNew wbRowDel wbClear)) {
         next if !ref($self->{$nme});
         $self->{$nme}->configure(-state=>'disabled');
       }
    }
    if (!scalar(@{$self->{-dos}})) {
       foreach my $nme (qw(wbReread wbQuery wbFind wbRowGoTop wbRowGoPrev wbRowGoNext wbRowGoBot)) {
         next if !ref($self->{$nme});
         $self->{$nme}->configure(-state=>'disabled');
       }
    }
 }
 if ($self->{-mdmnu}=~/button/i && ref($self->{'wmBar'})) { ## Menubuttons
    foreach my $btn ($self->children) {
      next if $btn !~/^Tk::Menubutton/i;
      my $mnu =$btn->cget(-menu);
      next if !$mnu || $mnu->index('last') =~/none/i;;
      for (my $i=0; $i<=$mnu->index('last'); $i++) {
          next if $mnu->type($i) =~/separator|cascade/i;
          $mnu->entryconfigure($i,-state=>'normal');
      }
    }
    if (!$self->{-mdedt} || !scalar(@{$self->{-dos}})) {
       my %opt =(-state=>'disabled');
       my $mnu =$self->{'wmBar'};
       $mnu->[0]->cget(-menu)->entryconfigure(0,%opt);
       $mnu->[0]->cget(-menu)->entryconfigure(5,%opt);
       $mnu->[1]->cget(-menu)->entryconfigure(0,%opt);
       $mnu->[1]->cget(-menu)->entryconfigure(1,%opt);
       $mnu->[1]->cget(-menu)->entryconfigure(2,%opt);
       $mnu->[1]->cget(-menu)->entryconfigure(4,%opt);
     # $mnu->[1]->cget(-menu)->entryconfigure(6,%opt);
     # $mnu->[1]->cget(-menu)->entryconfigure(8,%opt);
     # $mnu->[1]->cget(-menu)->entryconfigure(9,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(2,%opt);
       if (!scalar(@{$self->{-dos}})) {
       $mnu->[0]->cget(-menu)->entryconfigure(1,%opt);
       $mnu->[0]->cget(-menu)->entryconfigure(3,%opt);
       $mnu->[0]->cget(-menu)->entryconfigure(4,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(0,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(1,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(3,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(5,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(6,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(8,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(9,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(10,%opt);
       $mnu->[3]->cget(-menu)->entryconfigure(11,%opt);
       }
    }
 }
 elsif ($self->{-mdmnu}=~/bar/i && ref($self->{'wmBar'})) { ## Menu bar
    foreach my $mnu ($self->{'wmBar'}->children) {
      next if $mnu !~/^Tk::Menu/i || $mnu->index('last') =~/none/i;
      for (my $i=0; $i<=$mnu->index('last'); $i++) {
          next if $mnu->type($i) =~/separator|cascade/i;
          $mnu->entryconfigure($i,-state=>'normal');
      }
    }
    if (!$self->{-mdedt} || !scalar(@{$self->{-dos}})) {
       my %opt =(-state=>'disabled');
       my $mnu =$self->{'wmBar'};
       $mnu->entrycget(0,-menu)->entryconfigure(0,%opt);
       $mnu->entrycget(0,-menu)->entryconfigure(5,%opt);
       $mnu->entrycget(1,-menu)->entryconfigure(0,%opt);
       $mnu->entrycget(1,-menu)->entryconfigure(1,%opt);
       $mnu->entrycget(1,-menu)->entryconfigure(2,%opt);
       $mnu->entrycget(1,-menu)->entryconfigure(4,%opt);
     # $mnu->entrycget(1,-menu)->entryconfigure(6,%opt);
     # $mnu->entrycget(1,-menu)->entryconfigure(8,%opt);
     # $mnu->entrycget(1,-menu)->entryconfigure(9,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(2,%opt);
       if (!scalar(@{$self->{-dos}})) {
       $mnu->entrycget(0,-menu)->entryconfigure(1,%opt);
       $mnu->entrycget(0,-menu)->entryconfigure(3,%opt);
       $mnu->entrycget(0,-menu)->entryconfigure(4,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(0,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(1,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(3,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(5,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(6,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(8,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(9,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(10,%opt);
       $mnu->entrycget(3,-menu)->entryconfigure(11,%opt);
       }
    }
 }
 1;
}         


sub setActions {
 my $self =shift;
 my $mnu  = $self->{-mdmnu}
            ? ref($self->{'wmBar'})=~/^array/i
              ? $self->{'wmBar'}->[2]->cget(-menu)
              : $self->{'wmBar'}->entrycget(2,-menu)
            : $self->{'wbActions'}
              ? ($self->{'wbActions'}->children)[0]
              : return($self);
 my $fnt  ='';
 if (!$fnt) {my $mb =$self->parent->Menubutton(-text=>'Проба'); $fnt =$mb->cget(-font); $mb->destroy}

 $mnu->delete(0,'last');
 foreach my $elem (@_) {
    if (ref($elem)) {
       my $nm =$elem->[0];
       my $um =index($nm,"~"); $nm =~s/~//;
       $mnu->add((!defined($elem->[1]) ? ($elem->[0] ||'separator') : ($elem->[1] ||'command',-label=>$nm,-underline=>$um,-font=>$fnt))
               ,@$elem[2..$#{$elem}]);
    }
    elsif (!$elem || $elem =~/separator/i) {
       $mnu->add('separator');
    }
    else {
       my $nm =$elem;
       my $um =index($nm,"~"); $nm =~s/~//;
       $mnu->add('command',-label=>$nm,-underline=>$um,-font=>$fnt,-command=>sub{$self->Action($nm)});
    }
 }
 $mnu;
}
