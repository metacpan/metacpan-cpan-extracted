#######################################################
# Perl`s Download Library
# This is a part of WebTools library!
#######################################################
# Ver 4.0
#######################################################
use strict;

my %sys_MIMETYPES = ('zip','application/zip','exe','application/octet-stream','doc','application/msword',
              'report','application/zip','mpga','audio/mpeg','mp3','audio/mpeg','gz','application/x-gzip',
              'gzip','application/x-gzip','xls','application/vnd.ms-excel');
my $sys_kill_flag = 0;
my $sys_length = 2048;
my $sys_period = 1;
my $sys_last_sent_byte;
$webtools::loaded_functions = $webtools::loaded_functions | 256;
#######################################################
# CGI based download function
# PROTO:
# $result = download_file($full_filename, $speed_limit);
# Example:
# $res = download_file('/downloads/unix.tar.gz','20');
# Where:
# '/downloads/unix.tar.gz' is full file name
# and '20' is speed limit in KB
#######################################################
sub download_file
{
 my ($filename,$speed) = @_;
 my ($name,$ext);
 if(($filename =~ m/^.*\.(.*)$/s))
   {
    $ext = $1;
   }
 else 
   {
    $ext = '';
   }
 my $type = $sys_MIMETYPES{$ext};
 if (($type eq '') or($ext eq '')) { $type = 'application/octet-stream'; }
 if (downloader_SendFile($filename,$type,$speed))
   {
    return(1);                    # Done!
   }
 else { return (0); }             # Transfer interrupted...or Apache kill process!
 # If Apache start killing..., Mole get exit NOW! :-))))
}

#######################################################
# CGI based download function
# PROTO:
# $result = download_mem_file($filename, $buffer, $speed_limit);
# Example:
# $res = download_file($filename,'some message','20');
#######################################################
sub download_mem_file
{
 my ($filename,$buffer,$speed) = @_;
 my ($name,$ext);
 if(($filename =~ m/^.*\.(.*)$/s))
   {
    $ext = $1;
   }
 else 
   {
    $ext = '';
   }
 my $type = $sys_MIMETYPES{$ext};
 if (($type eq '') or ($ext eq '')) { $type = 'application/octet-stream'; }
 if (downloader_SendMemFile($filename,$buffer,$type,$speed))
   {
    return(1);                    # Done!
   }
 else { return (0); }             # Transfer interrupted...or Apache kill process!
 # If Apache start killing..., Mole get exit NOW! :-))))
}

