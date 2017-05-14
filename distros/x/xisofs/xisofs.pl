#!yyzzy
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
#
#   requires : Perl 5.004
#              ptk 400.202
#              mkisofs v1.11
#              cdwrite 2.0 / cdrecord 1.4

$ROOT = "xyzzy";
$ICONS = "large_icons";

use lib "xyzzy";

use Tk;
use Bubble;
use help;
use selector;
use dlg;
use status;
use about;
use eltorito;
use files;
use dirs;
use cdwrite;
use defaults;

$version = "xisofs v1.3";
$current_filename = '';
$changed = 0;

cdwrite::check_programs();

$mw = new MainWindow;
$mw->title("$version - Untitled");
$mw->setPalette('grey80');

#-------------
# The Menu Bar
#-------------

$menuBar = $mw->Frame(
	-background => 'grey80',
	-borderwidth => 2,
	-relief => 'raised')->pack(
		-fill => 'x',
		-side => 'top');

# The help menu
$helpMenu = $menuBar->Menubutton(
	-underline => 0,
	-text => 'Help',
	-borderwidth => 1)->pack(
		-side => 'right');
$helpMenu->command(
	-underline => 0,
	-command => sub{about::display($mw)},
	-label => 'About	F1');
$mw->bind('<Key-F1>' => sub {about::display($mw)});

# The file menu
$fileMenu = $menuBar->Menubutton(
	-underline => 0,
	-text => 'File',
	-borderwidth => 1)->pack(
		-side => 'left');
$fileMenu->command(
	-underline => 0,
	-command => sub{reset_data('defaults')},
	-label => 'New (defaults)	Ctrl+N');
$fileMenu->command(
	-underline => 1,
	-command => sub{reset_data('blank')},
	-label => 'New (Blank)	Ctrl+B');
$fileMenu->command(
	-underline => 0,
	-command => sub{open_data()},
	-label => 'Open		Ctrl+O');
$fileMenu->separator;
$fileMenu->command(
	-underline => 0,
	-command => sub{save_data()},
	-label => 'Save		Ctrl+S');
$fileMenu->command(
	-underline => 1,
	-command => sub{save_data_as()},
	-label => 'Save As		Ctrl+A');
$fileMenu->command(
	-underline => 1,
	-command => sub{copy_over()},
	-label => 'Save As Defaults	Ctrl+V');
$fileMenu->separator;
$fileMenu->command(
	-underline => 0,
	-command => sub{do_quit()},
	-label => 'Quit		Alt+Q');
$mw->bind('<Control-Key-n>' => sub {reset_data('defaults')});
$mw->bind('<Control-Key-b>' => sub {reset_data('blank')});
$mw->bind('<Control-Key-o>' => sub {open_data()});
$mw->bind('<Control-Key-s>' => sub {save_data()});
$mw->bind('<Control-Key-a>' => sub {save_data_as()});
$mw->bind('<Control-Key-v>' => sub {copy_over()});
$mw->bind('<Alt-Key-q>' => sub{do_quit()});

# The build menu
$buildMenu = $menuBar->Menubutton(
	-underline => 0,
	-text => 'Build',
	-borderwidth => 1)->pack(
		-side => 'left');
$buildMenu->command(
	-underline => 0,
	-command => sub{build_image()},
	-label => 'Build Image		Ctrl+I');
if (($cdwrite::cdwrite) || ($cdwrite::cdrecord))
{
	$buildMenu->command(
		-underline => 0,
		-command => sub{cdwrite::write_image($mw)},
		-label => 'Write CDROM		Ctrl+W');
}
$buildMenu->separator;
$buildMenu->command(
	-underline => 3,
	-command => sub{eltorito::display($mw)},
	-label => 'El Torito			Ctrl+E');
$buildMenu->command(
	-underline => 8,
	-command => sub{files::display($mw)},
	-label => 'Exclude Files		Ctrl+F');
$buildMenu->command(
	-command => sub{dirs::display($mw)},
	-underline => 8,
	-command => sub{dirs::display($mw)},
	-label => 'Exclude Directories	Ctrl+D');
