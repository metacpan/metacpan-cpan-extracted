package Win32::MultiMedia::Mci;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = ( qw( SendString GetDeviceID GetErrorString ));

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
   
);
$VERSION = '0.01';



bootstrap Win32::MultiMedia::Mci $VERSION;

my $anum=0;

sub open
{
   my ($this, $dev, %args)= @_;
   $args{alias} ||= "a".$anum++; #give unique alias
   # convert incoming true/false to single args
   for my $univ (qw(shareable wait))    {
      $args{$univ} ? $args{$univ}="" : delete($args{$univ});
   }
   my $ret = SendString("open $dev ".join (" ", %args));
   my $self = {_alias => $args{alias}, _device =>$dev, _error=>$ret, %args};
   ref($this)?$this:bless($self, $this);
}

sub can
{
   my ($self, $cap)= @_;
   my $dev =$self->{_alias};
   my ($a) = SendString("capability $dev can $cap",1);   
}

sub device{$_[0]->{_device}}

sub error
{
   my ($self, $err)= @_;
   $self->{_error} && GetErrorString($err || $self->{_error});
}

sub send
{
   SendString($_[1],$_[2]);
}

##  Just using AUTOLOAD because all the methods are identical 
# but will probably change.
# The real release will most likely not use AUTOLOAD for everything
AUTOLOAD
{
   if ($AUTOLOAD =~ s/.*:://g)
   {
      no strict;
      eval qq {
       sub $AUTOLOAD {
         my (\$self, \@args) = \@_;
         my \$dev = \$self->{_alias};
         my \$ret=0;
         (\$ret, \$self->{_error}) = SendString("$AUTOLOAD \$dev ".join(" ",\@args),1);
         return \$self->{_error} || \$ret;
       }
      };
      &$AUTOLOAD(@_);
      
   }

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Win32::MultiMedia::Mci - Perl extension for the MCI MultiMedia system on Win32 
platforms.

=head1 SYNOPSIS

  use Win32::MultiMedia::Mci;
   my $k = Win32::MultiMedia::Mci->open("..\\k.wav");
   $k->play(wait);
   $k->close;

   #Play the the cd-rom
   my $k = Win32::MultiMedia::Mci->open("cdaudio");
   $k->play;
   print "press enter to stop\n";
   $t= <STDIN>;
   $k->stop;
   $k->close;


=head1 DESCRIPTION

=head1 Non OO


   Win32::MultiMedia::Mci::SendString("command string", bool);
   
      You can import this with:
         use Win32::MultiMedia::Mci(SendString);

      If bool is true, it returns an array containing the 
         result of the action along with the error code.  

         my ($value, $errornumber) = SendString("status mode cdaudio",1);

      For valid command strings, goto:
      http://msdn.microsoft.com/library/default.asp?URL=/library/psdk/multimed/mci_04dv.htm

       Example:
         SendString("open count.avi alias avi1");
         SendString("play avi1 wait");
         SendString("close avi1");

   

=head1 OO Methods


   All methods return 0 if sucessfull or an error number on 
      failure. Use $obj->error($num) to get the error string.

   All methods can take a flag called "wait" which tells the 
      command not to return until done.    

   $mci = Win32::MultiMedia::Mci->open( device, [option => value]* );

      Opens the device with the the given attributes.

         "device" can be:
            The name of a sound file of a MediaPlayer-recognized 
               type such as WAV, MP3, MID, AU, AVI etc.

            A system device such as "cdaudio", "sequencer", or 
               "digitalvideo".

            The keyword "new".

         options:
            "type": used with a device of "new" can take 
               values like "waveaudio".

            "alias": used to give the device opened an alias,
               this option isn't very useful in the OO form.

            "buffer": number of seconds to buffer.

            "style": used with digitalvideo (AVI). 
               values can be "child", "overlapped", or "popup"

            "parent": used with digitalvideo (AVI) to specify the 
               container window.  Value is a hwnd.  
                  In perlTk, get this with "hex($widget->id)"

            "shareable": used with cdaudio and devices. 
               Takes 0/1 value.

            "wait": tells the command not to return until done.
                Takes 0/1 value.   

     $mci->play( [option [=> value]]* );

         All devices:
            "from": start at the position given.
            "to":  stop at the position given.

            "wait": tells the command not to return until done.

         digitalvideo:
            "fullscreen": use fullscreen mode for compressed files.
            "repeat": loop the playback.
            "reverse": play backward. "from" does not work with 
               this flag.

         videodisc:            
            "fast": play the disc faster than normal.
            "slow": play the disc slower than normal.
            "speed":  specify the exact frames/sec to go.
            "scan": play as fast as possible with video.
            "reverse": reverse play.

         vcr (What? You don't have a VCR on *your* computer?):
            "at": specify 
            "scan": play as fast as possible with video.
            "reverse": reverse play.

   $mci->record( options )
      records on the device.

      waveaudio:
         from => position :  start at position
         to => position  :  stop at position
         insert :  new data is added
         overwrite : overwrite the old data
      
      digitalvideo:
         from => position :  start at position
         to => position  :  stop at position
         insert :  new data is added
         overwrite : overwrite the old data

   $mci->save(filename)
      Saves the recorded/modified data to filename.
 

   $mci->seek( to => position )
      "position" can be the keywords "start" or "end" 
            or a number.  Equivilent to $mci->play(from => position);  
      
       vcr can take:
          at => time  or  mark => marknum  or  "reverse"

       videodisc can take "reverse"
         
   
   $mci->stop()

      Stops the device.


   $mci->close()

      Closes the open device and all resources used by it.


   $mci->set(options)
    
         $mci->set("time format tmsf");

http://msdn.microsoft.com/library/default.asp?URL=/library/psdk/multimed/mmcmdstr_8eyc.htm

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut

