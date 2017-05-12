#From:	IN%"powers@swaps-comm.ml.com"  "Brent B. Powers Swaps Programmer x2293" 12-JAN-1996 15:53:27.41
#To:	IN%"nik@tiuk.ti.com"  "Nick Ing-Simmons"
#CC:	IN%"powers@swaps-post.swaps-comm.ml.com", IN%"ptk@guest.WPI.EDU", IN%"derf@asic.sc.ti.com"  "Fred Wagner"
#Subj:	RE: Suggestion for FileSelect.pm

#Nick Ing-Simmons writes:
# > In <199601120434.XAA15469@swapsdvlp02.ny-swaps-develop.ml.com>
# > On Thu, 11 Jan 1996 23:34:02 -0500
# > Brent B Powers Swaps Programmer X <powers@swaps-comm.ml.com> writes:
# > >I actually have one that does much of what is requested, and has been
# > >bog solid reliable for the last 3 or 4 months.  
# > >
# > >It wasn't until after I wrote this that someone (I think) put out one
# > >with the distribution....
# > >
# > >Unfortunately, I wrote it in the days of Tk-b5 or 6, and so it doesn't
# > >use the new combo box conventions.  I also don't think I'll have time
# > >to work on it for the next two weeks or so....  After that, it ought
# > >not take long to componentize it...
# > >
# > >Let me know via email if anyone wants to take a look...
# > 
# > I do ;-)
# > 
#;;; OK, then here it is.... un-composted..... By the way, did you ever
#take a look at what happens when you disable a menu button?  (I
#submitted it as a bug a couple of weeks ago, but haven't even had time
#to beg for installation of Tk-b9 yet...)


##################################################
##################################################
##						##
##	FileDialog - a reusable Tk-widget	##
##		     login screen		##
##						##
##	Version 1.0				##
##	Module:  %M%				##
##	Release: %I%				##
##	Delta:   %G% %U%			##
##	Fetched: %H% %T%			##
##						##
##	Brent B. Powers				##
##	Merrill Lynch				##
##	powers@swaps-comm.ml.com		##
##						##
##						##
##################################################
##################################################

## Change History:
## Version 1.0 - Initial implementation

## FileDialog is implemented as a Perl5 object with a number of methods,
## described below.  Simply create the FileDialog object, configure it
## (if desired), and activate it.  Careful attention should be paid
## to the configuration options, most notably CreateFlag and ChdirFlag.
##
## Create the FileDialog object with an implicit 'new'
## (i.e.
## 	use FileDialog;
## 	$main = MainWindow->new;
## 	$fdialog = $main->FileDialog;
## )
##
## At that point, the FileDialog should probably be configured via the
## 'configure' method.  Note that configuration options may be specified
## at creation time, as well. configure may be called with any number of
## options, and multiple options may also be specified at creation time.
##
## For instance:
##
## 	use FileDialog;
##
## 	$main = MainWindow->new;
## 	$fdialog = $main->FileDialog('Title'=>'Select File',
## 				     'CreateFlag' => 0);
## 	$fdialog->configure('Path' => "$ENV{'HOME'}",
## 			    'FileMask' => '*',
## 			    'ShowAllFlag' => 'NO',
##			    'grabflag => 1);
##
## Finally, the FileDialog is activated by the show method.  show returns
## undefined if the user selected cancel, and the selected file name otherwise.
## show also may take configuration options as parameters. Thus, given the
## code fragment above:
##
## 	$fname = $fdialog->show('ChDirFlag' => 1,
## 				'DisableShowAll' => 'YES');
## 	if (defined($fname)) {
## 	    open (FILE, $fname);
## 	} else {
## 	    die "What do you mean, Cancel?\n";
## 	}
##

