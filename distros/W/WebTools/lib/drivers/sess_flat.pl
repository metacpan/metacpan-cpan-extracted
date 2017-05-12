######################################################
# Flat Session Support for WebTools
# Powerd by www.proscriptum.com
#
######################################################

# Copyright (c) 2001, Julian Lishev, Sofia 2002
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.

######################################################

@sess_flat_requestedFiles  = ();
$sess_flat_countOfReqFiles = 0;
$sess_flat_ptrInBuffer = 0;
$sess_flat_allFiles = 0;
$sess_flat_boundary = '';
$sess_flat_file_prefix = '';
$sess_flat_file_size_limit = 0;

sub reset_SF_cache
{
 @sess_flat_requestedFiles  = ();      # Buffer for requested files!
 $sess_flat_countOfReqFiles = 500;     # Maximum files into buffer.
 $sess_flat_ptrInBuffer = 0;           # Current pointer into buffer.
 $sess_flat_allFiles = 0;              # Global processed files up to now.
 $sess_flat_boundary = '|';
 $sess_flat_file_prefix = 'webtools_sess_';
 $sess_flat_file_size_limit = 1048576; # Maximum size of flat size (1Mb)
 $webtools::loaded_functions = $webtools::loaded_functions | 16;
}

# Init variables
reset_SF_cache();

sub read_SF_NextFiles
{
 local *OD_FILE = shift(@_);
 my $sess_flat_path = shift(@_);
 my $sess_flat_cntFiles = shift(@_) || $sess_flat_countOfReqFiles;
 my $sess_flat_i;
 $sess_flat_ptrInBuffer = 0;
 @sess_flat_requestedFiles = ();
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 for ($sess_flat_i=0; $sess_flat_i<$sess_flat_cntFiles;$sess_flat_i++)
  {
   my $sess_flat_fn = readdir(OD_FILE);
   if($sess_flat_fn ne undef)
    {
     if((!($sess_flat_fn =~ /^\.$/s)) and (!($sess_flat_fn =~ /^\.\.$/s)))
      {
       my ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
           $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= stat($sess_flat_path.$sess_flat_fn);
       $sess_flat_fn .= $sess_flat_boundary.$sess_flat_mtime;            # File name + modified time (Eg: passwd|990466880)
       push(@sess_flat_requestedFiles, $sess_flat_fn);
      }
    else
     {
      $sess_flat_i--;
     }
    }
   else
    {
     push(@sess_flat_requestedFiles, $sess_flat_fn);
     last;
    }
  }
 return(@sess_flat_requestedFiles);
}

sub get_SF_NextFile
{
 local *OD_FILE = shift(@_);
 my $sess_flat_path = shift(@_);
 my $sess_flat_cntFiles = shift(@_) || $sess_flat_countOfReqFiles;
 if(($sess_flat_cntFiles == $sess_flat_ptrInBuffer) || ($sess_flat_allFiles == 0))
   {
    @sess_flat_requestedFiles = read_SF_NextFiles(OD_FILE,$sess_flat_path,$sess_flat_cntFiles);
   }
 my $sess_flat_fln = $sess_flat_requestedFiles[$sess_flat_ptrInBuffer++];
 $sess_flat_allFiles++;
 return($sess_flat_fln);
}

sub remove_SF_OldSessions
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_sessTime) = shift(@_) || time();
 local *ODFILE;
 reset_SF_cache();
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 opendir(ODFILE,$sess_flat_path);
 my $sess_flat_l='';
 my $sess_flat_tmpl = quotemeta($sess_flat_boundary);
 
 while($sess_flat_l = get_SF_NextFile(ODFILE,$sess_flat_path))
  {
   my ($sess_flat_fn,$sess_flat_modtime) = split(/$sess_flat_tmpl/,$sess_flat_l);
   if($sess_flat_fn =~ m/^$sess_flat_file_prefix/)
     {
      $sess_flat_modtime = int($sess_flat_modtime);
      if($sess_flat_modtime < $sess_flat_sessTime)
        {
         unlink($sess_flat_path.$sess_flat_fn);
        }
     }
  }
 closedir(ODFILE);
}

sub read_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;

 my $sess_flat_data = read_SF_lowlevel($sess_flat_path.$sess_flat_findSid);
 return($sess_flat_data);
}

sub find_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_file_prefix.$sess_flat_ses;

 if(-e $sess_flat_findFile)
  {
   return($sess_flat_ses);
  }
 return('');
}

sub write_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 my ($sess_flat_data) = shift(@_);
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 return(write_SF_lowlevel($sess_flat_findFile,$sess_flat_data));
}

sub create_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 if(-e $sess_flat_findFile)
  {
   unlink($sess_flat_findFile);
  }
 my $sess_orig_mask = umask 0177;   # umask 0177 is equal to mask 0600 (wr-------)
 open(CSFLL,">".$sess_flat_findFile) or return(undef);
 close(CSFLL);
 umask $sess_orig_mask;
 return(1);
}

