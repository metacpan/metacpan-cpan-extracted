#!perl -w
#
# Tk Transaction Manager.
# Application window.
#
# makarow, demed
#

use Tk::TM::Lib;

package Tk::TM::wApp;
require 5.000;
use strict;
use Tk::Tree;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.53';
@ISA = ('Tk::MainWindow');
@EXPORT_OK = qw(DBILogin);

my $PathLast ='0';
my $PathOpen =undef;

1;


#######################
sub new {
 my $class=shift;
 my $self =new Tk::MainWindow(@_);
 bless $self,$class;
 $self->initialize(@_);

}


#######################
sub initialize {
 my $self = shift;

 my $tmp =$self->Menubutton();
 my $fnt =$tmp->cget(-font);
          $tmp->destroy;

 $self->{-wgmnu} =$self->tmMenu()->pack(-fill=>'x');
 $self->{-wgmnu}->set(-dos=>[]);
 my $area =$self->Frame()->pack(-expand=>'yes',-fill=>'both');

 $self->{-wgnav} =$area->Scrolled('Tree',-scrollbars=>'se',-font=>$fnt
                                 ,-itemtype=>'text'
                                 ,-command=>sub{$self->ScrOpen(@_)}
                               # ,-cursor=>'hand2'
                                 )->pack(-fill=>'y',-side=>'left');
 $self->{-wgscr} =$area->Frame(-borderwidth=>2,-relief=>'groove')->pack(-expand=>'yes',-fill=>'both');
 $self->{-wgmnu}->set(-wgind=>$self->Label(-anchor=>'w',-relief=>'sunken')->pack(-expand=>'yes',-fill=>'x'));
 $self->{-title} =$self->cget(-title);
 $self->{-mdnav} ='treee';
 $self->{-parm}  ={}; $self->{-wgmnu}->set(-parm => $self->{-parm});

 $self->ConfigSpecs(-font=>['DESCENDANTS']);
 $self->ConfigSpecs(-relief=>['CHILDREN']);
 $self->ConfigSpecs(-background=>['CHILDREN']);
 $self->ConfigSpecs(-foreground=>['CHILDREN']);

 $self->bind('<Key-F6>'  ,sub{map {$_->focusForce() if /tree/i} $self->{-wgnav}->children()});
 $self->bind('<Shift-F6>',sub{map {$_->focusForce() if /tree/i} $self->{-wgnav}->children()});
 $self->{-wgnav}->bind('<Key-F6>'  ,sub{$self->{-wgnav}->focusNext()});
 $self->{-wgnav}->bind('<Shift-F6>',sub{$self->{-wgnav}->focusPrev()});

 $self->bind('<Destroy>',sub{$self->destroybind() if $_[0] && $_[0] eq $self});

 $self;
}

#######################
sub destroybind {
 my $self =$_[0];
 print "destroybind(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my $pth0 =$PathOpen; return if !$pth0;
 my $dta0 =(defined($pth0) ? $self->{-wgnav}->info('data',$pth0) : undef);
 ref($dta0->{-cbcmd}) && $self->Try($dta0->{-cbcmd},$dta0,'stop','',undef);
}

#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }
 $self;
}


#######################
sub setscr {
 my ($self, $op, $lbl, $sub, $parm, $opt) =@_;
 if (!defined($op) ||$op eq '') {
    $PathLast =$PathLast =~/^(.*)\.([^\.]+)$/ ? "$1." .($2 +1) : $PathLast +1
 }
 elsif ($op eq '+') {
    eval {$self->{-wgnav}->setmode($PathLast,'open'); $self->{-wgnav}->open($PathLast)};
    $PathLast =$PathLast .'.0'
 }
 elsif ($op =~/^\d/) {
    my @a =split(/\./, $PathLast); 
    eval {$self->{-wgnav}->setmode($PathLast,'open'); $self->{-wgnav}->open($PathLast)} 
         if $#a <$op;
    $a[$op] +=1; 
    $PathLast =join('.',@a[0..$op])
 }
 if ($lbl =~/^Login$/ && !ref($sub)) {
     $lbl =Tk::TM::Lang::txtMsg($lbl);
     $sub =\&DBILogin;
 }
 $opt ={} if !defined($opt);
 $opt->{-cbcmd}  =$sub;
 $opt->{-cbnme}  =$sub;
 $opt->{-label}  =$lbl;
 $opt->{-title}  ='';
 $opt->{-parm}   =(ref($parm) ? $parm : {});
 $opt->{-parmc}  =$self->{-parm}; # common to app parameters
 $opt->{-dos}    =undef;
 $opt->{-do}     =undef;          # 1-st data object, autoset
 #     {-reread} =undef;          # reread master always if not current
 $opt->{-rereadc}=undef;          # reread master toggle, autoclear
 $opt->{-wgapp}  =$self;
 $opt->{-wgmnu}  =$self->{-wgmnu};
 $opt->{-wgscr}  =$self->{-wgscr};

 $self->{-wgnav}->add($PathLast,-text=>$lbl,-data=>$opt);
}

#######################
sub Try {
 my ($self,$sub) =(shift,shift);
 my $ret =ref($sub) eq 'CODE' ? eval {&{$sub}(@_)} : $sub;
 print "Try(",join(',',map {defined($_) ? $_ : 'null'} @_),")->",defined($ret) ? $ret : 'null',"\n" if $Tk::TM::Common::Debug;
 $self->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error')
                  ,-message=> $@) if $@;
 $ret
}

