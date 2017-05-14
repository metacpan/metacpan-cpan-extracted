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

package cdwrite;

use wcenter;
use dlg;
use status;

#---------------------------------
# Set the options for writing a CD
#---------------------------------

sub set_options
{
	my ($parent) = @_;
	my $text;

	$parent->Busy;
	my $popup = $parent->Toplevel;
	$popup->title("CDR Options");
	$popup->configure(-background => 'grey80');
	$cdwrite::top = $popup;

	wcenter::offset($popup,155,114);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'CDR Options',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $topFrame = $popup->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-side => 'top',
			-fill => 'both');

	#------------------
	# The writing speed
	#------------------
	my $topLeftFrame = $topFrame->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-side => 'left',
			-fill => 'both');

	$topLeftFrame->Label(
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Writing Speed')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $writingSpeedFrame = $topLeftFrame->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'top',
			-fill => 'both');

	my $writingInnerFrame = $writingSpeedFrame->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey70')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top',
			-fill => 'both');

	$writingInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-highlightthickness => 0,
		-variable => \$main::dataField{'writingspeed'},
		-background => 'grey70',
		-activebackground => 'grey70',
		-value => 1,
		-text => '1x')->pack(
			-side => 'top');
	$popup->bind('<Control-Key-1>' => sub {
		$main::dataField{'writingspeed'} = 1;
	});
			
	$writingInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'writingspeed'},
		-background => 'grey70',
		-value => 2,
		-text => '2x')->pack(
			-side => 'top');
	$popup->bind('<Control-Key-2>' => sub {
		$main::dataField{'writingspeed'} = 2;
	});

	$writingInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'writingspeed'},
		-background => 'grey70',
		-value => 4,
		-text => '4x')->pack(
			-side => 'top');
	$popup->bind('<Control-Key-4>' => sub {
		$main::dataField{'writingspeed'} = 4;
	});

	$writingInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'writingspeed'},
		-background => 'grey70',
		-value => 6,
		-text => '6x')->pack(
			-side => 'top');
	$popup->bind('<Control-Key-6>' => sub {
		$main::dataField{'writingspeed'} = 6;
	});

	$writingInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'writingspeed'},
		-background => 'grey70',
		-value => 8,
		-text => '8x')->pack(
			-side => 'top');
	$popup->bind('<Control-Key-8>' => sub {
		$main::dataField{'writingspeed'} = 8;
	});


	#------------------
	# The writing speed
	#------------------
	my $topRightFrame = $topFrame->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-side => 'right',
			-fill => 'both');

	$topRightFrame->Label(
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Device Type')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $deviceTypeFrame = $topRightFrame->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'top',
			-fill => 'both');

	my $deviceInnerFrame = $deviceTypeFrame->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey70')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top',
			-fill => 'both');

	
	$cdwrite::rt[0] = $deviceInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'devicetype'},
		-background => 'grey70',
		-value => 'philips',
		-text => 'Philips')->pack(
			-anchor => 'w',
			-side => 'top');
	$popup->bind('<Control-Key-p>' => sub {
		$main::dataField{'devicetype'} = 'philips';
	});

	$cdwrite::rt[1] = $deviceInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'devicetype'},
		-background => 'grey70',
		-value => 'ims',
		-text => 'Ims')->pack(
			-anchor => 'w',
			-side => 'top');
	$popup->bind('<Control-Key-i>' => sub {
		$main::dataField{'devicetype'} = 'ims';
	});

	$cdwrite::rt[2] = $deviceInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'devicetype'},
		-background => 'grey70',
		-value => 'kodak',
		-text => 'Kodak')->pack(
			-anchor => 'w',
			-side => 'top');
	$popup->bind('<Control-Key-k>' => sub {
		$main::dataField{'devicetype'} = 'kodak';
	});

	$cdwrite::rt[3] = $deviceInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'devicetype'},
		-background => 'grey70',
		-value => 'yamaha',
		-text => 'Yamaha')->pack(
			-anchor => 'w',
			-side => 'top');
	$popup->bind('<Control-Key-y>' => sub {
		$main::dataField{'devicetype'} = 'yamaha';
	});

	$cdwrite::rt[4] = $deviceInnerFrame->Radiobutton(
		-command => sub{save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'devicetype'},
		-background => 'grey70',
		-value => 'hp',
		-text => 'Hewlet Packard')->pack(
			-anchor => 'w',
			-side => 'top');
	$popup->bind('<Control-Key-h>' => sub {
		$main::dataField{'devicetype'} = 'hp';
	});

	#------------------------
	# use cdwrite or cdrecord
	#------------------------
	my $cdrecFrame = $popup->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 15,
			-side => 'top',
			-fill => 'x');

	$cdrecFrame->Label(
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'CDR Program')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $cdInnerFrame = $cdrecFrame->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'top',
			-fill => 'both');

	my $usecdwrite = $cdInnerFrame->Radiobutton(
		-command => sub{
			my $i;
			for ($i=0; $i<5; $i++)
			{
				$cdwrite::rt[$i]->configure(-state => 'normal');
			}
			$cdwrite::deviceLabel->configure(
				-text => 'Device Path (eg /dev/cdwriter)');
			save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'use_program'},
		-background => 'grey70',
		-value => 'cdwrite',
		-text => 'Use cdwrite')->pack(
			-padx => 10,
			-side => 'left');

	my $usecdrecord = $cdInnerFrame->Radiobutton(
		-command => sub{
			my $i;
			for ($i=0; $i<5; $i++)
			{
				$cdwrite::rt[$i]->configure(-state => 'disabled');
			}
			$cdwrite::deviceLabel->configure(
				-text => 'Device SCSI ID,LUN (eg 2,0)');
			save_as_on()},
		-underline => 0,
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'use_program'},
		-background => 'grey70',
		-value => 'cdrecord',
		-text => 'Use cdrecord')->pack(
			-padx => 10,
			-side => 'right');

	$usecdwrite->configure(-state => 'disabled') unless ($cdwrite::cdwrite);
	$usecdrecord->configure(-state => 'disabled') unless ($cdwrite::cdrecord);

	$main::dataField{'use_program'} = 'cdwrite'
		if (($cdwrite::cdwrite)&&(!$cdwrite::cdrecord));

	$main::dataField{'use_program'} = 'cdrecord'
		if ((!$cdwrite::cdwrite)&&($cdwrite::cdrecord));

	if ($main::dataField{'use_program'} eq 'cdrecord')
	{
		my $i;
		for ($i=0; $i<5; $i++)
		{
			$cdwrite::rt[$i]->configure(-state => 'disabled');
		}
	}

	#------------
	# Device Name
	#------------
	$cdwrite::deviceLabel = $popup->Label(
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Device Name')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $popEntry = $popup->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-textvariable => \$main::dataField{'devicename'},
		-background => 'PapayaWhip')->pack(
			-side => 'top',
			-padx => 10);

	$popEntry->bind('<KeyPress>' => sub {save_as_on()});
	
	if ($main::dataField{'use_program'} eq 'cdwrite')
	{
		my $i;
		for ($i=0; $i<5; $i++)
		{
			$cdwrite::rt[$i]->configure(-state => 'disabled');
		}

		$cdwrite::deviceLabel->configure(
			-text => 'Device Path (eg /dev/cdwriter)');
	}
	else
	{
		$cdwrite::deviceLabel->configure(
			-text => 'Device SCSI ID,LUN (eg 2,0)');
	}

	#-------------------
	# Command Buttons
	#-------------------

	my $buttonBar = $popup->Frame->pack(
		-side => 'top',
		-pady => 5);

	$buttonBar->Button(
		-command => sub{
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Dismiss',
		-underline => 0,
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'left');

	$cdwrite::saveas = $buttonBar->Button(
		-command => sub{copy_defs()},
		-borderwidth => 1,
		-state => 'disabled',
		-text => 'Save As Default',
		-background => 'grey80',
		-underline => 0,
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');

	$popup->bind('<Control-Key-d>' => sub {
		destroy $popup;
	});

	$popup->bind('<Control-Key-s>' => '');
	$parent->Unbusy;
}

sub copy_defs
{
	$defaults::item{'writingspeed'} = 
		$main::dataField{'writingspeed'};
	$defaults::item{'devicetype'} =
		$main::dataField{'devicetype'};
	$defaults::item{'devicename'} =
		$main::dataField{'devicename'};
	$defaults::item{'use_program'} =
		$main::dataField{'use_program'};

	defaults::save();
	save_as_off();
}

sub save_as_on
{
	$cdwrite::saveas->configure(-state => 'normal');
	$cdwrite::top->bind('<Control-Key-s>' => sub {copy_defs()});
	$main::changed = 1;
	main::set_title();
}	
	
sub save_as_off
{
	$cdwrite::saveas->configure(-state => 'disabled');
	$cdwrite::top->bind('<Control-Key-s>' => '');
}	

#-------------------------------
# Create the pre-write cd window
#-------------------------------

sub write_image
{
	my ($parent) = @_;
	my $text;

	$parent->Busy;
	my $popup = $parent->Toplevel;
	$popup->title("Write CDROM");
	$popup->configure(-background => 'grey80');
	$cdwrite::top = $popup;

	wcenter::offset($popup,110,156);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'Write CDROM',
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
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'grey70')->pack(
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	# The cdrom image
	my $imageFrame = $popFrame->Frame(
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');

	my $imageLabel = $imageFrame->Label(
		-text => 'CDROM Image',
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'left');


	$imageLabel->bind('<Button-3>' =>
	sub {
		help::display($parent, 'help23');
	});

	my $imageEntry = $imageFrame->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$imageEntry->insert('end',$main::dataField{'destpath'});

	# Options
	$popFrame->Checkbutton(
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'simulate'},
		-background => 'grey70',
		-text => 'Simulate Recording')->pack(
			-anchor => 'w',
			-padx => 5,
			-side => 'top');

	$popFrame->Checkbutton(
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-variable => \$main::dataField{'eject'},
		-background => 'grey70',
		-text => 'Eject After Writing')->pack(
			-anchor => 'w',
			-padx => 5,
			-side => 'top');

	#-------------------
	# Command Buttons
	#-------------------

	my $buttonBar = $popup->Frame->pack(
		-side => 'top',
		-pady => 5);

	$buttonBar->Button(
		-command => sub{
				write_cdrom(get $imageEntry);
				destroy $popup;
			},
		-borderwidth => 1,
		-text => 'Write CD',
		-background => 'grey80',
		-underline => 0,
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-padx => 5,
			-side => 'left');

	$buttonBar->Button(
		-command => sub{
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Cancel',
		-underline => 0,
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'left');

	$popup->bind('<Control-Key-w>' => sub {
				write_cdrom(get $imageEntry);
				destroy $popup;
	});

	$popup->bind('<Control-Key-c>' => sub {
				destroy $popup;
	});

	$parent->Unbusy;
}

sub write_cdrom
{
	my ($src) = @_;
	my $cmdline;

	if ($main::dataField{'use_program'} eq '')
	{
		dlg::error($cdwrite::top,
			'No CD Writer program has been specified. Use CDR Options to select','Error');
		return;
	}

	if ($main::dataField{'use_program'} eq 'cdwrite')
	{
		$cmdline = 'cdwrite --verbose';
		unless ($cdwrite::cdwrite)
		{
			dlg::error($cdwrite::top,
				'cdwrite cannot be found on the path','Error');
			return;
		}
	}
	else
	{
		$cmdline = 'cdrecord -v';
		unless ($cdwrite::cdrecord)
		{
			dlg::error($cdwrite::top,
				'cdrecord cannot be found on the path','Error');
			return;
		}
	}

	if (length($src) == 0)
	{
		dlg::error($cdwrite::top,'A CDROM image path must be specified','Error');
		return;
	}

	unless(-r $src)
	{
		dlg::error($cdwrite::top,"$src is not a valid readable image file",'Error');
		return;
	}
	
	# sort out command line
	if ($main::dataField{'use_program'} eq 'cdwrite')
	{
		$cmdline = "$cmdline --eject" if ($main::dataField{'eject'} == 1);
		$cmdline = "$cmdline --dummy" if ($main::dataField{'simulate'} == 1);
		$cmdline = "$cmdline --speed " . $main::dataField{'writingspeed'} . " --device " . $main::dataField{'devicename'} . " --" . $main::dataField{'devicetype'};
		$cmdline = "$cmdline $src";
	}
	else
	{
		$cmdline = "$cmdline -dummy" if ($main::dataField{'simulate'} == 1);
		$cmdline = "$cmdline -eject" if ($main::dataField{'eject'} == 1);
		$cmdline = "$cmdline -speed " . $main::dataField{'writingspeed'};
		$cmdline = "$cmdline -dev " . $main::dataField{'devicename'};
		$cmdline = "$cmdline $src";
	}

	status::status_window(1,'Writing ISO9660 Image');
	status::status_window(3,"Command Line: $cmdline\n");
	status::runCommand($cmdline);

	dlg::error($cdwrite::top,'Write Finished','Information');
	status::status_window(4);
}

sub check_programs
{
	$cdwrite::cdwrite = 0;
	$cdwrite::cdrecord = 0;

	my $which = `which cdwrite`;
	$cdwrite::cdwrite = 1 if (substr($which,0,1) eq '/');
		
	$which = `which cdrecord`;
	$cdwrite::cdrecord = 1 if (substr($which,0,1) eq '/');
}

1;

