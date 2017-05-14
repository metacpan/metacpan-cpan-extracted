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

package selector;

use wcenter;
use Tk::BrowseEntry;

#---------------------------------
# Reset the file types filter list
#---------------------------------

sub add_type
{
	my ($ext,$desc) = @_;

	push(@selector::types,"$ext!!!$desc");
}

sub reset_types
{
	undef @selector::types;
}

#------------------------
# Display the file dialog
#------------------------

sub file
{
	my ($parent,$title,$name,$rt) = @_;

	$parent->Busy;

	if (length($rt) == 0)
	{
		if (length($selector::root) == 0)
		{
			chomp ($selector::root = `pwd`);
		}
	}
	else
	{
		$selector::root = $rt;
	}

	if ($#selector::types == -1)
	{
		add_type('*','All File Types');
	}

	my $popup = $parent->Toplevel;
	$popup->title($title);
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,140,235);

	$selector::top = $popup;

	#---------------------
	# where frame
	#---------------------

	my $whereFrame = $popup->Frame->pack(
		-pady => 5,
		-side => 'top');

	$whereFrame->Label(
		-text => 'Current Location')->pack(
			-padx => 5,
			-side => 'left');

	$whereFrame->Button(
		-command => sub{upbutton()},
		-text => 'Up',
		-activebackground => 'grey80',
		-borderwidth => 1)->pack(
			-padx => 5,
			-side => 'right');

	$selector::whereEntry = $whereFrame->Entry(
		-background => 'AntiqueWhite',
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 50,
		-font => '8x13',
		-highlightthickness => 0)->pack(
			-side => 'right',
			-padx => 5);

	$selector::whereEntry->insert('end',$selector::root);
	$selector::whereEntry->bindtags('all');

	#---------------------
	# Top  & bottom frames
	#---------------------

	my $topFrame = $popup->Frame->pack(
		-side => 'top',
		-fill => 'both',
		-expand => 'yes');

	my $bottomFrame = $popup->Frame->pack(
		-side => 'bottom',
		-fill => 'x');

	#-------------------
	# The directory list
	#-------------------

	my $dirFrame = $topFrame->Frame->pack(
		-padx => 5,
		-side => 'left',
		-expand => 'yes',
		-fill => 'both');

	$dirFrame->Label(
		-text => 'Directories',
		-foreground => 'red4')->pack(
			-pady => 5,
			-side => 'top');

	my $dirListFrame = $dirFrame->Frame->pack(
		-side => 'top',
		-expand => 'yes',
		-fill => 'both');

	my $dirListScrollbar = $dirListFrame->Scrollbar->pack(
		-side => 'right',
		-fill => 'y');
		
	$selector::dirListBox = $dirListFrame->Listbox(
		-width => 30,
		-font => '8x13',
		-background => 'PapayaWhip',
		-yscrollcommand => [$dirListScrollbar => 'set'])->pack(
			-side => 'left',
			-expand => 'yes',
			-fill => 'both');

	$dirListScrollbar->configure(-command => [$dirListBox => 'yview']);
		
	$selector::dirListBox->bind('<Double-1>' =>
		sub {
			double_dir();
		});

	#--------------
	# The file list
	#--------------

	my $fileFrame = $topFrame->Frame->pack(
		-side => 'right',
		-padx => 5,
		-expand => 'yes',
		-fill => 'both');

	$fileFrame->Label(
		-text => 'Files',
		-foreground => 'red4')->pack(
			-pady => 5,
			-side => 'top');

	my $fileListFrame = $fileFrame->Frame->pack(
		-side => 'top',
		-expand => 'yes',
		-fill => 'both');

	my $fileListScrollbar = $fileListFrame->Scrollbar->pack(
		-side => 'right',
		-fill => 'y');
		
	$selector::fileListBox = $fileListFrame->Listbox(
		-width => 30,
		-font => '8x13',
		-background => 'PapayaWhip',
		-yscrollcommand => [$fileListScrollbar => 'set'])->pack(
			-side => 'left',
			-expand => 'yes',
			-fill => 'both');

	$fileListScrollbar->configure(-command => [$fileListBox => 'yview']);

	$selector::fileListBox->bind('<Double-1>' =>
		sub {
			double_file();
		});

	$selector::fileListBox->bind('<1>' =>
		sub {
			single_file();
		});

	#--------------------
	# The Command Buttons
	#--------------------

	my $buttonFrame = $bottomFrame->Frame->pack(
		-side => 'right',
		-pady => 5);

	$selector::actionButton = $buttonFrame->Button(
		-state => 'disabled',
		-command => sub{action_button()},
		-text => $name,
		-activebackground => 'grey80',
		-borderwidth => 1)->pack(
			-padx => 5,
			-pady => 2,
			-side => 'top',
			-anchor => 'w');

	$buttonFrame->Button(
		-command => sub{$selector::final = ''},
		-activebackground => 'grey80',
		-text => 'Cancel',
		-borderwidth => 1)->pack(
			-padx => 5,
			-pady => 2,
			-side => 'top',
			-anchor => 'w');
	
	#------------------
	# Other information
	#------------------

	my $infoFrame = $bottomFrame->Frame->pack(
		-side => 'left',
		-fill => 'both',
		-pady => 5);

	#-----------------
	# The Filename Box
	#-----------------

	my $filenameFrame = $infoFrame->Frame->pack(
		-side => 'top',
		-fill => 'x',
		-pady => 5);

	$filenameFrame->Label(
		-text => 'File Name')->pack(
			-padx => 5,
			-side => 'left');

	$selector::filenameEntry = $filenameFrame->Entry(
		-font => '8x13',
		-background => 'PapayaWhip',
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 50,
		-highlightthickness => 0)->pack(
			-side => 'right',
			-padx => 5);

	$selector::filenameEntry->bind('<KeyPress>' =>
	sub {
		my $current = get $selector::filenameEntry;
		if (length($current) == 0)
		{
			$selector::actionButton->configure(-state => 'disabled');
		}
		else
		{
			$selector::actionButton->configure(-state => 'normal');
		}
	});

	$selector::filenameEntry->bind('<Key-Return>' =>
	sub {
		action_button();
	});

	#-----------------
	# The file type box
	#-----------------

	my $filetypeFrame = $infoFrame->Frame->pack(
		-side => 'top',
		-fill => 'x',
		-pady => 5);

	$filetypeFrame->Label(
		-text => 'File Type')->pack(
			-padx => 5,
			-side => 'left');

	 my $filetypeSelect = $filetypeFrame->BrowseEntry(
		-variable => \$browse_var,
		-width => 53)->pack(
			-side => 'right');

	my $c = 0;
	foreach(@selector::types)
	{
		my ($ext, $desc) = split('!!!');
	 	$filetypeSelect->insert('end',"$desc (.$ext)");

		$browse_var = "$desc (.$ext)" if ($c == 0);

		$c++;
	}

	my $bpm = $filetypeFrame->Pixmap(
		-file => "$main::ROOT/misc_icons/down.xpm");

	$filetypeSelect->Subwidget("arrow")->configure(
		-image => $bpm);
	$filetypeSelect->Subwidget("entry")->Subwidget("entry")->configure(
		-background => 'PapayaWhip');
	$filetypeSelect->Subwidget("slistbox")->configure(
		-background => 'PapayaWhip');

	$filetypeSelect->Subwidget("slistbox")->bind('<1>' =>
		sub {
			set_filter($filetypeSelect);
		});

	my $cmd =  $filetypeSelect->Subwidget("slistbox")->
				Subwidget("listbox")->bind('<ButtonRelease-1>');
	$filetypeSelect->Subwidget("slistbox")->
				Subwidget("listbox")->bind('<ButtonRelease-1>' =>
		sub {
			&$cmd;
			set_filter($filetypeSelect);
		});

	display_filter();

	my $old_focus = $popup->focusSave;
    my $old_grab  = $popup->grabSave;

	$popup->grab;
	$popup->focus;

	$popup->bind('<FocusOut>' => sub {
		$popup->focus;
	});
		
	#-------------------------------
	# Load in the initial file lists
	#-------------------------------
		
	load_lists();

	$selector::final = '';

	$parent->Unbusy;

	$popup->waitVariable(\$selector::final);

	$popup->grabRelease;
	&$old_focus;
	&$old_grab;

	destroy $popup;
	return $selector::final;
}

