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

package dlg;

use Tk;
use Tk::Dialog;

use wcenter;

#-----------------
# Yes or no dialog
#-----------------

sub yesno {
    my ($parent,$text,$title) = @_;
	$parent->Busy;

	my $popup = $parent->Toplevel;
	$popup->title($title);
	$popup->configure(-background => 'grey80');
	wcenter::offset($popup,157,204);

	$topFrame = $popup->Frame->pack(
		-side => 'top');

	# The icon
	$leftFrame = $topFrame->Frame->pack(
		-side => 'left');

	if (not defined($dlg::exclaim_icon))
	{
		$dlg::exclaim_icon = $popup->Pixmap(
			-file => "$main::ROOT/misc_icons/exclaim.xpm");
	}

	$leftFrame->Label(
		-image => $dlg::exclaim_icon)->pack(
			-padx => 10,
			-side => 'left');

	# The message
	$rightFrame = $topFrame->Frame->pack(
		-side => 'right');

	$rightFrame->Label(
		-wraplength => '4i',
		-text => $text)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'top');

	# The buttons
	$bottomFrame = $popup->Frame->pack(
		-side => 'bottom');

	my $yesbutton = $bottomFrame->Button(
		-command => sub{$dlg::answer = 'Yes'},
        -borderwidth => 1,
        -text => 'Yes',
		-underline => 0,
        -background => 'grey80',
        -activebackground => 'grey80',
        -highlightthickness => 0)->pack(
             -pady => 5,
             -padx => 5,
             -side => 'left');

	$bottomFrame->Button(
		-command => sub{$dlg::answer = 'No'},
        -borderwidth => 1,
        -text => 'No',
		-underline => 0,
        -background => 'grey80',
        -activebackground => 'grey80',
        -highlightthickness => 0)->pack(
             -pady => 5,
             -padx => 5,
             -side => 'left');

	$popup->bind('<Key-y>' => sub{$dlg::answer = 'Yes'});
	$popup->bind('<Key-n>' => sub{$dlg::answer = 'No'});

	my $old_focus = $popup->focusSave;
    my $old_grab  = $popup->grabSave;

	$popup->grab;
	$yesbutton->focus;

	$popup->bind('<FocusOut>' => sub {
		$yesbutton->focus;
	});
		
	$main::mw->Unbusy;
	$dlg::answer = '';

	$popup->waitVariable(\$dlg::answer);

	$popup->grabRelease;
	&$old_focus;
	&$old_grab;

	destroy $popup;

	return $dlg::answer;
}

#-------------
# Error Dialog
#-------------

sub error {
    my ($parent,$text,$title) = @_;
	$parent->Busy;

	my $popup = $parent->Toplevel;
	$popup->title($title);
	$popup->configure(-background => 'grey80');
	wcenter::offset($popup,157,204);

	$topFrame = $popup->Frame->pack(
		-side => 'top');

	# The icon
	$leftFrame = $topFrame->Frame->pack(
		-side => 'left');

	if (not defined($dlg::info_icon))
	{
		$dlg::info_icon = $popup->Pixmap(
			-file => "$main::ROOT/misc_icons/info.xpm");
	}

	$leftFrame->Label(
		-image => $dlg::info_icon)->pack(
			-padx => 10,
			-side => 'left');

	# The message
	$rightFrame = $topFrame->Frame->pack(
		-side => 'right');

	$rightFrame->Label(
		-wraplength => '4i',
		-text => $text)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'top');

	# The buttons
	$bottomFrame = $popup->Frame->pack(
		-side => 'bottom');

	my $yesbutton = $bottomFrame->Button(
		-command => sub{$dlg::answer = 'ok'},
        -borderwidth => 1,
        -text => 'Ok',
		-underline => 0,
        -background => 'grey80',
        -activebackground => 'grey80',
        -highlightthickness => 0)->pack(
             -pady => 5,
             -padx => 5,
             -side => 'left');

	$popup->bind('<Key-Return>' => sub{$dlg::answer = 'ok'});
	$popup->bind('<Key-o>' => sub{$dlg::answer = 'ok'});

	my $old_focus = $popup->focusSave;
    my $old_grab  = $popup->grabSave;

	$popup->grab;
	$yesbutton->focus;

	$popup->bind('<FocusOut>' => sub {
		$yesbutton->focus;
	});
		
	$main::mw->Unbusy;
	$dlg::answer = '';

	$popup->waitVariable(\$dlg::answer);

	$popup->grabRelease;
	&$old_focus;
	&$old_grab;

	destroy $popup;

	return;
}

1;
