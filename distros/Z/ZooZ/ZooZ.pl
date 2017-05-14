#!perl -w

use strict;
use Data::Dumper qw/Dumper/;
use Getopt::Long;

use Tk 804.025;
use Tk qw/:colors/;
use Tk::NoteBook;
use Tk::Adjuster;
use Tk::ToolBar;
use Tk::Tree;
use Tk::Compound;
use Tk::ItemStyle;
use Tk::Pane;
use Tk::Labelframe;
use Tk::DialogBox;
use Tk::PNG;

use constant DEBUG                => 0;
use constant NOTEBOOK_SUPPORT     => 0;
use constant DUMP_PM_SUPPORT      => 1;
use constant MENU_BUILDER_SUPPORT => 0;

use ZooZ::Forms;
use ZooZ::Project;
use ZooZ::Options;
use ZooZ::Generic;

#
# If we are using an older ToolBar, patch it up.
#
BEGIN {
  if ($Tk::ToolBar::VERSION <= 0.09) {

    package Tk::ToolBar;

    sub ToolBrowseEntry {
      my $self = shift;
      my %args = @_;

      my $m = delete $args{-tip} || '';
      my $l = $self->{CONTAINER}->BrowseEntry(%args);

      push @{$self->{WIDGETS}} => $l;

      $self->_packWidget($l);
      $self->{BALLOON}->attach($b, -balloonmsg => $m) if $m;

      return $l;
    }

    sub BrowseEntry { goto &ToolBrowseEntry }

  }
}

#
# Global vars
#

our (
     $MW,
     $VERSION,

     $SPLASH,
     $SPLASH_MSG,
     $SPLASH_PROG,
     $NO_SPLASH,
     $COPYRIGHT,

     # MainWindow frames
     $FRAME_L,
     $FRAME_M,

     # toolbar
     $TB,

     # menu
     $MENU,
     $PROJ_MENU,
     $PROJ_BE,
     $PROJ_BE_VAR,

     # Settings Tab and Hash
     $SETTINGS_F,
     %SETTINGS,
     %DEF_SETTINGS,

     # Widget frame
     $WIDGET_F,

     # Project data
     $PROJID,
     $CURID,
     @PROJECTS, # holds the objects.
     @PAGES,
     @NAMES,

     # icons
     %ICONS,
     $SELECTED_W, # selected widget
     $SELECTED_L, # dummy label

     # Extra ZooZ:: objects
     $FONTOBJ,
     $CALLBACKOBJ,
     $VARREFOBJ,

     # Global hash of all widgets.
     # This can be used by users in callbacks.
     %ZWIDGETS,

     # Options for getOpen/SaveFile
     @FILE_OPTIONS,

     # What files correspond to what projects
     @PROJECT_FILES,
     @PERL_FILES,
     @OPEN_PROJECTS,
     @PM_FILES,

     # Warnings
     $WARN_DIALOG,
     $WARNINGS_ON,

     # Perl lib path
     $PERLLIB,
    );


#
# temp vars
#
our %availableWidgets = (
			 butLab   => [qw/Label Image Button Radiobutton Checkbutton/],
			 text     => [qw/Entry Text ROText/],
			 menuList => [qw/Listbox Optionmenu/],
			 datadisp => [qw/Canvas Scale ProgressBar HList/],
#			 dialog   => [qw/Dialogbox Toplevel/],
			 misc     => [qw/Labelframe Frame/],
			 parasite => [qw/Scrollbar/],
			);

push @{$availableWidgets{datadisp}} => 'NoteBook' if NOTEBOOK_SUPPORT;

#
# Inits
#
$VERSION      = '1.2';
$PROJID       = 0;
$NO_SPLASH    = DEBUG? 1 : 0;
$WARNINGS_ON  = 1;
%DEF_SETTINGS = (
		 -borderwidth => 1,
		);
%SETTINGS     = %DEF_SETTINGS;
@FILE_OPTIONS = (
		 -defaultextension => '.zooz',
		 -initialdir       => '.',
		 -filetypes        =>
		 [
		  ['ZooZ Files', '.zooz'],
		  ['All Files',  '*'    ],
		 ],
		);
$COPYRIGHT     = 'Copyright 2004-2005 - Ala Qumsieh. All rights reserved.';

# Control Data::Dumper
$Data::Dumper::Indent = 0;

# First, check if ZooZ is installed.
die "Cannot find ZooZ libraries. Make sure ZooZ is properly installed on your system.\n"
  unless $PERLLIB = findDir('ZooZ/Project.pm');

#
# Read any command line args
#
GetOptions(
	   nosplash => \$NO_SPLASH,
	  );

#
# create stuff
#

createMW          (); updateSplash('Initializing GUI');
defineFonts       (); updateSplash();
createGUI         (); updateSplash();
createMenu        (); updateSplash();
loadIcons         (); updateSplash();
createToolBar     (); updateSplash('Loading Images');
#defineSettings    ();
loadBitmaps       (); updateSplash('Defining GUI Elements');
defineWidgets     (); updateSplash();
defineStyles      (); updateSplash('Initializing Modules');
createExtraObjects(); updateSplash();
createHandlers    (); updateSplash();
ZooZ::Forms::createAllForms($MW);

$SPLASH->withdraw;
$MW->deiconify;

ZooZ::Generic::popMessage(-over => $MW,
			  -msg  => "Welcome to ZooZv$VERSION",
			  -bg   => 'white',
			  -font => 'Level',
			 );

$MW->optionAdd('*preview*BorderWidth' => 2);

loadProject($_) for @ARGV;

MainLoop;

sub updateSplash {
  return if $NO_SPLASH;

  $SPLASH_PROG++;
  $SPLASH_MSG = shift if @_;
  $SPLASH->update;
  $MW->after(200);
}

