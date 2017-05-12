package Win32::MediaPlayer;

use strict;
use warnings;
use vars qw($VERSION $self $mciSendString $result);
use Win32::API;
$VERSION = '0.3';

BEGIN {
$mciSendString = new Win32::API(
    "winmm",
    "mciSendString",
    ['P', 'P', 'N', 'N'], 'N'
)|| die "Can't register mciSendString";
}


sub new {
my $self = {};
bless $self, $_[0];
$self->{alias} = rand;
$self->{pos} = 0;
$self->{play} = 0;
return $self;
}

sub load {
my $self = shift;
my $file = shift;
$result = doMM("open \"$file\" type mpegvideo alias ".$self->{alias});
return $result;
}

sub play {
my $self = shift;
my $pos = shift || $self->{pos};
$self->{play} = 1;
$result = doMM("play ".$self->{alias}." from $pos");
return $result;
}

sub volume {
my $self = shift;
warn 'No File Loaded' if($self->{play}==0);
my $vol = shift;
if($vol ne '') {
$vol*=10;
$result = doMM("setaudio ".$self->{alias}." volume to $vol");
return $result;
}else{
return 'Null';
}
}

sub length {
my $self = shift;
my $flag = shift;
warn 'No File Loaded' if($self->{play}==0);
$result = doMM("status ".$self->{alias}." length");
if($flag) {
my @time = localtime(int($result/1000));
$result = sprintf("%02d:%02d",$time[1],$time[0]);
}
return $result;
}

sub seek {
my $self = shift;
warn 'No File Loaded' if($self->{play}==0);
my $seektime = shift;
if($seektime=~/(\d{2}):(\d{2})/) {
$seektime = ($1*60+$2)*1000;
doMM("stop audiofile");
$result = doMM("play ".$self->{alias}." from $seektime");
}else{
doMM("stop audiofile");
$result = doMM("play ".$self->{alias}." from $seektime");
}
return $result;
}

sub pos {
my $self = shift;
my $flag = shift;
warn 'No File Loaded' if($self->{play}==0);
$result = doMM("status ".$self->{alias}." position");
if($flag) {
my @time = localtime(int($result/1000));
$result = sprintf("%02d:%02d",$time[1],$time[0]);
}
return $result;
}

sub pause {
my $self = shift;
warn 'No File Loaded' if($self->{play}==0);
$result = doMM("pause ".$self->{alias});
return $result;
}

sub resume {
my $self = shift;
warn 'No File Loaded' if($self->{play}==0);
$result = doMM("resume ".$self->{alias});
return $result;
}

sub close {
my $self = shift;
$self->{play} = 0;
$result = doMM("close ".$self->{alias});
return $result;
}



sub doMM {
my($cmd) = @_;
my $ret = "\0" x 1025;
my $rc = $mciSendString->Call($cmd, $ret, 1024, 0);
if($rc == 0) {
$ret =~ s/\0*$//;
return $ret;
}else{
return "error '$cmd': $rc";
}
}

=pod

=head1 NAME

Win32::MediaPlayer - Module for playing sound MP3 / WMA / WAV / MIDI file on Win32 platforms

=head1 SYNOPSIS

    use Win32::MediaPlayer;

    $winmm = new Win32::MediaPlayer;  # new an object
    $winmm->load('d:/10.mp3');        # Load music file disk, or an URL
    $winmm->play;                     # Play the music
    $winmm->volume(100);              # Set volume after playing
    $winmm->seek('00:32');            # seek to

    #$winmm->pause;                   # Pause music playing
    #$winmm->resume;                  # Resume music playing

    print 'Total Length : '.$winmm->length(1),$/; # Show total time.
    while(1) {
          sleep 1;
          print 'Now Position: '.$winmm->pos(1)."\r";   # Show now time.
    };

=head1 DESCRIPTION

This module allows playing of sound format like MP3 / WMA / WAV / MIDI on Win32 platforms using the MCI interface (which
depends on winmm.dll).

=head1 REQUIREMENTS

Only working on Win32, and you should installed the Win32::API

if not you can install by ppm, in the console mode

type command:

  ppm install http://www.bribes.org/perl/ppm/Win32-API.ppd


=head1 USAGE

=head2 new

The new method is the constructor. It will build a connection to the mci interface.

$winmm = new Win32::MediaPlayer;  # new an object

=head2 load()

$winmm->load('d:/10.mp3');        # Load music from the disk, or Internet URL.

=head2 play

$winmm->play;                     # Play the music file.

=head2 seek()

The value should be a format like XX:XX, or you can fill the micro second integer of the music.

$winmm->seek(100000);             # Seek the music file, at the 100 sec pos.


$winmm->seek('01:40');            # Seek the music file, at the 01 min 40 sec pos.

=head2 close

$winmm->close;                    # Close the music file.

=head2 volume()

The value is from 0 to 100

$winmm->volume(100);              # Set volume to 100 after playing


=head2 length()

Return the music total length


$length = $winmm->length(1);      # Return the length in XX:XX format.

$length = $winmm->length;         # Return the length in micro second integer.

=head2 pos()

Return the music now position

$length = $winmm->pos(1);      # Return the Position in XX:XX format.

$length = $winmm->pos;      # Return the Position in micro second integer.

=head2 pause

Pause the music play

$length = $winmm->pause;      # Pause the music play.

=head2 resume

Resume the music play

$length = $winmm->resume;      # Resume the music play.

=head1 AUTHOR

Lilo Huang

=head1 COPYRIGHT

Copyright 2006 by Lilo Huang All Rights Reserved.

You can use this module under the same terms as Perl itself.

=cut

__END__

1;