#######################
sub ScrOpen {
 print "ScrOpen(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my ($self, $pth1) =@_;
 my $dta1 =$self->{-wgnav}->info('data',$pth1);
 my $pthM =($pth1 =~/^(.*)\.([^\.]+)$/ ? $1 : undef);
 my $dtaM =(defined($pthM) ? $self->{-wgnav}->info('data',$pthM) : undef);
 my $pth0 =$PathOpen;
 my $dta0 =(defined($pth0) ? $self->{-wgnav}->info('data',$pth0) : undef);

 if (!defined($dta1->{-cbnme})) {return($pth0)}         # grouping only

 if (defined($pth0) && $pth0 eq $pth1 ) {return($pth0)} # the same screen

 if (defined($pthM) && !defined($dtaM->{-cbnme})) {$pthM =$dtaM =undef}

 if ($self->{-mdnav} =~/tree/i && defined($pthM) && defined($dtaM->{-cbnme})
    && !ref($dtaM->{-dos})) {return($pth0)}

 if ($self->{-mdnav} =~/treee/i && defined($pthM) && defined($dtaM->{-cbnme})
    && substr($pth0 ||'',0,length($pthM)) ne $pthM) {return($pth0)}

 if (defined($pth0)) {
    $dta0->{-do} =ref($dta0->{-dos}) ? $dta0->{-dos}->[0] : undef;
    $self->{-wgmnu}->Stop('#save#force');
    my $rstp =ref($dta0->{-cbcmd}) ? $self->Try($dta0->{-cbcmd},$dta0,'stop','',$dta1) : 1;
    if (!$rstp && $self->{-mdnav} =~/tree/i
       && defined($pthM) && defined($pth0) && $pth0 eq $pthM) {
       return($pth0)
    }
    $self->{-wgmnu}->doAll(sub{shift->Sleep('#wgs#dta')});
 }
 foreach my $w ($self->{-wgscr}->children) {$w->destroy}

 if ($self->{-mdnav} =~/tree/i
    && defined($pthM) && defined($pth0) && $pth0 ne $pthM) {
    if ($dtaM->{-reread} || $dtaM->{-rereadc}) { # reread master
       $dtaM->{-rereadc} =undef;
       $self->{-wgmnu}->set(-dos=>($dtaM->{-dos} ? $dtaM->{-dos} : []));
       $self->{-wgmnu}->Reread();
       $self->{-wgmnu}->doAll(sub{shift->Sleep('#dta')})
    }
    $dta0 =$dtaM;
 }

 $self->{-wgmnu}->set(-dos=>(ref($dta1->{-dos}) ? $dta1->{-dos} : []));
 $self->configure(-title=>(($dta1->{-title} ne '' ? $dta1->{-title} .' - ' : '') .$dta1->{-label} .' - ' .$self->{-title}));
 if (!ref($dta1->{-cbcmd})) {
    foreach my $d (($0 =~/^(.+)[\\\/][^\\\/]+$/ ? "$1" : "."), @INC) {
       next if !-f "$d/" .$dta1->{-cbnme};
       $self->Try(sub{$dta1->{-cbcmd} =do("$d/" .$dta1->{-cbnme}) });
       last;
    }
 }
 if (ref($dta1->{-cbcmd})) {
    $self->Try($dta1->{-cbcmd},$dta1,'start','',$dta0);
    $dta1->{-do} =ref($dta1->{-dos}) ? $dta1->{-dos}->[0] : undef;
  # print join(',',$self->{-wgscr}->children()),"\n";
 }

 $self->{-wgmnu}->set(-dos=>(ref($dta1->{-dos}) ? $dta1->{-dos} : []));
 $self->configure(-title=>(($dta1->{-title} ne '' ? $dta1->{-title} .' - ' : '') .$dta1->{-label} .' - ' .$self->{-title}));
 $PathOpen =$pth1
}


#######################
sub Start {
 my $self  =shift;
 my @chld  =$self->{-wgnav}->info('children');
 $PathOpen =$chld[0];
 my $dta   =$self->{-wgnav}->info('data',$PathOpen);
 $self->Try($dta->{-cbcmd},$dta,'start','');
 $dta->{-do} =ref($dta->{-dos}) ? $dta->{-dos}->[0] : undef;
 $self->{-wgmnu}->set(-dos=>(ref($dta->{-dos}) ? $dta->{-dos} : []));
 $self->configure(-title=>(($dta->{-title} ne '' ? $dta->{-title} .' - ' : '') .$dta->{-label} .' - ' .$self->{-title}));
}


#######################
sub DBILogin {
 print "DBILogin(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my ($self, $cmd) =@_;
 return(1) if $cmd !~/start/;
 Tk::TM::Common::DBILogin([$self->{-wgscr}, $self->{-wgmnu}->set(-wgind)]
                         ,$self->{-parm}->{-dsn}
                         ,$self->{-parm}->{-usr}
                         ,$self->{-parm}->{-psw}
                         ,ref($self->{-parm}) ? '#' .join('#',keys(%{$self->{-parm}})): $self->{-parm}
                         ,$self->{-parm}->{-dbopt}
                         );
 $self->{-dos} =[];
}