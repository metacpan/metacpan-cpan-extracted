#
#     Copyright (c) 1995 Fernando Trias. All rights reserved.
#     This is test software.  You are granted permission to use or
#     modify this software for the purposes of testing.  You may
#     redistribute this software as long as this intent is made
#     clear.
#
use Fame::HLI;
package Fame::DB;

use Carp;
use Exporter;
use DynaLoader;
@ISA = (Exporter, DynaLoader);

sub AUTOLOAD {
    local($constname);
    $AutoLoader::AUTOLOAD = $AUTOLOAD;
    goto &AutoLoader::AUTOLOAD;
}

#
# Fame utility library
#
# FT orig. 7/28/95
# 9/95
#

#
# EXTERNAL USE VARIBABLES
#

# default frequency (read/write)
$FREQ = &Fame::HLI::HDAILY;

# default type
$TYPE=&Fame::HLI::HNUMRC;

#default basis
$BASIS=&Fame::HLI::HBSDAY;

#default observed
$OBSERVED=&Fame::HLI::HOBSUM;

#default class
$CLASS=&Fame::HLI::HSERIE;

# default wildcard for FIRST and NEXT in the "Tie" routines (r/w)
$WILD = "?";

# list of open databases (read only) indexed by the db code
# returned by fameopen.
$TIEDB{0}="";

#
# INTERNAL USE VARIABLES
#

# list of wildcard databases
@WILDDB=();

#
# UTILITIES
#

