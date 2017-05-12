##################################################
##################################################
##                                              ##
##   JFileDialog v. 1.34 - a reusable Tk-widget ##
##      (c) 1996-2007 by Jim Turner             ##
##      --Derived 12/11/96 by Jim W. Turner--   ##
##      --from FileDialog                       ##
##                                              ##
##   by:  Brent B. Powers                       ##
##   Merrill Lynch                              ##
##   powers@swaps-comm.ml.com                   ##
##                                              ##
##################################################
##################################################

=head1 NAME

Tk::JFileDialog - A highly configurable File Dialog widget for Perl/Tk.  

=head1 DESCRIPTION

The widget is composed of a number
of sub-widgets, namely, a listbox for files and (optionally) directories, an entry
for filename, an (optional) entry for pathname, an entry for a filter pattern, a 'ShowAll'
checkbox (for enabling display of .* files and directories), and three buttons, namely
OK, Rescan, and Cancel.  Note that the labels for all subwidgets (including the text
for the buttons and Checkbox) are configurable for foreign language support.

=head1 SYNOPSIS

 my $LoadDialog = $main->JFileDialog(
 	-Title =>'Please select a file:',
 	-Create => 0
 );

=head2 Usage Description

To use FileDialog, simply create your FileDialog objects during initialization (or at
least before a Show).  When you wish to display the FileDialog, invoke the 'Show' method
on the FileDialog object;  The method will return either a file name, a path name, or
undef.  undef is returned only if the user pressed the Cancel button.

=head2 Example Code

The following code creates a FileDialog and calls it.  Note that perl5.002gamma is
required.

=item

 #!/usr/local/bin/perl -w

 use Tk;
 use Tk::JFileDialog;
 use strict;

 my($main) = MainWindow->new;
 my($Horiz) = 1;
 my($fname);

 my($LoadDialog) = $main->JFileDialog(-Title =>'This is my title',
 				    -Create => 0);

 $LoadDialog->configure(-FPat => '*pl',
 		       -ShowAll => 'NO');

 $main->Entry(-textvariable => \$fname)
 	->pack(-expand => 1,
 	       -fill => 'x');

 $main->Button(-text => 'Kick me!',
 	      -command => sub {
 		  $fname = $LoadDialog->Show(-Horiz => $Horiz);
 		  if (!defined($fname)) {
 		      $fname = "Fine,Cancel, but no Chdir anymore!!!";
 		      $LoadDialog->configure(-Chdir =>'NO');
 		  }
 	      })
 	->pack(-expand => 1,
 	       -fill => 'x');

 $main->Checkbutton(-text => 'Horizontal',
 		   -variable => \$Horiz)
 	->pack(-expand => 1,
 	       -fill => 'x');

 $main->Button(-text => 'Exit',
 	      -command => sub {
 		  $main->destroy;
 	      })
 	->pack(-expand => 1,
 	       -fill => 'x');

 MainLoop;

 print "Exit Stage right!\n";

 exit;

=head1 METHODS

The following non-standard method may be used with a FileDialog object

=head2 Show

=over 4

Displays the file dialog box for the user to operate.  Additional configuration
items may be passed in at Show-time In other words, this code snippet:

  $fd->Show(-Title => 'Ooooh, Preeeeeety!');

is the same as this code snippet:

  $fd->configure(-Title => 'Ooooh, Preeeeeety!');
  $fd->Show;

=head1 CONFIGURATION

	Any of the following configuration items may be set via the configure (or Show) method,
or retrieved via the cget method.

=head2 I<Flags>

Flags may be configured with either 1,'true', or 'yes' for 1, or 0, 'false', or 'no'
for 0. Any portion of 'true', 'yes', 'false', or 'no' may be used, and case does not
matter.

=head2 -Chdir

Enable the user to change directories. The default is 1. If disabled, the directory
list box will not be shown.

=head2 -Create

Enable the user to specify a file that does not exist. If not enabled, and the user
specifies a non-existent file, a dialog box will be shown informing the user of the
error (This Dialog Box is configurable via the EDlg* switches, below).

default: 1

=head2 -ShowAll

Determines whether hidden files (.*) are displayed in the File and Directory Listboxes.
The default is 0. The Show All Checkbox reflects the setting of this switch.

=head2 -DisableShowAll

Disables the ability of the user to change the status of the ShowAll flag. The default
is 0 (the user is by default allowed to change the status).

=head2 -DisableFPat

Disables the ability of the user to change the file selection pattern. The default
is 0 (the user is by default allowed to change the status).

=head2 -Grab

Enables the File Dialog to do an application Grab when displayed. The default is 1.

=head2 -History

Used with the "-HistFile" option.  Specifies how many files to retain in the 
history list.  The default is 0 (keep all).

=head2 -HistDeleteOk

If set, allows user to delete items from the history dropdown list and thus the 
history file.

=head2 -HistUsePath

If set, the path is set to that of the last file selected from the history.

=head2 -HistUsePathButton

If set, the path is set to that of the last file selected from the history.

=head2 -HistFile

Enables the keeping of a history of the previous files / directories selected.  
The file specified must be writable.  If specified, a history of up to 
"-History" number of files will be kept and will be displayed in a "JBrowseEntry" 
combo-box permitting user selection.

=head2 -PathFile

Specifies a file containing a list of "favorite paths" bookmarks to show in a 
dropdown list allowing quick-changes in directories.

=head2 -Horiz

True sets the File List box to be to the right of the Directory List Box. If 0, the
File List box will be below the Directory List box. The default is 1.

=head2 -QuickSelect

Default 1, if set to 0, user must invoke the "OK" button to complete selection. 
If 1 or 2, clicking item in the history menu automatically completes the 
selection.  If 2, single-clicking a file in the file list completes selection
(otherwise, a double-click is required).

=head2 -SelDir

If 1 or 2, enables selection of a directory rather than a file, and disables the
actions of the File List Box. Setting to 2 allows selection of either a file OR a directory.  The default is 0.

=head2 I<Special>

=head2 -FPat

Sets the default file selection pattern. The default is '*'. Only files matching
this pattern will be displayed in the File List Box.

=head2 -Geometry

Sets the geometry of the File Dialog. Setting the size is a dangerous thing to do.
If not configured, or set to '', the File Dialog will be centered.

=head2 -SelHook

SelHook is configured with a reference to a routine that will be called when a file
is chosen. The file is called with a sole parameter of the full path and file name
of the file chosen. If the Create flag is disabled (and the user is not allowed
to specify new files), the file will be known to exist at the time that SelHook is
called. Note that SelHook will also be called with directories if the SelDir Flag
is enabled, and that the FileDialog box will still be displayed. The FileDialog box
should B<not> be destroyed from within the SelHook routine, although it may generally
be configured.

SelHook routines return 0 to reject the selection and allow the user to reselect, and
any other value to accept the selection. If a SelHook routine returns non-zero, the
FileDialog will immediately be withdrawn, and the file will be returned to the caller.

There may be only one SelHook routine active at any time. Configuring the SelHook
routine replaces any existing SelHook routine. Configuring the SelHook routine with
0 removes the SelHook routine. The default SelHook routine is undef.

=head2 I<Strings>

The following two switches may be used to set default variables, and to get final
values after the Show method has returned (but has not been explicitly destroyed
by the caller)

=head2 -SelectMode
 
Sets the selectmode of the File Dialog.  If not configured it will be defaulted
to 'single'.  If set to 'multiple', then the user may select more than one file 
and a comma-delimited list of all selected files is returned.  Otherwise, only 
a single file may be selected.  
 
B<-File>  The file selected, or the default file. The default is ''.

B<-Path>  The path of the selected file, or the initial path. The default is $ENV{'HOME'}.

=head2 I<Labels and Captions>

For support of internationalization, the text on any of the subwidgets may be
changed.

B<-Title>  The Title of the dialog box. The default is 'Select File:'.

B<-DirLBCaption>  The Caption above the Directory List Box. The default is 'Directories'.

B<-FileLBCaption>  The Caption above the File List Box. The default is 'Files'.

B<-FileEntryLabel>  The label to the left of the File Entry. The Default is 'Filename:'.

