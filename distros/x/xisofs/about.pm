#   xisofs v1.3 Perl/Tk Interface to mkisofs / cdwrite
#   Copyright (c) 1997 Steve Sherwood (pariah@netcomuk.co.uk)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package about;

use wcenter;

sub display
{
	my ($parent) = @_;
	my $text;

	$main::mw->Busy;

	my $popup = $parent->Toplevel;
	$popup->title("About");
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,181,152);

	my $outerFrame = $popup->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-pady => 10,
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	my $popFrame = $outerFrame->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'PapayaWhip')->pack(
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	$popFrame->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'PapayaWhip',
		-text => $main::version,
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => '(c) Copyright 1997 Steve Sherwood',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => 'Perl/Tk Interface to mkisofs / cdwrite',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $version_mkisofs = 'Cannot Find mkisofs';
	my $version_cdwrite = 'Cannot Find cdwrite';
	my $version_cdrecord = 'Cannot Find cdrecord';

	my $which = `which mkisofs`;
	if (substr($which,0,1) eq '/')
	{
		chomp(my @hlp = `mkisofs -v 2>&1`);
		foreach(@hlp)
		{
			chomp;
			next unless (/^mkisofs/);

			$version_mkisofs = $_;
			last;
		}
	}

	$which = `which cdwrite`;
	if (substr($which,0,1) eq '/')
	{
		chomp(my @hlp = `cdwrite -h 2>&1`);
		foreach(@hlp)
		{
			chomp;
			next unless (/^cdwrite/);

			$version_cdwrite = $_;
			last;
		}
	}

	$which = `which cdrecord`;
	if (substr($which,0,1) eq '/')
	{
		$version_cdrecord = 'cdrecord v1.4 or earlier';
		chomp(my @hlp = `cdrecord -version 2>&1`);
		foreach(@hlp)
		{
			chomp;
			next unless (/^Cdrecord release/);

			($version_cdrecord) = /^Cdrecord release (\d\.\d)/;
			$version_cdrecord = "cdrecord $version_cdrecord";
			last;
		}
	}


	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => $version_mkisofs,
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-side => 'top');

	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => $version_cdwrite,
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-side => 'top');

	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => $version_cdrecord,
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-side => 'top');

	$popup->Button(
		-command => sub{$about::flag = 1},
		-borderwidth => 1,
		-text => 'Dismiss',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'bottom');

	$main::mw->Unbusy;

	$about::flag = 0;
	my $old_focus = $popup->focusSave;
	my $old_grab  = $popup->grabSave;
	$popup->grab;
	$popup->focus;
	$popup->bind('<FocusOut>' => sub {$popup->focus});

	$popup->waitVariable(\$about::flag);

	$popup->grabRelease;
	&$old_focus;
	&$old_grab;
	destroy $popup;
}

1;