sub createMW {
  $MW = new MainWindow;
  $MW->withdraw;
  $MW->title("ZooZ v$VERSION");
  $MW->geometry("800x600+0+0");
  $MW->protocol(WM_DELETE_WINDOW => \&closeApp);

  { # Create the splash window
    $SPLASH = $MW->Toplevel;
    $SPLASH->withdraw;
    $SPLASH->overrideredirect(1);
    my $f = $SPLASH->Frame(-bd     => 2,
			   -relief => 'ridge',
			  )->pack(qw/-fill both -expand 1/);

    #my $logo  = $SPLASH->Photo(-file => "$PERLLIB/ZooZ/icons/zooz_logo.gif");
    my $logo2 = $SPLASH->Photo(-file => "$PERLLIB/ZooZ/icons/screenshot4logo.gif");

    #$f->Label(-image => $logo)->pack(qw/-side top/);
    $f->Label(-image => $logo2)->pack(qw/-side top/);
    $f->ProgressBar(-from     => 0,
		    -to       => 11,
		    -variable => \$SPLASH_PROG,
		    -width    => 20,
		    -colors   => [0 => 'lightblue'],
		   )->pack(qw/-side top -fill x -pady 10 -padx 10/);

    $f->Label(-textvariable => \$SPLASH_MSG,
	      -font => 'Times 10 normal',
	     )->pack(qw/-fill x -side top/);

    $f->Label(-text => $COPYRIGHT,
	      -font => 'Times 10 normal',
	     )->pack(qw/-fill x -side top/);

    $SPLASH_PROG = 0;

    # Now center it.
    $SPLASH->update;
    my $sw = $SPLASH->screenwidth;
    my $sh = $SPLASH->screenheight;
    my $rw = $SPLASH->reqwidth;
    my $rh = $SPLASH->reqheight;

    my $x  = int 0.5 * ($sw - $rw);
    my $y  = int 0.5 * ($sh - $rh);

    $SPLASH->geometry("+$x+$y");
    $SPLASH->deiconify unless $NO_SPLASH;
  }
}

sub createGUI {
  # Top, left and main frames.
  $FRAME_L = $MW->Frame->pack(qw/-side left -fill y/);
  $FRAME_M = $MW->Frame->pack(qw/-side left -fill both -expand 1/);

  # frame to display selectable widgets.
  $WIDGET_F = $FRAME_L->Labelframe(
				   -text => 'Available Widgets',
				  )->pack(qw/-side top -fill both -expand 1/);

  # Dummy label to drag around.
  $SELECTED_L = $MW->Label(-textvariable => \$SELECTED_W,
			   -bg           => 'cornflowerblue',
			   -relief       => 'raised',
			   -borderwidth  => 1,
			  );

  # pressing Delete deletes selected widget.
  $MW->bind('<Delete>' => sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->deleteSelectedWidget });

  # create bindings for the menu.
  $MW->bind('<Control-n>' => \&newProject);
  $MW->bind('<Control-o>' => \&loadProject);
  $MW->bind('<Control-s>' => \&saveProject);
  $MW->bind('<Control-d>' => \&dumpPerl);
  $MW->bind('<Control-q>' => \&closeApp);
  $MW->bind('<Control-w>' => \&closeProject);
}

sub createMenu {
  $MENU = $MW->Menu(-type => 'menubar', -bd => 1);
  $MW->configure(-menu => $MENU);

  $MENU->optionAdd('*menu*BorderWidth' => 1);

  { # The File menu.
    my $f = $MENU->cascade(-label => '~File', -tearoff => 0);
    for my $ref (
		 ['New Project',        \&newProject,   'Ctrl-n'],
		 'sep',
		 ['Load Project',       \&loadProject,  'Ctrl-o'],
		 ['Save Project',       \&saveProject,  'Ctrl-s'],
		 ['Save Project As',    \&saveProjectAs         ],
		 ['Close Project',      \&closeProject, 'Ctrl-w'],
		 'sep',
		 ['Write Perl File',    \&dumpPerl,     'Ctrl-d'],
		 ['Write Perl File As', \&dumpPerlAs            ],
		 ['Write PM File',      \&dumpPerlPM            ],
		 ['Write PM File As',   \&dumpPerlPMAs          ],
		 'sep',
		 ['Quit',               \&closeApp,     'Ctrl-q'],
		) {

      if (ref $ref) {
	$f->command(-label => $ref->[0], -command => $ref->[1],
		    @$ref == 3 ? (-accelerator => $ref->[2]) : (),
		   );
      } else {
	$f->separator;
      }
    }

  }

  {
    # The edit menu.
    my $f = $MENU->cascade(-label => '~Edit', -tearoff => 0);
    for my $ref (
		 ['Delete Selected Widget', sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->deleteSelectedWidget }],
		 'sep',
		 ['Toggle Preview Window',  sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->togglePreview }],
		 'sep',
		 ['Properties', sub {}],
		) {

      if (ref $ref) {
	$f->command(-label => $ref->[0], -command => $ref->[1]);
      } else {
	$f->separator;
      }
    }
  }

  { # the configure menu.
    my $f = $MENU->cascade(-label => '~Configure', -tearoff => 0);
    for my $ref (
		 ['Configure Selected Widget', sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->configureSelectedWidget }],
		 'sep',
		 ['Configure Selected Row',    sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->_configureRowCol('row', 'selected') }],
		 ['Configure Selected Column', sub { $OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->_configureRowCol('col', 'selected') }],
		) {

      if (ref $ref) {
	$f->command(-label => $ref->[0], -command => $ref->[1]);
      } else {
	$f->separator;
      }
    }
  }

  { # The data menu.
    my $f = $MENU->cascade(-label => '~Data', -tearoff => 0);
    for my $ref (
		 ['Variable Definitions', [\&ZooZ::Forms::chooseVar,      '']],
		 ['Callback Definitions', [\&ZooZ::Forms::chooseCallback, '']],
		 ['Font Definitions',     [\&ZooZ::Forms::chooseFont,     '']],
		) {

      if (ref $ref) {
	$f->command(-label => $ref->[0], -command => $ref->[1]);
      } else {
	$f->separator;
      }
    }
  }

  # The project menu
#  $PROJ_MENU = $MENU->cascade(-label   => '~Projects',
#			      -tearoff => 0,
#			     );
  $PROJ_MENU = $MW->Menu(-tearoff     => 0);
  $MENU->add(cascade =>
	     -label  => 'Projects',
	     -underline => 0,
	     -menu   => $PROJ_MENU);

  # What? no help?
}

sub defineSettings {
  # this sub populates the Setting tab.

  my $f = $SETTINGS_F->Scrolled('Pane',
				-sticky     => 'nsew',
				-scrollbars => 'e',
				-gridded    => 'xy',
			       )->pack(qw/-fill both -expand 1/);

  # populate the 'Defaults' frame
  {
    my $defFrame = $f->Labelframe(-text => 'Defaults')->pack(qw/-side top -fill x/);
    $defFrame->optionAdd('*Entry.BorderWidth'  => 1);
    $defFrame->optionAdd('*Button.BorderWidth' => 1);

    my $row = 0;
    my $col = 0;
    for my $ref (
		 [-borderwidth => 'Border Width'],
		 [-background  => 'Background Color'],
		 [-font        => 'Font'],
		 [-foreground  => 'Foreground Color'],
		) {

      ZooZ::Options->addOptionGrid($ref->[0],
				   $ref->[1],
				   $defFrame,
				   $row,
				   $col,
				   \$SETTINGS{$ref->[0]},
				  );

      ($row, $col) = $col ? ($row + 1, 0) : ($row, 4);
    }

    $defFrame->gridColumnconfigure(0, -weight  => 1);
    $defFrame->gridColumnconfigure(4, -weight  => 1);
    $defFrame->gridColumnconfigure(3, -minsize => 20);
  }
}

