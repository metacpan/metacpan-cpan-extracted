##################################################
##################################################
##                                              ##
##   JFileDialog v. 2.0 - a reusable Tk-widget  ##
##      (c) 1996-2007 by Jim Turner             ##
##      --Derived 12/11/96 by Jim W. Turner--   ##
##      --from FileDialog                       ##
##                                              ##
##   FileDialog by:  Brent B. Powers            ##
##   Merrill Lynch                              ##
##   powers@swaps-comm.ml.com                   ##
##                                              ##
##################################################
##################################################

=head1 NAME

Tk::JFileDialog - A highly configurable File and Directory Dialog 
widget for Perl/Tk.  

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>.

=head1 COPYRIGHT

Copyright (c) 1996-2018 Jim Turner C<< <mailto:turnerjw784@yahoo.com> >>.
All rights reserved.  

This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

This is a derived work from Tk::Listbox and Tk::HList.

Jim Turner - C<< <mailto:turnerjw784@yahoo.com> >>

This code may be distributed under the same conditions as Perl itself.

=head1 SYNOPSIS

 my $getFileDialog = $main->JFileDialog(
 	-Title =>'Please select a file:',
 );
 my $filename = $getFileDialog->Show();
 if (defined $filename) {
    print "..User entered file name=$filename=.\n";
 }

=head1 DESCRIPTION

The widget is based on the Tk::FileDialog widget by Brent B. Powers.
It uses and depends on the author's Tk::JBrowseEntry widget and adds 
numerous features, such as optional history and favorites files, 
handles MS-Windows drive letters, additional key bindings, etc.

To use JFileDialog, simply create your JFileDialog objects during initialization (or at
least before a Show).  When you wish to display the JFileDialog, invoke the 'Show' method
on the JFileDialog object;  The method will return either a file name, a path name, or
undef.  undef is returned only if the user pressed the Cancel button.

=head2 Example Code