## The CreateFlag, DisableShowAllFlag, ShowAllFlag, and ChDirFlag
## configuration options are, clearly, flags.  As such, they may
## be set with 'YES','TRUE', or 1 for true (case is not considered),
## or 'FALSE', 'No' or 0 for false.  An invalid flag will cause a message
## to be printed to the console, and the flag will be reset to default!.
##

## The following are valid options for configure, new, and show:
##  (Key is #dw
##	where d is debugged, and w is written (- is no, x is yes))
##

###
### ChDirFlag
###	Set to TRUE to allow the user to change directories.  False
###	allows selection or creation in the current directory only.
###	The default is true.  Setting this value to false disables
###	the pathname entry field.
###
### CreateFlag
###	Set to TRUE to allow the user to specify a non-existent
###	file name.  False only allows specification of previously
###	existing file names.  The default is true.
###
### DisableShowAll
###	Set to FALSE to enable the user to utilize the ShowAll
###	radio button.  True disables the radio button, which is
###	set to whatever was specified via the ShowAllFlag. The
###	default is FALSE.
###
### File
###	Set to an initial value for the file.  If specified, and
###	the file exists, it will be highlighted in the list box.
###
### FileMask
###	Set to an initial specification pattern for the filename.
###	The default is "*".
###
### grabFlag
###	Set to TRUE to do an application level grab, false does
###	no grab.  Default it True
###
### Path
###	Set to the initial directory.  If unspecified, it will
###	default to that specified by the users HOME environment
###	setting.
###
### ShowAllFlag
###	Set to TRUE to show hidden files (.*) as well as normal
###	files.  The user may change this flag via the radio
###	button unless disallowed via the DisableShowAll configuration
###	option.  The default is false.
###
### Horizontal
###	Set to TRUE to enable the directory box to be to the LEFT
###	of the file box.  Set to false to enable the directory box
###	to be above the file box.  The default is false.
###
### Title
###	Set to the Window Title of the FileDialog window.  The default
###	is "Select File."

package ML::FileDialog;

require 5.001;
use Tk;
use Tk::Dialog;
use Carp;

@ISA = qw(Tk::Toplevel);

@FileDialog::Inherit::ISA = @ISA;

#bless(\qw(FileDialog))->WidgetClass;
Tk::Widget->Construct('FileDialog');


####  PUBLIC METHODS ####
sub configure {
    ## Configuration methods for File Dialog box.  Options are
	### ChDirFlag			### FileMask
	### CreateFlag			### Path
	### DisableShowAll		### ShowAllFlag
	### File			### Title
        ### GrabFlag			### Horizontal
    ## Any other configuration options are passed through to the parent.
    $self = shift;

    my (@config_list) = @_;

    my ($i, $val, $configval);

    for ($i = 0;$i < $#config_list; $i +=2) {
	$configval = lc($config_list[$i]);
	if ($configval eq 'chdirflag') {

	    &ParseFlag($self, $config_list[$i+1],'Chdir', 1);

	} elsif ($configval eq 'createflag') {

	    &ParseFlag($self, $config_list[$i+1],'Create', 1);

	} elsif ($configval eq 'showallflag') {

	    &ParseFlag($self, $config_list[$i+1],'Show', 0);

	} elsif ($configval eq 'disableshowall') {

	    &ParseFlag($self, $config_list[$i+1],'DisableShow', 0);

	} elsif ($configval eq 'horizontal') {

	    &ParseFlag($self, $config_list[$i+1],'Horiz', 0);
	    &BuildListBoxes($self,$self->{'Chdir'});

	} elsif ($configval eq 'file') {

	    &ParseString($self,$config_list[$i+1],'File');

	} elsif ($configval eq 'filemask') {

	    &ParseString($self,$config_list[$i+1],'FPat');

	} elsif ($configval eq 'path') {
	    
	    &ParseString($self,$config_list[$i+1],'Path');
	    if ((!-d $self->{'Path'}) || ($self->{'Path'} eq "")) {
		carp "$config_list[$i+1] is not a valid path\n";
		$self->{'Path'} = $ENV{"HOME"};
	    }
	} elsif ($configval eq 'title') {

	    &ParseString($self,$config_list[$i+1],'Title');

	} elsif ($configval eq 'grabflag') {

	    &ParseFlag($self, $config_list[$i+1],'Grab', 1);

	} else {
	    ## Pass through to the parent classes
	    return $self->parent->configure(@_);
	}
    }
}