### TBD. Check for any unsaved projects and prompt.
###      For now, prompt anyway.

sub closeApp {
  # prompt.
  unless (DEBUG) {
    my $ans = $MW->Dialog(-title   => 'Are you sure?',
			  -bitmap  => 'question',
			  -buttons => [qw/Yes No/],
			  -font    => 'Questions',
			  -text    => <<EOT)->Show;
If you quit, any unsaved projects
will be lost! Are you sure you want
to quit ZooZ?
EOT
  ;
    return if $ans eq 'No';
  }

  # make sure all localReturns are set.
  ZooZ::Forms::cancelAllForms();

  $MW->destroy;
}

sub defineWidgets {
  my @frames;
  my $firstBut;

  my $dum;

  # make all cells of the same size.
  my $cellwidth  = 0;
  my $cellheight = 0;

  for my $o ([butLab   => 'Labels and Buttons'],
	     [text     => 'Text Related'      ],
	     [menuList => 'Menus and Lists'   ],
	     [datadisp => 'Data Presentation' ],
	     #[dialog   => 'Dialogs'           ],
	     [parasite => 'Non Stand-Alone'   ],
	     [misc     => 'Miscellaneous'     ],
	    ) {

    my $b;

    my $f = $WIDGET_F->Frame(-bg          => 'white',
			     -relief      => 'sunken',
			     -borderwidth => 1);
    $b    = $WIDGET_F->Radiobutton(-text        => $o->[1],
				   -indicatoron => 0,
				   -variable    => \$dum,
				   -value       => $o->[0],
                                   -height      => 2,
                                   -borderwidth => 1,
				   -command     => sub {
				     $_->packForget for @frames;
				     $f->pack(-before => $b, qw/-side top -fill both -expand 1/);
				   })->pack(qw/-fill x -side top/);

    push @frames => $f;

    my $r = my $c = 0;

    for my $w (@{$availableWidgets{$o->[0]}}) {
      my $image  = lc $w;
      my $button = $f->Button(-bg                 => 'white',
			      -relief             => 'flat',
			      -borderwidth        => 1,
			      -highlightthickness => 0,
			      -command            => [\&selectWidgetToAdd, $w],
			       )->grid(-column => $c,
				       -row    => $r,
				       -sticky => 'nsew',
				      );

      my $comp = $button->Compound;
      $button->configure(-image => $comp);
      $comp->Line;
      if (exists $ICONS{$image}) {
	$comp->Image(-image => $ICONS{$image});
      } else {
	$comp->Bitmap(-bitmap => 'error');
      }
      $comp->Line;
      $comp->Text(-text => uc $w, -font => 'WidgetName', -anchor => 's');

      $button->update;
      my $bw = $button->ReqWidth;
      my $bh = $button->ReqHeight;
      $cellwidth  = $bw if $bw > $cellwidth;
      $cellheight = $bh if $bh > $cellheight;

      if ($c) {
	$c = 0;
	$r++;
      } else {
	$c++;
      }
    }

    $firstBut ||= $b;
    $f->gridRowconfigure   (++$r, -weight => 1);
  }

  # make sure they all have the same width.
  $firstBut->invoke;
  $MW->update;
  my $width = (sort {$b <=> $a} map $_->reqwidth, @frames)[0];
  for my $f (@frames) {
    $f->configure(-width => $width);
    $f->gridPropagate(0);
    $f->gridColumnconfigure($_, -minsize => $cellwidth ) for 0, 1;
    $f->gridRowconfigure   ($_, -minsize => $cellheight) for 0 ..($f->gridSize)[1];
  }
}

sub createToolBar {
  # create the ToolBar
  $TB = $MW->ToolBar(qw/-movable 0 -side top -cursorcontrol 0/);
  $TB->Button(-image   => 'filenew22',
	      -tip     => 'New Project',
	      -command => \&newProject,
	     );
  $TB->separator;
  $TB->Button(-image   => 'fileopen22',
	      -tip     => 'Load Project',
	      -command => \&loadProject);
  $TB->Button(-image   => 'filesave22',
	      -tip     => 'Save Project',
	      -command => \&saveProject);
  $TB->Button(-image   => 'fileclose22',
	      -tip     => 'Close Project',
	      -command => \&closeProject,
	     );
  $TB->separator;
  $TB->Button(-image   => $ICONS{dumpPL}, #'textsortinc16',
	      -tip     => 'Dump Perl Code',
	      -command => \&dumpPerl,
	     );
  $TB->Button(-image   => $ICONS{dumpPM}, #'textsortdec16',
	      -tip     => 'Dump PM Code',
	      -command => \&dumpPerlPM,
	     );
  $TB->separator;
  $TB->Button(-image   => 'viewmag22',
	      -tip     => 'Hide/Unhide Preview Window',
	      -command => sub {
		$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->togglePreview;
	      });
  $TB->Button(-image   => 'apptool22',
	      -tip     => 'Configure Selected Widget',
	      -command => sub {
		$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->configureSelectedWidget;
	      });
  $TB->Button(-image   => 'actcross16',
	      -tip     => 'Delete Selected Widget',
	      -command => sub {
		$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->deleteSelectedWidget;
	      });
  $TB->Button(-image   => 'viewmulticolumn22',
	      -tip     => 'Configure Selected Row',
	      -command => sub {
		$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->_configureRowCol('row', 'selected');
	      });
  $TB->Button(-image   => 'viewicon22',
	      -tip     => 'Configure Selected Column',
	      -command => sub {
		$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->_configureRowCol('col', 'selected');
	      });

  $TB->separator;

  if (DEBUG) {
    $TB->Button(-text => 'test',
		-command => sub {
		  #$OPEN_PROJECTS[$CURID] && $PROJECTS[$CURID]->_test;
		});
    $TB->separator;
  }

  # Now the project browseentry
  my $l = $TB->Label(-text   => 'Current Project:',
		     -anchor => 'w',
		     #-fg     => 'darkolivegreen',
		     -font   => 'Level',
		    );#->pack(qw/-side left -fill x/);

  $PROJ_BE = $TB->BrowseEntry(
			      -variable  => \$PROJ_BE_VAR,
			      -bd        => 1,
			      -browsecmd => sub {
				for my $i (0 .. $#NAMES) {
				  next unless $NAMES[$i] eq $PROJ_BE_VAR && $OPEN_PROJECTS[$i];
				  switchProject($i);
				  last;
				}
			      });#->pack(qw/-side left/);
  $PROJ_BE->Subwidget($_)->configure(-bd => 1) for qw/arrow slistbox/;

  # set up the binding to rename the project
  {
    my $e  = $PROJ_BE->Subwidget('entry')->Subwidget('entry');
    my $lb = $PROJ_BE->Subwidget('slistbox');

    $e->configure(-validate => 'key',
		  -vcmd     => sub {
		    # ALWAYS return 1 ...
		    # just set the correct info when a valid name is given.
		    return 1 if $_[4] == -1 || $_[4] == 6;

		    # make sure the name is unique.
		    # if not, make the label red.
		    if (grep $OPEN_PROJECTS[$_] && $NAMES[$_] eq $_[0] => 1 .. $#NAMES) {
		      $l->configure(-fg => 'red');
		      return 1;
		    }

		    $l->configure(-fg => 'black');#'darkolivegreen');
		    # just set the name.
		    # must update:
		    # 1. The proj menu.
		    # 2. The proj_be browseentry list.
		    # 3. The @NAMES array.
		    # 4. The project object name hash entry.
		    # 5. The window title.

		    # 1. the proj menu.
		    for my $i (0 .. $PROJ_MENU->index('last')) {
		      my $l = $PROJ_MENU->entrycget($i, '-label');
		      next unless $l eq $NAMES[$CURID];

		      $PROJ_MENU->entryconfigure($i, -label => $_[0]);
		      last;
		    }

		    # 2. the browseentry.
		    for my $i (0 .. $lb->index('end') - 1) {
		      next unless $lb->get($i) eq $NAMES[$CURID];

		      $lb->delete($i);
		      $lb->insert($i, $_[0]);
		      last;
		    }

		    # 3. @NAMES
		    $NAMES[$CURID] = $_[0];

		    # 4. The project object.
		    $PROJECTS[$CURID]->renameProject($_[0]);

		    # 5. The window title.
		    $MW->title("ZooZ v$VERSION - $NAMES[$CURID]");

		    return 1;
		  });
  }

}

