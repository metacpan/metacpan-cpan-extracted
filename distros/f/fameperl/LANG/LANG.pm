#
# FAME 4GL subclass definitions
# FT 9/95
#
# public:
#   {workdb} : work database key
#   {status} : last status
#   new      : constructor
#   command  : execute command
#   exec     : execute function and return value
#   inp      : execute commands from file
#
#
#     Copyright (c) 1995 Fernando Trias. All rights reserved.
#     This is test software.  You are granted permission to use or
#     modify this software for the purposes of testing.  You may
#     redistribute this software as long as this intent is made
#     clear.
#

package Fame::LANG;
 
sub new {
  my($key,$status);
  &Fame::HLI::cfmopwk($status, $key);
  if ($status != &Fame::HLI::HSUCC) {
    $Fame::HLI::status = $status;
    return undef;
  }
  return bless { "temp" => "tmp$$", "workdb" => $key, "status" => $status };
}

sub destroy {
  my($self)=shift;
  &Fame::HLI::cfmcldb($self->{status}, $self->{workdb});
}
 
sub command {
  my($self, $cmd)=@_;
  &Fame::HLI::cfmfame($self->{status}, $cmd);
  return $self;
}
 
sub exec {
  my($self, $cmd, $start, $end)=@_;

  my(@i)=&Fame::HLI::famegetinfo($self->{workdb}, $self->{temp});
  if ($i[0]!=0) {
    &Fame::HLI::cfmfame($self->{status}, "delete work'".$self->{temp});
  }

  $cmd="-/".$self->{temp}."=".$cmd;
  &Fame::HLI::cfmfame($self->{status}, $cmd);
  return undef if ($self->{status} != Fame::HLI::HSUCC);
  return &Fame::DB::Read($self->{workdb}, $self->{temp}, $start, $end);
}
 
sub inp {
  my($self,@files)=@_;
  my($v,$vp)=("","");
  local($_);
  foreach $v (@files) {
    open(XFAME, "<$v") || return undef;
    while(<XFAME>) {
      # account for multi-line statements
      if (s/&&\s*$//) { $vp.=$_."\n"; }
      &Fame::HLI::cfmfame($self->{status}, $vp.$_);
      if ($self->{status} != &Fame::HLI::HSUCC) { return undef; }
    }
    close(XFAME);
  }
  return 1;
}

1;