B<-PathEntryLabel>  The label to the left of the Path Entry. The default is 'Pathname:'.

B<-FltEntryLabel>  The label to the left of the Filter entry. The default is 'Filter:'.

B<-ShowAllLabel>  The text of the Show All Checkbutton. The default is 'Show All'.

=head2 I<Button Text>

For support of internationalization, the text on the three buttons may be changed.

B<-OKButtonLabel>  The text for the OK button. The default is 'OK'.

B<-RescanButtonLabel>  The text for the Rescan button. The default is 'Refresh'.

B<-CancelButtonLabel>  The text for the Cancel button. The default is 'Cancel'.

B<-HomeButtonLabel>  The text for the Home directory button. The default is 'Home'.

B<-CWDButtonLabel>  The text for the Current Working Directory button. 
The default is 'C~WD'.

B<-SortButton>  Whether or not to display a checkbox to change file box list sort order (default=1 show).

B<-SortButtonLabel>  The text for the Sort/Atime button. The default is 'Atime'.

B<-SortOrder>  Order to display files in the file list box ('Name' or 'Date' default=Name).
If 'Date', then the day and time is displayed in the box before the name, 
(but not included when selected)

=head2 I<Error Dialog Switches>

If the Create switch is set to 0, and the user specifies a file that does not exist,
a dialog box will be displayed informing the user of the error. These switches allow
some configuration of that dialog box.

=head2 -EDlgTitle

The title of the Error Dialog Box. The default is 'File does not exist!'.

=head2 -EDlgText

The message of the Error Dialog Box. The variables $path, $file, and $filename
(the full path and filename of the selected file) are available. The default
is I<"You must specify an existing file.\n(\$filename not found)">

=head1 Author

B<Jim Turner>

turnerjw at mesh . net

A derived work from Tk::FileDialog, by:

B<Brent B. Powers, Merrill Lynch (B2Pi)>

powers@ml.com

This code may be distributed under the same conditions as Perl itself.

=cut

package Tk::JFileDialog;

use vars qw($VERSION);
$VERSION = '1.62';

require 5.002;
use Tk;
use Tk::Dialog;
use Tk::JBrowseEntry;
use Carp;
use strict;
use Cwd;
use File::Glob; 
my $useAutoScroll = 0;
eval 'use Tk::Autoscroll; $useAutoScroll = 1; 1';

my $Win32 = 0;
$Win32 = ($^O =~ /Win/i) ? 1 : 0;

my $driveletter = '';

@Tk::JFileDialog::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('JFileDialog');

### Global Variables (Convenience only)
my(@topPack) = (-side => 'top', -anchor => 'center');
my(@rightPack) = (-side => 'right', -anchor => 'center');
my(@leftPack) = (-side => 'left', -anchor => 'center');
my(@xfill) = (-fill => 'x');
my(@yfill) = (-fill => 'y');
my(@bothFill) = (-fill => 'both');
my(@expand) = (-expand => 1);
my(@raised) = (-relief => 'raised');
my(@sunken) = (-relief => 'sunken');
my (@driveletters);
my ($cwdDfltDrive);


sub Populate
{
	## File Dialog constructor, inherits new from Toplevel
	my($FDialog, @args) = @_;

	$FDialog->SUPER::Populate(@args);
	$FDialog->{Configure}{-SortButton} = 1;   #DEFAULT UNLESS SET BY USER TO ZERO!
	foreach my $i (keys %{$args[0]})
	{
#x		if ($i eq '-HistFile' || $i eq '-History' || $i eq 'QuickSelect'
#x				|| $i eq '-PathFile' || $i eq '-HistDeleteOk' 
#x				|| $i eq '-HistUsePath' || $i eq '-HistUsePathButton')
		if ($i =~ /^\-(?:HistFile|History|QuickSelect|PathFile|HistDeleteOk|HistUsePath|HistUsePathButton|SortButton|SelDir)$/)
		{
			$FDialog->{Configure}{$i} = $args[0]->{$i};
		}
	}
	$FDialog->bind("<Control-Tab>",sub
	{
		my $self = shift;
		$self->focusPrev();
		Tk->break;
	});
	
	$FDialog->withdraw;
	
	if ($^O =~ /Win/i)
	{
		$cwdDfltDrive = substr(&cwd(),0,2);
		$cwdDfltDrive ||= substr(&getcwd(),0,2);
	}
	else
	{
		$FDialog->protocol('WM_DELETE_WINDOW' => sub
		{
			if (defined($FDialog->{'Can'}) && $FDialog->{'Can'}->IsWidget )
			{
				$FDialog->{'Can'}->invoke;
			}
		}
		);
#JWT???		$FDialog->transient($FDialog->toplevel);
	}
	## Initialize variables that won't be initialized later
	$FDialog->{'Retval'} = -1;
	$FDialog->{'DFFrame'} = 0;
	
	$FDialog->{Configure}{-Horiz} = 1;
	$FDialog->{Configure}{-SortOrder} = 'Name';
	
	$FDialog->BuildFDWindow;
	#$FDialog->{'activefore'} = $FDialog->{'SABox'}->cget(-foreground);
	$FDialog->{'inactivefore'} = $FDialog->{'SABox'}->cget(-disabledforeground);
	
	$FDialog->ConfigSpecs(-Chdir		=> ['PASSIVE', undef, undef, 1],
			-Create		=> ['PASSIVE', undef, undef, 1],
			-DisableShowAll	=> ['PASSIVE', undef, undef, 0],
			-DisableFPat	=> ['PASSIVE', undef, undef, 0],
			-FPat			=> ['PASSIVE', undef, undef, '*'],
			-File			=> ['PASSIVE', undef, undef, ''],
			-Geometry		=> ['PASSIVE', undef, undef, undef],
			-Grab			=> ['PASSIVE', undef, undef, 1],
			-Horiz		=> ['PASSIVE', undef, undef, 1],
			-Path			=> ['PASSIVE', undef, undef, "$ENV{'HOME'}"],
			-SelDir		=> ['PASSIVE', undef, undef, 0],
			-SortButton		=> ['PASSIVE', undef, undef, 1],
			-SortOrder		=> ['PASSIVE', undef, undef, 'Name'],
			-DirLBCaption		=> ['PASSIVE', undef, undef, 'Directories:'],
			-FileLBCaption	=> ['PASSIVE', undef, undef, 'Files:'],
			-FileEntryLabel	=> ['METHOD', undef, undef, 'Filename:'],
			-PathEntryLabel	=> ['METHOD', undef, undef, 'Pathname:'],
			-HistEntryLabel	=> ['METHOD', undef, undef, 'History:'],
			-FavEntryLabel	=> ['METHOD', undef, undef, 'Favorite Paths:'],
			-FltEntryLabel	=> ['METHOD', undef, undef, 'Filter:'],
			-ShowAllLabel		=> ['METHOD', undef, undef, 'ShowAll'],
			-OKButtonLabel	=> ['METHOD', undef, undef, '~OK'],
			-RescanButtonLabel	=> ['METHOD', undef, undef, '~Refresh'],
			-SortButtonLabel	=> ['METHOD', undef, undef, '~Atime'],
			-CancelButtonLabel	=> ['METHOD', undef, undef, '~Cancel'],
			-HomeButtonLabel	=> ['METHOD', undef, undef, '~Home'],
			-CWDButtonLabel	=> ['METHOD', undef, undef, 'C~WD'],
			-SelHook		=> ['PASSIVE', undef, undef, undef],
			-SelectMode => ['PASSIVE', undef, undef, 'single'],   #ADDED 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
			-ShowAll		=> ['PASSIVE', undef, undef, 0],
			-Title		=> ['PASSIVE', undef, undef, "Select File:"],
			-EDlgTitle		=> ['PASSIVE', undef, undef,
	'File does not exist!'],
			-History => ['PASSIVE', undef, undef, 0],
			-HistFile => ['PASSIVE', undef, undef, undef],
			-HistDeleteOk => ['PASSIVE', undef, undef, undef],
			-HistUsePath => ['PASSIVE', undef, undef, undef],
			-HistUsePathButton => ['PASSIVE', undef, undef, 0],
			-PathFile => ['PASSIVE', undef, undef, undef],
			-QuickSelect => ['PASSIVE', undef, undef, 1],
			-DestroyOnHide => ['PASSIVE', undef, undef, 0],
			-EDlgText		=> ['PASSIVE', undef, undef,
	"You must specify an existing file.\n"
			. "(\$filename not found)"]);
}

