###############################################
# DeepWalk library.
# Recursive copy,move,remove and chmod subs!
###############################################
# Exported functions:
# dw_copy, dw_move, dw_remove
###############################################
# Prototypes:
# $status = dw_copy($source,$target[,$umask]);
# $status = dw_move($source,$target[,$umask]);
# $status = dw_remove($path);
# #status = dw_chmod($path,$type,$mode);
# where:
# $status contain count of 
#   unsucessful copied/removed/chmoded files,
#   so $status = 0, means full success!
#   $status may have a follow negative
#   value: -1 means: "Not enought parameters"
# $source and $path are paths (absolute 
#   or relative) to folder or file.
# $target is always directory (absolute or 
#   relative).
# $type can be: 'all','folders','files'.
#   Function will affect only $type objects!
# $mode is permission mode of file/folder.
#   It should be in standart format as is in 
#   perl's chmod() function! (see Perl's docs)
# $umask is restricted (umask) file/folder mask
#   which is logical negative on $mask, so
#   $umask = 0553 is equal to chmod $mask 0224
#   If you use $umask parameter then all 
#   permissions will be affected from $umask!
###############################################
# Note: All functions are called with 
# "force" parameter, so not readable folder/
# file will be [re]moved, if you call [re]
# move function! (owned by same user of cource)
# Please be carefull! NO 'delete' confirma-
# tion is required!!!
###############################################

my @deepWalk;
my $system_slash;
my $deepWalk_file_buffer = 1048576; # Default file buffer size: 1Mb

&init_deepWalk();

sub init_deepWalk
{
 unless ($sys_dw_OS) 
  {
   unless ($sys_dw_OS = $^O) 
      {
       require Config;
       $sys_dw_OS = $Config::Config{'osname'};
      }
  }
 if    ($sys_dw_OS =~ /^MSWin/i){$sys_dw_OS = 'WINDOWS';}
 elsif ($sys_dw_OS =~ /^VMS/i) {$sys_dw_OS = 'VMS';}
 elsif ($sys_dw_OS =~ /^dos/i) {$sys_dw_OS = 'DOS';}
 elsif ($sys_dw_OS =~ /^MacOS/i) {$sys_dw_OS = 'MACINTOSH';}
 elsif ($sys_dw_OS =~ /^os2/i) {$sys_dw_OS = 'OS2';}
 elsif ($sys_dw_OS =~ /^epoc/i) {$sys_dw_OS = 'EPOC';}
 else  {$sys_dw_OS = 'UNIX'; }

 $needs_binmode = $sys_dw_OS=~/^(WINDOWS|DOS|OS2|MSWin)/;

 $system_slash = {
        UNIX=>'/', OS2=>'\\', EPOC=>'/', 
        WINDOWS=>'\\', DOS=>'\\', MACINTOSH=>':', VMS=>'/'
       }->{$sys_dw_OS};
 
 @deepWalk = ();
}

sub deepWalk
{
 my $prefix_path = shift;
 my @folders = ();
 my @deepWalkQueue = ();
 my $error = 0;
 my $folder = undef;
 my $current = undef;
 local * DIR_HANDLER;
 
 my $q_slash = quotemeta($system_slash);
 
 $prefix_path =~ s/\ {1,}$//s;
 $prefix_path =~ s/^\ {1,}//s;
 
 $prefix_path =~ s/[$q_slash]+$//s;
 unshift(@deepWalkQueue,$system_slash);
 
 while((scalar(@deepWalkQueue) > 0) and (!$error))
  {
   $current = pop(@deepWalkQueue);
   opendir(DIR_HANDLER,$prefix_path.$current) or next();
   $current =~ s/[$q_slash]+$//s;
   while(1)
    {
     $folder = readdir(DIR_HANDLER);
     if($folder ne undef)
       {
        if((!($folder =~ /^\.$/s)) and (!($folder =~ /^\.\.$/s)))
          {
            if(-d ($prefix_path.$current.$system_slash.$folder))
             {
              unshift(@deepWalkQueue,$current.$system_slash.$folder);
              push(@deepWalk,$current.$system_slash.$folder);
             }
          }
       }
      else {last;}
     }
    closedir(DIR_HANDLER);
  }
 return();
}