#
# ($year, $per) = &getdate($d, $freq)
#
#    $year  year (or 0 for case series)
#    $per   period (or case number)
#    $d     string date (like "1jan95" or "95q1") followed by
#           an optional +/- offset
#    $freq  optional frequency code (use $FREQ if not specified)
#
sub getdate {
  my ($d, $freq, $year, $per)=@_;
  my ($status, $date);
  #print STDERR "ydate $d\n";
  if (!$d || $d eq "" || $d eq "*") { return($year, $per); }
  if (!$freq) { $freq=$FREQ; }
  if ($freq==&Fame::HLI::HCASEX) { $d =~ s/^\d+://; return (0, $d); }
  if ($d =~ /:/) {
    ($year, $per)=split(/:/,$d,2);
    if ($year<100) { $year += 1900; }
    return ($year, $per);
  }
  # extract string ($dd) and +/- offset ($do)
  my ($dd,$do)=($d =~ /^([^+-]+)([+-]\d+)?/);
  print STDERR "xdate $d:$dd:$do\n";
  &Fame::HLI::cfmldat($status, $freq, $date, $dd, 
      &Fame::HLI::HJAN, &Fame::HLI::HFYFST, 1900);
  &Fame::HLI::cfmdatp($status, $freq, $date+$do, $year, $per);
  #print STDERR "xxdate $status $freq: $year, $per\n";
  return ($year, $per);
}

#
# &Read
#
#   $db    database key
#   $k     string object name
#   $start start string date
#   $end   end string date
#
# returns array of values
#
sub Read {
  my($db, $k, $start, $end)=@_;
  my(@i, @x);

  if (ref($db)) { $db=&famefind($k,@$db); }
  if ($db==-1) { return undef; }

  @i=&Fame::HLI::famegetinfo($db,$k);
  #print STDERR "info2 $db $k ",join(":",@i),"\n";
  if ($i[0]==0) { return undef; }

  ($sy, $sp)=&getdate($start, $i[2], @i[5,6]);
  ($ey, $ep)=&getdate($end, $i[2], @i[7,8]);

  #print STDERR "read2 $db $k $i[2]: $sy $sp $ey $ep\n";
  if ($sp<0 || $ep<0) { return undef; }
  if ($i[1] == &Fame::HLI::HSTRNG) {
    @x=&readstrings($db, $k, $i[2], $sy, $sp, $ey, $ep);
  } else {
    @x=&Fame::HLI::fameread($db, $k, $sy, $sp, $ey, $ep);
  }
  return @x;
}

#
# &Write
#
#   $db    database key
#   $k     string object name
#   $start start string date
#   @val   array of values to store
#
sub Write {
  my($db, $k, $start, @val)=@_;
  my(@i, @x);

  if ($#val<0) { return undef; }

  if (ref($db)) { $db=&famefind($k,@$db); }
  if ($db==-1) { return undef; }

  @i=&Fame::HLI::famegetinfo($db,$k);
  if ($i[0]==0) { return undef; }

  ($sy, $sp)=&getdate($start, $i[2], @i[5,6]);

  #print STDERR "Write: $db, $k, $sy, $sp, @val\n";
  if ($i[1] == &Fame::HLI::HSTRNG) {
    &writestrings($db, $k, $i[2], $sy, $sp, @val);
  } else {
    &Fame::HLI::famewrite($db, $k, $sy, $sp, @val);
  }
}

#
# readstrings  -- internal
#
sub readstrings {
  my($db,$k,$freq,$sy,$sp,$ey,$ep)=@_;
  my($num, $d, $sdate, $edate, $status, $r1, $r2, $r3, $str, $len);
  my(@ret)=();

  #print STDERR "read3 $db $k: $sy, $sp, $ey, $ep\n";
  if ($freq == &Fame::HLI::HCASEX) {
    for($d=$sp;$d<=$ep;$d++) {
      $num=-1;
      &Fame::HLI::cfmsrng($status,$freq,$sy,$d,$sy,$d,$r1,$r2,$r3,$num);
      &Fame::HLI::cfmrstr($status,$db,$k,$r1,$r2,$r3,$str,
                          &Fame::HLI::HNMVAL,$len);
      #print STDERR "string $d: $str\n";
      push(@ret,$str);
    }
  } else {
    &Fame::HLI::cfmpdat($status, $freq, $sdate, $sy, $sp);
    &Fame::HLI::cfmpdat($status, $freq, $edate, $ey, $ep);

    for($d=$sdate; $d <= $edate; $d++) {
      &Fame::HLI::cfmdatp($status, $freq, $d, $sy, $sp);
      $num=-1;
      &Fame::HLI::cfmsrng($status,$freq,$sy,$sp,$sy,$sp,$r1,$r2,$r3,$num);
      &Fame::HLI::cfmrstr($status,$db,$k,$r1,$r2,$r3,$str,
                          &Fame::HLI::HNMVAL,$len);
      push(@ret,$str);
    }
  }
  return @ret;
}

#
# writestrings  -- internal
#
sub writestrings {
  my($db,$k,$freq,$sy,$sp,@val)=@_;
  my($num, $d, $status, $r1, $r2, $r3, $str, $len);

  if ($freq == &Fame::HLI::HCASEX) {
    $d=$sp;
    foreach $str (@val) {
      $len = length($str);
      $d++;
      $num=-1;
      &Fame::HLI::cfmsrng($status,$freq,$sy,$d,$sy,$d,$r1,$r2,$r3,$num);
      &Fame::HLI::cfmwstr($status,$db,$k,$r1,$r2,$r3,$str,
                          &Fame::HLI::HNMVAL,$len);
    }
  } else {
    &Fame::HLI::cfmpdat($status, $freq, $d, $sy, $sp);
    foreach $str (@val) {
      $len = length($str);
      &Fame::HLI::cfmdatp($status, $freq, $d++, $sy, $sp);
      $num=-1;
      &Fame::HLI::cfmsrng($status,$freq,$sy,$sp,$sy,$sp,$r1,$r2,$r3,$num);
      &Fame::HLI::cfmwstr($status,$db,$k,$r1,$r2,$r3,$str,
                          &Fame::HLI::HNMVAL,$len);
    }
  }
}

#
# &Create
#
#    $db      reference to array of databases to access
#             or a single database number.  Will write
#             to the first database in the list.
#    $name    object name
# the following are optional:
#    $class   class code
#    $freq    frequency code
#    $type    object type
#    $basis   basisi attribute
#    $observ  observed attribute
#
sub Create {
  my($db, $name, $class, $freq, $type, $basis, $observ)=@_;
  my($status, $dbkey);
  if (ref($db)) { $db=$db->[0]; }
  $class=$CLASS unless $class;
  $freq=$FREQ unless $freq;
  $type=$TYPE unless $type;
  $basis=$BASIS unless $basis;
  $observ=$OBSERVED unless $observ;
  #print STDERR "$status,$db,$name,$class,$freq,$type,$basis,$observ\n";
  &Fame::HLI::cfmnwob($status,$db,$name,$class,$freq,$type,$basis,$observ);
  if ($status==&Fame::HLI::HSUCC) { return 1; }
  else { $!=$status; return 0; }
}

#
# $db = famefind ($key, @list)
#
#   $db    = database were $key resides or -1 for none
#   $key   = key to find
#   @list  = list of open database codes
#
sub famefind {
  my($key,@list)=@_;
  my($db,@i);
  foreach $db (@list) {
    #print STDERR "looking $db $key\n";
    if (&Fame::HLI::famegettype($db,$key)) { return $db; }
  }
  #print STDERR "not found $key\n";
  return -1;
}

sub fameerror {
  my($status,$module)=@_;
  return if $status = &Fame::HLI::HSUCC;
  if ($module) {
    print STDERR "FAME HLI ERROR $status in $module: ",&getsta($status),"\n";
  } else {
    print STDERR "FAME HLI ERROR $status: ",&getsta($status),"\n";
  }
}

#
# Object-oriented stuff
#

#sub new {
  #my $self = [];
  #my $pack = shift;
  #my (@l)=@_;
  ## print STDERR "new open $l[0]\n";
  #$self->[0] = &Fame::HLI::fameopen(@l);
  #if ($self->[0] == -1) { return undef; }
  #bless $self
#}

sub new {
  my $self = [];
  my $pack = shift;
  &append($self, @_) || return undef;
  bless $self;
}

sub append {
  my $self = shift;
  my($mode, $db, @dbl);
  $mode=&Fame::HLI::HRMODE;
  foreach $db (@_) {
    #print STDERR "check $db\n";
    if ($db =~ /^\d+$/) { $mode=$db; next; }
    $x=&Fame::HLI::fameopen($db,$mode);
    #print STDERR "tie $db:$mode:$x\n";
    if ($x == -1) { return undef; }
    push(@$self, $x);
  }
  return $self;
}

sub append_db {
  my $self = shift;
  my $db;
  foreach $db (@_) {
    push(@$self, $db);
  }
  return $self;
}

sub destroy {
  my $self = shift;
  my $v;
  foreach $v (@$self) {
    &Fame::HLI::fameclose($v);
  }
}

sub error {
  &fameerror($!);
}

#
#  TIE functions
#

sub TIEHASH {
  my($obj, @list)=@_;
  my($x, @db, $db);
  @db=();
  #print STDERR "TIE $obj @list\n";
  if (ref($list[0])) { @list=@{$list[0]}; }
  $mode=&Fame::HLI::HRMODE;
  foreach $db (@list) {
    #print STDERR "check $db\n";
    if ($db =~ /^\d+$/) { $mode=$db; next; }
    $x=&Fame::HLI::fameopen($db,$mode);
    #print STDERR "tie $db:$mode:$x\n";
    if ($x == -1) { return undef; }
    push(@db,$x);
    $TIEDB{$x}=$db;
  }
  bless \@db;
}

sub DESTROY {
  my($obj,$k)=@_;
  #print STDERR "Destroy $$obj\n";
  foreach $k (@$obj) {
    &Fame::HLI::fameclose($k);
    delete($TIEDB{$k});
  }
}

#
# convert a string ident to a date
#
#  <object> : <start_date>[+-offset] [ , <end_date>[+-offset] ]
#
#  date may be "*".
#
sub getident {
  my ($key,@dbl)=@_;
  my ($k,$sdate,$edate)=($key =~ /([^:]+):?([^,]*),?(.*)/);
  #split(/[,;]/,$key);
  my ($sy, $sp, $ey, $ep, @i, $db);

  $db=&famefind($k,@dbl);
  #print STDERR "search @dbl $k $db\n";
  if ($db<0) { return undef; }
  #print STDERR "found $db $k $sdate $edate\n";

  @i=&Fame::HLI::famegetinfo($db,$k);
  #print STDERR "info $k=",join(":",@i),"\n";

  if ($i[0] == &Fame::HLI::HSERIE) {

    if (!$sdate) { $sdate="*"; }
    if (!$edate) { $edate=$sdate; }

    if ($sdate eq "*") { ($sy, $sp)=@i[5,6]; }
    else { ($sy,$sp)=&getdate($sdate, $i[2]); }

    if ($edate eq "*") { ($ey, $ep)=@i[7,8]; }
    else { ($ey,$ep)=&getdate($edate, $i[2]); }
  
    if ($i[2] != &Fame::HLI::HCASEX && ($sy == 0 || $ey == 0)) { return undef; }
    #print STDERR "getdate $db $k $sy $sp $ey $ep\n";

    return ($db,$k,"$sy:$sp","$ey:$ep");
  } else {
    return ($db,$k,"0:0","0:0");
  }
}

sub FETCH {
  my ($obj, $key)=@_;
  #my (@x)=();

  # return db codes for all open databases
  if ($key eq "dbcodes") { return $obj; }

  # return names for open databases
  if ($key eq "dblist") {
    @x=();
    my ($k);
    foreach $k (@$obj) {
      push(@x,$TIEDB{$k});
    }
    return bless \@x;
  }

  #print STDERR "read0 @$obj $key\n";
  my ($db,$k,$start,$end)=&getident($key,@$obj);
  if (!$k) { return undef; }
  #print STDERR "read $db $k : $sy $sp $ey $ep\n";
  @x=&Read($db, $k, $start, $end);
  bless \@x;
}

sub STORE {
  my ($obj, $key, $val)=@_;
  my (@v);

  if (ref($val)) { @v=@$val; }
  else { @v=($val); }

  my ($db,$k,$start)=&getident($key,@$obj);
  #print STDERR "write $db $k $start ",join(":",@v),"\n";
  if (!$k) { return undef; }
  &Write($db, $k, $start, @v);
  1;
}

sub DELETE {
  my($obj, $key)=@_;
  my ($status);

  $db=&famefind($key,@$obj);
  &Fame::HLI::cfmdlob($status, $db, $key);
  if ($status == &Fame::HLI::HSUCC) { return 1; }
  else { return 0; }
}

sub EXISTS {
  my ($obj, $key)=@_;

  my($i)=&famefind($key, @$obj);
  if ($i<0) { return 0; }
  else { return 1; }
}

sub FIRSTKEY {
  my ($obj)=@_;
  my ($status, $name, $class, $type, $freq);
  my ($w)=($WILD);

  @WILDDB=@$obj;
  &Fame::HLI::cfminwc($status, $WILDDB[0], $w);
  &Fame::HLI::cfmnxwc($status, $WILDDB[0], $name, $class, $type, $freq);
  #print STDERR "Get First $obj : $status, $name, $class, $type, $freq\n";
  if ($status==&Fame::HLI::HSUCC) { return $name; }
  else { return undef; }
}

sub NEXTKEY {
  my ($obj, $last)=@_;
  my ($status, $name, $class, $type, $freq);
  my ($w)=($WILD);

  &Fame::HLI::cfmnxwc($status, $WILDDB[0], $name, $class, $type, $freq);
  #print STDERR "Start Get Next $obj : $status, $name, $class, $type, $freq\n";
  if ($status==&Fame::HLI::HSUCC) { return $name; }
  else { 
    shift(@WILDDB); 
    if ($#WILDDB<0) { return undef; }
    &Fame::HLI::cfminwc($status, $WILDDB[0], $w);
    &Fame::HLI::cfmnxwc($status, $WILDDB[0], $name, $class, $type, $freq);
    if ($status==&Fame::HLI::HSUCC) { return $name; }
    else { return undef; }
  }
}

1;
