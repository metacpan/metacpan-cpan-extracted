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

package dirs;

use wcenter;
use Tk::BrowseEntry;

sub display
{
	my ($parent) = @_;
	my $text;

	$parent->Busy;
	my $popup = $parent->Toplevel;
	$popup->title("Exclude Directories List");
	$popup->configure(-background => 'grey80');
	$dirs::top = $popup;

	wcenter::offset($popup,155,115);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Exclude Directories List',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $outerFrame = $popup->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-pady => 10,
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	#-------------------
	# The dirs list
	#-------------------

	my $dirListFrame = $outerFrame->Frame->pack(
		-side => 'top',
		-expand => 'yes',
		-fill => 'both');

	my $dirListScrollbar = $dirListFrame->Scrollbar->pack(
		-side => 'right',
		-fill => 'y');
		
	$dirs::dirListBox = $dirListFrame->Listbox(
		-width => 30,
		-font => '8x13',
		-background => 'PapayaWhip',
		-yscrollcommand => [$dirListScrollbar => 'set'])->pack(
			-side => 'left',
			-expand => 'yes',
			-fill => 'both');

	$dirListScrollbar->configure(-command => [$dirs::dirListBox => 'yview']);
		
	$dirs::dirListBox->bind('<Double-1>' =>
		sub {
			edit_item($popup) if ($main::dataField{'dircount'} > 0);
		});

	$dirs::dirListBox->bind('<1>' =>
		sub {
			enable_buttons() if ($main::dataField{'dircount'} > 0);
		});

	#-------------
	# The buttons
	#-------------

	$buttonFrame = $popup->Frame->pack(
		-side => 'top');

	$dismissButton = $buttonFrame->Button(
		-underline => 0,
		-command => sub{destroy $popup},
		-borderwidth => 1,
		-text => 'Dismiss',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');
	$popup->bind('<Key-d>' => sub{destroy $popup});

	$addButton = $buttonFrame->Button(
		-underline => 0,
		-command => sub{add_item($popup)},
		-borderwidth => 1,
		-text => 'Add',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');
	$popup->bind('<Key-a>' => sub{add_item($popup)});

	$dirs::editButton = $buttonFrame->Button(
		-underline => 0,
		-command => sub{edit_item($popup)},
		-state => 'disabled',
		-borderwidth => 1,
		-text => 'Edit',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');

	$dirs::deleteButton = $buttonFrame->Button(
		-underline => 2,
		-command => sub{delete_item($popup)},
		-state => 'disabled',
		-borderwidth => 1,
		-text => 'Delete',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');


	update_display();
	$parent->Unbusy;
}

#------------------------
# Add an item to the list
#------------------------

sub add_item
{
	my ($parent) = @_;

	$parent->Busy;
	my $popup = $parent->Toplevel;
	$popup->title("New Directory Specifier");
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,90,130);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Add Item',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

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
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	# The boot image
	my $addFrame = $popFrame->Frame(
		-background => 'grey80')->pack(
			-side => 'top',
			-fill => 'x');

	my $addEntry = $addFrame->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$addEntry->bind('<Key-Return>' => sub {
		apply_add($addEntry);
		destroy $popup;
	});

	$buttonFrame = $popup->Frame->pack(
		-side => 'bottom');

	$buttonFrame->Button(
		-command => sub{
			apply_add($addEntry);
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Ok',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'left');

	$buttonFrame->Button(
		-command => sub{
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Cancel',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');

	$addEntry->focus;		
	$parent->Unbusy;
}

#-----------------------
# Add a file to the list
#-----------------------

sub apply_add
{
	my ($w) = @_;
	my $filename = get $w;
	return if (length($filename) == 0);
	my $c = $main::dataField{'dircount'};

	$main::dataField{"dir_$c"} = $filename;
	$main::dataField{'dircount'} = $c + 1;

	update_display();
	$main::changed = 1;
	main::set_title();
}

#-------------------
# Update the display
#-------------------

sub update_display
{
	my $i;

	$dirs::dirListBox->delete(0,$main::dataField{'dircount'} - 1);
	for ($i = 0; $i < $main::dataField{'dircount'}; $i++)
	{
		$dirs::dirListBox->insert('end',$main::dataField{"dir_$i"});
	}

	disable_buttons();
}

sub enable_buttons
{
	$dirs::editButton->configure(-state => 'normal');
	$dirs::deleteButton->configure(-state => 'normal');

	$top->bind('<Key-e>' => sub{edit_item($top)});
	$top->bind('<Key-l>' => sub{delete_item($top)});
}

sub disable_buttons
{
	$dirs::editButton->configure(-state => 'disabled');
	$dirs::deleteButton->configure(-state => 'disabled');

	$top->bind('<Key-e>' => '');
	$top->bind('<Key-l>' => '');
}

#------------------------
# Add an item to the list
#------------------------

sub edit_item
{
	my ($parent) = @_;
	my $item = $dirs::dirListBox->curselection;

	my $popup = $parent->Toplevel;
	$popup->title("Edit File Specifier");
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,90,130);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Edit Item',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

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
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	# The boot image
	my $addFrame = $popFrame->Frame(
		-background => 'grey80')->pack(
			-side => 'top',
			-fill => 'x');

	my $addEntry = $addFrame->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$addEntry->insert('end',$main::dataField{"dir_$item"});

	$addEntry->bind('<Key-Return>' => sub {
		apply_edit($addEntry,$item);
		destroy $popup;
	});

	$buttonFrame = $popup->Frame->pack(
		-side => 'bottom');

	$buttonFrame->Button(
		-command => sub{
			apply_edit($addEntry,$item);
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Ok',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'left');

	$buttonFrame->Button(
		-command => sub{
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Cancel',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');

		
}

#-----------------------
# replace a file to the list
#-----------------------

sub apply_edit
{
	my ($w,$c) = @_;
	my $filename = get $w;

	$main::dataField{"dir_$c"} = $filename;

	update_display();
	$main::changed = 1;
	main::set_title();
}

#---------------
# Delete an item
#---------------

sub delete_item
{
	my $item = $dirs::dirListBox->curselection;

	my $i;

	$dirs::dirListBox->delete(0,$main::dataField{'dircount'} - 1);

	if (($main::dataField{'dircount'} == 1) ||
		($item == $main::dataField{'dircount'} -1))
	{
		$main::dataField{'dircount'}--;
		undef $main::dataField{"dir_$item"};
	}
	else
	{
		for ($i = $item; $i< ($main::dataField{'dircount'} - 1); $i++)
		{
			my $x = $i + 1;
			$main::dataField{"dir_$i"} = $main::dataField{"dir_$x"};
		}
	
		$i = $main::dataField{'dircount'} - 1;

		undef $main::dataField{"dir_$i"};
		$main::dataField{'dircount'}--;
	}

	disable_buttons();
	update_display();
	$main::changed = 1;
	main::set_title();
}

1;