sub newProject {
  $PROJECTS[$CURID]->togglePreview('OFF') if $OPEN_PROJECTS[$CURID];

  $PROJID++;

  my $name = shift || "Project $PROJID";
  my $page = $FRAME_M->Frame;

  $PAGES   [$PROJID] = $page;
  $NAMES   [$PROJID] = $name;
  $PROJECTS[$PROJID] = new ZooZ::Project
    (
     -id     => $PROJID,
     -top    => $page,
     -name   => $name,
     -title  => $name,
     -icons  => \%ICONS,
    );

  # focus it.
  $CURID = $PROJID;
  $_->packForget for $FRAME_M->packSlaves;
  $page->pack(qw/-fill both -expand 1/);
  $MW->title("ZooZ v$VERSION - $NAMES[$CURID]");

  *ZWIDGETS = $PROJECTS[$CURID]->allWidgetsHash;

  # add it to the menu.
  $PROJ_MENU->command(-label   => $name,
		      -command => [\&switchProject, $PROJID]);

  $PROJ_BE->insert(end => $name);
  $PROJ_BE_VAR = $name;

  $OPEN_PROJECTS[$CURID] = 1;
}

sub switchProject {
  my ($id) = @_;
  $PROJECTS[$CURID]->togglePreview('OFF') if $CURID && $OPEN_PROJECTS[$CURID];

  $CURID = $id;
  $_->packForget for $FRAME_M->packSlaves;

  $PAGES[$id]->pack(qw/-fill both -expand 1/);
  $MW->title("ZooZ v$VERSION - $NAMES[$CURID]");

  $PROJECTS[$CURID]->togglePreview('ON');

  *ZWIDGETS    = $PROJECTS[$CURID]->allWidgetsHash;
  $PROJ_BE_VAR = $NAMES[$CURID];
}

# must ask to save project first or not.
sub closeProject {
  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  my $ans = $MW->Dialog(-title   => 'Are you sure?',
			-bitmap  => 'question',
			-buttons => [qw/Yes No/, 'Save & Close'],
			-font    => 'Questions',
			-text    => <<EOT)->Show;
Any changes you made to the project
will be lost! Are you sure you want
to close $NAMES[$CURID]?
EOT
  ;
  return if $ans eq 'No';

  saveProject() if $ans eq 'Save & Close';

  # close the project. This means:
  # 1. Unmapping it.
  # 2. Cleaning up the project object.
  # 3. Removing it from the Projects menu.
  # 4. Change the MW title.
  #$PAGES   [$CURID]->packForget;
  $PAGES   [$CURID]->destroy;
  $PROJECTS[$CURID]->closeMe;
  $MW->title("ZooZ v$VERSION");

  removeFromMenu($NAMES[$CURID]);

  $OPEN_PROJECTS[$CURID] = 0;
}

#
# This differs from saveProject in that it prompts for
# a file name to save to. It then calls saveProject();
#

sub saveProjectAs {
  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  my $f = $MW->getSaveFile(@FILE_OPTIONS,
			   -title => 'Choose File to Save',
			  );

  defined $f or return;

  $PROJECT_FILES[$CURID] = $f;

  goto &saveProject;
}

#
# This does not prompt for a file name if the project has
# one associated with it.
#

sub saveProject {
  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  goto &saveProjectAs unless defined $PROJECT_FILES[$CURID];

  open my $fh, "> $PROJECT_FILES[$CURID]" or die "$PROJECT_FILES[$CURID]: $!\n";

  print $fh "[ZooZ v$VERSION]\n";
  print $fh "[Project $NAMES[$CURID]]\n\n";

  $PROJECTS[$CURID]->save($fh);

  # Now dump any subroutines.
  for my $n ($CALLBACKOBJ->listAll) {
    my $code = $CALLBACKOBJ->code($n);
    s/\s+$//, s/^\s+// for $code;

    print $fh <<EOT;
\[Sub $n\]
$code
\[End Sub\]

EOT
  ;
  }

  # And dump any vars.
  for my $v ($VARREFOBJ->listAll) {
    my $val   = $v;
    $val      =~ s/(.)/$ {1}main::/;
    $val      = Dumper($1 eq "\$" ? eval "$val" : eval "\\$val");
    $val      =~ s/\$VAR1 = //;
    $val      =~ s/;$//;
    $val      =~ s/^[\[\{]/\(/;  # stupid cperl mode
    $val      =~ s/[\]\}]$/\)/;

    print $fh <<EOT;
\[Var $v\]
$val
\[End Var\]

EOT
  ;
  }

  # and the fonts.
  for my $f ($FONTOBJ->listAll) {
    next if $f eq 'Default';

    my %data = $MW->fontActual($f);

    print $fh <<EOT;
\[Font $f\]
EOT
  ;
    print $fh "$_ $data{$_}\n" for keys %data;
    print $fh "[End Font]\n\n";
  }

  close $fh;

  my $f = $PROJECT_FILES[$CURID];
  $f =~ s|.*/||;

  ZooZ::Generic::popMessage(-over  => $MW,
			    -msg   => "Project file $f saved successfully.",
			    -delay => 1500,
			    -bg    => 'white',
			    -font  => 'Level');
}

