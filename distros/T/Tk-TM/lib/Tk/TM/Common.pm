#!perl -w
#
# Tk Transaction Manager.
# Common.
#
# makarow, demed
#

package Tk::TM::Common;
require 5.000;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.53';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(DBILogin);

use vars qw($Debug $Edit $Echo $DBH $Help $About $CursorWait %SQLType);
$Debug      =0;       # debug level or switch
$Echo       =1;       # echo printing
$Edit       =1;       # default edit mode enabled
$DBH        =undef;   # DBI database Handle
$Help       =undef;   # 'Help' array ref or sub ref
$About      =undef;   # 'About' array ref or sub ref
$CursorWait ='watch'; # Wait cursor type
%SQLType    =         # SQL data type names
             (0=>'unknown',1=>'CHAR'
             ,2=>'NUMERIC',3=>'DECIMAL',4=>'INTEGER',5=>'SMALLINT',6=>'FLOAT',7=>'REAL',8=>'DOUBLE'
             ,9=>'DATETIME',12=>'VARCHAR'
             ,91=>'DATE',92=>'TIME',93=>'TIMESTAMP');

sub DBILogin {
 my $scr =(ref($_[0]) ? shift : undef);
 my ($dsn, $usr, $psw, $opt, $dbopt) =@_;
    $opt  =$opt   ||'';
    $dbopt=$dbopt || {};
 my $dbh;
 eval('use DBI');
 my $dlg   =$scr ? (ref($scr) eq 'ARRAY' ? $scr->[0] : $scr) 
                 : new Tk::MainWindow(-title=>Tk::TM::Lang::txtMsg('Login')); 
 my $rspfd;
 my $dsnlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('Database'))
                ->grid(-row=>0, -column=>0, -sticky=>'w');
 my $dsnfd =$dlg->Entry(-textvariable=>\$dsn)
                ->grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'we');
            $dsnfd->configure(-state=>'disabled', -bg=>$dlg->cget(-bg)) if $opt !~/dsn|edit/i;
 my $usrlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('User'))
                ->grid(-row=>1, -column=>0, -sticky=>'w');
 my $usrfd =$dlg->Entry(-textvariable=>\$usr)
                ->grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'we');
 my $pswlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('Password'))
                ->grid(-row=>2, -column=>0, -sticky=>'w');
 my $pswfd =$dlg->Entry(-textvariable=>\$psw,-show=>'*')
                ->grid(-row=>2, -column=>1, -columnspan=>2, -sticky=>'we');
 my $btnok =$dlg->Button(-text=>Tk::TM::Lang::txtMsg($scr ? 'Login' : 'Ok')
                        ,-command=>
                           sub{$rspfd->configure(-text=>'Connecting...');
                               my $curs =$dlg->cget(-cursor);
                               $dlg->configure(-cursor=>$CursorWait);
                               $dlg->update;
                               $dlg->configure(-cursor=>$curs);
                               if (eval {$dbh =DBI->connect($dsn,$usr,$psw,$dbopt)}) 
                                    {$rspfd->configure(-text=>'Connected'); 
                                     eval {$_[0] =$dsn};
                                     eval {$_[1] =$usr};
                                     eval {$_[2] =$psw};
                                     $DBH =$dbh if $scr || $opt !~/return/i;
                                     $dlg->destroy if !$scr}
                               else {$rspfd->configure(-text=>$DBI::errstr)}
                              }
                        )
                ->grid(-row=>3, -column=>($scr ? 2 : 1), -sticky=>'we');
 my $btncn =$dlg->Button(-text=>Tk::TM::Lang::txtMsg('Cancel')
                        ,-command=>sub{if(!$scr && $opt =~/return/i) {$dlg->destroy} else {Tk::exit}})
                ->grid(-row=>3, -column=>2, -sticky=>'we') if !$scr;
    $rspfd =ref($scr) eq 'ARRAY' ? $scr->[1]
           :$dlg->Label(-anchor=>'w',-relief=>'sunken')
                ->grid(-row=>4, -column=>0, -columnspan=>3, -sticky=>'we');
 $dsnfd->bind('<Key-Return>',sub{$btnok->invoke});
 $usrfd->bind('<Key-Return>',sub{$btnok->invoke});
 $pswfd->bind('<Key-Return>',sub{$btnok->invoke});
 if (!$scr) {
  # $dlg->bind('<Key-Return>',sub{$btnok->invoke});
    $dlg->bind('<Key-Escape>',sub{$btncn->invoke});
    if ($opt =~/center/i) {
       $dlg->update;
       $dlg->geometry('+'.int(($dlg->screenwidth() -$dlg->width())/2.2) 
                     .'+'.int(($dlg->screenheight() -$dlg->height())/2.2));
    }
    $dlg->grab;
    $dlg->focusForce;
    $usrfd->focusForce;
    Tk::MainLoop();
 }
 else {
    $usrfd->focusForce;
 }
 $dbh;
}