sub dw_copy_files
{
 my $source = shift;
 my $target = shift;
 my $umask  = shift;
 my $counter_strike = 0;
 
 my $file = undef;
 local * DIR_HANDLER;
 
 $source .= $system_slash;
 $target .= $system_slash;
 
 opendir(DIR_HANDLER,$source) or return();
 while(1)
  {
   $file = readdir(DIR_HANDLER);
   if($file ne undef)
    {
     if((!($file =~ /^\.$/s)) and (!($file =~ /^\.\.$/s)))
        {
          if(!(-d ($source.$file)))
           {
            if(!&dw_copy_file($source.$file,$target.$file,$umask)) {$counter_strike++};
           }
        }
    }
   else {last;}
  }
 closedir(DIR_HANDLER);
 return($counter_strike);
}

sub dw_copy_file
{
 my $source = shift;
 my $target = shift;
 my $umask  = shift;
 local * SRCFILE;
 local * DSTFILE;
 my $orig_mask;
 my $buffer;
 
 my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source);
 
 if($umask ne undef)
  {
   $orig_mask = umask $umask;
  }
 
 open(SRCFILE,$source) or return(-1);
 binmode SRCFILE;
 
 open(DSTFILE,'>'.$target) or do {
  close SRCFILE;
  return(-2);
 };
 
 binmode DSTFILE;
 
 while(1)
   {
    my $result = read(SRCFILE,$buffer,$deepWalk_file_buffer);
    if($result == 0)
      {
       last;
      }
    if($result eq undef)               # Error!
      {
       close SRCFILE;
       close DSTFILE;
       return(-3);
      }
    if(!(print DSTFILE $buffer))
      {
       close SRCFILE;
       close DSTFILE;
       return(-4);
      }
   }
 
 close SRCFILE;
 close DSTFILE;
 
 if($umask eq undef)
  {
   chmod ($mode, $target);
  }
  
 if($< == 0)
  {
   chown $uid, $gid, $target;
  }
 
 utime ($atime, $mtime, $target);
 umask $orig_mask;
 return(1);
}

sub recursive_mkdir
{
 my $folder = shift;
 my $umask  = shift;
 
 my $q_slash = quotemeta($system_slash);
 my @paths = split(/$q_slash/s,$folder);
 
 my $path;
 my $full_path = '';
 foreach $path (@paths)
  {
   $full_path .= $path.$system_slash;
   if($umask ne undef)
     {
      my $orig_mask = umask $umask;
      mkdir($full_path,0777);
      umask $orig_mask;
     }
    else
     {
      mkdir($full_path,0777);
     }
  }
}

sub dw_copy
{
 return(-1) if(scalar(@_) < 2);
 my $source = shift;
 my $target = shift;
 my $umask  = $_[0] eq '' ? shift : undef;
 my $folder;
 my $counter_strike = 0;
 
 my $q_slash = quotemeta($system_slash);
 
 # Repair wrong slashes: \\ to / in Unix like OS and / to \\ in Dos like OS.
 if($system_slash =~ m/\\/si)
  {
   $source =~ s/\//$system_slash/sg;
   $target =~ s/\//$system_slash/sg;
  }
 if($system_slash =~ m/\//si)
  {
   $source =~ s/\\/$system_slash/sg;
   $target =~ s/\\/$system_slash/sg;
  }
 
 if(-d $source)
  {
   $target =~ s/$q_slash$//s;
   if(!($source =~ m/$q_slash$/s))
    { 
     $source =~ m/([^\:$q_slash]+)$/s;    
     $target .= $system_slash.$1;
    }
   $source =~ s/$q_slash$//s;
   
   @deepWalk = ();
   &deepWalk($source);
   
   unshift(@deepWalk,'');
   foreach $folder (@deepWalk)
    {
     if(!(-e $target))
      {
      	&recursive_mkdir($target,$umask);
      }
     if(!(-e $target.$folder))
       {
        if($umask ne undef)
         {
          my $orig_mask = umask $umask;
          my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
          mkdir($target.$folder,0777);
          utime ($atime, $mtime, $target.$folder);
          umask $orig_mask;
         }
        else
         {
          my $orig_mask = umask 0000;
          my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
       	  mkdir($target.$folder,$mode);
       	  utime ($atime, $mtime, $target.$folder);
       	  umask $orig_mask;
       	 }
       }
     if(-e $target.$folder)
      {
       $counter_strike += &dw_copy_files($source.$folder,$target.$folder,$umask);
      }
    }
  }
 else
  {
   my $file;
   if($source =~ m/(.*)$q_slash(.*)$/s)
    {
     $file = $2;
    }
   else
    {
     $file = $source;
    }
   if(!(-e $target))
     {
      &recursive_mkdir($target,$umask);
     }
   if(-e $target)
     {
      if(!&dw_copy_file($source,$target.$system_slash.$file,$umask)) {$counter_strike++;}
     }
  }
 return($counter_strike);
}

sub dw_move_files
{
 my $source = shift;
 my $target = shift;
 my $umask  = shift;
 my $counter_strike = 0;
 
 my $file = undef;
 local * DIR_HANDLER;
 
 $source .= $system_slash;
 $target .= $system_slash;
 
 opendir(DIR_HANDLER,$source) or return();
 while(1)
  {
   $file = readdir(DIR_HANDLER);
   if($file ne undef)
    {
     if((!($file =~ /^\.$/s)) and (!($file =~ /^\.\.$/s)))
        {
          if(!(-d ($source.$file)))
           {
            if(!&dw_copy_file($source.$file,$target.$file,$umask)) {$counter_strike++;}
            else
             {
              if(!(-w $source.$file))
               {
               	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$file);
               	chmod(($mode | 0700),$source.$file);    # Make file removeable for owner
               }
              unlink($source.$file);
             }
           }
        }
    }
   else {last;}
  }
 closedir(DIR_HANDLER);
 return($counter_strike);
}