sub loadProject {
  my $f = shift;

  unless ($f) {
    $f = $MW->getOpenFile(@FILE_OPTIONS,
			  -title => 'Choose File to Load',
			 );
    defined $f or return;
  }

  $MW->Busy;

  open my $fh, $f or die $!;

  my @DATA;
  my $PMW = {};
  my @ROWCOLDATA;

  local $_;
  my $projName;

  while (<$fh>) {
    s/\#.*//;

    # is it a project name
    if (/^\s*\[\s*Project\s+(.+?)\s*\]\s*$/) {
      $projName = $1;

      # Is it the mainwindow?
    } elsif (/^\s*\[MainWindow\]/) {
      s/\#.*//;

      while (<$fh>) {
	last if /^\s*\[End\s+Widget\]/;

	if (/^\s*Title\s+(.+)/) {
	  $PMW->{title} = $1;
	} elsif (/^WCONF\s+(\S+)\s+(.+)/) {
	  $PMW->{$1} = $2;
	}
      }

      # Is it a widget?
    } elsif (/^\s*\[Widget\s+(\S+)\]/) {
      my %data;
      $data{NAME} = $1;

      # read until the end of the widget definition.
      while (<$fh>) {
	s/\#.*//;
	if (/^\s*\[End\s+Widget\]/) {
	  # create the widget.
	  #$proj->loadWidget(\%data);
	  #last;

	  # Don't create the widgets yet. Do that after the
	  # sub and var definitions have been done.
	  push @DATA => \%data;
	  last;
	}

	if (/^\s*([PWE]CONF)\s+(\S+)(?:\s+(.*))?\s*$/) {
	  my $v = defined $3 ? $3 : '';
	  $data{$1}{$2} = $v eq 'undef' ? undef : $v;
	  next;
	}

	next unless /^\s*(\S+)\s+(\S+)\s*$/;
	$data{$1} = $2;
      }

      # is it a sub definition?
    } elsif (/^\s*\[Sub\s+(\S+)\]/) {
      my $name = $1;
      my $code = '';

      while (<$fh>) {
	last if /^\s*\[End\s+Sub\]/;
	$code .= $_;
      }

      $CALLBACKOBJ->add($name, $code);

      # eval it.
      {
	no strict;
	no warnings;

	$code =~ s/sub \Q$name/sub /;
	*{"main::$name"} = eval "package main; $code";
      }

      $CALLBACKOBJ->name2code($name, eval "\\&main::$name");

      # is it a var?
    } elsif (/^\s*\[Var\s+(\S+)\]/) {
      my $name = $1;
      my $val  = <$fh>;
      <$fh>;  # [End Var]

      $VARREFOBJ->add($name);
      $name =~ s/^(.)/$ {1}main::/;
      eval "$name = $val";

      $VARREFOBJ->name2ref($name, eval "\\$name");

      # Is it a row/col conf option?
    } elsif (/^\s*\[(Row|Col)\s+(\d+)\]/) {
      my $rowOrCol = $1;
      my $num      = $2;

      my %data;
      while (<$fh>) {
	last if /^\s*\[End\s+$rowOrCol\]/;

	$data{$1} = $2 if /^\s*(\S+)\s+(.+?)\s*$/;
      }

      push @ROWCOLDATA => [$rowOrCol, $num, %data];

      # is it a font definition?
    } elsif (/^\s*\[Font\s+(\S+)\s*\]/) {
      my $name = $1;
      my @data;

      while (<$fh>) {
	last if /^\s*\[End\s+Font\]/;

	next unless /^\s*(\S+)\s+(.+?)\s*$/;

	push @data => $1, $2;
      }

      # create the font.
      $FONTOBJ->add($name, $MW->fontCreate($name, @data));
    }
  }

  # Create the project.
  newProject($projName);
  my $proj = $PROJECTS[$CURID];
  $PROJECT_FILES[$CURID] = $f;

  # Now create all the widgets.
  $proj->loadWidget($_) for @DATA;
  $proj->unselectCurrentWidget;
  $proj->_unhideCanvas;

  # Load any row/col conf (after widget creation)
  $proj->loadRowCol(@$_) for @ROWCOLDATA;

  # configure the mainwindow.
  $proj->setMW($PMW) if defined $PMW;

  $MW->Unbusy;

  $f =~ s|.*/||;

  ZooZ::Generic::popMessage(-over  => $MW,
			    -msg   => "Project file $f loaded successfully.",
			    -delay => 1500,
			    -bg    => 'white',
			    -font  => 'Level');
}

sub loadIcons {
  for my $file (<$PERLLIB/ZooZ/icons/*png>, <$PERLLIB/ZooZ/icons/*gif>) {  # should this use Tk->findINC ??
    my ($name, $format) = $file =~ m{.*/(.+)\.(gif|png)};
    next if exists $ICONS{$name};

    $ICONS{$name} = $MW->Photo("$name-zooz", -format => $format, -file => $file);
  }
}

sub loadBitmaps {
  my $downbits = pack("b10" x 5,
		      "11......11",
		      ".11....11.",
		      "..11..11..",
		      "...1111...",
		      "....11....",
		     );

  $MW->DefineBitmap('down_size', 10, 5, $downbits);

  my $upbits = pack("b10" x 5,
		    "....11....",
		    "...1111...",
		    "..11..11..",
		    ".11....11.",
		    "11......11",
		   );

  $MW->DefineBitmap('up_size', 10, 5, $upbits);

  # define the h bitmap.
  my $rightbits = pack("b5" x 10,
		       "1....",
		       "11...",
		       ".11..",
		       "..11.",
		       "...11",
		       "...11",
		       "..11.",
		       ".11..",
		       "11...",
		       "1....",
		      );

  $MW->DefineBitmap('right_size', 5, 10, $rightbits);

  my $leftbits = pack("b5" x 10,
		       "....1",
		       "...11",
		       "..11.",
		       ".11..",
		       "11...",
		       "11...",
		       ".11..",
		       "..11.",
		       "...11",
		       "....1",
		      );

  $MW->DefineBitmap('left_size', 5, 10, $leftbits);

  my $rightArrow = pack("b10" x 5,
			"......11..",
			".......11.",
			"1111111111",
			".......11.",
			"......11..",
		       );

  my $leftArrow = pack("b10" x 5,
		       "..11......",
		       ".11.......",
		       "1111111111",
		       ".11.......",
		       "..11......",
		      );

  my $upArrow = pack("b5" x 10,
		     "..1..",
		     ".111.",
		     "11111",
		     "1.1.1",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		    );

  my $downArrow = pack("b5" x 10,
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "1.1.1",
		       "11111",
		       ".111.",
		       "..1..",
		      );

  my $box = pack("b5" x 5,
		 ".....",
		 ".111.",
		 ".111.",
		 ".111.",
		 ".....",
		);

  $MW->DefineBitmap('rightArrow', 10,  5, $rightArrow);
  $MW->DefineBitmap('leftArrow',  10,  5, $leftArrow );
  $MW->DefineBitmap('upArrow',     5, 10, $upArrow   );
  $MW->DefineBitmap('downArrow',   5, 10, $downArrow );
  $MW->DefineBitmap('box',         5,  5, $box       );
}

