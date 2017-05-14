#
# $Id: SelFile.pm,v 1.4 1995/11/18 00:16:47 scheinin Exp $
#

package Tk::SelFile;

use Tk qw(Ev);
use Carp;
use English;
#togo#use strict 'vars';
use strict;
require Tk::Dialog;
require Tk::Toplevel;
require Tk::LabEntry;
require Tk::ScrlListbox;
require Cwd;
@Tk::SelFile::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('SelFile');

=head1 NAME

 SelFile - a widget for choosing a file to read or write

=head1 SYNOPSIS

 use Tk;
 use Tk::SelFile;

 $mw = MainWindow->new;  # As an example.

 $start_dir = ".";       # As an example.
 $sfw = $mw->SelFile(
		     -directory => $start_dir,
		     -width     =>  30,
		     -height    =>  20,
		     -filelistlabel  => 'Files',
		     -filter         => '*',
		     -filelabel      => 'File',
		     -dirlistlabel   => 'Directories',
		     -dirlabel       => 'Filter',
 		     -readbutlabel   => 'Read',
 		     -writebutlabel  => 'Write',
 		     -cancelbutlabel => 'Cancel',
		     );
 Please see the Populate subroutine as the configuration
 list may change.

 ($opcode, $filename) = $sfw->Show;

 $opcode will have the value -readbutlabel (e.g. 'READ'),
 -writebutlabel (e.g. 'WRITE') or -cancelbutlabel (e.g. 'CANCEL').
 An empty string for the text assigned to -readbutlabel or
 -writebutlabel will eliminate that particular button.
 $filename will be a file pathname, or in the case of CANCEL
 it will be a single space character.

 $SFref = $sfw->configure(option => value[, ...])

=head1 DESCRIPTION

   This Module pops up a file selector box, with a directory entry
   with filter on top, a list of directories in the current directory,
   a list of files in the current directory, an entry for entering
   or modifying a file name, a read button, a write button, a
   cancel button, a HOME button, and a button to return to the
   starting directory (-directory).

   The button to return to the starting directory is motivated by
   the idea that an application may have a directory unrelated to
   the home directory, e.g. a library of data, that is set to be
   the starting directory.  If the user goes to the home directory,
   the user may not recall the starting directory that was set by
   the application.

   A call to SelFile few (or no options, such as shown below)
   will result in the default values shown in the example
   given in the SYNOPSIS section.  The most uptodate list of
   configuration variables and default values can be found in the
   subroutine Populate as arguments to the subroutine ConfigSpecs.

   $sfw = $mw->SelFile;

   A dialog box error message is generated if the user clicks the
   Read button for a file that does not exist.
   For Write, a dialog box that requests whether the user wishes
   to overwrite the file is generated for a file that already exists.
   Also for Write, a dialog box error message is generated is the
   file name is blank.

   This widget can be configured for requesting a file name to read,
   requesting a file name for writing, or for requesting either.
   For the initial call to SelFile that configures the widget,
   if -readbutlabel is not a member of the argument list, then
   the default value is used (i.e. Read).  If on the other hand
   it is present but specifies an empty string, as shown below
   -readbutlabel   => '',
   then the button is not created.  An analogous rule applies
   to the argument -writebutlabel.

   The file name output is a single space character rather than undef
   when CANCEL is selected so that the user can process the return values
   without checking the values, e.g. storing the result for later use.


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

Alan Scheinine wants to thank David Greaves (davidg@oak.reading.sgi.com)
for pointing out errors and for suggesting improvements.  He also wants
to thank Nick Ing-Simmons (nik@tiuk.ti.com) for sending the soon-to-be
FileSelect for Tk-b9.  This SelFile program diverges from SelectFile
with regard to style but nonetheless has benefited from the ideas and
actual code of SelectFile.

Future history.  For Tk-b9, "show" and "subwidget" should become
"Show" and "Subwidget"
Change $cw->subwidget('dialog')->show;  Tk-b8
to     $cw->Subwidget('dialog')->Show;  Tk-b9

=cut


sub Cancel
{
    my ($cw,$textout) = @_;
    $cw->{Selected} = [$$textout,' '];
}

sub ReadFile
{
    my ($cw,$textout) = @_;
    my $dir  = $cw->cget('-directory');
    my $pathname = $cw->{'Pathname'};
    if( !( -e $pathname ) ){
       dialog_nonexist($cw,$pathname);
    }
    else {
       $cw->{Selected} = [$$textout,$pathname];
    }
}
sub WriteFile
{
    my ($cw,$textout) = @_;
    my $dir  = $cw->cget('-directory');
    my $pathname = $cw->{'Pathname'};
    if( $pathname =~ m/^\s*$/ ){
       dialog_noname($cw);
       return;
    }
    if( -e $pathname ){
       my $yes = dialog_overwrite($cw,$pathname);
       if($yes == 1){
	  $cw->{Selected} = [$$textout,$pathname];
       }
    }
    else {
       $cw->{Selected} = [$$textout,$pathname];
    }
}