sub new {
    # Constructor for the File Dialog box
    my($Class) = shift;
    my($Parent) = shift;

    my($self) = {};
    bless $self;

    ### Initialize instance variables
    $self->{'Show'} = 0;
    $self->{'DisableShow'} = 0;
    $self->{'FPat'} = "*";
    $self->{'File'} = "";
    $self->{'Path'} = "$ENV{'HOME'}";
    $self->{'Title'} = "Select File:";
    $self->{'Create'} = 1;
    $self->{'Chdir'} = 1;
    $self->{'Retval'} = -1;
    $self->{'Grab'} = 1;
    $self->{'Horiz'} = 0;


    ## Create the window itself
    my ($FDTop) = $Parent->Toplevel;
    $self->{'FDTop'} = $FDTop;

    $self->{'DFFrame'} = 0;

    $FDTop->withdraw;

    &BuildFDWindow($self, @_);

    ##  And check for any configuration items
    $self->configure(@_);

    ## return the object for further reference
    return $self;
}

sub show {
    my ($self) = shift;

    ## First, check for additional configuration items
    $self->configure(@_);

    ## Do any configuration that we need to
    $self->{'FPat'} = '*' unless $self->{'FPat'} ne "";

    ## Set up, or remove, the directory box
    if ($self->{'Chdir'}) {
	&EnableDirWindow($self);
    } else {
	&DestroyDirWindow($self);
    }

    ## Enable, or disable, the show all box
    if ($self->{'DisableShow'}) {
	$self->{'SABox'}->configure(-state => 'disabled');
    } else {
	$self->{'SABox'}->configure(-state => 'normal');
    }

    my($FDT) = $self->{'FDTop'};
    $FDT->title($self->{'Title'});

    ## Create window position
    ## (Right now, we'll just center the damned thing)
    my $winvx = $FDT->parent->vrootx;
    my $winvy = $FDT->parent->vrooty;
    my $winrw = $FDT->reqwidth;
    my $winrh = $FDT->reqheight;
    my $winsw = $FDT->screenwidth;
    my $winsh = $FDT->screenheight;
    my $x = int($winsw/2 - $winrw/2 - $winvx);
    my $y = int($winsh/2 - $winrh/2 - $winvy);

    &RescanFiles($self);
    ## Restore the window, and go
    $FDT->deiconify;

    $FDT->grab if ($self->{'Grab'});


    $self->{'Retval'} = 0;
    $self->{'RetFile'} = "";

    $FDT->tkwait('variable',\$self->{'Retval'});

    $FDT->grab('release');

    $FDT->withdraw;

    if ($self->{'Retval'} == -1) {
	## User hit cancel
	return undef;
    } else {
	## It should equal 1... return the value
	return $self->{'RetFile'};
    }

}

####  PRIVATE METHODS AND SUBROUTINES ####
sub IsNum {
    my($parm) = @_;
    my($warnSave) = $;
    $ = 0;
    my($res) = (($parm + 0) eq $parm);
    $ = $warnSave;
    return $res;
}

sub ParseFlag {
    ## Given a flag (1, yes, t, or true for 1, or 0, no, f, or false for
    ## 0), return either 0, 1, or undef if not matched
    my ($self, $flag, $var, $dflt) = @_;
    
    ## Calculate whether it's a zero or a 1 (or undef if bad)
    if (&IsNum($flag)) {
	$flag = 1 unless $flag == 0;
    } else {
	my ($fc) = lc(substr($flag,0,1));
	
	if (($fc eq "y") || ($fc eq "t")) {
	    $flag = 1;
	} elsif (($fc eq "n") || ($fc eq "f")) {
	    $flag = 0;
	} else {
	    ## bad value... complain about it
	    carp ("\"$flag\" is not a valid flag!");
	    $flag = $dflt;
	}
    }
    $self->{"$var"} = $flag;
    return $flag;
}