sub defineFonts {
  $MW->fontCreate('Row/Col Num',
		  -family => 'Nimbus',
		  -size   => 10,
		  -weight => 'bold',
		 );

  $MW->fontCreate('WidgetName',
		  -family => 'Helvetica',
		  -size   => 10,
		 );

  $MW->fontCreate('Questions',
		  -family => 'Nimbus',
		  -size   => 10,
		 );

  $MW->fontCreate('Level',
		  -family => 'helvetica',
		  -size   => 13,
		  -weight => 'normal',
		 );

  $MW->fontCreate('OptionText',
		  -family => 'helvetica',
		  -size   => 11,
		  -weight => 'normal',
		 );

#  $MW->fontCreate('WidgetName',
#		  -family => 'helvetica',
#		  -size   => 12,
#		 );
}

sub selectWidgetToAdd {
  return unless $OPEN_PROJECTS[$CURID];

  $SELECTED_W = shift;

  $SELECTED_L->configure(exists $ICONS{lc $SELECTED_W} ?
			 (-image => $ICONS{lc $SELECTED_W}) :
			 (-image => ''));

  my $w = $SELECTED_L->reqwidth  / 2;
  my $h = $SELECTED_L->reqheight / 2;

  my ($x, $y) = $MW->pointerxy;
  $x -= $MW->rootx;
  $y -= $MW->rooty;

  $SELECTED_L->place(-x => $x - $w,
		     -y => $y - $h);

  # set the bindings.

  # when the mouse moves, update the dummy label.
  $MW->bind('<Motion>' => sub {
	      my ($x, $y) = $MW->pointerxy;
	      $x -= $MW->rootx;
	      $y -= $MW->rooty;

	      $SELECTED_L->place(-x => $x - $w,
				 -y => $y - $h);
	    });

  # clicking somewhere does something.
  $MW->bind('<1>' => sub {
	      $OPEN_PROJECTS[$CURID] or return;

	      $PROJECTS[$CURID]->dropWidgetInCurrentObject
		  or return;

	      endDrag();
	    });

  # pressing escape cancels.
  $MW->bind('<Escape>'    => \&endDrag);
  $MW->bind('<<EndDrag>>' => \&endDrag);
}

sub endDrag {
  $SELECTED_L->placeForget;
  $MW->bind($_ => '') for qw/<Escape> <Motion> <1>/;
}

sub defineStyles {
  $MW->ItemStyle(imagetext         =>
		 -stylename        => 'container',
		 -fg               => 'red',
		 -selectforeground => 'red',
		);
}

sub createExtraObjects {
  # Create the font object
  $FONTOBJ = new ZooZ::Fonts;

  {
    # create the default font.
    # use a dummy label.
    my $l    = $MW->Label      (-text => 'test');
    my $c    = $l  ->configure ('-font');
    my $font = $MW->fontCreate ('Default',
				map {$_ => $c->[-1]->actual($_)}
				qw/-family -size -weight -slant -underline -overstrike/,
			       );
    $l->destroy;
    $FONTOBJ->add(Default => $font);
  }

  # create the callback object
  $CALLBACKOBJ = new ZooZ::Callbacks;

  # create the varRef object
  $VARREFOBJ = new ZooZ::varRefs;
}

sub removeFromMenu {
  my $c = shift;

  for my $i (0 .. $PROJ_MENU->index('last')) {
    my $l = $PROJ_MENU->entrycget($i, '-label');
    next unless $l eq $c;

    $PROJ_MENU->delete($i);
    last;
  }

  # now, remove from browseEntry
  for my $i (0 .. $#NAMES) {
    $PROJ_BE->delete($i, $i), last if $PROJ_BE->get($i) eq $c;
  }
  $PROJ_BE_VAR = '';
}