### A few methods for configuration
sub OKButtonLabel
{
	&SetButton('OK',@_);
}
sub RescanButtonLabel
{
	&SetButton('Rescan',@_);
}
sub SortButtonLabel
{
	my $self = $_[0];
	&SetButton('SortxButton',@_)  if (defined $self->{'SortxButton'}) ;
}
sub CancelButtonLabel
{
	&SetButton('Can',@_);
}
sub HomeButtonLabel
{
	&SetButton('Home',@_);
}
sub CWDButtonLabel
{
	&SetButton('Current',@_);
}

sub SetButton
{
	my($widg, $self, $title) = @_;
	if (defined($title))
	{
		my ($underlinepos) = ($title =~ s/^(.*)~/$1/) ? length($1): undef;
		## This is a configure
		$self->{$widg}->configure(-text => $title);
		if (defined($underlinepos) && $underlinepos >= 0)
		{
			$self->{$widg}->configure(-underline => $underlinepos);
			my ($mychar) = substr($title,$underlinepos,1);
			$self->bind("<Alt-\l$mychar>",sub {$self->{$widg}->Invoke;});
		}
	}
	## Return the current value
	$self->{$widg}->cget(-text);
	$self->{$widg}->bind("<Return>",sub {$self->{$widg}->Invoke;});
}

sub HistEntryLabel
{
	&SetLabel('HEF', @_);
}
sub FavEntryLabel
{
	&SetLabel('FAV', @_);
}
sub FileEntryLabel
{
	&SetLabel('FEF', @_);
}
sub PathEntryLabel
{
	&SetLabel('PEF', @_);
}
sub FltEntryLabel
{
	&SetLabel('patFrame', @_);
}
sub ShowAllLabel
{
	&SetButton('SABox', @_);
}
sub SetLabel
{
	my($widg, $self, $title) = @_;
	if (defined($title))
	{
		## This is a configure
		$self->{$widg}->{'Label'}->configure(-text => $title);
	}
	## Return the current value
	$self->{$widg}->{'Label'}->cget(-text);
}

sub SetFlag
{
	## Set the given flag to either 1 or 0, as appropriate
	my($self, $flag, $dflt) = @_;
	
	$flag = "-$flag";
	
	## We know it's defined as there was a ConfigDefault call after the Populate
	## call.  Therefore, all we have to do is parse the non-numerics
	if (&IsNum($self->{Configure}{$flag}))
	{
		$self->{Configure}{$flag} = 1 unless $self->{Configure}{$flag} == 0;
	}
	else
	{
		my($val) = $self->{Configure}{$flag};
		
		my($fc) = lc(substr($val,0,1));
		
		if (($fc eq 'y') || ($fc eq 't'))
		{
			$val = 1;
		}
		elsif (($fc eq 'n') || ($fc eq 'f'))
		{
			$val = 0;
		}
		else
		{
			## bad value, complain about it
			carp ("\"$val\" is not a valid flag ($flag)!");
			$dflt = 0 if !defined($dflt);
			$val = $dflt;
		}
		$self->{Configure}{$flag} = $val;
	}
	return $self->{Configure}{$flag};
}

sub Show
{
	my ($self) = shift;
	
    my $old_focus = $self->focusSave;
    my $old_grab = $self->grabSave;
	$self->configure(@_);
	
	## Clean up flag variables
	$self->SetFlag('Chdir');
	$self->SetFlag('Create');
	$self->SetFlag('ShowAll');
	$self->SetFlag('DisableShowAll');
	$self->SetFlag('DisableFPat');    #ADDED 20050126.
	$self->SetFlag('Horiz');
	$self->SetFlag('Grab');
	#$self->SetFlag('SelDir');
	
	## Set up, or remove, the directory box
	&BuildListBoxes($self);
	## Enable, or disable, the show all box
	if ($self->{Configure}{-DisableShowAll})
	{
		$self->{'SABox'}->configure(-state => 'disabled');
	}
	else
	{
		$self->{'SABox'}->configure(-state => 'normal');
	}
	$self->{'FPat'}->configure(-state => ($self->{Configure}{-DisableFPat})
			? 'disabled' : 'normal');    #ADDED 20050126.
	## Enable or disable the file entry box
	if ($self->{Configure}{-SelDir} == 1)
	{
		$self->{Configure}{-File} = '';
		$self->{'FileEntry'}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'});
		$self->{'FileList'}->configure(-selectforeground => $self->{'inactivefore'});
		$self->{'FileList'}->configure(-foreground => $self->{'inactivefore'});
	}	
	## Set the title
	$self->title($self->{Configure}{-Title});
	
	## Create window position (Center unless configured)
	$self->update;
	if (defined($self->{Configure}{-Geometry}))
	{
		$self->geometry($self->{Configure}{-Geometry});
	}
	else
	{
		my($x,$y);
		$x = int(($self->screenwidth - $self->reqwidth)/2 - $self->parent->vrootx);
		$y = int(($self->screenheight - $self->reqheight)/2 - $self->parent->vrooty);
		$self->geometry("+$x+$y");
	}
	
	## Fill the list boxes
	&RescanFiles($self);
	## Restore the window, and go
	$self->update;
	$self->deiconify;
	
	## Set up the grab
	$self->grab if ($self->{Configure}{-Grab});
	
	## Initialize status variables
	$self->{'Retval'} = 0;
	$self->{'RetFile'} = "";
	
	if ($self->{Configure}{-SelDir} == 1)   # !!!
	{
		$self->{'DirEntry'}->focus;
	}
	else
	{
		$self->{'FileEntry'}->focus;
	}
	select(undef, undef, undef, 0.1)  if ($ENV{DESKTOP_SESSION} =~ /AfterStep version 2.2.1[2-9]/i);  #JWT:ADDED FANCY SLEEP FUNCTION 20140606 B/C TO GET AFTERSTEP TO GIVE "TRANSIENT" WINDOWS THE FOCUS?!;
	my($i) = 0;
	while (!$i)
	{
		$self->tkwait('variable',\$self->{'Retval'});
		$i = $self->{'Retval'};
		if ($i != -1)
		{
			## No cancel, so call the hook if it's defined
			if (defined($self->{Configure}{-SelHook}))
			{
				## The hook returns 0 to ignore the result,
				## non-zero to accept.  Must release the grab before calling
				$self->grab('release') if (defined($self->grab('current')));
				
				$i = &{$self->{Configure}{-SelHook}}($self->{'RetFile'});
				
				$self->grab if ($self->{Configure}{-Grab});
			}
		}
		else
		{
			$self->{'RetFile'} = undef;
		}
	}
	
	$self->grab('release') if (defined($self->grab('current')));
    &$old_focus;
    &$old_grab;
#	$self->parent->focus();
	($self->{Configure}{-DestroyOnHide} == 1) ? $self->destroy : $self->withdraw;
	return $self->{'RetFile'};
}

sub getLastPath
{
	my ($self) = shift;
	
	my $path = $self->{Configure}{-Path};
	$path = $driveletter . $path  if ($driveletter && $^O =~ /Win/i);
	return $path;
}

sub getHistUsePathButton
{
	my ($self) = shift;
	
	return 0  unless (defined $self->{"histToggleVal"});
	return $self->{"histToggleVal"};
}

####  PRIVATE METHODS AND SUBROUTINES ####
sub IsNum
{
	my($parm) = @_;
	my($warnSave) = $_;
	$_ = 0;
	my($res) = (($parm + 0) eq $parm);
	$_ = $warnSave;
	return $res;
}

