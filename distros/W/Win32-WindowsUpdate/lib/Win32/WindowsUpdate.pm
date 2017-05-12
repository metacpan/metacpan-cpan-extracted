package Win32::WindowsUpdate;

use strict;
use warnings;
use Win32::OLE qw(in);
use Win32::TieRegistry (Delimiter => '/');

our $VERSION = '0.04';

=head1 NAME

Win32::WindowsUpdate - Access to Windows Update functions

=head1 DESCRIPTION

Provides the ability to see installed and available (not installed) Windows Updates as well as install them.
It provides other features, such as the ability to disable/enable automatic reboot of the computer when users are logged on.
Read the list of methods below to see the available features.

If a feature is missing, request it!
File a "wishlist" bug on the CPAN bug tracker or shoot me an email (C<dusty#megagram#com>).

If you test this, please let me know your results.
It's not ready for production use, but any testing is greatly appreciated.
It should work, but I haven't tested on enough systems to promise this.

=head1 EXAMPLE

  use Win32::WindowsUpdate;
  my $wu = Win32::WindowsUpdate->new;

  die "Reboot first...\n" if $wu->rebootRequired;

  $wu->setAutoRebootWhileLoggedOn(0); # don't auto reboot

  my @updates;
  foreach my $update ($wu->updates)
  {
    next unless ($update->{Title} =~ m/Security Update.*Windows XP/i); # filter for something
    push(@updates, $update); # push it into the updates list
  }

  sleep 1 while ($wu->installerBusy); # if Windows Installer is busy
  die "Reboot first...\n" if $wu->rebootRequired; # if whatever WI finished doing requires reboot
  $wu->install(@updates); # install your selected updates
  print "Installed updates want you to reboot...\n" if $wu->rebootRequired;

  # .. or to blindly install all updates:

  use Win32::WindowsUpdate;
  my $wu = Win32::WindowsUpdate->new;
  $wu->install($wu->updates);

=head1 METHODS

=head2 new

  my $wu = Win32::WindowsUpdate->new;
  my $wu = Win32::WindowsUpdate->new({online => 0});

Creates the WindowsUpdate object.

=over

=item online

Defaults to C<1>.
Check online for updates.

=back

=cut

sub new
{
  my $class = shift;
  my $args = shift;
  my $self = {};

  $self->{online} = (defined($args->{online}) ? ($args->{online} ? 1 : 0) : 1); # online by default
  $self->{updateSession} = Win32::OLE->new('Microsoft.Update.Session') or die "ERROR creating Microsoft.Update.Session\n";
  $self->{updateSearcher} = $self->{updateSession}->CreateUpdateSearcher or die "ERROR creating CreateUpdateSearcher\n";
  $self->{updateSearcher}->{Online} = $self->{online};
  $self->{systemInfo} = Win32::OLE->new('Microsoft.Update.SystemInfo') or die "ERROR creating Microsoft.Update.SystemInfo\n";

  return bless($self, $class);
}

=head2 updates

  my $updates = $wu->updates;
  # .. or ..
  my @updates = $wu->updates;

  my $updatesHidden = $wu->updates({IsHidden => 1});

Returns a list of updates available for download and install.

=over

=item IsInstalled

Returns installed (if true) or not installed (if false) updates.
Defaults to C<0>.

=item IsHidden

Returns hidden (if true) or not hidden (if false) updates.
Defaults to C<0>.

=back

=cut

sub updates
{
  my $self = shift;
  my $args = shift;

  my $isInstalled = (defined($args->{IsInstalled}) ? ($args->{IsInstalled} ? 1 : 0) : 0);
  my $isHidden = (defined($args->{IsHidden}) ? ($args->{IsHidden} ? 1 : 0) : 0);
  my $query = $args->{query} || "IsInstalled = $isInstalled AND IsHidden = $isHidden";

  my $queryResult = $self->{updateSearcher}->Search($query);
  my $updates = $queryResult->Updates;

  my @updates;
  foreach my $update (in $updates)
  {
    my $info = {};

    $info->{UpdateId} = $update->Identity->UpdateID;
    $info->{Title} = $update->Title;
    $info->{Description} = $update->Description;
    $info->{RebootRequired} = $update->RebootRequired;
    $info->{ReleaseNotes} = $update->ReleaseNotes;
    $info->{EulaText} = $update->EulaText;
    $info->{EulaAccepted} = $update->EulaAccepted;

    push(@{$info->{Category}}, {Name => $_->Name, CategoryID=> $_->CategoryID}) foreach (in $update->Categories);
    push(@{$info->{MoreInfoUrl}}, $_) foreach (in $update->MoreInfoUrls);
    push(@{$info->{KBArticleID}}, $_) foreach (in $update->KBArticleIDs);
    push(@{$info->{SecurityBulletinID}}, $_) foreach (in $update->SecurityBulletinIDs);
    push(@{$info->{SupersededUpdateID}}, $_) foreach (in $update->SupersededUpdateIDs);

    push(@updates, $info);
  }

  return (wantarray ? @updates : \@updates);
}

=head2 installed

  my $installed = $wu->installed;
  # .. or ..
  my @installed = $wu->installed;

Returns a list of installed updates.

=cut

sub installed
{
  my $self = shift;
  my $args = shift;

  return $self->updates({
    IsInstalled => 1,
    IsHidden => $args->{IsHidden},
  });
}

=head2 install

  my @updates;
  foreach my $update ($wu->updates)
  {
    printf("Available Update: %s %s\n", $update->{UpdateId}, $update->{Title});
    next unless ($update->{Title} =~ m/Security Update.*Windows XP/i);
    printf("Want to install: %s\n", $update->{Title});

    push(@updates, $update->{UpdateId});
    # .. or .. (both ways will work)
    push(@updates, $update);
  }
  $wu->install(@updates);

  # .. or ..

  $wu->install($wu->updates); # if you want to install all updates

Install specified updates.
Provide an array of either C<update> (directly from C<< $wu->updates >>) or C<updateId>.
See example above for usage.

=cut

sub install
{
  my $self = shift;
  my @updates = @_;

  return undef unless scalar(@updates); # no updates specified?  don't run.

  my %updates;
  # I'm sure there's a better way... gimme patch!
  foreach my $update (@updates)
  {
    my $uid = (ref($update) eq 'HASH' ? $update->{UpdateId} : $update);
    $updates{$uid}++;
  }

  my $updatecoll = Win32::OLE->new('Microsoft.Update.UpdateColl') or die "ERROR creating Microsoft.Update.UpdateColl\n";
  $updatecoll->Clear;

  my $queryResult = $self->{updateSearcher}->Search("IsInstalled = 0 AND IsHidden = 0") or die "ERROR in query\n";
  my $updates = $queryResult->Updates;

  foreach my $update (in $updates)
  {
    my $updateID = $update->Identity->UpdateID;
    next unless $updates{$updateID};
    $update->AcceptEula;
    $updatecoll->Add($update);
  }

  my $downloader = $self->{updateSession}->CreateUpdateDownloader;
  $downloader->LetProperty('Updates', $updatecoll);
  my $downloadResult = $downloader->Download;

  my $installer = $self->{updateSession}->CreateUpdateInstaller;
  $installer->LetProperty('Updates', $updatecoll);
  $installer->{AllowSourcePrompts} = 0;
  $installer->{ForceQuiet} = 1;
  my $installResult = $installer->Install;

  return $installResult->ResultCode;
}

=head2 rebootRequired

  my $needToReboot = $wu->rebootRequired();

Returns bool.  True if reboot is required, false otherwise.

This doesn't necessarily mean any installs will fail, but there is something pending a reboot.
Your install might fail, though.  Keep this in mind.

You should check this before and after you run C<install>.
If it's true before you install, you may want to reboot before you install.
If it's true after you install, you'll want to reboot sometime.

=cut

sub rebootRequired
{
  my $self = shift;
  return ($self->{systemInfo}->RebootRequired ? 1 : 0);
}

=head2 installerBusy

  my $installerIsBusy = $wu->installerBusy();

Returns bool.  True if Windows Installer is busy, false otherwise.

If the installer is busy, you probably won't have any success at running C<install>.
You could just sit in a loop waiting for it to no longer be busy, but you'd want to check
C<rebootRequired> immediately before you run C<install> to be sure you won't want to reboot
first.

=cut

sub installerBusy
{
  my $self = shift;
  my $installer = $self->{updateSession}->CreateUpdateInstaller;
  return ($installer->IsBusy ? 1 : 0);
}

=head2 setAutomaticUpdates

Set the Automatic Updates setting.

=over

=item disable (or C<1>)

Disable Automatic Updates altogether.
Any updates will need to performed manually (using this module, via Windows Updates, or your other methods)

=item notifyonly (or C<2>)

Notify of new updates, but don't download or install them.

=item notifydownload (or C<3>)

Download new updates automatically, but don't install them.
The user will be notified that updates are pending and will have the ability to choose which updates to install.

=item automatic (or C<4>)

Download and install updates automatically.
The user will only be notified that they need to reboot after updates are completed (if reboot is needed).
Windows might automatically reboot itself after some period of time to "be helpful".

=back

=cut

sub setAutomaticUpdates
{
  my $self = shift;
  my $setting = lc(shift);
  my $value = 0;

  $value = 1 if ($setting eq 'disable' or $setting eq '1');
  $value = 2 if ($setting eq 'notifyonly' or $setting eq '2');
  $value = 3 if ($setting eq 'notifydownload' or $setting eq '3');
  $value = 4 if ($setting eq 'automatic' or $setting eq '4');

  return undef unless ($value >= 1 && $value <= 4);

  my $state = ($value == 1 ? 7 : 2); # 7=audisabled, 2=detectionpending

  my $key = $Registry->{'LMachine/Software/Microsoft/Windows/CurrentVersion/WindowsUpdate/Auto Update/'};
  $key->{'/AUState'} = ['0x000'.$state, 'REG_DWORD'];
  $key->{'/AUOptions'} = ['0x000'.$value, 'REG_DWORD'];

  return $value;
}

=head2 setAutoRebootWhileLoggedOn

  $wu->setAutoRebootWhileLoggedOn(1); # enable (auto reboot, Windows default behavior)
  $wu->setAutoRebootWhileLoggedOn(0); # disable (no auto reboot)

Enable or disable the automatic reboot "feature".
If there is a pending reboot, it won't take effect until after the reboot.
Will still nag for a reboot, but the reboot won't be automatic after a period of time.
If the logged on user doesn't have reboot privilege, the nag will still appear, but it won't do anything except nag.
Without this setting, Windows will reboot automatically after the nag screen has been ignored for five minutes...
and for non-admins, they can't prevent the reboot.
This option (if set to C<0>) will prevent this behavior.
Defaults to C<0> if you don't specify a value.

See also http://blogs.msdn.com/tim_rains/archive/2004/11/15/257877.aspx

=cut

sub setAutoRebootWhileLoggedOn
{
  my $self = shift;
  my $setting = shift;
  $setting = !!$setting; # yummy double-negative makes a tasty bool

  my $key = $Registry->{'LMachine/Software/Policies/Microsoft/Windows/'};
  $key = $key->CreateKey('Windows Update/');
  $key = $key->CreateKey('AU/');
  $key->{'/NoAutoRebootWithLoggedOnUsers'} = ['0x000'.(!$setting), 'REG_DWORD'];

  return $setting;
}

=head2 setRebootNag (noop)

NOOP.
Incomplete as I find a reasonable way to do this, preferably without requiring a reboot.
Needs to reliably support Win2k and newer, including Pro, Home, and Server versions.
Ideas or patches?  Let me know.

See also http://www.codinghorror.com/blog/archives/000294.html

=cut

sub setRebootNag
{
  my $self = shift;
}

=head1 TODO

=over

=item Provide ability to install specific updates.

=item Provide ability to hide and unhide specific updates.

=item Provide ability to uninstall updates (maybe?).

=item Provide ability to do background install with ability to check on status.

=item Provide ability to only download updates, not install them.

=item Provide ability to disable/enable "Please reboot..." nag messages after update install. (see C<setRebootNag> above)

=item Determine other necessary features. (email me with your requests: C<dusty#megagram#com> or use the CPAN bug tracker)

=back

=head1 BUGS/WISHLIST

B<REPORT BUGS!>
Report any bugs to the CPAN bug tracker or email me C<dusty#megagram#com>.

To wishlist something, use the CPAN bug tracker (set as wishlist) or email me.
I'd be happy to implement useful functionality in this module on request.
I'd also be happy to accept patches.

=head1 COPYRIGHT/LICENSE

Copyright 2009 Megagram.  You can use any one of these licenses: Perl Artistic, GPL (version >= 2), BSD.

=head2 Perl Artistic License

Read it at L<http://dev.perl.org/licenses/artistic.html>.
This is the license we prefer.

=head2 GNU General Public License (GPL) Version 2

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

See the full license at L<http://www.gnu.org/licenses/>.

=head2 GNU General Public License (GPL) Version 3

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

See the full license at L<http://www.gnu.org/licenses/>.

=head2 BSD License

  Copyright (c) 2009 Megagram.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:

      * Redistributions of source code must retain the above copyright notice, this list of conditions
      and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
      and the following disclaimer in the documentation and/or other materials provided with the
      distribution.
      * Neither the name of Megagram nor the names of its contributors may be used to endorse
      or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