if (($cdwrite::cdwrite) || ($cdwrite::cdrecord))
{
	$buildMenu->command(
		-command => sub{dirs::display($mw)},
		-underline => 8,
		-command => sub{cdwrite::set_options($mw)},
		-label => 'CDR Options		Ctrl+O');
	$mw->bind('<Control-Key-o>' => sub {cdwrite::set_options($mw)});
	$mw->bind('<Control-Key-w>' => sub {cdwrite::write_image($mw)});
}

$mw->bind('<Control-Key-i>' => sub {build_image()});
$mw->bind('<Control-Key-e>' => sub {eltorito::display($mw)});
$mw->bind('<Control-Key-f>' => sub {files::display($mw)});
$mw->bind('<Control-Key-d>' => sub {dirs::display($mw)});

#-----------
# Button Bar
#-----------

$buttonBar = $mw->Frame->pack(
	-side => 'top',
	-fill => 'x');

$bubble = new Bubble(
	-background => 'PapayaWhip',
	-foreground => 'black');

$fileButtonBar = $buttonBar->Frame->pack(
	-side => 'left');

$newPixmap = $fileButtonBar->Pixmap(-file => "$ROOT/$ICONS/new.xpm");
$newButton = $fileButtonBar->Button(
	-command => sub{reset_data('blank')},
	-activebackground => 'grey80',
	-image => $newPixmap)->pack(
		-side => 'left');
$bubble->attach($newButton,
	-text => 'Reset to blank document');

$openPixmap = $fileButtonBar->Pixmap(-file => "$ROOT/$ICONS/open.xpm");
$openButton = $fileButtonBar->Button(
	-command => sub {open_data()},
	-activebackground => 'grey80',
	-image => $openPixmap)->pack(
		-side => 'left');
$bubble->attach($openButton,
	-text => 'Open Project');

$savePixmap = $fileButtonBar->Pixmap(-file => "$ROOT/$ICONS/save.xpm");
$saveButton = $fileButtonBar->Button(
	-command => sub {save_data()},
	-activebackground => 'grey80',
	-image => $savePixmap)->pack(
		-side => 'left');
$bubble->attach($saveButton,
	-text => 'Save Project');

$buildButtonBar = $buttonBar->Frame->pack(
	-padx => 10,
	-side => 'left');

$buildPixmap = $buildButtonBar->Pixmap(-file => "$ROOT/$ICONS/build.xpm");
$buildButton = $buildButtonBar->Button(
	-command => sub{build_image()},
	-activebackground => 'grey80',
	-image => $buildPixmap)->pack(
		-side => 'left');
$bubble->attach($buildButton,
	-text => 'Build ISO9660 Image');

$eltoritoPixmap = $buildButtonBar->Pixmap(-file => "$ROOT/$ICONS/eltorito.xpm");
$eltoritoButton = $buildButtonBar->Button(
	-command => sub{eltorito::display($mw)},
	-activebackground => 'grey80',
	-image => $eltoritoPixmap)->pack(
		-side => 'left');
$bubble->attach($eltoritoButton,
	-text => 'El Torito Options');

$filesPixmap = $buildButtonBar->Pixmap(-file => "$ROOT/$ICONS/files.xpm");
$filesButton = $buildButtonBar->Button(
	-command => sub{files::display($mw)},
	-activebackground => 'grey80',
	-image => $filesPixmap)->pack(
		-side => 'left');
$bubble->attach($filesButton,
	-text => 'Exclude Files List');

$dirsPixmap = $buildButtonBar->Pixmap(-file => "$ROOT/$ICONS/dirs.xpm");
$dirsButton = $buildButtonBar->Button(
	-command => sub{dirs::display($mw)},
	-activebackground => 'grey80',
	-image => $dirsPixmap)->pack(
		-side => 'left');
$bubble->attach($dirsButton,
	-text => 'Exclude Directories List');