sub createHandlers {
  $SIG{__DIE__} = sub {
    # ignore the error due to CodeText if it's not present.
    return if $_[0] =~ m{Can't locate Tk/CodeText\.pm}; #';

    my $msg = "\n\nMessage:\n$_[0]";
    chomp $msg;

    my $ans = $MW->Dialog(-title   => 'Fatal Error Detected',
			  -bitmap  => 'error',
			  -buttons => [qw/Ok Quit/],
			  -font    => 'Questions',
			  -text    => join ' ' => split " \n", <<EOT)->Show;
A fatal error has been detected and was trapped! 
You can press 'Ok' and continue, but it is best 
that you save your work and restart. If you can 
reproduce this behaviour, then please send the necessary 
steps to do so to aqumsieh\@cpan.org.
$msg
EOT
  ;

    CORE::exit if $ans eq 'Quit';

    $MW->deiconify;
    goto &MainLoop;
  };

  open my $warnLog, "> ZooZ.log" or
    die "ERROR: Could not create log file: $!\n";

  $SIG{__WARN__} = sub {
    print $warnLog shift;

    return unless $WARNINGS_ON;

    unless ($WARN_DIALOG) {
      $WARN_DIALOG = $MW->DialogBox(-title   => 'Non-Fatal Error Detected',
				    -buttons => [qw/Ok/],
				    -popover => $MW);

      $WARN_DIALOG->Label(-justify => 'left',
			  -font    => 'Questions',
			  -text    => <<EOT)->pack;
A non-fatal error has been caught and recorded
in ZooZ.log. It is probably fine to continue.
It is best that you save your work. If you can
reproduce the error, then please send me details
at aqumsieh\@cpan.org.
EOT
  ;

      $WARN_DIALOG->Checkbutton(
				-text       => 'Do not show this message again.',
				-variable   => \$WARNINGS_ON,
				-font       => 'Questions',
			       )->pack;
    }

    $WARN_DIALOG->Show();
  } unless DEBUG;

  $SIG{INT} = \&closeApp unless DEBUG;
}

sub dumpPerlAs {
  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  my $f = $MW->getSaveFile(-title => 'Choose File to Save',
			   -defaultextension => '.pl',
			   -initialdir       => '.',
			   -filetypes        =>
			   [
			    ['PL Files',   '.pl'],
			    ['ZooZ Files', '.zooz'],
			    ['All Files',  '*'    ],
			   ],
			  );
  $f or return;

  $PERL_FILES[$CURID] = $f;

  goto &dumpPerl;
}

sub dumpPerl {
  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  goto &dumpPerlAs unless defined $PERL_FILES[$CURID];

  open my $fh, "> $PERL_FILES[$CURID]" or die "$PERL_FILES[$CURID]: $!\n";

  $MW->Busy;

  # some headers.
  my $time = localtime;

  my $h    = DEBUG ? "use lib '/home/aqumsieh/Tk804.025_beta15/lib/site_perl/5.8.3/i686-linux';\n" : '';
  print $fh <<EOT;
#!perl

##################
#
# This file was automatically generated by ZooZ.pl v$VERSION
# on $time.
# Project: $NAMES[$CURID]
# File:    $PROJECT_FILES[$CURID]
#
##################

#
# Headers
#
use strict;
use warnings;
$h
use Tk 804;

#
# Global variables
#
my (
     # MainWindow
     \$MW,

     # Hash of all widgets
     \%ZWIDGETS,
    );

#
# User-defined variables (if any)
#
EOT
  ;

  # now dump the user-defined vars.
  local $Data::Dumper::Indent = 2;

  for my $v ($VARREFOBJ->listAll) {
    my $val   = $v;
    $val      =~ s/(.)/$ {1}main::/;
    $val      = Dumper($1 eq "\$" ? eval "$val" : eval "\\$val");
    $val      =~ s/\$VAR1 = //;
    $val      =~ s/;$//;
    $val      =~ s/^[\[\{]/\(/;  # stupid cperl mode
    $val      =~ s/[\]\}]$/\)/;

    chomp $val;

    print $fh <<EOT;
my $v = $val;

EOT
  ;
  }

  # Create the MainWindow
  print $fh <<'EOT';

######################
#
# Create the MainWindow
#
######################

$MW = MainWindow->new;

######################
#
# Load any images and fonts
#
######################
ZloadImages();
ZloadFonts ();

EOT
  ;

  # Now let the project do it's thing.
  $PROJECTS[$CURID]->dumpPerl($fh);

  # finish off
  print $fh <<EOT;


###############
#
# MainLoop
#
###############

MainLoop;

#######################
#
# Subroutines
#
#######################

EOT
  ;

  # Now the subroutines.

  # first subroutine is ZloadImages();
  {
    my $images = $PROJECTS[$CURID]->getImageHash;

    print $fh "sub ZloadImages {\n";

    for my $file (keys %$images) {
      my $name = $images->{$file};

      my $method;
      if    ($file =~ /\.(?:gif|ppm|pgm)$/) { $method = 'Photo'  }
      elsif ($file =~ /\.bmp$/)             { $method = 'Bitmap' }
      elsif ($file =~ /\.xpm$/)             { $method = 'Pixmap' }
      else {
	# should never be here.
	next;
      }

      print $fh "  \$MW->$method('$name', -file => '$file');\n";
    }
    print $fh "}\n\n";
  }

  # now it's ZloadFonts();
  {
    print $fh "sub ZloadFonts {\n";

    for my $f ($FONTOBJ->listAll) {
      next if $f eq 'Default';

      my %data = $MW->fontActual($f);

      # quote the values, if we need to.
      /^-?\d+/ or $_ = "'$_'" for values %data;

      my $str  = ZooZ::Generic::lineUpCommas(map [$_, $data{$_}], keys %data);
      print $fh "  \$MW->fontCreate('$f',\n$str\n  );\n";
    }
    print $fh "}\n\n";
  }


  # and the user-defined subs.
  {
    for my $n ($CALLBACKOBJ->listAll) {
      my $code = $CALLBACKOBJ->code($n);
      s/\s+$//, s/^\s+// for $code;
      $code =~ s/\A\#.*\n//;
      $code =~ s/sub main::/sub /;

      print $fh <<EOT;
$code

EOT
  ;
    }
  }

  close $fh;

  $MW->Unbusy;

  my $f = $PERL_FILES[$CURID];
  $f =~ s|.*/||;

  ZooZ::Generic::popMessage(-over  => $MW,
			    -msg   => "Perl code exported successfully to $f.",
			    -delay => 1500,
			    -bg    => 'white',
			    -font  => 'Level');
}

sub dumpPerlPMAs {  # Code dup :(
  DUMP_PM_SUPPORT or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'Not implemented yet!',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  my $f = $MW->getSaveFile(-title => 'Choose File to Save',
			   -defaultextension => '.pm',
			   -initialdir       => '.',
			   -filetypes        =>
			   [
			    ['PM Files',   '.pm'],
			    ['ZooZ Files', '.zooz'],
			    ['All Files',  '*'    ],
			   ],
			  );
  $f or return;

  $PM_FILES[$CURID] = $f;

  goto &dumpPerlPM;
}

sub dumpPerlPM {
  DUMP_PM_SUPPORT or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'Not implemented yet!',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  $OPEN_PROJECTS[$CURID] or return
    ZooZ::Generic::popMessage(-over  => $MW,
			      -msg   => 'No active project.',
			      -delay => 1500,
			      -bg    => 'white',
			      -font  => 'Level');

  goto &dumpPerlPMAs unless defined $PM_FILES[$CURID];

  open my $fh, "> $PM_FILES[$CURID]" or die "$PM_FILES[$CURID]: $!\n";

  $MW->Busy;

  # some headers.
  my $time = localtime;

  my $h    = DEBUG ? "use lib '/home/aqumsieh/Tk804.025_beta15/lib/site_perl/5.8.3/i686-linux';\n" : '';
  my $pack = $NAMES[$CURID];

  $pack =~ s/\W/_/g;

  print $fh <<EOT;

package $pack;

##################
#
# This file was automatically generated by ZooZ.pl v$VERSION
# on $time.
# Project: $NAMES[$CURID]
# File:    $PROJECT_FILES[$CURID]
#
##################

#
# Headers
#
use strict;
use warnings;
$h

use Tk 804;
use base qw/Tk::Derived Tk::Frame/;

Construct Tk::Widget '$pack';

our \%ZWIDGETS;

#
# User-defined variables (if any)
#
EOT
  ;

  # now dump the user-defined vars.
  my $vars = stringifyVars();
  print $fh $_ for @$vars;

  print $fh <<'EOT';

sub ClassInit {
  my ($class, $mw) = @_;

  # load any fonts or images
  ZloadImages($mw);
  ZloadFonts ($mw);
}

sub Populate {
  my ($w, $args) = @_;

  $w->SUPER::Populate($args);

  # need to create a dummy Frame to prevent
  # Tk overriding subwidget configurations.
  my $f = $w->Frame->pack(qw/-fill both -expand 1/);

EOT
  ;

  # Now let the project do it's thing.
  $PROJECTS[$CURID]->dumpPerl($fh, 1, '$f');

  print $fh "\n\n";

  # Advertise all the widgets
  my $allWidgets = $PROJECTS[$CURID]->allWidgetsHash;
  for my $name (keys %$allWidgets) {
    print $fh "  \$w->Advertise('$name' => \$ZWIDGETS{'$name'});\n";
  }

  # finish off
  print $fh <<EOT;
\}

#######################
#
# Subroutines
#
#######################

EOT
  ;

  # Now the subroutines.

  # first subroutine is ZloadImages();
  {
    my $images = $PROJECTS[$CURID]->getImageHash;

    print $fh "sub ZloadImages {\n  my \$MW = shift;\n";

    for my $file (keys %$images) {
      my $name = $images->{$file};

      my $method;
      if    ($file =~ /\.(?:gif|ppm|pgm)$/) { $method = 'Photo'  }
      elsif ($file =~ /\.bmp$/)             { $method = 'Bitmap' }
      elsif ($file =~ /\.xpm$/)             { $method = 'Pixmap' }
      else {
	# should never be here.
	next;
      }

      print $fh "  \$MW->$method('$name', -file => '$file');\n";
    }
    print $fh "}\n\n";
  }

  # now it's ZloadFonts();
  {
    print $fh "sub ZloadFonts {\n  my \$MW = shift;\n";

    for my $f ($FONTOBJ->listAll) {
      next if $f eq 'Default';

      my %data = $MW->fontActual($f);

      # quote the values, if we need to.
      /^-?\d+/ or $_ = "'$_'" for values %data;

      my $str  = ZooZ::Generic::lineUpCommas(map [$_, $data{$_}], keys %data);
      print $fh "  \$MW->fontCreate('$f',\n$str\n  );\n";
    }
    print $fh "}\n\n";
  }


  # and the user-defined subs.
  {
    for my $n ($CALLBACKOBJ->listAll) {
      my $code = $CALLBACKOBJ->code($n);
      s/\s+$//, s/^\s+// for $code;
      $code =~ s/\A\#.*\n//;
      $code =~ s/sub main::/sub /;

      print $fh <<EOT;
$code

EOT
  ;
    }
  }

  # modules return a true value.
  print $fh "\n'ZooZ Rocks!';\n";

  close $fh;

  $MW->Unbusy;

  my $f = $PM_FILES[$CURID];
  $f =~ s|.*/||;

  ZooZ::Generic::popMessage(-over  => $MW,
			    -msg   => "Module code exported successfully to $f.",
			    -delay => 1500,
			    -bg    => 'white',
			    -font  => 'Level');
}

#
# This sub returns an array ref of the declaration code of
# all the variables.
#

sub stringifyVars {
  local $Data::Dumper::Indent = 2;

  my @vars;

  for my $v ($VARREFOBJ->listAll) {
    my $val   = $v;
    $val      =~ s/(.)/$ {1}main::/;
    $val      = Dumper($1 eq "\$" ? eval "$val" : eval "\\$val");
    $val      =~ s/\$VAR1 = //;
    $val      =~ s/;$//;
    $val      =~ s/^[\[\{]/\(/;  # stupid cperl mode
    $val      =~ s/[\]\}]$/\)/;

    chomp $val;

#    print $fh <<EOT;
#my $v = $val;
#
#EOT
#  ;
    push @vars => "my $v = $val;\n";
  }

  return \@vars;
}

sub findDir {
  my $f = shift;

  for my $p (@INC) {
    return $p if -f "$p/$f";
  }

  return 0;
}

__END__

=pod

=head1 NAME

ZooZ.pl - A Perl/Tk GUI builder in pure Perl/Tk.

=head1 SYNOPSIS

    % perl ZooZ.pl

=head1 DESCRIPTION

ZooZ is a GUI builder for Perl/Tk written in pure Perl/Tk. It has the
following features:

=over 4

=item *

Intuitive interface.

=item *

Support for a wide variety of widgets.

=item *

Ability to save/load projects.

=item *

Ability to dump stand-alone Perl code.

=item *

Ability to dump code as a Perl module in the form of a Perl/Tk mega widget.

=item *

Includes a simple IDE for defining variables and subroutines.

=back

=head1 STATUS AND LIMITATIONS

ZooZ is an on-going effort, and will probably stay so for a long time. At this stage,
though, I consider it to be very usable. There are some major limitations though.
For a comprehensive list of missing features, you can look at the Progress.txt
file that comes in the root directory of the distribution. If you think there is
something else that should be included in that file, then drop me a note.

=head1 REQUIREMENTS

To run ZooZ, you need Tk804, which in turn needs Perl 5.8 or better.
I will probably support Tk800 sometime in the future, in which case
any Perl5 version will be supported.

In addition Tk::ToolBar is required. Again, I will probably make this
optional in a future release.

=head1 OPTIONAL COMPONENTS

Tk::CodeText is optional. If present it will be used in the simple
IDE to highlight user-entered Perl code. If missing, a regular
Tk::Text will be used.

=head1 TIPS

=over 4

=item *

You can create a project, then save the code as a Perl Module with a F<.pm> extension.
This will create a composite mega widget, with the same name as your project, but with
any non-alphanumeric characters switched to underscores. For example, C<Project 1.5> will
be changed to C<Project_1_5>. You can then B<use> this in a larger program as a regular
widget.

For example, if you dumped your module into F<myMod.pm>, and your project was called
C<Project 1.5>, then you would do this in your main code:

    use myMod;
    my $project = $parent->Project_1_5->pack;

Note also that the mega widget will F<Advertise()> every widget in your project.
So, if your project had a canvas called Canvas1, you can access it like this:

    my $cv = $project->Subwidget('Canvas1');

=item *

ZooZ automatically defines a hash called I<%ZWIDGETS> that holds the project's
widgets. This allows the user to access any widget inside of a callback via
I<$ZWIDGETS{WidgetName}> where B<WidgetName> is the name of the widget.

=item *

You can click on the row and column numbers to configure their properties.

=item *

If you want a row or column to take up more space than it currently does,
then increase its greediness. Remember that widgets are confined to the
space of the grids they occupy.

=back

=head1 BUGS

You tell me! If you think you found a bug, or you want to discuss anything
ZooZ-related, then please drop me a note at I<aqumsieh@cpan.org>.

=head1 ACKNOWLEDGEMENTS

I'm indebted to everyone on comp.lang.perl.tk for constructive comments and
bug reports. Many people also emailed me with bugs and suggestions. It is
much appreciated.

=head1 COPYRIGHTS

Copyright 2004-2005 - Ala Qumsieh.

This program is distributed under the same terms as Perl itself.

The use of the Camel image with the topic of Perl is a trademark
of O'Reilly Media, Inc. Used with permission.

=end