#---------------------------
# Load the files and dirs in
#---------------------------

sub load_lists
{
	opendir(LS,$selector::root) || die "$dir : $!";
	chomp(my @dirlist = readdir(LS));
	closedir(LS);

	$selector::dirListBox->delete(0,$#dirs);
	$selector::fileListBox->delete(0,$#files);

	undef @selector::dirs;
	undef @selector::files;

	if ($selector::root ne '/')
	{
		push(@dirs, '<..>');
		$selector::dirListBox->insert('end', '<..>');
	}

	foreach $filename (@dirlist)
	{
		$_ = $filename;
		next if (($_ eq ".") || ($_ eq ".."));

		my ($dev, $ino, $mode, $nlink, $uid)
			= lstat("$selector::root/$filename");

		
		if (($mode & 0170000) == 0040000)
		{
			push(@dirs, $filename);
			$selector::dirListBox->insert('end', $filename);
		}
		else
		{
			my $len = length($selector::currentFilter)+1;
			my $end = substr($filename, -$len,$len);
			next unless (($end eq ".$selector::currentFilter") ||
				     ($selector::currentFilter eq '*'));	

			push(@files, $filename);
			$selector::fileListBox->insert('end', $filename);
		}
	}
}						   

#------------------------------------------------
# Function to handle double clicks on the dir box
#------------------------------------------------

sub double_dir
{
	my $new_dir = $selector::root;
	my $index = $selector::dirListBox->curselection;

	if ($selector::dirs[$index] ne '<..>')
	{
		if ($selector::root ne '/')
		{
			$new_dir = "$new_dir/$selector::dirs[$index]";
		}
		else
		{
			$new_dir = "/$selector::dirs[$index]";
		}
	}
	else
	{
		my @tmp = split('/', $new_dir);
		$#tmp--;
		$new_dir = join('/',@tmp);

		$new_dir = '/' if (length($new_dir) == 0);
	}

	if (opendir(LS,$new_dir))
	{
		closedir(LS);
		$selector::root = $new_dir;
		$selector::whereEntry->delete('0.0','end');
		$selector::whereEntry->insert('end',$selector::root);
		load_lists();
		$selector::filenameEntry->delete('0.0','end');
		$selector::actionButton->configure(-state => 'disabled');
	}

}

#------------------------------------------------
# Function to handle single clicks on the file box
#------------------------------------------------

sub single_file
{
	my $index = $selector::fileListBox->curselection;

	$selector::filenameEntry->delete('0.0','end');
	$selector::filenameEntry->insert('0.0',$selector::files[$index]);
	$selector::actionButton->configure(-state => 'normal');
}

#------------------------------------------------
# Function to handle double clicks on the file box
#------------------------------------------------

sub double_file
{
	my $index = $selector::fileListBox->curselection;

	if ($selector::root eq '/')
	{
		$selector::final = "/$selector::files[$index]";
	}
	else
	{
		$selector::final = "$selector::root/$selector::files[$index]";
	}
}

#---------------------------------
# Function to handle the up-button
#---------------------------------

sub upbutton
{
	my @tmp = split('/', $selector::root);
	$#tmp--;
	$selector::root = join('/',@tmp);

	$selector::root = '/' if (length($selector::root) == 0);

	$selector::whereEntry->delete('0.0','end');
	$selector::whereEntry->insert('end',$selector::root);
	load_lists();
	$selector::filenameEntry->delete('0.0','end');
	$selector::actionButton->configure(-state => 'disabled');
}

#--------------------------------
# Function to set the filter type
#--------------------------------

sub set_filter
{
	my ($widget) = @_;

	$cur = $widget->Subwidget("slistbox")->curselection;

	my ($ext, $desc) = split('!!!',$selector::types[$cur]);
	
	$selector::currentFilter = $ext;

	load_lists();

	$selector::filenameEntry->delete('0.0','end');
	$selector::actionButton->configure(-state => 'disabled');
}

sub display_filter
{
	my ($ext, $desc);

	if (length($selector::currentFilter) == 0)
	{
		($ext,$desc) = split('!!!', $selector::types[0]);
	}
	else
	{
		foreach(@selector::types)
		{
			($ext, $desc) = split('!!!');
			last if ($ext eq $selector::currentFilter);
		}
	}

	$selector::currentFilter = $ext;
}

#---------------------------------------------------
# Function to handle the action button being pressed
#---------------------------------------------------

sub action_button
{
	my $filename = get $selector::filenameEntry;

	return if (length($filename) == 0);

	my $len = length($selector::currentFilter)+1;
	my $end = substr($filename, -$len,$len);

	if (($end ne ".$selector::currentFilter")&&
	    ($selector::currentFilter ne '*'))
	{
		$filename = "$filename.$selector::currentFilter";
	}

	if ($selector::root eq '/')
	{
		$selector::final = "/$filename";
	}
	else
	{
		$selector::final = "$selector::root/$filename";
	}
}

1;