$quitPixmap = $buttonBar->Pixmap(-file => "$ROOT/$ICONS/quit.xpm");
$quitButton = $buttonBar->Button(
	-command => sub {do_quit()},
	-activebackground => 'grey80',
	-image => $quitPixmap)->pack(
		-side => 'right');
$bubble->attach($quitButton,
	-text => 'Quit');

if (($cdwrite::cdwrite) || ($cdwrite::cdrecord))
{
	$writeButtonBar = $buttonBar->Frame->pack(
		-padx => 10,
		-side => 'left');
	
	$writePixmap = $writeButtonBar->Pixmap(-file => "$ROOT/$ICONS/burn.xpm");
	$writeButton = $writeButtonBar->Button(
		-command => sub{cdwrite::write_image($mw)},
		-activebackground => 'grey80',
		-image => $writePixmap)->pack(
			-side => 'left');
	$bubble->attach($writeButton,
		-text => 'Write ISO9660 Image To CDROM');
	
	$optionPixmap = $writeButtonBar->Pixmap(-file => "$ROOT/$ICONS/cdopt.xpm");
	$optionButton = $writeButtonBar->Button(
		-command => sub{cdwrite::set_options($mw)},
		-activebackground => 'grey80',
		-image => $optionPixmap)->pack(
			-side => 'left');
	$bubble->attach($optionButton,
		-text => 'CDR Options');
}

#----------
# Separator
#----------

$separator = $mw->Frame(
	-borderwidth => 1,
	-relief => 'sunken')->pack(
		-side => 'top',
		-fill => 'x');
$separator->Frame()->pack;

#-----------
# Status Bar
#-----------

$statusFrame = $mw->Frame(
	-relief => 'sunken',
	-borderwidth => 1,
	-background => 'grey40')->pack(
		-side => 'bottom',
		-padx => 5,
		-pady => 5,
		-fill => 'x');

$statusText = $statusFrame->Label(
	-text => 'Ready and Willing',
	-foreground => 'white',
	-background => 'grey40')->pack(
		-side => 'top',
		-padx => 2,
		-pady => 2);

#---------------
# The path names
#---------------

$mw->Label(
	-text => 'Filesystem Locations',
	-foreground => 'red4')->pack(
		-side => 'top');

$pathFrame = $mw->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-side => 'top',
		-padx => 10,
		-fill => 'x');

#--------------
# Entry Boxes
#--------------

entry($pathFrame, 'srcpath','Source Path','help01',1024,60,
	'Enter the full source path to the directory structure you wish to build');
entry($pathFrame, 'destpath','Destination Filename','help02',1024,60,
	'Enter the full destination path to the image file you wish to create');

#---------------
# The info names
#---------------

$mw->Label(
	-text => 'CDROM Information',
	-foreground => 'red4')->pack(
		-side => 'top');

$infoFrame = $mw->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-side => 'top',
		-padx => 10,
		-fill => 'x');

$infoLeftFrame = $infoFrame->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-side => 'left',
		-padx => 5,
		-pady => 10,
		-fill => 'both');

$infoRightFrame = $infoFrame->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-side => 'right',
		-padx => 5,
		-pady => 10,
		-fill => 'both');

#----------
# Entry Boxes
#----------

entry($infoLeftFrame, 'application','Application','help17',128,30,
	'Enter the title of the application being created (Max 128 characters)');
entry($infoLeftFrame, 'copyright','Copyright','help18',37,30,
	'Enter the copyright information (Max 37 characters)');
entry($infoLeftFrame, 'publisher','Publisher','help03',128,30,
	'Enter the publisher of the application begin created (Max 128 characters)');
entry($infoLeftFrame, 'preparer','Preparer','help04',128,30,
	'Enter the preparer of the application being created (Max 128 characters)');
entry($infoLeftFrame, 'volumeid', 'Volume ID','help05',32,30,
	'Enter the volume ID of the application being created (Max 32 characters)');
entry($infoRightFrame, 'abstract', 'Abstract','help19',37,30,
	'Enter the abstract information (Max 37 characters)');