sub BuildListBox
{
	my($self, $fvar, $flabel, $listvar,$hpack, $vpack) = @_;
	
	## Create the subframe
	#$self->{"$fvar"} = $self->{'DFFrame'}->Frame(-setgrid => 1)
	$self->{"$fvar"} = $self->{'DFFrame'}->Frame
			->pack(-side => $self->{Configure}{-Horiz} ? $hpack : $vpack,
			-anchor => 'center',
			-padx => '4m', # !!!
			-pady => '2m',
	@bothFill, @expand);
	
	## Create the label
	$self->{"$fvar"}->Label(-text => "$flabel")
			->pack(@topPack, @xfill);
	
	## Create the frame for the list box
	my($fbf) = $self->{"$fvar"}->Frame
			->pack(@topPack, @bothFill, @expand);
	
	## And the scrollbar and listbox in it
#	$self->{"$listvar"} = $fbf->Listbox(@raised, -exportselection => 0)
#			->pack(@leftPack, @expand, @bothFill);

#	$fbf->AddScrollbars($self->{"$listvar"});
#	$fbf->configure(-scrollbars => 'se');
	$self->{"$listvar"} = $fbf->Scrolled('Listbox', -scrollbars => 'se', @raised, 
			-exportselection => 0)->pack(@leftPack, @expand, @bothFill);
	
	$self->{"$listvar"}->Subwidget('xscrollbar')->configure(-takefocus => 0);
	$self->{"$listvar"}->Subwidget('yscrollbar')->configure(-takefocus => 0);
	Tk::Autoscroll::Init($self->{"$listvar"})  if ($useAutoScroll);
	$self->{"$listvar"}->bind('<Enter>', sub { $self->bind('<MouseWheel>', [ sub { $self->{"$listvar"}->yview('scroll',-($_[1]/120)*1,'units') }, Tk::Ev("D")]); });
	$self->{"$listvar"}->bind('<Leave>', sub { $self->bind('<MouseWheel>', [ sub { Tk->break; }]) });

	#NEXT LINE ADDED 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
	$self->{"$listvar"}->configure(-selectmode => $self->{Configure}{-SelectMode});
}

sub BindDir
{
	### Set up the bindings for the directory selection list box
	my($self) = @_;
	
	my($lbdir) = $self->{'DirList'};
	#$lbdir->bind("<Double-1>" => sub
	$lbdir->bind("<ButtonRelease-1>", sub   #CHGD. 20020122 TO MAKE SINGLE-CLICK CHDIR.
	{
		my($np) = $lbdir->curselection;
		return if !defined($np);
		$np = $lbdir->get($np);
		if ($np eq '..')
		{
			## Moving up one directory
			$_ = $self->{Configure}{-Path};
			chop if m!/$!;
			s!(.*/)[^/]*$!$1!;
			$self->{Configure}{-Path} = $_;
		}
		elsif ($np eq "/")
		{
			## Moving to root directory
			$self->{Configure}{-Path} = $np;
		}
		else
		{
			## Going down into a directory
			$self->{Configure}{-Path} .= "/" . "$np/"  unless ($np eq '.');
		}
		$self->{Configure}{-Path} =~ s!//*!/!g;
		\&RescanFiles($self);
	}
	);
	$lbdir->bind("<Return>" => sub
	{
		my($np) = $lbdir->index('active');
		return if !defined($np);
		$np = $lbdir->get($np);
		if ($np eq "..")
		{
			## Moving up one directory
			$_ = $self->{Configure}{-Path};
			chop if m!/$!;
			s!(.*/)[^/]*$!$1!;
			$self->{Configure}{-Path} = $_;
		}
		elsif ($np eq "/")
		{
			## Moving to root directory
			$self->{Configure}{-Path} = $np;
		}
		else
		{
			## Going down into a directory
			$self->{Configure}{-Path} .= "/" . "$np/"  unless ($np eq '.');
		}
		$self->{Configure}{-Path} =~ s!//*!/!g;
		\&RescanFiles($self);
	}
	);
	$self->{'DirEntry'}->bind('<Key>' => [\&keyFn,\$self->{Configure}{'Path'},$self->{'DirList'}]);
}

