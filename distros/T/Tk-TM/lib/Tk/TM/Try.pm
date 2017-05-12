#!perl -w
#
# Tk Transaction Manager.
# Try/Catch and Transaction functions.
#
# makarow, demed
#

package Tk::TM::Try;
require 5.000;
require Exporter;
use     Carp;
use     Tk::TM::Common;
use     Tk::TM::DataObject;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.50';
@ISA = qw(Exporter);
@EXPORT = qw(Try(@) TryDBI(@) TryHdr);

use vars qw($ErrorDie $Error);
$ErrorDie   =0;   # die on errors: $Tk::TM::Try::ErrorDie=1
$Error      ='';  # error result


############################################
sub Try (@) {
 my $ret;
 local ($TrySubject, $TryStage) =('','');
 { local $ErrorDie =1;
   $ret = @_ >1 && ref($_[0]) eq 'CODE' ? eval {&{$_[0]}} : $_[0];
 }
 if   (!$@) {$ret} 
 else {
   my $err =$@ =$Error =$TrySubject .($TryStage eq '' ? '' : ": $TryStage:\n") .$@;
   $ret =ref($_[$#_]) eq 'CODE' ? &{$_[$#_]}() : $_[$#_]; 
   $@ ="$err\n$@" unless $@ eq $err;
   if ($ErrorDie) {die($err)}
   elsif ($Tk::TM::Common::Echo && ref($_[$#_]) ne 'CODE') {warn("Error: $err")}
   $ret
 }
}


############################################
sub TryDBI (@) {
 my $dbh =ref($_[0]) ne 'CODE' 
         ? shift 
         : ($Tk::TM::DataObject::Current ? $Tk::TM::DataObject::Current->{-dbh} : undef)
         || $Tk::TM::Common::DBH;
 my $ret;
 local ($TrySubject, $TryStage) =('','');
 eval  {$dbh->{AutoCommit} =0};
 eval  {local $ErrorDie =1;
        local $dbh->{RaiseError} =1;
        $ret =&{$_[0]};
        $dbh->commit;
       };
 if   (!$@) {
      my $err =$@; eval {$dbh->{AutoCommit} =1}; $@ =$err;
      $ret
 }
 else {
   my $err =$@ =$Error =$TrySubject .($TryStage eq '' ? '' : ": $TryStage:\n") .$@;
   TryHdr(undef,"rollback: $@");
   eval{$dbh->rollback; $dbh->{AutoCommit} =1}; $@=$err;
   $ret =ref($_[$#_]) eq 'CODE' ? &{$_[$#_]}() : $_[$#_]; 
   $@ ="$err\n$@" unless $@ eq $err;
   if ($ErrorDie) {die($err)}
   elsif ($Tk::TM::Common::Echo && ref($_[$#_]) ne 'CODE') {warn("Error: $err")}
   $ret
 }
}

############################################
sub TryHdr {
 $TrySubject =$_[0] if defined($_[0]);
 $TryStage   =$_[1] if defined($_[1]);
 $Tk::TM::Common::Echo && print($TrySubject.($TryStage ne '' ? ": $TryStage" : $TryStage)."...");
 ''
}
