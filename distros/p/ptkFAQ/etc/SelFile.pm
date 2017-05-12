
package SelFile;
use Tk qw(Ev);
use Carp;
use English;
use strict 'vars';
require Tk::Toplevel;
require Tk::LabEntry;
require Tk::ScrlListbox;
require Tk::Dialog;
require Cwd;
@SelFile::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('SelFile','Select File');


=head1 NAME

 SelFile - a widget for choosing a file to read or write

=head1 SYNOPSIS

 require 5.001;
 use Tk;
 use SelFile;

 $mw = MainWindow->new;  # For example.

 $start_dir = ".";
 $sfw = $mw->SelFile(
		     -directory => $start_dir,
		     -width     =>  30,
		     -height    =>  20,
		     -filelistlabel  => 'Files',
		     -filter         => '*',
		     -filelabel      => 'File',
		     -dirlistlabel   => 'Directories',
		     -dirlabel       => 'Filter',
		     );

 A call with fewer (or no options) such as shown below
 will result in the default values shown above.
 $sfw = $mw->SelFile;

 In a callback bound to an event the user can invoke the widget
 to request a file selection with the following line.
 ($opcode, $filename) = $sfw->show;

 $opcode will have the value 'READ', 'WRITE' or 'CANCEL'.
 $filename will be a file pathname, or in the case of CANCEL
 it will be a single space character.

=head1 DESCRIPTION

   This Module pops up a Fileselector box, with a directory entry
   with filter on top, a list of directories in the current directory,
   a list of files in the current directory, an entry for entering
   or modifying a file name, a read button, a write button, and a
   cancel button.

   If your system administrator does not have time to install
   this package, you could put it into a directory such as
   $HOME/Myperl (with the name SelFile.pm) and at the top of
   any Perl script have the following

 BEGIN {
    @INC = ("$ENV{'HOME'}/Myperl", @INC);
 }

=head1 AUTHORS

Based on original FileSelect by
Klaus Lichtenwalder, Lichtenwalder@ACM.org, Datapat GmbH, 
Munich, April 22, 1995
adapted by
Frederick L. Wagner, derf@ti.com, Texas Instruments Incorporated, 
Dallas, 21Jun95
further adapted by
Alan Louis Scheinine, scheinin@crs4.it,
Centro di Ricerca, Sviluppo e Studi Superiori in Sardegna (CRS4)
Cagliari, 14 November 1995

=head1 HISTORY

=cut

sub Cancel
{
    my ($cw) = @_;
    $cw->{Selected} = ['Cancel',' '];
}

sub ReadFile
{
    my ($cw) = @_;
    my $dir  = $cw->cget('-directory');
    my $pathname = $cw->{Pathname};
    if( !( -e $pathname ) ){
       dialog_nonexist($cw,$pathname);
    }
    else {
       $cw->{Selected} = ['Read',$pathname];
    }
}

sub WriteFile
{
    my ($cw) = @_;
    my $dir  = $cw->cget('-directory');
    my $pathname = $cw->{Pathname};
    if( -e $pathname ){
       my $yes = dialog_overwrite($cw,$pathname);
       if($yes == 1){
	  $cw->{Selected} = ['Write',$pathname];
       }
    }
    else {
       $cw->{Selected} = ['Write',$pathname];
    }
}

sub dialog_nonexist {
   my($cw,$pathname) = @_;
   my $ok = 'OK';
   my $my_color = 'orange';
   my $my_text_color = 'cyan';
   my $DialogNonexist = $cw->Dialog(
       -title         => 'File Does Not Exist',
       -font          =>
          '-*-Helvetica-Bold-R-Normal--*-160-*-*-*-*-*-*',
       -text          => "$pathname  \n does not exist",
       -justify => 'center',	    
       -default_button => $ok,
       -buttons        => [$ok],
   );
   $DialogNonexist->configure(-background => $my_color);
   $DialogNonexist->configure(-foreground => $my_text_color);
   $DialogNonexist->iconname('Nonexist');
   my $width = length($pathname)*14;
   if($width < 200){ $width = 200; }
   $DialogNonexist->configure(-wraplength => $width);
   my $button = $DialogNonexist->show;
}

sub dialog_overwrite {
   my($cw,$pathname) = @_;
   my($yes, $can) = ('Yes', 'Cancel');
   my $my_color = 'orange';
   my $my_text_color = 'cyan';
   my $DialogOverwrite = $cw->Dialog(
       -title         => 'File Already Exists',
       -font          =>
          '-*-Helvetica-Bold-R-Normal--*-160-*-*-*-*-*-*',
       -text          => 'Overwrite file?' . "\n$pathname  \n",
       -justify => 'center',	    
       -default_button => $can,
       -buttons        => [$yes,$can],
   );
   $DialogOverwrite->configure(-background => $my_color);
   $DialogOverwrite->configure(-foreground => $my_text_color);
   $DialogOverwrite->iconname('Overwrite');
   my $width = length($pathname)*14;
   if($width < 200){ $width = 200; }
   $DialogOverwrite->configure(-wraplength => $width);
   my $button = $DialogOverwrite->show;
   if($button eq $yes){
      return 1;
   }
   else { return 0; }
}

