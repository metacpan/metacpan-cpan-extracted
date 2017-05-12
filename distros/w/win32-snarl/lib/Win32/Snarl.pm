package Win32::Snarl;

use 5.008000;
use strict;
use warnings;

our @ISA = qw();
our $VERSION = '1.01';

use Carp;
use Win32::GUI ();

# Windows message number
use constant WM_COPYDATA  => 0x04a;
use constant WM_USER      => 0x400;
use constant WM_SNARLTEST => WM_USER + 237;

# Snarl Commands
use constant SNARL_SHOW                     => 1;
use constant SNARL_HIDE                     => 2;
use constant SNARL_UPDATE                   => 3;
use constant SNARL_IS_VISIBLE               => 4;
use constant SNARL_GET_VERSION              => 5;
use constant SNARL_REGISTER_CONFIG_WINDOW   => 6;
use constant SNARL_REVOKE_CONFIG_WINDOW     => 7;
use constant SNARL_REGISTER_ALERT           => 8;
use constant SNARL_REVOKE_ALERT             => 9;
use constant SNARL_REGISTER_CONFIG_WINDOW_2 => 10;
use constant SNARL_EX_SHOW                  => 32;

# Global Events
use constant SNARL_LAUNCHED       => 1;
use constant SNARL_QUIT           => 2;
use constant SNARL_ASK_APPLET_VER => 3;
use constant SNARL_SHOW_APP_UI    => 4;

# Notification Events
use constant SNARL_NOTIFICATION_CLICKED   => 32;
use constant SNARL_NOTIFICATION_TIMED_OUT => 33;
use constant SNARL_NOTIFICATION_ACK       => 34;
use constant SNARL_NOTIFICATION_CANCELLED => 32;

# Error Responses
use constant M_NOT_IMPLEMENTED => 0x80000001;
use constant M_OUT_OF_MEMORY   => 0x80000002;
use constant M_INVALID_ARGS    => 0x80000003;
use constant M_NO_INTERFACE    => 0x80000004;
use constant M_BAD_POINTER     => 0x80000005;
use constant M_BAD_HANDLE      => 0x80000006;
use constant M_ABORTED         => 0x80000007;
use constant M_FAILED          => 0x80000008;
use constant M_ACCESS_DENIED   => 0x80000009;
use constant M_TIMED_OUT       => 0x8000000a;
use constant M_NOT_FOUND       => 0x8000000b;
use constant M_ALREADY_EXISTS  => 0x8000000c;

# C Struct Formats
use constant PACK_FORMAT    => 'l4a1024a1024a1024';
use constant PACK_FORMAT_EX => 'l4a1024a1024a1024 a1024a1024a1024l2';

# Subroutines

sub _Dump {
  my ($mem) = @_;

  unpack('H2' x length($mem), $mem);
}

sub _Test {
  my $hwnd = GetSnarlWindow() or return M_FAILED;
  Win32::GUI::SendMessage($hwnd, WM_SNARLTEST, 0, 0);
}

sub _SendMessage {
  my ($struct) = @_;

  my $hwnd = GetSnarlWindow() or return M_FAILED;
  my $cd  = pack 'L2P', 2, length $struct, $struct;
  my $res = Win32::GUI::SendMessage($hwnd, WM_COPYDATA, 0, $cd);

  if (my $err = _Error($res)) {
    croak $err;
  }

  $res;
}

sub _MakeString {
  my ($data) = @_;

  substr($data, 0, 1023);
}

sub _MakeStruct {
  my %params = @_;

  my @fields = qw[command id timeout data title text icon];

  $params{$_} ||= 0 for qw[command id timeout data];
  $params{$_} = _MakeString($params{$_} || '') for qw[title text icon];

  pack PACK_FORMAT, @params{@fields};
}

sub _MakeStructEx {
  my %params = @_;

  my @fields = qw[command id timeout data title text icon class extra extra2 reserved1 reserved2];

  $params{$_} ||= 0 for qw[command id timeout data reserved1 reserved2];
  $params{$_} = _MakeString($params{$_} || '') for qw[title text icon class extra extra2];

  pack PACK_FORMAT_EX, @params{@fields};
}

sub _Error {
  my ($value) = @_;

  $value += 0xffffffff if $value < 0;

  my %errors = (
    0x80000001 => 'Not Implemented',
    0x80000002 => 'Out of Memory',
    0x80000003 => 'Invalid Arguments',
    0x80000004 => 'No Interface',
    0x80000005 => 'Bad Pointer',
    0x80000006 => 'Bad Handle',
    0x80000007 => 'Aborted',
    0x80000008 => 'Failed',
    0x80000009 => 'Access Denied',
    0x8000000a => 'Timed Out',
    0x8000000b => 'Not Found',
    0x8000000c => 'Already Exists',
  );

  return $errors{$value};
}

=head1 NAME

Win32::Snarl - Perl extension for Snarl notifications