The following code creates a JFileDialog and calls it.  Note that perl5.002gamma is
required.

 #!/usr/bin/perl -w

 use Tk;
 use Tk::JFileDialog;
 use strict;

 my $main = MainWindow->new;
 my $Horiz = 1;
 my $fname;

 my $LoadDialog = $main->JFileDialog(-Title =>'This is my title',
 				    -Create => 0);

 $LoadDialog->configure(-FPat => '*pl',
 		       -ShowAll => 0);

 $main->Entry(-textvariable => \$fname)
 	->pack(-expand => 1,
 	       -fill => 'x');

 $main->Button(-text => 'Kick me!',
 	      -command => sub {
 		  $fname = $LoadDialog->Show(-Horiz => $Horiz);
 		  if (!defined($fname)) {
 		      $fname = "Fine,Cancel, but no ShowDirList anymore!!!";
 		      $LoadDialog->configure(-ShowDirList => 0);
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

The following non-standard method may be used with a JFileDialog object

=head2 Show()

=over 4

Displays the file dialog box for the user to operate.  Additional configuration
items may be passed in at Show-time In other words, this code snippet:

  $fd->Show(-Title => 'Ooooh, Preeeeeety!');

is the same as this code snippet:

  $fd->configure(-Title => 'Ooooh, Preeeeeety!');
  $fd->Show;

=back

=head2 getHistUsePathButton()

=over 4

Fetches the value of the "Keep Path" checkbox created by setting the B<-HistUsePath> 
option.  The checkbox can be set initially by the B<-HistUsePathButton>.  The purpose of 
this allows an application to "remember" the user's last choice for this checkbox the next 
time he invokes the JFileDialog widget by fetching it's status via this function after 
the JFileDialog widget is closed when the user last selected a file, etc., then using that 
variable as the I<HistUsePathButton> argument when JFileDialog is opened again within the 
application.  Returns integer (1 or 0).

=back

=head2 getLastPath()

Fetches the current path as it was when the JFileDialog wiget last closed.  The purpose of 
this allows an application to "remember" the path the previous user selected from the next 
time he invokes the JFileDialog widget by fetching it's status via this function after 
the JFileDialog widget is closed when the user last selected a file, etc., then using that 
variable as the I<-Path> argument when JFileDialog is opened again within the application.

=over 4

Fetches the value of the "Keep Path" checkbox created by setting the B<-HistUsePath> 
option.  The checkbox can be set initially by the B<-HistUsePathButton>.  The purpose of 
this allows an application to "remember" the user's last choice for this checkbox the next 
time he invokes the JFileDialog widget by fetching it's status via this function after 
the JFileDialog widget is closed when the user last selected a file, etc.  Returns 
integer (1 or 0).

=back

=head1 DEPENDENCIES

Cwd, File::Glob, Tk, Tk::JBrowseEntry

=head1 CONFIGURATION

Any of the following configuration items may be set via the configure (or Show) method,
or retrieved via the cget method:

=head2 -Create

Enable the user to specify a file that does not exist. If not enabled, and the user
specifies a non-existent file, a dialog box will be shown informing the user of the
error (This Dialog Box is configurable via the EDlg* switches, below).
If set to -1, user can not create a new file nor type in a name, only select from 
the list.  Default: 1 (enable user to enter a "new" (non-existant) file name).

=head2 -DisableFPat

Disables the ability of the user to change the file selection pattern (the user is 
by default allowed to change the status).  Default: 0 (enable user to change the file 
selection pattern).

=head2 -DisableShowAll

Disables the ability of the user to change the status of the ShowAll flag (the user is 
by default allowed to change the status).  Default: 0 (enable user to toggle showing 
of hidden files and directories).

=head2 -File

The default file name.  If specified and the file exists 
in the currently-selected path, it will be highlighted and selected; and pressing 
the [Reset] button will reset the selected file to be this one.  Default: none 
(no default file name is initially shown).

=head2 -FPat

Sets the default file selection pattern.  Only files matching this pattern will 
be displayed in the File List Box.  It can also be multiple extensions separated by 
the pipe symbol ("|"), ie. "*.jpg|*.gif|*.png".  Default: '' (*).

=head2 -FPatList

Specifies a reference to a list of valid file extensions composing the drop-down 
list for the "Filter" field for selecting a file selection pattern.  Default is 
empty.  Example:  B<-FPatList> => ['*.jpg|*.gif|*.png', '*.pl|*.pm', '*.exe'].  
NOTE:  If B<-Fpat> is also specified, but is NOT in the B<-FPatList> list, it will 
automatically be appended to the top of the list.

=head2 -FPatOnly

Compares all files selected or typed in against the file selection pattern, if set 
to 1.  This, combined with B<-FPat> and / or B<-FPatList> can force a user to enter 
files with the proper extension.

=head2 -Geometry

Sets the geometry of the File Dialog. Setting the size is a dangerous thing to do.
If not configured, or set to '', the File Dialog will be centered.  Default: undef 
(window-manager sets the popup window's geometry).

=head2 -Grab

Enables the File Dialog to do an application Grab when displayed.  Default: 1 
(file dialog will grab focus and be "modal").

=head2 -HistDeleteOk

If set, allows user to delete items from the history dropdown list and thus the 
history file.  Default 0 (do not allow user to remove items in history).
NOTE:  requires Tk::JBrowseEntry v5.0 or later to work.

=head2 -HistFile

Enables the keeping of a history of the previous files / directories selected.  
The file specified must be writable.  If specified, a history of up to 
"-History" number of files will be kept and will be displayed in a "JBrowseEntry" 
combo-box permitting user selection.  Default: undef (no history file or drop-down).

=head2 -History

Used with the "-HistFile" option.  Specifies how many files to retain in the 
history list.  Zero means keep all.  Default is 20 (keep last 20).

=head2 -HistUsePath

If set, the path is set to that of the last file selected from the history.
If set to something other than 1 or 0, a checkbox will appear to the right 
of the history dropdown labeled "Keep Path" to allow user to control this.
If set to a string, then that will be used for the checkbox label in lieu of 
"Keep Path".  Default: undef (not set).

=head2 -HistUsePathButton

Set (check or uncheck) the "Keep Path" checkbox created if "-HistUsePath" option 
is set, otherwise, ignored.  The state of this button can also be fetched by 
calling the getHistUsePathButton() method, which returns 1 or 0.  Default: 0.

=head2 -Horiz

True sets the File List box to be to the right of the Directory List Box. If 0, the
File List box will be below the Directory List box. The default is 1 (display the 
listboxes side-by-side).

=head2 -maxwidth

Specifies the maximum width in avg. characters the width of the text entry fields 
are allowed to expand to.  Default:  60.

=head2 -noselecttext

Normally, when the widget has the focus, the current value is "selected" 
(highlighted and in the cut-buffer). Some consider this unattractive in 
appearance, particularly with the "readonly" state, which appears as a raised 
button in Unix, similar to an "Optionmenu". Setting this option will cause 
the text to not be selected (highlighted). 

=head2 -Path

The initial (default) selection path.  The default is the current 
working directory.  If specified, pressing [Reset] will switch the directory 
dialog back to this path.  Default: none (use current working directory).

=head2 -PathFile

Specifies a file containing a list of "favorite paths" bookmarks to show in a 
dropdown list allowing quick-changes in directories.  Default: undef (no 
favorite path file or dropdown list).

=head2 -QuickSelect

If set to 0, user must invoke the "OK" button to complete selection 
from the listbox.  If 1 or 2, double-clicking or single-clicking (respectively) an 
item in the file list automatically completes the selection.  NOTE:  If set to 2 
(single-click) and I<-SelectMode> is "multiple" or "extended" then it will be 
forced to 1 (double-click), since single-click will just add the file to the 
list to be selected.  This also affects the history and favorite path dropdown 
lists.  If 1 or 2, clicking an item from these lists invokes selection.  Default: 1.

=head2 -SelDir

If 1 or 2, enables selection of a directory rather than a file, and disables the
actions of the File List Box. Setting to 2 allows selection of either a file OR a 
directory.  If -1, the directory listbox, etc. are disabled and the user is forced 
to select file(s) from the initially-specified path.  NOTE:  This will NOT prevent 
the user from typing an alternate path in front of the file name entered, so the 
application must still verify the path returned and handle as desired, ie. display 
an error dialog and force them to reenter, strip the path, etc.  Default: 0 (only 
file(s) may be selected).

=head2 -SelectMode
 
Sets the selectmode of the File Dialog.  If not configured it will be defaulted
to 'browse' (single).  If set to 'multiple' or 'extended', then the user may select 
more than one file and a comma-delimited list of all selected files is returned.  
Otherwise, only a single file may be selected.  Default: 'browse' (selecting only 
a single file from the list allowed).
 
=head2 -SelHook

SelHook is configured with a reference to a routine that will be called when a file
is chosen. The file is called with a sole parameter of the full path and file name
of the file chosen. If the Create flag is disabled (and the user is not allowed
to specify new files), the file will be known to exist at the time that SelHook is
called. Note that SelHook will also be called with directories if the SelDir Flag
is enabled, and that the JFileDialog box will still be displayed. The JFileDialog box
should B<not> be destroyed from within the SelHook routine, although it may generally
be configured.

SelHook routines return 0 to reject the selection and allow the user to reselect, and
any other value to accept the selection. If a SelHook routine returns non-zero, the
JFileDialog will immediately be withdrawn, and the file will be returned to the caller.

There may be only one SelHook routine active at any time. Configuring the SelHook
routine replaces any existing SelHook routine. Configuring the SelHook routine with
0 removes the SelHook routine.  Default: undef (no callback function).

=head2 -ShowAll

Determines whether hidden files and directories (.* and those with the M$-Windows "hidden" 
attribute set, on Windows) are displayed in the File and Directory Listboxes.  
The Show All Checkbox reflects the setting of this switch.  Default: 0 (do not show 
hidden files or directories).

=head2 -ShowDirList

Enable the user to change directories.  If disabled, the directory
list box will not be shown.  Generally, I<-SelDir> should also be set to -1, otherwise, 
user can still change directories by typing them in.  Default: 1 (enable).

=head2 -ShowFileList

Enable the user to select file(s) from a list.  If disabled, the file 
list box will not be shown.  Generally, I<-SelDir> should also be set to 1, otherwise, 
user can still select files by typing them in.  Default: 1 (enable).

-head2 -Title

The Title of the dialog box.  Default: 'Select File:'.

=head2 I<Labels and Captions>

For support of internationalization, the text on any of the subwidgets may be
changed.

B<-CancelButtonLabel>  The text for the Cancel button.  Default: 'Cancel'.

B<-CdoutButtonLabel>  The text for the JFM4 Filemanager "Current" Directory button. 
Default: 'C~dout'.

B<-CWDButtonLabel>  The text for the Cdout Directory button.  Default: 'C~WD'.

B<-DirLBCaption>  The Caption above the Directory List Box.  Default: 'Folders:' 
on Windows sytems and 'Directories:' on all others.

B<-FileEntryLabel>  The label to the left of the File Entry.  Default: 'File:'.

B<-FltEntryLabel>  The label to the left of the Filter entry.  Default: 'Filter:'.

B<-FileLBCaption>  The Caption above the File List Box.  Default: 'Files'.

B<-HomeButtonLabel>  The text for the Home directory button.  Default: 'Home'.

B<-OKButtonLabel>  The text for the OK button.  Default: 'Ok'.

B<-PathEntryLabel>  The label to the left of the Path Entry.  Default: 'Path:'.

B<-RescanButtonLabel>  The text for the Rescan button.  Default: 'Refresh'.

B<-ResetButtonLabel>  The text for the Reset button.  Default: 'Re~set'.

B<-ShowAllLabel>  The text of the Show All Checkbutton.  Default: 'Show All'.

B<-SortButton>  Whether or not to display a checkbox to change file box list sort 
order.  Default: 1 (show).

B<-SortButtonLabel>  The text for the Sort/Atime button.  Default: 'Atime'.

B<-SortOrder>  Order to display files in the file list box ('Name' or 'Date' default=Name).
If 'Date', then the day and time is displayed in the box before the name, 
(but not included when selected)

=head2 I<Error Dialog Switches>

If the Create switch is set to 0, and the user specifies a file that does not exist,
a dialog box will be displayed informing the user of the error. These switches allow
some configuration of that dialog box.

=head2 -EDlgText

DEPRECIATED (now ignored)! - The message of the Error Dialog Box. The variables $path, $file, and $filename
(the full path and filename of the selected file) are available.  Default: 
I<"You must specify an existing file.\n(\$filename not found)">

=head2 -EDlgTitle

The title of the Error Dialog Box.  Default: 'Incorrect entry or selection!'.

=cut

package Tk::JFileDialog;

use vars qw($VERSION $bummer $MAXWIDTH);
$VERSION = '2.01';
$MAXWIDTH = 60;  #AVG. CHARACTERS.

require 5.002;
use strict;
use Carp;
use Cwd;
use File::Glob;
use Tk;
use Tk::Dialog;
use Tk::JBrowseEntry;

my $useAutoScroll = 0;
eval 'use Tk::Autoscroll; $useAutoScroll = 1; 1';

BEGIN
{
	if ($^O =~ /MSWin/)
	{
		require Win32::File;

no strict 'subs';
		Win32::File->import(qw/HIDDEN/);
		$bummer = 1;
	}
	else
	{
		$bummer = 0;
	}
}

my $driveletter = '';
my %lastPaths;
my $homedir = $bummer ? $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'} : $ENV{'HOME'};
$homedir ||= $ENV{'LOGDIR'}  if ($ENV{'LOGDIR'});
$homedir =~ s#[\/\\]$##;

@Tk::JFileDialog::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('JFileDialog');

### Global Variables (Convenience only)
my @topPack = (-side => 'top', -anchor => 'center');
my @rightPack = (-side => 'right', -anchor => 'center');
my @leftPack = (-side => 'left', -anchor => 'center');
my @xfill = (-fill => 'x');
my @yfill = (-fill => 'y');
my @bothFill = (-fill => 'both');
my @expand = (-expand => 1);
my @raised = (-relief => 'raised');
my @sunken = (-relief => 'sunken');
my @driveletters;
my $cwdDfltDrive;
my $histHasChanged = 0;

sub Populate
{
	## File Dialog constructor, inherits new from Toplevel
	my ($FDialog, @args) = @_;

	$FDialog->SUPER::Populate(@args);
	$FDialog->{'Configure'}{'-SortButton'} = 1;   #DEFAULT UNLESS SET BY USER TO ZERO!
	$FDialog->{'Configure'}{'-noselecttext'} = 0;
	$FDialog->{'Configure'}{'-maxwidth'} = $MAXWIDTH;
	$FDialog->{'Configure'}{'-FPatOnly'} = 0;

	foreach my $i (keys %{$args[0]})
	{
		$FDialog->{'Configure'}{$i} = $args[0]->{$i}
			if ($i =~ /^\-(?:HistFile|History|QuickSelect|PathFile|HistDeleteOk|HistUsePath|HistUsePathButton|SortButton|SelDir|ShowFileList|ShowDirList|noselecttext|maxwidth|FPatOnly)$/o);
	}
	$FDialog->bind('<Control-Tab>',sub
	{
		my $self = shift;
		$self->focusPrev();
		Tk->break;
	});

	$FDialog->withdraw;

	if ($bummer)
	{
		$cwdDfltDrive = substr(&cwd(),0,2);
		$cwdDfltDrive ||= substr(&getcwd(),0,2);
	}
	else
	{
		$FDialog->protocol('WM_DELETE_WINDOW' => sub
		{
			$FDialog->{'Can'}->invoke  if (defined($FDialog->{'Can'}) && $FDialog->{'Can'}->IsWidget);
		});
	}
	## Initialize variables that won't be initialized later
	$FDialog->{'Retval'} = -1;
	$FDialog->{'DFFrame'} = 0;

	$FDialog->{'Configure'}{'-Horiz'} = 1;
	$FDialog->{'Configure'}{'-SortOrder'} = 'Name';

	$FDialog->BuildFDWindow;
	#$FDialog->{'activefore'} = $FDialog->{'SABox'}->cget(-foreground);
	$FDialog->{'inactivefore'} = $FDialog->{'SABox'}->cget(-disabledforeground);

	my $dirLabel = $bummer ? 'Folders:' : 'Directories:';
	$FDialog->ConfigSpecs(-ShowDirList		=> ['PASSIVE', undef, undef, 1],
			-ShowFileList		=> ['PASSIVE', undef, undef, 1],
			-ShowDirList		=> ['PASSIVE', undef, undef, 1],
			-Create		=> ['PASSIVE', undef, undef, 1],
			-DisableShowAll	=> ['PASSIVE', undef, undef, 0],
			-DisableFPat	=> ['PASSIVE', undef, undef, 0],
			-FPat			=> ['PASSIVE', undef, undef, ''],
			-FPatList			=> ['PASSIVE', undef, undef, undef],
			-FPatFilters	=> ['PASSIVE', undef, undef, undef],
			-FPatOnly	=> ['PASSIVE', undef, undef, 0],
			-File			=> ['PASSIVE', undef, undef, ''],
			-Geometry		=> ['PASSIVE', undef, undef, undef],
			-Grab			=> ['PASSIVE', undef, undef, 1],
			-Horiz		=> ['PASSIVE', undef, undef, 1],
			-Path			=> ['PASSIVE', undef, undef, undef],
			-SelDir		=> ['PASSIVE', undef, undef, 0],
			-SortButton		=> ['PASSIVE', undef, undef, 1],
			-SortOrder		=> ['PASSIVE', undef, undef, 'Name'],
			-DirLBCaption		=> ['PASSIVE', undef, undef, $dirLabel],
			-FileLBCaption	=> ['PASSIVE', undef, undef, 'Files:'],
			-FileEntryLabel	=> ['METHOD', undef, undef, 'File:'],
			-PathEntryLabel	=> ['METHOD', undef, undef, 'Path:'],
			-FltEntryLabel	=> ['METHOD', undef, undef, 'Filter:'],
			-ShowAllLabel		=> ['METHOD', undef, undef, 'ShowAll'],
			-OKButtonLabel	=> ['METHOD', undef, undef, '~OK'],
			-RescanButtonLabel	=> ['METHOD', undef, undef, '~Refresh'],
			-ResetButtonLabel	=> ['METHOD', undef, undef, 'Re~set'],
			-SortButtonLabel	=> ['METHOD', undef, undef, '~Atime'],
			-CancelButtonLabel	=> ['METHOD', undef, undef, '~Cancel'],
			-HomeButtonLabel	=> ['METHOD', undef, undef, '~Home'],
			-CWDButtonLabel	=> ['METHOD', undef, undef, 'C~WD'],
			-CdoutButtonLabel	=> ['METHOD', undef, undef, 'C~dir'],
			-SelHook		=> ['PASSIVE', undef, undef, undef],
			-SelectMode => ['PASSIVE', undef, undef, 'browse'],   #ADDED 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
			-ShowAll		=> ['PASSIVE', undef, undef, 0],
			-Title		=> ['PASSIVE', undef, undef, 'Select File:'],
			-EDlgTitle		=> ['PASSIVE', undef, undef, 'Incorrect entry or selection!'],
			-History => ['PASSIVE', undef, undef, 20],
			-HistFile => ['PASSIVE', undef, undef, undef],
			-HistDeleteOk => ['PASSIVE', undef, undef, undef],
			-HistUsePath => ['PASSIVE', undef, undef, undef],
			-HistUsePathButton => ['PASSIVE', undef, undef, 0],
			-PathFile => ['PASSIVE', undef, undef, undef],
			-DefaultFile => ['PASSIVE', undef, undef, undef],
			-QuickSelect => ['PASSIVE', undef, undef, 1],
			-DestroyOnHide => ['PASSIVE', undef, undef, 0],
			-noselecttext => ['PASSIVE', undef, undef, 0],
			-maxwidth => ['PASSIVE', undef, undef, $MAXWIDTH],
			-EDlgText		=> ['PASSIVE', undef, undef, "You must specify an existing file.\n"
					. "(\$errnames not found)"]);
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
sub ResetButtonLabel
{
	&SetButton('Reset',@_);
}
sub SortButtonLabel
{
	&SetButton('SortxButton',@_)  if (defined $_[0]->{'SortxButton'}) ;
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
sub CdoutButtonLabel
{
	&SetButton('CDOUT',@_);
}

sub SetButton
{
	my ($widg, $self, $title) = @_;
	if ($widg && defined($self) && defined($self->{$widg})) {
		if (defined($title) && $title =~ /\S/o)
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
		$self->{$widg}->bind('<Return>',sub {$self->{$widg}->Invoke;});
	}
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
	my ($widg, $self, $title) = @_;

	$self->{$widg}->{'Label'}->configure(-text => $title)  if (defined $title);
	## Return the current value
	$self->{$widg}->{'Label'}->cget(-text);
}

sub SetFlag
{
	## Set the given flag to either 1 or 0, as appropriate
	my ($self, $flag, $dflt) = @_;

	$flag = "-$flag";

	## We know it's defined as there was a ConfigDefault call after the Populate
	## call.  Therefore, all we have to do is parse the non-numerics
	if (&IsNum($self->{'Configure'}{$flag}))
	{
		$self->{'Configure'}{$flag} = 1 unless $self->{'Configure'}{$flag} == 0;
	}
	else
	{
		my $val = $self->{'Configure'}{$flag};
		
		my $fc = lc(substr($val,0,1));
		
		if ($fc =~ /^[yt]$/io)
		{
			$val = 1;
		}
		elsif ($fc =~ /^[nf]$/io)
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
		$self->{'Configure'}{$flag} = $val;
	}
	return $self->{'Configure'}{$flag};
}

sub Show
{
	my ($self) = shift;
	
#    my $old_focus = $self->focusSave;
#     my $old_grab = $self->grabSave;
	$self->configure(@_);
	## Clean up flag variables
	$self->SetFlag('ShowDirList');
	$self->SetFlag('ShowFileList');
	#$self->SetFlag('Create');
	$self->SetFlag('ShowAll');
	$self->SetFlag('DisableShowAll');
	$self->SetFlag('DisableFPat');    #ADDED 20050126.
	$self->SetFlag('Horiz');
	$self->SetFlag('Grab');
	#$self->SetFlag('SelDir');

	## Set up, or remove, the directory box
	&BuildListBoxes($self);
	## Enable, or disable, the show all box
	if ($self->{'Configure'}{'-DisableShowAll'})
	{
		$self->{'SABox'}->configure(-state => 'disabled');
	}
	else
	{
		$self->{'SABox'}->configure(-state => 'normal');
	}
	$self->{'FPat'}->configure(-state => ($self->{'Configure'}{'-DisableFPat'})
			? 'readonly' : 'normal');    #ADDED 20050126.
	## Enable or disable the file entry box
	if ($self->{'Configure'}{'-SelDir'} == 1)
	{
		$self->{'Configure'}{'-File'} = '';
		$self->{'FileEntry'}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'});
		if ($self->{'FileList'}) {
			$self->{'FileList'}->configure(-selectforeground => $self->{'inactivefore'});
			$self->{'FileList'}->configure(-foreground => $self->{'inactivefore'});
		}
	}
	elsif ($self->{'Configure'}{'-SelDir'} == -1)
	{
		$self->{'DirEntry'}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'});
		if (defined $self->{'DirList'}) {
			$self->{'DirList'}->configure(-selectforeground => $self->{'inactivefore'});
			$self->{'DirList'}->configure(-foreground => $self->{'inactivefore'});
		}
		$self->{"driveMenu"}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'})  if ($bummer);
		$self->{'Home'}->configure(-state => 'disabled');
		$self->{'Current'}->configure(-state => 'disabled');
		$self->{'CDOUT'}->configure(-state => 'disabled')  if (defined $self->{'CDOUT'});
	}
	if ($self->{'Configure'}{'-Create'} < 0)
	{
		$self->{'FileEntry'}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'});
		$self->{'DirEntry'}->configure(-state => 'disabled',
				-foreground => $self->{'inactivefore'});
	}
	## Set the title
	$self->title($self->{'Configure'}{'-Title'});

	## Create window position (Center unless configured)
	$self->update;
	$self->geometry($self->{'Configure'}{'-Geometry'})
			if (defined($self->{'Configure'}{'-Geometry'}));

	## Fill the list boxes
	$self->{'Configure'}{'-Path'} = ''  unless (defined $self->{'Configure'}{'-Path'});
	$self->{'Configure'}{'-File'} = ''  unless (defined $self->{'Configure'}{'-File'});
	$self->{'Configure'}{'-Path'} = Win32::GetFullPathName($driveletter)
			if ($bummer && $self->{'Configure'}{'-Path'} !~ /\S/);
	if ($self->{'Configure'}{'-Path'} =~ m#^\.\.[\/\\]?$#)
	{
		$self->{'Configure'}{'-Path'} = &cwd() || &getcwd();
		$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;
		$self->{'Configure'}{'-Path'} =~ s#\/([^\/]+)$#\/#;
	}
	elsif ($self->{'Configure'}{'-Path'} !~ /\S/ || $self->{'Configure'}{'-Path'} =~ m#^\.[\/\\]?$#)
	{
		$self->{'Configure'}{'-Path'} = &cwd() || &getcwd();
	}
	$self->{'Configure'}{'-Path'} =~ s/^\~/${homedir}/;
	$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;  #FIX WINDOWSEY PATHS!
	$self->{'Configure'}{'-DefaultFile'} = $self->{'Configure'}{'-Path'};
	$self->{'Configure'}{'-DefaultFile'} .= '/'  if ($self->{'Configure'}{'-DefaultFile'} =~ m#[^\/]$#);
	$self->{'Configure'}{'-DefaultFile'} .= $self->{'Configure'}{'-File'}
			if ($self->{'Configure'}{'-SelDir'} != 1 && $self->{'Configure'}{'-File'} =~ /\S/);
	&RescanFiles($self, $self->{'Configure'}{'-DefaultFile'});
	## Restore the window, and go
	$self->update;
	$self->deiconify;
	
	## Initialize status variables
	$self->{'Retval'} = 0;
	$self->{'RetFile'} = '';
	
#xDEPRECIATED:	if ($ENV{'DESKTOP_SESSION'} =~ /AfterStep version 2.2.1[2-9]/o or $ENV{'SUDO_USER'})   #JWT:ADDED FANCY SLEEP FUNCTION 20140606 B/C TO GET AFTERSTEP TO GIVE "TRANSIENT" WINDOWS THE FOCUS?!;
#x	{
#x		$self->waitVisibility;  #NOTE:  DESKTOP_SESSION UNDEFINED IF SUDO, SO ASSUME AS & DO DELAY ANYWAY!
#x		select(undef, undef, undef, 0.1);  #FANCY QUICK-NAP FUNCTION!
#x	}
	if ($self->{'Configure'}{'-SelDir'} == 1)   # !!!
	{
		my $widget = ($self->{'Configure'}{'-Create'} < 0) ? 'DirList' : 'DirEntry';
			
		$self->{$widget}->focus;
	}
	else
	{
		my $widget = ($self->{'Configure'}{'-Create'} < 0) ? 'FileList' : 'FileEntry';

		$self->{$widget}->focus;
	}
	## Set up the grab
	$self->grab if ($self->{'Configure'}{'-Grab'});

	my $i = 0;
	while (!$i)
	{
		$self->tkwait('variable',\$self->{'Retval'});
		$i = $self->{'Retval'};
		if ($i != -1)
		{
			## No cancel, so call the hook if it's defined
			if (defined($self->{'Configure'}{'-SelHook'}))
			{
				## The hook returns 0 to ignore the result,
				## non-zero to accept.  Must release the grab before calling
				$self->grab('release') if (defined($self->grab('current')));
				$i = &{$self->{'Configure'}{'-SelHook'}}($self->{'RetFile'});
				$self->grab if ($self->{'Configure'}{'-Grab'});
			}
		}
		else
		{
			$self->{'RetFile'} = undef;
		}
	}

	$self->update;
	$self->grab('release') if (defined($self->grab('current')));
	$self->parent->state('normal');
	$self->parent->focus(-force);
	($self->{'Configure'}{'-DestroyOnHide'} == 1) ? $self->destroy : $self->withdraw;
#    &$old_focus;
#    &$old_grab;
	return $self->{'RetFile'};
}

sub getLastPath
{
	my ($self) = shift;

	my $path = $lastPaths{$driveletter} || $self->{'Configure'}{'-Path'};
	$path = $driveletter . $path  if ($bummer && $driveletter);
	return $path;
}

sub getHistUsePathButton
{
	my ($self) = shift;

	return 0  unless (defined $self->{'histToggleVal'});
	return $self->{'histToggleVal'};
}

####  PRIVATE METHODS AND SUBROUTINES ####
sub IsNum
{
	my $parm  = shift;
	my $warnSave = shift;
	$_ = 0;
	my $res = (($parm + 0) eq $parm);
	$_ = $warnSave;
	return $res;
}

sub BuildListBox
{
	my ($self, $fvar, $flabel, $listvar,$hpack, $vpack) = @_;

	## Create the subframe
	$self->{$fvar} = $self->{'DFFrame'}->Frame
			->pack(-side => $self->{'Configure'}{'-Horiz'} ? $hpack : $vpack,
			-anchor => 'center',
			-padx => '4m',
			-pady => '2m',
	@bothFill, @expand);

	## Create the label
	$self->{$fvar}->Label(-text => $flabel)->pack(@topPack, @xfill);

	## Create the frame for the list box
	my $fbf = $self->{$fvar}->Frame->pack(@topPack, @bothFill, @expand);

	## And the scrollbar and listbox in it
	$self->{$listvar} = $fbf->Scrolled('Listbox', -scrollbars => 'se', @raised, 
			-exportselection => 0)->pack(@leftPack, @expand, @bothFill);

	$self->{$listvar}->Subwidget('xscrollbar')->configure(-takefocus => 0);
	$self->{$listvar}->Subwidget('yscrollbar')->configure(-takefocus => 0);
	Tk::Autoscroll::Init($self->{$listvar})  if ($useAutoScroll);
	$self->{$listvar}->bind('<Enter>', sub { $self->bind('<MouseWheel>', [ sub { $self->{$listvar}->yview('scroll',-($_[1]/120)*1,'units') }, Tk::Ev("D")]); });
	$self->{$listvar}->bind('<Leave>', sub { $self->bind('<MouseWheel>', [ sub { Tk->break; }]) });

	#NEXT LINE ADDED 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
	$self->{$listvar}->configure(-selectmode => $self->{'Configure'}{'-SelectMode'})  if ($listvar eq 'FileList');
}

sub BindDir
{
	### Set up the bindings for the directory selection list box
	my $self = shift;

	my $lbdir = $self->{'DirList'};
	$lbdir->bind('<ButtonRelease-1>', sub   #CHGD. 20020122 TO MAKE SINGLE-CLICK CHDIR.
	{
		if ($self->{'Configure'}{'-SelDir'} != -1)
		{
			my $np = $lbdir->curselection;
			return  unless (defined($np));
			$np = $lbdir->get($np);
			return  unless ($np =~ /\S/o);
			if ($np eq '..')
			{
				## Moving up one directory
				$_ = $self->{'Configure'}{'-Path'};
				chop if m!/$!o;
				s!(.*/)[^/]*$!$1!;
				$self->{'Configure'}{'-Path'} = $_;
			}
			elsif ($np eq '/')
			{
				## Moving to root directory
				$self->{'Configure'}{'-Path'} = $np;
			}
			elsif ($bummer && 
					($self->{'Configure'}{'-Path'} !~ /\S/o || $self->{'Configure'}{'-Path'} =~ /^\w\:$/o))
			{
				$self->{'Configure'}{'-Path'} .= "$np/"  unless ($np eq '.');
			}
			else
			{
				## Going down into a directory
				$self->{'Configure'}{'-Path'} .= '/' . "$np/"  unless ($np eq '.');
			}
			$self->{'Configure'}{'-Path'} =~ s!//*!/!go;
			$self->{'DirEntry'}->icursor('end');
			$self->{'DirEntry'}->selectionRange(0,'end')
					unless ($self->{'Configure'}{'-noselecttext'});
			\&RescanFiles($self);
		}
	});

	$lbdir->bind('<Return>' => sub
	{
		if ($self->{'Configure'}{'-SelDir'} != -1)
		{
			my $np = $lbdir->index('active');
			return if !defined($np);
			$np = $lbdir->get($np);
			if ($np =~ /^\.\.$/o)
			{
				## Moving up one directory
				$_ = $self->{'Configure'}{'-Path'};
				chop if m!/$!o;
				s!(.*/)[^/]*$!$1!;
				$self->{'Configure'}{'-Path'} = $_;
			}
			elsif ($np =~ m#^\/$#o)
			{
				## Moving to root directory
				$self->{'Configure'}{'-Path'} = $np;
			}
			else
			{
				## Going down into a directory
				$self->{'Configure'}{'-Path'} .= '/' . "$np/"  unless ($np eq '.');
			}
			$self->{'Configure'}{'-Path'} =~ s!//*!/!go;
			\&RescanFiles($self);
		}
	});

	$self->{'DirEntry'}->bind('<Key>' => [\&keyFn,\$self->{'Configure'}{'Path'},$self->{'DirList'}]);
}

sub BindFile
{
	### Set up the bindings for the file selection list box
	my $self = shift;

	## A single click selects (highlights) the file:
	$self->{'FileList'}->bind('<ButtonRelease-1>', sub
	{
		if ($self->{'Configure'}{'-SelDir'} != 1)
		{
#			$self->{'Configure'}{'-File'} =
#					$self->{'FileList'}->get($self->{'FileList'}->curselection);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{'FileList'}->curselection;
			$self->{'FileEntry'}->icursor('end');
			$self->{'FileEntry'}->selectionRange(0,'end')
					unless ($self->{'Configure'}{'-noselecttext'});

		}
	}
	);
	## Do not allow single-click to complete select if selecting multiple files allowed!
	$self->{'Configure'}{'-QuickSelect'} = 1  if ($self->{'Configure'}{'-QuickSelect'} == 2 
			&& $self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/i);

	if ($self->{'Configure'}{'-QuickSelect'} == 2)
	{
		## A single-click completes the selection:
		$self->{'FileList'}->bind('<1>', sub
		{
			if ($self->{'Configure'}{'-SelDir'} != 1)
			{
				my $f = $self->{'FileList'}->curselection;
				return if !defined($f);
				($self->{'Configure'}{'-File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$self->{'OK'}->invoke;
			}
		});
	}
	elsif ($self->{'Configure'}{'-QuickSelect'})
	{
		## A double-click completes the selection:
		$self->{'FileList'}->bind('<Double-ButtonRelease-1>', sub
		{
			if ($self->{'Configure'}{'-SelDir'} != 1)
			{
				my $f = $self->{'FileList'}->curselection;
				return if !defined($f);
				$self->{'OK'}->invoke;
			}
		});
	}
	$self->{'FileList'}->bind('<Return>', sub
	{
		if ($self->{'Configure'}{'-SelDir'} != 1)
		{
			my $f = $self->{'FileList'}->index('active');
			return if !defined($f);
#			$self->{'Configure'}{'-File'} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{'FileList'}->curselection;
			$self->{'OK'}->focus;
		}
	});

	$self->{'FileList'}->bind('<space>', sub
	{
		if ($self->{'Configure'}{'-SelDir'} != 1)
		{
			my $f = $self->{'FileList'}->index('active');
			return if !defined($f);
#			$self->{'Configure'}{'-File'} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{'FileList'}->curselection;
		}
	});

	$self->{'FileList'}->bind('<Alt-s>', sub
	{
		if ($self->{'Configure'}{'-SelDir'} != 1)
		{
			my $f = $self->{'FileList'}->index('active');
			return if !defined($f);

			if ($ENV{'jwtlistboxhack'})
			{
				$self->{'FileList'}->jwtSpaceSelect($f);
			}
			else
			{
				$self->{'FileList'}->BeginSelect($f);
			}
			($self->{'File'} = $self->{'FileList'}->get($f)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
#			$self->{'Configure'}{'-File'} = $self->{'FileList'}->get($f);
			#PREV. CHGD. TO NEXT 20050416 TO PERMIT MULTIFILE SELECTIONS, THANKS TO Paul Falbe FOR THIS PATCH!
 			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{'FileList'}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{'FileList'}->curselection;
			Tk->break;
		}
	});

	#$self->{'FileList'}->configure(-selectforeground => 'blue');
	$self->{'FileEntry'}->bind('<Key>' => [\&keyFn,\$self->{'Configure'}{'File'},$self->{'FileList'}]);
}

sub BuildPathEntry
{
	### Build the entry, label, and frame indicated.  This is a
	### convenience routine to avoid duplication of code between
	### the file and the path entry widgets
	my ($self, $LabelVar, $entry) = @_;
	my $LabelType = $LabelVar;
	$LabelVar = "-$LabelVar";

	## Create the entry frame
	my $eFrame = $self->Frame(@raised)
			->pack(-padx => '4m', -ipady => '2m',@topPack, @xfill); # !!!

	## Now create and pack the title and entry
	$eFrame->{'Label'} = $eFrame->Label->pack(@leftPack); # !!!

	if ($bummer)
	{
		$_ = Win32::GetNextAvailDrive();
		s/\W//g;
		unless ($#driveletters >= 0)
		{
			for my $i ('A'..'Z')
			{
				last  if ($i eq $_);
				push (@driveletters, "$i:");
			}
		}
		$driveletter ||= ($_ gt 'C') ? 'C:' : 'A:';
		$self->{'driveMenu'} = $eFrame->JBrowseEntry(
				-textvariable => \$driveletter,
				-state => 'normal',
				-browsecmd => [\&chgDriveLetter, $self],
				-takefocus => 1,
				-browse => 1,
				-noselecttext => $self->{'Configure'}{'-noselecttext'},
				-choices => \@driveletters
		)->pack(@leftPack);
	}
	else
	{
		$driveletter = '';
	}
	${$self->{'Configure'}{'PathList'}}{''} = '';
	my ($l, $r, $s, $dir);
	my $favcnt = 0;
	if ($bummer && -d $self->{'Configure'}{'-PathFile'})   #ADDED 20081029 TO ALLOW USAGE OF WINDOWS' "FAVORITES" (v1.4)
	{
		(my $pathDir = $self->{'Configure'}{'-PathFile'}) =~ s#\\#\/#g;
		chop($pathDir)  if ($pathDir =~ m#\/$#);
		my ($f, %favHash);
		if (opendir (FAVDIR, $pathDir))
		{
			while (defined($f = readdir(FAVDIR)))
			{
				if ($f =~ /\.lnk$/o)
				{
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
				${$self->{'Configure'}{'PathList'}}{$favHash{$f}} = $f;
				++$favcnt;
			}
		}
	}
	elsif ($self->{'Configure'}{'-PathFile'} && open(TEMP, $self->{'Configure'}{'-PathFile'}))
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
				${$self->{'Configure'}{'PathList'}}{$l} = $r;
				++$favcnt;
			}
		}
	}

	my $altbindings = (!defined($self->{'Configure'}{'-SelDir'}) || $self->{'Configure'}{'-SelDir'} != 1)
			? 'Right=NoSearch,Return=NonEmptyGo' : 'Right=NoSearch';
	$self->{$entry} = $eFrame->JBrowseEntry(@sunken,
			-label => '',
			-state => $favcnt ? 'normal' : 'textonly',
			-variable => \$self->{'Configure'}{$LabelVar},
			-altbinding => 'Return=NonEmptyGo,Right=NoSearch',
			-btntakesfocus => 1,
			-browsecmd => sub {
				$self->{'Configure'}{'-Path'} = $self->{$entry}->dereference($self->{'Configure'}{$LabelVar});
				&RescanFiles($self)  unless (!$self->{'Configure'}{'-QuickSelect'} || $_[2] =~ /(?:space|listbox\.mod)/o);
				$self->{$entry}->icursor('end');  ###
				my $state = $self->{$entry}->cget( "-state" );
				$self->{'FileEntry'}->focus  #WARNING:THIS LINE CAN LOCK UP THE APP (at least w/o this test)?!
						unless ($state =~ /dis/o || !$self->{'Configure'}{'-QuickSelect'} || $_[2] =~ /(?:space|listbox\.mod)/o);
			},
			-noselecttext => $self->{'Configure'}{'-noselecttext'},
			-listrelief => 'flat',
			-maxwidth => defined($self->{'Configure'}{'-maxwidth'}) ? $self->{'Configure'}{'-maxwidth'} : $MAXWIDTH,
	)->pack(@leftPack, @expand, @xfill);
	$self->{$entry}->choices(\%{$self->{'Configure'}{'PathList'}})  if ($favcnt);
	if ($self->{'Configure'}{'-SortButton'})
	{
		$self->{'SortxButton'} = $eFrame->Checkbutton( -variable => \$self->{'Configure'}{'-SortOrder'},
				-onvalue => 'Date', -offvalue => 'Name',
				-text => 'Atime',
				-command => sub { &SortFiles($self); }
		)->pack(@leftPack);
	}

	$self->{$entry}->bind('<Escape>',sub {
		$self->{$entry}->Popdown  if ($self->{$entry}->{'popped'});
		if ($self->{'Configure'}{$LabelVar} =~ /\S/o)
		{
			$self->{'Configure'}{$LabelVar} = '';
		}
		else
		{
			$self->{'Configure'}{$LabelVar} = $lastPaths{$driveletter} || &cwd() || &getcwd();
			$self->{$entry}->icursor('end');
			$self->{$entry}->selectionRange(0,'end')
					unless ($self->{'Configure'}{'-noselecttext'});
		}
	});

	my $whichlist = 'DirList';
	$self->{$entry}->bind('<Tab>',sub 
	{
		my ($oldval,$currentval);
		$oldval = $lastPaths{$driveletter};
		if (length($oldval))    #ADDED 20010131
		{
			$currentval = $self->{'Configure'}{$LabelVar};
			my $restofsel = $oldval;
			if ($self->{'Configure'}{'-ShowDirList'})
			{
				($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$restofsel .= $_ . '/'  if ($_ && $_ ne '.' && $_ ne '..' && $_ ne '/');
			}
			$self->{'Configure'}{$LabelVar} = $restofsel;
			$self->{$entry}->icursor('end');
			Tk->break  unless ($currentval eq $restofsel);
		}
	});

	$self->{$entry}->bind('<Up>',sub
	{
		if ($self->{'Configure'}{'-ShowDirList'}) {
			my ($currentval);
			$currentval = $lastPaths{$driveletter};
			$self->{$whichlist}->UpDown(-1);
			my ($restofsel) = $currentval;
			($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
			if (m#^\/$#o)
			{
				$restofsel = $_;
			}
			elsif (/^\.\.$/o)
			{
				$restofsel =~ s#[^\/]+\/$##o;
			}
			else
			{
				$restofsel .= $_ . '/';
			}
			$self->{'Configure'}{$LabelVar} = $restofsel;
			$self->{$entry}->icursor('end');
			$self->{$entry}->selectionRange(0,'end')
					unless (!$_ || $self->{'Configure'}{'-noselecttext'});
		}
		Tk->break;
	});

	$self->{$entry}->bind('<Down>',sub
	{
		if ($self->{$entry}->{'popped'})
		{
			$self->{$entry}->Subwidget('slistbox')->focus;
		}
		elsif ($self->{'Configure'}{'-ShowDirList'}) {
			my ($currentval);
			$currentval = $lastPaths{$driveletter};
			$self->{$whichlist}->UpDown(1);
			my $restofsel = $currentval;
			($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
			if (m#^\/$#o)
			{
				$restofsel = $_;
			}
			elsif (/^\.\.$/o)
			{
				$restofsel =~ s#[^\/]+\/$##o;
			}
			else
			{
				$restofsel .= $_ . '/';
			}
			$self->{'Configure'}{$LabelVar} = $restofsel;
			$self->{$entry}->icursor('end');
			$self->{$entry}->selectionRange(0,'end')
					unless (!$_ || $self->{'Configure'}{'-noselecttext'});
		}
		Tk->break;
	});

	return $eFrame;
}

sub BuildFileEntry
{
	### Build the entry, label, and frame indicated.  This is a
	### convenience routine to avoid duplication of code between
	### the file and the path entry widgets
	my ($self, $LabelVar, $entry) = @_;
	my $LabelType = $LabelVar;
	$LabelVar = "-$LabelVar";
	my $histcnt = 0;

	## Create the entry frame
	my $eFrame = $self->Frame(@raised)
			->pack(-padx => '4m', -ipady => '2m',@topPack, @xfill); # !!!

	## Now create and pack the title and entry
	$eFrame->{'Label'} = $eFrame->Label->pack(@leftPack); # !!!

	push (@{$self->{'Configure'}{'HistList'}}, '');
	if ($self->{'Configure'}{'-HistFile'} && open(TEMP, $self->{'Configure'}{'-HistFile'}))
	{
		while (<TEMP>)
		{
			chomp;
			if ($_)
			{
				push (@{$self->{'Configure'}{'HistList'}}, $_);
				++$histcnt;
			}
		}
		close TEMP;
	}

	$self->{"histToggleVal"} = (defined($self->{'Configure'}{'-HistUsePathButton'}) && $self->{'Configure'}{'-HistUsePathButton'} == 1) ? 1 : 0;
	if ($self->{'Configure'}{'-HistUsePath'}  && $self->{'Configure'}{'-HistUsePath'} != 1)
	{
		my $pathLabel = $self->{'Configure'}{'-HistUsePath'};
		$pathLabel = 'Keep Path'  if ($self->{'Configure'}{'-HistUsePath'} =~ /^\-?\d/);
		$self->{"histToggle"} = $eFrame->Checkbutton(
				-text   => $pathLabel,
				-variable=> \$self->{"histToggleVal"}
		)->pack(@rightPack);
	}

	my $altbindings = (!defined($self->{'Configure'}{'-SelDir'}) || $self->{'Configure'}{'-SelDir'} != 1)
			? 'Right=NoSearch,Return=NonEmptyGo' : 'Right=NoSearch';
	$self->{$entry} = $eFrame->JBrowseEntry(@sunken,
			-label => '',
			-state => $histcnt ? 'normal' : 'textonly',
			-variable => \$self->{'Configure'}{$LabelVar},
			-altbinding => $altbindings,
			-deleteitemsok => $self->{'Configure'}{'-HistDeleteOk'}||0,
			-btntakesfocus => 1,
			-browsecmd => sub {
				$self->{'OK'}->invoke  unless (!$self->{'Configure'}{'-QuickSelect'} or $_[2] =~ /(?:space|listbox\.mod)/o);
				$self->{'FileEntry'}->focus;
				if ($self->{'Configure'}{'-HistUsePath'} == 1 || ($self->{'Configure'}{'-HistUsePath'} && $self->{"histToggleVal"}))
				{
					$self->{'Configure'}{'-Path'} = $self->{'Configure'}{$LabelVar};
					$self->{'Configure'}{'-Path'} =~ s#\/[^\/]+$##o  unless (-d $self->{'Configure'}{'-Path'});
					$driveletter = $1  if ($bummer && $self->{'Configure'}{'-Path'} =~ s/^(\w\:)//o);
					&RescanFiles($self);
				}
			},
			-noselecttext => $self->{'Configure'}{'-noselecttext'},
			-listrelief => 'flat',
			-maxwidth => defined($self->{'Configure'}{'-maxwidth'}) ? $self->{'Configure'}{'-maxwidth'} : $MAXWIDTH,
	)->pack(@rightPack, @expand, @xfill);
	if ($Tk::JBrowseEntry::VERSION >= 5.0)
	{
		$self->{$entry}->configure(-deletecmd => sub {
				my $self = shift;
				my $idx = shift;  #NOTE: *BEFORE* DELETE HAPPENS, IS INDEX OF SELECTED ENTRY, AFTERWARDS, IS -1!
				$histHasChanged = 1  if ($idx < 0); #TRUE *AFTER* DELETE!
				return !$idx ? 1 : 0;  #PREVENT DELETION OF TOP (0th) (THE BLANK) ENTRY!
		});
	}
	$self->{$entry}->choices(\@{$self->{'Configure'}{'HistList'}})  if ($histcnt);

	my $whichlist = 'FileList';

	local *grabListContent = sub {
	};


	$self->{$entry}->bind('<Escape>',sub {
		$self->{$entry}->Popdown  if ($self->{$entry}->{'popped'});
		if ($self->{'Configure'}{$LabelVar} =~ /\S/o)
		{
			$self->{'Configure'}{$LabelVar} = '';
		}
		else
		{
		 	$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{$whichlist}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{$whichlist}->curselection;
			$self->{$entry}->icursor('end');
			$self->{$entry}->selectionRange(0,'end')
					unless ($self->{'Configure'}{'-noselecttext'});
		}
	});

	$self->{$entry}->bind('<Tab>',sub 
	{
		if ($self->{'Configure'}{'-ShowFileList'} && $self->{'Configure'}{'-SelDir'} != 1) {
			my ($oldval,$currentval);
			$currentval = $self->{$entry}->get;
			if (length($currentval) && $currentval !~ /\,/o)    #ADDED 20010131
			{
				$oldval = $currentval;
				$currentval = ''  unless ($currentval =~ m#\/#o);
				$currentval =~ s#(.*\/)(.*)$#$1#;
				my ($restofsel) = $currentval;
				($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				if ($_ && $_ ne '.' && $_ ne '..' && $_ ne '/' && $_ !~ /\,/o)   #IF ADDED 20010131.
				{
#					($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
					my ($sel) = $self->{$whichlist}->curselection;
					$restofsel .= $_  if ($sel =~ /\d/o);
				}
				$self->{'Configure'}{$LabelVar} = $restofsel;
				$self->{$entry}->icursor('end');
				Tk->break  unless ($restofsel eq $oldval);
			}
		}
	});

	$self->{$entry}->bind('<Up>',sub
	{
		if ($self->{'Configure'}{'-ShowFileList'} && $self->{'Configure'}{'-SelDir'} != 1) {
			if ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/io)
			{
				$self->{'Configure'}{$LabelVar} = '';
				my $f = $self->{$whichlist}->index('active');
				if (defined $f)
				{
		 			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{$whichlist}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{$whichlist}->curselection;
				}
				$self->{$whichlist}->focus();
			}
			else
			{
				$self->{$whichlist}->UpDown(-1);
				($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$self->{'Configure'}{$LabelVar} = $_;
				$self->{$entry}->icursor('end');
				$self->{$entry}->selectionRange(0,'end')
						unless (!$_ || $self->{'Configure'}{'-noselecttext'});
			}
		}
		Tk->break;
	});

	$self->{$entry}->bind('<Down>',sub
	{
		if ($self->{$entry}->{'popped'})
		{
			$self->{$entry}->Subwidget('slistbox')->focus;
		}
		elsif ($self->{'Configure'}{'-ShowFileList'} && $self->{'Configure'}{'-SelDir'} != 1) {
			if ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/io)
			{
				$self->{'Configure'}{$LabelVar} = '';
				my $f = $self->{$whichlist}->index('active');
				if (defined $f)
				{
		 			$self->{'Configure'}{'-File'} = join ',', map { (my $f = $self->{$whichlist}->get($_)) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o; $f }
					$self->{$whichlist}->curselection;
				}
				$self->{$whichlist}->focus();
			}
			else
			{
				$self->{$whichlist}->UpDown(1);
				($_ = $self->{$whichlist}->get('active')) =~ s/^\d\d\d\d\d\d\d\d \d\d\d\d //o;
				$self->{'Configure'}{$LabelVar} = $_;
				$self->{$entry}->icursor('end');

				$self->{$entry}->selectionRange(0,'end')
						unless (!$_ || $self->{'Configure'}{'-noselecttext'});
			}
		}
		Tk->break;
	});

	return $eFrame;
}

sub BuildListBoxes
{
	my $self = shift;

	## Destroy both, if they're there
	$self->{'DFFrame'}->destroy  if ($self->{'DFFrame'} && $self->{'DFFrame'}->IsWidget);
	$self->{'DFFrame'} = $self->Frame;
	$self->{'DFFrame'}->pack(-before => $self->{'FEF'}, @topPack, @bothFill, @expand);
	
	## Build the file window before the directory window, even
	## though the file window is below the directory window, we'll
	## pack the directory window before.
	if ($self->{'Configure'}{'-ShowDirList'})
	{
		&BuildListBox($self,'DirFrame',$self->{'Configure'}{'-DirLBCaption'},'DirList','left','top');
		&BindDir($self);
	}

	if ($self->{'Configure'}{'-ShowFileList'}) {
		&BuildListBox($self, 'FileFrame',$self->{'Configure'}{'-FileLBCaption'},'FileList','right','bottom');
		## Set up the bindings for the file list
		&BindFile($self);
	}
}

sub BuildFDWindow
{
	### Build the entire file dialog window
	my $self = shift;
	### Build the filename entry box
	$self->{'FEF'} = &BuildFileEntry($self, 'File', 'FileEntry');

	### Build the pathname directory box
	$self->{'PEF'} = &BuildPathEntry($self, 'Path','DirEntry');

	### Now comes the multi-part frame
	my $patFrame = $self->Frame->pack(-padx => '4m', -pady => '2m', @topPack, @xfill);

	## Label first...
	$self->{'patFrame'}->{'Label'} = $patFrame->Label->pack(@leftPack);

	my @fpatList = ($self->{'Configure'}{'-FPat'});
	$self->{'FPat'} = $patFrame->JBrowseEntry(@sunken,
			-label => '',
			-state => 'normal',
			-variable => \$self->{'Configure'}{'-FPat'},
			-deleteitemsok => 0,
			-listrelief => 'flat',
			-altbinding => 'Down=Popup;Return=SingleGo;Return=NonEmptyGo',
			-browsecmd => sub {
				&RescanFiles($self);
				if ($self->{'Configure'}{'-SelDir'} == 1)   # !!!
				{
					my $widget = ($self->{'Configure'}{'-Create'} < 0) ? 'DirList' : 'DirEntry';
			
					$self->{$widget}->focus;
				}
				else
				{
					my $widget = ($self->{'Configure'}{'-Create'} < 0) ? 'FileList' : 'FileEntry';

					$self->{$widget}->focus;
				}
			},
			-noselecttext => $self->{'Configure'}{'-noselecttext'},
	)->pack(@leftPack, @expand, @xfill);

	## and the radio box
	$self->{'SABox'} = $patFrame->Checkbutton(-variable => \$self->{'Configure'}{'-ShowAll'},
			-command => sub { &RescanFiles($self);}
	)->pack(@leftPack);

	### JWT:Build the Favorites Dropdown list.

	### FINALLY!!! the button frame
	my $butFrame = $self->Frame(@raised);
	$butFrame->pack(-padx => '2m', -pady => '2m', @topPack, @xfill);

	$self->{'OK'} = $butFrame->Button(-command => sub
	{
		&GetReturn($self);
	})->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	$self->{'Rescan'} = $butFrame->Button(-command => sub
	{
		if ($bummer && $self->{'Configure'}{'-Path'} !~ /\S/)
		{
			$self->{'Configure'}{'-Path'} = Win32::GetFullPathName($driveletter);
			$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;
		}
		$self->{'Configure'}{'-Path'} = $lastPaths{$driveletter} || &cwd() || &getcwd()  if ($self->{'Configure'}{'-Path'} !~ /\S/);
		$self->{'Configure'}{'-File'} = '';
		&RescanFiles($self);
	})->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	$self->{'Reset'} = $butFrame->Button(
		-text => 'Reset', 
		-underline => 2,
		-command => sub
		{
			if ($bummer && $self->{'Configure'}{'-Path'} !~ /\S/)
			{
				$self->{'Configure'}{'-Path'} = Win32::GetFullPathName($driveletter);
				$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;
			}
			$self->{'Configure'}{'-Path'} = &cwd() || &getcwd()  if ($self->{'Configure'}{'-Path'} !~ /\S/);
			$self->{'Configure'}{'-File'} = '';
			&RescanFiles($self, $self->{'Configure'}{'-DefaultFile'});
		}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	$self->{'Can'} = $butFrame->Button(-command => sub
	{
		$self->{'Retval'} = -1;
	})->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	$self->{'Home'} = $butFrame->Button(
		-text => 'Home', 
		-underline => 0,
		-command => sub
		{
			$self->{'Configure'}{'-Path'} = $homedir;
			if ($bummer)
			{
				$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;
			}
			else
			{
				$self->{'Configure'}{'-Path'} = (getpwuid($<))[7]
						unless (!$< || $self->{'Configure'}{'-Path'});
			}
			$self->{'Configure'}{'-Path'} ||= &cwd() || &getcwd();
			if ($bummer && $self->{'Configure'}{'-Path'} =~ /^(\w\:)/)
			{
				$driveletter = $1;
				$self->{'Configure'}{'-Path'} =~ s/^(\w\:)//;  #STRANGE: PERL WOULDN'T DO THIS AS A SINGLE TEST & GRAB $1?!
			}
			&RescanFiles($self);
		}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	$self->{'Current'} = $butFrame->Button(
		-text => 'CWD',
		-underline => 1,
		-command => sub
		{
			$self->{'Configure'}{'-Path'} = &cwd() || &getcwd();
			&RescanFiles($self);
		}
	)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);

	if (-e "${homedir}/.cdout")  #SPECIAL BUTTON USED W/JFM4 FILEMANAGER:
	{
		my $cdir0 = &cwd() || &getcwd();
		my $cdir = $cdir0;
		open (CD, "${homedir}/.cdout") || last;
		$cdir = <CD>;
		chomp($cdir);
		close CD;
		if ($cdir ne $cdir0) {  #JFM4'S "CURRENT DIR" IS DIFFERENT FROM SHELL'S:
			$self->{'CDOUT'} = $butFrame->Button(
				-text => 'Cdir',
				-underline => 1,
				-command => sub
				{
					$self->{'Configure'}{'-Path'} = $cdir;
					$self->{'Configure'}{'-Path'} =~ s#\\#\/#g;
					&RescanFiles($self);
				}
			)->pack(-padx => '2m', -pady => '2m', @leftPack, @expand, @xfill);
		}
	}
}

sub RescanFiles
{
	### Fill the file and directory boxes
	my $self = shift;
	my $defaultfid = shift || '';
	my $defaultdir = '';
	my $defaultfile = '';
	my $path = $self->{'Configure'}{'-Path'};
	my $show = $self->{'Configure'}{'-ShowAll'};
	my $chdir = $self->{'Configure'}{'-ShowDirList'};
	my $chfile = $self->{'Configure'}{'-ShowFileList'};

	if ($path =~ m#^\.\.[\/\\]?$#o)
	{
		$path =~ s#\\#\/#go;
		$path =~ s#\/([^\/]+)$#\/#o;
	}
	elsif ($path !~ /\S/o || $path =~ m#^\.[\/\\]?$#o)
	{
		$path = $lastPaths{$driveletter} || &cwd() || &getcwd();
	}
	$path =~ s/^\~/${homedir}/;
	$path =~ s#\\#\/#go;  #FIX WINDOWSEY PATHS!
	$self->{'Configure'}{'-File'} = ''  if ($self->{'Configure'}{'-Create'} < 1);
	if ($defaultfid)
	{
		$defaultfid =~ s#\\#\/#go;
		($defaultdir = $defaultfid) =~ s#\/([^\/]+)$#\/#o;
		$defaultfile = $1;
		if (!$defaultfile && $defaultdir !~ m#\/#o && !-d $defaultdir)
		{
			$defaultfile = $defaultdir;
			$defaultdir = '';
		}
		$defaultfile = ''  if ($self->{'Configure'}{'-SelDir'} == 1);
		if ($defaultdir)
		{			
			if ($defaultdir =~ m#^\/#o || ($bummer && $defaultdir =~ /^\w\:/o))
			{
				$path = $defaultdir;
			}
			else
			{
				$path .= $defaultdir;
			}
		}
	}
	$path = ''  unless (defined $path);
	if ($path =~ m#^\.\.[\/\\]?$#o)
	{
		$path = $lastPaths{$driveletter} || &cwd() || &getcwd();
		$path =~ s#[\/\\]$##o;
		$path =~ s#\\#\/#go;
		$path =~ s#\/[^\/]+$#\/#o;
	}
	$_ = $lastPaths{$driveletter} || &cwd() || &getcwd();
	$path =~ s/^\.$/$_/;
	$path =~ s/^\~/${homedir}/;
	$path =~ s!^[\/\\]/([a-zA-Z]\:)!$1!;
	$driveletter = $1  if ($path =~ s/^(\w\:)(.*)$/$2/);
	$driveletter =~ tr/a-z/A-Z/;
	$path =~ s!(.*/)[^/]*/\.\./?$!$1! 
			&& $self->{'Configure'}{'-Path'} =~ s!(.*/)[^/]*/\.\./?$!$1!;
	unless (-d $path || ($bummer && -d "${driveletter}$path"))
	{
		print STDERR "-JFileDialog: =$path= is NOT a directory.\n";
		carp "$path is NOT a directory, using prev. directory.\n";
		$path = $lastPaths{$driveletter} || &cwd() || &getcwd();
		$path =~ s#\\#\/#go;
		$path =~ s#\/$##o;
	}
	if ($bummer)
	{
		$path .= '/'  if (length($path) && $path !~ m#[\:\/]$#o);
		$self->{'Configure'}{'-Path'} = $path;
		$lastPaths{$driveletter} = $path;
		$path = $driveletter . $path  if ($driveletter);
	}
	else
	{
		$path .= '/'  if (length($path) == 0 || $path !~ m#\/$#o);
		$self->{'Configure'}{'-Path'} = $path;
		$lastPaths{$driveletter} = $path;
	}

	### path now has a trailing / no matter what	

	$self->configure(-cursor => 'watch');
	my $OldGrab = $self->grab('current');
	$self->{'Rescan'}->grab;
	$self->{'Rescan'}->configure(-state => 'disabled');
	$self->update;
	my (@allfiles, $direntry);
	if (opendir(ALLFILES,$path))
	{
		@allfiles = readdir(ALLFILES);
		closedir(ALLFILES);
	}

	## First, get the directories...
	if ($chdir)
	{
		my $dl = $self->{'DirList'};

		$dl->delete(0,'end');
		$dl->insert('end', '/')  unless ($path eq '/' || ($bummer && $path =~ m#^\w\:\/?$#o));
		foreach $direntry (sort @allfiles)
		{
			next  if !-d "${path}$direntry";
			next  if $direntry =~ m/^\.\.?$/o;
			unless ($show)
			{
				next  if ($direntry =~ /^\./o);
				if ($bummer)  #SKIP DIRECTORIES WINDOWS CONSIDERS HIDDEN:
				{
					my $attrs;
					next  unless (Win32::File::GetAttributes("${path}$direntry", $attrs));
					next  if ($attrs & HIDDEN());
				}
			}
			$dl->insert('end',$direntry);
		}
		$dl->insert(1,'..')   #ADDED 20010130 JWT TO FIX MISSING ".." CHOICE!
				unless ($path eq '/' || ($bummer && $path =~ m#^\w\:\/?$#o));
	}

	## Now, get the files
	if ($chfile) {
		my $fl = $self->{'FileList'};
		my @fpatList;
		$fl->delete(0,'end');

		($_ = defined($self->{'Configure'}{'-FPat'}) ? $self->{'Configure'}{'-FPat'} : '') =~ s/^\s*|\s*$//o;
		if (defined $self->{'Configure'}{'-FPatList'})
		{
			$self->{'Configure'}{'-FPat'} = $_ = ${$self->{'Configure'}{'-FPatList'}}[0]  if ((!$_ || /^\*$/o)
					&& $self->{'Configure'}{'-DisableFPat'});
			my $found = 0;
			foreach my $i (@{$self->{'Configure'}{'-FPatList'}})
			{
				if ($i eq $_)
				{
					$found = 1;
					last;
				}
			}
			@fpatList = $found || $self->{'Configure'}{'-DisableFPat'} ? @{$self->{'Configure'}{'-FPatList'}}
					: ($_, @{$self->{'Configure'}{'-FPatList'}});
		}
		else
		{
			@fpatList = ($_);
		}
		@{$self->{'Configure'}{'-FPatList'}} = @fpatList;
		$self->{'FPat'}->choices(\@fpatList)  if ($#fpatList > 0);

		$self->{'Configure'}{'-FPatFilters'} = $_  if ($self->{'Configure'}{'-FPatOnly'});
		my @filters = split(/\|/o, $_);
		@filters = ('')  unless ($#filters >= 0);
		undef @allfiles;

		if (opendir(DIR, $path))
		{
FILELOOP:			while ($_ = readdir(DIR))
			{
				if (!$filters[0] || $filters[0] =~ /^\*$/o)
				{
					push @allfiles, $_;
					next;
				}
				foreach my $filter (@filters)
				{
					if (/^${filter}$/)
					{
						push @allfiles, $_;
						next FILELOOP;
					}
				}
			}
			closedir DIR;
		}
		if ($self->{'Configure'}{'-SortOrder'} =~ /^N/o)
		{
			foreach $direntry (sort @allfiles)
			{
				if (-f "${path}$direntry")
				{
					$direntry =~ s!.*/([^/]*)$!$1!;
					unless ($show)
					{
						next  if ($direntry =~ /^\./o);  #SKIP ".-FILES" EVEN ON WINDOWS!
						if ($bummer)  #SKIP FILES WINDOWS CONSIDERS HIDDEN:
						{
							my $attrs;
							next  unless (Win32::File::GetAttributes("${path}$direntry", $attrs));
							next  if ($attrs & HIDDEN());
						}
					}
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
					unless ($show)
					{
						next  if ($direntry =~ /^\./o);  #SKIP ".-FILES" EVEN ON WINDOWS!
						if ($bummer)  #SKIP FILES WINDOWS CONSIDERS HIDDEN:
						{
							my $attrs;
							next  unless (Win32::File::GetAttributes("${path}$direntry", $attrs));
							next  if ($attrs & HIDDEN());
						}
					}
					push @sortedFiles, ($atime . ' ' . $direntry);
				}
			}
			my @stats;
			foreach $direntry (sort @sortedFiles)
			{
				$fl->insert('end',$direntry);
			}
		}
	}

	if ($defaultfile && $self->{'Configure'}{'-SelDir'} != 1)
	{
		$self->{'Configure'}{'-File'} = $defaultfile;
	}
	&LbFindSelection($self->{'FileList'}, $self->{'Configure'}{'-File'})
			if (defined($self->{'FileList'}) && $self->{'Configure'}{'-File'} =~ /\S/o);

	$self->configure(-cursor => 'top_left_arrow');

	if ($bummer)
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

	if ($self->{'Configure'}{'HistList'} && $self->{'Configure'}{'-HistFile'} 
			&& open(TEMP, ">$self->{'Configure'}{'-HistFile'}"))
	{
		shift (@{$self->{'Configure'}{'HistList'}});
		print TEMP "$fname\n";
		my $i = 1;
		my $t;
		while (@{$self->{'Configure'}{'HistList'}})
		{
			$t = shift @{$self->{'Configure'}{'HistList'}};
			unless ($t !~ /\S/o || $t eq $fname)
			{
				print TEMP "$t\n";
				++$i;
				last  if ($self->{'Configure'}{'-History'} 
						&& $i >= $self->{'Configure'}{'-History'});
			}
		}
		close TEMP;
		if ($self->{'Configure'}{'-HistUsePath'} == 1 || ($self->{'Configure'}{'-HistUsePath'} && $self->{"histToggleVal"}))
		{
			$self->{'Configure'}{'-Path'} = $fname;
			$self->{'Configure'}{'-Path'} =~ s#\/[^\/]+$##o  unless (-d $self->{'Configure'}{'-Path'});
			$driveletter = $1  if ($bummer && $self->{'Configure'}{'-Path'} =~ s/^(\w\:)//o);
		}
	}
}

sub GetReturn
{
	my ($self) = @_;

	## Construct the filename
	my $path = $self->{'Configure'}{'-Path'} || '';
	$path =~ s/^\s+//;
	$path =~ s/\s+$//;
	my ($fname, $fnamex);

	if ($self->{'Configure'}{'-Hist'})  #DEPRECIATED, I THINK:
	{
		$fname = $self->{'Configure'}{'-Hist'};
		@{$self->{'Configure'}{'HistList'}} = $self->{'FileEntry'}->choices();
		&add2Hist($self, $fname);
	}
	elsif ($bummer)  #M$-WINDOWS:
	{
		@{$self->{'Configure'}{'HistList'}} = $self->{'FileEntry'}->choices()  if ($histHasChanged);
		$path = $driveletter . $path  if ($driveletter);
		if ($path =~ m/^[a-z]\:$/i)
		{
			my $absPath = Win32::GetFullPathName($path);
			$path = $absPath  if ($absPath);
		}
		$path =~ s#\\#\/#go;  #FIX BACKWARD WINDOWS PATH SEPERATORS.
		$path .= '/'  if ($path !~ m#[\:\/]$#);
		
		$fname = $path;
		#AT THIS POINT, $fname IS A "x:/path/"!
		if ($self->{'Configure'}{'-SelDir'} != 1)  #(-1, 0, or 2) FILES ALLOWED OR REQUIRED:
		{
			if ($self->{'Configure'}{'-File'} le ' ')  #NO FILES SPECIFIED, IT'D BETTER BE A DIRECTORY!:
			{
				if ($self->{'Configure'}{'-SelDir'} < 2)  #(-1 or 0: FILE REQUIRED), NONE ENTERED, RETURN OK THOUGH!
				{
					$self->{'RetFile'} = undef;
					$self->{'Retval'} = -1;

					return;
				}
				elsif ($self->{'Configure'}{'-Create'} <= 0 && !(-d $fname))
				{
					## Put up no create allowed dialog
					$self->{'Configure'}{'-EDlgText'} = "You must specify an existing folder.\n($fname not found)";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
							-text => $self->{'Configure'}{'-EDlgText'},
							-bitmap => 'error'
					)->Show;

					return;
				}
			}
			else  #ONE OR MORE FILES SPECIFIED:
			{
				## Make sure that the file exists, if the user is not allowed
				## to create
				my @filelist = split (/\s*\,\s*/, $self->{'Configure'}{'-File'});
				unless ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/i || $#filelist <= 0)
				{
					$self->{'Configure'}{'-EDlgText'} = "Only a single file is allowed!\n" 
							. $self->{'Configure'}{'-File'} . "\nrepresents multiple files.";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
								-text => $self->{'Configure'}{'-EDlgText'},
								-bitmap => 'error'
					)->Show;

					return;
				}
				my $filenames = '';
				my $errnames = '';
				my @filters = split (/\|/o, $self->{'Configure'}{'-FPatFilters'});
				@filters = ('')  unless ($#filters >= 0);
FILELOOP1:				foreach my $f (@filelist)   #ADD FULL PATHS TO ANY THAT ARE MISSING PATHS!:
				{
					$f =~ s#\\#\/#go;
					$f = $driveletter . $f  if ($f =~ m#^\/#o);
					$f = $fname . $f  unless ($f =~ m#^\w\:#o);
					if ($f =~ m#^(\w\:)([^\/].*)$#o)  #FIX "RELATIVE" PATHS, IE. "c:relpath/file", "c:file", ETC.:
					{
						my $dl = $1;
						my $fn = $2;
						($f = Win32::GetFullPathName($dl)) =~ s#\\#\/#go;
						$f .= '/'  unless ($f =~ m#\/$#o);
						$f .= $fn;
					}
					if ($self->{'Configure'}{'-Create'} > 0 || -f $f)   #SEPARATE THE SHEEP FROM THE GOATS:
					{
						if (!$filters[0] || $filters[0] =~ /^\*$/o)
						{
							$filenames .= $f . ',';
							next;
						}
						foreach my $filter (@filters)
						{
							if ($f =~ /^${filter}$/)
							{
								$filenames .= $f . ',';
								next FILELOOP1;
							}
						}
						$errnames .= $f . ', ';
						$filenames .= $f . ',';
					}
					else
					{
						$errnames .= $f . ', '  if (! -f $f);
					}
				}
				if ($errnames)   #SEND THE GOATS TO THE ERROR DIALOG HELL:
				{
					$errnames =~ s/\,\s*$//;
					## Put up no create allowed dialog
					my $errdesc = '';
					if ($self->{'Configure'}{'-Create'} <= 0)
					{
						$errdesc = 'existing file';
						$errdesc .= "\nwith a matching extention"  if ($self->{'Configure'}{'-FPatOnly'});
					}
					else
					{
						$errdesc .= 'file with matching extention';
					}
					$errdesc =~ s/file/file(s)/
							if ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/i);
					$self->{'Configure'}{'-EDlgText'} = "You must specify ${errdesc}.\n"
							. "($errnames)";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
							-text => $self->{'Configure'}{'-EDlgText'},
							-bitmap => 'error')->Show;

					return;
				}

				($fname = $filenames) =~ s/\,\s*$//;
			}
		}
		else  #-SelDir is 1:  IT'D BETTER BE A DIRECTORY!:
		{
			if ($self->{'Configure'}{'-Create'} <= 0 && !(-d $fname))
			{
				## Put up no create allowed dialog
				$self->{'Configure'}{'-EDlgText'} = "You must specify an existing folder.\n($fname not found)";
				$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
						-text => $self->{'Configure'}{'-EDlgText'},
						-bitmap => 'error'
				)->Show;

				$fname =~ s/ file(\W*)$/ directory$1/i;
				return;
			}
		}
	}
	else   #REST OF THE NON-WINDOWS WORLD:
	{
		@{$self->{'Configure'}{'HistList'}} = $self->{'FileEntry'}->choices()  if ($histHasChanged);
		$path =~ s/^\~/${homedir}/;
		$path .= '/'  unless ($path =~ m#\/$#);
		#AT THIS POINT PATH ENDS IN "/" AND DOES NOT START WITH "~":
		if ($path =~ m#^\/#)
		{
			$fname = $path;
		}
		else
		{
			my $cwd = &cwd() || &getcwd();
			$cwd .= '/'  unless ($cwd =~ m#\/$#);
			$fname = $cwd . $path;
		}
		$path = $fname;
		#AT THIS POINT, $fname & $path ARE A FULL "/path/"!
		if ($self->{'Configure'}{'-SelDir'} != 1)  #(-1, 0, OR 2) FILES ALLOWED OR REQUIRED:
		{
			if ($self->{'Configure'}{'-File'} le ' ')  #NO FILES SPECIFIED:
			{
				if ($self->{'Configure'}{'-SelDir'} < 2)  #(-1 or 0: FILE REQUIRED), NONE ENTERED, RETURN OK THOUGH!
				{
					$self->{'RetFile'} = undef;
					$self->{'Retval'} = -1;
					return;
				}
				elsif ($self->{'Configure'}{'-Create'} <= 0 && !(-d $fname))
				{
					## Put up no create allowed dialog
					$self->{'Configure'}{'-EDlgText'} = "You must specify an existing directory.\n($fname not found)";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
							-text => $self->{'Configure'}{'-EDlgText'},
							-bitmap => 'error'
					)->Show;

					return;
				}
			}
			else  #ONE OR MORE FILES SPECIFIED:
			{
				unless ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/i 
						|| $self->{'Configure'}{'-File'} !~ /\,/)
				{
					$self->{'Configure'}{'-EDlgText'} = "Only a single file is allowed!\n" 
							. $self->{'Configure'}{'-File'} . "\nrepresents multiple files.";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
								-text => $self->{'Configure'}{'-EDlgText'},
								-bitmap => 'error'
					)->Show;

					return;
				}
				$fnamex = $self->{'Configure'}{'-File'};  #1 OR MORE FILES, SEPARATED BY COMMAS:
				$fnamex =~ s/^\~/${homedir}/go;
					#$fname = $path . $self->{'Configure'}{'-File'}; #CHGD. TO NEXT 20050417 PER PATCH FROM Paul Falbe.
					#($fname = $path . $self->{'Configure'}{'-File'}) =~ s/\,\s*/\,$path/g;
				($fname = $fnamex) =~ s#\,\s*([^\/])#\,${path}$1#g;   #FIXES ANY RELATIVE PATHS (EXCEPT 1ST ONE).
				$fname = $path . $fname  unless ($fname =~ m#^\/#o);  #FIX 1ST ONE, IF RELATIVE.
				#$fname IS NOW A LIST OF ONE OR MORE ABSOLUTE FILENAMES:
				$fname =~ s/\s*\,\s*/\,/g;
				my @filelist = split (/\,/, $fname);
				my $filenames = '';
				my $errnames = '';
				my @filters = split (/\|/o, $self->{'Configure'}{'-FPatFilters'});
				@filters = ('')  unless ($#filters >= 0);
FILELOOP2:				foreach my $f (@filelist)
				{
					if ($self->{'Configure'}{'-Create'} > 0 || -f $f)   #SEPARATE THE SHEEP FROM THE GOATS:
					{
						if (!$filters[0] || $filters[0] =~ /^\*$/o)
						{
							$filenames .= $f . ',';
							next;
						}
						foreach my $filter (@filters)
						{
							if ($f =~ /^${filter}$/)
							{
								$filenames .= $f . ',';
								next FILELOOP2;
							}
						}
						$errnames .= $f . ', ';
					}
					else
					{
						$errnames .= $f . ', ';
					}
				}
				if ($errnames)   #SEND THE GOATS TO THE ERROR DIALOG HELL:
				{
					$errnames =~ s/\,\s*$//;
					## Put up no create allowed dialog
					my $errdesc = '';
					if ($self->{'Configure'}{'-Create'} <= 0)
					{
						$errdesc = 'existing file';
						$errdesc .= "\nwith a matching extention"  if ($self->{'Configure'}{'-FPatOnly'});
					}
					else
					{
						$errdesc .= 'file with matching extention';
					}
					$errdesc =~ s/file/file(s)/
							if ($self->{'Configure'}{'-SelectMode'} =~ /(?:multiple|extended)/i);
					$self->{'Configure'}{'-EDlgText'} = "You must specify ${errdesc}.\n"
							. "($errnames)";
					$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
							-text => $self->{'Configure'}{'-EDlgText'},
							-bitmap => 'error')->Show;

					return;
				}
				($fname = $filenames) =~ s/\,\s*$//;
			}
		}
		else  #-SelDir is 1:  IT'D BETTER BE A DIRECTORY!:
		{
			if ($self->{'Configure'}{'-Create'} <= 0 && !(-d $fname))
			{
				## Put up no create allowed dialog
				$self->{'Configure'}{'-EDlgText'} = "You must specify an existing directory.\n($fname not found)";
				$self->Dialog(-title => $self->{'Configure'}{'-EDlgTitle'},
						-text => $self->{'Configure'}{'-EDlgText'},
						-bitmap => 'error'
				)->Show;

				return;
			}
		}
	}
	&add2Hist($self, $fname);
	$self->{'RetFile'} = $fname;
	$self->{'Retval'} = 1;
	return;
}

sub keyFn    #JWT: TRAP LETTERS PRESSED AND ADJUST SELECTION ACCORDINGLY.
{
	my ($e,$w,$l) = @_;
	my $mykey = $e->XEvent->A;
	if ($mykey)
	{
		my ($entryval) = $e->get;
		$entryval =~ s#(.*/)(.*)$#$2#;
		&LbFindSelection($l,$entryval);
	}
}

sub LbFindSelection
{
	my ($l, $var_ref, $srchval) = @_;

	return -1  unless ($l);

	$srchval = $var_ref  unless ($srchval);
	$l->configure(-selectmode => 'browse')
			if (defined($l->{'Configure'}{'-selectmode'}) && $l->{'Configure'}{'-selectmode'} eq 'single');
	my @listsels = ();
	eval '@listsels = $l->get(\'0\',\'end\');';
	return -1  if ($@);

	if ($srchval eq '')
	{
		$l->selectionClear('0','end');
		return -1;
	}

	if ($#listsels >= 0 && $listsels[0] =~ /^\d\d\d\d\d\d\d\d \d\d\d\d /o)
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
			return $i;
		}
	}
	return -1;
}

sub chgDriveLetter   #ADDED 20010130 BY JWT.
{
	my ($self) = shift;

	$driveletter =~ tr/a-z/A-Z/;
	$driveletter = substr($driveletter,0,1) . ':'  if (length($driveletter) >= 2 || $driveletter =~ /^[A-Z]$/o);
	$self->{'Configure'}{'-Path'} = ''  if ($_[2] =~ /(?:listbox|key\.\w)/o);
	if ($self->{'Configure'}{'-Path'} !~ /\S/o)
	{
		$self->{'Configure'}{'-Path'} = $lastPaths{$driveletter} || Win32::GetFullPathName($driveletter);
		$self->{'Configure'}{'-Path'} =~ s#\\#\/#go;
	}
	&RescanFiles($self);
}

sub SortFiles
{
	my ($self) = shift;

	&RescanFiles($self);
}

1;

__END__