sub dialog_nonexist {
   my($cw,$pathname) = @_;
   my $width = length($pathname)*14;
   if($width < 400){ $width = 400; }
   my $my_text_color = 'blue';
   $cw->subwidget('dialog_error')->configure(
       -title         => 'File Does Not Exist',
       -text          => "$pathname  \n does not exist",
       -wraplength => $width,
       -foreground => $my_text_color,
   );
   $cw->subwidget('dialog_error')->show;
}

sub dialog_noname {
   my($cw) = @_;
   my $width = 400;
   my $my_text_color = 'blue';
   $cw->subwidget('dialog_error')->configure(
       -title         => 'No File Name',
       -text          => "   No file name specified.      ",
       -wraplength => $width,
       -foreground => $my_text_color,
   );
   $cw->subwidget('dialog_error')->show;
}

sub dialog_overwrite {
   my($cw,$pathname) = @_;
   my($yes, $can) = ($cw->{'overwrite_yes'},$cw->{'overwrite_cancel'});
   my $my_text_color = 'LawnGreen';
   my $width = length($pathname)*14;
   if($width < 400){ $width = 400; }
   $cw->subwidget('dialog_noyes')->configure(
       -title         => 'File Already Exists',
       -text          => 'Overwrite file?' . "\n$pathname  \n",
       -wraplength => $width,
       -foreground => $my_text_color,
   );
   my $button = $cw->subwidget('dialog_noyes')->show;
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
#  Remove whitespace characters.
   $dir =~ s/\s//g;
#  If all that is left is nothing, set as current directory.
   if( $dir eq "" ) {
      $dir = '.';
   }
#  If there is no slash and the name (perhaps a filter) is not
#  a directory, then set as current directory.
   if( !($dir =~ m|/|) ) {
      if( !(-d $dir) ){
	 $dir = './' . $dir;
      }      
   }
#  If pathname does not end in slash but is a directory,
#  then add a slash.
   if( !( $dir =~ m|^.*/$| ) ){
      if( -e $dir ){
	 if( -d $dir ){
	    $dir = $dir . '/';
	 }
      }
   }
#  If name is a directory, add asterisk wildcard.
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
    if( !defined($name) ){ return; }
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
    my $default_dir = '.';

    # Create filter (or directory) entry, place at the top

    my $e = $w->Component(LabEntry => 'dir_entry',
			  -textvariable => \$w->{Directory},
			  -labelvariable => \$w->{Configure}{-dirlabel},
                          -font          =>
			  '-*-Fixed-Bold-R-*-*-15-*-*-*-*-*-*',
			  );
    $e->pack(-side => 'top', -expand => 0, -fill => 'x',
	     -padx => 4, -pady => 4,
	     );


    $e->bind('<Return>' => [ $w => 'set_filter', Ev(['get']) ]);

    # Create file entry, place at the bottom

    $e = $w->Component(LabEntry => 'file_entry',
		       -textvariable => \$w->{'Pathname'},
		       -labelvariable => \$w->{Configure}{-filelabel},
		       -font          =>
		       '-*-Fixed-Bold-R-*-*-15-*-*-*-*-*-*',
		       );
    $e->pack(-side => 'bottom', -expand => 0, -fill => 'x',
	     -padx => 4, -pady => 4,
	     );

    # Create directory scrollbox, place at the left-middle

    my $b = $w->Component(ScrlListbox => 'dir_list', 
			  -labelvariable => \$w->{Configure}{-dirlistlabel},
			  -scrollbars => 'se',
			  );
    $b->pack(-side => 'left', -expand => 1, -fill => 'both',
	     -padx => 10, -pady => 10,
	     );
    $b->bind('<Button-1>' => [ $w => 'accept_dir', Ev(['Getselected']) ]);

    my $f = $w->Frame();
    $f->pack(-side => 'right',
	     -expand => 'y',
	     );
    my $read_text = \$w->{Configure}{-readbutlabel};
    my $write_text = \$w->{Configure}{-writebutlabel};
    my $cancel_text = \$w->{Configure}{-cancelbutlabel};
    if(!defined($args->{'-readbutlabel'}) ||
       length($args->{'-readbutlabel'}) > 0){
       $b = $f->Component(Button => 'read_button',
			  -textvariable => $read_text,
			  -command => [ 'ReadFile', $w, $read_text ]);
       $b->pack(-side => 'top',
		-padx => 2, -pady => 10,
		);
    }
    if(!defined($args->{'-writebutlabel'}) ||
       length($args->{'-writebutlabel'}) > 0){
       $b = $f->Component(Button => 'write_button',
			  -textvariable => $write_text,
			  -command => [ 'WriteFile', $w, $write_text ]);
       $b->pack(-side => 'top',
		-padx => 2, -pady => 10,
		);
    }

    # If start directory is not HOME,
    # make button to return to start directory.
    my $dir_init;
    my $dir_home = $ENV{'HOME'};
    my $new;
    if( defined($args->{'-directory'}) ){
       $dir_init = $args->{'-directory'};
    }
    else {
       $dir_init = $default_dir;
    }
    my $pwd = Cwd::getcwd();
    if (chdir($dir_init)) {
       $new = Cwd::getcwd();
       if ($new) {
	  $dir_init = $new;
       } else {
	  carp "Cannot getcwd in '$dir_init'" unless ($new);
       }
       chdir($pwd) || carp "Cannot chdir($pwd) : $!";
    }
    else {
       croak "Cannot chdir($dir_init) :$!";
    }
    # Because of NFS, ENV{'HOME'} might be different from output
    # of getcwd().  Find home directory name in getcwd() language.
    if (chdir($dir_home)) {
       my $new = Cwd::getcwd();
       if ($new) {
	  $dir_home = $new;
       } else {
	  carp "Cannot getcwd in '$dir_home'" unless ($new);
       }
       chdir($pwd) || carp "Cannot chdir($pwd) : $!";
    }
    else {
       croak "Cannot chdir($dir_home) :$!";
    }
    if($dir_init ne $dir_home){
       my $name_max = 32;
       my $slash_max = 2;
       my $partial = ' ';
       my $slash_count = 0;
       my $salami = $dir_init;
       my $letter;
       while ($name_max > 0 &&
	      length($salami) > 0 &&
	      $slash_count < $slash_max){
	  $letter = chop($salami);
	  if($letter eq "/"){ $slash_count++; }
	  $partial = $letter . $partial;
	  $name_max--;
       }
       $b = $f->Component(Button => 'initdir_button',
			  '-text' => "return to\n...$partial",
			  '-font' =>
		'-*-helvetica-medium-r-*-*-12-*-*-*-*-*-*',
			  -command =>
		          [$w => 'configure','-directory',$dir_init],
			  );
       $b->pack(-side => 'top',
		-padx => 2, -pady => 2,
		);
    }

    $b = $f->Component(Button => 'home_button',
		       '-text' => 'HOME',
		       -command =>
		          [$w => 'configure','-directory',$ENV{'HOME'}],
		       );
    $b->pack(-side => 'top',
	     -padx => 2, -pady => 10,
	     );
    $b = $f->Component(Button => 'cancel_button',
		       -textvariable => $cancel_text,
		       -command => [ 'Cancel', $w, $cancel_text ]);
    $b->pack(-side => 'top',
	     -padx => 2, -pady => 10,
	     );

    # Create File Scrollbox, Place at the right-middle

    $b = $w->Component(ScrlListbox => 'file_list', 
		       -scrollbars => 'se',
		       -labelvariable => \$w->{Configure}{-filelistlabel} );
    $b->pack(-side => 'right', -expand => 1, -fill => 'both',
	     -padx => 10, -pady => 10,
	     );
    $b->bind('<Button-1>' => [$w => 'accept_name', Ev(['Getselected']) ] );

    my $bg_color;

    # Error dialog box.
    $bg_color = 'orange';
    my $v = $w->Component(Dialog => 'dialog_error',
			  -background => $bg_color,
			  -justify    => 'center',	    
			  -font       =>
			  '-*-Helvetica-Bold-R-Normal--*-160-*-*-*-*-*-*',
			  -buttons    => ['OK'],
			  -default_button => 'OK',
			  );

    # Overwrite dialog box.
    $w->{'overwrite_yes'} = 'Yes';
    $w->{'overwrite_cancel'} = 'Cancel';
    $bg_color = 'violet';
    my($yes, $can) = ('Yes', 'Cancel');
    my $v = $w->Component(Dialog => 'dialog_noyes',
			  -background => $bg_color,
			  -justify    => 'center',	    
			  -font       =>
			  '-*-Helvetica-Bold-R-Normal--*-160-*-*-*-*-*-*',
			  -buttons        => [$yes,$can],
			  -default_button => $can,
			  );

    $w->ConfigSpecs(-width          => [ ['file_list','dir_list'],
					undef, undef, 30 ],
		    -height         => [ ['file_list','dir_list'],
					undef, undef, 20 ],
		    -directory      =>
		       [ 'METHOD', undef, undef, $default_dir ],
		    -filelistlabel  => [ 'PASSIVE', undef, undef, 'Files' ],
		    -filter         => [ 'METHOD', undef, undef, '*' ],
		    -regexp         => [ 'PASSIVE', undef, undef, undef ],
		    -filelabel      => [ 'PASSIVE', undef, undef, 'File' ],
		    -dirlistlabel   =>
		       [ 'PASSIVE', undef, undef, 'Directories'],
 		    -dirlabel       => [ 'PASSIVE', undef, undef, 'Filter'],
 		    -readbutlabel   => [ 'PASSIVE', undef, undef, 'Read'],
 		    -writebutlabel  => [ 'PASSIVE', undef, undef, 'Write'],
 		    -cancelbutlabel => [ 'PASSIVE', undef, undef, 'Cancel'],
		    '-accept'       => ['CALLBACK',undef,undef, undef ],
		    DEFAULT         => [ 'file_list' ],
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

sub Show
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