sub destroy_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 if(-e $sess_flat_findFile)
  {
   unlink($sess_flat_findFile);
   return(1);
  }
 return(0);
}

sub update_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);
 
 if($sess_flat_ses eq '') {return(undef);}
 
 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 my $sess_flat_dat = read_SF_File($sess_flat_findFile,$sess_flat_ses);
 if(-e $sess_flat_findFile)
  {
   destroy_SF_File($sess_flat_findFile,$sess_flat_ses);
  }
 write_SF_File($sess_flat_findFile,$sess_flat_ses,$sess_flat_dat);

 return(1);
}

sub read_SF_lowlevel
{
 my ($sess_flat_findSid) = shift(@_);
 open(RSFLL,$sess_flat_findSid) or return(undef);
 binmode(RSFLL);
 if(read(RSFLL,$sess_flat_dat,$sess_flat_file_size_limit) eq undef)
   {
    $sess_flat_dat = undef;
   }
 close(RSFLL);
 return($sess_flat_dat);
}

sub write_SF_lowlevel
{
 my ($sess_flat_nFile,$sess_flat_data) = @_;
 my $sess_flat_dat = 1;
 my ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
     $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= ();
 my $sess_flat_fl = 0;
 if(-e $sess_flat_nFile)
  {
   ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
    $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= stat($sess_flat_nFile);
   $sess_flat_fl = 1;
  }
 my $sess_orig_mask = umask 0177;   # umask 0177 is equal to mask 0600 (wr-------)
 open(WSFLL,">".$sess_flat_nFile) or return(undef);
 binmode(WSFLL);
 if(!(print WSFLL $sess_flat_data))
   {
    $sess_flat_dat = undef;
   }
 close(WSFLL);
 umask $sess_orig_mask;
 if($sess_flat_fl) {utime ($sess_flat_atime,$sess_flat_mtime,$sess_flat_nFile);}
 return($sess_flat_dat);
}

sub osetflag_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);

 my ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
     $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= ();

 if($sess_flat_ses eq '') {return(undef);}

 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 if(-e $sess_flat_findFile)
  {
   ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
    $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= stat($sess_flat_findFile);
   my $sess_flat_f = 350100000;   # 4 February 1981
   if($sess_flat_atime > 360100000)
    {
     utime ($sess_flat_f,$sess_flat_mtime,$sess_flat_findFile);
     return(1);
    }
   else
    {
     return(-1);  # Unaccessable (still locked)
    }
  }
}

sub csetflag_SF_File
{
 my $sess_flat_path = shift(@_);
 my ($sess_flat_ses) = shift(@_);

 my ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
     $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= ();

 if($sess_flat_ses eq '') {return(undef);}

 if(!($sess_flat_path =~ m/\/$/s)) {$sess_flat_path .= '/';}
 
 my $sess_flat_findSid = $sess_flat_file_prefix.$sess_flat_ses;
 my $sess_flat_findFile = $sess_flat_path.$sess_flat_findSid;
 if(-e $sess_flat_findFile)
  {
   ($sess_flat_dev,$sess_flat_ino,$sess_flat_mode,$sess_flat_nlink,$sess_flat_uid,$sess_flat_gid,$sess_flat_rdev,
    $sess_flat_size,$sess_flat_atime,$sess_flat_mtime,$sess_flat_ctime,$sess_flat_blksize,$sess_flat_blocks)= stat($sess_flat_findFile);
   my $sess_flat_f = time();   # 4 February 1981
   if($sess_flat_atime < 360100000)
    {
     utime ($sess_flat_f,$sess_flat_mtime,$sess_flat_findFile);
     return(1);
    }
   else
    {
     return(-1);  # Unaccessable (still locked)
    }
  }
}

#####################################################################
# Session Support Functions
#####################################################################

my $sys_sess_flat_eval = << 'SYS_FLAT_EVAL_TERMINATOR';
sub sess_flat_session_clear_expired
{
 remove_SF_OldSessions($tmp,time()-$sys_time_for_flat_sess);
 return(1);
}
sub sess_flat_session_expire_update
{
 return(update_SF_File($tmp,$sys_local_sess_id));
}
sub sess_flat_insert_sessions_row   # ($session_id,$db_handler)
{
 write_SF_File($tmp,$sys_local_sess_id,'');
 return(1);
}
sub sess_flat_DB_OnDestroy
{
 return(1);
}
$webtools::sys__subs__->{'session_clear_expired'} = \&sess_flat_session_clear_expired;
$webtools::sys__subs__->{'session_expire_update'} = \&sess_flat_session_expire_update;
$webtools::sys__subs__->{'insert_sessions_row'} = \&sess_flat_insert_sessions_row;
$webtools::sys__subs__->{'DB_OnDestroy'} = \&sess_flat_DB_OnDestroy;
SYS_FLAT_EVAL_TERMINATOR

if($sess_force_flat =~ m/^on$/i){eval $sys_sess_flat_eval;}

1;