sub dw_move
{
 return(-1) if(scalar(@_) < 2);
 my $source = shift;
 my $target = shift;
 my $umask  = $_[0] eq '' ? shift : undef;
 my $folder;
 my $counter_strike = 0;
 my $remove_root = 0;
 
 my $q_slash = quotemeta($system_slash);
 
 # Repair wrong slashes: \\ to / in Unix like OS and / to \\ in Dos like OS.
 if($system_slash =~ m/\\/si)
  {
   $source =~ s/\//$system_slash/sg;
   $target =~ s/\//$system_slash/sg;
  }
 if($system_slash =~ m/\//si)
  {
   $source =~ s/\\/$system_slash/sg;
   $target =~ s/\\/$system_slash/sg;
  }
 
 if(-d $source)
  {
   $target =~ s/$q_slash$//s;
   if(!($source =~ m/$q_slash$/s))
    { 
     $source =~ m/([^\:$q_slash]+)$/s;    
     $target .= $system_slash.$1;
     $remove_root = 1;
    }
   $source =~ s/$q_slash$//s;
   
   @deepWalk = ();
   &deepWalk($source);
   unshift(@deepWalk,'');
   foreach $folder (@deepWalk)
    {
     if(!(-e $target))
      {
      	&recursive_mkdir($target,$umask);
      }
     if(!(-e $target.$folder))
       {
        if($umask ne undef)
         {
          my $orig_mask = umask $umask;
          my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
          mkdir($target.$folder,0777);
          utime ($atime, $mtime, $target.$folder);
          umask $orig_mask;
         }
        else
         {
          my $orig_mask = umask 0000;
          my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
       	  mkdir($target.$folder,$mode);
       	  utime ($atime, $mtime, $target.$folder);
       	  umask $orig_mask;
       	 }
       }
     if(-e $target.$folder)
      {
       $counter_strike += &dw_move_files($source.$folder,$target.$folder,$umask);
      }
    }
   
   if (!$remove_root) {shift(@deepWalk);}
   foreach $folder (reverse(@deepWalk))
    {
     if(!(-w $source.$folder))
      {
       my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
       chmod(($mode | 0700),$source.$folder);    # Make folder removeable for owner
      }
     rmdir($source.$folder);
    }
  }
 else
  {
   my $file;
   if($source =~ m/(.*)$q_slash(.*)$/s)
    {
     $file = $2;
    }
   else
    {
     $file = $source;
    }
   
   if(!(-e $target))
     {
      &recursive_mkdir($target,$umask);
     }
   if(-e $target)
     {
      if(!&dw_copy_file($source,$target.$system_slash.$file,$umask)) {$counter_strike++;}
      else
       {
       	if(!(-w $source))
          {
           my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source);
           chmod(($mode | 0700),$source);    # Make file removeable for owner
          }
        unlink($source);
       }
     }
  }
 return($counter_strike);
}

sub dw_remove_files
{
 my $source = shift;
 my $counter_strike = 0;
 
 my $file = undef;
 local * DIR_HANDLER;
 
 $source .= $system_slash;
 $target .= $system_slash;
 
 opendir(DIR_HANDLER,$source) or return();
 while(1)
  {
   $file = readdir(DIR_HANDLER);
   if($file ne undef)
    {
     if((!($file =~ /^\.$/s)) and (!($file =~ /^\.\.$/s)))
        {
          if(!(-d ($source.$file)))
           {
            if(!(-w $source.$file))
              {
               my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$file);
               chmod(($mode | 0700),$source.$file);    # Make file removeable for owner
              }
            if(!unlink($source.$file)) {$counter_strike++;}
           }
        }
    }
   else {last;}
  }
 closedir(DIR_HANDLER);
 return($counter_strike);
}

