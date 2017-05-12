package Win32::MCI::CD;

use warnings;
use strict;

require 5;

our $VERSION = "0.02";

use Win32::API;
use Carp;


###########################################################################
###
### Define variables for this module.
###
###########################################################################

my $mci_sendstring = new Win32::API("winmm.dll", "mciSendStringA", ['P', 'P', 'N', 'N'], 'N') || croak "Creating api call mciSendStringA failed";
my $mci_error = new Win32::API("winmm.dll", "mciGetErrorStringA", ['N', 'P', 'N'], 'N') || croak "Creating api call mciGetErrorStringA failed";
my $last_error = 0;


###########################################################################
###
### Construct our object.
###
###########################################################################

sub new {
 my $class = shift;
 my %parms = @_;
 my $self;
 if(!defined $parms{-aliasname}) { croak "Option -aliasname was ignored";}
 if(!defined $parms{-drive}) { croak "Option -drive was ignored";}
 %{$self} = %parms;
 bless $self, $class;
 return $self;
}


###########################################################################
###
### Functions below are used by the module itself.
### 
###########################################################################

sub strip_spaces { return unpack('A*', shift); }

sub sendstring
{
 my $command = shift; 
 my $return_string = " " x 256;
 my $return = $mci_sendstring->Call($command, $return_string, length($return_string), 0);
 return ($return, strip_spaces($return_string));
}


###########################################################################
###
### Functions below can be called by user, as methods.
### 
###########################################################################

sub cd_opendevice
{
 my $self = shift; 
 my $drive = $self->{-drive};
 my $namedevice = $self->{-aliasname}; 
 my $ret = (sendstring("open $drive type cdaudio ALIAS $namedevice wait shareable"))[0];
 if($ret != 0) { $last_error = $ret; return 0;}
 return 1;
}

sub cd_closedevice
{
 my $self = shift;
 my $namedevice = $self->{-aliasname}; 
 my $ret = (sendstring("close $namedevice"))[0];
 if($ret != 0) { $last_error = $ret; return 0;}
 return 1;
}

sub cd_getlasterror
{
 my $self = shift;
 my $return_string = " " x 128;
 my $return = $mci_error->Call($last_error, $return_string, length($return_string));
 return ($last_error, strip_spaces($return_string));
}

sub cd_mode_milliseconds
{
 my $self = shift;
 my $namedevice = $self->{-aliasname}; 
 my $ret = (sendstring("set $namedevice time format milliseconds wait"))[0]; 
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_mode_tmsf
{
 my $self = shift;
 my $namedevice = $self->{-aliasname}; 
 my $ret = (sendstring("set $namedevice time format tmsf wait"))[0]; 
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_play
{
 my ($self, $pos) = @_;
 my $namedevice = $self->{-aliasname}; 
 my $ret;
 if($pos)
 { 
  $ret =  (sendstring("play $namedevice from $pos"))[0];
  if($ret != 0) { $last_error = $ret; return 0; }
 }
 else
 {
  $ret =  (sendstring("play $namedevice"))[0];
  if($ret != 0) { $last_error = $ret; return 0; }
 }
 return 1;
}

sub cd_stop
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my $ret = (sendstring("stop $namedevice"))[0];
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_pause
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my $ret = (sendstring("pause $namedevice"))[0];
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_status
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my ($ret, $status) = sendstring("status $namedevice mode");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $status;
}

sub cd_currentpos
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my ($ret, $pos) = sendstring("status $namedevice position");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $pos;
}

sub cd_tracklength
{
 my ($self, $track) = @_;
 my $namedevice = $self->{-aliasname};
 my ($ret, $length) = sendstring("status $namedevice length track $track");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $length; 
}

sub cd_cdlength
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my ($ret, $length) = sendstring("status $namedevice length wait");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $length;
}

sub cd_tracks
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my ($ret, $tracks) = sendstring("status $namedevice number of tracks wait");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $tracks;
}

sub cd_opentray
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my $ret = (sendstring("set $namedevice door open"))[0];
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_closetray
{
 my $self = shift;
 my $namedevice = $self->{-aliasname}; 
 my $ret = (sendstring("set $namedevice door closed"))[0];
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1;
}

sub cd_present
{
 my $self = shift;
 my $namedevice = $self->{-aliasname};
 my ($ret, $status) = sendstring("status $namedevice media present");
 if($ret != 0) { $last_error = $ret; return 0; }
 return $status;
}

sub cd_seek
{
 my ($self, $pos) = @_;
 my $namedevice = $self->{-aliasname};
 my $ret = (sendstring("seek $namedevice to $pos"))[0];
 if($ret != 0) { $last_error = $ret; return 0; }
 return 1; 
}

1;

__END__

###########################################################################
###
### Documentation
### 
###########################################################################