sub ParseString {
    ### Given a string and entry value, set the entry to the string
    my($self, $val, $entry) = @_;
    if (!defined($val)) {
	$val = "";
    }
    $self->{"$entry"} = $val;
}

my(@topPack) = (-side => 'top', -anchor => 'center');

sub DestroyDirWindow {
    my($self) = shift;

    if ($self->{'DirFrame'} ne "") {
	$self->{'DirFrame'}->destroy if $self->{'DirFrame'}->IsWidget;
	$self->{'DirFrame'} = "";
    }

    ## Lastly, disable the DirEntry
    $self->{'DirEntry'}->configure(-state=>'disabled');

}

sub EnableDirWindow {
    my($self) = shift;

    if ($self->{'DirFrame'} eq "") {
	&BuildListBox($self,'DirFrame','Directories:', 'DirList');
    }
    $self->{'DirEntry'}->configure(-state=>'normal');
}

sub BuildListBox {
    my ($self) = shift;
    my($fvar, $flabel, $listvar,$hpack, $vpack) = @_;

    my ($FDT) = $self->{'DFFrame'};

    ## Create the subframe
    my($sF) = $FDT->Frame;
    $self->{"$fvar"} = $sF;

    my($pack) = $self->{'Horiz'} ? $hpack : $vpack;

    $sF->pack(-side => "$pack",
	      -anchor => 'center',
	      -fill => 'both',
	      -expand => 1);
    ## Create the label
    $sF->Label(-relief => 'raised',
		   -text => "$flabel")
	    ->pack(@topPack, -fill => 'x');

    ## Create the frame for the list box
    my($fbf) = $sF->Frame;
    $fbf->pack(@topPack, -fill => 'both', -expand => 1);

    ## And the scrollbar and listbox in it
    my $fl = $fbf->Listbox(-relief => 'raised');
    $self->{"$listvar"} = $fl;

    $fl->pack(-side => 'left',
	      -anchor => 'center',
	      -expand => 1, 
	      -fill => 'both');

    my($fs) = $fbf->Scrollbar(-borderwidth => 1,
			      -relief => 'raised',
			      -command => ['yview',$fl]);

    $fs->pack(-side => 'right',
	      -anchor => 'center',
	      -fill => 'y');

    ## Now set up the horizontal scroll bar frame and bar
    my $fh = $sF->Frame;
    $fh->pack(@topPack,-expand => 1,-fill => 'x');

    my $fhs = $fh->Scrollbar(-borderwidth => 1,
			     -orient => 'horizontal',
			     -relief => 'raised',
			     -command => ['xview', $fl]);

    $fhs->pack(-side => 'left',
	       -anchor => 'center',
	       -expand => 1,
	       -fill => 'x');

    $fh->Frame(-width => 17)
	    ->pack(-side => 'right',
		   -anchor => 'center');

    ## Finally, configure the listbox to use the scrollbars
    $fl->configure(-yscrollcommand => ['set', $fs],
		   -xscrollcommand => ['set', $fhs]);
		   

}

sub BindDir {
    ### Set up the bindings for the directory selection list box
    my($self) = @_;

    my($lbdir) = $self->{'DirList'};
    $lbdir->bind("<Double-1>" => sub {
	my($np) = $lbdir->get('active');
	if ($np eq "..") {
	    ## Moving up one directory
	    $self->{'Path'} =~ s!(.*)/[^/]*$!$1!;
	} else {
	    ## Going down into a directory
	    $self->{'Path'} .= "/" . "$np";
	}
	\&RescanFiles($self);
    });
}