sub dw_remove
{
 return(-1) if(scalar(@_) != 1);
 my $source = shift;
 my $folder;
 my $counter_strike = 0;
 my $remove_root = 0;
 
 my $q_slash = quotemeta($system_slash);
 
 # Repair wrong slashes: \\ to / in Unix like OS and / to \\ in Dos like OS.
 if($system_slash =~ m/\\/si)
  {
   $source =~ s/\//$system_slash/sg;
  }
 if($system_slash =~ m/\//si)
  {
   $source =~ s/\\/$system_slash/sg;
  }
  
 if(-d $source)
  {
   if(!($source =~ m/$q_slash$/s))
   { 
    $source =~ m/([^\:$q_slash]+)$/s;    
    $remove_root = 1;
   }
   $source =~ s/$q_slash$//s;
   
   @deepWalk = ();
   &deepWalk($source);
   unshift(@deepWalk,'');
   foreach $folder (@deepWalk)
    {
     $counter_strike += &dw_remove_files($source.$folder);
    }
   
   if (!$remove_root) {shift(@deepWalk);}
   foreach $folder (reverse(@deepWalk))
    {
     if(!(-w $source.$folder))
      {
       my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
       chmod(($mode | 0700),$source.$folder);    # Make folder removeable for owner
      }
     rmdir($source.$folder);
    }
  }
 else
  {
   if(!(-w $source))
     {
      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source);
      chmod(($mode | 0700),$source);    # Make file removeable for owner
     }
   if(!unlink($source)) {$counter_strike++;}
  }
 return($counter_strike);
}

sub dw_chmod_files
{
 my $source = shift;
 my $mode   = shift;
 my $counter_strike = 0;
 
 my $file = undef;
 local * DIR_HANDLER;
 
 $source .= $system_slash;
 $target .= $system_slash;
 
 opendir(DIR_HANDLER,$source) or return();
 while(1)
  {
   $file = readdir(DIR_HANDLER);
   if($file ne undef)
    {
     if((!($file =~ /^\.$/s)) and (!($file =~ /^\.\.$/s)))
        {
          if(!(-d ($source.$file)))
           {
            my $orig_mask = umask 0000;
            my ($dev,$ino,$md,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$file);
            if(!chmod($mode,$source.$file)) {$counter_strike++;}
            utime ($atime, $mtime, $source.$file);
            umask $orig_mask;
           }
        }
    }
   else {last;}
  }
 closedir(DIR_HANDLER);
 return($counter_strike);
}

sub dw_chmod
{
 return(-1) if(scalar(@_) != 3);
 my $source = shift;
 my $type   = shift || 'all';
 my $mode   = shift || 0755;
 my $folder;
 my $counter_strike = 0;
 my $chmod_root = 0;
 my $q_slash = quotemeta($system_slash);
 
 # Repair wrong slashes: \\ to / in Unix like OS and / to \\ in Dos like OS.
 if($system_slash =~ m/\\/si)
  {
   $source =~ s/\//$system_slash/sg;
  }
 if($system_slash =~ m/\//si)
  {
   $source =~ s/\\/$system_slash/sg;
  }
 
 if(-d $source)
  {
   if(!($source =~ m/$q_slash$/s))
   { 
    $source =~ m/([^\:$q_slash]+)$/s;    
    $chmod_root = 1;
   }
   $source =~ s/$q_slash$//s;
   
   @deepWalk = ();
   &deepWalk($source);
   unshift(@deepWalk,'');
   foreach $folder (@deepWalk)
    {
     if($type =~ m/^(all|files)$/si)
      {
       $counter_strike += &dw_chmod_files($source.$folder,$mode);
      }
    }
   
   if (!$chmod_root) {shift(@deepWalk);}
   if($type =~ m/^(all|folders)$/si)
     {
      foreach $folder (reverse(@deepWalk))
       {
        my $orig_mask = umask 0000;
        my ($dev,$ino,$md,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source.$folder);
        if(!chmod($mode,$source.$folder)) {$counter_strike++;}
        utime ($atime, $mtime, $source.$folder);
        umask $orig_mask;
       }
     }
  }
 else
  {
   if($type =~ m/^(all|files)$/si)
     {
      my $orig_mask = umask 0000;
      my ($dev,$ino,$md,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source);
      if(!chmod($mode,$source)) {$counter_strike++;}
      utime ($atime, $mtime, $source);
      umask $orig_mask;
     }
  }
 return($counter_strike);
}

1;