=head1 SYNOPSIS

  use Win32::Snarl;

  Win32::Snarl::ShowMessage('Perl', 'Perl is awesome, so is Snarl.');

  my $msg_id = Win32::Snarl::ShowMessage('Time', 'The time is now ' . (scalar localtime));
  while (Win32::Snarl::IsMessageVisible($msg_id)) {
    sleep 1;
    Win32::Snarl::UpdateMessage($msg_id, 'Time', 'The time is now ' . (scalar localtime));
  }

=head1 DESCRIPTION

Snarl E<lt>http://www.fullphat.net/E<gt> is a notification system inspired by
Growl E<lt>http://growl.info/E<gt> for Macintosh that lets applications display
nice alpha-blended messages on the screen.

C<Win32::Snarl> is the perl interface to Snarl.

=head1 NORMAL METHOD INTERFACE

=cut

sub GetAppPath    { M_NOT_IMPLEMENTED }
sub GetGlobalMsg  { M_NOT_IMPLEMENTED }
sub GetIconsPath  { M_NOT_IMPLEMENTED }
sub GetVersion    { M_NOT_IMPLEMENTED }
sub SetTimeout    { M_NOT_IMPLEMENTED }

=head2 GetSnarlWindow()

Returns a handle to the current Snarl Dispatcher window, or zero if it wasn't 
found. This is the recommended way to test if Snarl is running or not.

=cut

sub GetSnarlWindow {
  # no parameters

  my $hwnd = Win32::GUI::FindWindow('', 'Snarl');
  return unless Win32::GUI::IsWindow($hwnd);

  return $hwnd;
}

=head2 GetVersionEx()

Returns the Snarl system version number. This is an integer value which 
represents the system build number and can be used to identify the specific 
version of Snarl running. Of course, as this function is only available as of 
Snarl V37, if calling it returns zero (or an M_RESULT value) you should use 
C<GetVersion> to determine which pre-V37 version of Snarl is installed.

=cut

sub GetVersionEx {
  # no parameters

  _SendMessage(_MakeStruct(
    command => SNARL_GET_VERSION,
  ));
}

=head2 HideMessage($id)

Hides the notification specified by $id. $id is the value returned by 
C<ShowMessage> or C<ShowMessageEx> when the notification was initially created. 
This function returns True if the notification was successfully hidden or False 
otherwise (for example, the notification may no longer exist).

=cut

sub HideMessage {
  my ($id) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_HIDE,
    id => $id,
  ));
}

=head2 IsMessageVisible($id)

Returns True if the notification specified by $id is still visible, or False if 
not. $id is the value returned by c<ShowMessage> or c<ShowMessageEx> when the 
notification was initially created.

=cut

sub IsMessageVisible {
  my ($id) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_IS_VISIBLE,
    id => $id,
  ));
}

=head2 RegisterAlert($application, $class)

Registers an alert of $class for application $application which must have 
previously been registered with either C<RegisterConfig> or C<RegisterConfig2>.
$class is displayed in the Snarl Preferences panel so it should be people 
friendly ("My cool alert" as opposed to "my_cool_alert").

If $application isn't registered you'll get M_NOT_FOUND returned. Other 
possible return values are M_FAILED if Snarl isn't running, M_TIMED_OUT if 
Snarl couldn't process the request quickly enough, or M_ALREADY_EXISTS if the 
alert has already been registered. If all went well, M_OK is returned.

=cut

sub RegisterAlert {
  my ($application, $class) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_REGISTER_ALERT,
    title => $application,
    text => $class,
  ));
}

=head2 RegisterConfig($hwnd, $application, $reply)

Registers an application's configuration interface with Snarl. $application is 
the text that's displayed in the Applications list so it should be people 
friendly ("My cool app" rather than "my_cool_app"). Also, it really should 
match the name of the application as when a user runs an application called 
"MyCoolApp.exe" they'd expect to see that appear in the Applications list and 
not "Titanics Cruncher 1.1".

As of V37, if the user double-clicks the application's entry in the Preferences 
panel, one of two things can happen: if the window specified in $hwnd has a 
title then it is simply displayed by Snarl - this is to maintain backwards 
compatability with previous releases of Snarl. If, however, the window has no 
title and $reply is non-zero then Snarl sends $reply to the window specified in 
$hwnd with SNARL_SHOW_APP_UI in wParam.

Be sure to call C<RevokeConfig> when your application exits. If you fail to do 
this, your application will remain orphaned in Snarl's Preferences panel until 
the user quits Snarl.

=cut

sub RegisterConfig {
  my ($hwnd, $application, $reply) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_REGISTER_CONFIG_WINDOW,
    id => $reply,
    data => $hwnd,
    title => $application,
  ));
}

=head2 RegisterConfig2($hwnd, $application, $reply, $icon)

Registers an application's configuration interface with Snarl. This function is 
identical to C<RegisterConfig> except that $icon can be used to specify a PNG 
image which will be displayed against the application's entry in Snarl's 
Preferences panel.

Be sure to call C<RevokeConfig> when your application exits. If you fail to do 
this, your application will remain orphaned in Snarl's Preferences panel until 
the user quits Snarl.

=cut