sub BindFile
{
	### Set up the bindings for the file selection list box
	my($self) = @_;
	
	## A single click selects the file...
	$self->{'FileList'}->bind("<ButtonRelease-1>", sub
	{
		if ($self->{Configure}{-SelDir} != 1)
		{
#			$self->{Configure}{-File} =
#					$self->{'FileList'}->get($self->{'FileList'}->curselection);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{Configure}{-File} = join ",", map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
                                                     $self->{'FileList'}->curselection;
		}
	}
	);
	## A double-click selects the file for good
	if ($self->{Configure}{-QuickSelect} == 2)
	{
		$self->{'FileList'}->bind("<1>", sub
		{
			if ($self->{Configure}{-SelDir} != 1)
			{
				my($f) = $self->{'FileList'}->curselection;
				return if !defined($f);
				#$self->{'File'} = $self->{'FileList'}->get($f);
				($self->{Configure}{-File} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$self->{'OK'}->invoke;
			}
		}
		);
	}
	elsif ($self->{Configure}{-QuickSelect})
	{
		$self->{'FileList'}->bind("<Double-ButtonRelease-1>", sub
		{
			if ($self->{Configure}{-SelDir} != 1)
			{
				my($f) = $self->{'FileList'}->curselection;
				return if !defined($f);
				($self->{'File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$self->{'OK'}->invoke;
			}
		}
		);
	}
	$self->{'FileList'}->bind("<Return>", sub
	{
		if ($self->{Configure}{-SelDir} != 1)
		{
			my($f) = $self->{'FileList'}->index('active');
			return if !defined($f);
			($self->{'File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
#			$self->{Configure}{-File} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{Configure}{-File} = join ",", map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
                                                     $self->{'FileList'}->curselection;
			$self->{Configure}{-File} ||= $self->{'File'};
			$self->{'OK'}->focus;
#			$self->{'OK'}->invoke;
		}
	}
	);
	$self->{'FileList'}->bind("<space>", sub
	{
		if ($self->{Configure}{-SelDir} != 1)
		{
			my($f) = $self->{'FileList'}->index('active');
			return if !defined($f);
			($self->{'File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
#			$self->{Configure}{-File} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{Configure}{-File} = join ",", map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
                                                     $self->{'FileList'}->curselection;
		}
	}
	);
	$self->{'FileList'}->bind("<Alt-s>", sub
	{
		if ($self->{Configure}{-SelDir} != 1)
		{
			my($f) = $self->{'FileList'}->index('active');
			return if !defined($f);
			($self->{'File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
#			$self->{Configure}{-File} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{Configure}{-File} = join ",", map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
                                                     $self->{'FileList'}->curselection;
		}
	}
	);
	#$self->{'FileList'}->configure(-selectforeground => 'blue');
	$self->{'FileEntry'}->bind('<Key>' => [\&keyFn,\$self->{Configure}{'File'},$self->{'FileList'}]);
}

sub BuildEntry
{
	### Build the entry, label, and frame indicated.  This is a
	### convenience routine to avoid duplication of code between
	### the file and the path entry widgets
	my($self, $LabelVar, $entry) = @_;
	my($LabelType) = $LabelVar;
	$LabelVar = "-$LabelVar";
	
	## Create the entry frame
	my $eFrame = $self->Frame(@raised)
			->pack(-padx => '4m', -ipady => '2m',@topPack, @xfill); # !!!
	
	## Now create and pack the title and entry
	$eFrame->{'Label'} = $eFrame->Label->pack(@leftPack); # !!!

#	$self->{"$entry"} = $eFrame->Entry(@sunken,
#				-textvariable => \$self->{Configure}{$LabelVar})
#			->pack(@rightPack, @expand, @xfill);
	
	if ($LabelType eq 'Path')   #NEXT 26 ADDED 20010130 TO ADD DRIVE-LETTER SELECTION IN WINDOZE!
	{
		if ($Win32)
		{
			$_ = Win32::GetNextAvailDrive();
			s/\W//g;
			#my (@driveletters);
#			@driveletters = ();
			unless ($#driveletters >= 0)
			{
				for my $i ('A'..'Z')
				{
					last  if ($i eq $_);
#					push (@driveletters, "~$i:");
					push (@driveletters, "$i:");
				}
			}
			$driveletter ||= 'C:';
#			$self->{"driveMenu"} = $eFrame->JOptionmenu(
#					-textvariable => \$driveletter,
#					-command => [\&chgDriveLetter, $self],
#					#-relief => 'raised',
#					#-highlightthickness => 2,
#					-indicatoron => 0,
#					-takefocus => 1,
#					-options => \@driveletters)
#				->pack(@rightPack);
			$self->{"driveMenu"} = $eFrame->JBrowseEntry(
					-textvariable => \$driveletter,
					-state => 'normal',
					-browsecmd => [\&chgDriveLetter, $self],
					#-highlightthickness => 2,
					#-altbinding => 'Down=Popup,Return=Next',
					-takefocus => 1,
					-browse => 1,
					-choices => \@driveletters)
				->pack(@leftPack);
		}
		else
		{
			$driveletter = '';
		}
	}
	$self->{"$entry"} = $eFrame->Entry(@sunken,
				-textvariable => \$self->{Configure}{$LabelVar})
			->pack(@leftPack, @expand, @xfill);
	if ($LabelType eq 'File' && (!defined($self->{Configure}{-SelDir}) || $self->{Configure}{-SelDir} != 1))
	{
		$self->{"$entry"}->bind("<Return>",sub
		{
			#&RescanFiles($self);
			$self->{'OK'}->Invoke;
		});
	}
	#elsif ($LabelType eq 'Path' && $self->{Configure}{-SelDir})
	elsif ($LabelType eq 'Path')
	{
		if ($self->{Configure}{-SortButton})
		{
			$self->{'SortxButton'} = $eFrame->Checkbutton( -variable => \$self->{Configure}{-SortOrder},
				-onvalue => 'Date', -offvalue => 'Name',
				-text => 'Atime',
				-command => sub { &SortFiles($self);})
				->pack(@leftPack);
		}
		$self->{"$entry"}->bind("<Return>",sub
			{
				&RescanFiles($self);
				$self->{"$entry"}->SetCursor('end');  ###
				#$self->{'OK'}->focus;
			}
		);
	}
	$self->{"$entry"}->bind("<Escape>",sub {$self->{'Can'}->Invoke;});
	
	my ($whichlist) = 'FileList';
	$whichlist = 'DirList'  if ($LabelType eq 'Path');
	
	$self->{"$entry"}->bind("<Tab>",sub 
	{
		my ($oldval,$currentval);
		$currentval = $self->{"$entry"}->get;
		if (length($currentval))    #ADDED 20010131
		{
			$oldval = $currentval;
			$currentval = ''  unless ($currentval =~ m#\/#o);
			$currentval =~ s#(.*\/)(.*)$#$1#;
			($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
			my ($restofsel) = $currentval;
			if ($_ && $_ ne '.' && $_ ne '..' && $_ ne '/')   #IF ADDED 20010131.
			{
				($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$restofsel .= $_;
			}
#			elsif ($_ eq '..' && $restofsel ne $oldval)
#			{
#				$restofsel =~ s!(.*/)[^/]*/\.\./?$!$1!;
#			}
			$self->{$entry}->delete('0.0','end');
			$self->{$entry}->insert('end',$restofsel);
			Tk->break  unless ($restofsel eq $oldval);
		}
	});
	$self->{"$entry"}->bind("<Up>",sub
	{
		my ($currentval);
		$currentval = $self->{"$entry"}->get;
		$currentval = ''  unless ($currentval =~ m#\/#);
		$currentval =~ s#(.*\/)(.*)$#$1#;
		$self->{$whichlist}->UpDown(-1);
		my ($restofsel) = $currentval;
		($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
		$restofsel .= $_;
		$self->{$entry}->delete('0.0','end');
		$self->{$entry}->insert('end',$restofsel);
		Tk->break;
	}
	);
	$self->{"$entry"}->bind("<Down>",sub
	{
		my ($currentval);
		$currentval = $self->{"$entry"}->get;
		$currentval = ''  unless ($currentval =~ m#\/#);
		$currentval =~ s#(.*\/)(.*)$#$1#;
		$self->{$whichlist}->UpDown(1);
		my ($restofsel) = $currentval;
		($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
		$restofsel .= $_;
		$self->{$entry}->delete('0.0','end');
		$self->{$entry}->insert('end',$restofsel);
		Tk->break;
	}
	);
	
	return $eFrame;
}

sub BuildBrowse
{
	### Build the entry, label, and frame indicated.  This is a
	### convenience routine to avoid duplication of code between
	### the file and the path entry widgets
	my($self, $LabelVar, $entry) = @_;
	my($LabelType) = $LabelVar;
	$LabelVar = "-$LabelVar";
	
	## Create the entry frame
	my $eFrame = $self->Frame(@raised)
			->pack(-padx => '4m', -ipady => '2m',@topPack, @xfill); # !!!
	
	## Now create and pack the title and entry
	$eFrame->{'Label'} = $eFrame->Label->pack(@leftPack); # !!!

	push (@{$self->{Configure}{HistList}}, '');
	if ($self->{Configure}{-HistFile} && open(TEMP, $self->{Configure}{-HistFile}))
	{
		while (<TEMP>)
		{
			chomp;
			push (@{$self->{Configure}{HistList}}, $_)  if ($_);
		}
	}

	if ($LabelVar eq '-Hist')
	{
		$self->{"histToggleVal"} = (defined($self->{Configure}{-HistUsePathButton}) && $self->{Configure}{-HistUsePathButton} == 1) ? 1 : 0;
		if ($self->{Configure}{-HistUsePath}  && $self->{Configure}{-HistUsePath} != 1)
		{
			my $pathLabel = $self->{Configure}{-HistUsePath};
			$pathLabel = 'Keep Path'  if ($self->{Configure}{-HistUsePath} =~ /^\-?\d/);
			$self->{"histToggle"} = $eFrame->Checkbutton(
				-text   => $pathLabel,
				-variable=> \$self->{"histToggleVal"}
			)->pack(@rightPack);
		}
	}
	$self->{"$entry"} = $eFrame->JBrowseEntry(@raised,
				-label => '',
				-state => 'readonly',
				-variable => \$self->{Configure}{$LabelVar},
				-choices => \@{$self->{Configure}{HistList}},
				-deleteitemsok => $self->{Configure}{-HistDeleteOk}||0,
				-browsecmd => sub {
					$self->{'OK'}->invoke  unless (!$self->{Configure}{-QuickSelect} or $_[2] =~ /space$/);
					$self->{'FileEntry'}->delete('0.0','end');
					$self->{'FileEntry'}->insert('end', $self->{Configure}{$LabelVar});
					$self->{'FileEntry'}->focus;
					if ($self->{Configure}{-HistUsePath} == 1 || ($self->{Configure}{-HistUsePath} && $self->{"histToggleVal"}))
					{
						$self->{Configure}{-Path} = $self->{Configure}{$LabelVar};
						$self->{Configure}{-Path} =~ s#\/[^\/]+$##  unless (-d $self->{Configure}{-Path});
						$driveletter = $1  if ($^O =~ /Win/i && $self->{Configure}{-Path} =~ s/^(\w\:)//);
						&RescanFiles($self);
					}
					$self->{Configure}{$LabelVar} = '';
				},
				-listrelief => 'flat')
			->pack(@rightPack, @expand, @xfill);
	
	$eFrame->packForget  unless ($self->{Configure}{-HistFile});
#DOESN'T WORK?!	$self->{"$entry"}->bind('<Shift-ButtonRelease>', sub {
#			$self->{'FileEntry'}->delete('0.0','end');
#			$self->{'FileEntry'}->insert('end',\$self->{Configure}{$LabelVar});
#			Tk->break;
#	});

	return $eFrame;
}

sub BuildFAV
{
	### Build the entry, label, and frame indicated.  This is a
	### convenience routine to avoid duplication of code between
	### the file and the path entry widgets
	my($self, $LabelVar, $entry) = @_;
	my($LabelType) = $LabelVar;
	$LabelVar = "-$LabelVar";
	
	## Create the entry frame
	my $eFrame = $self->Frame(@raised)
			->pack(-padx => '4m', -ipady => '2m',@topPack, @xfill); # !!!
	
	## Now create and pack the title and entry
	$eFrame->{'Label'} = $eFrame->Label->pack(@leftPack); # !!!

	${$self->{Configure}{PathList}}{''} = '';
	my ($l, $r, $s, $dir);
	if ($Win32 && -d $self->{Configure}{-PathFile})   #ADDED 20081029 TO ALLOW USAGE OF WINDOWS' "FAVORITES" (v1.4)
	{
		(my $pathDir = $self->{Configure}{-PathFile}) =~ s#\\#\/#go;
		chop($pathDir)  if ($pathDir =~ m#\/$#);
		my ($f, %favHash);
		if (opendir (FAVDIR, $pathDir))
		{
			while (defined($f = readdir(FAVDIR)))
			{
				if ($f =~ /\.lnk$/o)
				{
#					print "-file=$f=\n";
					if (open (LNKFILE, "<${pathDir}/$f"))
					{
						while (defined($s = <LNKFILE>))
						{
							if ($s =~ /(\w\:\\\w[\w\\\_\-\. ]+)/o)
							{
								($dir = $1) =~ s#\\#\/#gso;
								$dir =~ s/\s+#//gso;
								if (-d $dir)
								{
									$f =~ s/\.lnk//io;
									$favHash{$f} = $dir;
									last;
								}
							}
						}
						close LNKFILE;
					}
				}
			}
			closedir FAVDIR;
			foreach $f (sort keys %favHash)
			{
				${$self->{Configure}{PathList}}{$favHash{$f}} = $f;
			}
		}
	}
	elsif ($self->{Configure}{-PathFile} && open(TEMP, $self->{Configure}{-PathFile}))
	{
		while (<TEMP>)
		{
			chomp;
			if ($_)
			{
				$l = $_;
				$r = '';
				($l,$r) = split(/\;/o);
				$r ||= $l;
				${$self->{Configure}{PathList}}{$l} = $r;
			}
		}
	}

	$self->{"$entry"} = $eFrame->JBrowseEntry(@raised,
				-label => '',
				-state => 'readonly',
				-variable => \$self->{Configure}{$LabelVar},
				-choices => \%{$self->{Configure}{PathList}},
				-browsecmd => sub {
					$self->{Configure}{-Path} = $self->{$entry}->dereference($self->{Configure}{$LabelVar});
					&RescanFiles($self)  unless (!$self->{Configure}{-QuickSelect} or $_[2] =~ /space$/);
					$self->{'FileEntry'}->focus;
				},
				-listrelief => 'flat')
			->pack(@rightPack, @expand, @xfill);
	$eFrame->packForget  unless ($self->{Configure}{-PathFile} && -r $self->{Configure}{-PathFile});
	return $eFrame;
}

sub BuildListBoxes
{
	my($self) = shift;
	
	## Destroy both, if they're there
	if ($self->{'DFFrame'} && $self->{'DFFrame'}->IsWidget)
	{
		$self->{'DFFrame'}->destroy;
	}
	
	$self->{'DFFrame'} = $self->Frame;
	$self->{'DFFrame'}->pack(-before => $self->{'FEF'},
			@topPack, @bothFill, @expand);
	
	## Build the file window before the directory window, even
	## though the file window is below the directory window, we'll
	## pack the directory window before.
	&BuildListBox($self, 'FileFrame',
			$self->{Configure}{-FileLBCaption},
			'FileList','right','bottom');
	## Set up the bindings for the file list
	&BindFile($self);
	
	if ($self->{Configure}{-Chdir})
	{
		&BuildListBox($self,'DirFrame',$self->{Configure}{-DirLBCaption},
				'DirList','left','top');
		&BindDir($self);
	}
}

sub BuildFDWindow
{
	### Build the entire file dialog window
	my($self) = shift;
	### Build the filename entry box
	$self->{'FEF'} = &BuildEntry($self, 'File', 'FileEntry');
	
	### Build the pathname directory box
	$self->{'PEF'} = &BuildEntry($self, 'Path','DirEntry');

	### JWT:Build the History Dropdown list.
	$self->{'HEF'} = &BuildBrowse($self, 'Hist', 'HistEntry');

	### Now comes the multi-part frame
	my $patFrame = $self->Frame->pack(-padx => '4m', -pady => '2m', @topPack, @xfill);  # !!!
	
	## Label first...
	$self->{'patFrame'}->{'Label'} = $patFrame->Label->pack(@leftPack); # !!!
	
	## Now the entry...
	$self->{'FPat'} = $patFrame->Entry(-textvariable => \$self->{Configure}{-FPat})
			->pack(@leftPack, @expand, @xfill);
	$self->{'FPat'}->bind("<Return>",sub { &RescanFiles($self);});
	
	## and the radio box
	$self->{'SABox'} = $patFrame->Checkbutton(-variable => \$self->{Configure}{-ShowAll},
			-command => sub { &RescanFiles($self);})
			->pack(@leftPack);
	
	### JWT:Build the Favorites Dropdown list.
	$self->{'FAV'} = &BuildFAV($self, 'FAV', 'FavEntry');

	### FINALLY!!! the button frame
	my $butFrame = $self->Frame(@raised);
	$butFrame->pack(-padx => '2m', -pady => '2m', @topPack, @xfill);
	
	$self->{'OK'} = $butFrame->Button(-command => sub
	{
		&GetReturn($self);
	}
	)
			->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
	
	$self->{'Rescan'} = $butFrame->Button(-command => sub
	{
		&RescanFiles($self);
	}
	)
			->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
	
	$self->{'Can'} = $butFrame->Button(-command => sub
	{
		$self->{'Retval'} = -1;
	}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
	
	$self->{'Home'} = $butFrame->Button(
		-text => 'Home', 
		-underline => 0,
		-command => sub
		{
			$self->{Configure}{-Path} = $ENV{HOME} || $ENV{LOGDIR};
			$self->{Configure}{-Path} =~ s#\\#\/#go;
			$self->{Configure}{-Path} = (getpwuid($<))[7]
					unless ($Win32 || !$< || $self->{Configure}{-Path});
			$self->{Configure}{-Path} ||= &cwd() || &getcwd();
			&RescanFiles($self);
		}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
	
	$self->{'Current'} = $butFrame->Button(
		-text => 'CWD',
		-underline => 1,
		-command => sub
		{
			$self->{Configure}{-Path} = &cwd() || &getcwd();
			$self->{Configure}{-Path} =~ s#\\#\/#go;
			&RescanFiles($self);
		}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
	
	if (-e "$ENV{HOME}/.cdout")
	{
		my $cdir0 = &cwd() || &getcwd();
		my $cdir = $cdir0;
		open (CD, "$ENV{HOME}/.cdout") || last;
		$cdir = <CD>;
		chomp($cdir);
		close CD;
		if ($cdir ne $cdir0) {
			$self->{'CDOUT'} = $butFrame->Button(
				-text => 'Cdir',
				-underline => 1,
				-command => sub
				{
					$self->{Configure}{-Path} = $cdir;
					$self->{Configure}{-Path} =~ s#\\#\/#go;
					&RescanFiles($self);
				}
			)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
		}
	}
}

sub RescanFiles
{
	### Fill the file and directory boxes
	my($self) = shift;
	
	my($fl) = $self->{'FileList'};
	my($dl) = $self->{'DirList'};
	my($path) = $self->{Configure}{-Path};
	my($show) = $self->{Configure}{-ShowAll};
	my($chdir) = $self->{Configure}{-Chdir};
	### Remove a final / if it is there, and add it
	$path = '' unless (defined($path));
	$_ = &cwd() || &getcwd();
	if ($path !~ /\S/)
	{
		$self->{Configure}{-Path} = $path  if ($path eq '/');
	}
	$path =~ s/^\./$_/;
	$driveletter = $1  if ($path =~ s/^(\w\:)(.*)$/$2/);
	$driveletter =~ tr/a-z/A-Z/;
	$path =~ s!(.*/)[^/]*/\.\./?$!$1! 
			&& $self->{Configure}{-Path} =~ s!(.*/)[^/]*/\.\./?$!$1!;
	if ($^O =~ /Win/i)
	{
		if (length($path) && substr($path,-1,1) ne '/')
		{
			$path .= '/';
		}
		$self->{Configure}{-Path} = $path;
		$path = $driveletter . $path  if ($driveletter);
		#$path =~ s!^/([a-zA-Z]\:)!$1!;
	}
	else
	{
		if ($path =~ /^~/o)
		{
			$path = `ls -d $path`;   # !!! HANDLES DIRS W/ A TILDE!
			chomp($path);
		}
		if ((length($path) == 0) || (substr($path,-1,1) ne '/'))
		{
			$path .= '/';
			$self->{Configure}{-Path} = $path;
		}
	}
	### path now has a trailing / no matter what

	unless (($path =~ /^~/o) || -d $path)
	{
		print STDERR "-JFileDialog: =$path= is NOT a directory\n";
		carp "$path is NOT a directory\n";
		return 0;
	}
	
	$self->configure(-cursor => 'watch');
	my($OldGrab) = $self->grab('current');
	$self->{'Rescan'}->grab;
	$self->{'Rescan'}->configure(-state => 'disabled');
	$self->update;
	my (@allfiles);
	if (opendir(ALLFILES,$path))
	{
		@allfiles = readdir(ALLFILES);
		closedir(ALLFILES);
	}
	my($direntry);
	
	## First, get the directories...
	if ($chdir)
	{
		my ($parentfound) = 0;
		$dl->delete(0,'end');
		$dl->insert('end', '/')  unless ($path eq '/');
		foreach $direntry (sort @allfiles)
		{
			next if !-d "$path$direntry";
			next if $direntry eq ".";
			if (   !$show
			&& (substr($direntry,0,1) eq ".")
			&& $direntry ne "..")
			{
				next;
			}
			next  if ($direntry eq '..' && $path eq '/');
			$dl->insert('end',$direntry);
			$parentfound = 1  if ($direntry =~ /^\.\./o);
		}
		$dl->insert(1,'..')   #ADDED 20010130 JWT TO FIX MISSING ".." CHOICE!
				unless ($parentfound || $path eq '/' || ($path =~ m#^\w\:\/?$#o));
		$dl->insert(1,'.')  if ($path eq '/' || ($path =~ m#^\w\:\/?$#o));
	}
	
	## Now, get the files
	$fl->delete(0,'end');
	
	$_ = $self->{Configure}{-FPat};
	s/^\s*|\s*$//;
	$_ = $self->{Configure}{-FPat} = '*' if $_ eq '';
	
	my($pat) = $_;
	undef @allfiles;
	
	@allfiles = <$path.$pat> if $show;
	
	my ($cmd) = $path . $pat;
	if (opendir(DIR, $path))
	{
		@allfiles = grep { /\.${pat}$/i } readdir(DIR);
		closedir DIR;
	}
	if ($self->{Configure}{-SortOrder} =~ /^N/o)
	{
		foreach $direntry (sort @allfiles)
		{
			if (-f "${path}$direntry")
			{
				$direntry =~ s!.*/([^/]*)$!$1!;
				next  if (!$show && $direntry =~ /^\./o);  #SKIP ".-FILES" EVEN ON WINDOWS!
				$fl->insert('end',$direntry);
			}
		}
	}
	else
	{

		my @sortedFiles;
		foreach $direntry (@allfiles)
		{
			if (-f "${path}$direntry")
			{
				my (@timestuff, @stats, $atime);
				@stats = stat "${path}$direntry";
				@timestuff = localtime($stats[9]);
				$atime = ($timestuff[5] + 1900);
				$atime .= '0'  if ($timestuff[4] < 9);
				$atime .= ($timestuff[4] + 1);
				$atime .= '0'  if ($timestuff[3] < 10);
				$atime .= $timestuff[3];
				$atime .= ' ';
				$atime .= '0'  if ($timestuff[2] < 10);
				$atime .= $timestuff[2];
				$atime .= '0'  if ($timestuff[1] < 10);
				$atime .= $timestuff[1];
				$direntry =~ s!.*/([^/]*)$!$1!;
				next  if (!$show && $direntry =~ /^\./o);  #SKIP ".-FILES" EVEN ON WINDOWS!
				push @sortedFiles, ($atime . ' ' . $direntry);
			}
		}
		my @stats;
		foreach $direntry (sort @sortedFiles)
		{
			$fl->insert('end',$direntry);
		}
	}
	
	$self->configure(-cursor => 'top_left_arrow');
	
	if ($^O =~ /Win/i)
	{
		my $foundit = 0;
		for (my $i=0;$i<=$#driveletters;$i++)
		{
			if ($driveletters[$i] eq $driveletter)
			{
				$foundit = 1;
				last;
			}
		}
		unless ($foundit)
		{
			my @l = @driveletters;
			push (@l, $driveletter);
			@driveletters = sort @l;
			$self->{"driveMenu"}->choices(\@driveletters);
		}
		
	}
	$self->{'Rescan'}->grab('release') if $self->grab('current') == $self->{'Rescan'};
	$OldGrab->grab if defined($OldGrab);
	$self->{'Rescan'}->configure(-state => 'normal');
	$self->update;
	return 1;
}

sub add2Hist
{
	my $self = shift;
	my $fname = shift;

	if ($self->{Configure}{HistList} && $self->{Configure}{-HistFile} 
			&& open(TEMP, ">$self->{Configure}{-HistFile}"))
	{
		shift (@{$self->{Configure}{HistList}});
		print TEMP "$fname\n";
		my $i = 1;
		my $t;
		while (@{$self->{Configure}{HistList}})
		{
			$t = shift(@{$self->{Configure}{HistList}});
			unless ($t eq $fname)
			{
				print TEMP "$t\n";
				++$i;
				last  if ($self->{Configure}{-History} 
						&& $i >= $self->{Configure}{-History});
			}
		}
		close TEMP;
		if ($self->{Configure}{-HistUsePath} == 1 || ($self->{Configure}{-HistUsePath} && $self->{"histToggleVal"}))
		{
#$fname = 'v:/dev/.propval/html/x.pl';
			$self->{Configure}{-Path} = $fname;
			$self->{Configure}{-Path} =~ s#\/[^\/]+$##  unless (-d $self->{Configure}{-Path});
			$driveletter = $1  if ($^O =~ /Win/i && $self->{Configure}{-Path} =~ s/^(\w\:)//);
#"=".$fname."=".$driveletter."=".$xxx."="
		}
	}
}

sub GetReturn
{
	my ($self) = @_;
	
	## Construct the filename
	my $path = $self->{Configure}{-Path};
	my $fname;
	if ($self->{Configure}{-Hist})
	{
		$fname = $self->{Configure}{-Hist};
		@{$self->{Configure}{HistList}} = $self->{HistEntry}->choices();
		&add2Hist($self, $fname);
	}
	elsif ($^O =~ /Win/i)
	{
		$path = $driveletter . $path  if ($driveletter);
		$path .= "/" if (substr($path, -1, 1) ne '/');
		$path .= "/" if (length($path) && substr($path, -1, 1) ne '/');
		
		if ($self->{Configure}{-SelDir})
		{
			$fname = $self->{'DirList'};
			if (defined($fname->curselection))
			{
				$fname = $fname->get($fname->curselection);
				$fname =~ s/^\d\d\d\d\d\d\d\d \d\d \d\d//o;
				if ($fname =~ /^\.\.$/)   # !!!
				{
					$path =~ s/\/$//;
					$path =~ s#/[^/]*$#/#;
				}
			}
			else
			{
				$fname = '';
			}
			if ($fname =~ /^\.\.$/)
			{
				$fname = $path;
				$fname = '/'  if ($fname le ' ');
			}
			else
			{
				$fname = $path . $fname;
			}
			$fname =~ s/\/$//  unless ($fname =~ /^\/$/);
		} 
		if ($self->{Configure}{-SelDir} != 1)
		{
			if (!$self->{Configure}{-SelDir} && $self->{Configure}{-File} le ' ')
			{
				$self->{'RetFile'} = undef;
				$self->{'Retval'} = -1;
				return;
			}
			elsif (substr($self->{Configure}{-File},0,1) eq '/')  # !!!
			{
				$fname = $self->{Configure}{-File};  #!!!
			}
			elsif ($self->{Configure}{-SelDir} != 2 || $self->{Configure}{-File} gt ' ')
			{
				#WINNT: $fname = $path . $self->{Configure}{-File};
				$fname = $path  unless ($self->{Configure}{-File} =~ /^[a-zA-Z]\:/);
				$fname .= $self->{Configure}{-File};
			}
			## Make sure that the file exists, if the user is not allowed
			## to create
			if (!$self->{Configure}{-Create} && $self->{Configure}{-File} gt ' ' && !(-f $fname) && !((-d $fname) && $self->{Configure}{-SelDir}))
			{
				## Put up no create dialog
				my($path) = $self->{Configure}{-Path};
				$path = $driveletter . $path  if ($driveletter);
				my($file) = $self->{Configure}{-File};
				my($filename) = $fname;
				eval "\$fname = \"$self->{Configure}{-EDlgText}\"";
				$self->Dialog(-title => $self->{Configure}{-EDlgTitle},
						-text => $fname,
						-bitmap => 'error')
						->Show;
				return;
			}
		}
		
		&add2Hist($self, $fname);
	}
	else
	{
		my $fnamex;
		
		if ($path =~ /^~/)
		{
			#$path = `rksh 'ls -d $path'`;   # !!! HANDLES DIRS W/ A TILDE!
			$path = `ls -d $path`;   # !!! HANDLES DIRS W/ A TILDE!
			chomp($path);
		}
		$path .= "/" if (substr($path, -1, 1) ne '/');
		if ($self->{Configure}{-SelDir})
		{
			$fname = $self->{'DirList'};
			if (defined($fname->curselection))
			{
				$fname = $fname->get($fname->curselection);
				if ($fname =~ /^\.\.$/)   # !!!
				{
					$path =~ s/\/$//;
					$path =~ s#/[^/]*$#/#;
				}
				$fname =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
			}
			else
			{
				$fname = '';
			}
			if ($fname =~ /^\.\.$/)
			{
				$fname = $path;
				$fname = '/'  if ($fname le ' ');
			}
			elsif ($fname =~ /^~/)    # !!!
			{
				#$fname = `rksh 'ls -d $fname'`;   # !!! HANDLES FILES W/ A TILDE!
				$fname = `ls -d $fname`;   # !!! HANDLES FILES W/ A TILDE!
				chomp($fname);
			}
			else
			{
				$fname = $path . $fname;
			}
			$fname =~ s/\/$//  unless ($fname =~ /^\/$/);
		}
		if ($self->{Configure}{-SelDir} != 1)
		{
			if (!$self->{Configure}{-SelDir} && $self->{Configure}{-File} le ' ')
			{
				$self->{'RetFile'} = undef;
				$self->{'Retval'} = -1;
				return;
			}
			$fnamex = $self->{Configure}{-File};
			if ($fnamex =~ /^~/)    # !!!
			{
				#$fnamex = `rksh 'ls -d $fnamex'`;   # !!! HANDLES FILES W/ A TILDE!
				$fnamex = `ls -d $fnamex`;
				chomp($fnamex);
				$fname = $fnamex;
			}
			elsif (substr($fnamex,0,1) eq '/')  # !!!
			{
				$fname = $fnamex;  #!!!
			}
			elsif ($self->{Configure}{-SelDir} != 2 || $self->{Configure}{-File} gt ' ')
			{
				#$fname = $path . $self->{Configure}{-File}; #CHGD. TO NEXT 20050417 PER PATCH FROM Paul Falbe.
				($fname = $path . $self->{Configure}{-File}) =~ s/,/,$path/g;
			}
			## Make sure that the file exists, if the user is not allowed
			## to create
			if (!$self->{Configure}{-Create} && $self->{Configure}{-File} gt ' ' && !(-f $fname) && !((-d $fname) && $self->{Configure}{-SelDir}))
			{
				## Put up no create dialog
				my($path) = $self->{Configure}{-Path};
				$path = $driveletter . $path  if ($driveletter);
				my($file) = $self->{Configure}{-File};
				my($filename) = $fname;
				eval "\$fname = \"$self->{Configure}{-EDlgText}\"";
				$self->Dialog(-title => $self->{Configure}{-EDlgTitle},
						-text => $fname,
						-bitmap => 'error')
						->Show;
				## And return
				return;
			}
		}
		&add2Hist($self, $fname);
	}
	$self->{'RetFile'} = $fname;
	$self->{'Retval'} = 1;
}

sub keyFn    #JWT: TRAP LETTERS PRESSED AND ADJUST SELECTION ACCORDINGLY.
{
	my ($e,$w,$l) = @_;
	my $mykey = $e->XEvent->A;
	#	if ($w->cget( "-state" ) eq "readonly")  #TEXT FIELD HAS FOCUS.
	#	{
	if ($mykey)
	{
		my ($entryval) = $e->get;
		$entryval =~ s#(.*/)(.*)$#$2#;
		&LbFindSelection($l,$entryval);
	}
	#	}
	#	else   #LISTBOX HAS FOCUS.
	#	{
	#		&LbFindSelection($w)  if ($mykey);
	#	}
}

sub LbFindSelection
{
	my ($l, $var_ref, $srchval) = @_;
	
	#my $var_ref;
	
	unless ($srchval)
	{
		#my $var_ref = $w->cget( "-textvariable" );
		#my $var_ref = \$w->{Configure}{$LabelVar};
		$srchval = $var_ref;
	}
	#my $l = $w;
	#$l->configure(-selectmode => 'browse');  #CHGD. TO NEXT. 20050418 TO ALLOW MULTIPLE SELECTIONS.
	$l->configure(-selectmode => 'browse')
			if ($l->{Configure}{-selectmode} eq 'single');
	my (@listsels) = $l->get('0','end');
	if ($#listsels >= 0 && $listsels[0] =~ /^\d\d\d\d\d\d\d\d \d\d\d\d /)
	{
		foreach my $i (0..$#listsels)
		{
			$listsels[$i] =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
		}
	}
	foreach my $i (0..$#listsels)
	{
		if ($listsels[$i] eq $srchval)
		{
			$l->selectionClear('0','end');
			$l->activate($i);
			$l->selectionSet($i);
			$l->see($i);
			#my $var_ref = $w->cget("-listok") || undef;;
			#$$var_ref = 1  if (defined($var_ref));
			return $i;
		}
	}
	foreach my $i (0..$#listsels)
	{
		if ($listsels[$i] =~ /^$srchval/)
		{
			$l->selectionClear('0','end');
			$l->activate($i);
			$l->selectionSet($i);
			$l->see($i);
			#$var_ref = $w->cget("-listok") || undef;;
			#$$var_ref = 1  if (defined($var_ref));
			return $i;
		}
	}
	foreach my $i (0..$#listsels)
	{
		if ($listsels[$i] =~ /^$srchval/i)
		{
			$l->selectionClear('0','end');
			$l->activate($i);
			$l->selectionSet($i);
			$l->see($i);
			#$var_ref = $w->cget("-listok") || undef;;
			#$$var_ref = 1  if (defined($var_ref));
			return $i;
		}
	}
	#$var_ref = $w->cget("-listok") || undef;;
	#$$var_ref = 0  if (defined($var_ref));
	return -1;
}

sub chgDriveLetter   #ADDED 20010130 BY JWT.
{
	my ($self) = shift;

	#$_ = $self->{Configure}{-Path};
	#s!^\w\:!$driveletter!  if ($driveletter =~ /\w\:/);
	#$self->{Configure}{-Path} = $driveletter  if ($driveletter =~ /\w\:/);
	$driveletter =~ tr/a-z/A-Z/;
	$driveletter = substr($driveletter,0,1) . ':'  if (length($driveletter) >= 2 || $driveletter =~ /^[A-Z]$/);
	$self->{Configure}{-Path} = ''  if ($_[2] =~ /(?:listbox|key\.\w)/);
	$self->{Configure}{-Path} = &cwd() || &getcwd()
			if (!$self->{Configure}{-Path} && $driveletter =~ /$cwdDfltDrive/i);
	&RescanFiles($self);
}

sub SortFiles
{
	my ($self) = shift;

	&RescanFiles($self);
}

### Return 1 to the calling  use statement ###
1;
### End of file FileDialog.pm ###
__END__