entry($infoRightFrame, 'bibliographic','Bibliographic','help22',37,30,
	'Enter the bibliographic information (Max 37 characters)');
entry($infoRightFrame, 'systemid','System ID','help20',32,30,
	'Enter the system identifier information (Max 32 characters)');
entry($infoRightFrame, 'volumeset','Volume Set','help21',278,30,
	'Enter the volume set information (Max 278 characters)');

$dataField{'bootimage'} = '';
$dataField{'bootcatalog'} = '';
$dataField{'dircount'} = 0;
$dataField{'filecount'} = 0;

#------------
# The options
#------------

$mw->Label(
	-text => 'Options',
	-foreground => 'red4')->pack(
		-side => 'top');

$optFrame = $mw->Frame(
	-background => 'grey70',
	-relief => 'sunken',
	-borderwidth => 1)->pack(
		-side => 'top',
		-padx => 10,
		-fill => 'x');

$optLeftFrame = $optFrame->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-side => 'left',
		-pady => 10,
		-padx => 5,
		-ipady => 10,
		-fill => 'both');

$optRightFrame = $optFrame->Frame(
	-relief => 'sunken',
	-background => 'grey70',
	-borderwidth => 1)->pack(
		-pady => 10,
		-padx => 5,
		-side => 'right',
		-fill => 'both');

#----------------------
# Check Boxes
#----------------------

for ($i=0; $i<12; $i++)
{
	$dataField{"check$i"} = 0;
}

$dataField{'radio1'} = 0;

check(0,0,$optLeftFrame, 'Include All Files', 'help06',
	'Include all files regardless of filename');
check(0,1,$optLeftFrame, 'Omit Trailing Periods', 'help07',
	'Omit trailing period from files that do not have an extension');
check(0,2,$optLeftFrame, 'Do Not Use Deep Directory Relocation', 'help08',
	'Do not use deep directory relocation, just pack them as they are');
check(0,3,$optLeftFrame, 'Follow Symbolic Links', 'help09',
	'Follow symbolic links when creating filesystem');
check(0,4,$optLeftFrame, 'Allow Full 32 Character Filenames', 'help10',
	'Allow full 32 character filenames, instead of DOS 8.3');
check(0,5,$optLeftFrame, 'Allow Filenames To Begin With A Period', 'help11',
	'Do not replace leading dot with an underscore');
check(0,6,$optRightFrame, 'Omit Version Numbers', 'help12',
	'Omit file version numbers which are rarely used');
check(0,7,$optRightFrame, 'Use Rock Ridge Protocol', 'help13',
	'Use Rock Ridge protocol to further describe the files on the filesystem');
radio(1,8,$optRightFrame, 'Generate Full Rock Ridge Attributes', 'help14');
radio(1,9,$optRightFrame, 'Generate Adjusted Rock Ridge Attributes', 'help15');
check(0,10,$optRightFrame, 'Generate translation table', 'help16',
	'Generate a TRANS.TBL file in each directory');
check(0,11,$optRightFrame, 'Generate Records for Compressed Files ', 'help25',
	'Generate special SUSP records for transparently compressed files');

$mw->protocol(WM_SAVE_YOURSELF => sub{save_data()});
$mw->protocol(WM_DELETE_WINDOW => sub{do_quit()});

reset_data('defaults');

MainLoop;
exit 0;

#------------
# Entry Field
#------------