sub accept_dir
{
    my ($cw,$new) = @_;
    my $dir = $cw->cget('-directory');
    my $filter_ref = $cw->subwidget('dir_entry')->cget('-textvariable');
    my $filter_path = $$filter_ref;
    if($new eq $cw->{'rescan_text'}){
       $new = ".";
    }
    elsif($new eq $cw->{'up_text'}){
       $new = "..";
    }
    set_filter($cw, $filter_path);
    $cw->configure(-directory => "$dir/$new");
}

sub set_filter
{
   my ($cw,$dir) = @_;
   if( !( $dir =~ m|^.*/$| ) ){
      if( -e $dir ){
	 if( -d $dir ){
	    $dir = $dir . '/';
	 }
      }
   }
   if( -d $dir ){
      $dir = $dir . '*';
   }
   my $filter = $dir;
   $dir =~ s/^(.*)\/[^\/]*$/$1/;
   $cw->configure(-directory => $dir);
   $filter =~ s/^.*\/([^\/]*)$/$1/;
   $cw->configure(-filter => $filter);
}

sub accept_name
{
    my ($cw,$name) = @_;
    my $dir  = $cw->cget('-directory');
    my $pathname = $dir . '/' . $name;
    $cw->{'Pathname'} = $pathname;
    $cw->subwidget('file_entry')->delete(0, 'end');
    $cw->subwidget('file_entry')->insert(0, $pathname);
}

sub Populate
{
    my ($w, $args) = @_;

    $w->InheritThis($args);
    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);

    $w->{'reread'} = 0;
    $w->withdraw;
    $w->{'Pathname'} = "";
    $w->{'rescan_text'} = ".  (rescan current)";
    $w->{'up_text'} = "..  (up)";

    #
    # Create Filter (or Directory) Entry, Place at the top
    #
    my $e = $w->Component(LabEntry => 'dir_entry',
			  -textvariable => \$w->{Directory},
			  -labelvariable => \$w->{Configure}{-dirlabel},
                          -font          =>
			  '-*-helvetica-medium-r-normal-*-14-*-*-*-*-*-*',
			  );
    $e->pack( -side => 'top',
	     -expand => 0,
	     -fill => 'x', );


    $e->bind('<Return>' => [ $w, 'set_filter', Ev(['get']) ]);

    #
    # Create File Entry, Place at the bottom
    #
    $e = $w->Component(LabEntry => 'file_entry',
		       -textvariable => \$w->{Pathname},
		       -labelvariable => \$w->{Configure}{-filelabel},
		       -font          =>
		       '-*-helvetica-medium-r-normal-*-14-*-*-*-*-*-*',
		       );
    $e->pack( -side => 'bottom', -expand => 0, -fill => 'x');

    # Create Directory Scrollbox, Place at the left-middle

    my $b = $w->Component(ScrlListbox => 'dir_list', 
			  -scrollbars => 'se',
			  -labelvariable => \$w->{Configure}{-dirlistlabel});
    $b->pack(-side => 'left', 
	     -expand => 1, 
	     -fill => 'both');
    $b->bind('<Button-1>' => [ $w, 'accept_dir', Ev(['Getselected']) ]);

    # Add a Label

    #   my $l = $b->Component(Label => 'label',
    # 			     -textvariable => \$w->{Configure}{-dirlistlabel});
    #   $l->pack(-fill => 'x',
    # 	         -side => 'top',
    # 	         -before => ($b->packslaves)[0]);

    my $f = $w->Frame();
    $f->pack(-side => 'right',
	     -fill => 'y');
    $b = $f->Button('-text' => 'Read',
		    -command => [ 'ReadFile', $w ]);
    $b->pack(-side => 'top',
	     -expand => 1);
    $b = $f->Button('-text' => 'Write',
		    -command => [ 'WriteFile', $w ]);
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
    $b->bind('<Button-1>' => [$w ,'accept_name', Ev(['Getselected']) ] );

    # Add a Label

    #   my $l = $b->Component(Label => 'label',
    # 			-textvariable => );
    #   $l->pack(-fill => 'x',
    # 	   -side => 'top',
    # 	   -before => ($b->packslaves)[0]);

    $w->ConfigSpecs(-width          => [ ['file_list','dir_list'],
					undef, undef, 30 ],
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
		    -dirlabel       => [ PASSIVE, undef, undef, 'Filter'],
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
	    my $dir_text;
	    foreach $f (sort(readdir(DIR))) {
		my $path = "$dir/$f";
		if (-d $path) {
		   if($f eq "."){
		      $dir_text = $w->{'rescan_text'};
		   }
		   elsif($f eq ".."){
		      $dir_text = $w->{'up_text'};
		   }
		   else {
		      $dir_text = $f;
		   }
		   $w->subwidget('dir_list')->insert('end', $dir_text);
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
