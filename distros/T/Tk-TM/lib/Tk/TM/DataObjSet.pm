#!perl -w
#
# Tk Transaction Manager.
# Set of data objects, Base Class for Menus and Action Bars.
#
# makarow, demed
#

package Tk::TM::DataObjSet;
require 5.000;
use strict;
use Tk::TM::Common;
use Tk::TM::Lang;
use Tk::TM::DataObject;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.52';

use vars qw($Current);
$Current    =undef;    # Current DataObjSet
my $Parm    ={};       # Default value for {-parm}

1;


#######################
sub new {
 my $class =shift;
 my $self ={};
 bless $self,$class;
 $Current =$self;
 $self->initialize(@_);
}


#######################
sub initialize {
 my $self =shift;
 $Current =$self;
 print "initialize($self, ",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->{-dos}   =\@Tk::TM::DataObject::Available; # set of data objects # configurable
 $self->{-wgind} =undef;                           # indicator widget    # configurable
 $self->{-mdmnu} ='bar'; # || 'button' || ''       # type of menu        # configurable
 $self->{-mdtbr} =1;     # || false                # type of toolbar     # configurable
 $self->{-mdedt} =1;                               # mode edit           # configurable
 $self->{-mdnav} =0;                               # mode navigate only  # configurable
 $self->{-mdscr} =undef;                           # one-screen dos?     # configurable
 $self->{-about} =$Tk::TM::Common::About;          # about text or code  # configurable
 $self->{-help}  =$Tk::TM::Common::Help;           # help text or code   # configurable
 $self->{-parm}  =$Parm;                           # programmer`s parms  # configurable
 $self->set(@_);
 $self;
}


#######################
sub destroybind {
 my $self =$_[0];
 print "destroybind(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 foreach my $do (@{$self->{-dos}}) {
    $do->destroy() if ref($do);
 }
 $self->{-dos}   =undef;
 $self->{-wgind} =undef;
 $self->{-about} =undef;
 $self->{-help}  =undef;
 $self->{-parm}  =undef;

}


#######################
sub DESTROY {
 my $self =$_[0];
 print "DESTROY(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
}


#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 $Current =$self;
 my $md = exists($opt{-mdedt});
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }
 if ($self->{-wgind} && ($opt{-dos} || $opt{-wgind})) {
    foreach my $do (@{$self->{-dos}}) {
      $do->set(-wgind=>$self->{-wgind})
    }
 }
 if ($opt{-dos} && @{$opt{-dos}}) {
    foreach my $do (@{$self->{-dos}}) {
       $do->set(-wgmnu=>$self);
    }
    my $do =$self->DataObject();
    if (ref($do)) {$self->{-mdedt} =$do->set(-mdedt); $md =1};
 }
 $self->mdApply() if $md;
 $self;
}

#######################
sub setpush {
 my ($self, $opt) =(shift,shift);
 $Current =$self;
 if    (ref($self->{$opt}) eq 'ARRAY') {
       push(@{$self->{$opt}}, @_)
 }
 elsif (ref($self->{$opt}) eq 'HASH') {
       my %v =@_;
       foreach my $k (keys(%v)) { $self->{$opt}->{$k} =$v{$k} }
 }
}


#######################
#######################