#######################################################
# Add new MIME type
# PROTO:  download_add_mimetype($ext,$mimetype);
# Example:
# download_add_mimetype('zip','application/zip');
#######################################################
sub download_add_mimetype
{
 my ($ext,$mimetype) = @_;
 $ext =~ s/\.//sgi;
 $ext =~ s/^\ //sgi;
 $ext =~ s/\ {1,}$//sgi;
 $mimetype =~ s/^\ //sgi;
 $mimetype =~ s/\ {1,}$//sgi;
 if(($mimetype ne '') and ($ext ne ''))
  {
   $sys_MIMETYPES{$ext} = $mimetype;
  }
}
#######################################################
# Get file site of download target
# PROTO:  $size = download_get_filesize($filename);
# Example:
# $size = download_get_filesize('/downloads/file.zip');
#######################################################
sub download_get_filesize
{
 my ($file) = shift(@_);
 use POSIX;
 $file =~ s/\\/\//sgi;
 $file =~ s/^\ //sgi;
 $file =~ s/\ {1,}$//sgi;
 if(-e $file)
  {
   local *GETFSIZE;
   open(GETFSIZE,$file) or return(-1); # Error or just locked
   seek(GETFSIZE,0,SEEK_END);
   my $size = tell(GETFSIZE);
   close(GETFSIZE);
   return($size);
  }
 return(-1);   # File not found
}
#######################################################
# Get file size of download target
# PROTO:  $size = download_last_bytes();
# Example:
# $size = download_last_bytes();
#######################################################
sub download_last_bytes
{
 return($sys_last_sent_byte);
}
#######################################################
sub downloader_onApacheKill
{
 $sys_kill_flag = 1;
}
#######################################################
# Read and Send file to STDOUT
#######################################################
sub downloader_SendFile
{
 my ($filename,$type,$speed) = @_;
 my $name;
 $sys_last_sent_byte = 0;
 if($speed) {$speed = int($speed*1024);}
 if($filename =~ m/\//)
  {
   $filename =~ m/^.*\/(.*)$/;
   $name = $1;
  }
 else { $name = $filename; }

 local $SIG{'TERM'} = '\&downloader_onApacheKill';   # Don`t allow Apache to kill process!
 local $SIG{'QUIT'} = '\&downloader_onApacheKill';
 local $SIG{'PIPE'} = '\&downloader_onApacheKill';
 local $SIG{'STOP'} = '\&downloader_onApacheKill';
 
 $sys_kill_flag = 0;
 $| = 1;
 open(FH,$filename) or return(0);
 binmode(FH);
 binmode(STDOUT);
 
 eval '$stdouthandle::sys_stdouthandle_header = 1;';
  
 print "MIME-Type: 1.0\n";
 print "X-Powered-By: WebTools/1.27\n";
 print "Content-Disposition: filename=\"$name\"\n";
 print "Content-Transfer-Encoding: binary\n";
 print "Content-Type: ".$type.";name=\"$name\"\n\n";
 my $buffer = '';
 if($speed){$sys_length = downloader_setSpeed($speed);}
 while(1)
   {
    if($sys_kill_flag == 1) { return(0);}  # Killed!
    my $result = read(FH,$buffer,$sys_length);
    if($result == 0)
      {
       last;
      }
    if($result eq undef)               # Error!
      {
       close FH;
       return(0);
      }
    if(!(print STDOUT $buffer))
      {
       close FH;
       return(0);
      }
    $sys_last_sent_byte += $sys_length;
    if($speed){sleep($sys_period);}
   }
 close FH;
 return(1);           		       # Done...
}
#######################################################
# Send memmory buffer as file to STDOUT
#######################################################
sub downloader_SendMemFile
{
 my ($filename,$buffer,$type,$speed) = @_;
 my $name;
 $sys_last_sent_byte = 0;
 if($speed) {$speed = int($speed*1024);}
 if($filename =~ m/\//)
  {
   $filename =~ m/^.*\/(.*)$/;
   $name = $1;
  }
 else { $name = $filename; }

 local $SIG{'TERM'} = '\&downloader_onApacheKill';   # Don`t allow Apache to kill process!
 local $SIG{'QUIT'} = '\&downloader_onApacheKill';
 local $SIG{'PIPE'} = '\&downloader_onApacheKill';
 local $SIG{'STOP'} = '\&downloader_onApacheKill';
 
 $sys_kill_flag = 0;
 $| = 1;

 binmode(STDOUT);
 
 eval '$stdouthandle::sys_stdouthandle_header = 1;';
  
 print "MIME-Type: 1.0\n";
 print "X-Powered-By: WebTools/1.27\n";
 print "Content-Disposition: filename=\"$name\"\n";
 print "Content-Transfer-Encoding: binary\n";
 print "Content-Type: ".$type.";name=\"$name\"\n\n";
 my $all_data = $buffer;
 $buffer = '';
 if($speed){$sys_length = downloader_setSpeed($speed);}
 while(1)
   {
    if($sys_kill_flag == 1) { return(0);}  # Killed!
    my $result;

    # $buffer - currently processing piece of code
    # $result - how many byte(s) are read
    ($result,$all_data,$buffer) = downloader_mem_read($all_data,$sys_length);
    if($result == 0)
      {
       last;
      }
    if($result eq undef)               # Error!
      {
       return(0);
      }
    if(!(print STDOUT $buffer))
      {
       return(0);
      }
    $sys_last_sent_byte += $sys_length;
    if($speed){sleep($sys_period);}
   }
 return(1);           		       # Done...
}
sub downloader_setSpeed
{
  my $speed=shift;

  return(int($speed*$sys_period));
}

sub downloader_mem_read
{
 my ($buffer,$sys_length) = @_;
 my $ln = length($buffer);

 if($ln == 0) {return((0,'',''));}
 if($ln <= $sys_length) {return(($ln,'',$buffer));}
 my $data = substr($buffer,0,$sys_length);

 return(($sys_length,substr($buffer,$sys_length),$data));
}

1;