sub entry
{
	my ($parent,$dataid,$title,$helpfile,$max,$len,$desc) = @_;

	my $frame = $parent->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');
	
	$frame->bind('<Enter>' =>
	sub {
			$statusText->configure(-text => $desc);
	});

	my $lab = $frame->Label(
		-text => $title,
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'left');

	$lab->bind('<Button-3>' =>
	sub {
			help::display($parent, $helpfile);
	});
	
	$lengthField{$dataid} = $max;
	$entryField{$dataid} = $item;
	$dataField{$dataid} = '';

	my $item = $frame->Entry(
		-textvariable => \$dataField{$dataid},
		-relief => 'sunken',
		-borderwidth => 2,
		-width => $len,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$item->bind('<Button-3>' =>
	sub {
			help::display($parent, $helpfile);
	});

	$item->bind('<KeyPress>' =>
	sub {
		my $current = get $item;
		if (length($current) > $max)
		{
			$mw->bell;
			$statusText->configure(-text => "This field has a maximum length of $max characters");
		}
		else
		{
			$statusText->configure(-text => '');
		}

		if ($changed == 0)
		{
			$changed = 1;
			set_title();
		}
	});


	$frame->bind('<Leave>' =>
	sub {
		$statusText->configure(-text => 'Right click on attributes for help');
	});


	return $item;
}

	
#----------------
# A Check Button
#----------------

sub check
{
	my ($type, $index, $parent,$title,$helpfile,$desc) = @_;
	my $pad = 5;
	my $state = 'normal';


	my $frame = $parent->Frame(
		-relief => 'flat',
		-background => 'grey70',
		-borderwidth => 0,
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');
	
	$frame->bind('<Enter>' =>
	sub {
			$statusText->configure(-text => $desc);
	});

	$frame->bind('<Leave>' =>
	sub {
			$statusText->configure(-text => 'Right click on attributes for help');
	});

	$chbtn[$index] = $frame->Checkbutton(
		-command => sub{action($index)},
		-state => $state,
		-text => $title,
		-variable => \$dataField{"check$index"},
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-background => 'grey70')->pack(
			-padx => $pad,
			-side => 'left');

	$chbtn[$index]->bind('<Button-3>' =>
	sub {
			help::display($parent, $helpfile);
	});
}

#----------------
# A Radio Button
#----------------

sub radio
{
	my ($type, $index, $parent,$title,$helpfile) = @_;
	my $state = 'disabled';

	my $frame = $parent->Frame(
		-relief => 'flat',
		-background => 'grey70',
		-borderwidth => 0,
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');
	
	$chbtn[$index] = $frame->Radiobutton(
		-command => sub{action($index)},
		-state => $state,
		-text => $title,
		-value => $index,
		-variable => \$dataField{"radio$type"},
		-activebackground => 'grey70',
		-highlightthickness => 0,
		-background => 'grey70')->pack(
			-padx => 35,
			-side => 'left');

	$chbtn[$index]->bind('<Button-3>' =>
	sub {
			help::display($parent, $helpfile);
	});
}


sub action
{
	my ($index) = @_;

	if ($index == 7)
	{
		if ($dataField{'check7'} == 1)
		{
			$chbtn[8]->configure(-state => 'normal');
			$chbtn[9]->configure(-state => 'normal');
			$dataField{'radio1'} = 8;
		}
		else
		{
			$chbtn[8]->configure(-state => 'disabled');
			$chbtn[9]->configure(-state => 'disabled');
			$radio[1] = 0;
		}
	}

	if ($changed == 0)
	{
		$changed = 1;
		set_title();
	}
}

#-------------------
# Routine to save as
#-------------------

sub save_data_as
{
	selector::reset_types();
	selector::add_type('iso','XISOfs Project Files');
	selector::add_type('*','All File Types');

	while (1)
	{
		my $filename = selector::file($mw,'Save File','Save');

		return if (length($filename) == 0);

		if (-e $filename)
		{
			next if (dlg::yesno($mw,"$filename exists. Overwrite ?","Overwrite") eq 'No');
		}

		write_data($filename);

		last;
	}
}

#--------------------------------------------
# Do save, if no current filemame, do save as
#--------------------------------------------

sub save_data
{
	if (length($current_filename) == 0)
	{
		save_data_as();
	}
	else
	{
		write_data($current_filename);
	}
}

#----------------------------------
# Write the actual data to the file
#----------------------------------

sub write_data
{
	my ($filename) = @_;

	if (open(OUT,">$filename"))
	{
		my ($i,$data);

		print OUT $version,"\n";
		while (($key,$val) = each %dataField)
		{
			print OUT "$key = $val\n";
		}

		close(OUT);

		$current_filename = $filename;
		$changed = 0;
		set_title();
	}
	else
	{
		dlg::error($mw,"$filename : $!",'Error');
		next;
	}
}

#---------------------
# Set the window title
#---------------------

sub set_title
{
	my $z = '';
	my $filename = 'Untitled';

	$z = '*' if ($changed == 1);
	$filename = $current_filename if (length($current_filename) != 0);

	$mw->title("$version - $filename $z");
}

#------------
# Open a file
#------------

sub open_data
{
	selector::reset_types();
	selector::add_type('iso','XISOfs Project Files');
	selector::add_type('*','All File Types');


	if ($changed == 1)
	{
		return if (dlg::yesno($mw,'The current file has changed, do you want to discard the changes ?','Discard Changes') eq 'No');
	}

	my $filename = selector::file($mw,'Open File','Open');
	return if (length($filename) == 0);

	if (open(IN,"$filename"))
	{
		my $i;

		chomp(my $ver = <IN>);

		if ($ver ne $version)
		{
			dlg::error($mw,"File is either incorrect version or corrupted",'Error');
			close(IN);
			return;
		}

		while (<IN>)
		{
			chomp;
			my ($key,$val) = /(\w+)\s*\=\s*(.*)/;

			$dataField{$key} = $val;
		}
		close(IN);

		if ($dataField{'check7'} == 1)
		{
			$chbtn[8]->configure(-state => 'normal');
			$chbtn[9]->configure(-state => 'normal');
		}
		else
		{
			$chbtn[8]->configure(-state => 'disabled');
			$chbtn[9]->configure(-state => 'disabled');
		}

		$current_filename = $filename;
		$changed = 0;
		set_title();
	}
	else
	{
		dlg::error($mw,"$filename : $!",'Error');
	}
}

#-------------------------------
# Reset data to initial defaults
#-------------------------------

sub reset_data
{
	my ($cmd) = @_;

	if ($changed == 1)
	{
		return if (dlg::yesno($mw,'The current file has changed, do you want to discard the changes ?','Discard Changes') eq 'No');
	}

	while (($key,$val) = each %entryField)
	{
		$dataField{$key} = '';
	}

	$dataField{'radio1'} = 0;
	for ($i=0; $i<12; $i++)
	{
		$dataField{"check$i"} = 0;
	}

	$dataField{'bootimage'} = '';
	$dataField{'bootcatalog'} = '';
	$dataField{'dircount'} = 0;
	$dataField{'filecount'} = 0;
	$dataField{'simulate'} = 0;
	$dataField{'eject'} = 1;

	$chbtn[8]->configure(-state => 'disabled');
	$chbtn[9]->configure(-state => 'disabled');

	if ($cmd eq 'defaults')
	{
		defaults::load();
		while(($key,$val) = each %defaults::item)
		{
			$dataField{$key} = $defaults::item{$key};
		}

		if ($dataField{'check7'} == 1)
		{
			$chbtn[8]->configure(-state => 'normal');
			$chbtn[9]->configure(-state => 'normal');
		}
		else
		{
			$chbtn[8]->configure(-state => 'disabled');
			$chbtn[9]->configure(-state => 'disabled');
		}

		$dataField{'writingspeed'} = 
				$defaults::item{'writingspeed'};
		$dataField{'devicetype'} = 
				$defaults::item{'devicetype'};
		$dataField{'devicename'} = 
				$defaults::item{'devicename'};
		$dataField{'use_program'} = 
				$defaults::item{'use_program'};
		
	}

	$current_filename = '';
	$changed = 0;
	set_title();

}

#------------------------
# Build the iso9660 image
#------------------------

sub build_image
{
	my $cmdline = 'mkisofs';
	my $src = $dataField{'srcpath'};
	my $dest = $dataField{'destpath'};

	chomp(my $which = `which mkisofs`);
	if (substr($which,0,1) ne '/')
	{
		dlg::error($mw,'mkisofs cannot be found on the path','Error');
		return;
	}

	if (length($src) == 0)
	{
		dlg::error($mw,'A source path must be specified','Error');
		return;
	}

	unless(-d $src)
	{
		dlg::error($mw,"$src is not a valid readable directory",'Error');
		return;
	}

	if (length($dest) == 0)
	{
		dlg::error($mw,'A destination file path must be specified','Error');
		return;
	}

	if (-r $dest)
	{
		return if (dlg::yesno($mw,"$dest exists. Overwrite ?",'Overwrite') eq 'No');
	}

	# Sort out command line
	$cmdline = "$cmdline -a" if ($dataField{'check0'} == 1);

	if (length($dataField{'bootimage'}) > 0)
	{
		my $t = $dataField{'bootimage'};
		$cmdline = "$cmdline -b '$t'";
	}

	if (length($dataField{'bootimage'}) > 0)
	{
		my $t = $dataField{'bootimage'};
		$cmdline = "$cmdline -b '$t'";
	}

	$cmdline = "$cmdline -f" if ($dataField{'check3'} == 1);
	$cmdline = "$cmdline -d" if ($dataField{'check1'} == 1);
	$cmdline = "$cmdline -D" if ($dataField{'check2'} == 1);
	$cmdline = "$cmdline -l" if ($dataField{'check4'} == 1);
	$cmdline = "$cmdline -L" if ($dataField{'check5'} == 1);
	$cmdline = "$cmdline -N" if ($dataField{'check6'} == 1);
	if ($dataField{'check7'} == 1)
	{
		$cmdline = "$cmdline -R" if ($dataField{'radio1'} == 8);
		$cmdline = "$cmdline -r" if ($dataField{'radio1'} == 9);
	}
	$cmdline = "$cmdline -T" if ($dataField{'check10'} == 1);
	$cmdline = "$cmdline -z" if ($dataField{'check11'} == 1);

	if (length($dataField{'bootimage'}) > 0)
	{
		my $t = $dataField{'bootimage'};
		$cmdline = "$cmdline -b '$t'";
	}

	if (length($dataField{'bootcatalog'}) > 0)
	{
		my $t = $dataField{'bootcatalog'};
		$cmdline = "$cmdline -c '$t'";
	}

	my $i;
	for ($i=0; $i < $dataField{'filecount'}; $i++)
	{
		my $t = $dataField{"file_$i"};
		$cmdline = "$cmdline -m '$t'";
	}

	for ($i=0; $i < $dataField{'dircount'}; $i++)
	{
		my $t = $dataField{"dir_$i"};
		$cmdline = "$cmdline -x '$t'";
	}

	$cmdline = "$cmdline -v -o $dest $src";

	# Sort out .mkisofsrc file
	my $filename = get_mkisofsrc_filename('new');

	system("mv $filename $filename.orig") if (-r $filename);

	open(OUT,">$filename");

	while (($key,$val) = each %entryField)
	{
		if (length($dataField{$key}) > $lengthField{$key})
		{
			dlg::error($mw,"The $key field has a maximum length of $lengthField{$key} characters",'Error');
			return;
		}
	}

	print OUT "APPI=",$dataField{'application'},"\n" 
		if (length($dataField{'application'}) > 0);
	print OUT "COPY=",$dataField{'copyright'},"\n" 
		if (length($dataField{'copyright'}) > 0);
	print OUT "PUBL=",$dataField{'publisher'},"\n" 
		if (length($dataField{'publisher'}) > 0);
	print OUT "PREP=",$dataField{'preparer'},"\n" 
		if (length($dataField{'preparer'}) > 0);
	print OUT "VOLI=",$dataField{'volumeid'},"\n" 
		if (length($dataField{'volumeid'}) > 0);
	print OUT "ABST=",$dataField{'abstract'},"\n" 
		if (length($dataField{'abstract'}) > 0);
	print OUT "BIBL=",$dataField{'bibliographic'},"\n" 
		if (length($dataField{'bibliographic'}) > 0);
	print OUT "SYSI=",$dataField{'systemid'},"\n" 
		if (length($dataField{'systemid'}) > 0);
	print OUT "VOLS=",$dataField{'volumeset'},"\n" 
		if (length($dataField{'volumeset'}) > 0);

	close(OUT);

	status::status_window(1,'Building ISO9660 Image');
	status::status_window(3,"Command Line: $cmdline\n");
	status::runCommand($cmdline);

	unlink($filename);
	system("mv $filename.orig $filename") if (-r "$filename.orig");

	dlg::error($mw,'Build Finished','Information');
	status::status_window(4);
}

#------------------------------------
# get the current .mkisofsrc filename
#------------------------------------

sub get_mkisofsrc_filename
{
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir);
	my ($cmd) = @_;

	if (length($ENV{'HOME'}) > 0)
	{
		$dir = $ENV{'HOME'};
	}
	else
	{
		($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir) = getpwuid($>);
	}
	my $filename = '';

	$dir = '' if ($dir eq '/');

	if (-r '.mkisofsrc')
	{
		$filename = '.mkisofsrc';
	}
	else
	{
		if (-r "$dir/.mkisofsrc")
		{
			$filename = "$dir/.mkisofsrc";
		}
		else
		{
			chomp(my $which = `which mkisofs`);
			if (substr($which,0,1) eq '/')
			{
				my @tmp = split('/',$which);
				$tmp[$#tmp] = '.mkisofsrc';
				$filename = join('/',@tmp);

			}
			
			if ($cmd eq 'new')
			{
				return "$dir/.mkisofsrc" unless (-r $filename);
			}
			else
			{
				return unless (-r $filename);
			}
		}
	}

	return $filename;
}

#---------------------------------
# Read the current .mkisofsrc file
#---------------------------------

sub read_mkisofsrc
{
	my ($appi,$copy,$abst,$bibl,$prep,$publ,$sysi,$vols);
	my $filename;

	return unless ($filename = get_mkisofsrc_filename());
	
	open(IN,$filename);
	while(<IN>)
	{
		chomp;
		study;

		next if ((/^#/)||(length($_) == 0));

		($dataField{'application'}) = /APPI\s*=\s*(.*)/ if (/APPI\s*=\s*(.*)/);
		($dataField{'copyright'}) = /COPY\s*=\s*(.*)/ if (/COPY\s*=\s*(.*)/);
		($dataField{'abstract'}) = /ABST\s*=\s*(.*)/ if (/ABST\s*=\s*(.*)/);
		($dataField{'bibliographic'}) = /BIBL\s*=\s*(.*)/ if (/BIBL\s*=\s*(.*)/);
		($dataField{'preparer'}) = /PREP\s*=\s*(.*)/ if (/PREP\s*=\s*(.*)/);
		($dataField{'publisher'}) = /PUBL\s*=\s*(.*)/ if (/PUBL\s*=\s*(.*)/);
		($dataField{'systemid'}) = /SYSI\s*=\s*(.*)/ if (/SYSI\s*=\s*(.*)/);
		($dataField{'volumeid'}) = /VOLI\s*=\s*(.*)/ if (/VOLI\s*=\s*(.*)/);
		($dataField{'volumeset'}) = /VOLS\s*=\s*(.*)/ if (/VOLS\s*=\s*(.*)/);
	}
	close(IN);
}

#-----------------
# Function to quit
#-----------------

sub do_quit
{
	if ($changed == 1)
	{
		return if (dlg::yesno($mw, 'Project has changed, Quit without saving ?','Quit')			 eq 'No');
	}

	destroy $mw;
}

#-------------------------------------------------------
# Function to copy the main fields to the defaults field
#-------------------------------------------------------

sub copy_over
{
	while (($key,$val) = each %entryField)
	{
		$defaults::item{$key} = $dataField{$key};
	}

	$defaults::item{'radio1'} = $dataField{'radio1'};

	for ($i=0; $i<12; $i++)
	{
		$defaults::item{"check$i"} = $dataField{"check$i"};
	}

	defaults::save();
}