sub Help {
 my $self  =shift;
 my $opt   =$_[0] ||'';
 my $title ='';
 my $abou0 =["Tk Transaction Manager","Andrew V Makarow <makarow\@mail.com>, Denis E Medveduyk <demed\@mail.com>"];
 my $about =undef;
 my $help  =undef;
 my $ehlp  =undef;
 my $mw    =$self->toplevel;
 $opt =$opt =~/about/i ? '-about' : '-help';

 if    (!$self->{-about})             {}
 elsif ($self->{-about} =~/array\(/i) {$about={$self->{-about}}}
 elsif ($self->{-about} =~/code\(/i)  {$about=&{$self->{-about}}}
 else                                 {$about=[$self->{-about}]}

 if ($opt =~/about/i) {
    return
    $mw->messageBox('-icon'=>'info'
                   ,-type=>'Ok'
                   ,-title=>Tk::TM::Lang::txtMsg('About application')
                   ,-message=>join("\n",(ref($about) ? @$about : @$abou0))
                   );
 }

 $self->CursorWait;

 if    (!$self->{-about})            {$about=['No text is available via {-about}']}
 if    (!$self->{-help})             {$help =['No text is available via {-help}']}
 elsif ($self->{-help} =~/array\(/i) {$help ={$self->{-help}}}
 elsif ($self->{-help} =~/code\(/i)  {$help =&{$self->{-help}}}
 else                                {$help =[$self->{-help}]}
 $ehlp =Tk::TM::Lang::txtHelp();

 my $dlg =new Tk::MainWindow(-title=>Tk::TM::Lang::txtMsg('Help')); $dlg->grab();
 my $txt;
 my $bf  =$dlg->Frame()->pack(-anchor=>'w');
 my $pb0 =$bf ->Button(-text=>Tk::TM::Lang::txtMsg('Operation')
             ,-command=>sub{$txt->configure(-state=>'normal');
                            $txt->delete('0.0','end'); 
                            $txt->insert('0.0',join("\n",@$ehlp));
                            $txt->configure(-state=>'disabled')})->pack(-side=>'left');
 my $pb1 =$bf ->Button(-text=>Tk::TM::Lang::txtMsg('Help')
             ,-command=>sub{$txt->configure(-state=>'normal');
                            $txt->delete('0.0','end'); 
                            $txt->insert('0.0',join("\n",@$help));
                            $txt->configure(-state=>'disabled')})->pack(-side=>'left');
 my $pb2 =$bf ->Button(-text=>Tk::TM::Lang::txtMsg('About application')
             ,-command=>sub{$txt->configure(-state=>'normal');
                            $txt->delete('0.0','end'); 
                            $txt->insert('0.0',join("\n",@$about));
                            $txt->configure(-state=>'disabled')})->pack(-side=>'left');
 my $pb3 =$bf ->Button(-text=>Tk::TM::Lang::txtMsg('Tk::TM')
             ,-command=>sub{$txt->configure(-state=>'normal');
                            $txt->delete('0.0','end'); 
                            $txt->insert('0.0',join("\n",@$abou0) ."\n" .$self->HelpDebug);
                            $txt->configure(-state=>'disabled')})->pack(-side=>'left');
 my $pb4 =$bf ->Button(-text=>Tk::TM::Lang::txtMsg('Close')
             ,-command=>sub{$dlg->destroy})->pack(-side=>'left');
 $txt =$dlg->Scrolled('Text',-font=>$pb0->cget(-font),-height=>20,-width=>90,-wrap=>'none',-scrollbars=>'se')
           ->pack(-side=>'top',-expand=>'yes',-fill=>'both');
 $dlg->bind('<Key-Escape>',sub{$pb4->invoke});
 $pb0->invoke;
 $pb0->focusForce;
 $dlg;
}


sub HelpDebug {
 my $self =shift;
 my $do =$self->DataObject;
 my $ret='';
 my $val;

 $ret =$ret ."\n*** Common paramters ***\n";
 $val =$self->set(-parm);
 foreach my $k (sort(keys(%$val))) {
   $ret =$ret ."$k\t=>" .(!defined($val->{$k}) ? 'null' : $val->{$k}) ."\n"
 }

 return($ret) if !$do;

 $ret =$ret ."\n*** Paramters of current data object ***\n";
 $val =$do->set(-parm);
 foreach my $k (sort(keys(%$val))) {
   $ret =$ret ."$k\t=>" .(!defined($val->{$k}) ? 'null' : $val->{$k}) ."\n"
 }

 $ret =$ret ."\n*** Fields in current data object ***\n";
 $val =$do->set(-dbfds);
 foreach my $f (@$val) {
   foreach my $k (sort(keys(%$f))) {
     $ret =$ret ."$k\t=>" .(!defined($f->{$k}) ? 'null' : $f->{$k}) .";\t";
   }
   $ret =$ret ."\n";
 }

 $ret =$ret ."\n*** Structure of current data object ***\n";
 foreach my $k (sort(keys(%$do))) {
   next if $k =~/dsdta|dsrd0|parm|parmc/i;
   if    (ref($do->{$k}) !~/array|hash/i) {$ret =$ret ."$k\t=>" .(!defined($do->{$k}) ? 'null' : $do->{$k}) .";\n";}
   elsif (ref($do->{$k}) eq 'ARRAY') {
         $ret =$ret ."$k\t=>[";
         foreach my $e (@{$do->{$k}}) {
           $ret =$ret .(!defined($e) ? 'null' : $e) ."; ";
         }
         $ret =$ret ."];\n";
   }
   elsif (ref($do->{$k}) eq 'HASH') {
         $ret =$ret ."$k\t=>{";
         foreach my $e (sort(keys(%{$do->{$k}}))) {
           $ret =$ret ."$e=>" .(!defined($do->{$k}->{$e}) ? 'null' : $do->{$k}->{$e}) ."; ";
         }
         $ret =$ret ."};\n";
   }
 }
 $ret
}


sub mdApply {
 my $self =shift
}


sub CursorWait {
 my $curs =$_[0]->cget(-cursor);
 $_[0]->toplevel->configure(-cursor=>$Tk::TM::Common::CursorWait);
 $_[0]->toplevel->update;
 $_[0]->toplevel->configure(-cursor=>$curs);
}


#######################
#######################


sub DataObject {          # Current data object
 my $self =shift;
 foreach my $do (@{$self->{-dos}}) {
    return $do if $do eq $Tk::TM::DataObject::Current;
 }
 $Tk::TM::DataObject::Current =${$self->{-dos}}[0];
}


sub doCurrent {           # Do for current data object
 my ($self, $op) =(shift, shift);
 $self->CursorWait;
 my $do =$self->DataObject();
 return(0) if !ref($do);
 &{$op}($do, @_);
}


sub doAll {               # Do for all data objects
 my ($self, $op) =(shift, shift);
 $self->CursorWait;
 my $do =($self->{-mdscr} ? $self->DataObject() : undef);
 return(0) if $self->{-mdscr} && !ref($do);
 my $sc =($self->{-mdscr} ? $do->set(-wgscr) : undef);
 foreach my $do (@{$self->{-dos}}) {
   next if $self->{-mdscr} && $sc ne $do->set(-wgscr);
   &{$op}($do, @_) || return(0);
 }
 1;
}


#######################
#######################



sub Action {shift->doCurrent(sub{shift->Action(@_)},@_)}

sub Clear {shift->doAll(sub{shift->Clear(@_)},@_)}

sub DBICnd {shift->doCurrent(sub{shift->DBICnd(@_)},@_)}

sub Export {shift->doCurrent(sub{shift->Export(@_)},@_)}

sub Find {shift->doCurrent(sub{shift->Find(@_)},@_)}

sub FindNxt {shift->doCurrent(sub{shift->FindNxt(@_)},@_)}

sub FldHelp {shift->doCurrent(sub{shift->wgFldHelper(@_)},@_)}

sub Import {shift->doCurrent(sub{shift->Import(@_)},@_)}

sub Print {my $self =shift; $self->doAll(sub{shift->Stop(@_)},@_) && $self->doCurrent(sub{shift->Print(@_)},@_)}

sub Reread {shift->doAll(sub{shift->Retrieve(@_)},'#reread')}

sub Retrieve {shift->doAll(sub{shift->Retrieve(@_)},@_)}

sub RowDel {shift->doCurrent(sub{shift->RowDel(@_)},@_)}

sub RowGo {shift->doCurrent(sub{shift->RowGo(@_)},@_)}

sub RowNew {shift->doCurrent(sub{shift->RowNew(@_)},@_)}

sub RowUndo {shift->doCurrent(sub{shift->RowUndo(@_)},@_)}

sub Save {shift->doAll(sub{shift->Save(@_)},@_)}

sub Stop {shift->doAll(sub{shift->Stop(@_)},@_)}