=head1 NAME

Win32::MCI::CD - Play and control audio cd's via MCI API

=head1 SYNOPSIS

    use Win32::MCI::CD;
 
    my $cd = new Win32::MCI::CD(-aliasname => 'our_cd', -drive => 'f:');
    
    $cd->cd_opendevice();
    $cd->cd_mode_tmsf();
    $cd->cd_play(3);
    $cd->cd_closedevice();


=head1 ABSTRACT

With this module you can play and control audio cd's via the MCI API.

=head1 DESCRIPTION

=head2 Constructor

=over 4

=item new Win32::MCI::CD(-aliasname => $aliasname, -drive => $drive)

Constructor for a new object. The option -aliasname is a reference for
the MCI API. Since the module opens devices shareable you may create more
constructors, as long as you use unique alias names. Use sensible
characters for $aliasname, no spaces. The option -drive gives you the
possibility to select your cd-rom. The variable $drive is DOS formatted,
e.g. "f:".

=back

=head2 Methods

=over 4

=item cd_opendevice()

First open the device before you do anything. Returns 1 if the operation 
was a success, 0 if the operation failed.

=item cd_closedevice()

Closes the device. Always use this method if you stop using the
device. Notice that this method doesn't stop the cd playing. Returns 1 
if the operation was a succes, 0 if the operation failed.

=item cd_getlasterror()

If a method returns 0 you can use this method to get the last
error. This method returns an array with two elements. The first 
element is the MCI error number. The second element is the MCI error
description. Notice that the description is in the language of your OS.

=item cd_mode_milliseconds()

You can use two time formats. If you call this method before you call 
a time related method, e.g. cd_getcurrentpos, the time format is in 
milliseconds. Returns 1 if the operation was a success, 0 if the operation 
failed.

=item cd_mode_tmsf()

If you call this method before you call a time related method the time 
format is "TT:MM:SS:FF". Track, minutes, seconds, frames. Returns 1 if 
the operation was a success, 0 if the operation failed.

=item cd_play($pos)

This method starts playing the cd at the given position $pos. The position
format depends on the time format. If you have called cd_mode_tmsf before,
the format of $pos may be "1" for track one or "01:02" for track one at two 
minutes. The variable $pos must be in milliseconds if you have called 
cd_mode_milliseconds before. You may omit the position argument.

=item cd_stop()

This method stops playing the cd. Returns 1 if the operation was a success,
0 if the operation failed.

=item cd_pause()

This method pauses the currently playing cd.  Returns 1 if the operation was 
a success, 0 if the operation failed. To start playing again use cd_play
without an argument.

=item cd_status()

This method returns the status. Returns "playing" if the cd is playing,
"stopped" if the cd has stopped and 0 if the operation failed. There may 
be more values, but this is what I got back.

=item cd_currentpos()

This method returns the current position of the playing cd. The format of the
returned value is "TT:MM:SS:FF" if the method cd_mode_tmsf was called before.
If method cd_mode_milliseconds was called before, the returned value is the
current position in milliseconds. The method returns 0 if the operation
failed.

=item cd_tracklength($track)

This method returns the length of the given track. The returned value has the
format "MM:SS:FF" if method cd_mode_tmsf was called before. If method
cd_mode_milliseconds was called before the returned value is the track length 
in milliseconds. The method returns 0 if the operation failed.

=item cd_length()

This method returns the total length of the cd. The returned value has the
format "MM:SS:FF" if method cd_mode_tmsf was called before. If method
cd_mode_milliseconds was called before, the returned value is the cd length 
in milliseconds. The method returns 0 if the operation failed.

=item cd_tracks()

This method returns the number of tracks. The returned value is 0 if the
operation failed.

=item cd_opentray()

This method opens the cd-rom tray. Some cd-rom players don't support this
feature. Returns 1 if the operation was a success, 0 if the operation 
failed.

=item cd_closetray()

This method closes the cd-rom tray. Some cd-rom players don't support this
feature. Returns 1 if the operation was a success, 0 if the operation 
failed.

=item cd_present()

This method returns "true" (B<as a string!>) if there is a cd in the player,
"false" if there isn't a cd in the player. Returns 0 if the operation
failed.

=item cd_seek($pos)

This method points the laser at the given position. Use this method when
your cd is not playing. The method cd_play without an argument starts 
playing from the given position. See method cd_play for the position format.

=back

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 REQUIRED MODULES

C<Win32::API>

=head1 SEE ALSO

C<Win32::MCI::Basic>, fire MCI commands directly.

C<Win32::DriveInfo>, check if a drive is a cd-rom player.

=head1 AUTHOR

Lennert Ouwerkerk <lennert@kabelfoon.nl>

=head1 COPYRIGHT

Copyright (C) 2002 Lennert Ouwerkerk. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

