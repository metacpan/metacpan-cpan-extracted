package FlatLock;

# Flat lock module written by Julian Lishev
# This module is part of WebTools package!
# Privacy and terms are same as WebTools!
# www.proscriptum.com

# This module can "lock" one or other number.
# In that state it will stay till somebody
# "unlock" this number or till critical
# timeout become (i.e. after 300sec)

# You can use this module to lock and unlock
# some critical actions of your programs.

# This module create file (default) in /tmp
# directory when you lock "fibre" and module
# delete this file when fibre is unlocked!


use strict;

%FlatLock::AllMembers = ();

=head2 $obj = FlatLock->new (%inp);

 %inp hash can contain follow members:
   id     - Id of new flocked fibre.(Default: rand() 1 to 10000)
   path   - Full path to directory where temp files will be created!
            (Default: '/tmp')
   wpc    - Is time between two attempts when fibre is locked! 
            (default is rand() between 0.3 - 0.6 sec.)
   tpc    - Is total number of attempts in case of locked fibre.
            (default: 6)
   critical_time - Is maximum time in seconds before engine to 
                   force deleting of locked fibre! (default: 300)

=cut

BEGIN
 {
  use vars qw($VERSION @ISA @EXPORT);
  $VERSION = "1.26";
  @ISA = qw(Exporter);
  @EXPORT = qw();
 }

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $this = {};
 
 my %inp = @_;
 
 $this->{'id'} = $inp{'id'} or do {
 while(1)
  {
   my $id = int(rand(9999)+1);
   if(!exists($FlatLock::AllMembers{$id}))
     {
      $this->{'id'} = $id;
      $FlatLock::AllMembers{$id} = $id;
      last;
     }
  }
 };
 $FlatLock::AllMembers{$this->{'id'}} = $this->{'id'};
 $this->{'path'} = $inp{'path'} || '/tmp/';
 $this->{'path'} =~ s/\\/\//sgi;
 $this->{'path'} =~ s/([^\/])$/$1\//sgi;
 if(!(-e $this->{'path'})) {die "Error: Unavalable path!";}
 $this->{'path'} .= 'webtools_lock_handle_';
 $this->{'wpc'} = $inp{'wpc'} || (rand(0.3) + 0.3);
 $this->{'tpc'} = $inp{'tpc'} || 6;
 $this->{'critical_time'} =$inp{'critical_time'} || 300;
 bless($this,$class);
 return($this);
}

sub force_unlock
{
 my $obj = shift;
 my $id  = shift;
 $id = $id || $obj->{'id'};
 unlink($obj->{'path'}.$id);
 1;
}

sub is_locked
{
 my $obj = shift;
 my $id  = shift;
 $id = $id || $obj->{'id'};
 
 open(LFILE, $obj->{'path'}.$id) or return(0);
 close LFILE;
 return(1);
}

sub lock
{
 my $obj = shift;
 my $id  = shift;
 $id = $id || $obj->{'id'};
 
 my $i;
 foreach $i (1..$obj->{'tpc'})
 {
  if($obj->is_locked($id))
   {
    if($i == $obj->{'tpc'}) { return(0); }        # System wan't to reallocate this handle!
    select(undef,undef,undef,$obj->{'wpc'});
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,
        $mtime,$ctime,$blksize,$blocks)= stat($obj->{'path'}.$id);
    my $difr = time() - $mtime;
    if($difr >= $obj->{'critical_time'})          # System used too long time this handle!
      {
       $obj->force_unlock();
      }
   }
  else
   {
    open(FILE, '>'.$obj->{'path'}.$id) or return(-1);  # Error can't create file!
    close FILE;
    return(1);
   }
  }
 return(0);
}


sub unlock
{
 my $obj = shift;
 my $id  = shift;
 
 $id = $id || $obj->{'id'};
 
 if(!$obj->is_locked($id))
  {
   return(-1);        # Not locked?!?
  }
 else
  {
   unlink($obj->{'path'}.$id) or return(-2);  # Error can't delete file!
   return(1);
  }
}

sub DESTROY
{
 1;
}

1;