sub BindFile {
    ### Set up the bindings for the file selection list box
    my($self) = @_;
    ## A single click selects the file...
    $self->{'FileList'}->bind("<ButtonRelease-1>", sub {
	$self->{'File'} = $self->{'FileList'}->get('active');
    });
    ## A double-click selects the file for good
    $self->{'FileList'}->bind("<Double-1>", sub {
	$self->{'File'} = $self->{'FileList'}->get('active');
	$self->{'OK'}->invoke;
    });


}

sub BuildEntry {
    ### Build the entry, label, and frame indicated.  This is a 
    ### convenience routine to avoid duplication of code between
    ### the file and the path entry widgets

    my($self) = shift;

    my($LabelTitle, $LabelVar, $entry) = @_;

    my($FDT) = $self->{'FDTop'};

    ## Create the entry frame
    my $eFrame = $FDT->Frame(-relief => 'raised');
    $eFrame->pack(@topPack, -fill => 'x');

    ## Now create and pack the title and entry
    $eFrame->Label(-relief => 'raised',
		   -text => $LabelTitle)
	    ->pack(-side => 'left',
		   -anchor => 'center');

    my $eEntry = $eFrame->Entry(-relief => 'raised',
				-textvariable => \$self->{"$LabelVar"});

    ## Pack up the title and entry
    $eEntry->pack(-side => 'right',
		  -anchor => 'center',
		  -expand => 1,
		  -fill => 'x');

    $eEntry->bind("<Return>",sub {\&RescanFiles($self)});

    $self->{"$entry"} = $eEntry;

    return $eFrame;
}

sub BuildListBoxes {
    my($self) = shift;
    my($bvar) = shift;


    ## Destroy both, if they're there
    if ($self->{'DFFrame'}) {
	$self->{'DFFrame'}->destroy;
    }

    $self->{'DFFrame'} = $self->{'FDTop'}->Frame;
    $self->{'DFFrame'}->pack(-before => $self->{'FEF'},
			     @topPack,
			     -fill => 'both',
			     -expand => 1);

    ## Build the file window before the directory window, even
    ## though the file window is below the directory window, we'll
    ## pack the directory window before.
    &BuildListBox($self, 'FileFrame','File:', 'FileList','right','bottom');
    ## Set up the bindings for the file list
    &BindFile($self);

    if ($bvar) {
	&BuildListBox($self,'DirFrame','Directories:', 'DirList','left','top');
	&BindDir($self);
    }
}

sub BuildFDWindow {
    ### Build the entire file dialog window
    my($self) = shift;
    my($FDT) = $self->{'FDTop'};

    $FDT->title($self->{'Title'});

    ### Build the filename entry box
    $self->{'FEF'} = &BuildEntry($self, 'Filename:', 'File', 'FileEntry');

    &BuildListBoxes($self,1);

    ### Build the pathname directory box
    &BuildEntry($self, 'Pathname:', 'Path','DirEntry');

    ### Now comes the multi-part frame
    my $patFrame = $FDT->Frame(-relief => 'raised');
    $patFrame->pack(@topPack, -fill => 'x');

    ## Label first...
    $patFrame->Label(-relief => 'raised',
		     -text => 'Filter')
	    ->pack(-side => 'left',
		   -anchor => 'center');

    ## Now the entry...
    my($patE) = $patFrame->Entry(-relief => 'raised',
				 -textvariable => \$self->{'FPat'});
    $patE->pack(-side => 'left',
		-anchor => 'center',
		-expand => 1,
		-fill => 'x');
    $patE->bind("<Return>",sub {\&RescanFiles($self);});


    ## and the radio box
    my($sbox) = $patFrame->Checkbutton(-text => 'Show All',
				       -variable => \$self->{'Show'});
    $sbox->configure(-command => sub {\&RescanFiles($self);});
    $sbox->pack(-side => 'left',
		-anchor => 'center');
    $self->{'SABox'} = $sbox;

    ### FINALLY!!! the button frame
    my $butFrame = $FDT->Frame(-relief => 'raised');
    $butFrame->pack(@topPack, -fill => 'x');

    $self->{'OK'} = $butFrame->Button(-text => 'OK',
				      -command => sub {
					  \&GetReturn($self);
				      });
    $self->{'OK'}->pack(-side => 'left',
			-anchor => 'center',
			-expand => 1,
			-fill => 'x');

    $butFrame->Button(-text => 'Rescan',
		      -command => sub {
			  \&RescanFiles($self);
		      })
	    ->pack(-side => 'left',
		   -anchor => 'center',
		   -expand => 1,
		   -fill => 'x');

    $butFrame->Button(-text => 'Cancel',
		      -command => sub {
			  $self->{'Retval'} = -1;
		      })
	    ->pack(-side => 'left',
		   -anchor => 'center',
		   -expand => 1,
		   -fill => 'x');


}

