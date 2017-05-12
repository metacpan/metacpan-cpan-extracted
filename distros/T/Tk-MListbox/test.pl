#!/usr/bin/perl -w

## THIS IS ONE OF THE TEST SCRIPTS THAT HANS PROVIDED WITH MLISTBOX
## It IS STILL UNDERGOING EDITS BY ME - RCS

## MListbox demonstration application. This is a simple directory browser
## Original Author: Hans J. Helgesen, December 1999.
## Modified by: Rob Seegel, to work in Win32 as well
## Use and abuse this code. I did - RCS

use File::stat;
use Tk;
use Tk::MListbox;

## Create main perl/tk window.
my $mw = MainWindow->new;

## Create the MListbox widget. 
## Specify alternative comparison routine for integers and date.
## frame, but since the "Show All" button references $ml, we have to create
## it now. 

my %red = qw(-bg red -fg white);
my %green = qw(-bg green -fg white);
my %white = qw(-fg black);

my $ml = $mw->Scrolled('MListbox',
    -scrollbars => 'osoe',
    -background => 'white', 
    -foreground => 'blue',
    -textwidth => 10,
    -highlightthickness => 2,
    -width => 0,
    -selectmode => 'browse',
    -bd=>2,
    -relief=>'sunken',
    -columns=>[
        [qw/-text Mode -textwidth 10/, %red],
	[qw/-text NLink -textwidth 5/, %green, 
            -comparecmd => sub {$_[0] <=> $_[1]}],
	[qw/-text UID/, %white],
	[qw/-text GID/, %green],
	[qw/-text Size/,%red, 
            -comparecmd => sub {$_[0] <=> $_[1]}],
	[qw/-text Mtime/, %green, 
	    -comparecmd => \&compareDate],
        [qw/-text Name/, %white]
 ]);


## Put the exit button and the "Show All" button in 
## a separate frame.
my $f = $mw->Frame(
    -bd=>2,
    -relief=>'groove'
)->pack(qw/-anchor w -expand 0 -fill x/);

$f->Button(
    -text=>'Exit',
    -command => sub{exit}
)->pack(qw/-side right -anchor e/);

$f->Button(
    -text=>'Show All', 
    -command=>sub {
        foreach ($ml->columnGet(0,'end')) {
	    $ml->columnShow($_);
        }
})->pack(qw/-side left -anchor w/);

# Put the MListbox widget on the bottom of the main window.
$ml->pack(-expand=>1, -fill=>'both', -anchor=>'w');

# Double clicking any of the data rows calls openFileOrDir()
# (But only directories are handled for now...)
$ml->bindRows("<Double-Button-1>", \&openFileOrDir);

# Right-clicking the column heading creates the hide/show popup menu.
$ml->bindColumns("<Button-3>", [\&columnPopup]);


$ml->bindRows('<ButtonRelease-1>',  
    sub {
        my ($w, $infoHR) = @_;
        print "You selected row: " . $infoHR->{-row} .
             " in column: " . $infoHR->{-column} . "\n";
    }
);


# Start by showing the current directory.
directory (".");

MainLoop;

#----------------------------------------------------------
#
sub directory
{
    my ($dir) = @_;

    chdir($dir);
    
    my $pwd = `pwd`; chomp $pwd;
    $mw->title ("Directory: $pwd");
    
    # Empty $ml
    $ml->delete(0,'end');
    
    opendir (DIR, ".") or die "Cannot open '.': $!\n";
    
    foreach my $name (readdir(DIR)) {	
	my $st = stat($name);
        my $mode = $st->mode;
	
	my $type = do {
	    if (-l $name) {
		$mode = 0777;
		'l';
	    } elsif (-f $name) {
		'-';
	    } elsif (-d $name) {
		'd';
	    } elsif (-p $name) {
		'p';
	    } elsif (-b $name) {
		'b';
	    } elsif (-c $name) {
		'c';
	    } else {
		' ';
	    }};
	    
	my $mtime = localtime($st->mtime);
	$mode = $type . convMode ($st->mode);
        $ml->insert('end', 
            [$mode, $st->nlink, $st->uid, $st->gid, $st->size, $mtime,$name]
        );
    }
}

# This callback is called if the user double-clicks one of the rows in
# the MListbox. If the selected file is a directory, open it.
#
sub openFileOrDir
{
    my @sel = $ml->curselection;
    if (@sel == 1) {
	my ($mode, $name) = ($ml->getRow($sel[0]))[0,6];
	if ($mode =~ m/^d/) {   # Directory?
	    directory ($name);
	}
    }
}

# This callback is called if the user right-clicks the column heading.
# Create a popupmenu with hide/show options.
sub columnPopup
{
    my ($w, $infoHR) = @_;
    
    # Create popup menu.
    my $menu = $w->Menu(-tearoff=>0);
    my $index = $infoHR->{'-column'};  


    # First item is "Hide (this column)".
    #
    $menu->add ('command',
		-label=>"Hide ".$w->columnGet($index)->cget(-text),
		-command=>sub {
		    $w->columnHide($index);
		});
    $menu->add ('separator');

    # Create a "Show" entry for each column that is not currently visible.
    #
    foreach ($w->columnGet(0,'end')) {  # Get all columns from $w.
	unless ($_->ismapped) {
	    $menu->add('command',
		       -label=>"Show ".$_->cget(-text),
		       -command=>[ $w => 'columnShow', $_, -before=>$index],
		       );
	}
    }
    $menu->Popup(-popover=>'cursor');
}

# Converts a numeric file mode to the format provided by the ls command.
#
sub convMode 
{
    my $mode = shift;
    my $result = '';

    $result .= ($mode & 0400) ? 'r' : '-';
    $result .= ($mode & 0200) ? 'w' : '-';
    if ($mode & 0100) {
	if ($mode & 04000) {
	    $result .= 's';
	} else {
	    $result .= 'x';
	}
    } else {
	$result .= '-';
    }

    $result .= ($mode & 040) ? 'r' : '-';
    $result .= ($mode & 020) ? 'w' : '-';
    if ($mode & 010) {
	if ($mode & 02000) {
	    if (($mode & 02010) || 
		($mode & 02030) ||
		($mode & 02050) ||
		($mode & 02070))
	    {
		$result .= 's';
	    } else {
		$result .= 'l';
	    }
	} else {
	    $result .= 'x';
	}
    } else {
	$result .= '-';
    }

    $result .= ($mode & 04) ? 'r' : '-';
    $result .= ($mode & 02) ? 'w' : '-';
    $result .= ($mode & 01) ? 'x' : '-';

    return $result;
}

# Callback for date comparison. Expects that the dates are on the format
# "day mon dd hh:mm:ss yyyy", for example "Tue Dec  7 12:13:11 1999".
#
sub compareDate
{
    my ($d1, $d2) = @_;
    convertDate($d1) cmp convertDate($d2);
}
sub convertDate
{
    my ($str) = @_;
    my ($wday,$mon,$day,$hour,$min,$sec,$year) = 
	($str =~ m/(\S*)\s*(\S*)\s*(\d*)\s*(\d\d):(\d\d):(\d\d)\s*(\d\d\d\d)/);

    my $month=0;
    foreach (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/) {
	if ($mon eq $_) {
	    last;
	} else {
	    $month++;
	}
    }
    return sprintf ("%04d%02d%02d%02d%02d%02d", 
		    $year,$month,$day,$hour, $min, $sec);
}




