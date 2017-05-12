From:	IN%"elston@cave.arc.nasa.gov" 12-OCT-1995 23:09:04.32
To:	IN%"lusol@Turkey.CC.Lehigh.EDU"
CC:	IN%"ptk@WPI.EDU"
Subj:	RE: FileSelect

Return-path: <owner-ptk@bigboote.WPI.EDU>
Received: from bigboote.WPI.EDU by LNS62.LNS.CORNELL.EDU (PMDF V4.3-13 #8932)
 id <01HWDC1B7YE896ZFSL@LNS62.LNS.CORNELL.EDU>; Thu,
 12 Oct 1995 23:08:50 -0400 (EDT)
Received: (from majordom@localhost) by bigboote.WPI.EDU (8.7.1/8.7.1)
 id VAA18607 for ptk-outgoing; Thu, 12 Oct 1995 21:56:25 -0400
Received: from cave.arc.nasa.gov (cave.arc.nasa.gov [128.102.130.110])
 by bigboote.WPI.EDU (8.7.1/8.7.1) with SMTP id VAA18598 for <ptk@WPI.EDU>;
 Thu, 12 Oct 1995 21:56:19 -0400
Received: from slimemold.arc.nasa.gov by cave.arc.nasa.gov (8.6.10/1.35)
 id SAA27832; Thu, 12 Oct 1995 18:56:21 -0700
Received: by slimemold.arc.nasa.gov (8.6.10) id SAA11038; Thu,
 12 Oct 1995 18:56:17 -0700
Date: Thu, 12 Oct 1995 18:56:17 -0700
From: elston@cave.arc.nasa.gov (Mark Elston)
Subject: Re: FileSelect
In-reply-to: <199510111751.NAA18970@Turkey.CC.Lehigh.EDU>
 (lusol@Turkey.CC.Lehigh.EDU)
Sender: owner-ptk@WPI.EDU
To: lusol@Turkey.CC.Lehigh.EDU
Cc: ptk@WPI.EDU
Message-id: <199510130156.SAA11038@slimemold.arc.nasa.gov>
Content-transfer-encoding: 7BIT
X-Authentication-Warning: bigboote.WPI.EDU: majordom set sender to owner-ptk
 using -f
Precedence: bulk

Stephen,

Here is my 'FileSave.pm' file I promised you.  If you modify it please
let me know since it is really a quick and dirty hack of the
FileSelect.pm anyway and I would appreciate any ideas anyone else has.

BTW, the directory box now requires a double click instead of a single
click since I had several times sent the program off into never-never
land by double-clicking on a directory name.

One thing that I thought of as a possible enhancement is to make the 
filename at the bottom be selected when the box is popped up.  This
makes any changes or just accepting the current value as simple as
hitting the return key.

Anyway, play with it and see how you like it.

Mark.

---------------------------------------------------------------------------
package Tk::FileSave;
use Tk qw(Ev);
use Carp;
use English;
use strict 'vars';
require Tk::Toplevel;
require Tk::LabEntry;
require Tk::ScrlListbox;
require Cwd;
@Tk::FileSave::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('FileSave');

=head1 NAME

 FileSave - a widget for choosing files

=head1 SYNOPSIS

 use Tk::FileSave;

 $FSref = $top->FileSave(-directory => $start_dir);
               $top            - a window reference, e.g. MainWindow->new
               $start_dir      - the starting point for the FileSave
 $FSref = $top->show;
               Executes the fileselector until either a filename is
               accepted or the user hits Cancel. Returns the filename
               or the empty string, respectively, and unmaps the
               FileSave.
 $FSref = $top->configure(option => value[, ...])
               At the moment, only one option is taken care of:
               -directory changes the starting directory for the
               Fileselector to the one given as value.

=head1 DESCRIPTION

   This Module pops up a Fileselector box, with a directory entry on
   top, a list of directories in the current directory, a list of
   files in the current directory, an entry for entering/modifying a
   file name, an accept button and a cancel button.

   You can enter a starting directory in the directory entry. After
   hitting Return, the listboxes get updated. Double clicking on any
   directory shows you the respective contents. Single clicking on a
   file brings it into the file entry for further consideration,
   double clocking on a file pops down the file selector and calls
   the optional command with the complete path for the selected file.
   Hitting return in the file selector box or pressing the accept
   button will also work. *NOTE* the file selector box will only then
   get destroyed if the file name is not zero length. If you want
   yourself take care of it, change the if(length(.. in sub
   accept_file.

=head1 AUTHORS

Based on original FileSelect by
Klaus Lichtenwalder, Lichtenwalder@ACM.org, Datapat GmbH, 
Munich, April 22, 1995
adapted by  Frederick L. Wagner, derf@ti.com, Texas Instruments Incorporated, 
Dallas, 21Jun95

=head1 HISTORY

 950621 -- The following changes were made:
   1: Rewrote Tk stuff to take advantage of new Compound widget module, so
      FileSelect is now composed of 2 LabEntry and 2 ScrlListbox2
      subwidgets.
   2: Moved entry labels (from to the left of) to above the entry fields.
   3: Caller is now able to control these aspects of widget, in both
        FileSelect (new) and configure :

      Option                Controls                            Default
      --------------------  ----------------------------------- ------------
        -directory          initial directory                   `pwd`
        -selectmode         mode of Files listbox               browse
        -dir_entry_label    label over directory filter entry   "Filter"
        -dir_list_label     label over directory listbox        "Directories"
        -file_entry_label   label over file entry               "File"
        -file_list_label    label over file listbox             "Files"
        -height             listbox height                      20
        -width              listbox width                       20
   4: I changed from Double-Button-1 to Button-1 in the Files listbox,
      to work with multiple mode in addition to browse mode.  I also
      made some name changes (LastPath --> saved_path, ...).
   5: The show method is not yet updated.
   6: The topLevel stuff is not done yet.  I took it out while I toy with
      the idea of FileSelect as a subwidget.  Then the 'normal' topLevel
      thing with Buttons along the bottom could be build on top of it.

 By request of Henry Katz <katz@fs09.webo.dg.com>, I added the functionality
 of using the Directory entry as a filter. So, if you want to only see the
 *.c files, you add a .c (the *'s already there :) and hit return.

=cut

sub Cancel
{
    my ($cw) = @_;
    $cw->{Selected} = undef;
}

sub Accept
{
    my ($cw) = @_;
    my $dir  = $cw->cget('-directory');
    $cw->{Selected} = [map( $dir . '/' . $_, $cw->Getselected)];
}

sub accept_dir
{
    my ($cw,$new) = @_;
    my $dir  = $cw->cget('-directory');
    $cw->configure(-directory => "$dir/$new");
}

sub accept_name
{
    my ($cw,$name) = @_;
    my $dir  = $cw->cget('-directory');
    $cw->{Selected} = [$dir . '/' . $name];
}

sub Populate
{
    my ($w, $args) = @_;

    $w->InheritThis($args);
    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);

    $w->{'reread'} = 0;
    $w->withdraw;

    #
    # Create Filter (or Directory) Entry, Place at the top
    #
    my $e = $w->Component(LabEntry => 'dir_entry',
			  -textvariable => \$w->{Directory},
			  -labelvariable => \$w->{Configure}{-dirlabel}
			  );
    $e->pack( -side => 'top',
	     -expand => 0,
	     -fill => 'x', );
    $e->bind('<Return>' =>  [ $w, 'configure', '-directory' => Ev(['get']) ] );

    #
    # Create File Entry, Place at the bottom
    #
    $e = $w->Component( LabEntry => 'file_entry',
		       # -labelanchor    => 'w',
		       -labelvariable => \$w->{Configure}{-filelabel}
		       );
    $e->pack( -side => 'bottom', -expand => 0, -fill => 'x');
    #    $e->bind('<Return>' => [ $w , 'validate', Ev(['get']) ] );
    $e->bind('<Return>' => [ $w , 'accept_name', Ev(['get']) ] );

    # Create Directory Scrollbox, Place at the left-middle

    my $b = $w->Component(ScrlListbox => 'dir_list', 
			  -scrollbars => 'se',
			  -labelvariable => \$w->{Configure}{-dirlistlabel});
    $b->pack(-side => 'left', 
	     -expand => 1, 
	     -fill => 'both');
    $b->bind('<Double-Button-1>' => [ $w, 'accept_dir', Ev(['Getselected']) ]);

    # Add a Label

    #   my $l = $b->Component(Label => 'label',
    # 			     -textvariable => \$w->{Configure}{-dirlistlabel});
    #   $l->pack(-fill => 'x',
    # 	         -side => 'top',
    # 	         -before => ($b->packslaves)[0]);

    my $f = $w->Frame();
    $f->pack(-side => 'right', 
	     -fill => 'y');
    $b = $f->Button('-text' => 'Accept', 
		    -command => [ 'Accept', $w ]);
    $b->pack(-side => 'top', 
	     -expand => 1);
    $b = $f->Button('-text' => 'Cancel', 
		    -command => [ 'Cancel', $w ]);
    $b->pack(-side => 'top', 
	     -expand => 1);

    # Create File Scrollbox, Place at the right-middle

    $b = $w->Component(ScrlListbox => 'file_list', 
		       -scrollbars => 'se',
		       -labelvariable => \$w->{Configure}{-filelistlabel} );
    $b->pack(-side => 'right', 
	     -expand => 1, 
	     -fill => 'both');
    $b->bind('<Double-1>' => [$w ,'Accept']);

    # Add a Label

    #   my $l = $b->Component(Label => 'label',
    # 			-textvariable => );
    #   $l->pack(-fill => 'x',
    # 	   -side => 'top',
    # 	   -before => ($b->packslaves)[0]);

    $w->ConfigSpecs(-width          => [ ['file_list','dir_list'],
					undef, undef, 20 ],
		    -height         => [ ['file_list','dir_list'],
					undef, undef, 20 ],
		    -directory      => [ METHOD, undef, undef, '.' ],
		    -filelistlabel  => [ PASSIVE, undef, undef, 'Files' ],
		    -filter         => [ METHOD, undef, undef, '*' ],
		    -filterlabel    => [ PASSIVE, undef, undef,
					'Files Matching' ],
		    -regexp         => [ PASSIVE, undef, undef, undef ],
		    -filelabel      => [ PASSIVE, undef, undef, 'File' ],
		    -dirlistlabel   => [ PASSIVE, undef, undef, 'Directories'],
		    -dirlabel       => [ PASSIVE, undef, undef, 'Directory'],
		    '-accept'       => ['CALLBACK',undef,undef, undef ],
		    DEFAULT         => [ 'file_list' ]
		    );
    $w->Delegates( DEFAULT => 'file_list' );
    return $w;
}

sub translate
{
    my ($bs,$ch) = @_;
    return "\\$ch" if (length $bs);
    return ".*"  if ($ch eq '*');
    return "."   if ($ch eq '?');
    return "\\."  if ($ch eq '.');
    return "\\/" if ($ch eq '/');
    return "\\\\" if ($ch eq '\\');
    return $ch;
}

sub filter
{
    my ($cw,$val) = @_;
    my $var = \$cw->{Configure}{'-filter'};
    if (@_ > 1) {
	my $regex = $val;
	$$var = $val;
	$regex =~ s/(\\?)(.)/&translate($1,$2)/ge ;
	$cw->{'match'} = sub { shift =~ /^${regex}$/ } ;
    }
    return $$var;
}

sub directory
{
    my ($cw,$val) = @_;
    $cw->idletasks if $cw->{'reread'};
    my $var = \$cw->{Configure}{'-directory'};
    my $dir = $$var;
    if (@_ > 1 && defined $val) {
	unless ($cw->{'reread'}++) {
	    $cw->Busy;
	    $cw->DoWhenIdle(['reread',$cw,$val]);
	}
    }
    return $$var;
}

sub reread
{
    my ($w,$dir) = @_;
    my $pwd    = Cwd::getcwd();
    if (chdir($dir)) {
	my $new = Cwd::getcwd();
	if ($new) {
	    $dir = $new;
	} else {
	    carp "Cannot getcwd in '$dir'" unless ($new);
	}
	chdir($pwd) || carp "Cannot chdir($pwd) : $!";
	if (opendir(DIR, $dir))	{
	    $w->subwidget('dir_list')->delete(0, "end");
	    $w->subwidget('file_list')->delete(0, "end");
	    my $accept = $w->cget('-accept');
	    my $f;
	    foreach $f (sort(readdir(DIR))) {
		next if ($f eq '.');
		my $path = "$dir/$f";
		if (-d $path) {
		    $w->subwidget('dir_list')->insert('end', $f);
		} else {
		    if (&{$w->{match}}($f)) {
			if (!defined($accept) || $accept->Call($path)) {
			    $w->subwidget('file_list')->insert('end', $f) ;
			}
		    }
		}
	    }
	    closedir(DIR);
	    $w->{Configure}{'-directory'} = $dir;
	    $w->Unbusy;
	    $w->{'reread'} = 0;
	    $w->{Directory} = $dir . "/" . $w->cget('-filter');
	} else {
	    my $panic = $w->{Configure}{'-directory'};
	    $w->Unbusy;
	    $w->{'reread'} = 0;
	    chdir($panic) || croak "Cannot chdir($panic) : $!";
	    croak "Cannot opendir('$dir') :$!";
	}
    } else {
	$w->Unbusy;
	$w->{'reread'} = 0;
	croak "Cannot chdir($dir) :$!";
    }
}

sub validate
{
    my ($cw,$name) = @_;
    my $i = 0;
    my $n = $cw->index('end');
    for ($i= 0; $i < $n; $i++) {
	my $f = $cw->get($i);
	if ($f eq $name) {
	    $cw->selection('set',$i);
	    return;
	}
    }
}


sub show
{
    my ($cw,@args) = @_;
    $cw->Popup(@args);
    $cw->tkwait('visibility', $cw);
    $cw->focus;
    $cw->tkwait(variable => \$cw->{Selected});
    $cw->withdraw;
    return (wantarray) ? @{$cw->{Selected}} : $cw->{Selected}[0];
}

1;


---------------------------------------------------------------------------