sub RescanFiles {
### Fill the file and directory boxes
    my($self) = shift;

    my($fl) = $self->{'FileList'};
    my($dl) = $self->{'DirList'};
    my($path) = $self->{'Path'};
    my($show) = $self->{'Show'};
    my($chdir) = $self->{'Chdir'};

    if (!-d $self->{'Path'}) {
	carp "$path is NOT a directory\n";
	return 0;
    }
    chop($path) if (substr($path,-1,1) eq "/");

    opendir(ALLFILES,$path);
    my(@allfiles) = readdir(ALLFILES);
    closedir(ALLFILES);

    my($direntry);

    ## First, get the directories...
    if ($chdir) {
	$dl->delete(0,'end');
	foreach $direntry (sort @allfiles) {
	    next if !-d "$path/$direntry";
	    next if $direntry eq ".";
	    if (   !$show
		&& (substr($direntry,0,1) eq ".")
		&& $direntry ne "..") {
		next;
	    }
	    $dl->insert('end',$direntry);
	}
    }

    ## Now, get the files
    $fl->delete(0,'end');
    my($pat) = $self->{'FPat'};
    $_ = $pat;
    s/^[ \t]*//;
    s/[ \t]*$//;
    if ($_ eq "") {
	$pat = $self->{'FPat'} = '*';
    }
    my($pat) = $self->{'FPat'};
    
    undef @allfiles;

    if ($show) {
	my($hpat) = "." . $pat;
	@allfiles = <$path/$hpat>;
    }
    @allfiles = (@allfiles, <$path/$pat>);
    foreach $direntry (sort @allfiles) {

	if (-f "$direntry") {
	    $direntry =~ s!.*/([^/]*)$!$1!;
	    $fl->insert('end',$direntry);
	}
    }
    return 1;
}

sub GetReturn {
    my ($self) = @_;

    ## Construct the filename
    my $path = $self->{'Path'};
    my $fname = $self->{'File'};

    my $p = $path;
    $path .= "/" if (chop($p) ne "/");

    $fname = $path . $self->{'File'};

    if (!$self->{'Create'}) {
	## Make sure that the file exists, as the user is not allowed
	## to create
	if (!-f $fname) {
	    ## Put up no create dialog
	    my $top = $self->{'FDTop'};
	    my $DBOX = $top->Dialog('File does not exist!',
				    "You must specify an existing file.\n" .
				    "$fname not found",
				    'error',
				    'OK',
				    'OK');
	    $DBOX->configure(Message, -justify => 'center');
	    $DBOX->show;

	    ## And return
	    return;
	}
    }

    $self->{'RetFile'} = $fname;
    $self->{'Retval'} = 1;
}

### Return 1 to the calling  use statement ###
1;
### End of file FileDialog.pm ###

#Brent B. Powers             Merrill Lynch          powers@swaps.ml.com