sub RegisterConfig2 {
  my ($hwnd, $application, $reply, $icon) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_REGISTER_CONFIG_WINDOW_2,
    id => $reply,
    data => $hwnd,
    title => $application,
    icon => $icon,
  ));
}

=head2 RevokeConfig($hwnd)

Removes the application previously registered using C<RegisterConfig> or 
C<RegisterConfig2>. $hwnd should be the same as that used during registration. 
Typically this is done as part of an application's shutdown procedure.

This function returns M_OK on success. Other possible return values are 
M_FAILED if Snarl isn't running, M_TIMED_OUT if Snarl couldn't process the 
request quickly enough or M_NOT_FOUND if the application wasn't already 
registered.

=cut

sub RevokeConfig {
  my ($hwnd) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_REVOKE_CONFIG_WINDOW,
    data => $hwnd,
  ));
}

=head2 ShowMessage($title, $text, $timeout, $icon, $hwnd, $reply)

Displays a message with $title and $text. $timeout controls how long the 
message is displayed for (in seconds) (omitting this value means the message is 
displayed indefinately). $icon specifies the location of a PNG image which will 
be displayed alongside the message text.

$hwnd and $reply identify the handle of a window and a Windows message 
respectively. If both are provided then $reply will be sent to $hwnd if the 
user right- or left-clicks the message, or the message times out. In each 
instance the wParam value of the message will be set to one of the following 
values:

  Right Click         SNARL_NOTIFICATION_CLICKED
  Left Click          SNARL_NOTIFICATION_ACK
  Interval Expires    SNARL_NOTIFICATION_TIMED_OUT

If all goes well this function returns a value which uniquely identifies the 
new notification. Other possible return values are M_FAILED if Snarl isn't 
running, or M_TIMED_OUT if Snarl couldn't process the request quickly enough.

=cut

sub ShowMessage {
  my ($title, $text, $timeout, $icon, $hwnd, $reply) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_SHOW,
    id => $reply,
    timeout => $timeout,
    data => $hwnd,
    title => $title,
    text => $text,
    icon => $icon,
  ));
}

=head2 ShowMessageEx($class, $title, $text, $timeout, $icon, $hwnd, $reply, $sound)

Displays a notification. This function is identical to C<ShowMessage> except 
that $class specifies an alert previously registered with C<RegisterAlert> and 
$sound can optionally specify a WAV sound to play when the notification is 
displayed on screen.

$sound can either be a filename to a specific sound to play, or it can 
represent a system sound. To play a system sound, prefix the name of the sound 
with a '+' symbol. For example, to play the default 'Mail Received' system 
sound, you would specify "+MailBeep" in SoundFile. System sounds are listed 
under C<HKEY_CURRENT_USER\AppEvents\EventLabels> in the Registry. Note that if 
an existing sound is being played, the requested sound may not be played, 
although the notification will still be displayed.

If all goes well this function returns a value which uniquely identifies the 
new notification. Other possible return values are M_FAILED if Snarl isn't 
running, M_TIMED_OUT if Snarl couldn't process the request quickly enough, 
M_BAD_HANDLE or M_NOT_FOUND if the application isn't registered with Snarl or 
M_ACCESS_DENIED if the user has blocked the notification class within Snarl's 
preferences.

=cut

sub ShowMessageEx {
  my ($class, $title, $text, $timeout, $icon, $hwnd, $reply, $sound) = @_;

  _SendMessage(_MakeStructEx(
    command => SNARL_EX_SHOW,
    id => $reply,
    timeout => $timeout,
    data => $hwnd,
    title => $title,
    text => $text,
    icon => $icon,
    class => $class,
    extra => $sound,
  ));
}

=head2 UpdateMessage($id, $title, $text, $icon)

Changes the title and text in the message specified by $id to the values 
specified by $title and $text respectively. $id is the value returned by 
C<ShowMessage> or C<ShowMessageEx> when the notification was originally 
created. To change the timeout parameter of a notification, use C<SetTimeout>

If all goes well this function returns M_OK. Other possible return values are 
M_FAILED if Snarl isn't running, M_TIMED_OUT if Snarl couldn't process the 
request quickly enough or M_NOT_FOUND if the specified notification wasn't 
found.

=cut

sub UpdateMessage {
  my ($id, $title, $text, $icon) = @_;

  _SendMessage(_MakeStruct(
    command => SNARL_UPDATE,
    id => $id,
    title => $title,
    text => $text,
    icon => $icon,
  ));
}

=head1 OBJECT INTERFACE

There is also an object interface to this module but it is a work in progress.

=head1 KNOWN ISSUES

Currently, the C<ShowMessageEx> function gets a M_BAD_POINTER response and does
not function.  This makes C<RegisterConfig>, C<RegisterConfig2>, and 
C<RegisterAlert> pretty useless.

=head1 SEE ALSO

C<Win32::GUI> For Windows API Calls

Snarl Documentation E<lt>http://www.fullphat.net/dev/E<gt>

=head1 AUTHOR

Alan Berndt, E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alan Berndt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
